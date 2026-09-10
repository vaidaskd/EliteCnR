CnR = CnR or {}
CnR.State = CnR.State or { sides = {} }

function CnR.GetIdentifier(src)
    if not src or src == 0 then return nil end
    return GetPlayerIdentifierByType(src, 'license')
end

-- ── Per-life cop stats (#6) ───────────────────────────────────────────────────
-- Counts arrests/kills for the current life. Stored in the persistent profile so they
-- survive a disconnect/reconnect — only /newlife clears them.
local function statsOf(p)
    p.stats = p.stats or { stdArrests = 0, instantArrests = 0, robberKills = 0 }
    return p.stats
end

function CnR.BumpStat(src, key)
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    local s = statsOf(p)
    s[key] = (s[key] or 0) + 1
    CnR.Persistence.SaveProfile(id, p)
end

function CnR.GetStats(src)
    local id = CnR.GetIdentifier(src)
    if not id then return { stdArrests = 0, instantArrests = 0, robberKills = 0 } end
    return statsOf(CnR.Persistence.GetProfile(id))
end

function CnR.ResetStats(src)
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    p.stats = { stdArrests = 0, instantArrests = 0, robberKills = 0 }
    CnR.Persistence.SaveProfile(id, p)
end

RegisterNetEvent('cnr:server:getStats', function()
    local src = source
    TriggerClientEvent('cnr:client:showStats', src, CnR.GetStats(src))
end)

-- Resolve the current rank (+ next-level XP for the HUD bar) for either ladder.
local function rankWithNext(side, xp)
    xp = tonumber(xp) or 0
    -- Robbers no longer have a rank ladder (credits replaced XP/levels).
    if side == CnR.Sides.ROBBER then return nil end
    local list = Config and Config.Ranks
    if not list then return nil end
    local cur = list[1]
    for _, r in ipairs(list) do if xp >= (r.xp or 0) then cur = r else break end end
    if not cur then return nil end
    local nextXp
    for _, r in ipairs(list) do
        if (r.xp or 0) > (cur.xp or 0) and (not nextXp or r.xp < nextXp) then nextXp = r.xp end
    end
    return { id = cur.id, name = cur.name, xp = cur.xp or 0, nextXp = nextXp }
end

function CnR.PushProfile(src)
    if not src or src == 0 then return end
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    local rank = rankWithNext(p.side, p.xp or 0)
    TriggerClientEvent('cnr:client:profileUpdate', src, {
        side            = p.side or 'none',
        xp              = p.xp or 0,
        rankId          = rank and rank.id or 1,
        rankName        = rank and rank.name or nil,
        rank            = rank,   -- full rank (id/name/xp/nextXp) for the HUD bar
        station         = p.station,
        cash            = p.cash or 0,
        credits         = p.credits or 0,
        jailSeconds     = p.jailSecondsRemaining or 0,
        jailDebtSeconds = p.jailDebtSeconds or 0,
    })
end

function CnR.GetSide(src)
    return CnR.State.sides[src] or CnR.Sides.NONE
end

function CnR.SetSide(src, side)
    if side ~= CnR.Sides.COP and side ~= CnR.Sides.ROBBER and side ~= CnR.Sides.NONE then
        CnR.Util.log('warn', 'SetSide: invalid side %s for src=%s', tostring(side), tostring(src))
        return
    end
    CnR.State.sides[src] = side
    TriggerEvent('cnr_doorlock:setPlayerSide', src, side)
    TriggerClientEvent('cnr_doorlock:setLocalSide', src, side)
    local id = CnR.GetIdentifier(src)
    if id then
        local profile = CnR.Persistence.GetProfile(id)
        profile.side = side
        CnR.Persistence.SaveProfile(id, profile)
    end
end

local DEFAULT_ROBBER_SKIN = {
    isCustom = true,
    gender = 'male',
    father = 0,
    mother = 0,
    shapeMix = 0.5,
    skinMix = 0.5,
    eyes = 0,
    hair = 4,
    hairColor = 2,
    beard = 0,
    beardColor = 0,
    top = 1,
    topTxt = 0,
    pants = 1,
    pantsTxt = 0,
    shoes = 1,
    shoesTxt = 0,
    arms = 0
}

local function pickRobberSpawn()
    local list = (Config and Config.Spawns and Config.Spawns.robbers) or nil
    if not list or #list == 0 then return nil end

    local function nearInterior(pos)
        local p = vector3(pos.x, pos.y, pos.z)  -- candidate may be a vec4 (with heading)
        local minDist = 15.0
        if Config.Stores then
            for _, s in ipairs(Config.Stores) do
                if s.cashier and #(p - s.cashier) < minDist then return true end
            end
        end
        if Config.Banks then
            for _, b in ipairs(Config.Banks) do
                local t = b.teller
                if t and #(p - vec3(t.x, t.y, t.z)) < minDist then return true end
            end
        end
        return false
    end

    for _ = 1, 8 do
        local candidate = list[math.random(#list)]
        if not nearInterior(candidate) then
            return candidate
        end
    end
    return list[math.random(#list)]
end

local function robberLoadoutFromProfile(profile)
    local blocked = {
        WEAPON_NIGHTSTICK = true,
        WEAPON_FLASHLIGHT = true,
        WEAPON_STUNGUN = true,
        WEAPON_FIREEXTINGUISHER = true,
        WEAPON_FLAREGUN = true,
        WEAPON_SMOKEGRENADE = true,
        GADGET_PARACHUTE = true,
    }
    local weapons = profile.weapons
    local ammo = profile.weaponAmmo
    if weapons and #weapons > 0 then
        if not ammo then ammo = {} end
        local cleaned = {}
        for _, w in ipairs(weapons) do
            if not blocked[w] then
                cleaned[#cleaned + 1] = w
                if not ammo[w] then ammo[w] = 100 end
            end
        end
        weapons = cleaned
        if #weapons == 0 then
            return { 'WEAPON_PISTOL' }, { WEAPON_PISTOL = 100 }
        end
        return weapons, ammo
    end
    return { 'WEAPON_PISTOL' }, { WEAPON_PISTOL = 100 }
end

local function savedSpawn(profile, fallback)
    if profile and profile.lastPos and profile.lastPos.x and profile.lastPos.y and profile.lastPos.z then
        return {
            x = profile.lastPos.x + 0.0,
            y = profile.lastPos.y + 0.0,
            z = profile.lastPos.z + 0.0,
            w = profile.lastPos.h or profile.lastPos.w or 0.0,
        }
    end
    return fallback
end

RegisterNetEvent('cnr:server:syncPosition', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    if CnR.GetSide and CnR.GetSide(src) == CnR.Sides.NONE then return end

    local id = CnR.GetIdentifier(src)
    if not id then return end
    local profile = CnR.Persistence.GetProfile(id)
    local pos = {
        x = tonumber(payload.x) or 0.0,
        y = tonumber(payload.y) or 0.0,
        z = tonumber(payload.z) or 0.0,
        h = tonumber(payload.h) or 0.0,
    }
    if (profile.jailSecondsRemaining or 0) > 0 then
        -- Serving time: remember exactly where in the jail they are, kept SEPARATE from
        -- lastPos (their free-roam spawn) so a reconnect resumes in the same jail spot. #jail-resume
        profile.jailPos = pos
    else
        profile.lastPos = pos
        profile.jailPos = nil   -- free again → drop any stale jail position
    end
    CnR.Persistence.SaveProfile(id, profile)
end)

RegisterNetEvent('cnr:server:setSide', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local id = CnR.GetIdentifier(src)
    local previousProfile = id and CnR.Persistence.GetProfile(id) or nil
    local previousSide = previousProfile and previousProfile.side or CnR.Sides.NONE

    CnR.SetSide(src, payload.side)

    if id then
        local p = CnR.Persistence.GetProfile(id)
        if payload.skin    then p.skin    = payload.skin    end
        if payload.station then p.station = payload.station end
        -- Becoming a robber always starts a clean loadout — never inherit weapons from
        -- a prior cop life (or a post-newLife 'none' state where previousSide isn't COP).
        if payload.side == CnR.Sides.ROBBER then
            p.weapons = {}
            p.weaponAmmo = {}
            p.lastPos = nil
            p.station = nil
        end
        CnR.Persistence.SaveProfile(id, p)
        CnR.Persistence.Flush()  -- Write immediately so skin survives a quick rejoin
    end

    local pl = Player(src)
    if pl and pl.state then pl.state:set('cnrSide', payload.side, true) end

    if payload.side == CnR.Sides.COP then
        if CnR.Ranks and CnR.Ranks.ApplyRank then
            local p = CnR.Persistence.GetProfile(id)
            CnR.Ranks.ApplyRank(src, p.rankId or 1, payload.skin)
        end
    elseif payload.side == CnR.Sides.ROBBER then
        local spawn = pickRobberSpawn()
        local p = id and CnR.Persistence.GetProfile(id) or {}
        local weapons, ammo = robberLoadoutFromProfile(p)
        if not p.weapons or #p.weapons == 0 then
            if CnR.Armory and CnR.Armory.SaveWeapons then
                CnR.Armory.SaveWeapons(id, weapons, ammo)
            end
        end
        TriggerClientEvent('cnr:client:applyLoadout', src, {
            side    = 'robber',
            weapons = weapons,
            ammo    = ammo,
            armor   = nil,
            skin    = payload.skin or DEFAULT_ROBBER_SKIN,
            spawn   = savedSpawn(p, spawn),
        })
    end

    if CnR.PushProfile then CnR.PushProfile(src) end
end)

CnR._welcomed = CnR._welcomed or {}

RegisterNetEvent('cnr:server:requestTeamSelect', function()
    local src = source

    -- One-time global-chat welcome banner per session.
    if not CnR._welcomed[src] then
        CnR._welcomed[src] = true
        if CnR.Chat and CnR.Chat.Welcome then CnR.Chat.Welcome(src) end
    end

    local id = CnR.GetIdentifier(src)
    local profile = id and CnR.Persistence.GetProfile(id) or nil

    if profile and (profile.side == CnR.Sides.COP or profile.side == CnR.Sides.ROBBER) then
        CnR.State.sides[src] = profile.side
        TriggerEvent('cnr_doorlock:setPlayerSide', src, profile.side)
        TriggerClientEvent('cnr_doorlock:setLocalSide', src, profile.side)
        local pl = Player(src)
        if pl and pl.state then pl.state:set('cnrSide', profile.side, true) end

        if profile.side == CnR.Sides.COP then
            if CnR.Ranks and CnR.Ranks.ApplyRank then
                -- Resume at the cop's last location after a restart; nil falls back to station.
                local resume = savedSpawn(profile, nil)
                CnR.Ranks.ApplyRank(src, profile.rankId or 1, profile.skin, true, false, resume)
            end
        else
            local jailed = (profile.jailSecondsRemaining or 0) > 0
            local weapons, ammo = robberLoadoutFromProfile(profile)
            -- If they reconnect with jail time owed (e.g. disconnected while cuffed),
            -- spawn them AT the jail, never at their last position — otherwise the
            -- loadout spawn races the jail teleport and drops them back where they left.
            local spawn
            if jailed then
                -- Spawn straight at their saved jail spot if we have one (goToJail resumes
                -- there too); otherwise fall back to the Bolingbroke anchor. #jail-resume
                local jp = profile.jailPos
                if jp and jp.x then
                    spawn = { x = jp.x, y = jp.y, z = jp.z, w = jp.h or 0.0 }
                else
                    local j = Config.Jail and Config.Jail.bolingbroke
                    spawn = j and { x = j.x, y = j.y, z = j.z, w = j.w or 0.0 } or pickRobberSpawn()
                end
            else
                spawn = savedSpawn(profile, pickRobberSpawn())
            end
            TriggerClientEvent('cnr:client:applyLoadout', src, {
                side    = 'robber',
                weapons = weapons,
                ammo    = ammo,
                armor   = nil,
                skin    = profile.skin or DEFAULT_ROBBER_SKIN,
                spawn   = spawn,
            })
        end

        if (profile.jailSecondsRemaining or 0) > 0 then
            if CnR.Jail and CnR.Jail.SendToJail then
                -- Pass their saved JAIL position so they resume in the same jail at the same
                -- spot (jailPos, not lastPos — lastPos is their free-roam spawn). #jail-resume
                CnR.Jail.SendToJail(src, nil, profile.jailPos)
            else
                TriggerClientEvent('cnr:client:goToJail', src, {
                    seconds = profile.jailSecondsRemaining,
                    resume  = profile.jailPos,
                })
            end
        elseif profile.side == CnR.Sides.ROBBER and profile.wanted then
            -- Returning robber who left wanted comes back wanted (red name + map blip).
            -- Skipped if they're serving jail (handled above, where wanted is cleared). #1
            if CnR.Crime and CnR.Crime.SetWanted then CnR.Crime.SetWanted(src, true) end
        end

        if CnR.PushProfile then CnR.PushProfile(src) end
        CnR.Util.log('info', 'restored player src=%s side=%s rank=%s', tostring(src), tostring(profile.side), tostring(profile.rankId))
        return
    end

    local copSkins = {
        'mp_m_freemode_01',
        'mp_f_freemode_01',
    }
    local robberSkins = {

        'a_m_y_business_03', 'a_m_y_business_01', 'a_m_y_business_02',
        'a_m_y_hipster_01',  'a_m_y_hipster_02',  'a_m_y_hipster_03',
        'a_m_m_eastsa_01',   'a_m_m_eastsa_02',
        'a_f_y_business_02', 'a_f_y_business_03', 'a_f_y_business_04',
        'a_f_y_hipster_01',  'a_f_y_hipster_02',  'a_f_y_hipster_03',
        'a_m_y_skater_01',   'a_m_y_skater_02',
        'a_m_y_genstreet_01','a_m_y_stbla_01',    'a_m_y_stwhi_01',
        'a_m_y_stlat_01',    'a_m_y_yoga_01',
        'a_f_y_genhot_01',   'a_f_y_eastsa_01',
        'a_f_y_clubcust_01', 'a_f_y_clubcust_02',
        'a_m_y_clubcust_01', 'a_m_y_clubcust_02',
        'a_m_y_beach_01',    'a_m_y_beach_03',
        'a_m_y_downtown_01',
    }
    TriggerClientEvent('cnr:client:openTeamSelect', src, {
        skinsByTeam = { cop = copSkins, robber = robberSkins },
        profileSkin = profile and profile.skin and CnR.Util.NormalizeCopSkin(profile.skin) or false,
    })
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    CnR.Persistence.Load()
    CnR.Util.log('info', 'cnr resource started')
end)

-- Declared here so the stop/drop handlers and the reportPosition handler can reference it.
local _playerPositions = {}

-- Write a player's most recent (1s-fresh) position into their profile as lastPos, so a
-- reconnect — especially after a server restart — resumes exactly where they were instead of
-- at the default spawn. Heading carries over from the 30s position sync. Jailed players are
-- skipped (they resume at jail), and only sided players have a meaningful position to save.
local function persistLastPos(src)
    if CnR.GetSide and CnR.GetSide(src) == CnR.Sides.NONE then return end
    local id = CnR.GetIdentifier(src); if not id then return end
    local pos = _playerPositions[src]; if not pos then return end
    local p = CnR.Persistence.GetProfile(id)
    if (p.jailSecondsRemaining or 0) > 0 then
        -- Serving time on disconnect → save the jail position (not lastPos) so the next login
        -- drops them back in the SAME jail at the SAME spot. #jail-resume
        p.jailPos = { x = pos.x, y = pos.y, z = pos.z, h = (p.jailPos and p.jailPos.h) or 0.0 }
        CnR.Persistence.SaveProfile(id, p)
        return
    end
    p.lastPos = { x = pos.x, y = pos.y, z = pos.z, h = (p.lastPos and p.lastPos.h) or 0.0 }
    CnR.Persistence.SaveProfile(id, p)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, sid in ipairs(GetPlayers()) do persistLastPos(tonumber(sid)) end
    CnR.Persistence.Flush()
end)

AddEventHandler('playerDropped', function(_reason)
    local src = source
    persistLastPos(src)
    local id = CnR.GetIdentifier(src)
    if id then
        local p = CnR.Persistence.GetProfile(id)
        CnR.Persistence.SaveProfile(id, p)
        CnR.Persistence.Flush()
    end
    CnR.State.sides[src] = nil
    _playerPositions[src] = nil
    TriggerEvent('cnr_doorlock:setPlayerSide', src, 'none')
    TriggerClientEvent('cnr_doorlock:setLocalSide', src, 'none')
end)

CreateThread(function()
    local interval = (Config and Config.Save and Config.Save.intervalSec) or 60
    while true do
        Wait(interval * 1000)
        CnR.Persistence.Flush()
    end
end)

-- Players self-report position every 1s. Server can't read GetEntityCoords for
-- out-of-streaming-range peds, so this is the only reliable position source.
RegisterNetEvent('cnr:server:reportPosition', function(pos)
    local src = source
    if type(pos) == 'table' and tonumber(pos.x) then
        _playerPositions[src] = { x = pos.x + 0.0, y = pos.y + 0.0, z = pos.z + 0.0 }
    end
end)

-- Build and broadcast the map-blip list every 2s. Includes EVERY cop and every
-- wanted robber with their last-reported position. The client builds coord blips
-- from this list (not from GetActivePlayers, which is limited to streamed players),
-- so blips are visible everywhere on the big map.
CreateThread(function()
    while true do
        Wait(2000)
        local out = {}
        for _, sidStr in ipairs(GetPlayers()) do
            local src = tonumber(sidStr)
            local pos = _playerPositions[src]
            local pl = Player(src)
            local jailed = pl and pl.state and pl.state.cnrJailed
            if pos and not jailed then                       -- jailed prisoners are hidden on the map #10
                local side = CnR.GetSide(src)
                local wanted = CnR.Crime and CnR.Crime.IsWanted(src)
                if side == CnR.Sides.COP then
                    out[tostring(src)] = { x = pos.x, y = pos.y, z = pos.z, side = 'cop', name = GetPlayerName(src) }
                elseif side == CnR.Sides.ROBBER and wanted then
                    out[tostring(src)] = { x = pos.x, y = pos.y, z = pos.z, side = 'robber', name = GetPlayerName(src) }
                end
            end
        end
        TriggerClientEvent('cnr:client:mapBlips', -1, out)
    end
end)

-- Player carjack: the attacker (who is playing the jack animation client-side) asks us to
-- evict the player they're jacking — you can't pull another player's ped out from a client.
-- We just validate proximity and tell the victim's client to bail out of the seat. #3
RegisterNetEvent('cnr:server:evictDriver', function(data)
    local src = source
    if type(data) ~= 'table' then return end
    local victim = tonumber(data.victim)
    if not victim or victim == src then return end
    local sp, vp = GetPlayerPed(src), GetPlayerPed(victim)
    if sp == 0 or vp == 0 then return end
    if #(GetEntityCoords(sp) - GetEntityCoords(vp)) > 8.0 then return end
    TriggerClientEvent('cnr:client:forceExitVehicle', victim)
end)