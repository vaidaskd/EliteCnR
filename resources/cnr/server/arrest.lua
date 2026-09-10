CnR = CnR or {}
CnR.Arrest = CnR.Arrest or {}
CnR.Arrest.cuffs = CnR.Arrest.cuffs or {}

local function distSqEntities(a, b)
    if a == 0 or b == 0 then return math.huge end
    local ax, ay, az = table.unpack(GetEntityCoords(a))
    local bx, by, bz = table.unpack(GetEntityCoords(b))
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return dx * dx + dy * dy + dz * dz
end

local function uncuff(target)
    local cop = CnR.Arrest.cuffs[target]
    CnR.Arrest.cuffs[target] = nil
    local pl = Player(target)
    if pl and pl.state then pl.state:set('cnrCuffedBy', nil, true) end
    if target and GetPlayerPed(target) ~= 0 then
        TriggerClientEvent('cnr:client:uncuffed', target)
    end
    CnR.Util.log('info', 'uncuffed target=%s (cop=%s)', tostring(target), tostring(cop))
end

RegisterNetEvent('cnr:server:attemptCuff', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local target = tonumber(payload.target); if not target then return end
    if CnR.GetSide(src) ~= CnR.Sides.COP then return end
    if CnR.GetSide(target) ~= CnR.Sides.ROBBER then return end
    if not (CnR.Crime and CnR.Crime.IsWanted(target)) then return end
    if CnR.Arrest.cuffs[target] then return end
    local copPed = GetPlayerPed(src); local robberPed = GetPlayerPed(target)
    if copPed == 0 or robberPed == 0 then return end
    if distSqEntities(copPed, robberPed) > (2.5 * 2.5) then return end
    CnR.Arrest.cuffs[target] = src
    do
        local pl = Player(target)
        if pl and pl.state then pl.state:set('cnrCuffedBy', src, true) end   -- lets the cop client offer arrest options
    end
    TriggerClientEvent('cnr:client:cuffed', target, { byCopSrc = src })
    TriggerClientEvent('cnr:client:notify', target, {
        kind = 'error',
        text = ("You've been cuffed by %s"):format(GetPlayerName(src) or 'a cop'),
    })
    -- Tell the cop they succeeded and how to proceed. #9
    TriggerClientEvent('cnr:client:notify', src, {
        kind = 'ok',
        text = ('You cuffed %s — press C again for arrest options'):format(GetPlayerName(target) or 'the suspect'),
    })
    CnR.Util.log('info', 'cuffed target=%d by cop=%d', target, src)
end)

--- Returns the arrest-entrance config entry the cop is standing inside, or nil.
local function findArrestEntrance(cx, cy, cz)
    local entrances = Config.ArrestEntrances or { Config.ArrestEntrance }
    for _, e in ipairs(entrances) do
        local c = e.center
        local r = e.radius or 3.0
        local dx, dy, dz = cx - c.x, cy - c.y, cz - c.z
        if (dx * dx + dy * dy + dz * dz) <= (r * r) then
            return e
        end
    end
    return nil
end

RegisterNetEvent('cnr:server:deliverArrest', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local target = tonumber(payload.target); if not target then return end
    if CnR.Arrest.cuffs[target] ~= src then return end
    local copPed = GetPlayerPed(src)
    if copPed == 0 then return end
    local cx, cy, cz = table.unpack(GetEntityCoords(copPed))
    local entrance = findArrestEntrance(cx, cy, cz)
    if not entrance then return end
    local station = entrance.station or 'missionRow'

    local id = CnR.GetIdentifier(src)
    if id then
        local p = CnR.Persistence.GetProfile(id)
        p.cash    = (p.cash or 0) + (Config.Payouts.arrestCash or 0)
        p.credits = (p.credits or 0) + ((Config.Credits and Config.Credits.perArrest) or 5)
        CnR.Persistence.SaveProfile(id, p)
    end
    if CnR.BumpStat then CnR.BumpStat(src, 'stdArrests') end   -- #6
    TriggerClientEvent('cnr:client:arrestRewarded', src, {
        credits = (Config.Credits and Config.Credits.perArrest) or 5,
        cash    = Config.Payouts.arrestCash or 0,
    })
    if CnR.PushProfile then CnR.PushProfile(src) end

    -- Uncuff first so the client detaches before the jail teleport fires.
    uncuff(target)
    if CnR.Crime and CnR.Crime.SetWanted then CnR.Crime.SetWanted(target, false) end

    local tid = CnR.GetIdentifier(target)
    if tid then
        if CnR.Jail and CnR.Jail.SendToJail then
            CnR.Jail.SendToJail(target, station)
        else
            local tp = CnR.Persistence.GetProfile(tid)
            local seconds = (tp.jailSecondsRemaining or 0) + (tp.jailDebtSeconds or 0)
            TriggerClientEvent('cnr:client:goToJail', target, { seconds = seconds })
        end
    end
    local seconds = 0
    if tid then
        local tp = CnR.Persistence.GetProfile(tid)
        seconds = tp.jailSecondsRemaining or 0
    end
    if CnR.Crime and CnR.Crime.Broadcast then
        -- Left-side game feed (NOT global chat), with role-coloured names, like kill notices. #8
        CnR.Crime.Broadcast(('%s arrested %s'):format(CnR.Crime.NameTag(src), CnR.Crime.NameTagRed(target)))
    end
    CnR.Util.log('info', 'arrest delivered: cop=%d target=%d seconds=%d', src, target, seconds)
end)

