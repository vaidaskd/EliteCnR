CnR = CnR or {}

local function requestModelBlocking(model)
    local hash = (type(model) == 'string') and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 200 do
        Wait(25); tries = tries + 1
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

RegisterNetEvent('cnr:client:spawnVehicle', function(payload)
    if type(payload) ~= 'table' or not payload.model or not payload.coords then return end
    local hash = requestModelBlocking(payload.model)
    if not hash then return end
    local c = payload.coords
    local x = c.x or c[1]; local y = c.y or c[2]; local z = c.z or c[3]
    local heading = c.h or c.heading or 90.0

    local veh = CreateVehicle(hash, x + 0.0, y + 0.0, z + 0.0, heading + 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)

    -- Snap to the road/ground beneath the spawn point so it never falls or floats
    -- if the configured z is slightly off.
    SetVehicleOnGroundProperly(veh)

    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleFixed(veh)
    -- Lock multi-livery vehicles (e.g. Ineos LSPD/Sheriff) to their configured livery.
    if CnR.VehiclePreview and CnR.VehiclePreview.applyLivery then
        CnR.VehiclePreview.applyLivery(veh, payload.model)
    end
    if SetVehicleEngineOn then SetVehicleEngineOn(veh, true, true, false) end
    SetEntityAsMissionEntity(veh, true, true)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if netId and netId ~= 0 then SetNetworkIdCanMigrate(netId, true) end

    local plate = ('LSPD-%03d'):format((GetPlayerServerId(PlayerId()) or 0) % 1000)
    SetVehicleNumberPlateText(veh, plate)


    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    ClearPlayerWantedLevel(PlayerId())
end)

-- (Notifications are handled solely by the single NUI toast in nui.lua. The old
--  duplicate "[CnR]" game-feed post that lived here has been removed.)
