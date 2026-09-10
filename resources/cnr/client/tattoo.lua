CnR = CnR or {}
CnR.Tattoo = CnR.Tattoo or {}

-- Catalog ids the player currently owns (kept in sync by the server).
local ownedIds = {}

local function overlayHashes(id, ped)
    local t = Config and Config.Tattoos and Config.Tattoos[id]
    if not t or not t.collection then return nil end
    local overlay = (IsPedMale(ped) and t.male) or t.female or t.male
    if not overlay then return nil end
    return GetHashKey(t.collection), GetHashKey(overlay)
end

-- Clear every tattoo and re-apply the given list of catalog ids (gender-resolved).
local function applyList(ids)
    local ped = PlayerPedId()
    if ped == 0 then return end
    ClearPedDecorations(ped)
    for _, id in ipairs(ids or {}) do
        local col, ov = overlayHashes(id, ped)
        if col then AddPedDecorationFromHashes(ped, col, ov) end
    end
end

-- Re-apply only the owned tattoos (called on spawn and when a preview is cancelled).
function CnR.Tattoo.reapply()
    applyList(ownedIds)
end

-- ── Clothing strip for preview ──────────────────────────────────────────────
-- When previewing a tattoo we temporarily remove the clothing that covers that body
-- area so the design is visible, then restore the player's outfit afterwards.
local COVER_COMPS = { top = { 11, 3, 8 }, pants = { 4 } }   -- components each slot covers
local clothSnap = nil   -- captured outfit while a preview session is active

-- Capture the player's real outfit ONCE per preview session.
local function snapshotClothes(ped)
    if clothSnap then return end
    clothSnap = {}
    for _, c in ipairs({ 11, 3, 8, 4 }) do
        clothSnap[c] = { d = GetPedDrawableVariation(ped, c), t = GetPedTextureVariation(ped, c) }
    end
end

-- Put the captured outfit back on (does NOT end the session).
local function applySnapshot(ped)
    if not clothSnap then return end
    for c, v in pairs(clothSnap) do
        SetPedComponentVariation(ped, c, v.d, v.t, 0)
    end
end

-- Bare the components a tattoo slot covers (drawable 15 = "none" on freemode peds).
local function bareSlot(ped, cover)
    local comps = COVER_COMPS[cover]
    if not comps then return end
    for _, c in ipairs(comps) do
        SetPedComponentVariation(ped, c, 15, 0, 0)
    end
end

-- Live preview: reset to the real outfit, strip the area this tattoo sits on, then show
-- the owned tattoos + the highlighted design.
function CnR.Tattoo.preview(id)
    local ped = PlayerPedId()
    if ped == 0 then return end
    snapshotClothes(ped)     -- capture real outfit once
    applySnapshot(ped)       -- undo any previous strip
    local t = Config and Config.Tattoos and Config.Tattoos[id]
    if t and t.cover then bareSlot(ped, t.cover) end

    ClearPedDecorations(ped)
    for _, owned in ipairs(ownedIds) do
        local col, ov = overlayHashes(owned, ped)
        if col then AddPedDecorationFromHashes(ped, col, ov) end
    end
    local col, ov = overlayHashes(id, ped)
    if col then AddPedDecorationFromHashes(ped, col, ov) end
end

function CnR.Tattoo.cancelPreview()
    local ped = PlayerPedId()
    if ped ~= 0 then applySnapshot(ped) end   -- restore the outfit
    clothSnap = nil                           -- end the session
    applyList(ownedIds)
end

-- Server is authoritative on what the player owns.
RegisterNetEvent('cnr:client:applyTattoos', function(list)
    ownedIds = {}
    if type(list) == 'table' then
        for _, id in ipairs(list) do
            local n = tonumber(id)
            if n then ownedIds[#ownedIds + 1] = n end
        end
    end
    applyList(ownedIds)
end)

RegisterNetEvent('cnr:client:openTattooShop', function(payload)
    if CnR.NativeMenus and CnR.NativeMenus.openTattooShop then
        CnR.NativeMenus.openTattooShop(payload or {})
    end
end)

-- Map blips for every parlor (sprite 75 = tattoo icon).
CreateThread(function()
    for _, p in ipairs((Config and Config.TattooParlors) or {}) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 75)
        SetBlipColour(b, 7)        -- purple
        SetBlipScale(b, 0.85)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Tattoo Parlor')
        EndTextCommandSetBlipName(b)
    end
end)

-- Proximity interaction: press E at a parlor to open the shop.
CreateThread(function()
    while true do
        local wait = 600
        local ped = PlayerPedId()
        if ped ~= 0 and Config and Config.TattooParlors then
            local pc = GetEntityCoords(ped)
            local near = false
            for _, p in ipairs(Config.TattooParlors) do
                if #(pc - vector3(p.x, p.y, p.z)) < 2.5 then near = true; break end
            end
            if near then
                wait = 0
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to get a tattoo')
                EndTextCommandDisplayHelp(0, false, false, -1)
                if IsControlJustReleased(0, 38) then   -- E
                    TriggerServerEvent('cnr:server:requestTattooShop')
                end
            end
        end
        Wait(wait)
    end
end)

-- Pull the player's saved tattoos shortly after this script starts (covers reconnects).
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('cnr:server:requestTattoos')
end)
