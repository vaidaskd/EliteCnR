

CnR = CnR or {}

local WORLD_DENSITY = 1.2
-- Ambient pedestrian density. Kept modest on purpose: CnR is a city-wide shootout, and every
-- ambient ped that reacts to gunfire fires a networked NETWORK_RESPONDED_TO_THREAT_EVENT.
-- Those accumulate in the fixed rage::netGameEvent pool and, at full density, overflow it
-- (~510 entries) → "Ran out of rage::netGameEvent pool space" crash. #netpool
local PED_DENSITY   = 0.3

local function deleteAmbientVehicles()
    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles do
        local veh = vehicles[i]
        if DoesEntityExist(veh) and not IsEntityAMissionEntity(veh) then
            local model = GetEntityModel(veh)
            local class = GetVehicleClass(veh)
            -- class 15/16 = helis/planes; blimps + the prison bus (pbus) that ambiently
            -- spawns inside Bolingbroke are also cleared. #prison-bus
            if class == 15 or class == 16
                or model == `blimp` or model == `blimp2` or model == `blimp3`
                or model == `pbus` then
                SetEntityAsMissionEntity(veh, true, true)
                DeleteVehicle(veh)
            end
        end
    end
end

CreateThread(function()

    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
    SetGarbageTrucks(false)
    SetRandomBoats(false)
    SetRandomTrains(false)
    SetScenarioTypeEnabled('WORLD_VEHICLE_POLICE_BIKE', false)
    SetScenarioTypeEnabled('WORLD_VEHICLE_POLICE_CAR', false)
    SetScenarioTypeEnabled('WORLD_VEHICLE_POLICE_NEXT_TO_CAR', false)
    SetScenarioTypeEnabled('WORLD_VEHICLE_HELI_LIFEGUARD', false)
    SetScenarioTypeEnabled('WORLD_VEHICLE_MILITARY_PLANES_BIG', false)
    SetScenarioTypeEnabled('WORLD_VEHICLE_MILITARY_PLANES_SMALL', false)

    for i = 1, 15 do
        EnableDispatchService(i, false)
    end

    while true do
        Wait(0)
        SetPedDensityMultiplierThisFrame(PED_DENSITY)
        SetScenarioPedDensityMultiplierThisFrame(PED_DENSITY, PED_DENSITY)
        SetParkedVehicleDensityMultiplierThisFrame(WORLD_DENSITY)
        SetVehicleDensityMultiplierThisFrame(WORLD_DENSITY)
        SetRandomVehicleDensityMultiplierThisFrame(WORLD_DENSITY)

        for i = 1, 15 do
            EnableDispatchService(i, false)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        -- Keep the skies/water clear (aircraft, boats, blimps) but leave ambient
        -- pedestrians and traffic drivers alone so the city stays populated.
        deleteAmbientVehicles()
    end
end)

-- ── netGameEvent pool guard ─────────────────────────────────────────────────────
-- Stop ambient pedestrians (not players, not our mission NPCs) from reacting to gunfire /
-- threats. Blocking their non-temporary events means they no longer emit the networked
-- NETWORK_RESPONDED_TO_THREAT_EVENT that was flooding — and overflowing — the netGameEvent
-- pool and crashing clients. Runs on every client, so the whole session stops producing the
-- flood. Peds still stand around; they just don't panic-broadcast during shootouts. #netpool
CreateThread(function()
    while true do
        Wait(500)
        local peds = GetGamePool('CPed')
        for i = 1, #peds do
            local p = peds[i]
            if DoesEntityExist(p) and not IsPedAPlayer(p) and not IsEntityAMissionEntity(p) then
                SetBlockingOfNonTemporaryEvents(p, true)
                SetPedFleeAttributes(p, 0, false)
            end
        end
    end
end)

-- Remove dogs and cats only (leave birds and other animals). Matches the GTA V dog/cat
-- ped models and deletes them from the ped pool.
local DOG_CAT_MODELS = {
    [`a_c_chop`]=1, [`a_c_chop_02`]=1, [`a_c_husky`]=1, [`a_c_retriever`]=1,
    [`a_c_rottweiler`]=1, [`a_c_shepherd`]=1, [`a_c_poodle`]=1, [`a_c_pug`]=1,
    [`a_c_westy`]=1, [`a_c_cat_01`]=1,
}
CreateThread(function()
    while true do
        Wait(1000)
        local peds = GetGamePool('CPed')
        for i = 1, #peds do
            local p = peds[i]
            if DoesEntityExist(p) and not IsPedAPlayer(p) and DOG_CAT_MODELS[GetEntityModel(p)] then
                SetEntityAsMissionEntity(p, true, true)
                DeleteEntity(p)
            end
        end
    end
end)


CreateThread(function()
    while true do
        Wait(500)
        local pid = PlayerId()
        local side = CnR.State and CnR.State.side
        if side == CnR.Sides.COP then
            if GetPlayerWantedLevel(pid) ~= 0 then
                ClearPlayerWantedLevel(pid)
            end
        end

        SetMaxWantedLevel(0)
        SetPlayerWantedLevel(pid, 0, false)
        SetPlayerWantedLevelNow(pid, false)
    end
end)


local POLICE_MODELS = {
    [`police`]=1, [`police2`]=1, [`police3`]=1, [`police4`]=1,
    [`policeb`]=1, [`policet`]=1, [`sheriff`]=1, [`sheriff2`]=1,
    [`pranger`]=1, [`fbi`]=1, [`fbi2`]=1, [`riot`]=1, [`riot2`]=1,
    [`polmav`]=1, [`policeold1`]=1, [`policeold2`]=1, [`granger`]=1,
}

CreateThread(function()
    while true do
        Wait(500)
        local side = CnR.State and CnR.State.side
        local ped = PlayerPedId()
        if ped ~= 0 then
            local nearVeh = GetClosestVehicle(GetEntityCoords(ped).x, GetEntityCoords(ped).y, GetEntityCoords(ped).z, 6.0, 0, 70)
            if nearVeh ~= 0 and DoesEntityExist(nearVeh) then
                local model = GetEntityModel(nearVeh)
                if POLICE_MODELS[model] then
                    if side == CnR.Sides.COP then
                        SetVehicleDoorsLocked(nearVeh, 1)
                        SetVehicleNeedsToBeHotwired(nearVeh, false)
                        SetVehicleHasBeenOwnedByPlayer(nearVeh, true)
                    else

                        SetVehicleDoorsLocked(nearVeh, 2)
                    end
                end
            end
        end
    end
end)
