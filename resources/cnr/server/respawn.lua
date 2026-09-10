CnR = CnR or {}

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

local function nearestPoliceStation(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return 'missionRow' end
    local pos = GetEntityCoords(ped)
    local nearest = 'missionRow'
    local nearestDist = math.huge
    for key, st in pairs(Config and Config.PoliceStations or {}) do
        local s = st.spawn
        -- Some stations (e.g. vespucci) define spawn as an array of vec4s; extract first.
        if type(s) == 'table' and not s.x then s = s[1] end
        if s then
            local dx = pos.x - s.x
            local dy = pos.y - s.y
            local d = dx * dx + dy * dy
            if d < nearestDist then
                nearestDist = d
                nearest = key
            end
        end
    end
    return nearest
end

-- Picks one entry from a spawn table (or passes through a single vec4).
local function pickSpawn(s)
    if type(s) == 'table' and s[1] and not s.x then
        s = s[math.random(#s)]
    end
    return s
end

local function copStationSpawn(station)
    local stations = Config and Config.PoliceStations or {}
    if station and stations[station] and stations[station].spawn then
        return pickSpawn(stations[station].spawn)   -- returns vec4, w = heading
    end
    local cops = Config and Config.Spawns and Config.Spawns.cops or {}
    return cops[station] or cops.missionRow
end

-- Returns the jail cell (or prison) spawn that matches the sentence length and station.
-- Mirrors the facility logic in server/jail.lua so the revive lands at the right cell.
local function pickJailReviveSpawn(totalSecs, station)
    local threshold = (Config and Config.JailTime and Config.JailTime.lowJailThreshold) or 120
    if (tonumber(totalSecs) or 0) > threshold then
        return Config and Config.Jail and Config.Jail.bolingbroke
    end
    if station == 'vespucci' then
        local cells = Config and Config.Jail and Config.Jail.vespucciCells
        if type(cells) == 'table' and cells[1] then
            return cells[math.random(#cells)]
        end
    end
    local cells = Config and Config.Jail and Config.Jail.missionRowCells
    if type(cells) == 'table' and cells[1] then
        return cells[math.random(#cells)]
    end
    return Config and Config.Jail and Config.Jail.bolingbroke
end

RegisterNetEvent('cnr:server:reportDeath', function()
    local src = source
    -- Already a PRISONER (serving): don't respawn/re-jail them here. The client jail loop
    -- revives them at the SAME station's cell. Re-rolling a random station only applies to a
    -- WANTED robber who dies free — never to someone already serving their sentence. #1
    local pl = Player(src)
    if pl and pl.state and pl.state.cnrJailed then return end

    local id = CnR.GetIdentifier(src)
    if not id then return end
    local profile = CnR.Persistence.GetProfile(id)

    local spawn = nil

    if profile.side == CnR.Sides.COP then
        spawn = copStationSpawn(profile.station or 'missionRow')
    else
        local wanted = (CnR.Crime and CnR.Crime.IsWanted and CnR.Crime.IsWanted(src)) or false
        local debt = profile.jailDebtSeconds or 0
        local sentence = profile.jailSecondsRemaining or 0

        if wanted or debt > 0 or sentence > 0 then
            -- Revive the player directly at the jail cell so there is no flash at a
            -- random spawn location before goToJail teleports them.
            -- A wanted robber who DIES goes to a RANDOM holding cell (arrests and
            -- self-surrenders pick a specific station; only death is random). The same
            -- station drives both the revive spot and the jail so they match.
            local station = (Config and Config.Jail and Config.Jail.vespucciCells and Config.Jail.vespucciCells[1]
                             and math.random(2) == 1) and 'vespucci' or 'missionRow'
            local totalSecs = debt + sentence
            spawn = pickJailReviveSpawn(totalSecs, station)
                 or (Config and Config.Jail and Config.Jail.bolingbroke)

            TriggerClientEvent('cnr:client:revive', src, {
                x       = spawn and spawn.x or 0.0,
                y       = spawn and spawn.y or 0.0,
                z       = spawn and spawn.z or 0.0,
                heading = spawn and (spawn.w or spawn.h or 0.0) or 0.0,
            })

            if CnR.Jail and CnR.Jail.SendToJail then
                CnR.Jail.SendToJail(src, station)
            else
                TriggerClientEvent('cnr:client:goToJail', src, { seconds = sentence })
            end
            if CnR.Crime and CnR.Crime.SetWanted then
                CnR.Crime.SetWanted(src, false)
            end
            TriggerClientEvent('cnr:client:respawnAck', src)
            if CnR.PushProfile then CnR.PushProfile(src) end
            return
        end

        spawn = pickRobberSpawn() or (Config and Config.Jail and Config.Jail.bolingbrokeRelease)
    end

    -- Use named-field access only: integer indexing ([1] etc.) crashes on vector types.
    -- For vec3, .w is nil so heading falls back to 0.
    TriggerClientEvent('cnr:client:revive', src, {
        x       = spawn and spawn.x or 0.0,
        y       = spawn and spawn.y or 0.0,
        z       = spawn and spawn.z or 0.0,
        heading = spawn and (spawn.w or (type(spawn) == 'table' and (spawn.h or spawn[4])) or 0.0) or 0.0,
    })

    if profile.side == CnR.Sides.COP then
        if CnR.Ranks and CnR.Ranks.ApplyRank then
            -- useSaved=false so ApplyRank uses spawnFor() (their chosen station),
            -- not profile.lastPos which would respawn them at their death location.
            CnR.Ranks.ApplyRank(src, profile.rankId or 1, profile.skin, false)
        end
    elseif profile.side == CnR.Sides.ROBBER then
        TriggerClientEvent('cnr:client:applyLoadout', src, {
            side    = 'robber',
            weapons = { 'WEAPON_PISTOL' },
            ammo    = { WEAPON_PISTOL = 100 },
            armor   = nil,
            skin    = profile.skin,
            spawn   = spawn,
        })
    end

    TriggerClientEvent('cnr:client:respawnAck', src)
    if CnR.PushProfile then CnR.PushProfile(src) end
end)
