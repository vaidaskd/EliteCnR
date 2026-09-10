

CnR = CnR or {}

local INTERACT_DIST = 3.5
local DEALER_DIST   = 6.0
local STORE_DIST    = 3.5

local function helpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function dist2d(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function pressedInteract()
    local pressed = CnR.KeysPressed and CnR.KeysPressed.interact
    local nativeE = IsControlJustReleased(0, 38)
    if (pressed and (GetGameTimer() - pressed) < 300) or nativeE then
        if CnR.KeysPressed then CnR.KeysPressed.interact = nil end
        return true
    end
    return false
end

local function nearestBlipPos(list, ped, maxDist)
    local pc = GetEntityCoords(ped)
    local best, bestD = nil, maxDist or INTERACT_DIST
    for _, item in ipairs(list or {}) do
        local p = item.pos or item
        if p and p.x then
            local d = dist2d(pc, p)
            if d < bestD then bestD = d; best = item end
        end
    end
    return best
end

local function nearestStore(ped, maxDist)
    local pc = GetEntityCoords(ped)
    local best, bestD = nil, maxDist or STORE_DIST
    if Config and Config.Stores then
        for _, s in ipairs(Config.Stores) do
            local p = s.cashier
            if not p and s.ped then p = vec3(s.ped.x, s.ped.y, s.ped.z) end
            if p then
                local d = dist2d(pc, p)
                if d < bestD then bestD = d; best = s end
            end
        end
    end
    if not best and Config and Config.Blips and Config.Blips.stores then
        best = nearestBlipPos(Config.Blips.stores, ped, maxDist)
    end
    return best
end

local function nearPrisonBikeNpc(ped)
    local cfg = Config and Config.PrisonBikeNpc
    if not cfg then return false end
    local locations = cfg.locations or { cfg }
    local pc = GetEntityCoords(ped)
    for _, vendor in ipairs(locations) do
        local p = vendor.pos
        if p and dist2d(pc, p) <= INTERACT_DIST then return true end
    end
    return false
end

local function nearPrisonFoodNpc(ped)
    local cfg = Config and Config.PrisonFoodNpc
    if not cfg or not cfg.pos then return false end
    return dist2d(GetEntityCoords(ped), cfg.pos) <= INTERACT_DIST
end

local function nearestBarber(ped, maxDist)
    local locations = (Config and Config.BarberShop and Config.BarberShop.locations)
        or (Config and Config.Blips and Config.Blips.barber)
        or {}
    return nearestBlipPos(locations, ped, maxDist or INTERACT_DIST)
end

CreateThread(function()
    while true do
        local wait = 600
        local ped = PlayerPedId()
        if ped ~= 0 and Config and Config.Blips then
            local nearAmmu  = nearestBlipPos(Config.Blips.ammunation, ped, INTERACT_DIST)
            local nearDeal  = nearestBlipPos(Config.Blips.dealership, ped, DEALER_DIST)
            local nearCloth = nearestBlipPos(Config.Blips.clothing, ped, INTERACT_DIST)
            local nearBarber = nearestBarber(ped, INTERACT_DIST)
            local nearBikes = nearPrisonBikeNpc(ped)
            local nearFood  = nearPrisonFoodNpc(ped)
            local nearStore = nearestStore(ped, STORE_DIST)

            if nearAmmu then
                wait = 0
                helpText('Press ~INPUT_CONTEXT~ to browse Ammu-Nation')
                if pressedInteract() then
                    TriggerServerEvent('cnr:server:requestAmmuShop')
                end
            elseif nearDeal then
                wait = 0
                helpText('Press ~INPUT_CONTEXT~ to browse Premium Deluxe Motorsport')
                if pressedInteract() then
                    TriggerServerEvent('cnr:server:requestDealership')
                end
            elseif nearCloth then
                wait = 0
                helpText('Press ~INPUT_CONTEXT~ to buy clothes')
                if pressedInteract() then
                    TriggerServerEvent('cnr:server:requestClothingShop')
                end
            elseif nearBarber then
                wait = 0
                helpText('Press ~INPUT_CONTEXT~ to use the barbershop')
                if pressedInteract() then
                    TriggerServerEvent('cnr:server:requestBarberShop')
                end
            elseif nearBikes then
                wait = 0
                helpText('Press ~INPUT_CONTEXT~ to request a free bike')
                if pressedInteract() then
                    TriggerServerEvent('cnr:server:requestPrisonBikeShop')
                end
            elseif nearFood then
                wait = 0
                helpText('Press ~INPUT_CONTEXT~ for the prison canteen')
                if pressedInteract() then
                    TriggerServerEvent('cnr:server:requestPrisonFood')
                end
            elseif nearStore then
                wait = 0
                local isLiquor = nearStore.name and nearStore.name:find('Liquor') ~= nil
                helpText(isLiquor and 'Press ~INPUT_CONTEXT~ to buy drinks'
                                   or 'Press ~INPUT_CONTEXT~ to buy snacks & drinks')
                if pressedInteract() then
                    TriggerServerEvent('cnr:server:requestFoodShop', { kind = isLiquor and 'liquor' or 'store' })
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('cnr:client:openAmmuShop', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openAmmuShop then
        CnR.NativeMenus.openAmmuShop(payload or {})
    end
end)

RegisterNetEvent('cnr:client:openDealership', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openDealership then
        CnR.NativeMenus.openDealership(payload or {})
    end
end)

RegisterNetEvent('cnr:client:openFoodShop', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openFoodShop then
        CnR.NativeMenus.openFoodShop(payload or {})
    end
end)

-- After a store purchase: confirm it and re-open the shop with updated cash, landing on
-- the same row so it feels instant rather than stale.
RegisterNetEvent('cnr:client:itemPurchased', function(payload)
    if type(payload) ~= 'table' then return end
    if CnR.NativeUI and CnR.NativeUI.notify then
        CnR.NativeUI.notify('Purchased ' .. (payload.label or 'item') .. '.')
    end
    if payload.kind and CnR.NativeMenus and CnR.NativeMenus.openFoodShop then
        local inv = Config.Inventory or {}
        local list = (payload.kind == 'liquor') and (inv.liquorShopMenu or {}) or (inv.foodShopMenu or {})
        CnR.NativeMenus.openFoodShop({
            menu   = list,
            prices = inv.foodShopPrices or {},
            items  = inv.items or {},
            title  = (payload.kind == 'liquor') and 'Liquor Store' or '24/7 Store',
            kind   = payload.kind,
            cash   = payload.cash,
            select = payload.select,
        })
    end
end)

RegisterNetEvent('cnr:client:openClothingShop', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openClothingShop then
        CnR.NativeMenus.openClothingShop(payload or {})
    end
end)

RegisterNetEvent('cnr:client:applyClothing', function(payload)
    if type(payload) ~= 'table' then return end
    local ped = PlayerPedId()
    local c = payload.components
    if type(c) == 'table' and CnR.Util and CnR.Util.SetComponentSafe then
        if c.top   ~= nil then CnR.Util.SetComponentSafe(ped, 11, c.top or 0, c.topTxt or 0, 0) end
        if c.pants ~= nil then CnR.Util.SetComponentSafe(ped, 4, c.pants or 0, c.pantsTxt or 0, 0) end
        if c.shoes ~= nil then CnR.Util.SetComponentSafe(ped, 6, c.shoes or 0, c.shoesTxt or 0, 0) end
        if c.arms  ~= nil then CnR.Util.SetComponentSafe(ped, 3, c.arms or 0, 0, 0) end
        if c.undershirt ~= nil then CnR.Util.SetComponentSafe(ped, 8, c.undershirt or 0, c.undershirtTxt or 0, 0) end
        if c.mask  ~= nil then CnR.Util.SetComponentSafe(ped, 1, c.mask or 0, c.maskTxt or 0, 0) end
    end
    -- Props: hat = slot 0, glasses = slot 1. drawable < 0 means "remove".
    local pr = payload.props
    if type(pr) == 'table' then
        if pr.hat ~= nil then
            if pr.hat < 0 then ClearPedProp(ped, 0)
            else SetPedPropIndex(ped, 0, pr.hat, pr.hatTxt or 0, true) end
        end
        if pr.glasses ~= nil then
            if pr.glasses < 0 then ClearPedProp(ped, 1)
            else SetPedPropIndex(ped, 1, pr.glasses, pr.glassesTxt or 0, true) end
        end
        if pr.watch ~= nil then  -- watch = prop slot 6
            if pr.watch < 0 then ClearPedProp(ped, 6)
            else SetPedPropIndex(ped, 6, pr.watch, pr.watchTxt or 0, true) end
        end
    end
end)

local function applyBarberSkin(payload)
    if type(payload) ~= 'table' then return end
    local skin = payload.skin or payload
    if type(skin) ~= 'table' then return end
    local ped = PlayerPedId()
    if ped == 0 then return end
    if CnR.Util and CnR.Util.ApplyCustomAppearance then
        CnR.Util.ApplyCustomAppearance(ped, skin, (CnR.State and CnR.State.side) or 'robber', payload.rankId or 1)
    end
end

RegisterNetEvent('cnr:client:openBarberShop', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openBarberShop then
        CnR.NativeMenus.openBarberShop(payload or {})
    end
end)

RegisterNetEvent('cnr:client:applyBarber', applyBarberSkin)
RegisterNetEvent('cnr:client:previewBarber', applyBarberSkin)

RegisterNetEvent('cnr:client:spawnFreePrisonVehicle', function(payload)
    if type(payload) ~= 'table' or not payload.model or not payload.coords then return end
    TriggerEvent('cnr:client:spawnCivilianCar', payload)
end)

RegisterNetEvent('cnr:client:openPrisonFood', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openPrisonFood then
        CnR.NativeMenus.openPrisonFood(payload or {})
    end
end)

RegisterNetEvent('cnr:client:openPrisonBikeShop', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openPrisonBikeShop then
        CnR.NativeMenus.openPrisonBikeShop(payload or {})
    end
end)

RegisterNetEvent('cnr:client:giveWeapon', function(payload)
    if type(payload) ~= 'table' or not payload.weapon then return end
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, GetHashKey(payload.weapon), tonumber(payload.ammo) or 100, false, false)
    if CnR.Weapons and CnR.Weapons.sync then CnR.Weapons.sync() end
end)

RegisterNetEvent('cnr:client:giveAmmo', function(payload)
    if type(payload) ~= 'table' or not payload.weapon then return end
    local ped = PlayerPedId()
    local hash = GetHashKey(payload.weapon)
    if HasPedGotWeapon(ped, hash, false) then
        AddAmmoToPed(ped, hash, tonumber(payload.amount) or 0)
    else
        GiveWeaponToPed(ped, hash, tonumber(payload.amount) or 0, false, false)
    end
    if CnR.Weapons and CnR.Weapons.sync then CnR.Weapons.sync() end
end)

RegisterNetEvent('cnr:client:applyArmor', function(payload)
    local ped = PlayerPedId()
    SetPedArmour(ped, math.min(100, tonumber(payload and payload.value) or 100))
end)

RegisterNetEvent('cnr:client:applyMedkit', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
end)

local function requestModelBlocking(model)
    local hash = (type(model) == 'string') and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 100 do Wait(50); t = t + 1 end
    return HasModelLoaded(hash) and hash or nil
end

RegisterNetEvent('cnr:client:spawnCivilianCar', function(payload)
    if type(payload) ~= 'table' or not payload.model then return end
    local hash = requestModelBlocking(payload.model)
    if not hash then return end
    local c = payload.coords or {}
    local x, y, z = c.x or 0.0, c.y or 0.0, c.z or 0.0
    local h = c.h or 60.0
    local veh = CreateVehicle(hash, x + 0.0, y + 0.0, z + 0.0, h, true, false)
    SetModelAsNoLongerNeeded(hash)

    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleFixed(veh)
    if CnR.VehiclePreview and CnR.VehiclePreview.applyLivery then
        CnR.VehiclePreview.applyLivery(veh, payload.model)
    end
    if SetVehicleEngineOn then SetVehicleEngineOn(veh, true, true, false) end
    SetEntityAsMissionEntity(veh, true, true)

    local plate = ('CIV-%03d'):format((GetPlayerServerId(PlayerId()) or 0) % 1000)
    SetVehicleNumberPlateText(veh, plate)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
end)
