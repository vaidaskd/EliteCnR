CnR = CnR or {}
CnR.DoorTool = CnR.DoorTool or {}

local doorStates = {}
local function doorKey(model, coords)
    return ('%s:%.1f:%.1f:%.1f'):format(model, coords.x, coords.y, coords.z)
end

local function nearestMatchingObject(model, coords)
    local best, bestD = 0, 2.2
    local objects = GetGamePool('CObject')
    for i = 1, #objects do
        local obj = objects[i]
        if DoesEntityExist(obj) and GetEntityModel(obj) == model then
            local d = #(GetEntityCoords(obj) - vector3(coords.x, coords.y, coords.z))
            if d < bestD then
                best = obj
                bestD = d
            end
        end
    end
    return best
end

local function permanentLockedConfig()
    return (Config and Config.PoliceDoorTool and Config.PoliceDoorTool.permanentLocked) or {}
end

local function permanentDoorHash(door)
    if not door or not door.model then return nil end
    return type(door.model) == 'string' and GetHashKey(door.model) or door.model
end

local function lockPermanentDoors()
    for _, door in ipairs(permanentLockedConfig()) do
        if door.pos then
            local hash = permanentDoorHash(door)
            if hash then
                local obj = nearestMatchingObject(hash, door.pos)
                if obj ~= 0 then
                    FreezeEntityPosition(obj, true)
                    SetEntityVelocity(obj, 0.0, 0.0, 0.0)
                end
            end
        end
    end
end

local function applyDoorState(state)
    if type(state) ~= 'table' or not state.model or not state.coords then return end
    local radius = state.radius or (Config.PoliceDoorTool and Config.PoliceDoorTool.doubleDoorRadius) or 3.0
    local objects = GetGamePool('CObject')
    for i = 1, #objects do
        local obj = objects[i]
        if DoesEntityExist(obj) then
            local d = #(GetEntityCoords(obj) - vector3(state.coords.x, state.coords.y, state.coords.z))
            if d <= radius then
                FreezeEntityPosition(obj, state.locked == true)
                if state.locked then
                    SetEntityVelocity(obj, 0.0, 0.0, 0.0)
                end
            end
        end
    end
end

RegisterNetEvent('cnr:client:doorToolState', function(state)
    if type(state) ~= 'table' then return end
    if state.model and state.coords then
        doorStates[doorKey(state.model, state.coords)] = state
    end
    applyDoorState(state)
end)

RegisterNetEvent('cnr:client:doorToolStates', function(states)
    if type(states) ~= 'table' then return end
    doorStates = {}
    for _, state in pairs(states) do
        if type(state) == 'table' and state.model and state.coords then
            doorStates[doorKey(state.model, state.coords)] = state
            applyDoorState(state)
        end
    end
end)

CreateThread(function()
    Wait(5000)
    print('[cnr][door_tool] loaded')
    TriggerServerEvent('cnr:server:doorToolRequestStates')
end)

CreateThread(function()
    while true do
        lockPermanentDoors()
        Wait(1500)
    end
end)
