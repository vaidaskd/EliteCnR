CnR = CnR or {}
CnR.Position = CnR.Position or {}

function CnR.Position.canSync()
    if not CnR.State or CnR.State.side == CnR.Sides.NONE then return false end
    if CnR.Spawn and CnR.Spawn.isInSelectionView and CnR.Spawn.isInSelectionView() then return false end
    return true
end

function CnR.Position.sync()
    if not CnR.Position.canSync() then return end
    local ped = PlayerPedId()
    if ped == 0 then return end
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    TriggerServerEvent('cnr:server:syncPosition', {
        x = c.x, y = c.y, z = c.z, h = h,
    })
end

CreateThread(function()
    while true do
        Wait(30000)
        CnR.Position.sync()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    CnR.Position.sync()
end)
