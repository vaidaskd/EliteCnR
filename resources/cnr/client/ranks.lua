CnR = CnR or {}

local ARMOR_VALUE = { superlight = 20, light = 40, standard = 60, heavy = 80, superheavy = 100 }

local function requestModelBlocking(model)
    local hash = (type(model) == 'string') and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 200 do
        Wait(25); tries = tries + 1
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function disableAutoSpawn()
    if GetResourceState('spawnmanager') == 'started' then
        exports.spawnmanager:setAutoSpawn(false)
    end
end

local function teleportTo(coords)
    if not coords then return end
    local ped = PlayerPedId()
    local x, y, z, h
    local t = type(coords)
    if t == 'vector3' then
        x, y, z, h = coords.x, coords.y, coords.z, 0.0
    elseif t == 'vector4' then
        x, y, z, h = coords.x, coords.y, coords.z, coords.w
    elseif t == 'table' then
        x = coords.x or coords[1]
        y = coords.y or coords[2]
        z = coords.z or coords[3]
        h = coords.w or coords.h or coords[4] or 0.0
    else
        return
    end
    if not (x and y and z) then return end
    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    local timeout = GetGameTimer() + 2000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(0)
    end
    SetEntityCoords(ped, x + 0.0, y + 0.0, z + 0.0, false, false, false, true)
    SetEntityHeading(ped, h + 0.0)
end

local function applySkin(payload)
    if not payload.skin then return end
    if type(payload.skin) == 'table' and payload.skin.isCustom then
        local modelName = (payload.skin.gender == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
        local hash = requestModelBlocking(modelName)
        local ped = PlayerPedId()
        if payload.uniformOnly and payload.side == 'cop' and hash and GetEntityModel(ped) == hash then
            if payload.clothes then
                CnR.Util.ApplyCopClothes(ped, payload.clothes)
            else
                CnR.Util.ApplyCopUniform(ped, payload.skin.gender, payload.outfitId or 1)
            end
            if payload.hideHat then ClearPedProp(ped, 0) end
            return
        end
        if hash and GetEntityModel(PlayerPedId()) ~= hash then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            local t0 = GetGameTimer()
            while GetEntityModel(PlayerPedId()) ~= hash and GetGameTimer() - t0 < 5000 do
                Wait(0)
            end
            Wait(100)
        end
        ped = PlayerPedId()
        CnR.Util.ApplyCustomAppearance(ped, payload.skin, payload.side, payload.outfitId or 1)
        -- A player-built Police Clothing uniform overrides the default outfit.
        if payload.side == 'cop' and payload.clothes then
            CnR.Util.ApplyCopClothes(ped, payload.clothes)
        end
        if payload.side == 'cop' and payload.hideHat then ClearPedProp(ped, 0) end
    else
        local hash = requestModelBlocking(payload.skin)
        if hash then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            Wait(100)
        end
    end
end

RegisterNetEvent('cnr:client:applyLoadout', function(payload)
    if type(payload) ~= 'table' then return end

    CnR._loadoutApplied = true  -- Release the boot black-screen hold loop
    CnR._applyingLoadout = true -- In-flight guard: jail waits for the skin to finish (see jail.lua) #skinfix

    disableAutoSpawn()
    DoScreenFadeOut(200)
    Wait(250)

    if payload.spawn then teleportTo(payload.spawn) end

    -- Delete any vehicle the engine placed the player in at spawn.
    local spawnVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if spawnVeh ~= 0 then DeleteVehicle(spawnVeh) end

    applySkin(payload)

    -- Cop accessories (glasses / watch) bought at the clothing store. The uniform itself
    -- strips prop 1, so these are re-applied here AFTER dressing so the purchase persists
    -- across deaths and reconnects. Robbers get theirs inside ApplyCustomAppearance. #4
    if payload.side == 'cop' and type(payload.skin) == 'table' and CnR.Util and CnR.Util.SetPropSafe then
        local sk = payload.skin
        local cped = PlayerPedId()
        CnR.Util.SetPropSafe(cped, 1, tonumber(sk.glasses) or -1, tonumber(sk.glassesTxt) or 0, true)
        CnR.Util.SetPropSafe(cped, 6, tonumber(sk.watch)   or -1, tonumber(sk.watchTxt)   or 0, true)
    end

    -- Re-apply saved tattoos after the skin/model has settled (a model change clears
    -- decorations, so this restores them on every spawn).
    SetTimeout(900, function()
        TriggerServerEvent('cnr:server:requestTattoos')
    end)

    local ped = PlayerPedId()
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))

    if payload.armor then
        SetPedArmour(ped, ARMOR_VALUE[payload.armor] or 50)
    else
        -- No armor tier (robbers) → spawn with zero armor. Clears any carryover from a
        -- previous cop life; they can still buy armor at Ammu-Nation.
        SetPedArmour(ped, 0)
    end

    RemoveAllPedWeapons(ped, true)
    local pistolHash = nil
    for _, w in ipairs(payload.weapons or {}) do
        local ammo = (payload.ammo and payload.ammo[w]) or 100
        local hash = GetHashKey(w)
        GiveWeaponToPed(ped, hash, ammo, false, false)
        if w:find('PISTOL') and not pistolHash then
            pistolHash = hash
        end
    end
    if pistolHash then
        SetCurrentPedWeapon(ped, pistolHash, true)
    end

    if payload.spawn then teleportTo(payload.spawn) end

    if CnR.Weapons and CnR.Weapons.sync then
        SetTimeout(500, function()
            CnR.Weapons.sync()
        end)
    end
    if CnR.Position and CnR.Position.sync then
        SetTimeout(500, function()
            CnR.Position.sync()
        end)
    end

    local me = PlayerPedId()
    FreezeEntityPosition(me, false)
    SetEntityVisible(me, true, false)
    SetEntityInvincible(me, false)
    SetPlayerControl(PlayerId(), true, 0)
    DoScreenFadeIn(400)
    CnR._applyingLoadout = false   -- skin fully applied — jail may now dress the jumpsuit #skinfix
