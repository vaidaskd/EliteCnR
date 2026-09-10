CnR = CnR or {}
CnR.Jail = CnR.Jail or {}

local jailed = {}

local DEFAULT_CIV_SKINS = {
    'a_m_y_business_03', 'a_m_y_hipster_01', 'a_m_m_eastsa_01',
    'a_f_y_business_02', 'a_f_y_hipster_02', 'a_m_y_skater_01',
    'a_m_y_genstreet_01', 'a_m_y_stbla_01',
}

local function pushUpdate(src, seconds)
    TriggerClientEvent('cnr:client:jailTimeUpdate', src, { seconds = math.max(0, math.floor(seconds + 0.5)) })
end

--- Choose the holding facility.
--- Long sentences go to Bolingbroke. Short sentences (≤ threshold) go to one of the
--- two PD holding cells chosen at RANDOM (50/50), not the nearest station.
local function facilityForSentence(seconds, station)
    local threshold = (Config and Config.JailTime and Config.JailTime.lowJailThreshold) or 120
    if (tonumber(seconds) or 0) > threshold then return 'bolingbroke' end
    -- Explicit station (e.g. the PD desk where a robber surrendered) is honoured.
    if station == 'vespucci' or station == 'missionRow' then return station end
    -- No station given (arrests): pick a holding cell at random.
    local hasVespucci = Config and Config.Jail and Config.Jail.vespucciCells and Config.Jail.vespucciCells[1]
    if hasVespucci and math.random(2) == 1 then
        return 'vespucci'
    end
    return 'missionRow'
end

