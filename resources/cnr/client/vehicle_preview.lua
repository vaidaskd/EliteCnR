

CnR = CnR or {}
CnR.VehiclePreview = CnR.VehiclePreview or {}

local previewVeh = nil
local previewCam = nil
local lastModel = nil
local session = nil
local debounceHandle = nil

local PREVIEW_DISTANCE = 6.0
local DEBOUNCE_MS = 220

local function resolveBay(context)
    if context == 'dealership' and Config and Config.Dealership and Config.Dealership.previewBay then
        return Config.Dealership.previewBay
    end
    if context == 'yard' then
        -- Prefer the garage NPC the player is actually standing at; fall back to
        -- their chosen spawn station, then Mission Row.
        local station = (CnR.State and (CnR.State.yardStation or CnR.State.station)) or 'missionRow'
        local heliPad = Config and Config.HeliPadFor and Config.HeliPadFor(station)
        if heliPad then return heliPad end
        local st = Config and Config.PoliceStations and Config.PoliceStations[station]
        if st and st.vehiclePreview then return st.vehiclePreview end
        if Config and Config.PoliceStations and Config.PoliceStations.missionRow then
            return Config.PoliceStations.missionRow.vehiclePreview
        end
    end
    return nil
end

local function setupCamera(anchor)
    if previewCam and DoesCamExist(previewCam) then
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    local cx = anchor.x - 4.5
    local cy = anchor.y - 4.5
    local cz = anchor.z + 1.6
    previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', cx, cy, cz, -8.0, 0.0, 45.0, 50.0, false, 0)
    PointCamAtCoord(previewCam, anchor.x, anchor.y, anchor.z + 0.5)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 0, true, false)
end

local function clearCamera()
    if previewCam and DoesCamExist(previewCam) then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
end

local function deletePreview()
    if previewVeh and DoesEntityExist(previewVeh) then
        SetEntityAsMissionEntity(previewVeh, true, true)
        DeleteVehicle(previewVeh)
    end
    previewVeh = nil
    lastModel = nil
end

local function cancelPendingLoad()
    if session then
        session.loadId = (session.loadId or 0) + 1
    end
end

-- Force a fixed livery AND/OR paint color on vehicles that otherwise spawn with a random
-- one. Livery index comes from Config.VehicleLivery; paint {primary,secondary} from
-- Config.VehicleColor. Keeps preview and the real spawn looking identical every time.
function CnR.VehiclePreview.applyLivery(veh, model)
    if not (veh and DoesEntityExist(veh) and model) then return end
    model = tostring(model):lower()
    SetVehicleModKit(veh, 0)

    local idx = Config and Config.VehicleLivery and Config.VehicleLivery[model]
    if idx ~= nil then
        if (GetVehicleLiveryCount(veh) or 0) > 0 then SetVehicleLivery(veh, idx) end
        if (GetNumVehicleMods(veh, 48) or 0) > 0 then SetVehicleMod(veh, 48, idx, false) end
    end

    local col = Config and Config.VehicleColor and Config.VehicleColor[model]
    if col then
        SetVehicleColours(veh, col[1] or 0, col[2] or col[1] or 0)
    end
end

local function configurePreview(veh, anchor, model)
    SetEntityAsMissionEntity(veh, true, true)
    SetEntityCoords(veh, anchor.x, anchor.y, anchor.z, false, false, false, false)
    SetEntityHeading(veh, anchor.w or anchor.h or 0.0)
    FreezeEntityPosition(veh, true)
    SetEntityInvincible(veh, true)
    SetEntityCollision(veh, false, false)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleEngineOn(veh, false, true, false)
    SetVehicleLights(veh, 2)
    SetVehicleNumberPlateText(veh, 'PREVIEW')
    CnR.VehiclePreview.applyLivery(veh, model)
end

local function loadModelAsync(model, loadId)
    local hash = (type(model) == 'string') and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 120 do
        if not session or session.loadId ~= loadId then return nil end
        Wait(0)
        tries = tries + 1
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

function CnR.VehiclePreview.clear()
    debounceHandle = nil
    cancelPendingLoad()
    deletePreview()
    clearCamera()
    session = nil