end)

-- Rank/level system removed (credits only) — no "You are now <rank>" feed message.
RegisterNetEvent('cnr:client:rankApplied', function() end)

-- Level-up: add newly unlocked weapons/armor in place, without wiping the current
-- arsenal or triggering a fade/respawn.
RegisterNetEvent('cnr:client:levelGrant', function(payload)
    if type(payload) ~= 'table' then return end
    local ped = PlayerPedId()
    for _, w in ipairs(payload.weapons or {}) do
        local hash = GetHashKey(w)
        if not HasPedGotWeapon(ped, hash, false) then
            local ammo = (payload.ammo and payload.ammo[w]) or 100
            GiveWeaponToPed(ped, hash, ammo, false, false)
        end
    end
    if payload.armor then
        local armorVal = ARMOR_VALUE[payload.armor] or 50
        if GetPedArmour(ped) < armorVal then SetPedArmour(ped, armorVal) end
    end
    if CnR.Weapons and CnR.Weapons.sync then CnR.Weapons.sync() end
end)

-- Police Clothing: apply just the chosen uniform components in place.
RegisterNetEvent('cnr:client:applyOutfit', function(payload)
    if type(payload) ~= 'table' then return end
    local ped = PlayerPedId()
    if payload.clothes and CnR.Util and CnR.Util.ApplyCopClothes then
        CnR.Util.ApplyCopClothes(ped, payload.clothes)
    elseif CnR.Util and CnR.Util.ApplyCopUniform then
        local gender = (type(payload.skin) == 'table' and payload.skin.gender) or 'male'
        CnR.Util.ApplyCopUniform(ped, gender, payload.outfitId or 1)
    end
    if payload.hideHat then ClearPedProp(ped, 0) end
end)

AddEventHandler('onClientMapStart', function()
    disableAutoSpawn()
end)
