CnR = CnR or {}
CnR.Chat = {}

local function chatCfg()
    return (Config and Config.Chat) or {}
end

local function nameColorForSide(side)
    local colors = (chatCfg().nameColors) or {}
    return colors[side] or colors.civ or '#ffffff'
end

--- Send a player chat message visible to everyone (or a specific target).
--- Renders with the coloured name prefix in gfx-chat's "message" template.
function CnR.Chat.Say(target, name, message, side)
    TriggerClientEvent('gfx-chat:addMessage', target, {
        type    = 'message',
        src     = 0,
        id      = 0,
        admin   = (side == 'admin'),
        name    = name or 'Unknown',
        message = message or '',
        color   = nameColorForSide(side),
    })
end

--- Send a plain system notification (grey "notify" style).
function CnR.Chat.System(target, message)
    TriggerClientEvent('gfx-chat:addMessage', target, {
        type    = 'notify',
        message = message or '',
    })
end

--- Send a highlighted notice (yellow "alert" style) with an optional tag prefix.
function CnR.Chat.Notice(target, preset, message, overrides)
    local presets = (chatCfg().notices) or {}
    local p = presets[preset] or presets.system or {
        tag = 'NOTE', tagColor = '#ffffff', label = '!', labelColor = '#ffcc33',
    }
    overrides = overrides or {}
    local tag = overrides.tag or p.tag

    TriggerClientEvent('gfx-chat:addMessage', target, {
        type    = 'alert',
        message = ('[%s] %s'):format(tag, message or ''),
    })
end

-- ─── Player chat (cnr_chat NUI) ────────────────────────────────────────────────
-- The custom chat sends the typed text here; we stamp the role colour + server ID and
-- fan it out. Name colour: blue cop, red wanted robber, white innocent robber / no team.
local CHAT_LOCAL_RANGE = 22.0   -- metres for LOCAL chat + the over-head bubble

