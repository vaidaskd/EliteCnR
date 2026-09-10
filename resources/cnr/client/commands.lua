CnR = CnR or {}

local HELP_SECTIONS = {
    {
        title = 'Overview',
        lines = {
            'Cops & Robbers — choose a side at spawn.',
            'Cops earn credits by arresting and killing wanted robbers; spend them on gear.',
            'Robbers earn cash by robbing stores ($2,000) and banks ($5,000).',
        },
    },
    {
        title = 'Robberies',
        lines = {
            'Aim a weapon at a store cashier or bank teller for 1s to begin.',
            'You must stay near the cashier/teller for 60 seconds for full payout.',
            'Leaving the area early gives a partial payout based on time held.',
            'Starting a robbery marks you WANTED (red blip) until arrested or new-life.',
        },
    },
    {
        title = 'Wanted & Crimes',
        lines = {
            'Killing a player: +2 minutes jail (cops killing innocents are kicked).',
            'Shooting at a cop while innocent: +1 minute jail and become WANTED.',
            'Stealing a police vehicle: +1 minute jail and become WANTED.',
        },
    },
    {
        title = 'Arrests',
        lines = {
            'Cops: walk within 1.5m of a wanted robber and press C to cuff.',
            'Drag or drive the suspect to the Mission Row arrest point.',
            'Delivery rewards $1,000 cash and 2.0 XP for the cop.',
        },
    },
    {
        title = 'Jail',
        lines = {
            'Under 2 minutes: held at Mission Row cells.',
            '2 minutes or more: sent to Bolingbroke Penitentiary.',
            'On release: pistol with 100 rounds, cash reset to $0.',
        },
    },
    {
        title = 'Commands',
        lines = {
            '/help — this menu.',
            '/newlife — wipe progression and reselect a team.',
            '/report <id> <reason> — submit a player report to admins.',
        },
    },
}

CnR.Commands = CnR.Commands or {}

-- Open the full-screen HTML Server Guide (left-nav, scrollable — no cut-off text).
-- Replaces the old cramped native menu.
function CnR.Commands.openHelp()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'help' })
end

RegisterCommand('help', CnR.Commands.openHelp, false)

RegisterCommand('newlife', function()
    if CnR.NativeMenus and CnR.NativeMenus.openNewLifeConfirm then
        CnR.NativeMenus.openNewLifeConfirm()
    end
end, false)

-- ── Admin gate ──────────────────────────────────────────────────────────────
-- The server tells us whether this player is staff (ACE-allowed). Dev/debug commands
-- are then no-ops for everyone else, so players only ever have /newlife and /help.
CnR.IsAdmin = CnR.IsAdmin or false
RegisterNetEvent('cnr:client:setAdmin', function(v) CnR.IsAdmin = v and true or false end)
CreateThread(function()
    Wait(2500)
    TriggerServerEvent('cnr:server:checkAdmin')
end)

local function adminOnly(name, fn)
    RegisterCommand(name, function(src, args, raw)
        if not CnR.IsAdmin then
            TriggerEvent('chat:addMessage', { args = { '[cnr]', 'That command is staff-only.' } })
            return
        end
        fn(src, args, raw)
    end, false)
end

adminOnly('cnrmodel', function()
    local model = GetEntityModel(PlayerPedId())
    local name = 'unknown'
    if model == `mp_m_freemode_01` then
        name = 'mp_m_freemode_01'
    elseif model == `mp_f_freemode_01` then
        name = 'mp_f_freemode_01'
    end
    TriggerEvent('chat:addMessage', {
        args = { '[cnr]', ('Current player model: %s (%s)'):format(name, model) }
    })
end, false)

adminOnly('coords', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    TriggerEvent('chat:addMessage', {
        args = {
            '[coords]',
            ('x=%.4f, y=%.4f, z=%.4f, h=%.4f'):format(pos.x, pos.y, pos.z, heading)
        }
    })
end, false)

