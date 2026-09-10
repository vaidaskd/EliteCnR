CnR = CnR or {}

-- ─── LOCAL chat over-head bubble (#2) ───────────────────────────────────────────
-- When a LOCAL message is sent, nearby players see a short preview above the
-- sender's nickname for a few seconds.
local bubbles = {}   -- [serverId] = { text = , expire = }

RegisterNetEvent('cnr:client:localBubble', function(payload)
    if type(payload) ~= 'table' then return end
    local sid  = tonumber(payload.sender)
    local text = tostring(payload.text or '')
    if not sid or text == '' then return end
    bubbles[sid] = { text = text, expire = GetGameTimer() + 6000 }
end)

CreateThread(function()
    while true do
        if next(bubbles) then
            Wait(0)
            local now = GetGameTimer()
            local myPos = GetEntityCoords(PlayerPedId())
            for sid, b in pairs(bubbles) do
                if now > b.expire then
                    bubbles[sid] = nil
                else
                    local plId = GetPlayerFromServerId(sid)
                    local ped = (plId ~= -1) and GetPlayerPed(plId) or 0
                    if ped ~= 0 then
                        local pos = GetEntityCoords(ped)
                        if #(myPos - pos) <= 25.0 then
                            -- Sit the bubble above the coloured nickname (drawn at +1.0).
                            local np = pos + vector3(0.0, 0.0, 1.45)
                            local onScreen, sx, sy = World3dToScreen2d(np.x, np.y, np.z)
                            if onScreen then
                                SetTextFont(4)
                                SetTextScale(0.34, 0.34)
                                SetTextColour(235, 235, 235, 230)
                                SetTextCentre(true)
                                SetTextOutline()
                                BeginTextCommandDisplayText('STRING')
                                AddTextComponentSubstringPlayerName('"' .. b.text .. '"')
                                EndTextCommandDisplayText(sx, sy)
                            end
                        end
                    end
                end
            end
        else
            Wait(250)
        end
    end
end)