end

function CnR.VehiclePreview.beginSession(context)
    CnR.VehiclePreview.clear()
    local bay = resolveBay(context)
    if not bay then
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local yaw = math.rad(GetEntityHeading(ped))
        bay = vec4(
            pCoords.x - math.sin(yaw) * PREVIEW_DISTANCE,
            pCoords.y + math.cos(yaw) * PREVIEW_DISTANCE,
            pCoords.z,
            (GetEntityHeading(ped) + 180.0) % 360.0
        )
    end
    session = {
        anchor = bay,
        loadId = 0,
        context = context,
    }
    setupCamera(bay)

    -- Keep ambient/emergency helicopters (e.g. the air ambulance that GTA spawns on
    -- rooftop helipads) off the preview pad, so the fixed camera only ever frames our
    -- own police helicopter. The global ambient sweep only runs every 2s, which leaves
    -- a window where a stray heli is visible in the preview shot.
    local mySession = session
    CreateThread(function()
        local pad = vector3(mySession.anchor.x, mySession.anchor.y, mySession.anchor.z)
        while session == mySession do
            local vehicles = GetGamePool('CVehicle')
            for i = 1, #vehicles do
                local veh = vehicles[i]
                -- Use IsThisModelAHeli (not vehicleClass) so an ambient air-ambulance
                -- mis-classed as "Emergency" is still caught and removed.
                if veh ~= previewVeh and DoesEntityExist(veh)
                    and IsThisModelAHeli(GetEntityModel(veh))
                    and #(GetEntityCoords(veh) - pad) < 60.0 then
                    SetEntityAsMissionEntity(veh, true, true)
                    SetEntityCoords(veh, pad.x, pad.y, pad.z - 200.0, false, false, false, false)
                    DeleteEntity(veh)
                    DeleteVehicle(veh)
                end
            end
            -- Run every frame so an ambient air-ambulance is removed before it ever
            -- renders in the fixed preview shot (it spawns shortly after the menu opens).
            Wait(0)
        end
    end)
end

function CnR.VehiclePreview.queue(model)
    if not session or type(model) ~= 'string' or model == '' then return end
    if model == lastModel and previewVeh and DoesEntityExist(previewVeh) then return end

    cancelPendingLoad()
    local loadId = session.loadId
    local anchor = session.anchor

    CreateThread(function()
        local hash = loadModelAsync(model, loadId)
        if not hash or not session or session.loadId ~= loadId then
            if hash then SetModelAsNoLongerNeeded(hash) end
            return
        end

        deletePreview()
        RequestCollisionAtCoord(anchor.x, anchor.y, anchor.z)

        local veh = CreateVehicle(hash, anchor.x, anchor.y, anchor.z, anchor.w or 0.0, false, false)
        SetModelAsNoLongerNeeded(hash)
        if not session or session.loadId ~= loadId then
            if veh and veh ~= 0 then DeleteVehicle(veh) end
            return
        end
        if not veh or veh == 0 then return end

        previewVeh = veh
        configurePreview(previewVeh, anchor, model)
        lastModel = model
    end)
end

function CnR.VehiclePreview.bindMenu(menu, context)
    if not menu then return end

    CnR.VehiclePreview.beginSession(context)

    local function runPreview(index)
        if not menu:Visible() or not session then return end
        local item = menu.Items and menu.Items[index]
        if item and item._model then
            CnR.VehiclePreview.queue(item._model)
        end
    end

    local function schedulePreview(index, immediate)
        debounceHandle = nil
        if immediate then
            runPreview(index)
            return
        end
        local captured = index
        debounceHandle = true
        SetTimeout(DEBOUNCE_MS, function()
            debounceHandle = nil
            runPreview(captured)
        end)
    end

    menu.OnIndexChange = function(_, index)
        schedulePreview(index, false)
    end

    menu.OnMenuClosed = function()
        CnR.VehiclePreview.clear()
    end

    schedulePreview(menu:CurrentSelection(), true)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    CnR.VehiclePreview.clear()
end)
