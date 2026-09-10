CnR = CnR or {}
CnR.Robbery = CnR.Robbery or {}

local active    = {}
local cooldowns = {}

local COOLDOWN_STORE_SEC = 180   -- 3 min (also gates buying at a just-robbed store)
local COOLDOWN_BANK_SEC  = 180   -- 3 min (banks + jewelry)

local function robberyCfg(key, fallback)
    local c = Config and Config.Robbery
    if c and c[key] ~= nil then return c[key] end
    return fallback
end

local function robberyDuration()
    return robberyCfg('durationSec', Config.RobberyDurationSec or 20)
end

local function distSq(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function playerSide(src)
    local s = CnR.GetSide and CnR.GetSide(src) or CnR.Sides.NONE
    if s ~= CnR.Sides.NONE then return s end
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if not id then return CnR.Sides.NONE end
    local p = CnR.Persistence.GetProfile(id)
    if p and p.side and p.side ~= CnR.Sides.NONE then
        CnR.State.sides[src] = p.side
        return p.side
    end
    return CnR.Sides.NONE
end

local function notify(src, kind, text)
    TriggerClientEvent('cnr:client:notify', src, { kind = kind, text = text })
end

local function originForRobbery(kind, id)
    if kind == 'store' then
        local s = Config.Stores[id]
        if not s then return nil end
        return vec3(s.cashier.x, s.cashier.y, s.cashier.z),
               s.payout or Config.Payouts.storeRobbery,
               Config.JailTime.storeRobbery
    elseif kind == 'bank' then
        local b = Config.Banks[id]
        if not b then return nil end
        return vec3(b.teller.x, b.teller.y, b.teller.z),
               b.payout or Config.Payouts.bankRobbery,
               Config.JailTime.bankRobbery
    elseif kind == 'jewelry' then
        local j = Config.JewelryStores and Config.JewelryStores[id]
        if not j then return nil end
        return vec3(j.teller.x, j.teller.y, j.teller.z),
               j.payout or Config.Payouts.jewelryRobbery,
               Config.JailTime.jewelryRobbery
    end
    return nil
end

local function cooldownKey(kind, id) return kind .. ':' .. tostring(id) end

local function cooldownLeft(kind, id)
    local k = cooldownKey(kind, id)
    local until_ = cooldowns[k] or 0
    local now = os.time()
    if until_ > now then return until_ - now end
    return 0
end

local function alertCops(kind, id, origin)
    local label = (kind == 'bank' and 'BANK') or (kind == 'jewelry' and 'JEWELRY') or 'STORE'
    local lookup = (kind == 'bank' and Config.Banks[id])
        or (kind == 'jewelry' and Config.JewelryStores and Config.JewelryStores[id])
        or Config.Stores[id]
    local name = (lookup and lookup.name) or 'unknown'
    for _, plId in ipairs(GetPlayers()) do
        local s = tonumber(plId)
        if s and playerSide(s) == CnR.Sides.COP then
            -- Dispatch the alert into the POLICE RADIO chat channel (not the game feed). #radio
            TriggerClientEvent('chat:addMessage', s, {
                cnr       = true,
                channel   = 'police',
                name      = 'DISPATCH',
                nameColor = '#1d6fff',
                text      = ('%s ROBBERY IN PROGRESS — %s'):format(label, name),
                textColor = '#ffd166',
            })
            TriggerClientEvent('cnr:client:robberyAlert', s, {
                kind = kind, id = id,
                pos = { x = origin.x, y = origin.y, z = origin.z },
                name = name,
            })
        end
    end
end

local function pushProgress(src, percent, payoutSoFar, jailSoFar)
    TriggerClientEvent('cnr:client:robberyProgress', src, {
        percent = percent,
        payoutSoFar = math.floor(payoutSoFar + 0.5),
        jailSoFar = math.floor(jailSoFar + 0.5),
    })
end

local function playerNearOrigin(src, origin, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local pc = GetEntityCoords(ped)
    return distSq(vec3(pc.x, pc.y, pc.z), origin) <= (radius * radius)
end

local function finishRobbery(src, completed)
    local r = active[src]
    if not r then return end
    active[src] = nil

    local duration = robberyDuration()
    local elapsed  = os.time() - r.startedAt
    local frac     = completed and 1.0 or math.min(1.0, math.max(0.0, elapsed / duration))
    local payout   = math.floor((r.payout or 0) * frac + 0.5)
    local maxJail  = r.jailAdd or 0
    local jailTarget = math.floor(maxJail * (completed and 1.0 or frac) + 0.5)
    local jailAdd  = math.max(0, jailTarget - (r.jailAccumulated or 0))

    local cdSec = (r.kind == 'bank' or r.kind == 'jewelry') and COOLDOWN_BANK_SEC or COOLDOWN_STORE_SEC
    cooldowns[cooldownKey(r.kind, r.id)] = os.time() + cdSec

    if payout > 0 or jailAdd > 0 then
        local id = CnR.GetIdentifier(src)
        if id then
            local p = CnR.Persistence.GetProfile(id)
            if payout > 0 then p.cash = (p.cash or 0) + payout end
            if jailAdd > 0 then
                p.jailDebtSeconds = (p.jailDebtSeconds or 0) + jailAdd
            end
            CnR.Persistence.SaveProfile(id, p)
        end
        if CnR.PushProfile then CnR.PushProfile(src) end
    end

    -- Credits: only a completed 24/7 / liquor store robbery rewards +1 credit. Bank/jewelry
    -- jobs already paid their credit cost up front and give no reward.
    if completed and r.kind == 'store' and CnR.Ranks and CnR.Ranks.GrantCredits then
        CnR.Ranks.GrantCredits(src, (Config.RobberCredits and Config.RobberCredits.perStoreRob) or 1)
    end

    local totalJail = (r.jailAccumulated or 0) + jailAdd

    -- Tell all cops the robbery at this location is over so the alert blip is removed.
    local alertKey = (r.kind or 'unk') .. ':' .. tostring(r.id or 0)
    for _, plId in ipairs(GetPlayers()) do
        local s = tonumber(plId)
        if s and playerSide(s) == CnR.Sides.COP then
            TriggerClientEvent('cnr:client:robberyEnded', s, { key = alertKey })
        end
    end

    pushProgress(src, completed and 100 or math.floor(frac * 100), payout, totalJail)
    TriggerClientEvent('cnr:client:robberyEnd', src, {
        completed = completed,
        payout    = payout,
        jailAdd   = totalJail,
        kind      = r.kind,
        id        = r.id,
        origin    = { x = r.origin.x, y = r.origin.y, z = r.origin.z },
    })

    local jailStr = (CnR.Crime and CnR.Crime.FmtJail and CnR.Crime.FmtJail(totalJail)) or (totalJail .. 's')
    if payout > 0 then
        notify(src, completed and 'ok' or 'warn', completed
            and (("You've committed ~r~robbery~s~, $%d +%s jail time added"):format(payout, jailStr))
            or  (("Robbery aborted early: $%d +%s jail time added"):format(payout, jailStr)))
    else
        notify(src, completed and 'ok' or 'warn', completed
            and (("You've committed ~r~robbery~s~, +%s jail time added"):format(jailStr))
            or  'Robbery failed — you left the area')
    end

    CnR.Util.log('info', 'robbery %s by src=%d kind=%s id=%d payout=%d jailDebt=+%d',
        completed and 'completed' or 'aborted', src, tostring(r.kind),
        r.id or -1, payout, totalJail)
end

RegisterNetEvent('cnr:server:robberyStart', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end

    if playerSide(src) ~= CnR.Sides.ROBBER then
        TriggerClientEvent('cnr:client:robberyStartFail', src, { reason = 'not_robber' })
        notify(src, 'error', 'Only robbers can hold up stores')
        return
    end
    if active[src] then return end

    local kind, id = payload.kind, tonumber(payload.id)
    if not id then return end

    -- Credit gate: 24/7 / liquor stores are free; jewelry costs 3, banks cost 5 (consumed
    -- up front, whether or not the job completes).
    local rc = Config.RobberCredits or {}
    local startCost = (kind == 'bank' and (rc.bankCost or 5))
        or (kind == 'jewelry' and (rc.jewelryCost or 3))
        or 0
    if startCost > 0 then
        if not (CnR.Ranks and CnR.Ranks.SpendCredits and CnR.Ranks.SpendCredits(src, startCost)) then
            TriggerClientEvent('cnr:client:robberyStartFail', src, { reason = 'credits' })
            notify(src, 'error', ('Need %d credits to rob this target'):format(startCost))
            return
        end
    end

    local left = cooldownLeft(kind, id)
    if left > 0 then
        TriggerClientEvent('cnr:client:robberyStartFail', src, { reason = 'cooldown', seconds = left })
        notify(src, 'warn', ('Target on cooldown: %ds'):format(left))
        return
    end

    local origin, payout, jailAdd = originForRobbery(kind, id)
    if not origin then
        TriggerClientEvent('cnr:client:robberyStartFail', src, { reason = 'invalid_target' })
        return
    end

    local startRadius = robberyCfg('startAimRadius', 4.0)
    if not playerNearOrigin(src, origin, startRadius + 1.0) then
        TriggerClientEvent('cnr:client:robberyStartFail', src, { reason = 'too_far' })
        notify(src, 'error', 'Get closer to the cashier')
        return
    end

    active[src] = {
        kind      = kind,
        id        = id,
        origin    = origin,
        startedAt = os.time(),
        payout    = payout,
        jailAdd   = jailAdd or 0,
        jailAccumulated = 0,
        lastJailTick = os.time(),
    }

local wasWanted = Player(src).state.cnrWanted == true

if CnR.Crime and CnR.Crime.SetWanted then CnR.Crime.SetWanted(src, true) end

-- Only show the "now wanted" notice the first time they go from innocent -> wanted.
if not wasWanted then
    notify(src, 'warn', 'You are now a ~r~Wanted~s~ Robber!')
end

    TriggerClientEvent('cnr:client:robberyStartAck', src, {
        kind = kind, id = id,
        origin = { x = origin.x, y = origin.y, z = origin.z },
        duration = robberyDuration(),
    })
    TriggerClientEvent('cnr:client:robberyStarted', src, {
        kind = kind, id = id,
        origin = { x = origin.x, y = origin.y, z = origin.z },
    })

    alertCops(kind, id, origin)
    pushProgress(src, 0, 0, 0)
end)

RegisterNetEvent('cnr:server:robberyCancel', function()
    local src = source
    if active[src] then
        finishRobbery(src, false)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if active[src] then active[src] = nil end
end)

CreateThread(function()
    while true do
        Wait(1000)
        local now = os.time()
        local duration = robberyDuration()
        local stayRadius = robberyCfg('stayRadius', 12.0)

        for src, r in pairs(active) do
            if not playerNearOrigin(src, r.origin, stayRadius) then
                finishRobbery(src, false)
            else
                local elapsed = now - r.startedAt
                if elapsed >= duration then
                    finishRobbery(src, true)
                else
                    local percent = math.floor((elapsed / duration) * 100)
                    local payoutSoFar = (r.payout or 0) * (elapsed / duration)
                    local maxJail = r.jailAdd or 0
                    local jailTarget = math.floor(maxJail * (elapsed / duration) + 0.5)
                    local jailDelta = jailTarget - (r.jailAccumulated or 0)
                    if jailDelta > 0 then
                        local id = CnR.GetIdentifier(src)
                        if id then
                            local p = CnR.Persistence.GetProfile(id)
                            p.jailDebtSeconds = (p.jailDebtSeconds or 0) + jailDelta
                            CnR.Persistence.SaveProfile(id, p)
                            r.jailAccumulated = (r.jailAccumulated or 0) + jailDelta
                            if CnR.PushProfile then CnR.PushProfile(src) end
                        end
                    end
                    pushProgress(src, percent, payoutSoFar, r.jailAccumulated or 0)
                end
            end
        end
    end
end)

function CnR.Robbery.CooldownLeft(kind, id) return cooldownLeft(kind, id) end

-- For the store shop: is buying blocked because this store is being robbed right now,
-- or is still on its post-robbery cooldown? Returns (blocked, secondsLeft). #9
function CnR.Robbery.StoreBuyBlocked(storeId)
    for _, r in pairs(active) do
        if r and r.kind == 'store' and r.id == storeId then
            return true, robberyDuration()
        end
    end
    local left = cooldownLeft('store', storeId)
    if left and left > 0 then return true, left end
    return false, 0
end
