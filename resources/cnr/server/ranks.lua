CnR        = CnR        or {}
CnR.Ranks  = CnR.Ranks  or {}

local ARMOR_RANK = { superlight = 1, light = 2, standard = 3, heavy = 4, superheavy = 5 }
local ARMOR_VALUE = { superlight = 20, light = 40, standard = 60, heavy = 80, superheavy = 100 }

local function defaultAmmo(weapon)
    local w = tostring(weapon or '')
    if w == 'WEAPON_NIGHTSTICK' or w == 'WEAPON_FLASHLIGHT' or w == 'WEAPON_STUNGUN'
       or w == 'WEAPON_FIREEXTINGUISHER' or w == 'WEAPON_FLAREGUN'
       or w == 'GADGET_PARACHUTE' or w == 'WEAPON_SMOKEGRENADE' then
        return 1
    end
    if w:find('PISTOL') or w == 'WEAPON_REVOLVER' then return 250 end
    if w:find('SMG') or w:find('RIFLE') or w == 'WEAPON_COMBATPDW'
       or w == 'WEAPON_COMBATMG' or w == 'WEAPON_APPISTOL' then
        return 500
    end
    if w:find('SHOTGUN') or w:find('SNIPER') then return 50 end
    return 100
end

CnR.Ranks.DefaultAmmo = defaultAmmo

local function strongerArmor(a, b)
    if not a then return b end
    if not b then return a end
    return (ARMOR_RANK[a] or 0) >= (ARMOR_RANK[b] or 0) and a or b
end