-- Instant arrest: jail the cuffed suspect immediately for fewer credits than escorting.
RegisterNetEvent('cnr:server:instantArrest', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local target = tonumber(payload.target); if not target then return end
    if CnR.Arrest.cuffs[target] ~= src then return end   -- must be the cop who cuffed them

    local id = CnR.GetIdentifier(src)
    local credits = (Config.Credits and Config.Credits.perInstantArrest) or 2
    if id then
        local p = CnR.Persistence.GetProfile(id)
        -- Instant arrest pays credits ONLY — no cash. The $1000 is the reward for a full
        -- Standard (escort) arrest. #1
        p.credits = (p.credits or 0) + credits
        CnR.Persistence.SaveProfile(id, p)
    end
    if CnR.BumpStat then CnR.BumpStat(src, 'instantArrests') end   -- #6
    TriggerClientEvent('cnr:client:arrestRewarded', src, {
        credits = credits, cash = 0,
    })
    if CnR.PushProfile then CnR.PushProfile(src) end
    TriggerClientEvent('cnr:client:notify', src, {
        kind = 'ok', text = ('Instant arrest — +%d credits'):format(credits),
    })

    uncuff(target)
    if CnR.Crime and CnR.Crime.SetWanted then CnR.Crime.SetWanted(target, false) end
    if CnR.Jail and CnR.Jail.SendToJail then
        CnR.Jail.SendToJail(target)
    end
    if CnR.Crime and CnR.Crime.Broadcast then
        -- Left-side game feed (NOT global chat), with role-coloured names, like kill notices. #8
        CnR.Crime.Broadcast(('%s arrested %s'):format(CnR.Crime.NameTag(src), CnR.Crime.NameTagRed(target)))
    end
    CnR.Util.log('info', 'instant arrest: cop=%d target=%d', src, target)
end)

CreateThread(function()
    while true do
        Wait(2000)
        for target, cop in pairs(CnR.Arrest.cuffs) do
            local copPed = GetPlayerPed(cop)
            local targetPed = GetPlayerPed(target)
            if copPed == 0 or targetPed == 0
                or GetEntityHealth(copPed) <= 0
                or GetEntityHealth(targetPed) <= 0 then
                uncuff(target)
            end
        end
    end
end)

-- Persist a (now offline) cuffed robber's owed time as an active sentence so they are
-- sent to jail the next time they connect (server/main.lua restore checks this).
local function commitJailOnReconnect(target)
    local id = CnR.GetIdentifier(target); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    local total = (p.jailSecondsRemaining or 0) + (p.jailDebtSeconds or 0)
    if total > 0 then
        p.jailSecondsRemaining = total
        p.jailDebtSeconds = 0
        CnR.Persistence.SaveProfile(id, p)
        CnR.Persistence.Flush()
    end
end

AddEventHandler('playerDropped', function()
    local src = source

    -- Case A: the COP who cuffed someone disconnected → the cuffed robber is freed
    -- (uncuffed), since the arresting officer is gone.
    for target, cop in pairs(CnR.Arrest.cuffs) do
        if cop == src then uncuff(target) end
    end

    -- Case B: a CUFFED robber disconnected → jail them on their next connect.
    if CnR.Arrest.cuffs[src] then
        CnR.Arrest.cuffs[src] = nil
        commitJailOnReconnect(src)
    end
end)

-- A player reported their own death. Uncuff if:
--   • they were the cuffed robber, OR
--   • they were a COP who had someone cuffed (the dead officer can't finish the arrest).
RegisterNetEvent('cnr:server:reportDeath', function()
    local victim = source
    if CnR.Arrest.cuffs[victim] then
        uncuff(victim)
    end
    for target, cop in pairs(CnR.Arrest.cuffs) do
        if cop == victim then uncuff(target) end
    end
end)
