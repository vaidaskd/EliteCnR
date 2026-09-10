CnR = CnR or {}

local function getProfile(src)
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return nil end
    return CnR.Persistence.GetProfile(id), id
end

local function notify(src, kind, text)
    TriggerClientEvent('cnr:client:notify', src, { kind = kind, text = text })
end

local function nearParlor(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local c = GetEntityCoords(ped)
    for _, p in ipairs((Config and Config.TattooParlors) or {}) do
        local dx, dy, dz = c.x - p.x, c.y - p.y, c.z - p.z
        if (dx * dx + dy * dy + dz * dz) <= (6.0 * 6.0) then return true end
    end
    return false
end

RegisterNetEvent('cnr:server:requestTattooShop', function()
    local src = source
    if not nearParlor(src) then
        notify(src, 'error', 'You must be at a tattoo parlor')
        return
    end
    local p = getProfile(src) or {}
    TriggerClientEvent('cnr:client:openTattooShop', src, {
        cash  = p.cash or 0,
        owned = p.tattoos or {},
    })
end)

RegisterNetEvent('cnr:server:buyTattoo', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local id = tonumber(payload.id); if not id then return end
    local t = Config and Config.Tattoos and Config.Tattoos[id]
    if not t then return end
    if not nearParlor(src) then
        notify(src, 'error', 'You must be at a tattoo parlor')
        return
    end

    local profile, ident = getProfile(src)
    if not profile then return end
    profile.tattoos = profile.tattoos or {}

    for _, owned in ipairs(profile.tattoos) do
        if owned == id then
            notify(src, 'warn', 'You already have that tattoo')
            TriggerClientEvent('cnr:client:applyTattoos', src, profile.tattoos)
            return
        end
    end

    local price = t.price or 500
    if (profile.cash or 0) < price then
        notify(src, 'error', ('Not enough cash ($%d needed)'):format(price))
        return
    end

    profile.cash = (profile.cash or 0) - price
    profile.tattoos[#profile.tattoos + 1] = id
    CnR.Persistence.SaveProfile(ident, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end

    TriggerClientEvent('cnr:client:applyTattoos', src, profile.tattoos)
    notify(src, 'ok', ('%s tattoo applied — $%d'):format(t.label or 'Tattoo', price))
end)

RegisterNetEvent('cnr:server:removeTattoos', function()
    local src = source
    if not nearParlor(src) then return end
    local profile, ident = getProfile(src)
    if not profile then return end
    profile.tattoos = {}
    CnR.Persistence.SaveProfile(ident, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end
    TriggerClientEvent('cnr:client:applyTattoos', src, {})
    notify(src, 'ok', 'All tattoos removed')
end)

-- Re-send owned tattoos so the client can re-apply them after a (re)spawn.
RegisterNetEvent('cnr:server:requestTattoos', function()
    local src = source
    local p = getProfile(src)
    TriggerClientEvent('cnr:client:applyTattoos', src, (p and p.tattoos) or {})
end)
