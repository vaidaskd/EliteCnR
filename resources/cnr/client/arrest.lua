CnR = CnR or {}
CnR.Arrest = CnR.Arrest or {}

local isCuffed       = false
local cuffedByCop    = 0
local attachedToCop  = false
local lastNoRobberMsg = 0

-- Nearest wanted robber that is NOT already cuffed (so a cuffed suspect won't show the
-- cuff prompt or be re-cuffable). #5
local function nearestWantedRobber(maxDist)
    local ped = PlayerPedId()
    local mc  = GetEntityCoords(ped)
    local best, bestSrc, bestDist = nil, 0, maxDist or 1.5
    for _, plId in ipairs(GetActivePlayers()) do
        local other = GetPlayerPed(plId)
        if other ~= 0 and other ~= ped then
            local sid = GetPlayerServerId(plId)
            local pst = Player(sid)
            if pst and pst.state and pst.state.cnrSide == 'robber' and pst.state.cnrWanted
                and not pst.state.cnrCuffedBy then
                local d = #(GetEntityCoords(other) - mc)
                if d < bestDist then
                    bestDist = d; bestSrc = sid; best = other
                end
            end
        end
    end
    return best, bestSrc
end

-- Nearest robber that THIS cop has cuffed (for arrest options). #6
local function nearestRobberICuffed(maxDist)
    local ped = PlayerPedId()
    local mc  = GetEntityCoords(ped)
    local mySid = GetPlayerServerId(PlayerId())
    local bestSrc, bestDist = 0, maxDist or 3.0
    for _, plId in ipairs(GetActivePlayers()) do
        local other = GetPlayerPed(plId)
        if other ~= 0 and other ~= ped then
            local sid = GetPlayerServerId(plId)
            local pst = Player(sid)
            if pst and pst.state and pst.state.cnrCuffedBy == mySid then
                local d = #(GetEntityCoords(other) - mc)
                if d < bestDist then bestDist = d; bestSrc = sid end
            end
        end
    end
    return bestSrc
end

local function findCopPed(copSrc)
    local pl = GetPlayerFromServerId(copSrc)
    if pl == -1 then return 0 end
    return GetPlayerPed(pl)
end

