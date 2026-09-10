CnR = CnR or {}
CnR.State = CnR.State or {}
CnR.State.names = CnR.State.names or {}            -- server id -> resolved display name
CnR.State.steamNames = CnR.State.steamNames or {}  -- steamid64 -> Steam persona name

-- ─────────────────────────────────────────────
-- Safe name resolver (NEVER returns nil/empty)
-- ─────────────────────────────────────────────
-- A name is only "real" if it has a visible character. These clients report a name made
-- purely of whitespace (confirmed: two TAB bytes, "\t\t") or FiveM colour codes (^0-^9),
-- which render blank in chat / the feed. Strip those and treat what's left as the test for
-- validity — if nothing remains, we look the Steam persona name up instead. #name
local function usableName(name)
    if type(name) ~= 'string' or name == '' then return nil end
    local stripped = name:gsub('%^%d', ''):gsub('%s+', '')
    if stripped == '' then return nil end
    return name
end
CnR.UsableName = usableName

-- The player's SteamID64 (decimal string) from their steam: identifier, or nil if none.
local function steamIdOf(src)
    for _, ident in ipairs(GetPlayerIdentifiers(src)) do
        local hex = ident:match('^steam:(%x+)$')
        if hex then return tostring(tonumber(hex, 16)) end
    end
    return nil
end

-- FiveM reports these clients' names as blank whitespace, but their steam: identifier
-- resolves fine — so we look the REAL persona name up ourselves via the Steam Web API and
-- cache it by SteamID. Needs steam_webApiKey in server.cfg (the same key that resolves the
-- steam: identifier). Async, so it warms the cache for the next lookup. #name
local function fetchSteamName(steamid)
    -- nil = never fetched; false = in flight; string = resolved. Skip the last two.
    if not steamid or CnR.State.steamNames[steamid] ~= nil then return end
    local key = GetConvar('steam_webApiKey', '')
    if key == '' or key == 'none' then return end
    CnR.State.steamNames[steamid] = false   -- in-flight marker: don't fire duplicate requests
    local url = ('https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s')
        :format(key, steamid)
    PerformHttpRequest(url, function(status, body)
        if status ~= 200 or type(body) ~= 'string' then
            CnR.State.steamNames[steamid] = nil   -- allow a retry later
            return
        end
        local ok, data = pcall(json.decode, body)
        local players = ok and type(data) == 'table' and data.response and data.response.players
        local persona = players and players[1] and players[1].personaname
        if type(persona) == 'string' and persona ~= '' then
            CnR.State.steamNames[steamid] = persona
        else
            CnR.State.steamNames[steamid] = nil
        end
    end, 'GET', '', { ['User-Agent'] = 'cnr' })
end
CnR.FetchSteamName = function(src) fetchSteamName(steamIdOf(src)) end

function CnR.GetName(src)
    local cached = CnR.State.names[src]
    if cached and cached ~= '' then
        return cached
    end

    -- 1) A real client-provided name, if the client actually sent one.
    local name = usableName(GetPlayerName(src))
    if name then
        CnR.State.names[src] = name
        return name
    end

    -- 2) The Steam persona name we fetched from the Web API (blank clients land here).
    local steamid = steamIdOf(src)
    if steamid then
        local persona = CnR.State.steamNames[steamid]
        if persona and persona ~= '' then   -- `false` = fetch in flight, skip
            CnR.State.names[src] = persona
            return persona
        end
        fetchSteamName(steamid)   -- kick one off so it's ready next time
    end

    -- 3) Last resort — readable and stable for this session.
    return ('Player %d'):format(src)
end

-- ─────────────────────────────────────────────
-- Cache lifecycle (fixes join timing issues)
-- ─────────────────────────────────────────────
-- The name is passed as the first arg here and is 100% reliable — unlike GetPlayerName(),
-- which returns "" (empty, NOT nil) for the first moments after connect. playerConnecting
-- always fires before playerJoining, so this warms the cache before any join broadcast or
-- chat message needs it. #name
AddEventHandler('playerConnecting', function(name)
    local src = source
    local usable = usableName(name)
    if usable then
        CnR.State.names[src] = usable
    else
        -- Blank client name — warm the Steam persona cache now, during the load screen, so
        -- it's ready by the time the join line / first chat message needs it.
        fetchSteamName(steamIdOf(src))
    end
end)

AddEventHandler('playerJoining', function()
    local src = source

    -- Re-resolve once the player has a real server id (fallback if the connect-time fetch
    -- hadn't finished yet). Small delay avoids the early empty GetPlayerName().
    SetTimeout(500, function()
        local usable = usableName(GetPlayerName(src))
        if usable then
            CnR.State.names[src] = usable
        else
            fetchSteamName(steamIdOf(src))
        end
    end)
end)

AddEventHandler('playerDropped', function()
    CnR.State.names[source] = nil
end)

-- ─────────────────────────────────────────────
-- Player list request
-- ─────────────────────────────────────────────
RegisterNetEvent('cnr:server:requestPlayerList', function()
    local src = source
    local players = {}

    for _, id in ipairs(GetPlayers()) do
        local sid = tonumber(id)

        -- resolve side safely
        local side = CnR.GetSide and CnR.GetSide(sid) or CnR.Sides.NONE

        if side == CnR.Sides.NONE then
            local ident = CnR.GetIdentifier and CnR.GetIdentifier(sid) or nil
            local profile = ident and CnR.Persistence and CnR.Persistence.GetProfile(ident) or nil
            side = (profile and profile.side) or CnR.Sides.NONE
        end

        players[#players + 1] = {
            id   = sid,
            name = CnR.GetName(sid),
            role = side or 'none',
        }
    end

    table.sort(players, function(a, b)
        return (a.id or 0) < (b.id or 0)
    end)

    TriggerClientEvent('cnr:client:openPlayerList', src, {
        players = players
    })
end)