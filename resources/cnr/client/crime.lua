CnR = CnR or {}
CnR.Crime = CnR.Crime or {}

CnR.State = CnR.State or {}
CnR.State.wanted = false

RegisterNetEvent('cnr:client:setWanted', function(payload)
    if type(payload) ~= 'table' then return end
    CnR.State.wanted = payload.wanted and true or false
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('cnrWanted', CnR.State.wanted, true)
    end
end)

-- ============================================================================
--  FRIENDLY FIRE — full PvP for everyone, with cop↔cop damage neutralised.
--
--  Friendly fire stays ON globally so EVERY normal case works: robber↔robber,
--  robber↔cop and cop↔robber all deal damage and can kill. (Relationship-group
--  tricks were removed — they were silently blocking ALL player damage.)
--
--  Cop↔cop is the only protected case. A cop ped:
--    • has critical hits disabled (no one-shot headshot kill), and
--    • is healed back to full the instant another COP damages it.
--  Robbers are unaffected, so they still down cops normally.
-- ============================================================================
NetworkSetFriendlyFireOption(true)

local lastCopHit = 0
-- The cop's health/armour from just BEFORE a cop hit, so we can undo cop-vs-cop damage
-- without granting any free health or armour (the old code reset armour to 100).
local safeHealth, safeArmor = nil, nil

local function attackerIsCop(attacker)
    if not attacker or attacker == 0 then return false end
    if not (IsEntityAPed(attacker) and IsPedAPlayer(attacker)) then return false end
    local pl = NetworkGetPlayerIndexFromPed(attacker)
    if pl == -1 then return false end
    local pst = Player(GetPlayerServerId(pl))
    return pst and pst.state and pst.state.cnrSide == 'cop' or false
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local victim, attacker = args[1], args[2]
    local me = PlayerPedId()
    if victim ~= me then return end
    if CnR.State.side ~= CnR.Sides.COP then return end
    if attackerIsCop(attacker) then
        lastCopHit = GetGameTimer()
        -- Undo the damage by restoring to the values from before the hit (NOT full).
        if safeHealth and safeHealth > 0 then SetEntityHealth(me, safeHealth) end
        if safeArmor then SetPedArmour(me, safeArmor) end
    end
end)

CreateThread(function()
    while true do
        local me = PlayerPedId()
        if CnR.State.side == CnR.Sides.COP and me ~= 0 then
            SetPedSuffersCriticalHits(me, false)   -- no instant headshot kills on cops
            if GetGameTimer() - lastCopHit < 600 then
                -- Hold their pre-hit health/armour for a short window (covers multi-shot
                -- bursts) — no free armour, just the damage from cops undone.
                if safeHealth and safeHealth > 0 then SetEntityHealth(me, safeHealth) end
                if safeArmor then SetPedArmour(me, safeArmor) end
                Wait(0)
            else
                -- Not under cop fire → record current (legit) health/armour every frame.
                safeHealth = GetEntityHealth(me)
                safeArmor  = GetPedArmour(me)
                Wait(0)
            end
        else
            local p = PlayerPedId()
            if p ~= 0 then SetPedSuffersCriticalHits(p, true) end
            safeHealth, safeArmor = nil, nil
            Wait(400)
        end
    end
end)

-- ============================================================================
--  KILL PENALTIES.
--  Player kills are detected victim-side in client/respawn.lua (GetPedSourceOfDeath)
--  and penalised in server/crime.lua. NPC (pedestrian) kills can't be reported by
--  the victim, so we detect them attacker-side here: collect peds the local player
--  damages, then confirm the death + source before reporting once per ped.
-- ============================================================================
local damagedPeds = {}   -- [pedHandle] = hostile(bool) — NPCs the local player has damaged
local function isAnimal(ped)
    return not IsPedHuman(ped)
end