local function loadAnim(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t0 < 3000 do Wait(50) end
    return HasAnimDictLoaded(dict)
end

local lastFollowTask = 0
local CUFF_DICT = 'mp_arresting'
local CUFF_ANIM = 'idle'

local function startFollowing(copPed)
    local me = PlayerPedId()
    if copPed == 0 then return end
    if IsEntityAttached(me) then DetachEntity(me, true, true) end
    -- Walk toward cop (primary task).
    TaskGoToEntity(me, copPed, -1, 1.2, 1.0, 0, 0)
    lastFollowTask = GetGameTimer()
    attachedToCop = true
    -- Upper-body cuffed idle animation (secondary task, loops, upper-body only).
    if loadAnim(CUFF_DICT) then
        TaskPlayAnim(me, CUFF_DICT, CUFF_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
    end
end

local function detachSelf()
    local me = PlayerPedId()
    if IsEntityAttached(me) then DetachEntity(me, true, true) end
    ClearPedTasks(me)
    attachedToCop = false
end

-- Seat the cuffed robber into a FREE passenger seat of the cop's vehicle.
-- Returns true if seated. If the vehicle has no passenger seat (e.g. a single-seat
-- sport bike), returns false WITHOUT attaching — the robber simply isn't taken along.
local function placeCuffedInVehicle(me, veh)
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(veh))
    if seats < 2 then return false end   -- no passenger seat at all (1-seat bike)
    for s = 0, seats - 2 do
        if IsVehicleSeatFree(veh, s) then
            ClearPedTasksImmediately(me)
            local vc = GetEntityCoords(veh)
            SetEntityCoordsNoOffset(me, vc.x, vc.y, vc.z, false, false, false)
            SetPedIntoVehicle(me, veh, s)
            Wait(150)
            return GetVehiclePedIsIn(me, false) == veh
        end
    end
    return false
end

RegisterNetEvent('cnr:client:cuffed', function(payload)
    if type(payload) ~= 'table' then return end
    isCuffed = true
    cuffedByCop = tonumber(payload.byCopSrc) or 0
    local copPed = findCopPed(cuffedByCop)
    startFollowing(copPed)
end)

RegisterNetEvent('cnr:client:uncuffed', function()
    isCuffed = false
    cuffedByCop = 0
    detachSelf()
end)

RegisterNetEvent('cnr:client:arrestRewarded', function(payload)
    if type(payload) ~= 'table' then return end

    CnR.Util.log('info', 'arrest reward xp=%s cash=%s', tostring(payload.xp), tostring(payload.cash))
end)

-- Cuff the nearest wanted robber in reach. Triggered by the cuff keybind (C). Returns
-- true if a cuff attempt was sent.
function CnR.Arrest.TryCuff()
    if not (CnR.State and CnR.State.side == CnR.Sides.COP) then return false end
    local _, sid = nearestWantedRobber(2.0)
    if sid and sid > 0 then
        TriggerServerEvent('cnr:server:attemptCuff', { target = sid })
        return true
    end
    return false
end

-- C key (control 26) drives BOTH cuffing and arrest options:
--   • near a robber YOU cuffed   → "Press C for arrest options" → menu  (#6)
--   • near an un-cuffed wanted    → "Press C to cuff this robber"  → cuff
CreateThread(function()
    while true do
        local sleep = 500
        if CnR.State and CnR.State.side == CnR.Sides.COP then
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                sleep = 0
                DisableControlAction(0, 26, true)  -- suppress C look-behind every frame
                local cuffedSid = nearestRobberICuffed(3.0)
                if cuffedSid and cuffedSid > 0 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_LOOK_BEHIND~ for arrest options')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsDisabledControlJustPressed(0, 26) then
                        if CnR.NativeMenus and CnR.NativeMenus.openArrestOptions then
                            CnR.NativeMenus.openArrestOptions(cuffedSid)
                        end
                    end
                elseif nearestWantedRobber(2.0) then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_LOOK_BEHIND~ to cuff this robber')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsDisabledControlJustPressed(0, 26) then
                        CnR.Arrest.TryCuff()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if isCuffed then
            local me = PlayerPedId()

            -- Immediately clear cuffed state on death so controls are restored before respawn.
            -- (Server also detects death via health-check loop and sends cnr:client:uncuffed.)
            if IsEntityDead(me) then
                isCuffed = false
                cuffedByCop = 0
                attachedToCop = false
                Wait(250)
            else

            -- While the pause menu (ESC) is open, don't touch controls at all, or its
            -- buttons become unclickable. Otherwise lock the cuffed player's controls.
            if not IsPauseMenuActive() then
                DisableAllControlActions(0)
                EnableControlAction(0, 1, true)
                EnableControlAction(0, 2, true)
                EnableControlAction(0, 245, true)
                EnableControlAction(0, 199, true)   -- INPUT_FRONTEND_PAUSE
                EnableControlAction(0, 200, true)   -- INPUT_FRONTEND_PAUSE_ALTERNATE
            end
            local copPed = findCopPed(cuffedByCop)
            if copPed ~= 0 then
                local copVeh = GetVehiclePedIsIn(copPed, false)
                local myVeh  = GetVehiclePedIsIn(me, false)
                local copDriving = (copVeh ~= 0 and GetPedInVehicleSeat(copVeh, -1) == copPed)

                if copDriving then
                    -- Cop is driving. Seat / attach the robber as a passenger, but only
                    -- when not already placed — re-running every frame caused the warp
                    -- flicker and the "standing on the bike" look.
                    local alreadyPlaced = (myVeh == copVeh) or IsEntityAttached(me)
                    if not alreadyPlaced then
                        attachedToCop = false
                        placeCuffedInVehicle(me, copVeh)
                        Wait(250)
                    end
                else
                    -- Cop is on foot. Make sure the robber is off the vehicle and following.
                    if IsEntityAttached(me) then DetachEntity(me, true, true) end
                    if myVeh ~= 0 then
                        TaskLeaveVehicle(me, myVeh, 16)
                        Wait(800)
                        startFollowing(copPed)
                    else
                        local now = GetGameTimer()
                        -- Re-issue movement task every 400 ms so it never stalls.
                        if now - lastFollowTask > 400 then
                            TaskGoToEntity(me, copPed, -1, 1.2, 1.0, 0, 0)
                            lastFollowTask = now
                        end
                        -- Re-assert upper-body cuffed animation if it stopped.
                        if not IsEntityPlayingAnim(me, CUFF_DICT, CUFF_ANIM, 3) then
                            if HasAnimDictLoaded(CUFF_DICT) then
                                TaskPlayAnim(me, CUFF_DICT, CUFF_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
                            end
                        end
                    end
                end
            end
            end  -- end else (not dead)
        else
            Wait(250)
        end
    end
end)

-- Draw a red ground cylinder at every arrest-delivery entrance (cops only).
-- Visible within 40 units so the player can see it from the hallway.
CreateThread(function()
    while true do
        if CnR.State and CnR.State.side == CnR.Sides.COP then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local entrances = Config and Config.ArrestEntrances or {}
            for _, e in ipairs(entrances) do
                local c = e.center
                if c and #(pos - vector3(c.x, c.y, c.z)) < 40.0 then
                    local r = e.radius or 3.0
                    local found, groundZ = GetGroundZFor_3dCoord(c.x, c.y, c.z + 2.0, false)
                    local markerZ = found and groundZ or (c.z - 0.9)
                    local textZ   = found and (groundZ + 1.2) or (c.z + 0.3)
                    DrawMarker(
                        1,
                        c.x, c.y, markerZ,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        r * 0.67, r * 0.67, 0.2,
                        220, 30, 30, 180,
                        false, false, 2,
                        false, nil, nil, false
                    )
                    local onScreen, sx, sy = World3dToScreen2d(c.x, c.y, textZ)
                    if onScreen then
                        SetTextFont(4)
                        SetTextScale(0.35, 0.35)
                        SetTextColour(255, 255, 255, 220)
                        SetTextOutline()
                        BeginTextCommandDisplayText('STRING')
                        AddTextComponentSubstringPlayerName('Arrest Point')
                        EndTextCommandDisplayText(sx, sy)
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function nearAnyArrestEntrance(mc)
    local entrances = Config.ArrestEntrances or { Config.ArrestEntrance }
    for _, e in ipairs(entrances) do
        local c = e.center
        local r = e.radius or 3.0
        local dx, dy, dz = mc.x - c.x, mc.y - c.y, mc.z - c.z
        if (dx * dx + dy * dy + dz * dz) <= (r * r) then return true end
    end
    return false
end

CreateThread(function()
    local lastFire = 0
    while true do
        Wait(500)
        if CnR.State and CnR.State.side == CnR.Sides.COP then
            local mePed = PlayerPedId()
            local mc = GetEntityCoords(mePed)
            if nearAnyArrestEntrance(mc) then
                for _, plId in ipairs(GetActivePlayers()) do
                    local other = GetPlayerPed(plId); local sid = GetPlayerServerId(plId)
                    if other ~= 0 and other ~= mePed then
                        local close = #(GetEntityCoords(other) - mc) < 6.0
                        local pst = Player(sid)
                        local isWanted = pst and pst.state and pst.state.cnrWanted
                        if close and isWanted and (GetGameTimer() - lastFire) > 1500 then
                            lastFire = GetGameTimer()
                            TriggerServerEvent('cnr:server:deliverArrest', { target = sid })
                        end
                    end
                end
            end
        end
    end
end)
