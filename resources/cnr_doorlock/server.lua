local doorStates = {}
local clientNear = {}
local playerSides = {}
local AUTO_RADIUS = 2.0

CreateThread(function()
    for i, door in ipairs(Config.DoorList or {}) do
        doorStates[i] = door.permanentLocked and true or (door.alwaysOpen and false) or (door.locked ~= false)
    end
end)

local function doorCenter(door)
    if not door then return nil end
    if door.objCoords then return door.objCoords end
    if door.doors and door.doors[1] then return door.doors[1].objCoords end
    if door.textCoords then return door.textCoords end
    return nil
end

local function nearDoor2d(pos, door, radius)
    radius = radius or AUTO_RADIUS
    if door.doors then
        for _, def in ipairs(door.doors) do
            if def.objCoords then
                local dx, dy = pos.x - def.objCoords.x, pos.y - def.objCoords.y
                if math.sqrt(dx * dx + dy * dy) <= radius then
                    return true
                end
            end
        end
    end

    local center = doorCenter(door)
    if not center then return false end
    local dx, dy = pos.x - center.x, pos.y - center.y
    return math.sqrt(dx * dx + dy * dy) <= radius
end

local function playerIsCop(src)
    local player = Player(src)
    return (player and player.state and player.state.cnrSide == 'cop') or playerSides[src] == 'cop'
end

local function anyCopNearDoor(door)
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src and playerIsCop(src) then
            local untilTime = clientNear[src] and clientNear[src][door._id or 0]
            if untilTime and untilTime > GetGameTimer() then
                return true
            end

            local ped = GetPlayerPed(src)
            if ped ~= 0 then
                local pos = GetEntityCoords(ped)
                if nearDoor2d(pos, door, door.autoDistance or Config.AutoDistance or AUTO_RADIUS) then
                    return true
                end
            end
        end
    end

    return false
end

RegisterNetEvent('cnr_doorlock:requestState', function()
    TriggerClientEvent('cnr_doorlock:setStateBulk', source, doorStates)
end)

RegisterNetEvent('cnr_doorlock:updateState', function(doorId, locked)
    doorId = tonumber(doorId)
    if not doorId or not Config.DoorList[doorId] then return end
    doorStates[doorId] = Config.DoorList[doorId].permanentLocked and true or (locked == true)
    TriggerClientEvent('cnr_doorlock:setState', -1, doorId, doorStates[doorId])
end)

RegisterNetEvent('cnr_doorlock:setPlayerSide', function(playerSrc, side)
    local src = tonumber(playerSrc)
    if not src or src == 0 then
        src = source
        side = playerSrc
    end
    if not src or src == 0 then return end
    playerSides[src] = side == 'cop' and 'cop' or side == 'robber' and 'robber' or 'none'
    if playerSides[src] ~= 'cop' then
        clientNear[src] = nil
    end
end)

RegisterNetEvent('cnr_doorlock:nearDoor', function(doorId)
    local src = source
    doorId = tonumber(doorId)
    local door = doorId and Config.DoorList[doorId] or nil
    if not door or door.permanentLocked or not playerIsCop(src) then return end

    clientNear[src] = clientNear[src] or {}
    clientNear[src][doorId] = GetGameTimer() + 1500

    if doorStates[doorId] ~= false then
        doorStates[doorId] = false
        TriggerClientEvent('cnr_doorlock:setState', -1, doorId, false)
    end
end)

RegisterNetEvent('cnr_doorlock:debugState', function(doorId)
    local src = source
    doorId = tonumber(doorId) or 0
    local player = Player(src)
    local stateSide = player and player.state and player.state.cnrSide or nil
    local cachedSide = playerSides[src]
    local ped = GetPlayerPed(src)
    local near = false
    if doorId > 0 and Config.DoorList[doorId] and ped ~= 0 then
        local door = Config.DoorList[doorId]
        door._id = doorId
        near = nearDoor2d(GetEntityCoords(ped), door, door.autoDistance or Config.AutoDistance or AUTO_RADIUS)
    end

    TriggerClientEvent('chat:addMessage', src, {
        args = {
            '[doorlock]',
            ('server stateSide=%s cachedSide=%s isCop=%s door=%s locked=%s serverNear=%s clientNear=%s'):format(
                tostring(stateSide),
                tostring(cachedSide),
                tostring(playerIsCop(src)),
                tostring(doorId),
                tostring(doorStates[doorId]),
                tostring(near),
                tostring(clientNear[src] and clientNear[src][doorId] and clientNear[src][doorId] > GetGameTimer())
            )
        }
    })
end)

AddEventHandler('playerDropped', function()
    clientNear[source] = nil
    playerSides[source] = nil
end)

CreateThread(function()
    while true do
        Wait(500)
        for i, door in ipairs(Config.DoorList or {}) do
            door._id = i
            local nextLocked = true
            if door.permanentLocked then
                nextLocked = true
            elseif door.alwaysOpen then
                nextLocked = false
            elseif anyCopNearDoor(door) then
                nextLocked = false
            end

            if doorStates[i] ~= nextLocked then
                doorStates[i] = nextLocked
                TriggerClientEvent('cnr_doorlock:setState', -1, i, nextLocked)
            end
        end
    end
end)
