-- Custom CnR chat client. Replaces the default cfx chat:
--  • Opens a styled input bar on T (colour / emoji / GIF buttons).
--  • Renders every chat:addMessage / gfx-chat:addMessage in a transparent display.
--  • Player messages are routed through the server (cnr:chat:send) so they get the
--    role-coloured name + server ID.

local inputOpen = false

-- Command suggestions (the "/" autocomplete list). Deliberately limited to the few
-- commands a player should ever use — the old list pulled in every engine/dev command
-- (/_assert, /archetypelist, …) which cluttered the box. Staff still type their tools
-- directly; they just aren't advertised here.
local suggestions = {}   -- name -> { name, help, params }

local ALLOWED = {
    ['/newlife'] = 'Reset your progress and pick a side again',
    ['/help']    = 'Open the server guide',
    ['/report']  = 'Report a player to staff',
}

local function buildSuggestionList()
    local out = {}
    for name, help in pairs(ALLOWED) do
        out[#out + 1] = { name = name, help = help }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function pushSuggestions()
    SendNUIMessage({ type = 'suggestions', list = buildSuggestionList() })
end

local function openChat()
    if inputOpen then return end
    inputOpen = true
    pushSuggestions()
    SetNuiFocus(true, true)               -- keyboard + mouse, so the colour/emoji tools are clickable
    -- Tell the NUI whether this player is a cop, so the POLICE RADIO channel is only
    -- offered to officers.
    local isCop = (LocalPlayer and LocalPlayer.state and LocalPlayer.state.cnrSide == 'cop') or false
    SendNUIMessage({ type = 'openInput', isCop = isCop })
end

RegisterCommand('cnr_openchat', function()
    openChat()
end, false)
RegisterKeyMapping('cnr_openchat', 'Open chat', 'keyboard', 'T')

-- Send / cancel from the NUI
RegisterNUICallback('cnr_chat:send', function(data, cb)
    inputOpen = false
    SetNuiFocus(false, false)
    local msg = tostring((data and data.text) or '')
    if msg ~= '' then
        if msg:sub(1, 1) == '/' then
            ExecuteCommand(msg:sub(2))
        else
            TriggerServerEvent('cnr:chat:send', {
                text    = msg,
                color   = data and data.color,
                channel = data and data.channel or 'global',
            })
        end
    end
    cb('ok')
end)

RegisterNUICallback('cnr_chat:close', function(_, cb)
    inputOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Join/leave announcements are shown ONLY in the cnr game feed (role-coloured), so any
-- chat-channel "<name> joined/left the server" line is a duplicate and is suppressed here.
-- This catches it no matter which resource emits it. Player chat (message.cnr) is never
-- touched. #1
local function isJoinLeaveAnnounce(message)
    if type(message) == 'string' then message = { args = { message } } end
    if type(message) ~= 'table' or message.cnr then return false end
    -- Gather EVERY string in the message (args + any field) so the announce is caught no
    -- matter which field holds the text or which resource emitted it.
    local parts = {}
    local function collect(v)
        if type(v) == 'string' then
            parts[#parts + 1] = v
        elseif type(v) == 'table' then
            for _, x in pairs(v) do if type(x) == 'string' then parts[#parts + 1] = x end end
        end
    end
    collect(message.args); collect(message.message); collect(message.text); collect(message.name)
    local s = table.concat(parts, ' '):lower()
    return s:find('joined the server', 1, true) ~= nil
        or s:find('left the server', 1, true) ~= nil
        or s:find('joined the game', 1, true) ~= nil
        or s:find('left the game', 1, true) ~= nil
        or s:find(' joined.', 1, true) ~= nil      -- default cfx chat "* name joined."
        or s:find(' left (', 1, true) ~= nil       -- default cfx chat "* name left (reason)"
        or s:find('connected', 1, true) ~= nil
        or s:find('disconnected', 1, true) ~= nil
end

-- Render incoming messages (covers all existing chat:addMessage / gfx-chat:addMessage callers)
RegisterNetEvent('chat:addMessage', function(message)
    if isJoinLeaveAnnounce(message) then return end
    SendNUIMessage({ type = 'addMessage', message = message })
end)
RegisterNetEvent('gfx-chat:addMessage', function(message)
    if isJoinLeaveAnnounce(message) then return end
    SendNUIMessage({ type = 'addMessage', message = message })
end)
RegisterNetEvent('chat:clear', function()
    SendNUIMessage({ type = 'clear' })
end)
RegisterCommand('clear', function()
    SendNUIMessage({ type = 'clear' })
end, false)

-- The legacy chat:addMessage path expects these events to exist.
RegisterNetEvent('chatMessage')
RegisterNetEvent('chat:addSuggestion')
RegisterNetEvent('chat:addSuggestions')
RegisterNetEvent('chat:removeSuggestion')
RegisterNetEvent('chat:addTemplate')

-- Collect command suggestions other resources register, and forward them to the NUI.
AddEventHandler('chat:addSuggestion', function(name, help, params)
    if type(name) == 'string' then
        suggestions[name] = { name = name, help = help or '', params = params }
        if inputOpen then pushSuggestions() end
    end
end)
AddEventHandler('chat:addSuggestions', function(list)
    if type(list) == 'table' then
        for _, s in ipairs(list) do
            if type(s) == 'table' and s.name then
                suggestions[s.name] = { name = s.name, help = s.help or '', params = s.params }
            end
        end
        if inputOpen then pushSuggestions() end
    end
end)
AddEventHandler('chat:removeSuggestion', function(name)
    if name and suggestions[name] then
        suggestions[name] = nil
        if inputOpen then pushSuggestions() end
    end
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetTextChatEnabled(false)
end)