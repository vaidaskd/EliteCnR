CnR = CnR or {}
CnR.Robbery = CnR.Robbery or {}

local activeLocal  = nil
local pendingStart = nil
local moneyBag     = 0
local lootDrop     = 0
local handsUpPed   = 0
local alertBlips   = {}

-- Cash-bag attachment params (tunable live via /bagbone /bagoff /bagrot — see bottom of file).
-- 18905 = SKEL_L_Hand (left hand), 28422 = right hand, 57005 = SKEL_R_Hand.
local bagBone = 18905
local bagOff  = { 0.55, 0.0, 0.02 }
local bagRot  = { 90.0, 90.0, 180.0 }

local function cfg(key, fallback)
    local c = Config and Config.Robbery
    if c and c[key] ~= nil then return c[key] end
    return fallback
end

local PROMPT_RADIUS = cfg('promptRadius', 4.5)
local AIM_RADIUS    = cfg('startAimRadius', 4.0)
local AIM_HOLD_MS   = cfg('startAimMs', 800)
local STAY_RADIUS   = cfg('stayRadius', 12.0)
local LOOT_RADIUS   = cfg('lootPickupRadius', 2.0)

local function vdist(a, b)
    if not a or not b then return math.huge end
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

local function drawHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function drawProgress(percent, payout, jailSoFar)
    local pct  = math.max(0, math.min(100, percent or 0))
    local barW = 0.30   -- 30 % of screen width
    local barH = 0.010
    local barX = 0.50
    local barY = 0.875

    -- Background track
    DrawRect(barX, barY, barW, barH, 0, 0, 0, 160)
    -- Fill
    if pct > 0 then
        local fillW = barW * (pct / 100)
        DrawRect(barX - barW * 0.5 + fillW * 0.5, barY, fillW, barH, 50, 200, 80, 230)
    end

    -- Label above the bar
    SetTextFont(4); SetTextScale(0.30, 0.30); SetTextColour(255, 255, 255, 200)
    SetTextOutline(); SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(
        string.format('ROBBERY %d%%  ~g~$%d~s~  ~o~+%ds~s~', pct, payout or 0, jailSoFar or 0)
    )
    EndTextCommandDisplayText(barX, barY - 0.022)
end

local function nearestStoreOrBank()
    local ped = PlayerPedId()
    local pc  = GetEntityCoords(ped)
    local best = nil
    if Config.Stores then
        for i, s in ipairs(Config.Stores) do
            local d = vdist(pc, s.cashier)
            if d < PROMPT_RADIUS and (not best or d < best.d) then
                best = { kind = 'store', id = i, origin = s.cashier, d = d, label = 'cashier' }
            end
        end
    end
    if Config.Banks then
        for i, b in ipairs(Config.Banks) do
            local t = b.teller
            local origin = vec3(t.x, t.y, t.z)
            local d = vdist(pc, origin)
            if d < PROMPT_RADIUS and (not best or d < best.d) then
                best = { kind = 'bank', id = i, origin = origin, d = d, label = 'teller' }
            end
        end
    end
    if Config.JewelryStores then
        for i, j in ipairs(Config.JewelryStores) do
            local t = j.teller
            local origin = vec3(t.x, t.y, t.z)
            local d = vdist(pc, origin)
            if d < PROMPT_RADIUS and (not best or d < best.d) then
                best = { kind = 'jewelry', id = i, origin = origin, d = d, label = 'jewelry clerk' }
            end
        end
    end
    return best
end

local function loadAnim(dict, timeoutMs)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t0 < (timeoutMs or 3000) do
        Wait(50)
    end
    return HasAnimDictLoaded(dict)
end

local function findClosestPedTo(coords, radius)
    local pool = GetGamePool('CPed')
    local best, bestD = 0, radius or 3.5
    for i = 1, #pool do
        local p = pool[i]
        if DoesEntityExist(p) and not IsPedAPlayer(p) then
            local d = #(GetEntityCoords(p) - vector3(coords.x, coords.y, coords.z))
            if d < bestD then bestD = d; best = p end
        end
    end
    return best
end

