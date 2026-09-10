CnR = CnR or {}
CnR.Keys = CnR.Keys or {
    cuff = false, interact = false,
    help = false, inventory = false, teamMenu = false, doorTool = false,
}

CnR.KeysPressed = CnR.KeysPressed or {}

-- `cmd` overrides the registered command name (defaults to '+cnr_<action>'). It is
-- bumped when a default keybind changes, because RegisterKeyMapping only applies a
-- default the first time a command name is seen — an existing saved binding (e.g. an
-- old 'q' for cuff) sticks otherwise. A new command name forces the new default.
local function makeBinding(action, defaultKey, description, onDown, onUp, device, cmd)
    cmd = cmd or ('+cnr_' .. action)
    local minus = '-' .. cmd:sub(2)
    RegisterCommand(cmd, function()
        CnR.Keys[action] = true
        CnR.KeysPressed[action] = GetGameTimer()
        if onDown then onDown() end
    end, false)
    RegisterCommand(minus, function()
        CnR.Keys[action] = false
        if onUp then onUp() end
    end, false)
    RegisterKeyMapping(cmd, description, device or 'keyboard', defaultKey)
end

local kb = (Config and Config.Keybinds) or {}

-- The first player to drive a vehicle owns it (cnrOwnedBy). A vehicle is "locked
-- against me" if its doors are locked AND I'm not the owner — so the owner can always
-- get into / unlock their own vehicle, everyone else is shut out. #4
local function ownerOf(veh)
    local by = nil
    pcall(function() by = Entity(veh).state and Entity(veh).state.cnrOwnedBy end)
    return by
end

-- "Locked against me" = our replicated cnrLocked flag is set by someone who isn't me. This
-- blocks ALL access (even jacking) to a player's own locked vehicle.
local function lockedAgainstMe(veh)
    if ownerOf(veh) == GetPlayerServerId(PlayerId()) then return false end
    local locked = false
    pcall(function() local s = Entity(veh).state; locked = s and s.cnrLocked end)
    return locked == true
end

-- Genuinely game-locked (door-lock status 2) and not mine — entering smashes the window.
-- Only COPS are blocked from breaking in (their own police vehicles are auto-unlocked, so
-- they never need to). Robbers may still break into locked cars (stealing a police vehicle
-- is an intended robber crime). #4
local function gameLockedAgainstMe(veh)
    if not (CnR.State and CnR.State.side == CnR.Sides.COP) then return false end
    return GetVehicleDoorLockStatus(veh) == 2 and ownerOf(veh) ~= GetPlayerServerId(PlayerId())
end

-- Is ANY other player currently inside this vehicle? GetVehiclePedIsIn reflects each
-- streamed player's real vehicle and syncs reliably, unlike IsVehicleSeatFree/
-- GetPedInVehicleSeat which report a remote player's seat as "free" — the exact reason F
-- kept treating a player-driven car as empty and dropping us into a passenger seat. #3
local function playerIsInVehicle(veh)
    for _, plId in ipairs(GetActivePlayers()) do
        if plId ~= PlayerId() then
            local pped = GetPlayerPed(plId)
            if pped and pped ~= 0 and pped ~= -1 and GetVehiclePedIsIn(pped, false) == veh then
                return true
            end
        end
    end
    return false
end

-- Closest vehicle to a ped within maxDist, scanning the vehicle pool directly. GetClosestVehicle
-- with its flags SILENTLY SKIPS player-occupied vehicles — which is why F/G only ever worked on
-- empty cars: the player-driven car was never even found, so vanilla F (tap=passenger /
-- hold=jack) took over. Walking the pool finds every vehicle, occupied or not. #3
local function nearestVehicle(ped, maxDist)
    local pc = GetEntityCoords(ped)
    local best, bestD = 0, maxDist or 8.0
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if v ~= 0 then
            local d = #(pc - GetEntityCoords(v))
            if d < bestD then bestD = d; best = v end
        end
    end
    return best
end

-- Entry guard: while an entry/jack is mid-animation, ignore further F/G presses. Without
-- this, spamming the key re-runs ClearPedTasks every press and cancels the walk/jack, so
-- it never completes on an occupied vehicle (the "only works when empty" bug). #2
local busyUntil = 0
local function busy() return GetGameTimer() < busyUntil end
local function clearBusy() busyUntil = 0 end