local function buildLoadout(rankId)
    local weapons, ammo, seen = {}, {}, {}
    local armor, rank = nil, nil
    if not (Config and Config.Ranks) then return weapons, ammo, armor, rank end
    for _, r in ipairs(Config.Ranks) do
        if r.id <= rankId then
            armor = strongerArmor(armor, r.armor)
            for _, w in ipairs(r.weapons or {}) do
                if not seen[w] then
                    seen[w] = true
                    weapons[#weapons + 1] = w
                    ammo[w] = defaultAmmo(w)
                end
            end
            if r.id == rankId then rank = r end
        end
    end
    return weapons, ammo, armor, rank
end

function CnR.Ranks.IsVehicleAllowed(rankId, model)
    if not (Config and Config.Ranks) or not model then return false end
    for _, r in ipairs(Config.Ranks) do
        if r.id <= rankId then
            for _, v in ipairs(r.vehicles or {}) do
                if v == model then return true end
            end
        end
    end
    return false
end

function CnR.Ranks.VehiclesFor(rankId)
    local out, seen = {}, {}
    if not (Config and Config.Ranks) then return out end
    for _, r in ipairs(Config.Ranks) do
        if r.id <= rankId then
            for _, v in ipairs(r.vehicles or {}) do
                if not seen[v] then
                    seen[v] = true
                    out[#out + 1] = v
                end
            end
        end
    end
    return out
end

-- Pick one entry from a spawn table (or pass through a single vec4).
local function pickSpawn(s)
    if type(s) == 'table' and s[1] and not s.x then
        s = s[math.random(#s)]
    end
    return s  -- vec4, .w holds heading
end

local function spawnFor(profile, rank)
    local stations = (Config and Config.PoliceStations) or {}
    if profile and profile.station and stations[profile.station] and stations[profile.station].spawn then
        return pickSpawn(stations[profile.station].spawn)
    end
    local legacy = (Config and Config.Spawns and Config.Spawns.cops) or {}
    if profile and profile.station and legacy[profile.station] then
        return legacy[profile.station]
    end
    local mr = stations.missionRow or legacy.missionRow
    if mr then
        if mr.spawn then return pickSpawn(mr.spawn) end
        return mr
    end
    return legacy.missionRow
end

local function rankSwitchSpawnFor(profile, rank)
    local stations = (Config and Config.PoliceStations) or {}
    local stationKey = profile and profile.station
    local station = stationKey and stations[stationKey] or nil
    station = station or stations.missionRow

    if station and station.rankTerminal then
        if station.rankTerminal.spawn then return station.rankTerminal.spawn end
        if station.rankTerminal.pos then
            local p = station.rankTerminal.pos
            return vec4(p.x, p.y, p.z, 0.0)
        end
    end
    if station and station.deskNpc and station.deskNpc.pos then return station.deskNpc.pos end
    return nil
end

local function mergeWeaponLists(rankWeapons, rankAmmo, savedWeapons, savedAmmo)
    local weapons, ammo, seen = {}, {}, {}
    for _, w in ipairs(rankWeapons or {}) do
        if not seen[w] then
            seen[w] = true
            weapons[#weapons + 1] = w
            ammo[w] = (rankAmmo and rankAmmo[w]) or defaultAmmo(w)
        end
    end
    for _, w in ipairs(savedWeapons or {}) do
        if not seen[w] then
            seen[w] = true
            weapons[#weapons + 1] = w
            ammo[w] = (savedAmmo and savedAmmo[w]) or defaultAmmo(w)
        elseif savedAmmo and savedAmmo[w] and savedAmmo[w] > (ammo[w] or 0) then
            ammo[w] = savedAmmo[w]
        end
    end
    return weapons, ammo
end

function CnR.Ranks.ApplyRank(src, _rankId, skin, useSaved, keepPosition, posOverride)
    if not src or src == 0 then return false, 'no source' end
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then
        return false, 'not a cop'
    end

    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return false, 'no identifier' end
    local profile = CnR.Persistence.GetProfile(id)

    -- Cops have no levels anymore; resolve the base rank just for the spawn/loadout helpers.
    local rank = CnR.Util.rankById(1)
    if not rank then return false, 'no levels configured' end

    local allowedSkin = nil
    if type(skin) == 'table' and skin.isCustom then
        allowedSkin = CnR.Util.NormalizeCopSkin(skin)
    elseif useSaved and profile.skin then
        allowedSkin = CnR.Util.NormalizeCopSkin(profile.skin)
    else
        allowedSkin = CnR.Util.NormalizeCopSkin(profile.skin)
    end
    profile.skin = allowedSkin

    local outfitId = profile.outfit or 1

    -- Cops ALWAYS spawn with only the base loadout (pistol, nightstick, taser,
    -- flashlight) AND only Super Light armor, regardless of level. Higher armor tiers
    -- and extra weapons are bought from the armory NPC — never auto-granted by level.
    local armorTier = 'superlight'
    local weapons, ammo = {}, {}
    for _, w in ipairs({ 'WEAPON_PISTOL', 'WEAPON_NIGHTSTICK', 'WEAPON_STUNGUN', 'WEAPON_FLASHLIGHT' }) do
        weapons[#weapons + 1] = w
        ammo[w] = defaultAmmo(w)
    end
    profile.weapons = weapons
    profile.weaponAmmo = ammo

    CnR.Persistence.SaveProfile(id, profile)
    -- posOverride (a saved last-position) wins when present — used on reconnect after a server
    -- restart so a cop resumes exactly where they were. With no override, cops spawn at their
    -- station's locker-room spawn (rank switches use the rank terminal).
    local spawn = posOverride
        or (keepPosition and rankSwitchSpawnFor(profile, rank) or spawnFor(profile, rank))

    TriggerClientEvent('cnr:client:applyLoadout', src, {
        side    = CnR.Sides.COP,
        weapons = weapons,
        ammo    = ammo,
        armor   = armorTier or 'light',
        skin    = allowedSkin,
        spawn   = spawn,
        outfitId = outfitId,
        clothes  = profile.copClothes,   -- player-built Police Clothing uniform (or nil)
        hideHat  = profile.hideHat == true,
        restore = useSaved == true,
        uniformOnly = keepPosition == true,
    })
    TriggerClientEvent('cnr:client:rankApplied', src, { rank = rank })
    if CnR.PushProfile then CnR.PushProfile(src) end
    CnR.Persistence.Flush()
    return true
end


function CnR.Ranks.GrantXp(src, amount)
    amount = tonumber(amount) or 0
    if amount == 0 then return end
    if not src or src == 0 then return end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return end
    local profile  = CnR.Persistence.GetProfile(id)
    local previous = profile.xp or 0
    profile.xp     = previous + amount

    -- Level is automatic: recompute from the new XP total.
    local oldRank = CnR.Util.rankFromXp(previous)
    local newRank = CnR.Util.rankFromXp(profile.xp) or CnR.Util.rankById(1)
    if newRank then profile.rankId = newRank.id end
    CnR.Persistence.SaveProfile(id, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end

    -- On a level-up: do NOT auto-grant weapons or armor — cops buy newly unlocked
    -- weapons and armor at the armory NPC. Just announce the new level.
    if newRank and (not oldRank or newRank.id > oldRank.id) then
        TriggerClientEvent('cnr:client:rankApplied', src, { rank = newRank })
        TriggerClientEvent('cnr:client:notify', src, {
            kind = 'info',
            text = ('Level up! You are now %s.'):format(newRank.name),
        })
    end
end

-- ─── Police credits ────────────────────────────────────────────────────────────
-- Cops earn credits (kills/arrests) and spend them at the armory / vehicle yard.
function CnR.Ranks.GrantCredits(src, amount)
    amount = tonumber(amount) or 0
    if amount == 0 or not src or src == 0 then return end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return end
    local profile = CnR.Persistence.GetProfile(id)
    profile.credits = (profile.credits or 0) + amount
    CnR.Persistence.SaveProfile(id, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end
end

function CnR.Ranks.GetCredits(src)
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return 0 end
    return CnR.Persistence.GetProfile(id).credits or 0
end

-- Deduct `cost` credits if the player can afford it. Returns true on success.
function CnR.Ranks.SpendCredits(src, cost)
    cost = tonumber(cost) or 0
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return false end
    local profile = CnR.Persistence.GetProfile(id)
    if (profile.credits or 0) < cost then return false end
    profile.credits = (profile.credits or 0) - cost
    CnR.Persistence.SaveProfile(id, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end
    return true
end

-- Robber XP (separate ladder via Config.RobberRanks). Adds XP, recomputes robber
-- level, pushes the profile (HUD), and announces a level-up. No loadout changes.
function CnR.Ranks.GrantRobberXp(src, amount)
    amount = tonumber(amount) or 0
    if amount == 0 or not src or src == 0 then return end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return end
    local profile = CnR.Persistence.GetProfile(id)
    local previous = profile.xp or 0
    profile.xp = previous + amount
    CnR.Persistence.SaveProfile(id, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end

    local oldL = CnR.Util.robberLevel(previous)
    local newL = CnR.Util.robberLevel(profile.xp)
    if newL > oldL then
        local r = CnR.Util.robberRankFromXp(profile.xp)
        TriggerClientEvent('cnr:client:notify', src, {
            kind = 'info',
            text = ('Level up! You are now %s.'):format((r and r.name) or ('Level ' .. newL)),
        })
    end
end

-- Whitelist of clothing fields the Police Clothing browser may set (all numeric).
local CLOTHES_FIELDS = {
    'top','topTxt','pants','pantsTxt','shoes','shoesTxt','undershirt','undershirtTxt',
    'armor','armorTxt','gloves','glovesTxt','arms','armsTxt','decl','declTxt',
    'mask','maskTxt','accessory','accessoryTxt','hat','hatTxt',
}
local function sanitizeClothes(t)
    if type(t) ~= 'table' then return nil end
    local out = {}
    for _, f in ipairs(CLOTHES_FIELDS) do
        if t[f] ~= nil then out[f] = math.floor(tonumber(t[f]) or 0) end
    end
    return out
end

RegisterNetEvent('cnr:server:requestClothingList', function()
    local src = source
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    local profile = id and CnR.Persistence.GetProfile(id) or {}
    TriggerClientEvent('cnr:client:clothingList', src, {
        clothes  = profile.copClothes,                      -- current saved uniform (or nil)
        station  = profile.station or 'missionRow',
        hideHat  = profile.hideHat == true,
        skin     = CnR.Util.NormalizeCopSkin(profile.skin), -- for resolving the uniform hat in preview
        outfitId = profile.outfit or 1,
    })
end)

-- Toggle whether the cop's police hat is worn. Persisted + applied immediately.
RegisterNetEvent('cnr:server:setHat', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    p.hideHat = payload.hide == true
    CnR.Persistence.SaveProfile(id, p)
    if CnR.PushProfile then CnR.PushProfile(src) end
    CnR.Persistence.Flush()
    -- The hat's visual is applied live by the menu (preview/save); spawn re-applies it
    -- from profile.hideHat. No need to re-apply the whole uniform here.
end)

RegisterNetEvent('cnr:server:applyClothing', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return end

    -- Police Clothing is fully unlocked (no rank/level gate): just save what they built.
    local clothes = sanitizeClothes(payload.clothes)
    if not clothes then return end

    local profile = CnR.Persistence.GetProfile(id)
    profile.copClothes = clothes
    CnR.Persistence.SaveProfile(id, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end
    CnR.Persistence.Flush()

    -- Apply only the uniform in place — no weapon reset, fade, or teleport.
    TriggerClientEvent('cnr:client:applyOutfit', src, {
        skin    = CnR.Util.NormalizeCopSkin(profile.skin),
        clothes = clothes,
    })
end)

RegisterNetEvent('cnr:server:setStation', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src)
    if not id then return end
    local station = payload.station
    if station ~= 'missionRow' and station ~= 'vespucci' then return end
    local p = CnR.Persistence.GetProfile(id)
    p.station = station
    CnR.Persistence.SaveProfile(id, p)
    if CnR.PushProfile then CnR.PushProfile(src) end
    -- Notification is shown client-side in native_menus.lua OnListSelect to avoid
    -- the double-notification (NUI + GTA ticker) that cnr:client:notify produces.
end)


local function isHelicopter(model)
    for _, h in ipairs((Config and Config.Helicopters) or {}) do
        if h == model then return true end
    end
    return false
end

-- Credit cost for a police vehicle: keyed by model, else by folder-name label, else default.
function CnR.Ranks.VehicleCreditCost(model, label)
    local byModel = Config and Config.VehicleCredits and Config.VehicleCredits[model]
    if byModel ~= nil then return byModel end
    if label and Config and Config.VehicleCreditsByLabel then
        local c = Config.VehicleCreditsByLabel[tostring(label):lower()]
        if c ~= nil then return c end
    end
    return (Config and Config.VehicleCreditsDefault) or 3
end

-- Build the police vehicle list with credit costs (cheapest first). `wantHelis=false`
-- excludes helicopters (air-support NPC); `wantHelis=true` includes ONLY helicopters.
local function buildVehicleList(credits, wantHelis)
    local out, seen = {}, {}
    if Config and Config.Ranks then
        for _, r in ipairs(Config.Ranks) do
            for _, v in ipairs(r.vehicles or {}) do
                if not seen[v] and (isHelicopter(v) == wantHelis) then
                    seen[v] = true
                    local label = CnR.AutoVehicleLabels and CnR.AutoVehicleLabels[v] or nil
                    local cost = CnR.Ranks.VehicleCreditCost(v, label)
                    out[#out + 1] = {
                        model    = v,
                        cost     = cost,
                        unlocked = (credits or 0) >= cost,
                        label    = label,  -- folder-name label for add-on vehicles
                    }
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.cost ~= b.cost then return a.cost < b.cost end
        return (a.label or a.model) < (b.label or b.model)
    end)
    return out
end

RegisterNetEvent('cnr:server:requestVehicleList', function()
    local src = source
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end
    local credits = (CnR.Ranks.GetCredits and CnR.Ranks.GetCredits(src)) or 0
    TriggerClientEvent('cnr:client:vehiclePicker', src, {
        vehicles = buildVehicleList(credits, false),  -- ground vehicles only
        credits  = credits,
    })
end)

RegisterNetEvent('cnr:server:requestHeliList', function()
    local src = source
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end
    local credits = (CnR.Ranks.GetCredits and CnR.Ranks.GetCredits(src)) or 0
    TriggerClientEvent('cnr:client:vehiclePicker', src, {
        vehicles = buildVehicleList(credits, true),   -- helicopters only
        credits  = credits,
        heli     = true,
    })
end)
