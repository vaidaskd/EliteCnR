local doorStates = {}
local doorBaselines = {}
local doorSystemIds = {}
local doorEntities = {}
local localSide = nil

local function clearDoorCache()
    doorEntities = {}
    doorSystemIds = {}
    for _, door in ipairs(Config.DoorList or {}) do
        door._entity = nil
        if door.doors then
            for _, def in ipairs(door.doors) do
                def._entity = nil
            end
        end
    end
end

local function doorCenter(door)
    if not door then return nil end
    if door.objCoords then return door.objCoords end
    if door.doors and door.doors[1] then return door.doors[1].objCoords end
    if door.textCoords then return door.textCoords end
    return nil
end

local function nearDoor2d(pos, door, radius)
    radius = radius or Config.AutoDistance or 2.0
    if door.doors then
        for _, def in ipairs(door.doors) do
            if def.objCoords then
                local dx, dy = pos.x - def.objCoords.x, pos.y - def.objCoords.y
                if math.sqrt(dx * dx + dy * dy) <= radius then return true end
            end
        end
    end

    local center = doorCenter(door)
    if not center then return false end
    local dx, dy = pos.x - center.x, pos.y - center.y
    return math.sqrt(dx * dx + dy * dy) <= radius
end

local function findOneDoorObject(def)
    if def._entity and DoesEntityExist(def._entity) then
        return def._entity
    end

    local center = def.objCoords

    -- GetClosestObjectOfType is more reliable than pool iteration — it uses the
    -- game's spatial index and works for entities that may not appear in CObject.
    if def.objHash then
        local obj = GetClosestObjectOfType(center.x, center.y, center.z, 5.0, def.objHash, false, false, false)
        if obj and obj ~= 0 and DoesEntityExist(obj) then
            def._entity = obj
            return obj
        end
    end

    -- Fallback: scan CObject pool with a relaxed 3-unit radius
    local best, bestD = 0, 3.0
    local objects = GetGamePool('CObject')

    for i = 1, #objects do
        local obj = objects[i]
        if DoesEntityExist(obj) and GetEntityModel(obj) == def.objHash then
            local dist = #(GetEntityCoords(obj) - center)
            if dist < bestD then
                best = obj
                bestD = dist
            end
        end
    end

    if best ~= 0 then
        def._entity = best
        return best
    end
    return nil
end

local function ensureDoorSystem(doorId, index, def)
    doorSystemIds[doorId] = doorSystemIds[doorId] or {}
    if doorSystemIds[doorId][index] then return doorSystemIds[doorId][index] end

    local id = GetHashKey(('cnr_doorlock_%s_%s'):format(doorId, index))
    doorSystemIds[doorId][index] = id
    if AddDoorToSystem then
        AddDoorToSystem(id, def.objHash, def.objCoords.x, def.objCoords.y, def.objCoords.z, false, false, false)
    end
    return id
end

