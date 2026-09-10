CnR = CnR or {}

-- Cop-only donut spot in the Mission Row PD kitchen. Walk up, press the interact key,
-- and the cop plays a donut-eating animation (with a donut prop) and gains a little health.
local DONUT_POS     = vector3(466.8988, -989.8340, 30.6896)
local INTERACT_DIST = 1.7
local EAT_HEAL      = 15
local eating        = false
local lastEat       = 0

local function helpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function eatDonut()
    if eating then return end
    eating = true
    local ped = PlayerPedId()

    local dict = 'mp_player_inteat@burger'
    RequestAnimDict(dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t < 2000 do Wait(10) end

    -- Donut prop in the right hand.
    local model = `prop_amb_donut`
    RequestModel(model)
    t = GetGameTimer()
    while not HasModelLoaded(model) and GetGameTimer() - t < 2000 do Wait(10) end
    local prop = 0
    if HasModelLoaded(model) then
        local c = GetEntityCoords(ped)
        prop = CreateObject(model, c.x, c.y, c.z, true, true, false)
        local bone = GetPedBoneIndex(ped, 18905)  -- PH_R_Hand
        AttachEntityToEntity(prop, ped, bone, 0.13, 0.04, 0.02, -50.0, 16.0, 60.0,
            true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(model)
    end

    if HasAnimDictLoaded(dict) then
        -- flag 49 = upper-body + secondary + looping, so the cop can stand/turn while eating.
        TaskPlayAnim(ped, dict, 'mp_player_int_eat_burger', 4.0, -4.0, -1, 49, 0, false, false, false)
    end

    Wait(3500)

    ClearPedSecondaryTask(ped)
    if prop ~= 0 and DoesEntityExist(prop) then DeleteEntity(prop) end
    if HasAnimDictLoaded(dict) then RemoveAnimDict(dict) end

    if EAT_HEAL > 0 then
        local hp = GetEntityHealth(ped)
        SetEntityHealth(ped, math.min(hp + EAT_HEAL, GetEntityMaxHealth(ped)))
    end
    if CnR.NativeUI and CnR.NativeUI.notify then
        CnR.NativeUI.notify(('Enjoy your donut. (+%d health)'):format(EAT_HEAL))
    end

    lastEat = GetGameTimer()
    eating = false
end

CreateThread(function()
    while true do
        local sleep = 600
        if not eating and CnR.State and CnR.Sides and CnR.State.side == CnR.Sides.COP then
            local ped = PlayerPedId()
            if ped ~= 0 and not IsEntityDead(ped) then
                if #(GetEntityCoords(ped) - DONUT_POS) <= INTERACT_DIST then
                    sleep = 0
                    helpText('Press ~INPUT_CONTEXT~ to eat a donut')
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastEat) > 1200 then
                        eatDonut()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