-- You can only START boarding/jacking a vehicle that is essentially STOPPED and within reach.
-- This is what stops F/G from making the ped chase a car that's driving away and then warp
-- into the seat — you cannot board a moving vehicle on foot, so we simply don't begin. #entry
local BOARD_MAX_SPEED = 1.5   -- m/s (~5 km/h): the car must be basically stationary
local BOARD_MAX_DIST  = 7.0   -- metres: sanity cap so we never walk the ped a long way to a car
local function canBoard(ped, veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return false end
    if #(GetEntityVelocity(veh)) > BOARD_MAX_SPEED then return false end
    if #(GetEntityCoords(ped) - GetEntityCoords(veh)) > BOARD_MAX_DIST then return false end
    return true
end

-- During an in-progress entry/jack, the target has "fled" if it despawned, sped up, or pulled
-- away. When that happens we CANCEL the task instead of letting the game warp us after it — no
-- teleporting across distance into a moving seat. #entry
local function vehicleFled(ped, veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return true end
    if #(GetEntityVelocity(veh)) > 6.0 then return true end                     -- ~22 km/h: clearly driving off
    if #(GetEntityCoords(ped) - GetEntityCoords(veh)) > 9.0 then return true end -- pulled out of range
    return false
end

-- On-screen instructional prompt (top-left help box). Beep is off so it can be refreshed
-- every frame while standing next to a vehicle without spamming a sound.
local function helpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

-- G key: toggle. In a vehicle → get OUT. On foot → get IN as a passenger.
local function passengerToggle()
    local ped = PlayerPedId()
    if ped == 0 then return end
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        ClearPedTasks(ped)
        local speed = #(GetEntityVelocity(veh))
        TaskLeaveVehicle(ped, veh, speed > 5.0 and 16 or 0)
        return
    end
    if busy() then return end
    local c = GetEntityCoords(ped)
    local veh = nearestVehicle(ped, 8.0)
    if not veh or veh == 0 then return end
    if not canBoard(ped, veh) then
        if CnR.NativeUI then CnR.NativeUI.notify('Get up to a stopped vehicle first.') end
        return                                             -- never chase a moving/distant car #entry
    end
    if lockedAgainstMe(veh) or gameLockedAgainstMe(veh) then
        if CnR.NativeUI then CnR.NativeUI.notify('🔒 That vehicle is locked.') end
        return                                             -- don't break a window to ride along #4
    end
    -- First free PASSENGER seat (0..n, never the driver seat -1).
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(veh))
    local target
    for seat = 0, math.max(0, seats - 2) do
        if IsVehicleSeatFree(veh, seat) then target = seat; break end
    end
    if not target then return end
    busyUntil = GetGameTimer() + 1200
    ClearPedTasks(ped)
    -- The real reason G used to "hijack": GTA AUTO-SHUFFLES a lone passenger into the driver
    -- seat the moment it empties (the driver player leaves, or an ambient NPC panics and flees
    -- after you board). Config flag 184 = PreventAutoShuffleToDriversSeat stops that natively —
    -- so we stay a passenger no matter what. SetPedCanBeDraggedOut(false) additionally stops
    -- the entry itself from jacking the current driver. No ClearPedTasks spam (that was
    -- cancelling the door-close animation and destabilising the seat). #3
    SetPedConfigFlag(ped, 184, true)
    local driver = GetPedInVehicleSeat(veh, -1)
    if driver ~= 0 and driver ~= ped then SetPedCanBeDraggedOut(driver, false) end
    -- If an NPC is driving, it PANICS the moment you board and flees — which empties the car
    -- and drags you out (the "passenger exits after a few seconds" bug). The only fix is to
    -- OWN the NPC and block its events, but ownership is ASYNC — setting the flag the same
    -- frame we request control (as before) applied it to a ped we didn't own yet, so it never
    -- took. We must keep requesting control + re-applying the calm flags the whole time. #3
    local npcDriver = (driver ~= 0 and driver ~= ped and not IsPedAPlayer(driver)) and driver or nil
    local function keepNpcCalm()
        if not (npcDriver and DoesEntityExist(npcDriver)) then return end
        if NetworkGetEntityIsNetworked(npcDriver) and not NetworkHasControlOfEntity(npcDriver) then
            NetworkRequestControlOfEntity(npcDriver)
        end
        SetBlockingOfNonTemporaryEvents(npcDriver, true)
        SetPedKeepTask(npcDriver, true)
    end
    keepNpcCalm()
    TaskEnterVehicle(ped, veh, 8000, target, 2.0, 1, 0)   -- animated sit-in (flag 1)
    CreateThread(function()
        local closed = false
        local t0 = GetGameTimer()
        -- Phase 1: boarding — keep the NPC calm so it doesn't flee before we even sit down.
        while GetVehiclePedIsIn(ped, false) ~= veh and GetGameTimer() - t0 < 8000 do
            Wait(50)
            if vehicleFled(ped, veh) then ClearPedTasks(ped); clearBusy(); return end  -- car drove off → cancel, no warp #entry
            keepNpcCalm()
        end
        -- Phase 2: aboard — keep it calm (and our door shut) for as long as we ride along.
        while GetVehiclePedIsIn(ped, false) == veh do
            Wait(100)
            keepNpcCalm()
            if GetPedInVehicleSeat(veh, -1) == ped then
                if IsVehicleSeatFree(veh, target) then SetPedIntoVehicle(ped, veh, target) end   -- never drive
            elseif not closed and GetPedInVehicleSeat(veh, target) == ped then
                SetVehicleDoorShut(veh, target + 1, false)   -- close our door once seated
                closed = true
            end
        end
        if driver and driver ~= 0 and DoesEntityExist(driver) then
            SetPedCanBeDraggedOut(driver, true)
        end
    end)
end

-- Get into the DRIVER seat (-1).
--   • EMPTY seat (occupied=false): plain animated entry, NO warp — the full get-in
--     animation always plays and you never teleport into the seat. #4
--   • NPC driver (occupied=true): flag 1 makes the ped naturally jack the driver with the
--     animation. If that stalls, or the game drops us into a passenger seat, we take hard
--     control of the car AND the NPC and force ourselves into the driver seat (which ejects
--     the NPC). This is the guarantee that F always hijacks an NPC car. #1
local function enterDriverSeat(veh, occupied)
    local ped = PlayerPedId()
    SetPedConfigFlag(ped, 184, false)   -- driver entry: allow the driver seat (clears any G no-shuffle)
    -- Hold the entry guard for the whole jack so a re-press can't cancel the animation.
    busyUntil = GetGameTimer() + (occupied and 5500 or 1500)
    ClearPedTasks(ped)
    if NetworkGetEntityIsNetworked(veh) then NetworkRequestControlOfEntity(veh) end
    -- Flag 8 = jack the occupied vehicle (the proper carjack flag): the ped walks up, drags
    -- the NPC out (the NPC stumbles) and gets in — the full hijack animation. Flag 1 = normal
    -- entry for an empty seat. Empty seats stay animation-only (no warp). #3
    TaskEnterVehicle(ped, veh, 8000, -1, 2.0, occupied and 8 or 1, 0)
    if not occupied then return end
    -- Let the jack animation play out (~3-4s). Warp ONLY as a last resort if it never
    -- completes, or if the ped is redirected into a passenger seat. A clean driver-seat jack
    -- returns below with no teleport at all. #3
    CreateThread(function()
        local t0 = GetGameTimer()
        while GetGameTimer() - t0 < 6000 do
            Wait(50)
            if GetPedInVehicleSeat(veh, -1) == ped then clearBusy(); return end  -- jacked cleanly (animated)
            -- only force it if we ended up in a non-driver seat; a good jack is caught above
            if GetVehiclePedIsIn(ped, false) == veh and GetPedInVehicleSeat(veh, -1) ~= ped then break end
            if vehicleFled(ped, veh) then ClearPedTasks(ped); clearBusy(); return end  -- drove off → cancel, no warp #entry
        end
        -- Finalise ONLY if we're right at the (still-stationary) car — e.g. the animation put
        -- us in the wrong seat or stalled at the door. Never warp across distance or onto a
        -- moving car; that instant teleport is exactly what we're eliminating. #entry
        if lockedAgainstMe(veh)
            or #(GetEntityCoords(ped) - GetEntityCoords(veh)) > 2.2
            or #(GetEntityVelocity(veh)) > BOARD_MAX_SPEED then
            clearBusy(); return
        end
        local npc = GetPedInVehicleSeat(veh, -1)
        -- NEVER warp-eject a PLAYER here — that path is server-only. This prevents the
        -- accidental "hold F to yank a player out" behaviour. Players go through the server.
        if npc ~= 0 and npc ~= ped and IsPedAPlayer(npc) then clearBusy(); return end
        for _ = 1, 15 do
            if NetworkGetEntityIsNetworked(veh) then NetworkRequestControlOfEntity(veh) end
            if npc ~= 0 and npc ~= ped and DoesEntityExist(npc) then NetworkRequestControlOfEntity(npc) end
            if NetworkHasControlOfEntity(veh) then break end
            Wait(20)
        end
        SetPedIntoVehicle(ped, veh, -1)   -- finalise: seat us as driver (ejects the NPC)
        clearBusy()
    end)
end

-- F: enter as DRIVER, hijacking the current occupant if the seat is taken.
--   • empty seat   → animated entry (no teleport).
--   • NPC driver   → animated jack + warp net (we own NPCs).
--   • PLAYER driver → the server evicts the victim and seats you; we identify the victim
--     HERE (our client has the accurate driver ped) and send their id. #2
-- Carjack a PLAYER-driven car WITH the animation: we play the jack (walk up, reach in), and
-- the moment we get to the door we tell the server to evict the victim (you can't pull a
-- remote player's ped out from a client). So the driver gets yanked out as we reach in, then
-- we drop into the freed seat — a real hijack, not an instant teleport-eject. #3
local function playerHijack(veh, victimSid)
    local ped = PlayerPedId()
    SetPedConfigFlag(ped, 184, false)   -- driver entry: clear any G no-shuffle flag
    busyUntil = GetGameTimer() + 6000
    ClearPedTasks(ped)
    TaskEnterVehicle(ped, veh, 10000, -1, 2.0, 8, 0)   -- flag 8: the jack animation
    CreateThread(function()
        local t0 = GetGameTimer()
        local evicted, retasked = false, false
        while GetGameTimer() - t0 < 6000 do
            Wait(50)
            if GetPedInVehicleSeat(veh, -1) == ped then clearBusy(); return end   -- seated
            if not evicted and vehicleFled(ped, veh) then ClearPedTasks(ped); clearBusy(); return end  -- victim drove off → cancel, no chase/warp #entry
            -- Only yank the victim out once we've reached the actual DRIVER DOOR. Measuring to
            -- the vehicle CENTRE was the bug: approaching from the far side, you pass within
            -- 2.5m of the centre while walking around the car, so the victim popped out before
            -- you ever got to the door. Measuring to the driver-door bone fixes that — the
            -- eviction now only fires when you're physically at the door. #3
            local doorIdx = GetEntityBoneIndexByName(veh, 'door_dside_f')
            local doorPos = (doorIdx ~= -1) and GetWorldPositionOfEntityBone(veh, doorIdx) or GetEntityCoords(veh)
            local atDoor = #(GetEntityCoords(ped) - doorPos) < 1.4
            if not evicted and ((atDoor and IsPedJacking(ped))
                or (atDoor and (GetGameTimer() - t0) > 1400)
                or (GetGameTimer() - t0) > 5000) then
                evicted = true
                TriggerServerEvent('cnr:server:evictDriver', { victim = victimSid })
            end
            -- once the seat is free, finish getting in with the animation (no teleport)
            if evicted and not retasked and IsVehicleSeatFree(veh, -1) and GetVehiclePedIsIn(ped, false) ~= veh then
                retasked = true
                TaskEnterVehicle(ped, veh, 8000, -1, 2.0, 1, 0)
            end
        end
        clearBusy()
    end)
end

local function hijackOrDrive(ped, veh)
    if lockedAgainstMe(veh) then
        if CnR.NativeUI then CnR.NativeUI.notify('🔒 That vehicle is locked.') end
        return
    end
    local driver = GetPedInVehicleSeat(veh, -1)
    -- Player-occupied seat → ALWAYS the animated server carjack, never the NPC warp path. If we
    -- can't resolve the victim's server id we simply don't jack (rather than teleport-ejecting a
    -- player, which is what happened when this fell through to enterDriverSeat). #entry
    if driver ~= 0 and driver ~= ped and IsPedAPlayer(driver) then
        local pl = NetworkGetEntityIsNetworked(veh) and NetworkGetPlayerIndexFromPed(driver) or -1
        if pl and pl ~= -1 then
            playerHijack(veh, GetPlayerServerId(pl))           -- player → animated carjack
        elseif CnR.NativeUI then
            CnR.NativeUI.notify("Can't carjack that driver right now.")
        end
        return
    end
    if driver == 0 or driver == ped then
        if gameLockedAgainstMe(veh) then
            if CnR.NativeUI then CnR.NativeUI.notify('🔒 That vehicle is locked.') end
            return                                             -- don't smash an empty locked car #4
        end
        enterDriverSeat(veh, false)                            -- empty → animated entry
    else
        enterDriverSeat(veh, true)                             -- NPC → animated jack
    end
end

-- Server-coordinated player carjack: you've been jacked → get pulled out of the seat and
-- stumble, like a real carjack victim (not a silent teleport out of the car). #3
RegisterNetEvent('cnr:client:forceExitVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end
    SetVehicleDoorOpen(veh, 0, false, false)   -- driver door flings open
    TaskLeaveVehicle(ped, veh, 0)              -- ANIMATED get-out (not an instant teleport)
    CreateThread(function()
        -- the moment we're actually out of the car, a short ragdoll stumble so it reads as
        -- being shoved out — instead of a clean voluntary exit or a teleport. #3
        local t0 = GetGameTimer()
        while GetGameTimer() - t0 < 3000 do
            Wait(50)
            if not IsPedInAnyVehicle(PlayerPedId(), false) then
                SetPedToRagdoll(PlayerPedId(), 900, 900, 0, true, true, false)
                return
            end
        end
    end)
end)


-- F (control 23 / INPUT_ENTER) = driver toggle:
--   • In a vehicle  → exit it.
--   • On foot near a vehicle → enter as DRIVER, hijacking the occupant (NPC or player)
--     if the driver seat is taken. Vanilla GTA auto-enters as a passenger when the
--     driver seat is occupied (the old "F enters as passenger" bug) and won't reliably
--     jack, so we suppress vanilla F and force driver-seat (-1) entry / a carjack.
-- Polled every frame so it always reacts instantly.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if ped ~= 0 then
            if IsPedInAnyVehicle(ped, false) then
                -- In a vehicle → F gets out. Handle it ourselves (disable vanilla to
                -- avoid a double-trigger), with the jump-out flag while moving.
                DisableControlAction(0, 23, true)
                if IsDisabledControlJustPressed(0, 23) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    ClearPedTasks(ped)
                    local speed = #(GetEntityVelocity(veh))
                    TaskLeaveVehicle(ped, veh, speed > 5.0 and 16 or 0)
                end
            else
                local c = GetEntityCoords(ped)
                local veh = nearestVehicle(ped, 8.0)
                if veh and veh ~= 0 then
                    DisableControlAction(0, 23, true)            -- block vanilla F (auto-passenger)
                    -- Tell the player how to get in when standing right by a car.
                    if #(c - GetEntityCoords(veh)) < 4.5 then
                        helpText('Press ~b~F~s~ to enter as driver, or ~b~G~s~ as passenger')
                    end
                    if IsDisabledControlJustPressed(0, 23) and not busy() then
                        if canBoard(ped, veh) then
                            hijackOrDrive(ped, veh)
                        elseif CnR.NativeUI then
                            CnR.NativeUI.notify('Get up to a stopped vehicle first.')   -- never chase a moving/distant car #entry
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)

