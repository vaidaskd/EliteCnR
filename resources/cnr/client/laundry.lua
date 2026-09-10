CnR = CnR or {}
CnR.Laundry = CnR.Laundry or {}

local STATE = {
    idle = 'idle', collecting = 'collecting', sorting = 'sorting',
    washing = 'washing', delivering = 'delivering',
}

local state         = STATE.idle
local jailedKnown   = false
local secondsLeft   = 0
local collectionTargets = {}
local collectIdx    = 1
local sortItems     = {}
local sortIdx       = 1
local sortRight     = 0
local washEnd       = 0

RegisterNetEvent('cnr:client:jailTimeUpdate', function(payload)
    if type(payload) ~= 'table' then return end
    secondsLeft = tonumber(payload.seconds) or 0
end)
RegisterNetEvent('cnr:client:goToJail', function(payload)
    if type(payload) ~= 'table' then return end
    secondsLeft = tonumber(payload.seconds) or 0
end)

local function vdist(a, b) return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z)) end

local function drawHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function drawMarker(coords, r, g, b)
    DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0, 0, 0, 0, 0, 0,
        0.8, 0.8, 0.6, r, g, b, 120, false, false, 2, false, nil, nil, false)
end

local function nearby(coords, radius)
    return vdist(GetEntityCoords(PlayerPedId()), coords) < (radius or 1.5)
end

local function isInBolingbroke()
    return vdist(GetEntityCoords(PlayerPedId()), Config.Jail.bolingbroke) < 250.0
end

local function pickCollectionPoints()
    local out = {}
    local pool = {}
    for i, c in ipairs(Config.Laundry.collectionPoints) do pool[i] = c end
    local count = math.random(1, math.min(3, #pool))
    for _ = 1, count do
        local idx = math.random(1, #pool)
        table.insert(out, pool[idx])
        table.remove(pool, idx)
    end
    return out
end

local LAUNDRY_TYPES = { 'white', 'dark', 'colored' }
local function randomSortItems()
    local out = {}
    for i = 1, 5 do out[i] = LAUNDRY_TYPES[math.random(1, 3)] end
    return out
end

local function typeToKey(t)
    if t == 'white' then return 157
    elseif t == 'dark' then return 158
    else return 160
    end
end

local function reset()
    state = STATE.idle
    collectionTargets, collectIdx = {}, 1
    sortItems, sortIdx, sortRight = {}, 1, 0
    washEnd = 0
end

CreateThread(function()
    while true do
        local wait = 250
        if secondsLeft > 0 and isInBolingbroke() then
            if state == STATE.idle then
                drawMarker(Config.Laundry.startMarker, 80, 200, 255)
                if nearby(Config.Laundry.startMarker, 1.8) then
                    drawHelp('Press ~INPUT_CONTEXT~ to start Laundry Duty')
                    if IsControlJustReleased(0, 38) then
                        collectionTargets = pickCollectionPoints()
                        collectIdx = 1
                        state = STATE.collecting
                    end
                end
            elseif state == STATE.collecting then
                local target = collectionTargets[collectIdx]
                if target then
                    drawMarker(target, 255, 200, 80)
                    if nearby(target, 1.5) then
                        drawHelp(string.format('Collect dirty clothes (%d/%d) — ~INPUT_CONTEXT~',
                            collectIdx, #collectionTargets))
                        if IsControlJustReleased(0, 38) then
                            collectIdx = collectIdx + 1
                            if collectIdx > #collectionTargets then
                                sortItems = randomSortItems()
                                sortIdx, sortRight = 1, 0
                                state = STATE.sorting
                            end
                        end
                    end
                end
            elseif state == STATE.sorting then
                local item = sortItems[sortIdx]
                if item then
                    SetTextFont(4); SetTextScale(0.55, 0.55); SetTextColour(255, 255, 255, 230); SetTextOutline()
                    BeginTextCommandDisplayText('STRING')
                    AddTextComponentSubstringPlayerName(
                        string.format('Sort item %d/5: %s   [1=white  2=dark  3=colored]',
                            sortIdx, item))
                    EndTextCommandDisplayText(0.30, 0.85)
                    local correct = typeToKey(item)
                    for _, k in ipairs({ 157, 158, 160 }) do
                        if IsControlJustReleased(0, k) then
                            if k == correct then sortRight = sortRight + 1 end
                            sortIdx = sortIdx + 1
                            if sortIdx > #sortItems then
                                washEnd = GetGameTimer()
                                    + math.random(Config.Laundry.washSecMin, Config.Laundry.washSecMax) * 1000
                                state = STATE.washing
                            end
                            break
                        end
                    end
                end
            elseif state == STATE.washing then
                drawMarker(Config.Laundry.washingMachine, 80, 255, 120)
                if nearby(Config.Laundry.washingMachine, 1.5) then
                    local left = math.max(0, math.floor((washEnd - GetGameTimer()) / 1000))
                    drawHelp(string.format('Washing… %ds remaining', left))
                    if GetGameTimer() >= washEnd then
                        state = STATE.delivering
                    end
                else
                    drawHelp('Return to the washing machine')
                end
            elseif state == STATE.delivering then
                drawMarker(Config.Laundry.delivery, 80, 255, 200)
                if nearby(Config.Laundry.delivery, 1.5) then
                    drawHelp('Press ~INPUT_CONTEXT~ to deliver folded laundry')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('cnr:server:laundryComplete')
                        reset()
                    end
                end
            end
            wait = 0
        else
            reset()
        end
        Wait(wait)
    end
end)