local function findDoorObjects(door)
    if doorEntities[door._id or 0] then
        local cached = doorEntities[door._id or 0]
        local valid = true
        for _, match in ipairs(cached) do
            if not (match.entity and DoesEntityExist(match.entity)) then
                valid = false
                break
            end
        end
        if valid then return cached end
    end

    local found = {}
    if door.doors then
        for idx, def in ipairs(door.doors) do
            ensureDoorSystem(door._id or 0, idx, def)
            local obj = findOneDoorObject(def)
            if obj then
                found[#found + 1] = { entity = obj, def = def, index = idx }
            end
        end
        doorEntities[door._id or 0] = found
        return found
    end

    ensureDoorSystem(door._id or 0, 1, door)
    local obj = findOneDoorObject(door)
    if obj then
        found[#found + 1] = { entity = obj, def = door, index = 1 }
    end

    doorEntities[door._id or 0] = found
    return found
end

local function objectKey(obj)
    local c = GetEntityCoords(obj)
    return ('%s:%.2f:%.2f:%.2f'):format(GetEntityModel(obj), c.x, c.y, c.z)
end

local function ensureBaseline(obj)
    local key = objectKey(obj)
    if not doorBaselines[key] then
        local c = GetEntityCoords(obj)
        doorBaselines[key] = {
            coords = vector3(c.x, c.y, c.z),
            heading = GetEntityHeading(obj),
        }
    end
    return doorBaselines[key]
end

local function applyDoorState(doorId)
    local door = Config.DoorList[doorId]
    if not door then return end
    door._id = doorId
    local locked = doorStates[doorId]

    -- GTA V's native door system is sufficient for all standard interior doors.
    -- SetStateOfClosestDoorOfType alone handles lock/unlock animation correctly
    -- without disrupting the engine's own door physics.
    local natDefs = door.doors or { door }
    for _, def in ipairs(natDefs) do
        if def.objHash and def.objCoords then
            local c = def.objCoords
            SetStateOfClosestDoorOfType(def.objHash, c.x, c.y, c.z, locked and 1 or 0, def.objHeading or 0.0, false)
        end
    end

    -- permanentLocked doors are managed entirely by the per-frame enforcement thread.
    -- Do NOT touch them here — calling GetEntityHeading() on a door that is mid-swing
    -- and passing it to SetStateOfClosestDoorOfType() would lock the door at the open
    -- angle, causing the "snaps to open position" bug.
end

local function displayCoordsForDoor(door)
    door._id = door._id or 0
    local matches = findDoorObjects(door)
    if matches[1] and matches[1].entity and DoesEntityExist(matches[1].entity) then
        local coords = GetEntityCoords(matches[1].entity)
        return vector3(coords.x, coords.y, coords.z + 0.65)
    end
    return door.textCoords
end

RegisterNetEvent('cnr_doorlock:setState', function(doorId, locked)
    doorId = tonumber(doorId)
    if not doorId then return end
    doorStates[doorId] = locked == true
    applyDoorState(doorId)
end)

RegisterNetEvent('cnr_doorlock:setStateBulk', function(states)
    if type(states) ~= 'table' then return end
    doorStates = states
    for i in ipairs(Config.DoorList or {}) do
        if doorStates[i] == nil then doorStates[i] = Config.DoorList[i].locked ~= false end
        applyDoorState(i)
    end
end)

RegisterNetEvent('cnr_doorlock:setLocalSide', function(side)
    localSide = side == 'cop' and 'cop' or side == 'robber' and 'robber' or 'none'
    clearDoorCache()
    TriggerServerEvent('cnr_doorlock:requestState')
end)

CreateThread(function()
    Wait(2500)
    TriggerServerEvent('cnr_doorlock:requestState')
end)

AddStateBagChangeHandler('cnrSide', nil, function(bagName, _, value)
    if bagName == ('player:%s'):format(GetPlayerServerId(PlayerId())) then
        localSide = value == 'cop' and 'cop' or value == 'robber' and 'robber' or 'none'
        if localSide == 'cop' then
            clearDoorCache()
            TriggerServerEvent('cnr_doorlock:requestState')
        end
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if ped ~= 0 then
            local pos = GetEntityCoords(ped)
            for i, door in ipairs(Config.DoorList or {}) do
                if not door.permanentLocked and nearDoor2d(pos, door, door.autoDistance or Config.AutoDistance or 2.0) then
                    TriggerServerEvent('cnr_doorlock:nearDoor', i)
                end
            end
        end
    end
end)

-- Debug: scan all objects near the player and report model hashes + coords
-- Usage: /doorscan [radius]  (default 5.0)
RegisterCommand('doorscan', function(src, args)
    local radius = tonumber(args[1]) or 5.0
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local objects = GetGamePool('CObject')
    local found = {}
    for i = 1, #objects do
        local obj = objects[i]
        if DoesEntityExist(obj) then
            local c = GetEntityCoords(obj)
            local dx, dy, dz = pos.x - c.x, pos.y - c.y, pos.z - c.z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist <= radius then
                local hash = GetEntityModel(obj)
                -- Try to reverse the hash name from known vespucci models
                local knownModels = {
                    'jail_grel','jail_door','d_l_gate','d_r_gate','d_l_gate_big','d_r_gate_big',
                    'facgate_centr','facgate_l','facgate_r','stair_door','wall_gate',
                    'v_ilev_ph_cellgate','v_ilev_ph_door01','v_ilev_ph_door002',
                    'd_1_l','d_1_r','d_2_l1','d_2_r1','d_2_l2','d_2_r2',
                }
                local name = tostring(hash)
                for _, m in ipairs(knownModels) do
                    if GetHashKey(m) == hash then name = m; break end
                end
                local frozen = IsEntityPositionFrozen(obj)
                local mission = IsEntityAMissionEntity(obj)
                found[#found+1] = ('obj=%d model=%s h=%.1f dist=%.2f pos=%.2f,%.2f,%.2f frozen=%s mission=%s'):format(obj, name, GetEntityHeading(obj), dist, c.x, c.y, c.z, tostring(frozen), tostring(mission))
            end
        end
    end
    -- Output goes to both chat and the F8 client console (console has scrollback).
    print(('[doorscan] ===== %d objects within %.1f units ====='):format(#found, radius))
    if #found == 0 then
        TriggerEvent('chat:addMessage', { args = { '[doorscan]', ('No objects in GetGamePool within %.1f units'):format(radius) } })
    else
        for _, msg in ipairs(found) do
            print('[doorscan] ' .. msg)
            TriggerEvent('chat:addMessage', { args = { '[doorscan]', msg } })
        end
    end
    print('[doorscan] ===== end =====')
    -- Also try GetClosestObjectOfType for known models
    local models = {'jail_grel','jail_door','d_l_gate','d_r_gate','facgate_centr','facgate_l','facgate_r','wall_gate'}
    for _, m in ipairs(models) do
        local ok, obj = pcall(GetClosestObjectOfType, pos.x, pos.y, pos.z, radius, GetHashKey(m), false, false, false)
        if ok and type(obj)=='number' and obj ~= 0 and DoesEntityExist(obj) then
            local c = GetEntityCoords(obj)
            TriggerEvent('chat:addMessage', { args = { '[doorscan-gct]', ('model=%s obj=%d x=%.2f y=%.2f z=%.2f'):format(m, obj, c.x, c.y, c.z) } })
        end
    end
end, false)

-- /doorprobe — AIM your crosshair at the stuck door, then run this. It raycasts
-- exactly what you're looking at and reports that entity's model + door state, so
-- we identify the correct piece (the cluster has ~9 different models stacked).
local function b(v) return tostring(v) end

local function aimedEntity()
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local cosrx = math.abs(math.cos(rx))
    local dir = vector3(-math.sin(rz) * cosrx, math.cos(rz) * cosrx, math.sin(rx))
    local dest = cam + dir * 12.0
    local ray = StartShapeTestRay(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, 16, PlayerPedId(), 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    return (hit == 1 and entity ~= 0) and entity or nil
end

RegisterCommand('doorprobe', function()
    local e = aimedEntity()
    if not e then print('[doorprobe] ray hit nothing — aim directly at the door surface'); return end
    local model = GetEntityModel(e)
    local c = GetEntityCoords(e)
    local h = GetEntityHeading(e)
    print('[doorprobe] ===== AIMED ENTITY =====')
    print(('[doorprobe] obj=%d model=%d type=%d pos=%.3f,%.3f,%.3f h=%.2f static=%s frozen=%s attached=%s mission=%s')
        :format(e, model, GetEntityType(e), c.x, c.y, c.z, h,
            b(IsEntityStatic and IsEntityStatic(e)), b(IsEntityPositionFrozen(e)),
            b(IsEntityAttached and IsEntityAttached(e)), b(IsEntityAMissionEntity(e))))
    local okGS, locked, dh = pcall(GetStateOfClosestDoorOfType, model, c.x, c.y, c.z)
    print(('[doorprobe] doorSystem ok=%s locked=%s openRatio=%s'):format(b(okGS), b(locked), b(dh)))
    print('[doorprobe] ===== end =====')
end, false)

-- /doorlook — point your crosshair at a door (no need to aim/fire a weapon) and run this.
-- Prints the door's MODEL and exact POSITION straight to chat, so you can copy the model
-- number and tell me which door to freeze/unfreeze later.
RegisterCommand('doorlook', function()
    local e = aimedEntity()
    if not e then
        TriggerEvent('chat:addMessage', { args = { '[doorlook]',
            'Not pointing at anything — put your crosshair on the door surface and retry.' } })
        return
    end
    local model = GetEntityModel(e)
    local c = GetEntityCoords(e)
    local h = GetEntityHeading(e)
    TriggerEvent('chat:addMessage', { color = { 80, 200, 120 }, args = { '[doorlook]',
        ('model=%d  pos=%.2f, %.2f, %.2f  h=%.1f  frozen=%s'):format(
            model, c.x, c.y, c.z, h, tostring(IsEntityPositionFrozen(e))) } })
    -- Also drop a copy in the console (F8) for easy copy/paste.
    print(('[doorlook] model=%d pos=%.4f,%.4f,%.4f h=%.4f frozen=%s'):format(
        model, c.x, c.y, c.z, h, tostring(IsEntityPositionFrozen(e))))
end, false)

-- /doorfix — AIM at the stuck door, run this to force that exact door CLOSED (open
-- ratio 0) and locked via the door system, WITHOUT re-enabling physics. If it works
-- visually we promote these coords/model into a permanent enforcement entry.
RegisterCommand('doorfix', function()
    local e = aimedEntity()
    if not e then print('[doorfix] ray hit nothing — aim at the door'); return end
    local model = GetEntityModel(e)
    local c = GetEntityCoords(e)
    local id = GetHashKey('cnr_doorfix_' .. tostring(model))
    pcall(AddDoorToSystem, id, model, c.x, c.y, c.z, false, false, false)
    pcall(DoorSystemSetDoorState, id, 1, false, true)        -- 1 = locked (holds closed)
    pcall(DoorSystemSetOpenRatio, id, 0.0, false, true)      -- 0 = closed in frame
    pcall(SetStateOfClosestDoorOfType, model, c.x, c.y, c.z, 1, 0.0, false)
    print(('[doorfix] forced closed: obj=%d model=%d pos=%.3f,%.3f,%.3f — check the door now')
        :format(e, model, c.x, c.y, c.z))
end, false)

RegisterCommand('doorstate', function()
    local state = LocalPlayer and LocalPlayer.state
    local side = state and state.cnrSide or 'nil'
    local ped = PlayerPedId()
    local pos = ped ~= 0 and GetEntityCoords(ped) or nil
    local nearest, nearestDist = nil, nil

    if pos then
        for i, door in ipairs(Config.DoorList or {}) do
            local center = doorCenter(door)
            if center then
                local dx, dy = pos.x - center.x, pos.y - center.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if not nearestDist or dist < nearestDist then
                    nearest = i
                    nearestDist = dist
                end
            end
        end
    end

    TriggerEvent('chat:addMessage', {
        args = {
            '[doorlock]',
            ('localSide=%s stateSide=%s nearest=%s dist=%.2f locked=%s'):format(
                tostring(localSide),
                tostring(side),
                tostring(nearest),
                nearestDist or -1.0,
                tostring(nearest and doorStates[nearest])
            )
        }
    })
    TriggerServerEvent('cnr_doorlock:debugState', nearest or 0)
end, false)

CreateThread(function()
    while true do
        Wait(1500)
        for i in ipairs(Config.DoorList or {}) do
            if doorStates[i] == nil then doorStates[i] = true end
            applyDoorState(i)
        end
    end
end)

-- Build a flat list of permanentLocked door defs once at script load.
-- Each entry caches the entity handle and the closed heading/position captured
-- on the very first frame the entity is found (default closed state).
-- The per-frame thread below enforces lock every single frame so the GTA V door
-- system never has a gap in which it can animate the door open.
local permDoors = (function()
    local list = {}
    local n = 0
    for _, door in ipairs(Config.DoorList or {}) do
        if door.permanentLocked then
            local defs = door.doors or { door }
            for _, def in ipairs(defs) do
                if def.objHash and def.objCoords then
                    n = n + 1
                    list[#list + 1] = {
                        hash     = def.objHash,
                        cx       = def.objCoords.x,
                        cy       = def.objCoords.y,
                        cz       = def.objCoords.z,
                        sysId    = GetHashKey(('cnr_perm_%d'):format(n)),
                        sysAdded = false,
                        obj      = nil,
                        th       = nil,
                        tx       = nil, ty = nil, tz = nil,
                    }
                end
            end
        end
    end
    return list
end)()

CreateThread(function()
    while true do
        Wait(0)
        for _, pd in ipairs(permDoors) do
            if not pd.obj or not DoesEntityExist(pd.obj) then
                local obj = GetClosestObjectOfType(pd.cx, pd.cy, pd.cz, 5.0, pd.hash, false, false, false)
                if obj and obj ~= 0 and DoesEntityExist(obj) then
                    pd.obj = obj
                    if not pd.th then
                        local c = GetEntityCoords(obj)
                        pd.tx, pd.ty, pd.tz = c.x, c.y, c.z
                        pd.th = GetEntityHeading(obj)
                    end
                    -- Register with the door system using a unique ID so we get
                    -- DoorSystemSetDoorState control without conflicting with any
                    -- native door-system entry that uses the model hash.
                    if not pd.sysAdded then
                        AddDoorToSystem(pd.sysId, pd.hash, pd.tx, pd.ty, pd.tz, false, false, false)
                        pd.sysAdded = true
                    end
                end
            end
            if pd.obj and DoesEntityExist(pd.obj) and pd.th then
                if pd.sysAdded then
                    DoorSystemSetDoorState(pd.sysId, 1, false, true)
                end
                SetEntityCoordsNoOffset(pd.obj, pd.tx, pd.ty, pd.tz, false, false, false)
                SetEntityHeading(pd.obj, pd.th)
                FreezeEntityPosition(pd.obj, true)
                SetEntityCollision(pd.obj, true, true)
                SetStateOfClosestDoorOfType(pd.hash, pd.cx, pd.cy, pd.cz, 1, pd.th, false)
            end
        end
    end
end)

-- Keep the Mission Row armory door (model 185711165 @ 450.10,-984.09) FROZEN in place
-- so it can't swing/drift. Re-applies on re-stream (the object gets a new handle when
-- the area reloads). Only this specific model at this spot is touched.
CreateThread(function()
    local POS   = vector3(450.10, -984.09, 30.84)
    local MODEL = 185711165
    while true do
        local ped = PlayerPedId()
        if ped ~= 0 and #(GetEntityCoords(ped) - POS) < 25.0 then
            for _, obj in ipairs(GetGamePool('CObject')) do
                if DoesEntityExist(obj) and GetEntityModel(obj) == MODEL
                   and #(GetEntityCoords(obj) - POS) < 2.0 then
                    if not IsEntityPositionFrozen(obj) then
                        FreezeEntityPosition(obj, true)
                    end
                end
            end
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

-- Keep the adjacent corridor door (model -1033001619 @ ~453.09,-983.23) UNFROZEN so it can
-- swing normally — it was getting left stuck in a frozen state. Only this model/spot is touched.
CreateThread(function()
    local POS   = vector3(453.09, -983.23, 30.84)
    local MODEL = -1033001619
    while true do
        local ped = PlayerPedId()
        if ped ~= 0 and #(GetEntityCoords(ped) - POS) < 25.0 then
            for _, obj in ipairs(GetGamePool('CObject')) do
                if DoesEntityExist(obj) and GetEntityModel(obj) == MODEL
                   and #(GetEntityCoords(obj) - POS) < 2.5 then
                    if IsEntityPositionFrozen(obj) then
                        FreezeEntityPosition(obj, false)
                    end
                end
            end
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

-- Keep the four Mission Row holding-cell doors (model -1033001619 along the -996.46 wall)
-- FROZEN closed so prisoners can't push them open. Same model as the corridor door above,
-- but matched only at these exact cell spots, so the two threads never fight.
CreateThread(function()
    local MODEL = -1033001619
    local DOORS = {
        vector3(467.19, -996.46, 25.01),
        vector3(471.48, -996.46, 25.01),
        vector3(475.75, -996.46, 25.01),
        vector3(480.03, -996.46, 25.01),
    }
    while true do
        local ped = PlayerPedId()
        local near = false
        if ped ~= 0 then
            local p = GetEntityCoords(ped)
            for _, d in ipairs(DOORS) do
                if #(p - d) < 30.0 then near = true break end
            end
        end
        if near then
            for _, obj in ipairs(GetGamePool('CObject')) do
                if DoesEntityExist(obj) and GetEntityModel(obj) == MODEL then
                    local oc = GetEntityCoords(obj)
                    for _, d in ipairs(DOORS) do
                        if #(oc - d) < 2.0 then
                            if not IsEntityPositionFrozen(obj) then
                                FreezeEntityPosition(obj, true)
                            end
                            break
                        end
                    end
                end
            end
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

-- Keep the Bolingbroke prison perimeter gates/fences frozen so they can't be pushed open.
-- Data-driven: each entry is { model, position }. Matched only at these exact spots.
local PRISON_GATES = {
    { m = 741314661,   p = vector3(1844.9984, 2604.8105, 44.6379) },
    { m = 741314661,   p = vector3(1818.5428, 2604.8105, 44.6102) },
    { m = 741314661,   p = vector3(1799.6104, 2616.9753, 44.5997) },
    { m = -1156020871, p = vector3(1797.7609, 2596.5649, 46.3873) },
    { m = 741314661,   p = vector3(1835.2842, 2689.1016, 44.4567) },
    { m = 741314661,   p = vector3(1830.1332, 2703.5002, 44.4437) },
    { m = 741314661,   p = vector3(1776.7013, 2747.1479, 44.4467) },
    { m = 741314661,   p = vector3(1762.1945, 2752.4915, 44.4452) },
    { m = 741314661,   p = vector3(1662.0138, 2748.7017, 44.4458) },
    { m = 741314661,   p = vector3(1648.4084, 2741.6699, 44.4432) },
    { m = 741314661,   p = vector3(1584.6528, 2679.7495, 44.5095) },
    { m = 741314661,   p = vector3(1575.7180, 2667.1504, 44.5075) },
    { m = 741314661,   p = vector3(1547.7062, 2591.2842, 44.5082) },
    { m = 741314661,   p = vector3(1546.9835, 2576.1277, 44.3878) },
    { m = 741314661,   p = vector3(1550.9294, 2482.7451, 44.3946) },
    { m = 741314661,   p = vector3(1558.2218, 2469.3472, 44.3939) },
    { m = 741314661,   p = vector3(1652.9816, 2409.5684, 44.4421) },
    { m = 741314661,   p = vector3(1667.6716, 2407.6501, 44.4258) },
    { m = 741314661,   p = vector3(1749.1400, 2419.8113, 44.4232) },
    { m = 741314661,   p = vector3(1762.5425, 2426.5103, 44.4343) },
    { m = 741314661,   p = vector3(1808.9912, 2474.5430, 44.4799) },
    { m = 741314661,   p = vector3(1813.7484, 2488.9094, 44.4610) },
}

CreateThread(function()
    local CENTER = vector3(1690.0, 2565.0, 45.0)
    while true do
        local ped = PlayerPedId()
        if ped ~= 0 and #(GetEntityCoords(ped) - CENTER) < 420.0 then
            for _, obj in ipairs(GetGamePool('CObject')) do
                if DoesEntityExist(obj) then
                    local m = GetEntityModel(obj)
                    if m == 741314661 or m == -1156020871 then
                        local oc = GetEntityCoords(obj)
                        for _, g in ipairs(PRISON_GATES) do
                            if g.m == m and #(oc - g.p) < 2.0 then
                                if not IsEntityPositionFrozen(obj) then
                                    FreezeEntityPosition(obj, true)
                                end
                                break
                            end
                        end
                    end
                end
            end
            Wait(2000)
        else
            Wait(3000)
        end
    end
end)

-- (Mission Row armory door is now fixed in the v_policehub interior via CodeWalker —
--  no runtime script needed. See resources/cnr_missionrow_doorfix.)

-- /permlock_debug — type this in chat near a jail cell door to see enforcement status
RegisterCommand('permlock_debug', function()
    local ped = PlayerPedId()
    local pos = ped ~= 0 and GetEntityCoords(ped) or nil
    TriggerEvent('chat:addMessage', { args = { '[permlock]', ('permDoors count=%d'):format(#permDoors) } })
    for i, pd in ipairs(permDoors) do
        local found = pd.obj and DoesEntityExist(pd.obj)
        local dist = pos and pd.tx and ('%.1f'):format(#(pos - vector3(pd.tx, pd.ty, pd.tz))) or 'n/a'
        local frozen = found and IsEntityPositionFrozen(pd.obj) or false
        local curH   = found and ('%.1f'):format(GetEntityHeading(pd.obj)) or 'n/a'
        TriggerEvent('chat:addMessage', { args = { '[permlock]',
            ('[%d] found=%s sysAdded=%s frozen=%s dist=%s capturedH=%.1f curH=%s sysId=%d'):format(
                i, tostring(found), tostring(pd.sysAdded), tostring(frozen),
                dist, pd.th or 0, curH, pd.sysId or 0)
        } })
    end
end, false)
