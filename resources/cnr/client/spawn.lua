CnR = CnR or {}
CnR.Spawn = CnR.Spawn or {}

local selectCam        = nil
local inSelectionView  = false
local cachedSkinsByTeam = { cop = {}, robber = {} }
local cachedProfileSkin = nil
local requestedOnBoot   = false


local PED_POS    = vec3(440.0, -981.5, 30.69)
local PED_HEADING = 0.0
local CAM_POS    = vec3(439.1, -978.8, 31.3)
local CAM_LOOK   = vec3(439.5, -981.5, 30.9)
local creatorLocation = nil
local camOrbit   = { angle = 180.0, pitch = 10.0, dist = 2.5 }

local function getCreatorLocation(side)
    local locations = (Config and Config.CharCreatorLocations) or nil
    if not locations then return nil end
    return locations[side] or locations.cop or locations.robber
end

local function applyCreatorLocation(loc)
    if not loc then return end
    creatorLocation = loc
    PED_POS = loc.ped and vec3(loc.ped.x, loc.ped.y, loc.ped.z) or PED_POS
    PED_HEADING = (loc.ped and loc.ped.w) or PED_HEADING
    CAM_POS = loc.cam or CAM_POS
    CAM_LOOK = loc.look or CAM_LOOK
    -- Start camera directly in front of the ped (opposite the heading direction).
    camOrbit.angle = (PED_HEADING + 180.0) % 360.0
    camOrbit.pitch = 10.0
end

local function updateSelectionCamera()
    if not (selectCam and DoesCamExist(selectCam)) then return end
    local a   = math.rad(camOrbit.angle)
    local p   = math.rad(camOrbit.pitch)
    local dxz = camOrbit.dist * math.cos(p)
    local cx  = PED_POS.x + dxz * math.sin(a)
    local cy  = PED_POS.y + dxz * math.cos(a)
    local cz  = PED_POS.z + 1.0 + camOrbit.dist * math.sin(p)
    SetCamCoord(selectCam, cx, cy, cz)
    PointCamAtCoord(selectCam, PED_POS.x, PED_POS.y, PED_POS.z + 1.0)
end

function CnR.Spawn.setCreatorSide(side)
    applyCreatorLocation(getCreatorLocation(side))
    if not inSelectionView then return end
    local ped = PlayerPedId()
    SetEntityCoords(ped, PED_POS.x, PED_POS.y, PED_POS.z, false, false, false, false)
    SetEntityHeading(ped, PED_HEADING)
    updateSelectionCamera()
end

local function enterSelectionView()
    if inSelectionView then return end
    inSelectionView = true

    applyCreatorLocation(getCreatorLocation('cop'))

    local ped = PlayerPedId()
    DoScreenFadeOut(400)
    Wait(450)

    -- Swap the default GTA character (Michael / player_zero) for a freemode ped BEFORE the
    -- screen fades back in, so the team-select pedestal never flashes Michael. Done while the
    -- screen is fully black; the real skin is applied once the player picks a side
    -- (CnR.Spawn.previewCustom). #michael
    local freemode = `mp_m_freemode_01`
    if GetEntityModel(ped) ~= freemode and GetEntityModel(ped) ~= `mp_f_freemode_01` then
        RequestModel(freemode)
        local t0 = GetGameTimer()
        while not HasModelLoaded(freemode) and GetGameTimer() - t0 < 5000 do Wait(10) end
        if HasModelLoaded(freemode) then
            SetPlayerModel(PlayerId(), freemode)
            SetModelAsNoLongerNeeded(freemode)
            ped = PlayerPedId()
            SetPedDefaultComponentVariation(ped)   -- clothed default, not underwear
        end
    end

    SetEntityCoords(ped, PED_POS.x, PED_POS.y, PED_POS.z, false, false, false, false)
    SetEntityHeading(ped, PED_HEADING)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, true)
    SetPlayerControl(false, 0)

    if not selectCam or not DoesCamExist(selectCam) then
        selectCam = CreateCamWithParams(
            'DEFAULT_SCRIPTED_CAMERA',
            CAM_POS.x, CAM_POS.y, CAM_POS.z,
            0.0, 0.0, 0.0,
            50.0, false, 0
        )
    end
    updateSelectionCamera()
    SetCamActive(selectCam, true)
    RenderScriptCams(true, false, 0, true, false)

    DoScreenFadeIn(500)