-- Was this NPC acting aggressively toward me? (In hostile zones the red blip appears
-- and gang members / civilians attack on sight — killing those in self-defence must
-- NOT be penalised.)
local function npcIsHostile(ped, myPed)
    if not DoesEntityExist(ped) then return false end
    -- "Aggressive" = the vanilla RED minimap circle (a red blip attached to the ped). Only
    -- those are self-defence and exempt. We deliberately do NOT count combat/aiming state,
    -- because a normal NPC fights back after the cop shoots it — that retaliation must still
    -- cost the cop a credit (the cop started it). Only a PRE-existing red blip is exempt. #4
    local blip = GetBlipFromEntity(ped)
    if blip and blip ~= 0 and DoesBlipExist(blip) and GetBlipColour(blip) == 1 then return true end
    return false
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local victim   = args[1]
    local attacker = args[2]
    local myPed = PlayerPedId()
    -- Attacker is me, OR the vehicle I'm driving (road-kills report the vehicle). #5
    local myVeh = GetVehiclePedIsIn(myPed, false)
    local byMe = (attacker == myPed) or (myVeh ~= 0 and attacker == myVeh)
    if not byMe then return end
    if not victim or victim == 0 or victim == myPed then return end
    if not IsEntityAPed(victim) then return end

    if IsPedAPlayer(victim) then
        -- I damaged another player. If I'm an INNOCENT robber and the victim is a cop,
        -- I just injured an officer → report it (server adds +1 min jail + wanted, once).
        -- Player KILLS are handled victim-side in respawn.lua, so we only do the injury
        -- report here.
        if CnR.State.side == CnR.Sides.ROBBER and not CnR.State.wanted then
            local pl = NetworkGetPlayerIndexFromPed(victim)
            if pl ~= -1 then
                local pst = Player(GetPlayerServerId(pl))
                if pst and pst.state and pst.state.cnrSide == 'cop' then
                    TriggerServerEvent('cnr:server:reportCopShot')
                end
            end
        end
        return
    end

    -- NPC damage from a WEAPON/melee (attacker is ME, not my vehicle). Lock in hostility at
    -- FIRST contact (was it already a red-blip aggressor?). Don't upgrade later, so an innocent
    -- NPC fighting back can't retroactively excuse the cop. Vehicle road-kills are NOT tracked
    -- here — the damage event is unreliable for them, so the scanner below handles those. #4
    if attacker == myPed and damagedPeds[victim] == nil and not isAnimal(victim) then
    damagedPeds[victim] = npcIsHostile(victim, myPed)
end
end)

CreateThread(function()
    while true do
        Wait(300)
        local myPed = PlayerPedId()
        for ped, hostile in pairs(damagedPeds) do
            if DoesEntityExist(ped) then
                if IsEntityDead(ped) or GetEntityHealth(ped) <= 0 then
                    -- Only WEAPON/melee kills are reported here (source of death is MY ped).
                    -- Vehicle road-kills are owned solely by the road-kill scanner below, so a
                    -- ped I shot AND ran over is never counted twice (that was the +2 min bug).
                    -- Only non-hostile NPCs are penalised (self-defence is free). #killfix
                    local src = GetPedSourceOfDeath(ped)
                    if src == myPed and not hostile then
                        TriggerServerEvent('cnr:server:reportNpcKill')
                    end
                    damagedPeds[ped] = nil
                end
            else
                damagedPeds[ped] = nil   -- despawned before we could confirm — skip
            end
        end
    end
end)

-- Road-kills: the damage event fires unreliably for vehicle-vs-ped (especially several in a
-- row), and the body can despawn before the death loop above confirms it — which is why
-- running NPCs over often didn't count. This scanner instead looks directly for any non-player
-- ped whose SOURCE OF DEATH is the vehicle we're driving, and reports each exactly once.
-- Running someone over always counts as murder (no self-defence exemption — you drove into
-- them). #4
local roadKilled = {}
CreateThread(function()
    while true do
        Wait(150)
        local myPed = PlayerPedId()
        local myVeh = (myPed ~= 0) and GetVehiclePedIsIn(myPed, false) or 0
        if myVeh ~= 0 then
            for _, ped in ipairs(GetGamePool('CPed')) do
    if ped ~= 0 and ped ~= myPed and not roadKilled[ped]
        and not IsPedAPlayer(ped)
        and not isAnimal(ped)
        and (IsEntityDead(ped) or GetEntityHealth(ped) <= 0) then
                    local src = GetPedSourceOfDeath(ped)
                    if src == myVeh
                        or (src ~= 0 and IsEntityAVehicle(src) and GetPedInVehicleSeat(src, -1) == myPed) then
                        roadKilled[ped] = true
                        TriggerServerEvent('cnr:server:reportNpcKill')
                    end
                end
            end
        end
        -- Prune a handle once it despawns OR comes back alive. The engine reuses ped handles,
        -- so a fresh living ped can inherit a handle still flagged "reported" — clearing it here
        -- means the next road-kill of a reused handle actually counts instead of being dropped
        -- (that was the "no jail when done in a row" bug). #killfix
        for ped in pairs(roadKilled) do
            if not DoesEntityExist(ped) or GetEntityHealth(ped) > 0 then roadKilled[ped] = nil end
        end
    end
end)

-- (Injuring a cop is detected by the actual-damage handler above, not by aiming.)

-- ============================================================================
--  ROBBER STEALS A POLICE VEHICLE → +1 min jail (once). Server-enforced.
-- ============================================================================
local lastVehicle = 0
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if CnR.State.side ~= CnR.Sides.COP then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and veh ~= lastVehicle and GetPedInVehicleSeat(veh, -1) == ped then
                lastVehicle = veh
                if IsPedInAnyPoliceVehicle(ped) then
                    TriggerServerEvent('cnr:server:reportPoliceCarTheft')
                end
            elseif veh == 0 then
                lastVehicle = 0
            end
        end
    end
end)
