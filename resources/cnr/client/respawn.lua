CnR = CnR or {}

local lastReport = 0
local awaitingRespawn = false

-- Resolve who killed the local player (server id), or 0 if not a player / unknown.
local function killerServerId()
    local ped = PlayerPedId()
    local killer = GetPedSourceOfDeath(ped)
    if not killer or killer == 0 or killer == ped then return 0 end
    -- Road-kill: the source of death can be the VEHICLE → blame its driver. #13
    if IsEntityAVehicle(killer) then
        killer = GetPedInVehicleSeat(killer, -1)
    end
    if killer and killer ~= 0 and killer ~= ped
        and IsEntityAPed(killer) and IsPedAPlayer(killer) then
        local pl = NetworkGetPlayerIndexFromPed(killer)
        if pl ~= -1 then return GetPlayerServerId(pl) end
    end
    return 0
end

local function reportDeath()
    if awaitingRespawn then return end
    if (GetGameTimer() - lastReport) < 1500 then return end
    lastReport = GetGameTimer()
    awaitingRespawn = true
    -- Include the killer so the server can apply jail/wanted penalties (server/crime.lua).
    TriggerServerEvent('cnr:server:reportDeath', { killer = killerServerId() })
end

-- Report only the killer (for the murder penalty) without entering the normal
-- awaiting-respawn flow — used when WE are jailed and the jail loop handles our respawn.
local lastKillerReport = 0
local function reportKillerOnly()
    if (GetGameTimer() - lastKillerReport) < 1500 then return end
    lastKillerReport = GetGameTimer()
    TriggerServerEvent('cnr:server:reportDeath', { killer = killerServerId() })
end

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if ped ~= 0 and IsEntityDead(ped) then
            if CnR.Jail and CnR.Jail.IsJailed and CnR.Jail.IsJailed() then
                -- Killing a prisoner still counts as murder (robber killer +2 min, cop
                -- killer −1 credit). The jail loop respawns us in our cell; we only report
                -- the killer here so they take the penalty. #4
                reportKillerOnly()
            else
                reportDeath()
            end
        end
    end
end)

RegisterNetEvent('cnr:client:applyLoadout', function()
    awaitingRespawn = false
end)
RegisterNetEvent('cnr:client:goToJail', function()
    awaitingRespawn = false
end)
RegisterNetEvent('cnr:client:respawnAck', function()
    awaitingRespawn = false
end)

RegisterNetEvent('cnr:client:revive', function(payload)
    payload = payload or {}
    local ped = PlayerPedId()
    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(
            payload.x or 0.0, payload.y or 0.0, payload.z or 0.0,
            payload.heading or 0.0, true, false
        )
        ped = PlayerPedId()
        ClearPedTasksImmediately(ped)
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then DeleteVehicle(veh) end
    end
    -- Always clear invincibility and restore control regardless of death state.
    -- NetworkResurrectLocalPlayer can leave the player in god-mode if p4 was true;
    -- clearing it here ensures a mortal state before applyLoadout or goToJail takes over.
    SetEntityInvincible(ped, false)
    SetPlayerControl(PlayerId(), true, 0)
end)