-- Cuff key (C / control 26) is polled directly via IsDisabledControlJustPressed in
-- arrest.lua. No RegisterKeyMapping is used — this bypasses FiveM keybind caching
-- completely so the key always works regardless of any previously saved client binding.

-- Ownership claim: whoever is driving a networked vehicle becomes its owner (used by
-- the lock system). Claims an unowned vehicle, and transfers ownership to a new driver
-- after a successful (re-)entry or hijack. #4
CreateThread(function()
    while true do
        Wait(750)
        local ped = PlayerPedId()
        if ped ~= 0 and IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and NetworkGetEntityIsNetworked(veh) then
                local mySid = GetPlayerServerId(PlayerId())
                if ownerOf(veh) ~= mySid then
                    NetworkRequestControlOfEntity(veh)
                    pcall(function() Entity(veh).state:set('cnrOwnedBy', mySid, true) end)
                end
            end
        end
    end
end)

-- Debug overlay for F/G troubleshooting: /vehdbg toggles a readout of what the game reports
-- about the closest vehicle, so we can see the actual values rather than guess. Admin-only.
CnR.VehDebug = false
RegisterCommand('vehdbg', function()
    CnR.VehDebug = not CnR.VehDebug
    TriggerEvent('chat:addMessage', { args = { '[veh]', 'debug ' .. (CnR.VehDebug and 'ON' or 'OFF') } })
end, false)
CreateThread(function()
    while true do
        if CnR.VehDebug then
            Wait(0)
            local ped = PlayerPedId()
            if ped ~= 0 and not IsPedInAnyVehicle(ped, false) then
                local c = GetEntityCoords(ped)
                local veh = nearestVehicle(ped, 8.0)
                if veh and veh ~= 0 then
                    local driver = GetPedInVehicleSeat(veh, -1)
                    local txt = ('F/G DEBUG~n~seatFree(-1)=%s~n~driver ped=%s~n~driver is player=%s~n~playerInVehicle=%s~n~networked=%s~n~doorLock=%s')
                        :format(tostring(IsVehicleSeatFree(veh, -1)), tostring(driver),
                            tostring(driver ~= 0 and IsPedAPlayer(driver)), tostring(playerIsInVehicle(veh)),
                            tostring(NetworkGetEntityIsNetworked(veh)), tostring(GetVehicleDoorLockStatus(veh)))
                    SetTextFont(4); SetTextScale(0.38, 0.38); SetTextColour(255, 230, 0, 255); SetTextOutline()
                    BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(txt)
                    EndTextCommandDisplayText(0.30, 0.62)
                end
            end
        else
            Wait(500)
        end
    end
end)

