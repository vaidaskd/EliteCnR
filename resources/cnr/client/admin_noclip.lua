-- Admin noclip — toggled via /noclip (server checks ACE before firing the event)

local noclipOn  = false
local BASE_SPEED = 0.5   -- units per frame at normal speed (~30 u/s @ 60 fps)

-- Convert gameplay-camera rotation to a forward unit vector
local function rotToDir(rot)
    local rz     = math.rad(rot.z)
    local rx     = math.rad(rot.x)
    local cosRx  = math.abs(math.cos(rx))
    return vector3(
        -math.sin(rz) * cosRx,
         math.cos(rz) * cosRx,
         math.sin(rx)
    )
end

local function notify(msg)
    TriggerEvent('chat:addMessage', { args = { '[admin]', msg } })
end

local function enableNoclip()
    noclipOn = true
    local ped = PlayerPedId()
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    notify('~g~Noclip ON~w~  |  WASD = move  |  Space = up  |  Ctrl = down  |  Shift = fast')
end

local function disableNoclip()
    noclipOn = false
    local ped = PlayerPedId()
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    notify('~r~Noclip OFF')
end

RegisterNetEvent('cnr:client:toggleNoclip')
AddEventHandler('cnr:client:toggleNoclip', function()
    if noclipOn then disableNoclip() else enableNoclip() end
end)

CreateThread(function()
    while true do
        if noclipOn then
            Wait(0)
            local ped   = PlayerPedId()
            local spd   = IsControlPressed(0, 21) and (BASE_SPEED * 6.0) or BASE_SPEED
            local fwd   = rotToDir(GetGameplayCamRot(2))
            local right = vector3(fwd.y, -fwd.x, 0.0)

            local dx, dy, dz = 0.0, 0.0, 0.0

            if IsControlPressed(0, 32) then  -- W  / left-stick forward
                dx = dx + fwd.x * spd; dy = dy + fwd.y * spd; dz = dz + fwd.z * spd
            end
            if IsControlPressed(0, 33) then  -- S  / left-stick back
                dx = dx - fwd.x * spd; dy = dy - fwd.y * spd; dz = dz - fwd.z * spd
            end
            if IsControlPressed(0, 34) then  -- A  / left-stick left
                dx = dx - right.x * spd; dy = dy - right.y * spd
            end
            if IsControlPressed(0, 35) then  -- D  / left-stick right
                dx = dx + right.x * spd; dy = dy + right.y * spd
            end
            if IsControlPressed(0, 22) then dz = dz + spd end  -- Space / jump = up
            if IsControlPressed(0, 36) then dz = dz - spd end  -- Ctrl  / duck = down

            -- Apply position delta (works on frozen entities)
            if dx ~= 0.0 or dy ~= 0.0 or dz ~= 0.0 then
                local p = GetEntityCoords(ped)
                SetEntityCoords(ped, p.x + dx, p.y + dy, p.z + dz, false, false, false, false)
            end

            -- Suppress GTA's own movement and kill any residual velocity
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        else
            Wait(200)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if noclipOn then disableNoclip() end
end)
