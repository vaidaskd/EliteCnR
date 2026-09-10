CnR = CnR or {}
CnR.State = CnR.State or {}
CnR.NUI   = CnR.NUI   or {}

CnR.State.side = CnR.Sides.NONE
CnR._sessionBootStarted = false
CnR._loadoutApplied = false

local nuiOpen = false

local function disableAutoSpawn()
    if GetResourceState('spawnmanager') == 'started' then
        exports.spawnmanager:setAutoSpawn(false)
    end
end

local function refreshSide()
    local s = LocalPlayer and LocalPlayer.state and LocalPlayer.state.cnrSide
    if s == CnR.Sides.COP or s == CnR.Sides.ROBBER then
        CnR.State.side = s
    else
        CnR.State.side = CnR.Sides.NONE
    end
end

local function bootHandover()
    if CnR._sessionBootStarted then return end
    CnR._sessionBootStarted = true

    -- Disable spawnmanager before any Wait so it can never auto-spawn the player.
    disableAutoSpawn()

    -- Keep the screen black and the ped invisible every frame from this point on
    -- until applyLoadout fires.  Starting the thread here (before ShutdownLoadingScreen)
    -- closes the 1-2 frame gap that previously let the random civilian spawn flash through.
    CreateThread(function()
        while not CnR._loadoutApplied do
            -- While the team-select / character creator is active it manages the screen
            -- itself (fades in, shows the ped on a pedestal). Forcing black here would fight
            -- its fade-in and leave the creator on a permanent black screen, so pause then.
            local inCreator = CnR.Spawn and CnR.Spawn.isInSelectionView and CnR.Spawn.isInSelectionView()
            if not inCreator then
                DoScreenFadeOut(0)
                local p = PlayerPedId()
                if p ~= 0 and DoesEntityExist(p) then
                    SetEntityVisible(p, false, false)
                    FreezeEntityPosition(p, true)
                end
            end
            Wait(0)
        end
    end)

    while not NetworkIsSessionStarted() do
        Wait(100)
    end

    -- Disable again after session start in case spawnmanager re-enabled it.
    disableAutoSpawn()

    DoScreenFadeOut(0)
    Wait(0)

    ShutdownLoadingScreen()
    if ShutdownLoadingScreenNui then
        ShutdownLoadingScreenNui()
    end

    local ped = PlayerPedId()
    local tries = 0
    while ped == 0 or ped == -1 do
        Wait(100)
        ped = PlayerPedId()
        tries = tries + 1
        if tries > 50 then break end
    end

    SetPlayerControl(PlayerId(), false, 0)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)

    Wait(100)
    TriggerServerEvent('cnr:server:requestTeamSelect')
end

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    refreshSide()
    disableAutoSpawn()  -- synchronous call before the thread starts
    CnR.Util.log('info', 'cnr client booted (side=%s)', tostring(CnR.State.side))
    CreateThread(bootHandover)
end)

AddEventHandler('onClientMapStart', function()
    disableAutoSpawn()
end)

CreateThread(function()
    while true do
        Wait(1000)
        refreshSide()
    end
end)

function CnR.NUI.open(msg)
    if type(msg) ~= 'table' then msg = { type = tostring(msg or 'open') } end
    SendNUIMessage(msg)
    SetNuiFocus(true, true)
    nuiOpen = true
end

function CnR.NUI.close()
    SendNUIMessage({ type = 'close' })
    SetNuiFocus(false, false)
    nuiOpen = false
end

function CnR.NUI.isOpen() return nuiOpen end

