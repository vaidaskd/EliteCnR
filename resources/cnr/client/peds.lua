CnR = CnR or {}

local SPAWNED = {}
local expectedSpawnCount = 0

local function loadModel(model)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local t = 0
        while not HasModelLoaded(hash) and t < 100 do Wait(50); t = t + 1 end
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function spawnPed(model, x, y, z, heading, name, zOffset, opts)
    local hash = loadModel(model)
    if not hash then return nil end

    local spawnZ = (z + 0.0) + (zOffset or 0.0)
    RequestCollisionAtCoord(x + 0.0, y + 0.0, spawnZ)
    local ped = CreatePed(4, hash, x + 0.0, y + 0.0, spawnZ, heading or 0.0, false, true)
    if not ped or ped == 0 then return nil end
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetEntityCanBeDamaged(ped, false)
    SetEntityAsMissionEntity(ped, true, true)
    if opts and opts.copUniform and CnR.Util and CnR.Util.NormalizeCopSkin and CnR.Util.ApplyCustomAppearance then
        local gender = (model == 'mp_f_freemode_01') and 'female' or 'male'
        local skin = CnR.Util.NormalizeCopSkin(gender)
        CnR.Util.ApplyCustomAppearance(ped, skin, 'cop', opts.outfitId or 1)
    end
    if opts and opts.freezeExact then
        -- Place at the EXACT given coords and freeze immediately — no ground snap.
        -- Used for peds in interiors (e.g. Bolingbroke canteen) whose collision isn't
        -- streamed at spawn time, where PlaceObjectOnGroundProperly makes them fall.
        SetEntityCoordsNoOffset(ped, x + 0.0, y + 0.0, spawnZ, false, false, false)
        FreezeEntityPosition(ped, true)
    else
        CreateThread(function()
            local untilTime = GetGameTimer() + 1200
            while DoesEntityExist(ped) and not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < untilTime do
                Wait(0)
            end
            Wait(350)
            if DoesEntityExist(ped) then
                PlaceObjectOnGroundProperly(ped)
                Wait(100)
                -- Nudge up slightly so feet sit on the surface rather than clipping into it.
                local c = GetEntityCoords(ped)
                SetEntityCoordsNoOffset(ped, c.x, c.y, c.z + 0.08, false, false, false)
                Wait(50)
                FreezeEntityPosition(ped, true)
            end
        end)
    end
    SetModelAsNoLongerNeeded(hash)
    SPAWNED[#SPAWNED + 1] = ped
    return ped
end

CnR.Peds = CnR.Peds or {}
local NAMED = {}

local function spawnNamed(key, model, x, y, z, h, label, zOffset)
    local ped = spawnPed(model, x, y, z, h, label, zOffset)
    if ped then NAMED[key] = ped end
    return ped
end

function CnR.Peds.get(key) return NAMED[key] end

local DESK_NPCS = {}
local ARMORY_NPCS = {}
local GARAGE_NPCS = {}

local function npcPointFromConfig(key, npcCfg, label)
    if not npcCfg or not npcCfg.pos then return end
    local p = npcCfg.pos
    return {
        model = npcCfg.model or 'mp_m_freemode_01',
        x = p.x, y = p.y, z = p.z, h = p.w or p.h or 0.0,
        zOffset = npcCfg.zOffset or 0.0,
        label = label,
        copUniform = true,
    }
end

local function buildStationNpcs()
    DESK_NPCS = {}
    ARMORY_NPCS = {}
    GARAGE_NPCS = {}
    if not (Config and Config.PoliceStations) then return end
    for key, st in pairs(Config.PoliceStations) do
        local desk = npcPointFromConfig(key, st.deskNpc, st.label .. ' Police Clothing')
        local armory = npcPointFromConfig(key, st.armoryNpc, st.label .. ' Armory Officer')
        local garage = npcPointFromConfig(key, st.garageNpc, st.label .. ' Garage Officer')
        if desk then DESK_NPCS[key] = desk end
        if armory then ARMORY_NPCS[key] = armory end
        if garage then GARAGE_NPCS[key] = garage end
    end
end

local function spawnAll()
    buildStationNpcs()

    if Config and Config.Stores then
        for _, s in ipairs(Config.Stores) do
            if s.ped and s.ped.x then
                spawnPed('mp_m_shopkeep_01', s.ped.x, s.ped.y, s.ped.z, s.ped.w or 0.0, s.name, -1.0)
            end
        end
    end

    if Config and Config.Banks then
        for _, b in ipairs(Config.Banks) do
            local p = b.ped or b.teller
            if p and p.x then
                spawnPed('ig_bankman', p.x, p.y, p.z, p.w or 0.0, b.name, -1.0)
            end
        end
    end

    if Config and Config.Blips and Config.Blips.ammunation then
        for i, a in ipairs(Config.Blips.ammunation) do
            local ped = spawnPed('s_m_y_ammucity_01', a.pos.x, a.pos.y, a.pos.z, a.heading or 180.0, a.name, -1.0)
            if ped then NAMED['ammu:' .. i] = ped end
        end
    end

    if Config and Config.Blips and Config.Blips.clothing then
        for _, c in ipairs(Config.Blips.clothing) do
            spawnPed('s_f_y_shop_low', c.pos.x, c.pos.y, c.pos.z, c.heading or 180.0, c.name, -1.0)
        end
    end

    if Config and Config.Blips and Config.Blips.jewelry then
        for _, j in ipairs(Config.Blips.jewelry) do
            spawnPed('s_f_y_shop_mid', j.pos.x, j.pos.y, j.pos.z, j.heading or 180.0, j.name, -1.0)
        end
    end

    if Config and Config.Blips and Config.Blips.dealership then
        for i, d in ipairs(Config.Blips.dealership) do
            local p = d.ped or d.pos
            local px, py, pz = p.x, p.y, p.z
            local ph = (d.ped and d.ped.w) or d.heading or 0.0
            local ped = spawnPed('a_m_y_business_01', px, py, pz, ph, d.name, -1.0)
            if ped then NAMED['dealer:' .. i] = ped end
        end
    end

    if Config and Config.PrisonBikeNpc then
        local bikeCfg = Config.PrisonBikeNpc
        local locations = bikeCfg.locations or { bikeCfg }
        for i, vendor in ipairs(locations) do
            local p = vendor.pos
            if p then
                spawnNamed('prison:bikes:' .. i, vendor.model or bikeCfg.model or 's_m_y_prismuscl_01',
                    p.x, p.y, p.z, p.w or 0.0, vendor.name or 'Prison Bike Rental', vendor.zOffset or bikeCfg.zOffset)
            end
        end
    end

    if Config and Config.PrisonFoodNpc and Config.PrisonFoodNpc.pos then
        local f = Config.PrisonFoodNpc
        local p = f.pos
        -- Spawn at the exact configured coords and freeze there (no ground snap), so the
        -- canteen guard stands firmly on the floor instead of falling through the interior.
        local ped = spawnPed(f.model or 's_m_m_prisguard_01',
            p.x, p.y, p.z, p.w or 0.0, f.label or 'Prison Canteen', f.zOffset, { freezeExact = true })
        if ped then NAMED['prison:food'] = ped end
    end

    for key, n in pairs(DESK_NPCS) do
        local ped = spawnPed(n.model, n.x, n.y, n.z, n.h, n.label, n.zOffset, { copUniform = n.copUniform, outfitId = 1 })
        if ped then NAMED['desk:' .. key] = ped end
    end
    if Config and Config.PoliceStations then
        for key, st in pairs(Config.PoliceStations) do
            if st.extraDeskNpcs then
                for i, npc in ipairs(st.extraDeskNpcs) do
                    local p = npc.pos
                    if p then
                        local ped = spawnPed(npc.model or 'mp_f_freemode_01', p.x, p.y, p.z, p.w or 0.0,
                            (st.label or key) .. ' Police Clothing', npc.zOffset or 0.0, { copUniform = true, outfitId = 1 })
                        if ped then NAMED['desk:' .. key .. ':' .. i] = ped end
                    end
                end
            end
        end
    end
    for key, n in pairs(ARMORY_NPCS) do
        local ped = spawnPed(n.model, n.x, n.y, n.z, n.h, n.label, n.zOffset, { copUniform = n.copUniform, outfitId = 2 })
        if ped then NAMED['armory:' .. key] = ped end
    end
    for key, n in pairs(GARAGE_NPCS) do
        local ped = spawnPed(n.model, n.x, n.y, n.z, n.h, n.label, n.zOffset, { copUniform = n.copUniform, outfitId = 2 })
        if ped then NAMED['garage:' .. key] = ped end
    end
    for _, h in ipairs((Config and Config.HeliNpcs) or {}) do
        local p = h.pos
        if p then
            local ped = spawnPed(h.model or 'mp_m_freemode_01', p.x, p.y, p.z, p.w or 0.0,
                'Police Air Support', h.zOffset or -1.0, { copUniform = true, outfitId = 2 })
            if ped then NAMED['heli:' .. (h.key or '?')] = ped end
        end
    end

    expectedSpawnCount = #SPAWNED
    CnR.Util.log('info', 'spawned %d shop/yard peds', #SPAWNED)
end

local function clearAll()
    for _, ped in ipairs(SPAWNED) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    SPAWNED = {}
    NAMED = {}
    expectedSpawnCount = 0
end

local function aliveCount()
    local n = 0
    for _, ped in ipairs(SPAWNED) do
        if DoesEntityExist(ped) then n = n + 1 end
    end
    return n
end

CnR.Peds.deskNPCs = DESK_NPCS
CnR.Peds.armoryNPCs = ARMORY_NPCS
CnR.Peds.garageNPCs = GARAGE_NPCS
CnR.Peds.heliNpcs = (function()
    local out = {}
    for _, h in ipairs((Config and Config.HeliNpcs) or {}) do
        if h.pos then out[#out + 1] = { key = h.key, pos = vector3(h.pos.x, h.pos.y, h.pos.z) } end
    end
    return out
end)()
CnR.Peds.lockerNPCs = DESK_NPCS

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(3000)
    spawnAll()
    CnR.Peds.deskNPCs = DESK_NPCS
    CnR.Peds.armoryNPCs = ARMORY_NPCS
    CnR.Peds.garageNPCs = GARAGE_NPCS
    CnR.Peds.lockerNPCs = DESK_NPCS
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    while true do
        Wait(15000)
        if expectedSpawnCount > 0 and aliveCount() < expectedSpawnCount then
            CnR.Util.log('warn', 'NPC watchdog detected missing peds; respawning')
            clearAll()
            Wait(500)
            spawnAll()
            CnR.Peds.deskNPCs = DESK_NPCS
            CnR.Peds.armoryNPCs = ARMORY_NPCS
            CnR.Peds.garageNPCs = GARAGE_NPCS
            CnR.Peds.lockerNPCs = DESK_NPCS
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearAll()
end)
