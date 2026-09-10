CnR = CnR or {}

-- Tell the client whether this player is staff, so dev/debug commands stay admin-only. #11
RegisterNetEvent('cnr:server:checkAdmin', function()
    local src = source
    local isAdmin = IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'cnr.admin')
    TriggerClientEvent('cnr:client:setAdmin', src, isAdmin and true or false)
end)

local RESOURCE     = 'cnr'
local REPORTS_FILE = 'data/reports.json'

local function loadReports()
    local raw = LoadResourceFile(RESOURCE, REPORTS_FILE)
    if not raw or raw == '' then return {} end
    local ok, out = pcall(function()

        return json.decode(raw)
    end)
    if ok and type(out) == 'table' then return out end
    return {}
end

local function saveReports(t)
    local ok, encoded = pcall(json.encode, t)
    if not ok then return false end
    return SaveResourceFile(RESOURCE, REPORTS_FILE, encoded, -1)
end

RegisterCommand('help', function(src)
    if src == 0 then
        print('[cnr] /help is a player command')
        return
    end
    TriggerClientEvent('cnr:client:openHelp', src)
end, false)

RegisterCommand('report', function(src, args)
    if src == 0 then return end
    if not args[1] then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '[cnr]', 'Usage: /report <id> <reason...>' }
        })
        return
    end
    local targetId = tonumber(args[1])
    if not targetId then return end
    local reason = table.concat(args, ' ', 2)
    if reason == '' then reason = '(no reason)' end
    local reports = loadReports()
    table.insert(reports, {
        ts = os.time(),
        reporterSrc = src,
        targetId = targetId,
        reason = reason,
    })
    saveReports(reports)
    CnR.Util.log('info', 'report by src=%d target=%d reason=%s', src, targetId, reason)
    print(string.format('[cnr][report] src=%d target=%d reason=%s', src, targetId, reason))
    TriggerClientEvent('chat:addMessage', src, {
        args = { '[cnr]', 'Report filed. Thanks.' }
    })
end, false)

local function isAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, 'cnr.admin')
        or IsPlayerAceAllowed(src, 'command.cnraddjail')
        or IsPlayerAceAllowed(src, 'command.cnrfree')
        or IsPlayerAceAllowed(src, 'command.cndfree')
end

local function parseJailSeconds(value)
    local raw = tostring(value or ''):lower()
    local amount, unit = raw:match('^(%d+)([sm]?)$')
    amount = tonumber(amount)
    if not amount or amount <= 0 then return nil end
    if unit == 's' then return amount end
    return amount * 60
end

local function reply(src, text)
    if src == 0 then
        print('[cnr] ' .. text)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '[cnr]', text } })
    end
end

RegisterCommand('noclip', function(src)
    if src == 0 then print('[cnr] /noclip is a player-only command'); return end
    if not isAdmin(src) then
        reply(src, 'No permission.')
        return
    end
    TriggerClientEvent('cnr:client:toggleNoclip', src)
end, false)

RegisterCommand('cnraddjail', function(src, args)
    if not isAdmin(src) then
        reply(src, 'No permission.')
        return
    end

    local target = tonumber(args[1] or '')
    local seconds = parseJailSeconds(args[2])
    if not target or not seconds then
        reply(src, 'Usage: /cnraddjail <playerId> <minutes|seconds>s. Examples: /cnraddjail 1 3 or /cnraddjail 1 180s')
        return
    end

    if not GetPlayerName(target) then
        reply(src, ('Player %s is not online.'):format(target))
        return
    end

    local id = CnR.GetIdentifier(target)
    if not id then
        reply(src, ('Player %s has no license identifier yet.'):format(target))
        return
    end

    local p = CnR.Persistence.GetProfile(id)
    p.jailDebtSeconds = (p.jailDebtSeconds or 0) + seconds
    if p.side == nil or p.side == 'none' then
        p.side = 'robber'
        if CnR.State and CnR.State.sides then CnR.State.sides[target] = CnR.Sides.ROBBER end
    end
    CnR.Persistence.SaveProfile(id, p)

    if CnR.Jail and CnR.Jail.SendToJail then
        CnR.Jail.SendToJail(target)
    end
    if CnR.PushProfile then CnR.PushProfile(target) end

    local total = (p.jailSecondsRemaining or 0) + (p.jailDebtSeconds or 0)
    reply(src, ('Added %d seconds jail time to %s.'):format(seconds, GetPlayerName(target) or target))
    TriggerClientEvent('cnr:client:notify', target, {
        kind = 'warn',
        text = ('Admin added %d seconds jail time.'):format(seconds),
    })
    CnR.Util.log('info', 'admin src=%s added jail=%ds to target=%s total=%s',
        tostring(src), seconds, tostring(target), tostring(total))
end, false)

