
CnR = CnR or {}
CnR.NUI = CnR.NUI or {}

RegisterNetEvent('cnr:client:openHud', function(payload)
    SendNUIMessage({ type = 'hudUpdate', payload = payload or {} })
end)

RegisterNetEvent('cnr:client:robberyProgress', function(payload)
    SendNUIMessage({ type = 'robberyProgress', payload = payload or {} })
end)

RegisterNetEvent('cnr:client:jailTimeUpdate', function(payload)
    SendNUIMessage({ type = 'jailTimeUpdate', payload = payload or {} })
end)

RegisterNetEvent('cnr:client:notify', function(payload)
    payload = payload or {}
    local text = tostring(payload.text or '')
    if text == '' then return end
    -- Single notification: ONE clean line in the game feed (bottom-left, near the
    -- minimap). No top-right NUI toast, no [CnR] tag, no duplicates.
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, true)
end)

RegisterNetEvent('cnr:client:clothingList', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openClothingStore then
        CnR.NativeMenus.openClothingStore(payload or {})
    end
end)

RegisterNetEvent('cnr:client:vehiclePicker', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openVehiclePicker then
        CnR.NativeMenus.openVehiclePicker(payload or {})
    end
end)

RegisterNetEvent('cnr:client:openHelp', function()
    if CnR.Commands and CnR.Commands.openHelp then
        CnR.Commands.openHelp()
    end
end)

function CnR.NUI.open(msg)
    if type(msg) ~= 'table' then return end
    SendNUIMessage(msg)
end

function CnR.NUI.close()
    SendNUIMessage({ type = 'close' })
end

CreateThread(function()
    while true do
        Wait(0)
        if (IsNuiFocused() or CnR.NativeUI.isOpen()) and IsControlJustReleased(0, 200) then
            SendNUIMessage({ type = 'closeAll' })
            SetNuiFocus(false, false)
            CnR.NativeUI.closeAll()
        end
    end
end)
