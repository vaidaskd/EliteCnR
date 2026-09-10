CnR = CnR or {}

local spawned = {}

local function loadModel(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 100 do Wait(50); t = t + 1 end
    return HasModelLoaded(hash) and hash or nil
end

local function spawnAmbientVehicle(entry)
    local model = entry.model
    local pos = entry.pos
    local hash = loadModel(model)
    if not hash then return end

    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
    local veh = CreateVehicle(hash, pos.x, pos.y, pos.z, pos.w or 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not veh or veh == 0 then return end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleEngineOn(veh, false, true, false)
    SetVehicleDirtLevel(veh, math.random() * 8.0)
    FreezeEntityPosition(veh, false)
    spawned[#spawned + 1] = veh
end

local function clearAmbient()
    for _, veh in ipairs(spawned) do
        if DoesEntityExist(veh) then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteVehicle(veh)
        end
    end
    spawned = {}
end

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(5000)

    local cfg = Config and Config.AmbientVehicles
    if not cfg or not cfg.models or not cfg.spawns then return end

    for _, pos in ipairs(cfg.spawns) do
        local model = cfg.models[math.random(#cfg.models)]
        spawnAmbientVehicle({ model = model, pos = pos })
        Wait(50)
    end

    CnR.Util.log('info', 'spawned %d ambient vehicles', #spawned)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearAmbient()
end)

-- A stray GTA-generated vehicle keeps parking itself at this exact spot (a vehicle generator
-- node — there's no spawner in our config/scripts). Two prongs: (1) tell the engine to stop
-- generating vehicles in this area, and (2) delete any EMPTY, UNOWNED car that still appears
-- there. We scan the vehicle pool directly — GetClosestVehicle silently skips some vehicles
-- (the same bug that broke F/G), which is why the old cleanup kept missing it. #5
CreateThread(function()
    local junk = vector3(1224.5103, 886.7607, 12.2587)
    while true do
        Wait(1500)
        local myPed = PlayerPedId()
        if myPed ~= 0 and #(GetEntityCoords(myPed) - junk) < 150.0 then
            -- clear any vehicle the parked-car generator drops in a small box around the spot
            RemoveVehiclesFromGeneratorsInArea(junk.x - 8.0, junk.y - 8.0, junk.z - 8.0,
                                               junk.x + 8.0, junk.y + 8.0, junk.z + 8.0)
            local myVeh = GetVehiclePedIsIn(myPed, false)
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if veh ~= 0 and veh ~= myVeh and #(GetEntityCoords(veh) - junk) < 5.0
                    and GetPedInVehicleSeat(veh, -1) == 0 then   -- empty
                    local owned = nil
                    pcall(function() owned = Entity(veh).state and Entity(veh).state.cnrOwnedBy end)
                    if not owned then   -- never delete a player's claimed car parked here
                        if NetworkGetEntityIsNetworked(veh) then NetworkRequestControlOfEntity(veh) end
                        SetEntityAsMissionEntity(veh, true, true)
                        DeleteVehicle(veh)
                    end
                end
            end
        end
    end
end)
