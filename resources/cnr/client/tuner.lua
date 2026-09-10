CnR = CnR or {}

local function helpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function nearestModShop(pos)
    local best, bestD = nil, math.huge
    for _, shop in ipairs((Config and Config.ModShop and Config.ModShop.locations) or {}) do
        if shop.pos then
            local d = #(pos - shop.pos)
            local radius = shop.radius or 30.0
            if d <= radius and d < bestD then
                bestD = d
                best = shop
            end
        end
    end
    return best
end

local function applyRepair(veh)
    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehiclePetrolTankHealth(veh, 1000.0)
end

RegisterNetEvent('cnr:client:applyVehicleMod', function(payload)
    if type(payload) ~= 'table' then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end

    SetVehicleModKit(veh, 0)

    if payload.action == 'repair' then
        applyRepair(veh)
        return
    end

    if payload.action == 'color' and payload.primary then
        local _, secondary = GetVehicleColours(veh)
        SetVehicleColours(veh, payload.primary, secondary)
        return
    end

    if payload.toggle and payload.modType then
        ToggleVehicleMod(veh, payload.modType, payload.enabled == true)
        return
    end

    if payload.modType then
        SetVehicleMod(veh, payload.modType, payload.modIndex or -1, false)
    end
end)

RegisterNetEvent('cnr:client:openModShop', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openModShop then
        CnR.NativeMenus.openModShop(payload or {})
    end
end)

CreateThread(function()
    while true do
        local wait = 500
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and not (CnR.NativeUI and CnR.NativeUI.isOpen()) then
            local shop = nearestModShop(GetEntityCoords(ped))
            if shop then
                wait = 0
                helpText('Press ~INPUT_CONTEXT~ to customize your vehicle')
                local pressed = CnR.KeysPressed and CnR.KeysPressed.interact
                local nativeE = IsControlJustReleased(0, 38)
                if (pressed and (GetGameTimer() - pressed) < 300) or nativeE then
                    if CnR.KeysPressed then CnR.KeysPressed.interact = nil end
                    TriggerServerEvent('cnr:server:requestModShop')
                end
            end
        end

        Wait(wait)
    end
end)
