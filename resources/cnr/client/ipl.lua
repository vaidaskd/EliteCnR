CnR = CnR or {}

local INTERACT_DIST = 2.0

local function helpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function teleportTo(vec)
    if not vec then return end
    local ped = PlayerPedId()
    DoScreenFadeOut(300)
    Wait(350)
    SetEntityCoords(ped, vec.x + 0.0, vec.y + 0.0, vec.z + 0.0, false, false, false, false)
    SetEntityHeading(ped, vec.w or vec.h or 0.0)
    Wait(200)
    DoScreenFadeIn(400)
end

-- Mission Row only: vanilla interior walk-in/out helpers (no custom MLOs)
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(1000)

    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local st = Config and Config.PoliceStations and Config.PoliceStations.missionRow
        if st then
        end

        Wait(sleep)
    end
end)
