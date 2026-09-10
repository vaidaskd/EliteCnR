CnR = CnR or {}
CnR.SafeZone = CnR.SafeZone or {}

-- Robbers cannot use weapons or fight inside police stations.
-- Exception: robbers serving a jail sentence may fight (melee only;
-- jail.lua already removes all weapons from jailed players).
-- minZ: only trigger when player z is above this floor level (keeps the zone from reaching
-- down into tunnels/sewers under the building). It must sit BELOW the lowest interior floor
-- so the ground-level cells & garage are covered too — the 3D radius keeps it building-sized.
-- Mission Row PD: main floor z≈30.7, cells/garage z≈24.9–25.7 → minZ 23.5 (covers both levels)
-- Vespucci PD:    interior z≈15-19, but its underground garage (floors 0/-1/below) drops to
--                 roughly z≈-2..4, so minZ must go negative to keep those levels gun-free.
local GUN_FREE_ZONES = {
    { label = 'Mission Row PD', center = vec3(450.0, -994.0, 27.0),    radius = 38.0, minZ = 23.5 },
    { label = 'Vespucci PD',    center = vec3(-1082.0, -818.0, 12.0),  radius = 46.0, minZ = -8.0 },
}

local BLOCKED_CONTROLS = {
    24,  -- attack / punch
    25,  -- attack 2
    37,  -- detonate
    47,  -- aim weapon
    58,  -- aim weapon (alt)
    140, -- melee attack 1
    141, -- melee attack 2
    142, -- melee attack light
    143, -- melee attack heavy
}

local function inGunFreeZone(pos, _ped)
    for _, zone in ipairs(GUN_FREE_ZONES) do
        if #(pos - zone.center) <= zone.radius and pos.z >= zone.minZ then
            return true, zone.label
        end
    end
    return false
end

local wasInZone = false

-- Draw each safe (gun-free) zone as a translucent green circle on the map/minimap.
local zoneBlips = {}
CreateThread(function()
    for _, zone in ipairs(GUN_FREE_ZONES) do
        local b = AddBlipForRadius(zone.center.x, zone.center.y, zone.center.z, zone.radius)
        SetBlipColour(b, 2)       -- green
        SetBlipAlpha(b, 128)      -- translucent fill
        SetBlipAsShortRange(b, false)
        zoneBlips[#zoneBlips + 1] = b
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, b in ipairs(zoneBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
end)

CreateThread(function()
    while true do
        local side = CnR.State and CnR.State.side
        if side == CnR.Sides.ROBBER then
            local ped = PlayerPedId()
            local pos  = GetEntityCoords(ped)
            local inside, label = inGunFreeZone(pos, ped)

            if inside then
                local isJailed = CnR.Jail and CnR.Jail.isJailed and CnR.Jail.isJailed()

                if not wasInZone and not isJailed then
                    wasInZone = true
                    if CnR.NativeUI and CnR.NativeUI.notify then
                        CnR.NativeUI.notify('~r~GUN-FREE ZONE~w~  ' .. (label or 'Police Station') .. ' — no weapons or fighting.')
                    end
                end

                if not isJailed then
                    DisablePlayerFiring(PlayerId(), true)
                    for _, ctrl in ipairs(BLOCKED_CONTROLS) do
                        DisableControlAction(0, ctrl, true)
                    end
                end
                -- Jailed robbers inside cells: no extra restriction applied here.
                -- jail.lua removes their weapons every frame, so they can only melee.

                Wait(0)
            else
                if wasInZone then
                    wasInZone = false
                end
                Wait(250)
            end
        else
            wasInZone = false
            Wait(500)
        end
    end
end)
