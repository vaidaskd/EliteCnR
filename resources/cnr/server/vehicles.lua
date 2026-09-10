CnR          = CnR          or {}
CnR.Vehicles = CnR.Vehicles or {}

local cooldownUntil = {}

local function yardFor(profile, rank, station)
    -- Helicopters spawn on the air-support station's rooftop helipad.
    local heliPad = Config and Config.HeliPadFor and Config.HeliPadFor(station)
    if heliPad then return heliPad end
    local yards = (Config and Config.VehicleYards) or {}
    local fallback = yards.missionRow or vec4(452.0, -1019.0, 28.1, 90.0)
    -- Prefer the garage the player interacted with, then their spawn station.
    station = station or (profile and profile.station)
    if station and yards[station] then
        return yards[station]
    end
    return fallback
end

function CnR.Vehicles.GetCooldownRemaining(src)
    local until_ = cooldownUntil[src] or 0
    local now = os.time()
    if until_ > now then return until_ - now end
    return 0
end

local function notify(src, kind, text)
    TriggerClientEvent('cnr:client:notify', src, { kind = kind, text = text })
end

RegisterNetEvent('cnr:server:requestVehicle', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local model = tostring(payload.model or '')
    if model == '' then return end

    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then
        notify(src, 'error', 'Only cops can request vehicles')
        return
    end

    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return end
    local profile = CnR.Persistence.GetProfile(id)

    -- Credit cost: deduct on spawn. No credits -> can't spawn a new one (an existing
    -- vehicle already out in the world is unaffected).
    local label = CnR.AutoVehicleLabels and CnR.AutoVehicleLabels[model] or nil
    local cost  = (CnR.Ranks and CnR.Ranks.VehicleCreditCost and CnR.Ranks.VehicleCreditCost(model, label)) or 0
    if (profile.credits or 0) < cost then
        notify(src, 'error', ('Not enough credits (%d needed)'):format(cost))
        return
    end

    local remaining = CnR.Vehicles.GetCooldownRemaining(src)
    if remaining > 0 then
        notify(src, 'error', ('Vehicle cooldown active: %ds'):format(remaining))
        return
    end

    -- Charge the credits now that the spawn is going through.
    if cost > 0 and not (CnR.Ranks and CnR.Ranks.SpendCredits and CnR.Ranks.SpendCredits(src, cost)) then
        notify(src, 'error', ('Not enough credits (%d needed)'):format(cost))
        return
    end

    local cd = (Config and Config.VehicleCooldownSec) or 120
    cooldownUntil[src] = os.time() + cd

    local station = payload.station
    local validHeli = Config and Config.HeliPadFor and Config.HeliPadFor(station) ~= nil
    if station ~= 'missionRow' and station ~= 'vespucci' and not validHeli then station = nil end
    local yard = yardFor(profile, nil, station)
    TriggerClientEvent('cnr:client:spawnVehicle', src, {
        model  = model,
        coords = { x = yard.x, y = yard.y, z = yard.z, h = yard.w or yard.h or 90.0 },
    })
end)

AddEventHandler('playerDropped', function()
    cooldownUntil[source] = nil
end)

-- ── Idle-vehicle cleanup ──────────────────────────────────────────────────────
-- Any vehicle a player has driven gets a cnrOwnedBy owner tag (set client-side). Once
-- such a vehicle has sat with no player inside for an hour, delete it so abandoned /
-- hijacked cars don't pile up around the map. Ambient traffic (never driven, no owner
-- tag) is left to the engine to stream out on its own.
local IDLE_LIMIT_MS = 60 * 60 * 1000   -- 1 hour
local emptySince = {}

CreateThread(function()
    while true do
        Wait(60000)   -- sweep once a minute
        local now = GetGameTimer()

        -- Which vehicles currently have a player aboard?
        local occupied = {}
        for _, pid in ipairs(GetPlayers()) do
            local pp = GetPlayerPed(tonumber(pid))
            if pp and pp ~= 0 then
                local v = GetVehiclePedIsIn(pp, false)
                if v and v ~= 0 then occupied[v] = true end
            end
        end

        for _, veh in ipairs(GetAllVehicles()) do
            local owned = false
            pcall(function() owned = Entity(veh).state and Entity(veh).state.cnrOwnedBy ~= nil end)
            if owned then
                if occupied[veh] then
                    emptySince[veh] = nil                     -- attended → reset timer
                elseif not emptySince[veh] then
                    emptySince[veh] = now                     -- just became empty
                elseif now - emptySince[veh] >= IDLE_LIMIT_MS then
                    emptySince[veh] = nil
                    if DoesEntityExist(veh) then DeleteEntity(veh) end
                end
            else
                emptySince[veh] = nil
            end
        end
    end
end)