makeBinding('interact', (kb.interact and kb.interact.key) or 'e',
    (kb.interact and kb.interact.description) or 'CnR: Interact (robbery, terminal)')

-- L: lock / unlock YOUR vehicle. Works whether you're sitting in it OR standing next to
-- it — but only if you own it (you were the first to drive it). Non-owners can't toggle
-- the lock inside or outside. #4
makeBinding('lock', (kb.lock and kb.lock.key) or 'l',
    (kb.lock and kb.lock.description) or 'CnR: Lock / unlock your vehicle',
    function()
        local ped = PlayerPedId()
        local mySid = GetPlayerServerId(PlayerId())
        local veh = GetVehiclePedIsIn(ped, false)   -- the vehicle you're sitting in
        if veh == 0 then
            local c = GetEntityCoords(ped)
            veh = nearestVehicle(ped, 5.0)   -- or the one you're standing by
        end
        if not veh or veh == 0 then
            if CnR.NativeUI then CnR.NativeUI.notify('No vehicle nearby.') end
            return
        end
        if ownerOf(veh) ~= mySid then
            if CnR.NativeUI then CnR.NativeUI.notify("🔒 That isn't your vehicle.") end
            return
        end
        if NetworkGetEntityIsNetworked(veh) then NetworkRequestControlOfEntity(veh) end
        -- Lock state lives in the replicated cnrLocked state bag (authoritative across
        -- clients); the native door lock is set alongside it for the game's own checks. #3
        local curLocked = false
        pcall(function() local s = Entity(veh).state; curLocked = s and s.cnrLocked end)
        if curLocked then
            SetVehicleDoorsLocked(veh, 1)
            SetVehicleDoorsLockedForAllPlayers(veh, false)
            pcall(function() Entity(veh).state:set('cnrLocked', false, true) end)
            if CnR.NativeUI then CnR.NativeUI.notify('🔓 Vehicle ~g~unlocked~s~') end
        else
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleDoorsLockedForAllPlayers(veh, true)
            pcall(function() Entity(veh).state:set('cnrLocked', true, true) end)
            if CnR.NativeUI then CnR.NativeUI.notify('🔒 Vehicle ~r~locked~s~') end
        end
    end)