local function startCashierHandsUp(origin)
    local p = findClosestPedTo(origin, 3.5)
    if p == 0 then return end
    handsUpPed = p
    SetEntityAsMissionEntity(p, true, true)
    ClearPedTasks(p)
    if loadAnim('random@mugging3') then
        TaskPlayAnim(p, 'random@mugging3', 'handsup_standing_base', 8.0, -8.0, -1, 49, 0, false, false, false)
    end
    SetBlockingOfNonTemporaryEvents(p, true)
end

local function stopCashierHandsUp()
    if handsUpPed ~= 0 and DoesEntityExist(handsUpPed) then
        ClearPedTasks(handsUpPed)
    end
    handsUpPed = 0
end

local function clearLootDrop()
    if lootDrop ~= 0 and DoesEntityExist(lootDrop) then
        DeleteObject(lootDrop)
    end
    lootDrop = 0
end

local function spawnLootDrop(origin, amount)
    clearLootDrop()
    if not origin or (amount or 0) <= 0 then return end

    local model = `prop_money_bag_01`
    RequestModel(model)
    local t0 = GetGameTimer()
    while not HasModelLoaded(model) and GetGameTimer() - t0 < 2000 do Wait(0) end
    if not HasModelLoaded(model) then return end

    local obj = CreateObject(model, origin.x, origin.y, origin.z - 0.9, false, false, false)
    SetModelAsNoLongerNeeded(model)
    if not obj or obj == 0 then return end

    SetEntityAsMissionEntity(obj, true, true)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, true, true)
    lootDrop = obj

    CreateThread(function()
        local drop = obj
        local pickedUp = false
        while DoesEntityExist(drop) and not pickedUp do
            Wait(0)
            local ped = PlayerPedId()
            local dropCoords = GetEntityCoords(drop)
            local dist = #(GetEntityCoords(ped) - dropCoords)
            if dist < LOOT_RADIUS then
                drawHelp('Press ~INPUT_CONTEXT~ to grab the cash')
                if IsControlJustReleased(0, 38) then
                    pickedUp = true
                    if loadAnim('anim@heists@money_grab@briefcase') then
                        TaskPlayAnim(ped, 'anim@heists@money_grab@briefcase', 'put_down_case', 8.0, -8.0, 1500, 49, 0, false, false, false)
                    end
                    DeleteObject(drop)
                    if lootDrop == drop then lootDrop = 0 end
                    if CnR.NativeUI and CnR.NativeUI.notify then
                        CnR.NativeUI.notify(('Collected $%s'):format(amount))
                    end
                end
            elseif dist < 8.0 then
                DrawMarker(2, dropCoords.x, dropCoords.y, dropCoords.z + 0.35,
                    0, 0, 0, 0, 0, 0, 0.25, 0.25, 0.25, 80, 220, 80, 180, false, true, 2, false, nil, nil, false)
            end
        end
    end)
end