-- Interactive probe to find the prison jumpsuit slot. Streamed clothing appends at
-- high runtime drawable indices (NOT the filename numbers), so scan visually:
--   /prisonfit  toggles probe mode (use on a freemode ped).
--   Left/Right arrow = drawable -/+ (hold to scan fast)
--   Up/Down arrow    = texture  -/+
--   G                = switch between TOP (comp 11) and LEGS (comp 4)
-- Watch yourself until the orange jumpsuit appears, note the on-screen numbers,
-- and report them to put in Config.Jail.prisonOutfit.
local probe = { active = false, comp = 11, drawable = 0, texture = 0, lastStep = 0 }

local function probeApply()
    local ped = PlayerPedId()
    -- Keep the chosen texture within range for whatever drawable we're on.
    local maxT = GetNumberOfPedTextureVariations(ped, probe.comp, probe.drawable)
    local tex = math.max(0, math.min(probe.texture, math.max(0, maxT - 1)))
    -- Plain apply for responsive sweeping (these retexture existing garments, so no
    -- preload wait needed). The jail uses SetComponentEUP for the final outfit.
    SetPedComponentVariation(ped, probe.comp, probe.drawable, tex, 0)
end

adminOnly('prisonfit', function()
    probe.active = not probe.active
    if probe.active then probeApply() end
end, false)

CreateThread(function()
    while true do
        if not probe.active then
            Wait(300)
        else
            Wait(0)
            local ped = PlayerPedId()
            local maxD = math.max(1, GetNumberOfPedDrawableVariations(ped, probe.comp))
            local maxT = math.max(1, GetNumberOfPedTextureVariations(ped, probe.comp, probe.drawable))

            SetTextFont(4); SetTextScale(0.45, 0.45); SetTextColour(255, 230, 80, 255); SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(
                ('PRISONFIT  %s   drawable %d / %d   texture %d / %d~n~[<- ->] drawable   [up/down] texture   [G] top/legs   /prisonfit close')
                :format(probe.comp == 11 and 'TOP(11)' or 'LEGS(4)', probe.drawable, maxD - 1, probe.texture, maxT - 1))
            EndTextCommandDisplayText(0.28, 0.02)

            DisableControlAction(0, 174, true); DisableControlAction(0, 175, true)
            DisableControlAction(0, 172, true); DisableControlAction(0, 173, true)

            local now = GetGameTimer()
            local fast = (now - probe.lastStep) > 110
            local changed = false
            if IsDisabledControlJustPressed(0, 175) or (IsDisabledControlPressed(0, 175) and fast) then probe.drawable = (probe.drawable + 1) % maxD; changed = true end
            if IsDisabledControlJustPressed(0, 174) or (IsDisabledControlPressed(0, 174) and fast) then probe.drawable = (probe.drawable - 1) % maxD; changed = true end
            if IsDisabledControlJustPressed(0, 172) or (IsDisabledControlPressed(0, 172) and fast) then probe.texture = (probe.texture + 1) % maxT; changed = true end
            if IsDisabledControlJustPressed(0, 173) or (IsDisabledControlPressed(0, 173) and fast) then probe.texture = (probe.texture - 1) % maxT; changed = true end
            if IsControlJustPressed(0, 47) then  -- G: switch component
                probe.comp = (probe.comp == 11) and 4 or 11
                probe.drawable = 0; probe.texture = 0; changed = true
            end
            if changed then probe.lastStep = now; probeApply() end
        end
    end
end)

-- Capture the current ped's clothing components so an LSPD_EUP (or any) look worn
-- via vMenu's clothing menu can be turned into a Config.Outfits entry. Dress up,
-- then /capoutfit — it prints a ready-to-paste outfit block to chat + F8 console.
adminOnly('capoutfit', function()
    local ped = PlayerPedId()
    local function d(c) return GetPedDrawableVariation(ped, c) end
    local function t(c) return GetPedTextureVariation(ped, c) end
    local function pd(p) return GetPedPropIndex(ped, p) end
    local function pt(p) return GetPedPropTextureIndex(ped, p) end

    local block = ({
        '{ -- captured outfit (component = drawable/texture)',
        ('    top = %d, topTxt = %d,           -- jbib (11)'):format(d(11), t(11)),
        ('    pants = %d, pantsTxt = %d,        -- lowr (4)'):format(d(4), t(4)),
        ('    shoes = %d, shoesTxt = %d,        -- feet (6)'):format(d(6), t(6)),
        ('    undershirt = %d, undershirtTxt = %d, -- accs (8)'):format(d(8), t(8)),
        ('    arms = %d, armsTxt = %d,          -- uppr (3)'):format(d(3), t(3)),
        ('    decl = %d, declTxt = %d,          -- badge (10)'):format(d(10), t(10)),
        ('    mask = %d, maskTxt = %d,          -- (1)'):format(d(1), t(1)),
        ('    accessory = %d, accessoryTxt = %d, -- teef (7)'):format(d(7), t(7)),
        ('    hat = %d, hatTxt = %d,            -- prop 0'):format(pd(0), pt(0)),
        ('    glasses = %d, glassesTxt = %d,    -- prop 1'):format(pd(1), pt(1)),
        ('    watch = %d, watchTxt = %d,        -- prop 6'):format(pd(6), pt(6)),
        '}',
    })
    for _, line in ipairs(block) do
        print('[capoutfit] ' .. line)
        TriggerEvent('chat:addMessage', { args = { '[capoutfit]', line } })
    end
end, false)