-- ─── Profanity filter ──────────────────────────────────────────────────────────
-- Curse words are replaced with symbol masks (case-insensitive, matched anywhere in a
-- word) so they never appear in ANY channel or the over-head bubble. Longer entries are
-- matched first so compound words mask fully.
local CENSOR_SYMBOLS = { '#', '$', '%', '@', '&', '*' }
local CURSE_WORDS = {
    'motherfucker', 'cocksucker', 'douchebag', 'bollocks', 'dickhead', 'bullshit',
    'asshole', 'dumbass', 'jackass', 'bastard', 'faggot', 'nigger', 'nigga', 'retard',
    'vagina', 'pussy', 'bitch', 'whore', 'dildo', 'prick', 'wanker',
    'fuck', 'shit', 'cunt', 'dick', 'cock', 'penis', 'slut', 'twat', 'fag',
}
table.sort(CURSE_WORDS, function(a, b) return #a > #b end)   -- longest first

local function maskOf(len)
    local t = {}
    for i = 1, len do t[i] = CENSOR_SYMBOLS[((i - 1) % #CENSOR_SYMBOLS) + 1] end
    return table.concat(t)
end
local function ciPattern(word)
    return (word:gsub('%a', function(c) return '[' .. c:upper() .. c:lower() .. ']' end))
end
function CnR.Chat.Censor(text)
    local out = tostring(text or '')
    for _, w in ipairs(CURSE_WORDS) do
        out = out:gsub(ciPattern(w), function(m) return maskOf(#m) end)
    end
    return out
end

-- First few words of a message, for the LOCAL over-head bubble — the full text still
-- goes to the chat window; only this preview is shortened. #A
local function chatShortText(message)
    local words, n = {}, 0
    for w in tostring(message):gmatch('%S+') do
        n = n + 1
        if n > 5 then break end
        words[#words + 1] = w
    end
    local s = table.concat(words, ' ')
    if n > 5 then s = s .. '…' end
    return s
end

RegisterNetEvent('cnr:chat:send', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local message = tostring(payload.text or '')
    if message == '' then return end
    if #message > 256 then message = message:sub(1, 256) end
    message = CnR.Chat.Censor(message)   -- mask profanity before it's shown anywhere

    local channel = tostring(payload.channel or 'global')
    if channel ~= 'local' and channel ~= 'police' then channel = 'global' end

    local side   = (CnR.GetSide and CnR.GetSide(src)) or 'none'
    local wanted = CnR.Crime and CnR.Crime.IsWanted and CnR.Crime.IsWanted(src)

    local pl = Player(src)
    local jailed = pl and pl.state and pl.state.cnrJailed
    local nameColor = '#ffffff'                                    -- innocent robber / no team
    if jailed then nameColor = '#ff8c00'                          -- prisoner → orange #10
    elseif side == CnR.Sides.COP then nameColor = '#1d6fff'       -- cop → blue (#1d6fff)
    elseif side == CnR.Sides.ROBBER and wanted then nameColor = '#ff5a5a' end  -- wanted → red

    local textColor = (type(payload.color) == 'string' and payload.color:match('^#%x%x%x%x%x%x$')) or nil

    -- CnR.GetName is the cached, never-empty resolver — raw GetPlayerName() returns "" for
    -- a short window after connect, which showed the ID with a blank name. See player_list.lua.
    local displayName = (CnR.GetName and CnR.GetName(src)) or GetPlayerName(src) or ('Player %d'):format(src)
    local function makeMsg()
        return {
            cnr       = true,
            channel   = channel,
            name      = ('%s (%d)'):format(displayName, src),
            nameColor = nameColor,
            text      = message,
            textColor = textColor,
        }
    end

    if channel == 'police' then
        -- POLICE RADIO: cops only (robbers can't send).
        if side ~= CnR.Sides.COP then
            CnR.Chat.System(src, 'Police radio is for officers only.')
            return
        end
        for _, pid in ipairs(GetPlayers()) do
            local p = tonumber(pid)
            if (CnR.GetSide and CnR.GetSide(p)) == CnR.Sides.COP then
                TriggerClientEvent('chat:addMessage', p, makeMsg())
            end
        end
    elseif channel == 'local' then
        -- LOCAL: players within range of the sender, plus an over-head bubble. If the
        -- sender is a prisoner, every OTHER prisoner also receives it regardless of
        -- distance — prison cells can be spread out, so plain proximity missed them. #3
        local sped = GetPlayerPed(src)
        if sped == 0 then return end
        local sc = GetEntityCoords(sped)
        local short = chatShortText(message)
        local function senderJailed(id)
            local pl = Player(id); return pl and pl.state and pl.state.cnrJailed and true or false
        end
        local imJailed = senderJailed(src)
        for _, pid in ipairs(GetPlayers()) do
            local p = tonumber(pid)
            local pped = GetPlayerPed(p)
            if pped ~= 0 then
                local inRange = #(sc - GetEntityCoords(pped)) <= CHAT_LOCAL_RANGE
                local bothJailed = imJailed and senderJailed(p)
                if inRange or bothJailed then
                    TriggerClientEvent('chat:addMessage', p, makeMsg())
                    -- Over-head bubble — sent to EACH player individually (never a table). #4
                    TriggerClientEvent('cnr:client:localBubble', p, { sender = src, text = short })
                end
            end
        end
    else
        TriggerClientEvent('chat:addMessage', -1, makeMsg())
    end
    CnR.Util.log('info', 'chat[%s] src=%d: %s', channel, src, message)
end)

-- ─── Join welcome banner ────────────────────────────────────────────────────────
-- "Cops" blue, "Robbers" red, rest white (via ^ colour codes). "Elite" stays white.
function CnR.Chat.Welcome(target)
    TriggerClientEvent('gfx-chat:addMessage', target, {
        type    = 'notify',
        message = 'Welcome to Elite ^#1d6fffCops^7 and ^1Robbers^7!',
    })
end

-- ─── /notice command ──────────────────────────────────────────────────────────
RegisterCommand('notice', function(src, args)
    if src ~= 0 then
        if not IsPlayerAceAllowed(src, 'cnr.notice')
            and not IsPlayerAceAllowed(src, 'cnr.admin')
        then return end
    end

    local preset = args[1]
    if not preset or #args < 2 then
        if src ~= 0 then
            CnR.Chat.System(src, 'Usage: /notice <preset> <message>')
        else
            print('Usage: notice <preset> <message>')
        end
        return
    end

    table.remove(args, 1)
    CnR.Chat.Notice(-1, preset, table.concat(args, ' '))
end, true)