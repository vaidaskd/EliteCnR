CnR = CnR or {}
CnR.Markers = CnR.Markers or {}

-- ============================================================================
--  MAP BLIPS — fully server-driven.
--  GetActivePlayers() only returns players streamed within ~250 m, so it can
--  NEVER show distant players. Instead the server sends every cop / wanted
--  robber's position+side and we build coord blips from that list. This makes
--  blips visible everywhere on the big map regardless of streaming distance.
-- ============================================================================

local blips = {}   -- [sid] = blip handle

-- Static POI: the YouTool hardware store (Senora Freeway, Grand Senora Desert — the
-- youtool_interior MLO). Sprite 402 = radar_repair (wrench / tool icon).
CreateThread(function()
    local b = AddBlipForCoord(2748.4, 3473.6, 55.7)
    SetBlipSprite(b, 402)
    SetBlipColour(b, 5)            -- yellow
    SetBlipScale(b, 0.9)
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('YouTool Hardware Store')
    EndTextCommandSetBlipName(b)
end)

-- Blips use a fixed palette (no free RGB). Palette 29 is a solid blue (the same blue the
-- PD station blips use) — not the cyan/light blue of palette 3. Nickname stays #1d6fff.
local COLOR_COP    = 29  -- solid blue (not cyan)
local COLOR_WANTED = 1   -- red ≈ rgb(224,50,50)

-- Report our own position to the server every second (server can't read
-- GetEntityCoords for out-of-range peds, so each client self-reports).
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if ped ~= 0 then
            local c = GetEntityCoords(ped)
            TriggerServerEvent('cnr:server:reportPosition', { x = c.x, y = c.y, z = c.z })
        end
    end
end)

local function removeBlip(sid)
    local h = blips[sid]
    if h and DoesBlipExist(h) then RemoveBlip(h) end
    blips[sid] = nil
end

-- Server pushes the full blip list. We create / move / colour / prune from it.
RegisterNetEvent('cnr:client:mapBlips', function(list)
    if type(list) ~= 'table' then return end
    local mySid = GetPlayerServerId(PlayerId())
    local seen = {}

    for sidKey, info in pairs(list) do
        local sid = tonumber(sidKey)
        if sid and sid ~= mySid and info and info.x then
            seen[sid] = true
            local color = (info.side == 'cop') and COLOR_COP or COLOR_WANTED
            local label = (info.name or 'Player') .. (info.side == 'cop' and ' [COP]' or ' [WANTED]')

            local h = blips[sid]
            if not h or not DoesBlipExist(h) then
                h = AddBlipForCoord(info.x + 0.0, info.y + 0.0, info.z + 0.0)
                SetBlipSprite(h, 1)
                SetBlipScale(h, 0.9)
                blips[sid] = h
            else
                SetBlipCoords(h, info.x + 0.0, info.y + 0.0, info.z + 0.0)
            end
            SetBlipColour(h, color)
            SetBlipAsShortRange(h, false)   -- false = long range = always on the big map
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(label)
            EndTextCommandSetBlipName(h)
        end
    end

    for sid in pairs(blips) do
        if not seen[sid] then removeBlip(sid) end
    end
end)

-- ============================================================================
--  NAMETAGS — custom RGB draw above nearby players.
--  We hide the playernames white default tag and render our own coloured one
--  so the colour is exact (cop = blue, wanted = red) and not a guessed
--  HUD-palette index.
-- ============================================================================

-- Draw our own colour-coded nametag above players. The native white GAMER_NAME is
-- permanently hidden in playernames_cl.lua (it never sets that component visible), so
-- there is no white-tag flicker to fight here anymore — we just draw our coloured one.
CreateThread(function()
    while true do
        Wait(0)
        local myPed = PlayerPedId()
        local myPos = myPed ~= 0 and GetEntityCoords(myPed) or nil
        for _, plId in ipairs(GetActivePlayers()) do
            if plId ~= PlayerId() then
                -- Draw our own coloured tag (cop = blue, wanted = red, else white).
                if myPos then
                    local ped = GetPlayerPed(plId)
                    if ped ~= 0 then
                        local pedPos = GetEntityCoords(ped)
                        if (pedPos.x ~= 0 or pedPos.y ~= 0) then
                            local dist = #(myPos - pedPos)
                            if dist <= 120.0 then
                                local r, g, b = 255, 255, 255
                                local pst = Player(GetPlayerServerId(plId))
                                if pst and pst.state then
                                    if pst.state.cnrJailed then
                                        r, g, b = 255, 140, 0     -- prisoner = orange (during sentence) #10
                                    elseif pst.state.cnrSide == 'cop' then
                                        r, g, b = 29, 111, 255    -- cop colour #1d6fff
                                    elseif pst.state.cnrSide == 'robber' and pst.state.cnrWanted then
                                        r, g, b = 224, 50, 50     -- matches wanted blip (palette 1)
                                    end
                                end

                                local np = pedPos + vector3(0.0, 0.0, 1.0)
                                local onScreen, sx, sy = World3dToScreen2d(np.x, np.y, np.z)
                                if onScreen then
                                    local alpha = dist < 20.0 and 255
                                        or math.max(80, math.floor(255 - (dist - 20.0) * 1.7))
                                    local scale = dist < 15.0 and 0.5 or math.max(0.34, 0.5 - (dist - 15.0) * 0.0016)
                                    SetTextFont(4)
                                    SetTextScale(scale, scale)
                                    SetTextColour(r, g, b, alpha)
                                    SetTextCentre(true)
                                    SetTextOutline()
                                    BeginTextCommandDisplayText('STRING')
                                    AddTextComponentSubstringPlayerName(GetPlayerName(plId))
                                    EndTextCommandDisplayText(sx, sy)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('cnr:client:setWanted', function(payload)
    if type(payload) ~= 'table' then return end
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('cnrWanted', payload.wanted and true or false, true)
    end
end)

AddStateBagChangeHandler('cnrWanted', nil, function() end)
AddStateBagChangeHandler('cnrSide',   nil, function() end)

-- #9 Talking overlay: lists players currently using voice chat, coloured by their CnR
-- status (prisoner orange · cop blue · wanted robber red · innocent white). Replaces
-- vMenu's fixed-cyan ShowSpeaker box, which is disabled in permissions.cfg.
local function statusColor(plId)
    local pst = Player(GetPlayerServerId(plId))
    if pst and pst.state then
        if pst.state.cnrJailed then return 255, 140, 0 end
        if pst.state.cnrSide == 'cop' then return 29, 111, 255 end
        if pst.state.cnrSide == 'robber' and pst.state.cnrWanted then return 224, 50, 50 end
    end
    return 255, 255, 255
end

CreateThread(function()
    while true do
        Wait(0)
        local talkers = {}
        for _, plId in ipairs(GetActivePlayers()) do
            if NetworkIsPlayerTalking(plId) then
                talkers[#talkers + 1] = plId
            end
        end
        if #talkers > 0 then
            SetTextFont(4); SetTextScale(0.30, 0.30); SetTextColour(190, 190, 200, 210)
            SetTextCentre(true); SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName('CURRENTLY TALKING')
            EndTextCommandDisplayText(0.5, 0.020)

            local y = 0.048
            for _, plId in ipairs(talkers) do
                local r, g, b = statusColor(plId)
                SetTextFont(4); SetTextScale(0.40, 0.40); SetTextColour(r, g, b, 255)
                SetTextCentre(true); SetTextOutline()
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName('» ' .. (GetPlayerName(plId) or '???'))
                EndTextCommandDisplayText(0.5, y)
                y = y + 0.030
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for sid in pairs(blips) do removeBlip(sid) end
end)