end

local function exitSelectionView()
    if not inSelectionView then return end
    inSelectionView = false

    DoScreenFadeOut(300)
    Wait(350)

    if selectCam and DoesCamExist(selectCam) then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(selectCam, false)
        selectCam = nil
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetPlayerControl(true, 0)

    SetNuiFocus(false, false)
    DoScreenFadeIn(500)
end

function CnR.Spawn.openTeamSelect(skinsByTeam, profileSkin)
    cachedSkinsByTeam = skinsByTeam or cachedSkinsByTeam
    if profileSkin ~= nil then
        cachedProfileSkin = (profileSkin ~= false) and profileSkin or nil
    end
    enterSelectionView()
    SendNUIMessage({
        type = 'teamSelect',
        payload = { skinsByTeam = cachedSkinsByTeam },
    })
    SetNuiFocus(true, true)
end

function CnR.Spawn.exitSelectionView()
    exitSelectionView()
end

function CnR.Spawn.isInSelectionView()
    return inSelectionView
end

AddEventHandler('playerSpawned', function()
    if CnR._sessionBootStarted then return end
    if requestedOnBoot then return end
    requestedOnBoot = true
    SetTimeout(800, function()
        if CnR._sessionBootStarted then return end
        if CnR.State and CnR.State.side and CnR.State.side ~= CnR.Sides.NONE then return end
        TriggerServerEvent('cnr:server:requestTeamSelect')
    end)
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if CnR._sessionBootStarted then return end
    SetTimeout(1500, function()
        if CnR._sessionBootStarted then return end
        if requestedOnBoot then return end
        if CnR.State and CnR.State.side and CnR.State.side ~= CnR.Sides.NONE then return end
        requestedOnBoot = true
        TriggerServerEvent('cnr:server:requestTeamSelect')
    end)
end)

RegisterNetEvent('cnr:client:openTeamSelect', function(payload)
    payload = payload or {}
    CnR.Spawn.openTeamSelect(payload.skinsByTeam, payload.profileSkin)
end)

RegisterNUICallback('cnr/chooseTeam', function(data, cb)
    local side = data and data.side
    if side ~= 'cop' and side ~= 'robber' then
        cb({ ok = false })
        return
    end

    SendNUIMessage({ type = 'closeAll' })
    SetNuiFocus(false, false)

    if CnR.Spawn.setCreatorSide then
        CnR.Spawn.setCreatorSide(side)
    end
    if CnR.CharMenu and CnR.CharMenu.open then
        CnR.CharMenu.open(side, cachedProfileSkin)
    end
    cb({ ok = true })
end)

