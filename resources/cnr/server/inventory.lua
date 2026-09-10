CnR = CnR or {}
CnR.Inventory = CnR.Inventory or {}

local function getProfileForSrc(src)
    local ident = GetPlayerIdentifierByType(src, 'license')
    if not ident then return nil, nil end
    local profile = CnR.Persistence and CnR.Persistence.GetProfile and CnR.Persistence.GetProfile(ident) or nil
    return profile, ident
end

local function ensureInventory(profile)
    if not profile.inventory or type(profile.inventory) ~= 'table' then
        profile.inventory = {}
    end
    return profile.inventory
end

local function clampItem(key, count)
    local def = Config.Inventory and Config.Inventory.items and Config.Inventory.items[key]
    if not def then return 0 end
    if count < 0 then count = 0 end
    if def.max and count > def.max then count = def.max end
    return count
end

function CnR.Inventory.Get(src)
    local profile = getProfileForSrc(src)
    if not profile then return {} end
    return ensureInventory(profile)
end

function CnR.Inventory.Add(src, key, qty)
    qty = qty or 1
    local profile, ident = getProfileForSrc(src)
    if not profile then return false end
    local inv = ensureInventory(profile)
    inv[key] = clampItem(key, (inv[key] or 0) + qty)
    if CnR.Persistence and CnR.Persistence.SaveProfile then
        CnR.Persistence.SaveProfile(ident, profile)
    end
    TriggerClientEvent('cnr:client:inventoryUpdate', src, { inventory = inv })
    return true
end

function CnR.Inventory.Remove(src, key, qty)
    qty = qty or 1
    local profile, ident = getProfileForSrc(src)
    if not profile then return false end
    local inv = ensureInventory(profile)
    if (inv[key] or 0) < qty then return false end
    inv[key] = clampItem(key, (inv[key] or 0) - qty)
    if CnR.Persistence and CnR.Persistence.SaveProfile then
        CnR.Persistence.SaveProfile(ident, profile)
    end
    TriggerClientEvent('cnr:client:inventoryUpdate', src, { inventory = inv })
    return true
end

RegisterNetEvent('cnr:server:requestInventory', function()
    local src = source
    local inv = CnR.Inventory.Get(src)
    local profile = getProfileForSrc(src) or {}
    TriggerClientEvent('cnr:client:inventoryUpdate', src, {
        inventory = inv,
        cash      = profile.cash or 0,
        xp        = profile.xp or 0,
        rankId    = profile.rankId or 1,
        jailSecondsRemaining = profile.jailSecondsRemaining or 0,
        jailDebtSeconds      = profile.jailDebtSeconds or 0,
    })
end)

RegisterNetEvent('cnr:server:useItem', function(payload)
    local src = source
    if type(payload) ~= 'table' or type(payload.key) ~= 'string' then return end
    local key = payload.key
    local def = Config.Inventory and Config.Inventory.items and Config.Inventory.items[key]
    if not def then return end
    local profile, ident = getProfileForSrc(src)
    if not profile then return end
    local inv = ensureInventory(profile)
    if (inv[key] or 0) <= 0 then return end
    inv[key] = inv[key] - 1
    if CnR.Persistence and CnR.Persistence.SaveProfile then
        CnR.Persistence.SaveProfile(ident, profile)
    end
    TriggerClientEvent('cnr:client:itemConsumed', src, { key = key, heal = def.heal or 0 })
    TriggerClientEvent('cnr:client:inventoryUpdate', src, { inventory = inv })
end)

RegisterNetEvent('cnr:server:removeItem', function(payload)
    local src = source
    if type(payload) ~= 'table' or type(payload.key) ~= 'string' then return end
    local key = payload.key
    local def = Config.Inventory and Config.Inventory.items and Config.Inventory.items[key]
    if not def then return end
    local profile, ident = getProfileForSrc(src)
    if not profile then return end
    local inv = ensureInventory(profile)
    if (inv[key] or 0) <= 0 then return end
    inv[key] = clampItem(key, (inv[key] or 0) - 1)
    if CnR.Persistence and CnR.Persistence.SaveProfile then
        CnR.Persistence.SaveProfile(ident, profile)
    end
    TriggerClientEvent('cnr:client:inventoryUpdate', src, { inventory = inv })
end)

RegisterNetEvent('cnr:server:buyItem', function(payload)
    local src = source
    if type(payload) ~= 'table' or type(payload.key) ~= 'string' then return end
    local key = payload.key
    local def = Config.Inventory and Config.Inventory.items and Config.Inventory.items[key]
    if not def then return end
    local price = Config.Inventory.foodShopPrices and Config.Inventory.foodShopPrices[key] or 0
    if price <= 0 then return end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local nearStore = false
    for _, s in ipairs((Config and Config.Stores) or {}) do
        local p = s.cashier
        if not p and s.ped then p = vec3(s.ped.x, s.ped.y, s.ped.z) end
        if p then
            local c = GetEntityCoords(ped)
            local dx, dy, dz = c.x - p.x, c.y - p.y, c.z - p.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) <= 6.0 then nearStore = true; break end
        end
    end
    if not nearStore then
        for _, s in ipairs((Config and Config.Blips and Config.Blips.stores) or {}) do
            if s.pos then
                local c = GetEntityCoords(ped)
                local dx, dy, dz = c.x - s.pos.x, c.y - s.pos.y, c.z - s.pos.z
                if math.sqrt(dx * dx + dy * dy + dz * dz) <= 6.0 then nearStore = true; break end
            end
        end
    end
    if not nearStore then
        TriggerClientEvent('cnr:client:notify', src, { kind = 'error', text = 'You must be at a convenience store' })
        return
    end

    local profile, ident = getProfileForSrc(src)
    if not profile then return end
    if (profile.cash or 0) < price then
        TriggerClientEvent('cnr:client:notify', src, { kind = 'error', text = 'Not enough cash' })
        return
    end
    local inv = ensureInventory(profile)
    if def.max and (inv[key] or 0) >= def.max then
        TriggerClientEvent('cnr:client:notify', src, { kind = 'error', text = 'Inventory full' })
        return
    end
    profile.cash = (profile.cash or 0) - price
    inv[key] = clampItem(key, (inv[key] or 0) + 1)
    if CnR.Persistence and CnR.Persistence.SaveProfile then
        CnR.Persistence.SaveProfile(ident, profile)
    end
    TriggerClientEvent('cnr:client:inventoryUpdate', src, { inventory = inv, cash = profile.cash })
    TriggerClientEvent('cnr:client:itemPurchased', src, {
        label  = def.label or key,
        cash   = profile.cash,
        kind   = payload.kind,    -- echoed back so the shop menu re-opens to the right list
        select = payload.select,  -- preserve the highlighted row
    })
    if CnR.PushProfile then CnR.PushProfile(src) end
end)
