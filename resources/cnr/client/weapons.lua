CnR = CnR or {}
CnR.Weapons = CnR.Weapons or {}

local TRACKED_WEAPONS = {
    'WEAPON_PISTOL', 'WEAPON_PISTOL_MK2', 'WEAPON_COMBATPISTOL', 'WEAPON_HEAVYPISTOL',
    'WEAPON_PISTOL50', 'WEAPON_APPISTOL', 'WEAPON_REVOLVER',
    'WEAPON_STUNGUN', 'WEAPON_NIGHTSTICK', 'WEAPON_FLASHLIGHT', 'WEAPON_FLAREGUN',
    'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_COMBATPDW', 'WEAPON_SMG_MK2',
    'WEAPON_PUMPSHOTGUN', 'WEAPON_PUMPSHOTGUN_MK2', 'WEAPON_SAWNOFFSHOTGUN',
    'WEAPON_CARBINERIFLE', 'WEAPON_CARBINERIFLE_MK2',
    'WEAPON_ASSAULTRIFLE', 'WEAPON_ASSAULTRIFLE_MK2', 'WEAPON_BATTLERIFLE',
    'WEAPON_MARKSMANRIFLE', 'WEAPON_MARKSMANRIFLE_MK2',
    'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER', 'WEAPON_COMBATMG',
    'WEAPON_FIREEXTINGUISHER', 'WEAPON_SMOKEGRENADE', 'GADGET_PARACHUTE',
}

function CnR.Weapons.collectFromPed(ped)
    ped = ped or PlayerPedId()
    local weapons, ammo = {}, {}
    if ped == 0 then return weapons, ammo end

    for _, w in ipairs(TRACKED_WEAPONS) do
        local hash = GetHashKey(w)
        if HasPedGotWeapon(ped, hash, false) then
            weapons[#weapons + 1] = w
            ammo[w] = GetAmmoInPedWeapon(ped, hash) or 0
        end
    end
    return weapons, ammo
end

function CnR.Weapons.sync()
    local side = CnR.State and CnR.State.side
    if not side or side == CnR.Sides.NONE then return end
    local weapons, ammo = CnR.Weapons.collectFromPed()
    TriggerServerEvent('cnr:server:syncWeapons', {
        weapons = weapons,
        ammo    = ammo,
    })
end

CreateThread(function()
    while true do
        Wait(45000)
        CnR.Weapons.sync()
    end
end)

-- Players must never leave a weapon pickup behind when they die. Otherwise others
-- walk over it and acquire out-of-loadout guns (e.g. a shotgun), which the sync
-- would then persist. Re-asserted periodically since the flag resets on respawn.
CreateThread(function()
    while true do
        Wait(3000)
        local ped = PlayerPedId()
        if ped ~= 0 then
            SetPedDropsWeaponsWhenDead(ped, false)
        end
    end
end)

-- NPCs must NOT drop their weapons when killed either — that's how a random shotgun
-- ended up on a player (kill an armed NPC, walk over the dropped gun, auto-pickup). #5
CreateThread(function()
    while true do
        Wait(2000)
        for _, p in ipairs(GetGamePool('CPed')) do
            if p ~= 0 and not IsPedAPlayer(p) then
                SetPedDropsWeaponsWhenDead(p, false)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    CnR.Weapons.sync()
end)
