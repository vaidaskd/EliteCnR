CnR = CnR or {}

RegisterNetEvent('cnr:client:openArmory', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openArmory then
        CnR.NativeMenus.openArmory(payload)
    end
end)

RegisterNetEvent('cnr:client:armoryRefill', function(payload)
    if type(payload) ~= 'table' then return end
    local ped = PlayerPedId()
    for _, w in ipairs(payload.weapons or {}) do
        local hash = GetHashKey(w)
        if HasPedGotWeapon(ped, hash, false) then
            local ammo = (payload.ammo and payload.ammo[w]) or 100
            SetPedAmmo(ped, hash, ammo)
        else
            GiveWeaponToPed(ped, hash, (payload.ammo and payload.ammo[w]) or 100, false, false)
        end
    end
    if CnR.Weapons and CnR.Weapons.sync then CnR.Weapons.sync() end
end)

RegisterNetEvent('cnr:client:armoryEquip', function(payload)
    if type(payload) ~= 'table' or not payload.weapon then return end
    local ped = PlayerPedId()
    local hash = GetHashKey(payload.weapon)
    local ammo = tonumber(payload.ammo) or 100
    if not HasPedGotWeapon(ped, hash, false) then
        GiveWeaponToPed(ped, hash, ammo, false, false)
    end
    SetCurrentPedWeapon(ped, hash, true)
    if CnR.Weapons and CnR.Weapons.sync then CnR.Weapons.sync() end
    -- Single clean notice in the game feed only (no NUI toast, no [CnR] tag).
    -- Prefer the server-provided proper-case label (e.g. "Pistol") over the raw hash name.
    local label = payload.label
    if not label or label == '' then
        label = (payload.weapon:gsub('WEAPON_', ''):gsub('GADGET_', ''))
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('Equipped ' .. label)
    EndTextCommandThefeedPostTicker(false, true)
end)

RegisterNetEvent('cnr:client:armoryArmor', function(payload)
    if type(payload) ~= 'table' then return end
    local ped = PlayerPedId()
    SetPedArmour(ped, math.max(0, math.min(100, tonumber(payload.value) or 0)))
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('Equipped ' .. tostring(payload.label or 'Armor'))
    EndTextCommandThefeedPostTicker(false, true)
end)
