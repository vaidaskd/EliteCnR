CnR = CnR or {}
CnR.Armory = CnR.Armory or {}

local function notify(src, kind, text)
    TriggerClientEvent('cnr:client:notify', src, { kind = kind, text = text })
end

-- Friendly weapon label, e.g. WEAPON_STUNGUN -> "Stungun", WEAPON_NIGHTSTICK -> "Nightstick".
-- Matches the casing used in the armory weapon list.
local function weaponLabel(weapon)
    local raw = tostring(weapon):gsub('WEAPON_', ''):gsub('GADGET_', ''):gsub('_', ' '):lower()
    return (raw:gsub('(%a)([%w]*)', function(a, b) return a:upper() .. b end))
end

function CnR.Armory.SaveWeapons(ident, weapons, ammo)
    if not ident then return end
    local profile = CnR.Persistence.GetProfile(ident)
    profile.weapons = weapons or {}
    profile.weaponAmmo = ammo or {}
    CnR.Persistence.SaveProfile(ident, profile)
end

function CnR.Armory.MergeWeapon(ident, weapon, ammoAmt)
    if not ident or not weapon then return end
    local profile = CnR.Persistence.GetProfile(ident)
    profile.weapons = profile.weapons or {}
    profile.weaponAmmo = profile.weaponAmmo or {}

    local found = false
    for _, w in ipairs(profile.weapons) do
        if w == weapon then found = true; break end
    end
    if not found then
        profile.weapons[#profile.weapons + 1] = weapon
    end
    profile.weaponAmmo[weapon] = ammoAmt or profile.weaponAmmo[weapon] or 100
    CnR.Persistence.SaveProfile(ident, profile)
end

local function buildUnlockedWeapons(rankId)
    local weapons, ammo, seen = {}, {}, {}
    if not (Config and Config.Ranks) then return weapons, ammo end
    for _, r in ipairs(Config.Ranks) do
        if r.id <= rankId then
            for _, w in ipairs(r.weapons or {}) do
                if not seen[w] then
                    seen[w] = true
                    weapons[#weapons + 1] = w
                    if CnR.Ranks and CnR.Ranks.DefaultAmmo then
                        ammo[w] = CnR.Ranks.DefaultAmmo(w)
                    else
                        ammo[w] = 100
                    end
                end
            end
        end
    end
    return weapons, ammo
end

local function mergeWeaponLists(rankWeapons, rankAmmo, savedWeapons, savedAmmo)
    local weapons, ammo, seen = {}, {}, {}
    for _, w in ipairs(rankWeapons or {}) do
        if not seen[w] then
            seen[w] = true
            weapons[#weapons + 1] = w
            ammo[w] = (rankAmmo and rankAmmo[w]) or 100
        end
    end
    for _, w in ipairs(savedWeapons or {}) do
        if not seen[w] then
            seen[w] = true
            weapons[#weapons + 1] = w
            ammo[w] = (savedAmmo and savedAmmo[w]) or 100
        elseif savedAmmo and savedAmmo[w] and savedAmmo[w] > (ammo[w] or 0) then
            ammo[w] = savedAmmo[w]
        end
    end
    return weapons, ammo
end

-- Full police weapon arsenal with credit costs, cheapest first. Anything not in
-- Config.WeaponCredits isn't sold here.
local function copWeaponCatalog(credits)
    local out = {}
    for weapon, cost in pairs(Config.WeaponCredits or {}) do
        out[#out + 1] = {
            weapon   = weapon,
            cost     = cost,
            label    = (Config.WeaponLabels and Config.WeaponLabels[weapon]) or weaponLabel(weapon),
            unlocked = (credits or 0) >= cost,
        }
    end
    table.sort(out, function(a, b)
        if a.cost ~= b.cost then return a.cost < b.cost end
        return a.label < b.label
    end)
    return out
end

local function copArsenalSet()
    local set = {}
    for w in pairs(Config.WeaponCredits or {}) do set[w] = true end
    return set
end

function CnR.Armory.UnlockedWeapons(rankId)
    return buildUnlockedWeapons(rankId)
end

-- Body armor tiers sold at the armory, each gated by level. Super Light is the default
-- spawn armor (level 1); it's listed here too so a cop can top it back up after taking hits.
local ARMOR_TIERS = {
    { tier = 'superlight',  label = 'Super Light Armor', level = 1, value = 20  },
    { tier = 'light',       label = 'Light Armor',       level = 2, value = 40  },
    { tier = 'standard',    label = 'Standard Armor',    level = 3, value = 60  },
    { tier = 'heavy',       label = 'Heavy Armor',       level = 5, value = 80  },
    { tier = 'superheavy',  label = 'Super Heavy Armor', level = 7, value = 100 },
}

local function armorCost(tier)
    return (Config.ArmorCredits and Config.ArmorCredits[tier]) or 0
end

local function buildArmorList(credits)
    local out = {}
    for _, t in ipairs(ARMOR_TIERS) do
        local cost = armorCost(t.tier)
        out[#out + 1] = {
            tier = t.tier, label = t.label, value = t.value,
            cost = cost, unlocked = (credits or 0) >= cost,
        }
    end
    table.sort(out, function(a, b) return a.cost < b.cost end)
    return out
end

-- (Re)open the armory with the player's current credit balance. Sent on request AND after
-- every purchase, so lock states + the shown balance refresh in real time.
function CnR.Armory.SendArmory(src)
    local credits = (CnR.Ranks and CnR.Ranks.GetCredits and CnR.Ranks.GetCredits(src)) or 0
    TriggerClientEvent('cnr:client:openArmory', src, {
        weapons = copWeaponCatalog(credits),
        armor   = buildArmorList(credits),
        credits = credits,
    })
end

RegisterNetEvent('cnr:server:armoryArmor', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end
    local tier
    for _, t in ipairs(ARMOR_TIERS) do if t.tier == payload.tier then tier = t break end end
    if not tier then return end
    local cost = armorCost(tier.tier)
    if not (CnR.Ranks and CnR.Ranks.SpendCredits and CnR.Ranks.SpendCredits(src, cost)) then
        notify(src, 'error', ('Not enough credits (%d needed)'):format(cost))
        return
    end
    TriggerClientEvent('cnr:client:armoryArmor', src, { value = tier.value, label = tier.label })
    CnR.Armory.SendArmory(src)  -- refresh menu with the new balance / lock states
end)

RegisterNetEvent('cnr:server:syncWeapons', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return end
    local side = CnR.GetSide and CnR.GetSide(src)
    if side == CnR.Sides.NONE then return end

    local weapons = payload.weapons or {}
    local ammo    = payload.ammo or {}

    -- A cop may only persist weapons sanctioned by their current level. This stops
    -- ground-pickup weapons (e.g. a shotgun dropped by a dead player) from sticking
    -- to the profile and reappearing on later spawns.
    if side == CnR.Sides.COP then
        -- Only persist weapons that belong to the police arsenal, so ground-pickup
        -- weapons (e.g. a robber's dropped rifle) don't stick to the profile.
        local allowed = copArsenalSet()
        local fw, fa = {}, {}
        for _, w in ipairs(weapons) do
            if allowed[w] then
                fw[#fw + 1] = w
                fa[w] = ammo[w]
            end
        end
        weapons, ammo = fw, fa
    end

    CnR.Armory.SaveWeapons(id, weapons, ammo)
end)

RegisterNetEvent('cnr:server:requestArmory', function()
    local src = source
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end
    if not (CnR.GetIdentifier and CnR.GetIdentifier(src)) then return end
    CnR.Armory.SendArmory(src)
end)

RegisterNetEvent('cnr:server:armoryRefill', function()
    local src = source
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end

    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return end
    local profile = CnR.Persistence.GetProfile(id)

    -- Free top-up: refill ammo on the base loadout + whatever the cop currently carries.
    local weapons, ammo, seen = {}, {}, {}
    local base = { 'WEAPON_PISTOL', 'WEAPON_NIGHTSTICK', 'WEAPON_STUNGUN', 'WEAPON_FLASHLIGHT' }
    for _, w in ipairs(base) do
        if not seen[w] then seen[w] = true; weapons[#weapons + 1] = w; ammo[w] = CnR.Ranks.DefaultAmmo(w) end
    end
    for _, w in ipairs(profile.weapons or {}) do
        if not seen[w] then seen[w] = true; weapons[#weapons + 1] = w; ammo[w] = CnR.Ranks.DefaultAmmo(w) end
    end

    CnR.Armory.SaveWeapons(id, weapons, ammo)

    TriggerClientEvent('cnr:client:armoryRefill', src, {
        weapons = weapons,
        ammo    = ammo,
    })
    notify(src, 'ok', 'Ammunition refilled')
end)

RegisterNetEvent('cnr:server:armoryEquip', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end

    local weapon = tostring(payload.weapon or '')
    if weapon == '' then return end

    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return end

    local cost = Config.WeaponCredits and Config.WeaponCredits[weapon]
    if cost == nil then
        notify(src, 'error', 'Weapon not available')
        return
    end
    if not (CnR.Ranks and CnR.Ranks.SpendCredits and CnR.Ranks.SpendCredits(src, cost)) then
        notify(src, 'error', ('Not enough credits (%d needed)'):format(cost))
        return
    end

    local ammoAmt = CnR.Ranks.DefaultAmmo and CnR.Ranks.DefaultAmmo(weapon) or 100
    CnR.Armory.MergeWeapon(id, weapon, ammoAmt)

    TriggerClientEvent('cnr:client:armoryEquip', src, {
        weapon = weapon,
        ammo   = ammoAmt,
        label  = (Config.WeaponLabels and Config.WeaponLabels[weapon]) or weaponLabel(weapon),
    })
    -- The client shows a single clean "Equipped X" line in the game feed; no NUI toast.
    CnR.Armory.SendArmory(src)  -- refresh menu with the new balance / lock states
end)
