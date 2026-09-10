CnR = CnR or {}
CnR.Doors = CnR.Doors or {}

local states = {}

local function keyFor(model, coords)
    return ('%s:%.1f:%.1f:%.1f'):format(model, coords.x, coords.y, coords.z)
end

local function inAllowedZone(pos)
    local cfg = Config and Config.PoliceDoorTool
    for _, zone in ipairs((cfg and cfg.zones) or {}) do
        if zone.pos then
            local dx, dy, dz = pos.x - zone.pos.x, pos.y - zone.pos.y, pos.z - zone.pos.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) <= (zone.radius or 50.0) then
                return true
            end
        end
    end
    return false
end

local function isPermanentLockedDoor(model, coords)
    local cfg = Config and Config.PoliceDoorTool
    for _, door in ipairs((cfg and cfg.permanentLocked) or {}) do
        local expected = type(door.model) == 'string' and GetHashKey(door.model) or door.model
        if tonumber(model) == tonumber(expected) and door.pos then
            local dx, dy, dz = coords.x - door.pos.x, coords.y - door.pos.y, coords.z - door.pos.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) <= (door.radius or 1.5) then
                return true
            end
        end
    end
    return false
end

RegisterNetEvent('cnr:server:doorToolRequestStates', function()
    TriggerClientEvent('cnr:client:doorToolStates', source, states)
end)

RegisterNetEvent('cnr:server:doorToolToggle', function(payload)
    local src = source
    if type(payload) ~= 'table' or type(payload.coords) ~= 'table' or not payload.model then return end
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.COP then return end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local pc = GetEntityCoords(ped)
    local coords = {
        x = tonumber(payload.coords.x) or 0.0,
        y = tonumber(payload.coords.y) or 0.0,
        z = tonumber(payload.coords.z) or 0.0,
    }
    local dx, dy, dz = pc.x - coords.x, pc.y - coords.y, pc.z - coords.z
    local range = (Config.PoliceDoorTool and Config.PoliceDoorTool.range) or 4.0
    if math.sqrt(dx * dx + dy * dy + dz * dz) > (range + 2.0) then return end
    if not inAllowedZone(pc) then return end
    if isPermanentLockedDoor(payload.model, coords) then return end

    local state = {
        model = tonumber(payload.model) or payload.model,
        coords = coords,
        heading = tonumber(payload.heading),
        radius = tonumber(payload.radius) or (Config.PoliceDoorTool and Config.PoliceDoorTool.doubleDoorRadius) or 3.0,
        locked = payload.locked == true,
    }
    states[keyFor(state.model, state.coords)] = state
    TriggerClientEvent('cnr:client:doorToolState', -1, state)
    TriggerClientEvent('cnr:client:notify', src, {
        kind = 'info',
        text = state.locked and 'Door locked' or 'Door unlocked',
    })
end)
