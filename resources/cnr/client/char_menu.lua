
CnR = CnR or {}
CnR.CharMenu = CnR.CharMenu or {}

local pool = CnR.NativeUI.pool
local charMenuOpen = false
local creatorState = {}
local sliderHandlers = {}

-- Curated, free-mix clothing for the current gender (top/bottom/shoes lists). nil when a
-- gender has no curated set yet (in that case we fall back to the preset outfit system).
local function clothingPool(gender)
    return (Config and Config.RobberClothing and Config.RobberClothing[gender]) or nil
end

local function indexOf(list, val, default)
    if list and val ~= nil then
        for i = 1, #list do if list[i] == val then return i end end
    end
    return default or 1
end

-- Highest valid texture index for a component's drawable on the current ped. Beyond this
-- GTA shows the checkerboard "missing texture", so selectors clamp to it.
local function maxTexFor(comp, drawable)
    local n = GetNumberOfPedTextureVariations(PlayerPedId(), comp, drawable or 0)
    return (n and n > 0) and (n - 1) or 0
end

-- Valid top texture indices for a top drawable: 0..count minus the configured blacklist
-- (the freemode model over-reports its texture count, so some indices are checkerboard).
local function allowedTopTex(cp, drawable)
    local maxTex = GetNumberOfPedTextureVariations(PlayerPedId(), 11, drawable or 0)
    maxTex = (maxTex and maxTex > 0) and math.min(15, maxTex - 1) or 15
    local blset = {}
    local bl = cp and cp.topTexBlacklist and cp.topTexBlacklist[drawable]
    if bl then for _, t in ipairs(bl) do blset[t] = true end end
    local out = {}
    for t = 0, maxTex do if not blset[t] then out[#out + 1] = t end end
    if #out == 0 then out = { 0 } end
    return out
end

local function robberOutfitPool()
    return (Config and Config.RobberOutfits and Config.RobberOutfits[creatorState.gender]) or {}
end

-- Apply a numbered outfit (1..N) from the preset gender pool into the working state.
local function applyRobberOutfit(idx)
    local p = robberOutfitPool()
    if #p == 0 then return end
    idx = ((tonumber(idx) or 1) - 1) % #p + 1
    creatorState.outfitIndex   = idx
    local o = p[idx]
    creatorState.top           = o.top or 0
    creatorState.topTxt        = o.topTxt or 0
    creatorState.arms          = o.arms or 0
    creatorState.undershirt    = o.undershirt or 0
    creatorState.undershirtTxt = o.undershirtTxt or 0
    creatorState.pants         = o.pants or 0
    creatorState.pantsTxt      = o.pantsTxt or 0
    creatorState.shoes         = o.shoes or 0
    creatorState.shoesTxt      = o.shoesTxt or 0
end

local function randomRobberOutfit()
    local p = robberOutfitPool()
    applyRobberOutfit(math.random(1, math.max(1, #p)))
end

-- Resolve the curated top/bottom/shoes selection (by list index) into component fields.
local function applyClothingSelection()
    local cp = clothingPool(creatorState.gender)
    if not cp then return end
    creatorState.arms          = cp.arms or 0
    creatorState.undershirt    = cp.undershirt or 15
    creatorState.undershirtTxt = cp.undershirtTxt or 0
    creatorState.top   = (cp.tops  and cp.tops[creatorState.topIdx])   or (cp.tops  and cp.tops[1])  or 0
    creatorState.pants = (cp.pants and cp.pants[creatorState.pantsIdx]) or (cp.pants and cp.pants[1]) or 0
    creatorState.shoes = (cp.shoes and cp.shoes[creatorState.shoesIdx]) or (cp.shoes and cp.shoes[1]) or 0
end

local function buildSkinTable()
    return {
        isCustom = true,
        gender = creatorState.gender,
        father = creatorState.father,
        mother = creatorState.mother,
        shapeMix = creatorState.shapeMix,
        skinMix = creatorState.skinMix,
        eyes = creatorState.eyes,
        hair = creatorState.hair,
        hairColor = creatorState.hairColor,
        beard = creatorState.beard,
        beardColor = creatorState.beardColor,
        outfitIndex = creatorState.outfitIndex,
        top = creatorState.top,
        topTxt = creatorState.topTxt,
        pants = creatorState.pants,
        pantsTxt = creatorState.pantsTxt,
        shoes = creatorState.shoes,
        shoesTxt = creatorState.shoesTxt,
        arms = creatorState.arms,
        undershirt = creatorState.undershirt,
        undershirtTxt = creatorState.undershirtTxt,
        -- The spawn creator never equips cosmetics — those come only from the clothing
        -- store. Declare them as "none" so deploying can't carry over or apply a hat /
        -- glasses / watch / mask.
        hat = -1, hatTxt = 0,
        glasses = -1, glassesTxt = 0,
        watch = -1, watchTxt = 0,
        mask = 0, maskTxt = 0,
    }
end

local function pushPreview()
    if CnR.Spawn and CnR.Spawn.previewCustom then
        CnR.Spawn.previewCustom(buildSkinTable(), creatorState.side)
    end
end

local function resetCreatorDefaults(side, savedSkin)
    creatorState.side = side
    local skin = (type(savedSkin) == 'table' and savedSkin.isCustom) and savedSkin or {}
    creatorState.gender = (skin.gender == 'female') and 'female' or 'male'
    creatorState.father = tonumber(skin.father) or 0
    creatorState.mother = tonumber(skin.mother) or 0
    creatorState.shapeMix = tonumber(skin.shapeMix) or 0.5
    creatorState.skinMix = tonumber(skin.skinMix) or 0.5
    creatorState.eyes = tonumber(skin.eyes) or 0
    creatorState.hair = tonumber(skin.hair) or 4
    creatorState.hairColor = tonumber(skin.hairColor) or 2
    creatorState.beard = creatorState.gender == 'female' and 0 or (tonumber(skin.beard) or 0)
    creatorState.beardColor = tonumber(skin.beardColor) or 0
    creatorState.top = tonumber(skin.top) or 1
    creatorState.topTxt = tonumber(skin.topTxt) or 0
    creatorState.pants = tonumber(skin.pants) or 1
    creatorState.pantsTxt = tonumber(skin.pantsTxt) or 0
    creatorState.shoes = tonumber(skin.shoes) or 1
    creatorState.shoesTxt = tonumber(skin.shoesTxt) or 0
    creatorState.arms = tonumber(skin.arms) or 0
    creatorState.undershirt = tonumber(skin.undershirt) or 0
    creatorState.undershirtTxt = tonumber(skin.undershirtTxt) or 0
    -- Robbers dress themselves. With a curated set (currently male) they free-mix
    -- top/bottom/shoes + textures; otherwise they fall back to numbered preset outfits.
    if side == 'robber' then
        local cp = clothingPool(creatorState.gender)
        if cp then
            creatorState.topIdx   = indexOf(cp.tops,  tonumber(skin.top),   1)
            creatorState.pantsIdx = indexOf(cp.pants, tonumber(skin.pants), 1)
            creatorState.shoesIdx = indexOf(cp.shoes, tonumber(skin.shoes), 1)
            applyClothingSelection()
        else
            local n = #robberOutfitPool()
            creatorState.outfitIndex = tonumber(skin.outfitIndex) or (n > 0 and math.random(1, n)) or 1
            applyRobberOutfit(creatorState.outfitIndex)
        end
    end
    creatorState.station = 'missionRow'
end

local function randomizeCreator()
    -- Randomize appearance (gender stays) and, for robbers, also the outfit.
    creatorState.father = math.random(0, 23)
    creatorState.mother = math.random(0, 21)
    creatorState.shapeMix = math.random()
    creatorState.skinMix = math.random()
    creatorState.eyes = math.random(0, 31)
    creatorState.hair = math.random(0, 74)
    creatorState.hairColor = math.random(0, 63)
    creatorState.beard = creatorState.gender == 'male' and math.random(0, 28) or 0
    creatorState.beardColor = math.random(0, 12)
    if creatorState.side == 'robber' then
        local cp = clothingPool(creatorState.gender)
        if cp then
            -- Mix everything: random shirt, bottoms and shoes, each with a random valid
            -- texture (tops skip blacklisted/checkerboard textures).
            creatorState.topIdx   = math.random(1, #cp.tops)
            creatorState.pantsIdx = math.random(1, #cp.pants)
            creatorState.shoesIdx = math.random(1, #cp.shoes)
            applyClothingSelection()
            local topAllowed = allowedTopTex(cp, creatorState.top)
            creatorState.topTxt   = topAllowed[math.random(1, #topAllowed)]
            creatorState.pantsTxt = math.random(0, maxTexFor(4, creatorState.pants))
            creatorState.shoesTxt = math.random(0, maxTexFor(6, creatorState.shoes))
        else
            randomRobberOutfit()
        end
    end
end

local function addSlider(menu, label, minVal, maxVal, current, onChange)
    local values = {}
    for i = minVal, maxVal do values[#values + 1] = i end
    local idx = math.max(1, math.min(#values, (current - minVal) + 1))
    local slider = NativeUI.CreateSliderItem(label, values, idx, false)
    menu:AddItem(slider)
    sliderHandlers[slider] = onChange
    return slider
end

local function numberLabels(n)
    local out = {}
    for i = 1, math.max(1, n) do out[i] = tostring(i) end
    return out
end

-- ── Custom bottom-bar hint ──────────────────────────────────────────────────────
-- Drawn as plain text (NativeUI's own button bar is disabled below). GTA's instructional
-- button glyphs for the arrow keys are unreliable — they render blank, and the accept glyph
-- flips to a mouse icon while the camera is being moved. Words are 100% reliable, spell out
-- exactly which keys to use, and never show a mouse. #charmenu
local function drawCreatorHint()
    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString('Up / Down Arrows: Navigate      Left / Right Arrows: Adjust      Enter: Confirm')
    DrawText(0.5, 0.945)
end

-- Builds and shows the creator menu from the current creatorState. Re-callable so a
-- gender change can rebuild the menu with the right clothing controls for that gender.
local function buildAndShow(side)
    sliderHandlers = {}
    local deploying = false
    pushPreview()

    local title = side == 'cop' and 'Police Recruit' or 'Robber Character'
    local menu = NativeUI.CreateMenu('Character Creator', title)
    pool:Add(menu)
    -- NativeUI disables all controls each frame while a menu is open. Keep the chat keys
    -- enabled so players can open chat and run /caprobber to record the current outfit.
    menu:AddEnabledControl(0, 245)  -- INPUT_MP_TEXT_CHAT_ALL (T)
    menu:AddEnabledControl(0, 246)  -- INPUT_MP_TEXT_CHAT_TEAM (Y)
    -- Character creation is mandatory, so there is no "back" out of it. Disabling the Back
    -- control makes the RIGHT mouse button (INPUT_FRONTEND_CANCEL / 177, which NativeUI's
    -- GoBack listens for) a no-op — matching the left button — and drops the "Back"/backspace
    -- hint from the bottom bar. #charmenu
    menu.Controls.Back.Enabled = false
    -- Keyboard-driven creator: turn off NativeUI's mouse cursor and its own instructional bar
    -- so we can draw our own (Navigate ↑↓ / Adjust ←→ / Confirm Enter) with pure key glyphs
    -- and no mouse icon. #charmenu
    menu.Settings.MouseControlsEnabled = false
    menu.Settings.MouseEdgeEnabled = false
    menu.Settings.InstructionalButtons = false
    charMenuOpen = true

    CreateThread(function()
        while charMenuOpen do
            DisableControlAction(0, 25, true)   -- INPUT_AIM (right mouse)
            DisableControlAction(0, 24, true)   -- INPUT_ATTACK (left mouse — prevent stray clicks)
            drawCreatorHint()
            Wait(0)
        end
    end)

    local heritage = NativeUI.CreateHeritageWindow(creatorState.mother, creatorState.father)
    menu:AddWindow(heritage)

    local genderItem = NativeUI.CreateListItem('Gender', { 'Male', 'Female' }, creatorState.gender == 'female' and 2 or 1)
    menu:AddItem(genderItem)

    -- Station selector (cop only), kept near the top so it's reachable without scrolling.
    local stationItem
    if side == 'cop' then
        local savedStationIdx = (creatorState.station == 'vespucci') and 2 or 1
        stationItem = NativeUI.CreateListItem('Spawn Station', { 'Mission Row PD', 'Vespucci PD' }, savedStationIdx)
        menu:AddItem(stationItem)
    end

    addSlider(menu, 'Mother', 0, 21, creatorState.mother, function(v)
        creatorState.mother = v
        heritage:Index(creatorState.mother, creatorState.father)
    end)
    addSlider(menu, 'Father', 0, 23, creatorState.father, function(v)
        creatorState.father = v
        heritage:Index(creatorState.mother, creatorState.father)
    end)
    addSlider(menu, 'Face Mix %', 0, 100, math.floor(creatorState.shapeMix * 100), function(v)
        creatorState.shapeMix = v / 100
    end)
    addSlider(menu, 'Skin Mix %', 0, 100, math.floor(creatorState.skinMix * 100), function(v)
        creatorState.skinMix = v / 100
    end)
    addSlider(menu, 'Hair Style', 0, 74, creatorState.hair, function(v) creatorState.hair = v end)
    addSlider(menu, 'Hair Color', 0, 63, creatorState.hairColor, function(v) creatorState.hairColor = v end)
    addSlider(menu, 'Eye Color', 0, 31, creatorState.eyes, function(v) creatorState.eyes = v end)

    -- Clothing controls (robber only). Curated set -> free top/bottom/shoes + textures.
    local outfitItem, topItem, topTexItem, pantsItem, pantsTexItem, shoesItem, shoesTexItem
    local cp = (side == 'robber') and clothingPool(creatorState.gender) or nil
    if side == 'robber' then
        addSlider(menu, 'Beard', 0, 28, creatorState.beard, function(v) creatorState.beard = v end)
        if cp then
            -- Top Texture is selected by POSITION into the allowed (non-checkerboard) list,
            -- so blacklisted textures are simply skipped.
            local topAllowed = allowedTopTex(cp, creatorState.top)
            local topPos = indexOf(topAllowed, creatorState.topTxt, 1)
            creatorState.topTxt = topAllowed[topPos]

            topItem = addSlider(menu, 'Top', 1, math.max(1, #cp.tops),
                math.max(1, math.min(#cp.tops, creatorState.topIdx or 1)), function(v)
                    creatorState.topIdx = v
                    applyClothingSelection()
                    local allowed = allowedTopTex(cp, creatorState.top)
                    local pos = indexOf(allowed, creatorState.topTxt, 1)
                    creatorState.topTxt = allowed[pos]
                    if topTexItem then topTexItem:Index(pos) end
                end)
            topTexItem = addSlider(menu, 'Top Texture', 0, 15, topPos - 1, function(v)
                local allowed = allowedTopTex(cp, creatorState.top)
                local pos = math.max(0, math.min(v, #allowed - 1))
                creatorState.topTxt = allowed[pos + 1]
                if pos ~= v and topTexItem then topTexItem:Index(pos + 1) end
            end)

            pantsItem = addSlider(menu, 'Bottoms', 1, math.max(1, #cp.pants),
                math.max(1, math.min(#cp.pants, creatorState.pantsIdx or 1)), function(v)
                    creatorState.pantsIdx = v
                    applyClothingSelection()
                    local mx = maxTexFor(4, creatorState.pants)
                    if creatorState.pantsTxt > mx then creatorState.pantsTxt = mx; if pantsTexItem then pantsTexItem:Index(mx + 1) end end
                end)
            pantsTexItem = addSlider(menu, 'Bottoms Texture', 0, 15, creatorState.pantsTxt, function(v)
                local mx = maxTexFor(4, creatorState.pants)
                if v > mx then v = mx; if pantsTexItem then pantsTexItem:Index(v + 1) end end
                creatorState.pantsTxt = v
            end)

            shoesItem = addSlider(menu, 'Shoes', 1, math.max(1, #cp.shoes),
                math.max(1, math.min(#cp.shoes, creatorState.shoesIdx or 1)), function(v)
                    creatorState.shoesIdx = v
                    applyClothingSelection()
                    local mx = maxTexFor(6, creatorState.shoes)
                    if creatorState.shoesTxt > mx then creatorState.shoesTxt = mx; if shoesTexItem then shoesTexItem:Index(mx + 1) end end
                end)
            shoesTexItem = addSlider(menu, 'Shoes Texture', 0, 15, creatorState.shoesTxt, function(v)
                local mx = maxTexFor(6, creatorState.shoes)
                if v > mx then v = mx; if shoesTexItem then shoesTexItem:Index(v + 1) end end
                creatorState.shoesTxt = v
            end)
        else
            -- No curated set for this gender yet: numbered preset outfits.
            local outfitNames = {}
            for i = 1, #robberOutfitPool() do outfitNames[i] = tostring(i) end
            if #outfitNames == 0 then outfitNames = { '1' } end
            outfitItem = NativeUI.CreateListItem('Outfit', outfitNames,
                math.max(1, math.min(#outfitNames, creatorState.outfitIndex or 1)), 'Choose a saved outfit set')
            menu:AddItem(outfitItem)
        end
    end

    local randomItem = NativeUI.CreateItem('Randomize', 'Random genetics and style')
    local deployItem = NativeUI.CreateItem('Deploy & Spawn', 'Confirm and enter the city')
    menu:AddItem(randomItem)
    menu:AddItem(deployItem)

    menu.OnSliderChange = function(_, item, index)
        local handler = sliderHandlers[item]
        if handler then
            handler(item:IndexToItem(index))
            pushPreview()
        end
    end

    menu.OnListChange = function(_, item, index)
        if item == genderItem then
            creatorState.gender = (index == 2) and 'female' or 'male'
            if creatorState.gender == 'female' then creatorState.beard = 0 end
            if side == 'robber' then
                local newCp = clothingPool(creatorState.gender)
                if newCp then
                    creatorState.topIdx   = math.max(1, math.min(#newCp.tops,  creatorState.topIdx or 1))
                    creatorState.pantsIdx = math.max(1, math.min(#newCp.pants, creatorState.pantsIdx or 1))
                    creatorState.shoesIdx = math.max(1, math.min(#newCp.shoes, creatorState.shoesIdx or 1))
                    applyClothingSelection()
                else
                    applyRobberOutfit(creatorState.outfitIndex or 1)
                end
            end
            -- Rebuild so the clothing controls match the new gender's set.
            charMenuOpen = false
            CnR.NativeUI.closeAll()
            buildAndShow(side)
        elseif outfitItem and item == outfitItem then
            applyRobberOutfit(index)
            pushPreview()
        elseif stationItem and item == stationItem then
            local idx = tonumber(index)
            local str = tostring(index or '')
            creatorState.station = (idx == 2 or str == 'Vespucci PD') and 'vespucci' or 'missionRow'
        end
    end

    menu.OnItemSelect = function(_, item)
        if item == randomItem then
            randomizeCreator()
            heritage:Index(creatorState.mother, creatorState.father)
            if cp then
                if topItem      then topItem:Index(creatorState.topIdx) end
                -- Top Texture slider is position-based over the allowed (non-blacklisted) list.
                if topTexItem   then topTexItem:Index(indexOf(allowedTopTex(cp, creatorState.top), creatorState.topTxt, 1)) end
                if pantsItem    then pantsItem:Index(creatorState.pantsIdx) end
                if pantsTexItem then pantsTexItem:Index(creatorState.pantsTxt + 1) end
                if shoesItem    then shoesItem:Index(creatorState.shoesIdx) end
                if shoesTexItem then shoesTexItem:Index(creatorState.shoesTxt + 1) end
            elseif outfitItem then
                outfitItem:Index(creatorState.outfitIndex)
            end
            pushPreview()
        elseif item == deployItem then
            deploying = true
            if stationItem then
                local idx = stationItem:Index()
                creatorState.station = (idx == 2) and 'vespucci' or 'missionRow'
            end
            TriggerServerEvent('cnr:server:setSide', {
                side = side,
                skin = buildSkinTable(),
                station = (side == 'cop') and creatorState.station or nil,
            })
            if CnR.Spawn and CnR.Spawn.exitSelectionView then
                CnR.Spawn.exitSelectionView()
            end
            menu:Visible(false)
            charMenuOpen = false
        end
    end

    local deploying = false  -- only true when Deploy & Spawn was actually clicked

    menu.OnMenuClosed = function()
        charMenuOpen = false
        if deploying then
            if CnR.Spawn and CnR.Spawn.exitSelectionView then
                CnR.Spawn.exitSelectionView()
            end
        else
            -- Closed by something other than Deploy (e.g. a stray right-click).
            -- Character creation is mandatory — reopen it instead of leaving the
            -- player stuck with no side chosen.
            CnR.NativeUI.closeAll()
            buildAndShow(side)
        end
    end

    menu:Visible(true)
    -- NativeUI's modular arithmetic: CurrentSelection(n) lands on item ((n-1) % Items)+1.
    -- For any item count, passing #Items makes (Items % Items)==0 which the getter maps to 1.
    -- Also reset pagination so the list scrolls to the top showing Gender first.
    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(#menu.Items)
end

function CnR.CharMenu.open(side, savedSkin)
    if charMenuOpen then return end
    resetCreatorDefaults(side, savedSkin)
    buildAndShow(side)
end

function CnR.CharMenu.isOpen()
    return charMenuOpen
end
