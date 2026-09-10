CnR = CnR or {}
CnR.Blips = CnR.Blips or {}

local staticHandles  = {}
local dynamicHandles = {}
local lastAudience   = nil

local function makeBlip(def, groupColor)
    local h = AddBlipForCoord(def.pos.x, def.pos.y, def.pos.z)
    SetBlipSprite(h, def.sprite or 1)
    SetBlipColour(h, def.color or groupColor or 0)
    SetBlipScale(h, def.scale or 0.85)
    SetBlipAsShortRange(h, def.short ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(def.name or '')
    EndTextCommandSetBlipName(h)
    return h
end

local function audienceMatches(blipAudience, mySide, groupKey)
    if not blipAudience or blipAudience == 'all' then return true end
    if blipAudience == mySide then return true end
    -- Cops need store/bank blips to respond to robberies
    if mySide == 'cop' and (groupKey == 'stores' or groupKey == 'banks') then
        return true
    end
    return false
end

local function clearGroup(key)
    if not staticHandles[key] then return end
    for _, h in ipairs(staticHandles[key]) do
        if DoesBlipExist(h) then RemoveBlip(h) end
    end
    staticHandles[key] = nil
end

local function clearAllStatic()
    for k in pairs(staticHandles) do clearGroup(k) end
end

local function rebuildStatic(side)
    clearAllStatic()
    if not Config or not Config.Blips then return end
    for groupKey, group in pairs(Config.Blips) do
        if type(group) == 'table' and group[1] then
            local handles = {}
            for _, def in ipairs(group) do
                if audienceMatches(def.audience, side, groupKey) then
                    handles[#handles + 1] = makeBlip(def)
                end
            end
            if #handles > 0 then
                staticHandles[groupKey] = handles
            end
        end
    end
end

local function ensureDynamic(name, def)
    if dynamicHandles[name] then return end
    if not def then return end
    dynamicHandles[name] = makeBlip(def)
end

local function removeDynamic(name)
    local h = dynamicHandles[name]
    if h and DoesBlipExist(h) then RemoveBlip(h) end
    dynamicHandles[name] = nil
end

CreateThread(function()

    Wait(2000)
    rebuildStatic(CnR.State and CnR.State.side or 'none')
    lastAudience = CnR.State and CnR.State.side or 'none'

    while true do
        Wait(2500)
        local side = CnR.State and CnR.State.side or 'none'
        if side ~= lastAudience then
            rebuildStatic(side)
            lastAudience = side
        end

        if side == 'cop' then
            -- Support both the new array (arrestEntrances) and the old single entry
            local arrestList = Config.Blips.arrestEntrances
                or (Config.Blips.arrestEntrance and { Config.Blips.arrestEntrance })
                or {}
            for i, ae in ipairs(arrestList) do
                ensureDynamic('arrestEntrance:' .. i, {
                    pos    = ae.pos,
                    sprite = ae.sprite or 526,
                    color  = ae.color  or 38,
                    scale  = ae.scale  or 0.85,
                    short  = false,
                    name   = ae.name   or 'Arrest Point',
                })
            end
        else
            -- Remove all arrest-entrance blips
            local arrestList = Config.Blips.arrestEntrances
                or (Config.Blips.arrestEntrance and { Config.Blips.arrestEntrance })
                or {}
            for i in ipairs(arrestList) do
                removeDynamic('arrestEntrance:' .. i)
            end
        end

    end
end)

function CnR.Blips.refresh()
    local side = CnR.State and CnR.State.side or 'none'
    rebuildStatic(side)
    lastAudience = side
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearAllStatic()
    for n in pairs(dynamicHandles) do removeDynamic(n) end
end)
