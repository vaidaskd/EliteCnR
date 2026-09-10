

CnR = CnR or {}
CnR.Shops = CnR.Shops or {}
local prisonBikeCooldown = {}

local function getProfile(src)
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return nil, nil end
    return CnR.Persistence.GetProfile(id), id
end

local function notify(src, kind, text)
    TriggerClientEvent('cnr:client:notify', src, { kind = kind, text = text })
end

local function findCatalogEntry(entryList, key, value)
    for _, e in ipairs(entryList or {}) do
        if tostring(e[key] or '') == tostring(value) then return e end
    end
    return nil
end

local function distEntityToVec3(ent, v)
    if not ent or ent == 0 or not v then return math.huge end
    local c = GetEntityCoords(ent)
    local dx, dy, dz = c.x - v.x, c.y - v.y, c.z - v.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function isNearAmmu(src, radius)
    radius = radius or 6.0
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    for _, a in ipairs((Config and Config.Blips and Config.Blips.ammunation) or {}) do
        if a.pos and distEntityToVec3(ped, a.pos) < radius then
            return true
        end
    end
    return false
end

local function isNearDealership(src, radius)
    radius = radius or 25.0
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local dealerBlip = Config.Blips.dealership and Config.Blips.dealership[1]
    return dealerBlip and dealerBlip.pos and distEntityToVec3(ped, dealerBlip.pos) <= radius
end

local function isNearFoodStore(src, radius)
    radius = radius or 6.0
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    for _, s in ipairs((Config and Config.Stores) or {}) do
        local p = s.cashier
        if not p and s.ped then p = vec3(s.ped.x, s.ped.y, s.ped.z) end
        if p and distEntityToVec3(ped, p) <= radius then return true end
    end
    for _, s in ipairs((Config and Config.Blips and Config.Blips.stores) or {}) do
        if s.pos and distEntityToVec3(ped, s.pos) <= radius then return true end
    end
    return false
end

local function isNearClothing(src, radius)
    radius = radius or 6.0
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    for _, c in ipairs((Config and Config.Blips and Config.Blips.clothing) or {}) do
        if c.pos and distEntityToVec3(ped, c.pos) <= radius then return true end
    end
    return false
end

local function isNearBarber(src, radius)
    radius = radius or 6.0
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local locations = (Config and Config.BarberShop and Config.BarberShop.locations)
        or (Config and Config.Blips and Config.Blips.barber)
        or {}
    for _, b in ipairs(locations) do
        if b.pos and distEntityToVec3(ped, b.pos) <= radius then return true end
    end
    return false
end

local function clampInt(value, minVal, maxVal)
    value = math.floor(tonumber(value) or minVal)
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

local function isNearPrisonBikeNpc(src, radius)
    radius = radius or 6.0
    local cfg = Config and Config.PrisonBikeNpc
    if not cfg then return false end
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local locations = cfg.locations or { cfg }
    local closest, closestDist = nil, radius
    for _, vendor in ipairs(locations) do
        local p = vendor.pos
        if p then
            local d = distEntityToVec3(ped, vec3(p.x, p.y, p.z))
            if d <= closestDist then
                closestDist = d
                closest = vendor
            end
        end
    end
    return closest
end

local function isNearPrisonFoodNpc(src, radius)
    radius = radius or 6.0
    local cfg = Config and Config.PrisonFoodNpc
    if not cfg or not cfg.pos then return false end
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return distEntityToVec3(ped, vec3(cfg.pos.x, cfg.pos.y, cfg.pos.z)) <= radius
end

local function itemAllowedForSide(entry, side)
    if not entry then return false end
    if side == CnR.Sides.COP and entry.forbidCop == true then return false end
    return true
end

