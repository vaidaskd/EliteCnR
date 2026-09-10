CnR = CnR or {}
CnR.Crime = CnR.Crime or {}

local wanted = {}

local function setWantedState(src, value)
    value = value and true or false
    wanted[src] = value or nil
    local pl = Player(src)
    if pl and pl.state then
        pl.state:set('cnrWanted', value, true)
    end
    -- Persist wanted status so it survives a disconnect/reconnect (no combat-logging out of
    -- wanted) and so the join feed can colour a returning wanted robber's name red. #1
    local id = CnR.GetIdentifier and CnR.GetIdentifier(src) or nil
    if id then
        local p = CnR.Persistence and CnR.Persistence.GetProfile(id)
        if p then
            p.wanted = value or nil
            CnR.Persistence.SaveProfile(id, p)
        end
    end
    TriggerClientEvent('cnr:client:setWanted', src, { wanted = value })
end

function CnR.Crime.SetWanted(src, value)
    setWantedState(src, value)
end

function CnR.Crime.IsWanted(src)
    return wanted[src] == true
end

-- Is this player currently serving time (in a cell right now)?
local function isServing(src)
    local j = false
    pcall(function() local s = Player(src).state; j = s and s.cnrJailed end)
    if j then return true end
    return (CnR.Jail and CnR.Jail.IsJailed and CnR.Jail.IsJailed(src)) or false
end

local function addJail(src, seconds)
    if not seconds or seconds <= 0 then return end
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    if isServing(src) then
        -- Already a prisoner → extend the ACTIVE sentence so the countdown actually grows and
        -- the HUD updates now. (Adding to debt only would never touch the current sentence.) #9
        p.jailSecondsRemaining = (p.jailSecondsRemaining or 0) + seconds
        CnR.Persistence.SaveProfile(id, p)
        TriggerClientEvent('cnr:client:jailTimeUpdate', src, { seconds = math.floor((p.jailSecondsRemaining) + 0.5) })
    else
        p.jailDebtSeconds = (p.jailDebtSeconds or 0) + seconds
        CnR.Persistence.SaveProfile(id, p)
    end
    if CnR.PushProfile then CnR.PushProfile(src) end
end

local function notify(src, kind, text)
    TriggerClientEvent('cnr:client:notify', src, { kind = kind, text = text })
end

-- Human-readable jail duration: seconds under a minute, otherwise minutes (+ seconds).
function CnR.Crime.FmtJail(sec)
    sec = math.floor(tonumber(sec) or 0)
    if sec < 60 then return sec .. ' seconds' end
    local m, s = math.floor(sec / 60), sec % 60
    return (s == 0) and (m .. ' min') or (m .. ' min ' .. s .. 's')
end
local fmtJail = CnR.Crime.FmtJail

-- Announce a public action (kill / arrest) to everyone on the server. #14
function CnR.Crime.Broadcast(text)
    TriggerClientEvent('cnr:client:notify', -1, { kind = 'info', text = text })
end
local function broadcast(text) CnR.Crime.Broadcast(text) end

-- A player's role for nickname colouring: cop / prisoner / wanted / innocent. Read from the
-- saved profile so it's correct even before the live side state is wired up (e.g. at join). #6
local function roleOf(src)
    local id = CnR.GetIdentifier(src)
    local profile = id and CnR.Persistence.GetProfile(id) or nil
    local side = (profile and profile.side) or (CnR.GetSide and CnR.GetSide(src)) or 'none'
    local jailed = false
    pcall(function() local s = Player(src).state; jailed = s and s.cnrJailed end)
    if not jailed and profile and (profile.jailSecondsRemaining or 0) > 0 then jailed = true end
    if side == CnR.Sides.COP or side == 'cop' then return 'cop' end
    if jailed then return 'prisoner' end
    -- Runtime wanted (live) OR persisted wanted (e.g. at join, before the live state is
    -- wired up) → red. #1
    if CnR.Crime.IsWanted(src) or (profile and profile.wanted) then return 'wanted' end
    return 'innocent'   -- robber not wanted, or no team chosen yet
end

-- Game-feed colour codes (left-side ticker). innocent/none = white.
local FEED_COLOR = { cop = '~b~', prisoner = '~o~', wanted = '~r~', innocent = '~w~' }
-- Global-chat hex colours, matching the in-game nickname palette.
local HEX_COLOR  = { cop = '#1d6fff', prisoner = '#ff8c00', wanted = '#ff3b3b', innocent = '#ffffff' }

-- Role-coloured name for the game feed (thefeed ticker). CnR.GetName never returns empty
-- (raw GetPlayerName does early in the join, breaking the name — see player_list.lua).
local function safeName(src)
    return (CnR.GetName and CnR.GetName(src)) or GetPlayerName(src) or '?'
