CnR = CnR or {}
CnR.Jail = CnR.Jail or {}

local jailed          = false
local secondsLeft     = 0
local currentFacility = nil   -- 'missionRow' | 'vespucci' | 'bolingbroke'
local currentCell     = nil

-- Exposed so the death/respawn loop leaves jailed players alone (the jail loop
-- handles their death by respawning them at their own cell).
function CnR.Jail.IsJailed() return jailed end

local prisonerSkin = nil  -- restore info captured when the jumpsuit is applied

local function loadModel(model)
    local hash = (type(model) == 'string') and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 200 do Wait(25); tries = tries + 1 end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

-- Dress the player as a prisoner regardless of their chosen skin. The jumpsuit
-- component indices only exist on the freemode peds, so for the street-ped robber
-- skins we temporarily swap to a gender-matched freemode model (restored on release).
local function applyPrisonerSkin()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    SetPedArmour(ped, 0)

    -- Already a prisoner (e.g. died and got re-jailed): re-apply the jumpsuit but
    -- keep the original appearance we saved the first time.
    if prisonerSkin then
        if CnR.Util and CnR.Util.ApplyPrisonerClothes then
            CnR.Util.ApplyPrisonerClothes(PlayerPedId())
        end
        return
    end

    local model = GetEntityModel(ped)
    local isFreemode = (model == `mp_m_freemode_01` or model == `mp_f_freemode_01`)

    if isFreemode then
        -- Snapshot clothing components so the exact look is restored on release.
        local comps = {}
        for c = 0, 11 do
            comps[c] = { d = GetPedDrawableVariation(ped, c), t = GetPedTextureVariation(ped, c) }
        end
        prisonerSkin = { mode = 'components', comps = comps }
        if CnR.Util and CnR.Util.ApplyPrisonerClothes then
            CnR.Util.ApplyPrisonerClothes(ped)
        end
    else
        -- Street ped: remember it, swap to freemode, then dress as a prisoner.
        prisonerSkin = { mode = 'model', model = model }
        local female = not IsPedMale(ped)
        local hash = loadModel(female and 'mp_f_freemode_01' or 'mp_m_freemode_01')
        if hash then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            Wait(50)
        end
        if CnR.Util and CnR.Util.ApplyPrisonerClothes then
            CnR.Util.ApplyPrisonerClothes(PlayerPedId())
        end
    end
end

-- Put the player's original appearance back when they leave jail.
local function restorePrisonerSkin()
    local state = prisonerSkin
    if not state then return end
    prisonerSkin = nil
    if state.mode == 'model' then
        local hash = loadModel(state.model)
        if hash then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
        end
    elseif state.mode == 'components' and state.comps then
        local ped = PlayerPedId()
        for c = 0, 11 do
            local v = state.comps[c]
            if v then SetPedComponentVariation(ped, c, v.d, v.t, 0) end
        end
    end
end