local function catalogForSide(catalog, side)
    local out = {}
    for _, entry in ipairs(catalog or {}) do
        if itemAllowedForSide(entry, side) then
            out[#out + 1] = entry
        end
    end
    return out
end


RegisterNetEvent('cnr:server:requestAmmuShop', function()
    local src = source
    if not (Config and Config.AmmuShop) then return end
    if not isNearAmmu(src, 8.0) then
        notify(src, 'error', 'You must be inside an Ammu-Nation')
        return
    end

    local profile = getProfile(src) or {}
    local side = CnR.GetSide and CnR.GetSide(src) or CnR.Sides.NONE
    TriggerClientEvent('cnr:client:openAmmuShop', src, {
        items = catalogForSide(Config.AmmuShop, side),
        cash  = profile.cash or 0,
    })
end)

-- Nearest Config.Stores index to the player (for robbery-cooldown lookup). #9
local function nearestStoreId(src, radius)
    local ped = GetPlayerPed(src); if ped == 0 then return nil end
    local best, bestD = nil, radius or 6.0
    for i, s in ipairs((Config and Config.Stores) or {}) do
        local p = s.cashier or (s.ped and vec3(s.ped.x, s.ped.y, s.ped.z))
        if p then
            local d = distEntityToVec3(ped, p)
            if d <= bestD then bestD = d; best = i end
        end
    end
    return best
end

RegisterNetEvent('cnr:server:requestFoodShop', function(payload)
    local src = source
    if not isNearFoodStore(src, 6.0) then
        notify(src, 'error', 'You must be at a store')
        return
    end
    -- Block buying while this store is being robbed or on its post-robbery cooldown.
    local storeId = nearestStoreId(src, 6.0)
    if storeId and CnR.Robbery and CnR.Robbery.StoreBuyBlocked then
        local blocked, left = CnR.Robbery.StoreBuyBlocked(storeId)
        if blocked then
            left = math.max(0, math.floor(left or 0))
            notify(src, 'error', ("Can't buy anything at the moment, store was recently robbed (%d:%02d)"):format(
                math.floor(left / 60), left % 60))
            return
        end
    end
    local inv  = Config.Inventory or {}
    local kind = (type(payload) == 'table' and payload.kind) or 'store'
    local menu, title
    if kind == 'liquor' then
        menu, title = inv.liquorShopMenu or {}, 'Liquor Store'
    else
        menu, title = inv.foodShopMenu or {}, '24/7 Store'
    end
    local profile = getProfile(src) or {}
    TriggerClientEvent('cnr:client:openFoodShop', src, {
        menu   = menu,
        prices = inv.foodShopPrices or {},
        items  = inv.items or {},
        title  = title,
        kind   = kind,
        cash   = profile.cash or 0,
    })
end)

RegisterNetEvent('cnr:server:requestClothingShop', function()
    local src = source
    if not isNearClothing(src, 8.0) then
        notify(src, 'error', 'You must be inside a clothing store')
        return
    end
    -- Officers keep their rank uniform (changed at the police locker), but they MAY buy
    -- accessories — glasses + watches — here. The client menu restricts cops to those two
    -- categories; robbers get the full wardrobe. #4
    local side = CnR.GetSide and CnR.GetSide(src) or CnR.Sides.NONE
    local isCop = (side == CnR.Sides.COP)
    local profile = getProfile(src) or {}
    local skin = isCop and CnR.Util.NormalizeCopSkin(profile.skin)
        or ((type(profile.skin) == 'table') and profile.skin or {})
    local gender = (skin.gender == 'female') and 'female' or 'male'
    local cp = Config.RobberClothing and Config.RobberClothing[gender]
    if not cp then
        notify(src, 'error', 'No clothing available for this character yet')
        return
    end
    TriggerClientEvent('cnr:client:openClothingShop', src, {
        gender  = gender,
        price   = (Config.ClothingShop and Config.ClothingShop.price) or 0,
        prices  = (Config.ClothingShop and Config.ClothingShop.prices) or {},
        cash    = profile.cash or 0,
        current = {
            top   = skin.top,   topTxt   = skin.topTxt,
            pants = skin.pants, pantsTxt = skin.pantsTxt,
            shoes = skin.shoes, shoesTxt = skin.shoesTxt,
            hat   = skin.hat,   hatTxt   = skin.hatTxt,
            glasses = skin.glasses, glassesTxt = skin.glassesTxt,
            watch = skin.watch, watchTxt = skin.watchTxt,
            mask  = skin.mask,  maskTxt  = skin.maskTxt,
        },
    })
end)

RegisterNetEvent('cnr:server:buyClothing', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if not isNearClothing(src, 8.0) then
        notify(src, 'error', 'You must be inside a clothing store')
        return
    end
    local side = CnR.GetSide and CnR.GetSide(src) or CnR.Sides.NONE
    local isCop = (side == CnR.Sides.COP)

    local profile, ident = getProfile(src)
    if not profile then return end

    local skin
    if isCop then
        -- Cops may ONLY change glasses + watches — discard any other category from the
        -- request so a tampered client can't make a cop buy tops/pants/etc. Their skin is
        -- normalized so the accessories have a (custom) table to persist into. #4
        skin = CnR.Util.NormalizeCopSkin(profile.skin)
        payload = {
            glasses = payload.glasses, glassesTxt = payload.glassesTxt,
            watch   = payload.watch,   watchTxt   = payload.watchTxt,
        }
    else
        skin = profile.skin
        if type(skin) ~= 'table' or not skin.isCustom then
            notify(src, 'error', 'Clothing changes require a custom character')
            return
        end
    end

    local gender = (skin.gender == 'female') and 'female' or 'male'
    local cp = Config.RobberClothing and Config.RobberClothing[gender]
    if not cp then notify(src, 'error', 'No clothing available'); return end

    -- Only the categories the player actually changed are present in the payload; untouched
    -- ones are left exactly as worn. Server is authoritative on the allowed indices.
    local function pick(list, idx)
        idx = tonumber(idx)
        return (list and idx and list[idx]) or nil
    end
    local function inList(list, v)
        for _, e in ipairs(list or {}) do if e == v then return true end end
        return false
    end
    local function pickProp(list, v, noneVal)
        v = tonumber(v)
        if v == nil or v == noneVal or inList(list, v) then return v or noneVal end
        return noneVal
    end

    -- Per-item price + cash check BEFORE applying anything, so nothing is applied (or
    -- mutated in the profile) when the player can't afford it. #12
    local cprices = (Config.ClothingShop and Config.ClothingShop.prices) or {}
    local price, any = 0, false
    if payload.topIdx   ~= nil then price = price + (cprices.top or 0); any = true end
    if payload.pantsIdx ~= nil then price = price + (cprices.pants or 0); any = true end
    if payload.shoesIdx ~= nil then price = price + (cprices.shoes or 0); any = true end
    if payload.hat      ~= nil then price = price + (cprices.hat or 0); any = true end
    if payload.glasses  ~= nil then price = price + (cprices.glasses or 0); any = true end
    if payload.watch    ~= nil then price = price + (cprices.watch or 0); any = true end
    if payload.mask     ~= nil then price = price + (cprices.mask or 0); any = true end
    if not any then notify(src, 'error', 'Nothing selected'); return end
    if (profile.cash or 0) < price then
        notify(src, 'error', ('Not enough cash ($%d needed)'):format(price))
        return
    end

    local components, props = {}, {}
    local changed = false

    if payload.topIdx ~= nil then
        local top = pick(cp.tops, payload.topIdx)
        if top == nil then notify(src, 'error', 'Invalid clothing selection'); return end
        skin.top, skin.topTxt = top, tonumber(payload.topTxt) or 0
        skin.arms = cp.arms or 0
        skin.undershirt, skin.undershirtTxt = cp.undershirt or 15, cp.undershirtTxt or 0
        components.top, components.topTxt = skin.top, skin.topTxt
        components.arms = skin.arms
        components.undershirt, components.undershirtTxt = skin.undershirt, skin.undershirtTxt
        changed = true
    end
    if payload.pantsIdx ~= nil then
        local pants = pick(cp.pants, payload.pantsIdx)
        if pants == nil then notify(src, 'error', 'Invalid clothing selection'); return end
        skin.pants, skin.pantsTxt = pants, tonumber(payload.pantsTxt) or 0
        components.pants, components.pantsTxt = skin.pants, skin.pantsTxt
        changed = true
    end
    if payload.shoesIdx ~= nil then
        local shoes = pick(cp.shoes, payload.shoesIdx)
        if shoes == nil then notify(src, 'error', 'Invalid clothing selection'); return end
        skin.shoes, skin.shoesTxt = shoes, tonumber(payload.shoesTxt) or 0
        components.shoes, components.shoesTxt = skin.shoes, skin.shoesTxt
        changed = true
    end
    if payload.hat ~= nil then
        skin.hat, skin.hatTxt = pickProp(cp.hats, payload.hat, -1), tonumber(payload.hatTxt) or 0
        props.hat, props.hatTxt = skin.hat, skin.hatTxt
        changed = true
    end
    if payload.glasses ~= nil then
        skin.glasses, skin.glassesTxt = pickProp(cp.glasses, payload.glasses, -1), tonumber(payload.glassesTxt) or 0
        props.glasses, props.glassesTxt = skin.glasses, skin.glassesTxt
        changed = true
    end
    if payload.watch ~= nil then
        skin.watch, skin.watchTxt = pickProp(cp.watches, payload.watch, -1), tonumber(payload.watchTxt) or 0
        props.watch, props.watchTxt = skin.watch, skin.watchTxt
        changed = true
    end
    if payload.mask ~= nil then
        skin.mask, skin.maskTxt = pickProp(cp.masks, payload.mask, 0), tonumber(payload.maskTxt) or 0
        components.mask, components.maskTxt = skin.mask, skin.maskTxt
        changed = true
    end

    if not changed then notify(src, 'error', 'Nothing selected'); return end

    profile.cash = (profile.cash or 0) - price
    profile.skin = skin
    CnR.Persistence.SaveProfile(ident, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end

    TriggerClientEvent('cnr:client:applyClothing', src, { components = components, props = props })
    notify(src, 'ok', price > 0 and ('Outfit applied — $%d'):format(price) or 'Outfit applied')
end)

RegisterNetEvent('cnr:server:requestBarberShop', function()
    local src = source
    if not isNearBarber(src, 8.0) then
        notify(src, 'error', 'You must be inside a barbershop')
        return
    end

    local profile = getProfile(src) or {}
    TriggerClientEvent('cnr:client:openBarberShop', src, {
        cash = profile.cash or 0,
        price = (Config.BarberShop and Config.BarberShop.price) or 100,
        prices = (Config.BarberShop and Config.BarberShop.prices) or {},
        skin = profile.skin or {},
        rankId = profile.rankId or 1,
    })
end)

RegisterNetEvent('cnr:server:buyBarberStyle', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if not isNearBarber(src, 8.0) then
        notify(src, 'error', 'You must be inside a barbershop')
        return
    end

    local profile, ident = getProfile(src)
    if not profile then return end
    local skin = profile.skin
    if type(skin) ~= 'table' or not skin.isCustom then
        notify(src, 'error', 'Barber changes require a custom character')
        return
    end

    -- Per-item pricing: only the styles that actually change are charged.
    local newHair       = clampInt(payload.hair, 0, 74)
    local newHairColor  = clampInt(payload.hairColor, 0, 63)
    local newBeard      = clampInt(payload.beard, 0, 28)
    local newBeardColor = clampInt(payload.beardColor, 0, 63)

    local bprices = (Config.BarberShop and Config.BarberShop.prices) or {}
    local price = 0
    if newHair       ~= (tonumber(skin.hair) or 0)       then price = price + (bprices.hair or 0) end
    if newHairColor  ~= (tonumber(skin.hairColor) or 0)  then price = price + (bprices.hairColor or 0) end
    if newBeard      ~= (tonumber(skin.beard) or 0)      then price = price + (bprices.beard or 0) end
    if newBeardColor ~= (tonumber(skin.beardColor) or 0) then price = price + (bprices.beardColor or 0) end

    if price <= 0 then
        notify(src, 'warn', 'No changes to apply')
        return
    end
    if (profile.cash or 0) < price then
        notify(src, 'error', ('Not enough cash ($%d needed)'):format(price))
        return
    end

    skin.hair = newHair
    skin.hairColor = newHairColor
    skin.beard = newBeard
    skin.beardColor = newBeardColor

    profile.cash = (profile.cash or 0) - price
    profile.skin = skin
    CnR.Persistence.SaveProfile(ident, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end

    TriggerClientEvent('cnr:client:applyBarber', src, { skin = skin, rankId = profile.rankId or 1 })
    notify(src, 'ok', ('Barber style applied - $%d'):format(price))
end)

RegisterNetEvent('cnr:server:buyWeapon', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end

    local key = tostring(payload.key or '')
    local entry = findCatalogEntry(Config.AmmuShop, 'weapon', key)
    if not entry then notify(src, 'error', 'Unknown item'); return end

    if not isNearAmmu(src, 8.0) then
        notify(src, 'error', 'You must be inside an Ammu-Nation')
        return
    end

    local side = CnR.GetSide and CnR.GetSide(src) or CnR.Sides.NONE
    if not itemAllowedForSide(entry, side) then
        notify(src, 'error', 'That item is not sold to police')
        return
    end

    local profile, ident = getProfile(src)
    if not profile then return end
    local price = entry.price or 0
    if (profile.cash or 0) < price then
        notify(src, 'error', ('Not enough cash ($%d needed)'):format(price))
        return
    end

    profile.cash = (profile.cash or 0) - price
    CnR.Persistence.SaveProfile(ident, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end

    if entry.weapon == 'ARMOR' or entry.weapon:sub(1, 6) == 'ARMOR_' then
        TriggerClientEvent('cnr:client:applyArmor', src, { value = entry.armorValue or 100 })
    elseif entry.weapon == 'MEDKIT' then
        TriggerClientEvent('cnr:client:applyMedkit', src, {})
    elseif entry.category == 'Ammo' and entry.ammoFor then
        TriggerClientEvent('cnr:client:giveAmmo', src, {
            weapon = entry.ammoFor, amount = entry.ammo or 0,
        })
        if CnR.Armory and CnR.Armory.MergeWeapon then
            local current = (profile.weaponAmmo and profile.weaponAmmo[entry.ammoFor]) or 0
            CnR.Armory.MergeWeapon(ident, entry.ammoFor, current + (entry.ammo or 0))
        end
    else
        TriggerClientEvent('cnr:client:giveWeapon', src, {
            weapon = entry.weapon, ammo = entry.ammo or 100,
        })
        if CnR.Armory and CnR.Armory.MergeWeapon then
            CnR.Armory.MergeWeapon(ident, entry.weapon, entry.ammo or 100)
        end
    end

    notify(src, 'ok', ('Bought %s — $%d'):format(entry.label or entry.weapon, price))
end)


RegisterNetEvent('cnr:server:requestDealership', function()
    local src = source
    if not (Config and Config.Dealership) then return end
    if not isNearDealership(src, 25.0) then
        notify(src, 'error', 'You must be at Premium Deluxe Motorsport')
        return
    end
    local profile = getProfile(src) or {}
    TriggerClientEvent('cnr:client:openDealership', src, {
        cars = Config.Dealership.cars,
        cash = profile.cash or 0,
    })
end)

RegisterNetEvent('cnr:server:buyCar', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local key = tostring(payload.model or '')
    local entry = findCatalogEntry(Config.Dealership.cars, 'model', key)
    if not entry then notify(src, 'error', 'Unknown vehicle'); return end


    if not isNearDealership(src, 25.0) then
        notify(src, 'error', 'You must be at Premium Deluxe Motorsport')
        return
    end

    local profile, ident = getProfile(src)
    if not profile then return end
    local price = entry.price or 0
    if (profile.cash or 0) < price then
        notify(src, 'error', ('Not enough cash ($%d needed)'):format(price))
        return
    end

    profile.cash = (profile.cash or 0) - price
    CnR.Persistence.SaveProfile(ident, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end

    local spawn = Config.Dealership.spawn
    TriggerClientEvent('cnr:client:spawnCivilianCar', src, {
        model = entry.model,
        coords = { x = spawn.x, y = spawn.y, z = spawn.z, h = spawn.w or 60.0 },
    })

    if price > 0 then
        notify(src, 'ok', ('Purchased %s — $%d'):format(entry.label or entry.model, price))
    else
        notify(src, 'ok', ('Collected %s'):format(entry.label or entry.model))
    end
end)

RegisterNetEvent('cnr:server:requestPrisonBike', function(payload)
    local src = source
    local vendor = isNearPrisonBikeNpc(src, 8.0)
    if not vendor then
        notify(src, 'error', 'You must be at the prison bike vendor')
        return
    end

    local cfg = Config and Config.PrisonBikeNpc
    if not cfg then return end
    local spawn = vendor.spawn or cfg.spawn
    if not spawn then return end
    local now = os.time()
    local until_ = prisonBikeCooldown[src] or 0
    if until_ > now then
        notify(src, 'warn', ('Bike cooldown active: %ds'):format(until_ - now))
        return
    end

    local requested = type(payload) == 'table' and tostring(payload.model or '') or ''
    local chosen = (cfg.vehicles and cfg.vehicles[1] and cfg.vehicles[1].model) or 'bmx'
    for _, v in ipairs(cfg.vehicles or {}) do
        if requested ~= '' and v.model == requested then chosen = v.model; break end
    end

    prisonBikeCooldown[src] = now + (cfg.cooldownSec or 120)
    local s = spawn
    TriggerClientEvent('cnr:client:spawnFreePrisonVehicle', src, {
        model = chosen,
        coords = { x = s.x, y = s.y, z = s.z, h = s.w or s.h or 0.0 },
    })
end)

RegisterNetEvent('cnr:server:requestPrisonBikeShop', function()
    local src = source
    if not isNearPrisonBikeNpc(src, 8.0) then
        notify(src, 'error', 'You must be at the prison bike vendor')
        return
    end
    local cfg = Config and Config.PrisonBikeNpc
    TriggerClientEvent('cnr:client:openPrisonBikeShop', src, {
        vehicles = (cfg and cfg.vehicles) or {},
        cooldown = math.max(0, (prisonBikeCooldown[src] or 0) - os.time()),
    })
end)

RegisterNetEvent('cnr:server:requestPrisonFood', function()
    local src = source
    if not isNearPrisonFoodNpc(src, 8.0) then
        notify(src, 'error', 'You must be at the prison canteen')
        return
    end
    local cfg = Config and Config.PrisonFoodNpc or {}
    local profile = getProfile(src) or {}
    TriggerClientEvent('cnr:client:openPrisonFood', src, {
        price = cfg.price or 0,
        heal  = cfg.heal or 20,
        cash  = profile.cash or 0,
    })
end)

AddEventHandler('playerDropped', function()
    prisonBikeCooldown[source] = nil
end)


local function isNearModShop(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local c = GetEntityCoords(ped)
    for _, shop in ipairs((Config and Config.ModShop and Config.ModShop.locations) or {}) do
        if shop.pos then
            local dx, dy, dz = c.x - shop.pos.x, c.y - shop.pos.y, c.z - shop.pos.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) <= (shop.radius or 30.0) then
                return true
            end
        end
    end
    return false
end

local function chargeProfile(src, price)
    if price <= 0 then return true end
    local profile, ident = getProfile(src)
    if not profile then return false end
    if (profile.cash or 0) < price then
        notify(src, 'error', ('Not enough cash ($%d needed)'):format(price))
        return false
    end
    profile.cash = (profile.cash or 0) - price
    CnR.Persistence.SaveProfile(ident, profile)
    if CnR.PushProfile then CnR.PushProfile(src) end
    return true
end

RegisterNetEvent('cnr:server:buyPrisonFood', function()
    local src = source
    if not isNearPrisonFoodNpc(src, 8.0) then
        notify(src, 'error', 'You must be at the prison canteen')
        return
    end
    local cfg = Config and Config.PrisonFoodNpc or {}
    if not chargeProfile(src, cfg.price or 0) then return end
    -- Play the eating animation only, then heal — handled client-side. The food prop is
    -- intentionally omitted so no burger shows in the prisoner's hand. #prison-food
    TriggerClientEvent('cnr:client:itemConsumed', src, {
        heal = cfg.heal or 20,
        anim = cfg.consume and cfg.consume.anim,
    })
    notify(src, 'ok', 'You ate the prison food.')
end)

RegisterNetEvent('cnr:server:requestModShop', function()
    local src = source
    if not isNearModShop(src) then
        notify(src, 'error', 'You must be inside Los Santos Customs')
        return
    end
    local ped = GetPlayerPed(src)
    if ped == 0 or GetVehiclePedIsIn(ped, false) == 0 then
        notify(src, 'error', 'You must be in a vehicle')
        return
    end
    local profile = getProfile(src) or {}
    TriggerClientEvent('cnr:client:openModShop', src, { cash = profile.cash or 0 })
end)

RegisterNetEvent('cnr:server:modShopRepair', function(payload)
    local src = source
    if not isNearModShop(src) then notify(src, 'error', 'Not at a mod shop'); return end
    local ped = GetPlayerPed(src)
    if ped == 0 or GetVehiclePedIsIn(ped, false) == 0 then
        notify(src, 'error', 'You must be in a vehicle')
        return
    end
    local price = (type(payload) == 'table' and payload.price) or (Config.ModShop and Config.ModShop.repairPrice) or 250
    if not chargeProfile(src, price) then return end
    TriggerClientEvent('cnr:client:applyVehicleMod', src, { action = 'repair' })
    notify(src, 'ok', ('Vehicle repaired — $%d'):format(price))
end)

RegisterNetEvent('cnr:server:modShopApply', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if not isNearModShop(src) then notify(src, 'error', 'Not at a mod shop'); return end
    local ped = GetPlayerPed(src)
    if ped == 0 or GetVehiclePedIsIn(ped, false) == 0 then
        notify(src, 'error', 'You must be in a vehicle')
        return
    end
    local price = payload.price or 0
    if not chargeProfile(src, price) then return end
    TriggerClientEvent('cnr:client:applyVehicleMod', src, payload)
    notify(src, 'ok', price > 0 and ('Upgrade applied — $%d'):format(price) or 'Upgrade removed')
end)