local function attachMoneyBagShort()
    local model = `prop_money_bag_01`
    RequestModel(model)
    local t0 = GetGameTimer()
    while not HasModelLoaded(model) and GetGameTimer() - t0 < 2000 do Wait(50) end
    if not HasModelLoaded(model) then return end
    local ped = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(ped))
    moneyBag = CreateObject(model, x, y, z + 0.2, true, true, false)
    -- Held in the left hand, upright (see bagBone/bagOff/bagRot above).
    AttachEntityToEntity(moneyBag, ped, GetPedBoneIndex(ped, bagBone),
        bagOff[1], bagOff[2], bagOff[3], bagRot[1], bagRot[2], bagRot[3],
        false, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(model)

    -- No emote/animation — just the bag in hand for 10s, then it disappears.
    SetTimeout(10000, function()
        if moneyBag ~= 0 and DoesEntityExist(moneyBag) then DeleteObject(moneyBag) end
        moneyBag = 0
    end)
end

RegisterNetEvent('cnr:client:robberyProgress', function(payload)
    if type(payload) ~= 'table' or not activeLocal then return end
    activeLocal.lastServerPercent = payload.percent or 0
    activeLocal.lastServerPayout  = payload.payoutSoFar or 0
    activeLocal.lastJailSoFar     = payload.jailSoFar or 0
end)

RegisterNetEvent('cnr:client:robberyStartAck', function(payload)
    if type(payload) ~= 'table' or not pendingStart then return end
    if pendingStart.kind ~= payload.kind or pendingStart.id ~= payload.id then return end
    activeLocal = {
        kind = payload.kind,
        id = payload.id,
        origin = pendingStart.origin,
        startedAt = GetGameTimer(),
        durationMs = (payload.duration or 20) * 1000,
    }
    pendingStart = nil
end)

RegisterNetEvent('cnr:client:robberyStartFail', function()
    pendingStart = nil
end)

RegisterNetEvent('cnr:client:robberyStarted', function(payload)
    if type(payload) ~= 'table' or not payload.origin then return end
    startCashierHandsUp(payload.origin)
end)

RegisterNetEvent('cnr:client:robberyEnd', function(payload)
    if type(payload) ~= 'table' then return end
    stopCashierHandsUp()
    activeLocal = nil
    pendingStart = nil

    local payout = tonumber(payload.payout) or 0
    if payout > 0 and payload.origin then
        spawnLootDrop(payload.origin, payout)
        -- Only show the carried cash bag when the full 1-minute robbery was completed,
        -- not when it was aborted early for a partial payout.
        if payload.completed then attachMoneyBagShort() end
    end
end)

local function cancelActiveRobbery(reason)
    if not activeLocal then return end
    TriggerServerEvent('cnr:server:robberyCancel', { reason = reason or 'client_cancel' })
    stopCashierHandsUp()
    activeLocal = nil
end

RegisterNetEvent('cnr:client:robberyEnded', function(payload)
    if type(payload) ~= 'table' then return end
    local key = payload.key
    if key and alertBlips[key] then
        if DoesBlipExist(alertBlips[key].handle) then RemoveBlip(alertBlips[key].handle) end
        alertBlips[key] = nil
    end
end)

RegisterNetEvent('cnr:client:robberyAlert', function(payload)
    if type(payload) ~= 'table' or type(payload.pos) ~= 'table' then return end
    local key = (payload.kind or 'unk') .. ':' .. tostring(payload.id or 0)
    if alertBlips[key] and DoesBlipExist(alertBlips[key].handle) then
        RemoveBlip(alertBlips[key].handle)
    end
    local h = AddBlipForCoord(payload.pos.x, payload.pos.y, payload.pos.z)
    SetBlipSprite(h, 161)
    SetBlipColour(h, 1)
    SetBlipScale(h, 1.2)
    SetBlipFlashes(h, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Robbery: ' .. (payload.name or '?'))
    EndTextCommandSetBlipName(h)
    alertBlips[key] = { handle = h, expiresAt = GetGameTimer() + 90000 }
end)

CreateThread(function()
    while true do
        Wait(2000)
        local now = GetGameTimer()
        for k, v in pairs(alertBlips) do
            if v.expiresAt < now then
                if DoesBlipExist(v.handle) then RemoveBlip(v.handle) end
                alertBlips[k] = nil
            end
        end
    end
end)

CreateThread(function()
    while true do
        local wait = 500
        if CnR.State and CnR.State.side == CnR.Sides.ROBBER and not activeLocal and not pendingStart then
            local near = nearestStoreOrBank()
            if near then
                wait = 0
                drawHelp(string.format('Aim weapon at %s to begin robbery', near.label))
                local ped = PlayerPedId()
                if IsPlayerFreeAiming(PlayerId()) and vdist(GetEntityCoords(ped), near.origin) < AIM_RADIUS then
                    local holdStart = GetGameTimer()
                    while IsPlayerFreeAiming(PlayerId())
                        and vdist(GetEntityCoords(PlayerPedId()), near.origin) < AIM_RADIUS do
                        if (GetGameTimer() - holdStart) >= AIM_HOLD_MS then
                            pendingStart = {
                                kind = near.kind,
                                id = near.id,
                                origin = vector3(near.origin.x, near.origin.y, near.origin.z),
                                at = GetGameTimer(),
                            }
                            TriggerServerEvent('cnr:server:robberyStart', { kind = near.kind, id = near.id })
                            break
                        end
                        Wait(50)
                    end
                end
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if activeLocal then
            local ped = PlayerPedId()
            local pc  = GetEntityCoords(ped)
            if vdist(pc, activeLocal.origin) > STAY_RADIUS then
                drawHelp('~r~Stay near the register!')
            elseif not IsPlayerFreeAiming(PlayerId()) then
                drawHelp('~r~Keep your weapon aimed at the cashier!')
                cancelActiveRobbery('stopped_aiming')
            else
                drawProgress(activeLocal.lastServerPercent or 0, activeLocal.lastServerPayout or 0, activeLocal.lastJailSoFar or 0)
                drawHelp('Robbery in progress — stay close')
            end
        elseif pendingStart then
            drawHelp('Starting robbery...')
            if GetGameTimer() - (pendingStart.at or 0) > 5000 then
                pendingStart = nil
            end
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if moneyBag ~= 0 and DoesEntityExist(moneyBag) then DeleteObject(moneyBag) end
    clearLootDrop()
    for _, v in pairs(alertBlips) do
        if v.handle and DoesBlipExist(v.handle) then RemoveBlip(v.handle) end
    end
end)

-- ─── Cash-bag attachment tuner (dev helper) ─────────────────────────────────────
-- /bagshow to preview on yourself, then /bagbone, /bagoff x y z, /bagrot x y z to adjust,
-- /bagdump to read the final numbers, /baghide to remove. The robbery bag uses the same
-- bagBone/bagOff/bagRot values, so once you find good numbers tell me and I'll bake them in.
local tuneBag = 0
local function tuneReattach()
    local ped = PlayerPedId()
    -- Reuse a single LOCAL object and just re-attach it; recreating a networked object
    -- each time fails after the first call (which is why edits stopped applying).
    if tuneBag == 0 or not DoesEntityExist(tuneBag) then
        local model = `prop_money_bag_01`
        RequestModel(model)
        local t0 = GetGameTimer()
        while not HasModelLoaded(model) and GetGameTimer() - t0 < 2000 do Wait(50) end
        if not HasModelLoaded(model) then return end
        local c = GetEntityCoords(ped)
        tuneBag = CreateObject(model, c.x, c.y, c.z + 0.2, false, false, false)
        SetModelAsNoLongerNeeded(model)
    end
    DetachEntity(tuneBag, true, true)
    AttachEntityToEntity(tuneBag, ped, GetPedBoneIndex(ped, bagBone),
        bagOff[1] + 0.0, bagOff[2] + 0.0, bagOff[3] + 0.0,
        bagRot[1] + 0.0, bagRot[2] + 0.0, bagRot[3] + 0.0,
        true, true, false, false, 2, true)
end

RegisterCommand('bagshow', function() tuneReattach() end, false)
RegisterCommand('baghide', function()
    if tuneBag ~= 0 and DoesEntityExist(tuneBag) then DeleteObject(tuneBag) end
    tuneBag = 0
end, false)
RegisterCommand('bagbone', function(_, a)
    bagBone = tonumber(a[1]) or bagBone
    tuneReattach()
end, false)
RegisterCommand('bagoff', function(_, a)
    bagOff = { tonumber(a[1]) or bagOff[1], tonumber(a[2]) or bagOff[2], tonumber(a[3]) or bagOff[3] }
    tuneReattach()
end, false)
RegisterCommand('bagrot', function(_, a)
    bagRot = { tonumber(a[1]) or bagRot[1], tonumber(a[2]) or bagRot[2], tonumber(a[3]) or bagRot[3] }
    tuneReattach()
end, false)
RegisterCommand('bagdump', function()
    TriggerEvent('chat:addMessage', { args = { '[bag]',
        ('bone=%d  off={%.3f, %.3f, %.3f}  rot={%.1f, %.1f, %.1f}'):format(
            bagBone, bagOff[1], bagOff[2], bagOff[3], bagRot[1], bagRot[2], bagRot[3]) } })
end, false)