RegisterNUICallback('cnr/closeHelp', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('cnr/newLifeConfirm', function(data, cb)
    data = data or {}
    local confirmed = data.confirmed == true or data.confirm == true
    if confirmed then
        TriggerServerEvent('cnr:server:newLife')
    end
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

local function previewModelBlocking(model)
    local hash = (type(model) == 'string') and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local t0 = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t0 < 4000 do Wait(50) end
    return HasModelLoaded(hash) and hash or nil
end

function CnR.Spawn.previewCustom(skinData, side)
    if type(skinData) ~= 'table' or not inSelectionView then return end
    skinData.side = side

    local modelName = (skinData.gender == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    local hash = previewModelBlocking(modelName)
    if not hash then return end
    if GetEntityModel(PlayerPedId()) ~= hash then
        SetPlayerModel(PlayerId(), hash)
        SetModelAsNoLongerNeeded(hash)
        local t0 = GetGameTimer()
        while GetEntityModel(PlayerPedId()) ~= hash and GetGameTimer() - t0 < 3000 do Wait(0) end
        Wait(100)
    end
    local ped = PlayerPedId()
    SetEntityCoords(ped, PED_POS.x, PED_POS.y, PED_POS.z, false, false, false, false)
    SetEntityHeading(ped, PED_HEADING)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, true)
    if not (CnR.NativeUI and CnR.NativeUI.isOpen()) then
        SetPlayerControl(PlayerId(), false, 0)
    end
    CnR.Util.ApplyCustomAppearance(ped, skinData, side, 1)
end


CreateThread(function()
    while true do
        if inSelectionView then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then


                FreezeEntityPosition(ped, true)
                SetEntityVisible(ped, true, false)
                SetEntityInvincible(ped, true)

                SetPlayerControl(PlayerId(), false, 0)

                -- Disable the mouse BUTTONS (clicks do nothing) and disable the mouse look
                -- AXES too — but we still read the axes below as DISABLED controls to drive the
                -- camera. Reading them disabled keeps the mouse from becoming the "active input
                -- device", so the on-screen button hints stay keyboard glyphs (no mouse icon). #charmenu
                DisableControlAction(0, 1, true)    -- INPUT_LOOK_LR (mouse X)
                DisableControlAction(0, 2, true)    -- INPUT_LOOK_UD (mouse Y)
                DisableControlAction(0, 24, true)   -- INPUT_ATTACK  (left mouse)
                DisableControlAction(0, 25, true)   -- INPUT_AIM     (right mouse)
                DisableControlAction(0, 69, true)   -- INPUT_VEH_ATTACK (extra mouse)
                DisableControlAction(0, 142, true)  -- INPUT_MELEE_ATTACK_ALTERNATE (mouse 3)

                -- Mouse-look orbit: mouse MOVEMENT rotates the camera around the ped.
                if selectCam and DoesCamExist(selectCam) then
                    local mx = GetDisabledControlNormal(0, 1)
                    local my = GetDisabledControlNormal(0, 2)
                    camOrbit.angle = (camOrbit.angle + mx * 5.0) % 360.0
                    camOrbit.pitch = math.max(-20.0, math.min(50.0, camOrbit.pitch - my * 3.0))
                    local a   = math.rad(camOrbit.angle)
                    local p   = math.rad(camOrbit.pitch)
                    local dxz = camOrbit.dist * math.cos(p)
                    local cx  = PED_POS.x + dxz * math.sin(a)
                    local cy  = PED_POS.y + dxz * math.cos(a)
                    local cz  = PED_POS.z + 1.0 + camOrbit.dist * math.sin(p)
                    SetCamCoord(selectCam, cx, cy, cz)
                    PointCamAtCoord(selectCam, PED_POS.x, PED_POS.y, PED_POS.z + 1.0)
                    SetCamActive(selectCam, true)
                    RenderScriptCams(true, false, 0, true, false)
                end


                local coords = GetEntityCoords(ped)
                if #(coords - PED_POS) > 2.0 then
                    SetEntityCoords(ped, PED_POS.x, PED_POS.y, PED_POS.z, false, false, false, false)
                    SetEntityHeading(ped, PED_HEADING)
                end


                DrawLightWithRange(PED_POS.x, PED_POS.y + 1.2, PED_POS.z + 1.1, 255, 255, 255, 6.0, 7.5)


                DrawLightWithRange(PED_POS.x + 1.0, PED_POS.y + 0.3, PED_POS.z + 0.5, 190, 220, 255, 4.0, 4.0)


                DrawLightWithRange(PED_POS.x - 0.5, PED_POS.y - 1.2, PED_POS.z + 0.9, 255, 235, 190, 4.5, 5.0)


            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)
