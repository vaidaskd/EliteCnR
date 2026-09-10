CnR = CnR or {}
CnR.Inventory = CnR.Inventory or {}

local lastSnapshot = { inventory = {}, cash = 0, xp = 0, rankId = 1, jailSecondsRemaining = 0 }

local function buildWeaponList()
    local ped = PlayerPedId()
    if ped == 0 then return {} end
    local out = {}

    local candidates = {
        'WEAPON_PISTOL', 'WEAPON_PISTOL_MK2', 'WEAPON_COMBATPISTOL', 'WEAPON_HEAVYPISTOL',
        'WEAPON_PISTOL50', 'WEAPON_APPISTOL', 'WEAPON_REVOLVER',
        'WEAPON_STUNGUN', 'WEAPON_NIGHTSTICK', 'WEAPON_FLASHLIGHT', 'WEAPON_FLAREGUN',
        'WEAPON_MICROSMG', 'WEAPON_COMBATPDW', 'WEAPON_SMG_MK2',
        'WEAPON_PUMPSHOTGUN', 'WEAPON_PUMPSHOTGUN_MK2',
        'WEAPON_CARBINERIFLE', 'WEAPON_CARBINERIFLE_MK2',
        'WEAPON_ASSAULTRIFLE', 'WEAPON_ASSAULTRIFLE_MK2',
        'WEAPON_BATTLERIFLE', 'WEAPON_MARKSMANRIFLE', 'WEAPON_MARKSMANRIFLE_MK2',
        'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER', 'WEAPON_COMBATMG',
        'WEAPON_FIREEXTINGUISHER', 'WEAPON_SMOKEGRENADE',
    }
    for _, w in ipairs(candidates) do
        local hash = GetHashKey(w)
        if HasPedGotWeapon(ped, hash, false) then
            local ammo = GetAmmoInPedWeapon(ped, hash)
            out[#out + 1] = { name = w, ammo = ammo or 0 }
        end
    end
    return out
end

local function openInventory()
    if CnR.NativeUI.isOpen() then
        CnR.NativeUI.closeAll()
        return
    end
    TriggerServerEvent('cnr:server:requestInventory')
    Wait(150)
    if CnR.NativeMenus and CnR.NativeMenus.openInventory then
        CnR.NativeMenus.openInventory({
            inventory = lastSnapshot.inventory or {},
            cash      = lastSnapshot.cash or 0,
            xp        = lastSnapshot.xp or 0,
            weapons   = buildWeaponList(),
            items     = (Config.Inventory and Config.Inventory.items) or {},
        })
    end
end

CnR.Inventory.open = openInventory
CnR.Inventory.close = function() CnR.NativeUI.closeAll() end

local kb = (Config.Keybinds and Config.Keybinds.inventory) or { key = 'i', description = 'CnR: Open inventory & player status' }
RegisterCommand('+cnr_inventory_open', function() openInventory() end, false)
RegisterCommand('-cnr_inventory_open', function() end, false)
RegisterKeyMapping('+cnr_inventory_open', kb.description, 'keyboard', kb.key)

RegisterCommand('inventory', function() openInventory() end, false)

RegisterNetEvent('cnr:client:inventoryUpdate', function(payload)
    if type(payload) ~= 'table' then return end
    if payload.inventory then lastSnapshot.inventory = payload.inventory end
    if payload.cash  ~= nil then lastSnapshot.cash = payload.cash end
    if payload.xp    ~= nil then lastSnapshot.xp = payload.xp end
    if payload.rankId ~= nil then lastSnapshot.rankId = payload.rankId end
    if payload.jailSecondsRemaining ~= nil then lastSnapshot.jailSecondsRemaining = payload.jailSecondsRemaining end
end)

local consuming = false

local function applyHeal(amount)
    if amount and amount > 0 then
        local ped = PlayerPedId()
        SetEntityHealth(ped, math.min(GetEntityHealth(ped) + amount, GetEntityMaxHealth(ped)))
    end
end

-- Plays the eat/drink/smoke animation with the item held in hand, then heals.
RegisterNetEvent('cnr:client:itemConsumed', function(payload)
    if type(payload) ~= 'table' then return end
    local key  = payload.key
    local def  = key and Config.Inventory and Config.Inventory.items and Config.Inventory.items[key] or nil
    local heal = tonumber(payload.heal) or (def and def.heal) or 0

    -- Animation/prop/scenario may come inline on the payload (e.g. prison food, which has
    -- no inventory item) or from the item def.
    local anim     = payload.anim     or (def and def.anim)
    local scenario = payload.scenario or (def and def.scenario)
    local prop     = payload.prop     or (def and def.prop)
    local scenTime = payload.time     or (def and def.time)

    -- No animation requested (or already busy) -> just heal instantly.
    if consuming or (not anim and not scenario) then
        applyHeal(heal)
        return
    end

    consuming = true
    CreateThread(function()
        local ped = PlayerPedId()

        if scenario then
            -- e.g. smoking — the scenario brings its own prop + animation.
            TaskStartScenarioInPlace(ped, scenario, 0, true)
            Wait(scenTime or 6000)
            ClearPedTasks(ped)
        else
            if anim.dict then
                RequestAnimDict(anim.dict)
                local t = GetGameTimer() + 1500
                while not HasAnimDictLoaded(anim.dict) and GetGameTimer() < t do Wait(10) end
            end

            -- Attach the item prop to the right hand. Accept a single model or a list of
            -- candidates and use the first that actually LOADS (don't gate on IsModelValid —
            -- it wrongly rejected the Sprunk can, so it fell back to the eCola can).
            local obj, p = nil, prop
            if p and (p.model or p.models) then
                local candidates = p.models or { p.model }
                local m
                for _, name in ipairs(candidates) do
                    local h = GetHashKey(name)
                    if IsModelInCdimage(h) then
                        RequestModel(h)
                        local t = GetGameTimer() + 2500
                        while not HasModelLoaded(h) and GetGameTimer() < t do Wait(10) end
                        if HasModelLoaded(h) then m = h; break end
                    end
                end
                if not m then
                    print(('[cnr] consumable prop model failed to load for %s'):format(tostring(payload.key)))
                else
                    local c = GetEntityCoords(ped)
                    obj = CreateObject(m, c.x, c.y, c.z, true, true, false)
                    local bone = GetPedBoneIndex(ped, p.bone or 18905)
                    AttachEntityToEntity(obj, ped, bone,
                        p.pos and p.pos.x or 0.0, p.pos and p.pos.y or 0.0, p.pos and p.pos.z or 0.0,
                        p.rot and p.rot.x or 0.0, p.rot and p.rot.y or 0.0, p.rot and p.rot.z or 0.0,
                        true, true, false, true, 1, true)
                    SetModelAsNoLongerNeeded(m)
                end
            end

            if anim.dict and HasAnimDictLoaded(anim.dict) then
                TaskPlayAnim(ped, anim.dict, anim.name, 4.0, -4.0, anim.time or 3000, anim.flag or 49, 0.0, false, false, false)
            end
            Wait(anim.time or 3000)

            if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
            ClearPedTasks(ped)
            if anim.dict then RemoveAnimDict(anim.dict) end
        end

        applyHeal(heal)
        consuming = false
    end)
end)