end

-- Role-coloured name for the game feed (thefeed ticker).
function CnR.Crime.NameTag(src)
    return (FEED_COLOR[roleOf(src)] or '~w~') .. safeName(src) .. '~s~'
end
-- Join / leave feed name colour: cop blue, wanted robber red, everyone else (innocent,
-- no team chosen / first spawn, or a prisoner with residual jail time) WHITE. Orange is
-- reserved for the live "serving jail" status, never the connect feed. #2
function CnR.Crime.NameTagConnect(src)
    local role = roleOf(src)
    local code = (role == 'cop') and '~b~' or (role == 'wanted') and '~r~' or '~w~'
    return code .. safeName(src) .. '~s~'
end
-- Force a RED name regardless of role — used for the suspect in arrest notices so they
-- read as the offender (red), not the prisoner orange that kicks in once jailed. Orange
-- is reserved for the live "serving jail" status (HUD / chat), not the arrest feed. #3
function CnR.Crime.NameTagRed(src)
    return '~r~' .. safeName(src) .. '~s~'
end
-- Role-coloured name for global chat (^#hex … ^7).
function CnR.Crime.NameHex(src)
    return ('^%s%s^7'):format(HEX_COLOR[roleOf(src)] or '#ffffff', safeName(src))
end
local nameTag = CnR.Crime.NameTag

-- Victim-side death report. `source` is the player who DIED; payload.killer is the
-- server id of whoever killed them (0 if not a player / unknown). The server applies
-- the correct penalty to the KILLER:
--   • wanted robber kills cop          → +2 min jail (stays wanted)
--   • innocent robber kills cop        → +2 min jail + wanted
--   • robber kills any other robber    → +2 min jail (+ wanted if innocent)
--   • cop kills wanted robber          → credit reward
--   • cop kills innocent player        → -1 credit penalty (floored at 0)
RegisterNetEvent('cnr:server:reportDeath', function(payload)
    local victim = source
    if type(payload) ~= 'table' then return end
    local killer = tonumber(payload.killer)
    if not killer or killer == 0 or killer == victim then return end

    local killerSide   = CnR.GetSide(killer)
    local victimSide   = CnR.GetSide(victim)
    local killerWanted = CnR.Crime.IsWanted(killer)
    local victimWanted = CnR.Crime.IsWanted(victim)
    local jailAdd      = (Config.JailTime and Config.JailTime.killPlayer) or 120  -- 2 min

    -- A currently-jailed PRISONER who kills anyone just gets +1 min tacked onto their active
    -- sentence — no wanted flag, no reward/credit logic (they're already serving). #prisoner-kill
    if isServing(killer) then
        local add = (Config.JailTime and Config.JailTime.prisonerKill) or 60
        addJail(killer, add)
        notify(killer, 'error', ('You killed someone while jailed — +%s to your sentence'):format(fmtJail(add)))
        broadcast(('%s murdered %s'):format(nameTag(killer), nameTag(victim)))   -- #7
        return
    end

    -- Is the victim a prisoner right now? (Killing a prisoner is never rewarded.) #2
    local victimJailed = false
    pcall(function() local s = Player(victim).state; victimJailed = s and s.cnrJailed end)

    if killerSide == CnR.Sides.COP then
        if victimSide == CnR.Sides.COP then
            -- Cop-vs-cop is blocked by the relationship-group immunity client-side;
            -- if it somehow happens, do nothing (no penalty, no reward).
            return
        end
        if victimJailed or not victimWanted then
            -- Cop killed a PRISONER or an innocent (non-wanted) player → lose 1 credit. The
            -- prisoner check makes this fire on the FIRST kill too (a jailed robber may still
            -- read as wanted otherwise). Allowed to go negative so it shows on the HUD. #2
            if CnR.Ranks and CnR.Ranks.GrantCredits then
                CnR.Ranks.GrantCredits(killer, -1)
            end
            notify(killer, 'error', victimJailed and 'You killed a prisoner — lost 1 credit'
                or 'You killed an innocent — lost 1 credit')
            broadcast(('%s killed %s'):format(nameTag(killer), nameTag(victim)))   -- #7
            return
        end
        -- Cop killed a wanted robber → reward credits + notification.
        local reward = (Config.Credits and Config.Credits.perKill) or 1
        if CnR.Ranks and CnR.Ranks.GrantCredits then
            CnR.Ranks.GrantCredits(killer, reward)
        end
        if CnR.BumpStat then CnR.BumpStat(killer, 'robberKills') end   -- #6

        notify(killer, 'ok', ("You've killed a ~r~wanted robber~s~, +%d credit added"):format(reward))
        broadcast(('%s eliminated %s'):format(nameTag(killer), nameTag(victim)))   -- #7

    elseif killerSide == CnR.Sides.ROBBER then
        -- Robber killed a cop OR another robber → jail time; become wanted if not already. If
        -- they're already serving, addJail extends the ACTIVE sentence (don't re-flag wanted). #9
        addJail(killer, jailAdd)
        if not killerWanted and not isServing(killer) then
            setWantedState(killer, true)
        end
        notify(killer, 'error', ("You've committed ~r~murder~s~, +%s jail time added"):format(fmtJail(jailAdd)))
        broadcast(('%s murdered %s'):format(nameTag(killer), nameTag(victim)))   -- #7
    end

    CnR.Util.log('info', 'reportDeath victim=%d killer=%d killerSide=%s victimSide=%s',
        victim, killer, tostring(killerSide), tostring(victimSide))
end)

-- Innocent robber INJURES a cop (actual damage) → +1 min jail + wanted, ONCE.
-- The wanted check makes it fire only on the first injury (already-wanted robbers skip).
RegisterNetEvent('cnr:server:reportCopShot', function()
    local src = source
    if CnR.GetSide(src) ~= CnR.Sides.ROBBER then return end
    if CnR.Crime.IsWanted(src) then return end
    local add = Config.JailTime.copShot or 60
    addJail(src, add)
    setWantedState(src, true)
    notify(src, 'error', ('You ~r~injured~s~ a police officer, +%s jail time added'):format(fmtJail(add)))
end)

-- Robber steals a police vehicle → jail time, but only ONCE per life (until /newlife).
-- The flag lives in the profile so it survives reconnects within the same life. #2
RegisterNetEvent('cnr:server:reportPoliceCarTheft', function()
    local src = source
    if CnR.GetSide(src) == CnR.Sides.COP then return end
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    if p.copCarFined then return end          -- already penalised this life
    p.copCarFined = true
    CnR.Persistence.SaveProfile(id, p)
    local add = Config.JailTime.copCarStolen or 60
    addJail(src, add)
    setWantedState(src, true)
    notify(src, 'error', ('You ~r~stole~s~ a police vehicle, +%s jail time added'):format(fmtJail(add)))
end)

-- Killing a pedestrian (NPC): same rules as killing a player. The client only reports
-- the kill when the NPC was NOT acting aggressively (no self-defence penalty).
--   • cop    → -1 credit (may go negative so it shows on the HUD) + notification
--   • robber → +2 min jail + wanted + "murder" notification
RegisterNetEvent('cnr:server:reportNpcKill', function()
    local src = source
    local side = CnR.GetSide(src)
    -- Jailed prisoner killing an NPC → +1 min to their sentence (same as killing a player). #prisoner-kill
    if isServing(src) then
        local add = (Config.JailTime and Config.JailTime.prisonerKill) or 60
        addJail(src, add)
        notify(src, 'error', ('You killed someone while jailed — +%s to your sentence'):format(fmtJail(add)))
        return
    end
    if side == CnR.Sides.COP then
        if CnR.Ranks and CnR.Ranks.GrantCredits then
            CnR.Ranks.GrantCredits(src, -1)
        end
        notify(src, 'error', 'You killed a civilian — lost 1 credit')
    elseif side == CnR.Sides.ROBBER then
        local jailAdd = (Config.JailTime and Config.JailTime.killPlayer) or 120
        addJail(src, jailAdd)
        if not CnR.Crime.IsWanted(src) then
            setWantedState(src, true)
        end
        notify(src, 'error', ("You've committed ~r~murder~s~, +%s jail time added"):format(fmtJail(jailAdd)))
    end
end)

-- Role-coloured join / leave lines in the LEFT-SIDE game feed (not global chat), matching the
-- kill/arrest notices. The default green/red chat lines are turned off via
-- chat_showJoins/chat_showQuits in server.cfg. Colour = role: cop blue, prisoner orange,
-- wanted red, innocent / not-yet-chosen white. #6
AddEventHandler('playerJoining', function()
    local src = source
    if GetPlayerName(src) then
        CnR.Crime.Broadcast(('%s joined the server'):format(CnR.Crime.NameTagConnect(src)))
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    -- Post the leave line BEFORE clearing wanted, so the colour is still accurate.
    if GetPlayerName(src) then
        CnR.Crime.Broadcast(('%s left the server'):format(CnR.Crime.NameTagConnect(src)))
    end
    wanted[src] = nil
end)
