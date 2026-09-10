CnR = CnR or {}
CnR.Laundry = CnR.Laundry or {}

local lastComplete = {}

RegisterNetEvent('cnr:server:laundryComplete', function()
    local src = source
    local id = CnR.GetIdentifier(src); if not id then return end
    local p = CnR.Persistence.GetProfile(id)
    if (p.jailSecondsRemaining or 0) <= 0 then return end
    local now = os.time()
    if lastComplete[src] and (now - lastComplete[src]) < 30 then return end
    lastComplete[src] = now
    local reduction = Config.JailTime.laundryReduction or Config.Laundry.reductionSec or 120
    p.jailSecondsRemaining = math.max(0, (p.jailSecondsRemaining or 0) - reduction)
    CnR.Persistence.SaveProfile(id, p)
    TriggerClientEvent('cnr:client:jailTimeUpdate', src, { seconds = p.jailSecondsRemaining })
    CnR.Util.log('info', 'laundry complete by src=%d, remaining=%d', src, p.jailSecondsRemaining)
end)

AddEventHandler('playerDropped', function()
    local src = source
    lastComplete[src] = nil
end)