local function freeJailedPlayer(src, args, commandName)
    if not isAdmin(src) then
        reply(src, 'No permission.')
        return
    end

    local target = tonumber(args[1] or '')
    if not target then
        reply(src, ('Usage: /%s <playerId>'):format(commandName))
        return
    end

    if not GetPlayerName(target) then
        reply(src, ('Player %s is not online.'):format(target))
        return
    end

    local id = CnR.GetIdentifier(target)
    if not id then
        reply(src, ('Player %s has no license identifier yet.'):format(target))
        return
    end

    local p = CnR.Persistence.GetProfile(id)
    p.jailDebtSeconds = 0
    p.jailSecondsRemaining = 0
    CnR.Persistence.SaveProfile(id, p)

    local ok = false
    if CnR.Jail and CnR.Jail.Release then
        ok = CnR.Jail.Release(target)
    else
        TriggerClientEvent('cnr:client:jailTimeUpdate', target, { seconds = 0 })
    end
    if CnR.Crime and CnR.Crime.SetWanted then CnR.Crime.SetWanted(target, false) end
    if CnR.PushProfile then CnR.PushProfile(target) end

    reply(src, ('Freed %s from jail.'):format(GetPlayerName(target) or target))
    TriggerClientEvent('cnr:client:notify', target, {
        kind = 'ok',
        text = 'Admin released you from jail.',
    })
    CnR.Util.log('info', 'admin src=%s freed target=%s ok=%s',
        tostring(src), tostring(target), tostring(ok))
end

RegisterCommand('cndfree', function(src, args)
    freeJailedPlayer(src, args, 'cndfree')
end, false)

RegisterCommand('cnrfree', function(src, args)
    freeJailedPlayer(src, args, 'cnrfree')
end, false)

local DEFAULT_CIV_SKINS = {
    'a_m_y_business_03', 'a_m_y_hipster_01', 'a_m_m_eastsa_01',
    'a_f_y_business_02', 'a_f_y_hipster_02', 'a_m_y_skater_01',
    'a_m_y_genstreet_01', 'a_m_y_stbla_01',
}

RegisterNetEvent('cnr:server:newLife', function()
    local src = source
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)

    -- Order: wanted first, then jail debt/sentence, joined with " + ".
    local blocked = {}
    if CnR.Crime and CnR.Crime.IsWanted and CnR.Crime.IsWanted(src) then
        blocked[#blocked + 1] = 'wanted status'
    end
    if (p.jailSecondsRemaining or 0) > 0 then
        blocked[#blocked + 1] = 'active jail sentence'
    end
    if (p.jailDebtSeconds or 0) > 0 then
        blocked[#blocked + 1] = 'active jail debt'
    end
    if #blocked > 0 then
        TriggerClientEvent('cnr:client:notify', src, {
            kind = 'error',
            text = 'New life unavailable: ' .. table.concat(blocked, ' + '),
        })
        return
    end

    p.outfit = 1
    p.cash = 0
    p.credits = 0   -- credits do not carry across a new life
    p.tattoos = {}  -- a new life wipes all tattoos (#6)
    p.copCarFined = nil   -- the once-per-life police-vehicle fine resets (#2)
    p.jailDebtSeconds = 0
    p.jailSecondsRemaining = 0
    p.side = 'none'
    p.lastPos = nil
    p.station = nil
    p.hideHat = nil   -- Police Hat toggle does not carry across lives.
    -- A new life wipes the whole loadout/inventory (no carrying cop weapons into a robber life).
    p.weapons = {}
    p.weaponAmmo = {}
    p.inventory = {}
    if p.skin then
        p.skin = CnR.Util.NormalizeCopSkin(p.skin)
        -- A new life also drops clothing-store cosmetics (hat/glasses/watch) so they don't
        -- linger across spawns or bleed into the next side's look. These otherwise persist
        -- across death and reconnect — only /newlife clears them. #4
        p.skin.hat, p.skin.hatTxt = nil, nil
        p.skin.glasses, p.skin.glassesTxt = nil, nil
        p.skin.watch, p.skin.watchTxt = nil, nil
    end
    CnR.Persistence.SaveProfile(id, p)
    if CnR.ResetStats then CnR.ResetStats(src) end   -- per-life cop stats reset #6
    TriggerClientEvent('cnr:client:applyTattoos', src, {})   -- wipe tattoo decorations now #6
    CnR.State.sides[src] = CnR.Sides.NONE
    local pl = Player(src)
    if pl and pl.state then pl.state:set('cnrSide', CnR.Sides.NONE, true) end
    TriggerEvent('cnr_doorlock:setPlayerSide', src, CnR.Sides.NONE)
    TriggerClientEvent('cnr_doorlock:setLocalSide', src, CnR.Sides.NONE)
    if CnR.Crime and CnR.Crime.SetWanted then CnR.Crime.SetWanted(src, false) end

    local copSkins = { 'mp_m_freemode_01', 'mp_f_freemode_01' }
    TriggerClientEvent('cnr:client:openTeamSelect', src, {
        skinsByTeam = {
            cop    = copSkins,
            robber = DEFAULT_CIV_SKINS,
        },
        profileSkin = p.skin or false,
    })
    CnR.Util.log('info', 'newLife reset for src=%d', src)
end)