-- Re-assert the jumpsuit while serving. Death/respawn or other resources (e.g.
-- vMenu's respawn appearance) can wipe it, so we keep putting it back. If something
-- reverted the player to a non-freemode model, swap back to freemode first.
local function maintainPrisonerSkin()
    if not prisonerSkin then return end
    local ped = PlayerPedId()
    if ped == 0 or IsEntityDead(ped) then return end
    local model = GetEntityModel(ped)
    if model ~= `mp_m_freemode_01` and model ~= `mp_f_freemode_01` then
        local female = not IsPedMale(ped)
        local hash = loadModel(female and 'mp_f_freemode_01' or 'mp_m_freemode_01')
        if hash then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            Wait(50)
        end
    end
    if CnR.Util and CnR.Util.ApplyPrisonerClothes then
        CnR.Util.ApplyPrisonerClothes(PlayerPedId())
    end
end

local function pickMissionRowCell()
    local cells = Config and Config.Jail and Config.Jail.missionRowCells
    if type(cells) == 'table' and cells[1] then
        return cells[math.random(#cells)]
    end
    return vec4(459.3768, -1001.5601, 24.9149, 266.4718)
end

local function pickVespucciCell()
    local cells = Config and Config.Jail and Config.Jail.vespucciCells
    if type(cells) == 'table' and cells[1] then
        return cells[math.random(#cells)]
    end
    return vec4(-1087.0, -849.0, 19.0, 90.0)
end

local function pickBolingbrokeCell()
    local cells = Config and Config.Jail and Config.Jail.bolingbrokeCells
    if type(cells) == 'table' and cells[1] then
        return cells[math.random(#cells)]  -- equal chance for every cell spot
    end
    return Config and Config.Jail and Config.Jail.bolingbroke
end

local function teleport(coords)
    if not coords then return end
    local me = PlayerPedId()
    local isTable = type(coords) == 'table'
    local x = coords.x or (isTable and coords[1])
    local y = coords.y or (isTable and coords[2])
    local z = coords.z or (isTable and coords[3])
    local h = coords.w or coords.h or (isTable and coords[4]) or 0.0
    if not x or not y or not z then return end
    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    local timeout = GetGameTimer() + 2500
    while not HasCollisionLoadedAroundEntity(me) and GetGameTimer() < timeout do Wait(0) end
    SetEntityCoords(me, x + 0.0, y + 0.0, z + 0.0, false, false, false, false)
    SetEntityHeading(me, h + 0.0)
end

local function jailAnchor()
    if currentFacility == 'bolingbroke' then
        local p = Config and Config.Jail and Config.Jail.bolingbroke
        return p and vec3(p.x, p.y, p.z), 145.0
    end
    if currentFacility == 'vespucci' then
        local cell = currentCell or pickVespucciCell()
        return vec3(cell.x, cell.y, cell.z), 15.0
    end
    -- default: missionRow
    local cell = currentCell or pickMissionRowCell()
    return vec3(cell.x, cell.y, cell.z), 10.0
end

function CnR.Jail.isJailed()
    return jailed
end

RegisterNetEvent('cnr:client:goToJail', function(payload)
    if type(payload) ~= 'table' then return end
    local s = tonumber(payload.seconds) or 0
    if s <= 0 then return end

    local facility = payload.facility
    local threshold = (Config and Config.JailTime and Config.JailTime.lowJailThreshold) or 180
    if facility ~= 'missionRow' and facility ~= 'vespucci' and facility ~= 'bolingbroke' then
        facility = (s <= threshold) and 'missionRow' or 'bolingbroke'
    end

    -- Redundant re-send: the reconnect flow fires goToJail twice (main.lua + the delayed
    -- maybeReJail). If we're already serving in this facility, just refresh the timer — do
    -- NOT teleport, or the player gets yanked back to the spawn spot after they've moved. #jail-resume
    if jailed and currentFacility == facility then
        secondsLeft = s
        return
    end

    jailed = true
    secondsLeft = s
    currentFacility = facility

    -- If a reconnect loadout (custom skin apply) is still in flight, wait for it to finish so
    -- the jail teleport + jumpsuit run AFTER the face/hair is set, never racing it. That race
    -- was what sometimes reset the player's appearance on reconnect. #skinfix
    local waitUntil = GetGameTimer() + 6000
    while CnR._applyingLoadout and GetGameTimer() < waitUntil do Wait(50) end

    DoScreenFadeOut(200)
    Wait(250)

    -- If the player is still dead (WASTED screen), resurrect in-place before teleporting.
    local me = PlayerPedId()
    if IsEntityDead(me) then
        NetworkResurrectLocalPlayer(0.0, 0.0, 0.0, 0.0, true, false)
        Wait(100)
        me = PlayerPedId()
    end

    -- Reconnect resume: if the server sent the exact spot the player was at when they
    -- disconnected while jailed, drop them straight back there instead of a fresh random
    -- cell. Fresh jailings (arrests) send no resume, so they still get a cell. #jail-resume
    local resume = payload.resume
    if type(resume) == 'table' and resume.x and resume.y and resume.z then
        currentCell = vec3(resume.x, resume.y, resume.z)
        teleport({ x = resume.x, y = resume.y, z = resume.z, h = resume.h or resume.w or 0.0 })
    elseif facility == 'missionRow' then
        currentCell = pickMissionRowCell()
        teleport(currentCell)
    elseif facility == 'vespucci' then
        currentCell = pickVespucciCell()
        teleport(currentCell)
    else -- bolingbroke
        currentCell = pickBolingbrokeCell()
        teleport(currentCell)
    end

    FreezeEntityPosition(me, false)
    SetEntityMaxHealth(me, 200)
    SetEntityHealth(me, GetEntityMaxHealth(me))
    SetEntityInvincible(me, false)
    SetPlayerControl(PlayerId(), true, 0)
    -- Only Bolingbroke (long sentences) dresses inmates in the prison jumpsuit.
    -- The short holding cells (Mission Row / Vespucci) keep the player's own clothes.
    if facility == 'bolingbroke' then
        applyPrisonerSkin()
    else
        RemoveAllPedWeapons(PlayerPedId(), true)
        SetPedArmour(PlayerPedId(), 0)
    end
    DoScreenFadeIn(400)
    -- Persist this jail position immediately so even a disconnect right after being jailed
    -- (before the 30s auto-sync) resumes here on reconnect. #jail-resume
    if CnR.Position and CnR.Position.sync then CnR.Position.sync() end
end)

RegisterNetEvent('cnr:client:jailTimeUpdate', function(payload)
    if type(payload) ~= 'table' then return end
    secondsLeft = tonumber(payload.seconds) or 0
    if secondsLeft <= 0 and jailed then
        jailed = false
        TriggerEvent('cnr:client:jailReleased')
        -- Only fade if we have a prison outfit to swap back (Bolingbroke inmates).
        local needRestore = prisonerSkin ~= nil
        if needRestore then
            DoScreenFadeOut(200)
            Wait(250)
        end
        if currentFacility == 'bolingbroke' then
            teleport(Config.Jail.bolingbrokeRelease)
        elseif currentFacility == 'vespucci' then
            teleport(Config.Jail.vespucciRelease
                or vec4(-1097.0, -836.5, 19.0, 305.0))
        else -- missionRow (default)
            teleport(Config.Jail.missionRowRelease
                or (Config.PoliceStations and Config.PoliceStations.missionRow
                    and Config.PoliceStations.missionRow.exit
                    and Config.PoliceStations.missionRow.exit.exterior))
        end
        local me = PlayerPedId()
        ClearPlayerWantedLevel(PlayerId())
        RemoveAllPedWeapons(me, true)
        -- Don't restore from the local snapshot (it could reinstate a wrong/default
        -- model like Michael). The server re-applies the player's saved skin via
        -- applyLoadout on release — just drop the prisoner state so the jumpsuit
        -- maintainer stops fighting it.
        prisonerSkin = nil
        currentFacility = nil
        currentCell     = nil
        if needRestore then
            DoScreenFadeIn(400)
        end
    end
end)

CreateThread(function()
    local lastMaintain = 0
    while true do
        Wait(0)
        if jailed and secondsLeft > 0 then
            local mins = math.floor(secondsLeft / 60)
            local secs = secondsLeft % 60
            SetTextFont(4); SetTextScale(0.6, 0.6); SetTextColour(255, 230, 80, 230); SetTextOutline()
            SetTextCentre(true)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(
                string.format('JAIL  %02d:%02d', mins, secs)
            )
            EndTextCommandDisplayText(0.5, 0.02)

            DisableControlAction(0, 47, true)
            DisableControlAction(0, 58, true)

            local ped = PlayerPedId()
            RemoveAllPedWeapons(ped, true)

            if IsEntityDead(ped) then
                -- Died while serving time: respawn at the SAME cell they were in.
                local cell = currentCell
                    or (currentFacility == 'vespucci' and pickVespucciCell())
                    or (currentFacility == 'missionRow' and pickMissionRowCell())
                    or pickBolingbrokeCell()
                DoScreenFadeOut(200)
                Wait(250)
                local h = (cell and (cell.w or cell.h)) or 0.0
                NetworkResurrectLocalPlayer(cell.x + 0.0, cell.y + 0.0, cell.z + 0.0, h + 0.0, true, false)
                Wait(100)
                local me = PlayerPedId()
                ClearPedTasksImmediately(me)
                SetEntityHealth(me, GetEntityMaxHealth(me))
                SetEntityInvincible(me, false)
                SetPlayerControl(PlayerId(), true, 0)
                RemoveAllPedWeapons(me, true)
                maintainPrisonerSkin()  -- re-dress as a prisoner after respawning
                DoScreenFadeIn(300)
            elseif currentFacility ~= 'bolingbroke' then
                -- Holding cells stay contained. The open Bolingbroke prison does NOT
                -- pull inmates back for wandering out of bounds.
                local anchor, radius = jailAnchor()
                if anchor and #(GetEntityCoords(ped) - anchor) > radius then
                    if currentFacility == 'vespucci' then
                        teleport(currentCell or pickVespucciCell())
                    else
                        teleport(currentCell or pickMissionRowCell())
                    end
                end
            end

            -- Keep the prison jumpsuit on despite death/respawn or other resources
            -- resetting the player's appearance.
            if GetGameTimer() - lastMaintain > 1500 then
                lastMaintain = GetGameTimer()
                maintainPrisonerSkin()
            end
        else
            Wait(500)
        end
    end
end)