-- Capture the current ped's clothing as a Config.RobberOutfits entry. Dress a freemode ped
-- (e.g. via vMenu) until it renders correctly, then /caprobber prints a ready-to-paste
-- line to chat + F8. Paste it into the matching gender list in config.lua.
adminOnly('caprobber', function()
    local ped = PlayerPedId()
    local function d(c) return GetPedDrawableVariation(ped, c) end
    local function t(c) return GetPedTextureVariation(ped, c) end
    local line = ("{ name = 'New Style', top = %d, topTxt = %d, arms = %d, undershirt = %d, undershirtTxt = %d, pants = %d, pantsTxt = %d, shoes = %d, shoesTxt = %d },")
        :format(d(11), t(11), d(3), d(8), t(8), d(4), t(4), d(6), t(6))
    print('[caprobber] ' .. line)
    TriggerEvent('chat:addMessage', { args = { '[caprobber]', line } })
end, false)

-- Open the free-form clothing customizer (old creator's clothing sliders) to browse
-- looks and capture them with /caprobber. Separate from the spawn character creator.
adminOnly('outfitlab', function()
    if CnR.NativeMenus and CnR.NativeMenus.openOutfitLab then
        CnR.NativeMenus.openOutfitLab()
    end
end, false)

RegisterNetEvent('cnr:client:openHelp', function()
    CnR.Commands.openHelp()
end)

-- Livery finder: sit in a vehicle and run /livery <n> to set that livery, or /livery with
-- no number to print how many liveries it has + the current one. Use this to find the
-- index of the look you want (e.g. the black LEO RCV), then tell it to lock in config.
adminOnly('livery', function(_, args)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        TriggerEvent('chat:addMessage', { args = { '[livery]', 'Get in a vehicle first.' } })
        return
    end
    SetVehicleModKit(veh, 0)
    local count = GetVehicleLiveryCount(veh)
    local n = tonumber(args[1])
    if n then
        SetVehicleLivery(veh, n)
        if GetNumVehicleMods(veh, 48) > 0 then SetVehicleMod(veh, 48, n, false) end
    end
    local msg = ('liveries: %d (0..%d) · current: %d'):format(count, math.max(0, count - 1), GetVehicleLivery(veh))
    print('[livery] ' .. msg)
    TriggerEvent('chat:addMessage', { args = { '[livery]', msg } })
end, false)

-- Paint-color finder: sit in a vehicle and run /color <primary> [secondary] to set the
-- paint. GTA colour 0 = Metallic Black, 12 = Matte Black. Find the look you want, then
-- lock it in Config.VehicleColor. /color alone prints the current colours.
adminOnly('color', function(_, args)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        TriggerEvent('chat:addMessage', { args = { '[color]', 'Get in a vehicle first.' } })
        return
    end
    local p = tonumber(args[1])
    local s = tonumber(args[2]) or p
    SetVehicleModKit(veh, 0)
    if p then SetVehicleColours(veh, p, s) end
    local cp, cs = GetVehicleColours(veh)
    local msg = ('primary=%d  secondary=%d'):format(cp, cs)
    print('[color] ' .. msg)
    TriggerEvent('chat:addMessage', { args = { '[color]', msg } })
end, false)