local function onJailRelease(src, profile, facility)
    profile.cash = 0
    profile.jailSecondsRemaining = 0   -- ALWAYS clear the sentence on release, so a player
    profile.jailDebtSeconds = 0        -- can never leave jail still carrying time. (new)
    profile.jailFacility = nil         -- forget the facility once the sentence is done #1
    profile.jailPos = nil              -- and the saved jail position — they're free now #jail-resume
    CnR.Persistence.SaveProfile(CnR.GetIdentifier(src), profile)

    local pl = Player(src)                                  -- clear prisoner status #10
    if pl and pl.state then pl.state:set('cnrJailed', false, true) end

    local skin = profile.skin
    if not skin or skin == '' then
        skin = DEFAULT_CIV_SKINS[math.random(#DEFAULT_CIV_SKINS)]
    end

    TriggerClientEvent('cnr:client:notify', src, {
        kind = 'info',
        text = 'Your sentence is complete — you are free to go.',
    })

    local releaseSpawn = Config.Jail.bolingbrokeRelease
    if facility == 'missionRow' then
        local rel = Config.Jail.missionRowRelease
        if rel then releaseSpawn = vec3(rel.x, rel.y, rel.z) end
    elseif facility == 'vespucci' then
        local rel = Config.Jail.vespucciRelease
        if rel then releaseSpawn = vec3(rel.x, rel.y, rel.z) end
    end

    TriggerClientEvent('cnr:client:applyLoadout', src, {
        side    = 'robber',
        weapons = { 'WEAPON_PISTOL' },
        ammo    = { WEAPON_PISTOL = 100 },
        armor   = nil,
        skin    = skin,
        spawn   = releaseSpawn,
    })

    pcall(function()
        if CnR.Crime and CnR.Crime.SetWanted then
            CnR.Crime.SetWanted(src, false)
        end
    end)

    if CnR.PushProfile then CnR.PushProfile(src) end
end

--- station: 'missionRow' | 'vespucci' | nil  (determines holding facility for short sentences)
--- resumePos: optional {x,y,z,h} — reconnect only, to drop the player back at their exact
--- pre-disconnect spot instead of a fresh cell. Fresh jailings pass nil. #jail-resume
function CnR.Jail.SendToJail(src, station, resumePos)
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    local debt = p.jailDebtSeconds or 0
    local sentence = p.jailSecondsRemaining or 0
    local total = sentence + debt
    if total <= 0 then return end

    -- On a RECONNECT (resumePos is passed) honour the facility they were already serving in —
    -- never recompute it from the remaining time. Otherwise a Bolingbroke inmate whose time
    -- dropped below the threshold got bounced to a Mission Row cell on reconnect. Fresh
    -- jailings (no resumePos) pick the facility normally. #jail-resume
    local facility = (resumePos and p.jailFacility) or facilityForSentence(total, station)
    p.jailDebtSeconds = 0
    p.jailSecondsRemaining = total
    p.cash = 0   -- cash is confiscated on the way in; you serve the time broke
    p.jailFacility = facility   -- remember WHERE, so a reconnect resumes in the SAME place #1
    CnR.Persistence.SaveProfile(id, p)
    jailed[src] = facility
    local pl = Player(src)                                  -- prisoner status: orange name, hidden blip #10
    if pl and pl.state then pl.state:set('cnrJailed', true, true) end
    TriggerClientEvent('cnr:client:goToJail', src, { seconds = total, facility = facility, resume = resumePos })
    if CnR.PushProfile then CnR.PushProfile(src) end
end

function CnR.Jail.IsJailed(src)
    return jailed[src] ~= nil
end

-- Robber uses the station front desk to surrender. Serves their jail debt (+ any
-- remaining sentence) per the normal jail rules; if they have nothing owed, they're innocent.
RegisterNetEvent('cnr:server:turnSelfIn', function(payload)
    local src = source
    if CnR.GetSide and CnR.GetSide(src) ~= CnR.Sides.ROBBER then return end
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    local total = (p.jailDebtSeconds or 0) + (p.jailSecondsRemaining or 0)
    if total <= 0 then
        TriggerClientEvent('cnr:client:notify', src, {
            kind = 'info', text = 'You are innocent — nothing to turn yourself in for.',
        })
        return
    end
    -- Surrender at the desk's own station: Vespucci desk → Vespucci jail, Mission Row desk →
    -- Mission Row jail (unless the sentence is long, in which case it's Bolingbroke).
    local station = type(payload) == 'table' and payload.station or nil
    if station ~= 'missionRow' and station ~= 'vespucci' then station = nil end
    if CnR.Crime and CnR.Crime.SetWanted then CnR.Crime.SetWanted(src, false) end
    CnR.Jail.SendToJail(src, station)
end)

function CnR.Jail.Release(src)
    local id = CnR.GetIdentifier(src); if not id then return false, 'no identifier' end
    local p = CnR.Persistence.GetProfile(id)
    local facility = jailed[src] or facilityForSentence(p.jailSecondsRemaining or p.jailDebtSeconds or 0, nil)

    p.jailDebtSeconds = 0
    p.jailSecondsRemaining = 0
    CnR.Persistence.SaveProfile(id, p)
    jailed[src] = nil
    pushUpdate(src, 0)
    onJailRelease(src, p, facility)
    return true
end

local function maybeReJail(src)
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    if (p.jailSecondsRemaining or 0) > 0 then
        -- Resume in the SAME facility they were serving in — NOT a freshly recomputed one. The
        -- old code re-ran facilityForSentence, so a Bolingbroke prisoner with <3 min left got
        -- bounced to a random PD cell on reconnect. Honour the saved facility. #1
        local facility = p.jailFacility or facilityForSentence(p.jailSecondsRemaining, nil)
        jailed[src] = facility
        local pl = Player(src)
        if pl and pl.state then pl.state:set('cnrJailed', true, true) end
        -- Resume at the exact spot they were serving in when they disconnected. #jail-resume
        TriggerClientEvent('cnr:client:goToJail', src, { seconds = p.jailSecondsRemaining, facility = facility, resume = p.jailPos })
        if CnR.PushProfile then CnR.PushProfile(src) end
    end
end

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(2000, function() maybeReJail(src) end)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end

    for _, src in ipairs(GetPlayers()) do
        maybeReJail(tonumber(src))
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    jailed[src] = nil
end)

CreateThread(function()
    local tick = 0
    while true do
        Wait(1000)
        tick = tick + 1
        for src in pairs(jailed) do
            local id = CnR.GetIdentifier(src)
            if id then
                local p = CnR.Persistence.GetProfile(id)
                local remaining = (p.jailSecondsRemaining or 0) - 1
                if remaining <= 0 then
                    p.jailSecondsRemaining = 0
                    CnR.Persistence.SaveProfile(id, p)
                    local facility = jailed[src] or 'bolingbroke'
                    jailed[src] = nil
                    pushUpdate(src, 0)
                    onJailRelease(src, p, facility)
                else
                    p.jailSecondsRemaining = remaining
                    CnR.Persistence.SaveProfile(id, p)
                    pushUpdate(src, remaining)
                    if (tick % 5) == 0 and CnR.PushProfile then
                        CnR.PushProfile(src)
                    end
                end
            else
                jailed[src] = nil
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        CnR.Persistence.Flush()
    end
end)

AddEventHandler('cnr:server:_internalJailMark', function(target)
    if target then jailed[target] = 'bolingbroke' end
end)