makeBinding('help', (kb.help and kb.help.key) or 'h',
    (kb.help and kb.help.description) or 'CnR: Open the server guide',
    function()
        if CnR.Commands and CnR.Commands.openHelp then
            CnR.Commands.openHelp()
        else
            ExecuteCommand('help')
        end
    end)

if Config and Config.EnableM then
    makeBinding('teamMenu', (kb.teamMenu and kb.teamMenu.key) or 'm',
        (kb.teamMenu and kb.teamMenu.description) or 'CnR: Open police clothing (cops only)',
        function()
            if CnR.State and CnR.State.side == CnR.Sides.COP then
                TriggerServerEvent('cnr:server:requestClothingList')
            end
        end)
end

makeBinding('doorTool', (kb.doorTool and kb.doorTool.key) or 'u',
    (kb.doorTool and kb.doorTool.description) or 'CnR: Toggle police/prison door lock')

-- Command bumped to +cnr_passenger3 (fresh name) so it defaults to 'g' and is not
-- affected by any stale 'f' binding saved under the old command names. F is handled
-- separately above as the driver-entry key.
makeBinding('passenger', (kb.passenger and kb.passenger.key) or 'g',
    (kb.passenger and kb.passenger.description) or 'CnR: Enter vehicle as passenger / exit vehicle',
    function() passengerToggle() end,
    nil, (kb.passenger and kb.passenger.device) or 'keyboard', '+cnr_passenger4')
