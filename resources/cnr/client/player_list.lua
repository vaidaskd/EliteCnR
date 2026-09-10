CnR = CnR or {}

local function openPlayerList()
    TriggerServerEvent('cnr:server:requestPlayerList')
end

CnR.PlayerList = CnR.PlayerList or {}
CnR.PlayerList.open = openPlayerList

local kb = (Config and Config.Keybinds and Config.Keybinds.playerList) or {
    key = 'f7',
    description = 'CnR: View online players',
}

RegisterCommand('+cnr_playerlist', function() openPlayerList() end, false)
RegisterCommand('-cnr_playerlist', function() end, false)
RegisterKeyMapping('+cnr_playerlist', kb.description, 'keyboard', kb.key)

RegisterCommand('players', function() openPlayerList() end, false)

RegisterNetEvent('cnr:client:openPlayerList', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openPlayerList then
        CnR.NativeMenus.openPlayerList(payload or {})
    end
end)
