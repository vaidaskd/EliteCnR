CnR = CnR or {}
CnR.HUD = CnR.HUD or {}

local hudCache = {
    side            = 'none',
    xp              = 0,
    jailSeconds     = 0,
    jailDebtSeconds = 0,
    servingJail     = false,
    rank            = nil,
    cash            = 0,
    credits         = 0,
}

local lastProfile = nil

RegisterNetEvent('cnr:client:openHud', function(payload)
    payload = payload or {}
    if payload.side ~= nil           then hudCache.side        = payload.side end
    if payload.xp ~= nil             then hudCache.xp          = payload.xp end
    if payload.jailSeconds ~= nil     then hudCache.jailSeconds = payload.jailSeconds end
    if payload.jailDebtSeconds ~= nil then hudCache.jailDebtSeconds = payload.jailDebtSeconds end
    if payload.rank ~= nil           then hudCache.rank        = payload.rank end
    if payload.cash ~= nil           then hudCache.cash        = payload.cash end
end)

RegisterNetEvent('cnr:client:rankApplied', function(payload)
    payload = payload or {}
    if payload.rank then hudCache.rank = payload.rank end
end)

RegisterNetEvent('cnr:client:jailTimeUpdate', function(payload)
    payload = payload or {}
    if payload.seconds ~= nil then hudCache.jailSeconds = payload.seconds end
    hudCache.servingJail = (hudCache.jailSeconds or 0) > 0
end)

AddEventHandler('cnr:client:jailReleased', function()
    hudCache.servingJail = false
    hudCache.jailSeconds = 0
end)

RegisterNetEvent('cnr:client:goToJail', function(payload)
    if type(payload) == 'table' and (tonumber(payload.seconds) or 0) > 0 then
        hudCache.servingJail = true
        hudCache.jailSeconds = tonumber(payload.seconds) or 0
    end
end)

RegisterNetEvent('cnr:client:arrestRewarded', function(payload)
    payload = payload or {}
    if payload.credits then hudCache.credits = (hudCache.credits or 0) + payload.credits end
    if payload.cash    then hudCache.cash    = (hudCache.cash or 0) + payload.cash end
end)

RegisterNetEvent('cnr:client:profileUpdate', function(payload)
    if type(payload) ~= 'table' then return end
    lastProfile = payload
    if payload.side        ~= nil then
        hudCache.side = payload.side
        if CnR.State then CnR.State.side = payload.side end
        if CnR.Blips and CnR.Blips.refresh then CnR.Blips.refresh() end
    end
    if payload.xp          ~= nil then
        hudCache.xp = payload.xp
        if CnR.State then CnR.State.xp = payload.xp end   -- for client-side level checks (rob-a-player)
    end
    if payload.cash        ~= nil then hudCache.cash        = payload.cash end
    if payload.credits     ~= nil then
        hudCache.credits = payload.credits
        if CnR.State then CnR.State.credits = payload.credits end
    end
    if payload.jailSeconds ~= nil     then hudCache.jailSeconds = payload.jailSeconds end
    if payload.jailDebtSeconds ~= nil then hudCache.jailDebtSeconds = payload.jailDebtSeconds end
    if payload.station       ~= nil then
        hudCache.station = payload.station
        if CnR.State then CnR.State.station = payload.station end
    end
    if payload.rank ~= nil then
        hudCache.rank = payload.rank
    elseif payload.rankName ~= nil and CnR.Util and CnR.Util.rankById then
        local r = CnR.Util.rankById(payload.rankId or 1)
        if r then hudCache.rank = r end
    end
    SendNUIMessage({
        type    = 'hudUpdate',
        payload = {
            side            = hudCache.side,
            xp              = hudCache.xp          or 0,
            jailSeconds     = hudCache.jailSeconds or 0,
            jailDebtSeconds = hudCache.jailDebtSeconds or 0,
            servingJail     = hudCache.servingJail or false,
            wanted          = (LocalPlayer.state and LocalPlayer.state.cnrWanted) or false,
            rank            = hudCache.rank,
            cash            = hudCache.cash        or 0,
            credits         = hudCache.credits     or 0,
        },
    })
end)

local function enrichRank(r, side)
    if type(r) ~= 'table' then return r end
    local list = (side == CnR.Sides.ROBBER) and (Config and Config.RobberRanks) or (Config and Config.Ranks)
    local nextXp = r.nextXp   -- keep server-provided value if present
    if nextXp == nil and list then
        for _, c in ipairs(list) do
            if (c.xp or 0) > (r.xp or 0) and (not nextXp or c.xp < nextXp) then
                nextXp = c.xp
            end
        end
    end
    local out = {}
    for k, v in pairs(r) do out[k] = v end
    out.nextXp = nextXp
    return out
end

CreateThread(function()
    while true do
        Wait(1000)


        local side = (CnR.State and CnR.State.side) or hudCache.side or 'none'
        if side == CnR.Sides.COP or side == CnR.Sides.ROBBER then
            hudCache.side = side
            if not IsNuiFocused() then
                local rank = hudCache.rank
                if not rank and CnR.Util then
                    if side == CnR.Sides.COP and CnR.Util.rankFromXp then
                        rank = CnR.Util.rankFromXp(hudCache.xp or 0)
                    elseif side == CnR.Sides.ROBBER and CnR.Util.robberRankFromXp then
                        rank = CnR.Util.robberRankFromXp(hudCache.xp or 0)
                    end
                end
                SendNUIMessage({
                    type = 'hudUpdate',
                    payload = {
                        side            = side,
                        xp              = hudCache.xp              or 0,
                        jailSeconds     = hudCache.jailSeconds     or 0,
                        jailDebtSeconds = hudCache.jailDebtSeconds or 0,
                        servingJail     = hudCache.servingJail     or false,
                        wanted          = (LocalPlayer.state and LocalPlayer.state.cnrWanted) or false,
                        rank            = rank and enrichRank(rank, side) or nil,
                        cash            = hudCache.cash            or 0,
                        credits         = hudCache.credits         or 0,
                    },
                })
            end
        else
            SendNUIMessage({
                type = 'hudUpdate',
                payload = { side = 'none' },
            })
        end
    end
end)
