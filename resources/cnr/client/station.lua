CnR = CnR or {}

local INTERACT_DIST = 3.5
local SCAN_INTERVAL = 500

local function helpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function pointsFromPeds(map)
    local out = {}
    if not map then return out end
    for key, n in pairs(map) do
        out[#out + 1] = { name = key, pos = vector3(n.x, n.y, n.z) }
    end
    return out
end

local function lockerPoints()
    local out = {}
    if not (Config and Config.PoliceStations) then return out end
    for key, st in pairs(Config.PoliceStations) do
        if st.weaponLocker and st.weaponLocker.pos then
            out[#out + 1] = {
                name   = key,
                pos    = st.weaponLocker.pos,
                radius = st.weaponLocker.radius or INTERACT_DIST,
            }
        end
    end
    return out
end

local function rankTerminalPoints()
    local out = {}
    if not (Config and Config.PoliceStations) then return out end
    for key, st in pairs(Config.PoliceStations) do
        if st.rankTerminal and st.rankTerminal.pos then
            out[#out + 1] = {
                name = key,
                pos = st.rankTerminal.pos,
                radius = st.rankTerminal.radius or INTERACT_DIST,
            }
        elseif CnR.Peds and CnR.Peds.deskNPCs and CnR.Peds.deskNPCs[key] then
            local n = CnR.Peds.deskNPCs[key]
            out[#out + 1] = {
                name = key,
                pos = vector3(n.x, n.y, n.z),
                radius = INTERACT_DIST,
            }
        end
        if st.extraDeskNpcs then
            for _, npc in ipairs(st.extraDeskNpcs) do
                if npc.pos then
                    out[#out + 1] = { name = key, pos = vector3(npc.pos.x, npc.pos.y, npc.pos.z), radius = INTERACT_DIST }
                end
            end
        end
    end
    return out
end

-- Floating labels above each cop-service NPC's head so players know what each one offers.
local function serviceLabelPoints()
    local out = {}
    for _, n in pairs(CnR.Peds.deskNPCs or {}) do
        out[#out + 1] = { pos = vector3(n.x, n.y, n.z), label = 'Information' }
    end
    if Config and Config.PoliceStations then
        for _, st in pairs(Config.PoliceStations) do
            if st.extraDeskNpcs then
                for _, npc in ipairs(st.extraDeskNpcs) do
                    if npc.pos then out[#out + 1] = { pos = vector3(npc.pos.x, npc.pos.y, npc.pos.z), label = 'Information' } end
                end
            end
        end
    end
    for _, n in pairs(CnR.Peds.armoryNPCs or {}) do
        out[#out + 1] = { pos = vector3(n.x, n.y, n.z), label = 'Ammunition' }
    end
    for _, n in pairs(CnR.Peds.garageNPCs or {}) do
        out[#out + 1] = { pos = vector3(n.x, n.y, n.z), label = 'Vehicle Yard' }
    end
    for _, h in ipairs(CnR.Peds.heliNpcs or {}) do
        out[#out + 1] = { pos = h.pos, label = 'Air Support' }
    end
    return out
end

CreateThread(function()
    while not (CnR.Peds and CnR.Peds.deskNPCs and CnR.Peds.garageNPCs) do Wait(500) end
    Wait(3500)   -- let the peds finish spawning
    local labels = serviceLabelPoints()
    local lastBuild = GetGameTimer()
    while true do
        local sleep = 600
        if #labels == 0 or (GetGameTimer() - lastBuild) > 20000 then
            labels = serviceLabelPoints(); lastBuild = GetGameTimer()
        end
        local pos = GetEntityCoords(PlayerPedId())
        for _, t in ipairs(labels) do
            if #(pos - t.pos) <= 18.0 then
                sleep = 0
                local on, sx, sy = World3dToScreen2d(t.pos.x, t.pos.y, t.pos.z + 1.05)
                if on then
                    SetTextFont(4)
                    SetTextScale(0.34, 0.34)
                    SetTextColour(255, 255, 255, 220)
                    SetTextCentre(true)
                    SetTextOutline()
                    BeginTextCommandDisplayText('STRING')
                    AddTextComponentSubstringPlayerName(t.label)
                    EndTextCommandDisplayText(sx, sy)
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while not (CnR.Peds and CnR.Peds.deskNPCs and CnR.Peds.garageNPCs) do
        Wait(500)
    end

    while true do
        local sleep = SCAN_INTERVAL
        if CnR.State and CnR.State.side == CnR.Sides.COP then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local nearDesk, nearLocker, nearArmory, nearYard, nearHeli = nil, nil, nil, nil, nil

            for _, t in ipairs(rankTerminalPoints()) do
                if #(pos - t.pos) <= (t.radius or INTERACT_DIST) then nearDesk = t; break end
            end
            if not nearDesk then
                for _, t in ipairs(lockerPoints()) do
                    if #(pos - t.pos) <= t.radius then nearLocker = t; break end
                end
            end
            if not nearDesk and not nearLocker then
                for _, t in ipairs(pointsFromPeds(CnR.Peds.armoryNPCs)) do
                    if #(pos - t.pos) <= INTERACT_DIST then nearArmory = t; break end
                end
            end
            if not nearDesk and not nearLocker and not nearArmory then
                for _, y in ipairs(pointsFromPeds(CnR.Peds.garageNPCs)) do
                    if #(pos - y.pos) <= INTERACT_DIST then nearYard = y; break end
                end
            end
            if not nearDesk and not nearLocker and not nearArmory and not nearYard then
                for _, h in ipairs(CnR.Peds.heliNpcs or {}) do
                    if #(pos - h.pos) <= INTERACT_DIST then nearHeli = h; break end
                end
            end

            -- Shared flag so the cuff key (also E) doesn't post "no robber nearby" at counters.
            if CnR.State then CnR.State.nearCopInteract = (nearDesk or nearLocker or nearArmory or nearYard or nearHeli) and true or false end

            if nearDesk or nearLocker or nearArmory or nearYard or nearHeli then
                sleep = 0
                if nearDesk then
                    helpText('Press ~INPUT_CONTEXT~ to set your spawn station')
                elseif nearLocker or nearArmory then
                    helpText('Press ~INPUT_CONTEXT~ to open the weapon locker')
                elseif nearYard then
                    helpText('Press ~INPUT_CONTEXT~ to open the vehicle yard')
                elseif nearHeli then
                    helpText('Press ~INPUT_CONTEXT~ to request a police helicopter')
                end
                local pressed = CnR.KeysPressed and CnR.KeysPressed.interact
                local nativeE = IsControlJustReleased(0, 38)
                if (pressed and (GetGameTimer() - pressed) < 300) or nativeE then
                    if CnR.KeysPressed then CnR.KeysPressed.interact = nil end
                    if nearDesk then
                        TriggerServerEvent('cnr:server:requestClothingList')
                    elseif nearLocker or nearArmory then
                        TriggerServerEvent('cnr:server:requestArmory')
                    elseif nearHeli then
                        -- Preview camera + spawn use THIS station's helipad.
                        if CnR.State then CnR.State.yardStation = nearHeli.key end
                        TriggerServerEvent('cnr:server:requestHeliList')
                    else
                        -- Remember which station's garage this is so the preview
                        -- camera and the spawn use that station, not the spawn one.
                        if CnR.State then CnR.State.yardStation = nearYard.name end
                        TriggerServerEvent('cnr:server:requestVehicleList')
                    end
                end
            end
        elseif CnR.State and CnR.State.side == CnR.Sides.ROBBER then
            -- Robbers can use the front desk to TURN THEMSELVES IN (serve their time).
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local nearDesk = nil
            for _, t in ipairs(rankTerminalPoints()) do
                if #(pos - t.pos) <= (t.radius or INTERACT_DIST) then nearDesk = t; break end
            end
            if nearDesk then
                sleep = 0
                helpText('Press ~INPUT_CONTEXT~ to turn yourself in')
                local pressed = CnR.KeysPressed and CnR.KeysPressed.interact
                local nativeE = IsControlJustReleased(0, 38)
                if (pressed and (GetGameTimer() - pressed) < 300) or nativeE then
                    if CnR.KeysPressed then CnR.KeysPressed.interact = nil end
                    TriggerServerEvent('cnr:server:turnSelfIn', { station = nearDesk.name })
                end
            end
        end
        Wait(sleep)
    end
end)
