
CnR = CnR or {}
CnR.NativeMenus = CnR.NativeMenus or {}

local pool = CnR.NativeUI.pool

local function closeAll()
    if CnR.VehiclePreview then CnR.VehiclePreview.clear() end
    CnR.NativeUI.closeAll()
end


function CnR.NativeMenus.openAmmuShop(payload)
    payload = payload or {}
    closeAll()

    local menu = NativeUI.CreateMenu('Ammu-Nation', ('Cash: $%s'):format(payload.cash or 0))
    pool:Add(menu)

    local byCat = {}
    for _, it in ipairs(payload.items or {}) do
        local cat = it.category or 'Misc'
        byCat[cat] = byCat[cat] or {}
        byCat[cat][#byCat[cat] + 1] = it
    end

    local subs = {}
    for cat, items in pairs(byCat) do
        local sub = pool:AddSubMenu(menu, cat, ('Browse %s'):format(cat))
        for _, it in ipairs(items) do
            local label = it.label or it.weapon
            local desc = ('$%s'):format(it.price or 0)
            if it.ammo and it.ammo > 0 then
                desc = desc .. (' · +%s ammo'):format(it.ammo)
            end
            local row = NativeUI.CreateItem(label, desc)
            row._weapon = it.weapon
            sub:AddItem(row)
        end
        sub.OnItemSelect = function(_, item)
            if item._weapon then
                TriggerServerEvent('cnr:server:buyWeapon', { key = item._weapon })
            end
        end
        subs[#subs + 1] = sub
    end

    -- Start the main menu and every category submenu highlighted on the first row.
    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    for _, sub in ipairs(subs) do
        if #sub.Items > 0 then
            sub.Pagination.Min = 0
            sub.Pagination.Max = sub.Pagination.Total
            sub:CurrentSelection(0)
        end
    end

    menu:Visible(true)
end


function CnR.NativeMenus.openFoodShop(payload)
    payload = payload or {}
    closeAll()

    local menu = NativeUI.CreateMenu(payload.title or 'Convenience Store', ('Cash: $%s'):format(payload.cash or 0))
    pool:Add(menu)

    local defs = payload.items or {}
    local prices = payload.prices or {}
    for _, key in ipairs(payload.menu or {}) do
        local def = defs[key] or {}
        local price = prices[key] or 0
        local row = NativeUI.CreateItem(
            def.label or key,
            ('$%s · heals +%s HP'):format(price, def.heal or 0)
        )
        row._key = key
        menu:AddItem(row)
    end

    menu.OnItemSelect = function(_, item)
        if item._key then
            -- Pass the shop kind + current row so the menu can re-open in place after the
            -- purchase (updated cash, same highlighted item).
            TriggerServerEvent('cnr:server:buyItem', {
                key = item._key, kind = payload.kind, select = menu:CurrentSelection() - 1,
            })
        end
    end

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(payload.select or 0)
    menu:Visible(true)
end

function CnR.NativeMenus.openClothingShop(payload)
    payload = payload or {}
    closeAll()

    local ped    = PlayerPedId()
    local gender = payload.gender or 'male'
    -- Cops keep their uniform — at a clothing store they may only buy accessories
    -- (glasses + watches), not full outfits. Robbers get the whole wardrobe. #12
    local isCop  = (CnR.State and CnR.State.side == CnR.Sides.COP)
        or (LocalPlayer and LocalPlayer.state and LocalPlayer.state.cnrSide == 'cop')
    local cp     = (Config.RobberClothing and Config.RobberClothing[gender]) or {}
    local tops   = cp.tops  or {}
    local pants  = cp.pants or {}
    local shoes  = cp.shoes or {}
    local price  = payload.price or 0
    local prices = payload.prices or {}   -- per-item costs

    -- Snapshot the worn clothes/cosmetics so backing out without buying restores them.
    local snap = {
        top = GetPedDrawableVariation(ped, 11), topTxt = GetPedTextureVariation(ped, 11),
        pants = GetPedDrawableVariation(ped, 4), pantsTxt = GetPedTextureVariation(ped, 4),
        shoes = GetPedDrawableVariation(ped, 6), shoesTxt = GetPedTextureVariation(ped, 6),
        arms = GetPedDrawableVariation(ped, 3),
        undershirt = GetPedDrawableVariation(ped, 8), undershirtTxt = GetPedTextureVariation(ped, 8),
        mask = GetPedDrawableVariation(ped, 1), maskTxt = GetPedTextureVariation(ped, 1),
        hat = GetPedPropIndex(ped, 0), hatTxt = GetPedPropTextureIndex(ped, 0),
        glasses = GetPedPropIndex(ped, 1), glassesTxt = GetPedPropTextureIndex(ped, 1),
        watch = GetPedPropIndex(ped, 6), watchTxt = GetPedPropTextureIndex(ped, 6),
    }

    local function idxOf(list, val)
        for i = 1, #list do if list[i] == val then return i end end
        return 1
    end
    local cur = payload.current or {}
    local sel = {
        topIdx   = idxOf(tops, cur.top),     topTxt   = tonumber(cur.topTxt)   or 0,
        pantsIdx = idxOf(pants, cur.pants),  pantsTxt = tonumber(cur.pantsTxt) or 0,
        shoesIdx = idxOf(shoes, cur.shoes),  shoesTxt = tonumber(cur.shoesTxt) or 0,
        hat = tonumber(cur.hat) or -1, hatTxt = tonumber(cur.hatTxt) or 0,
        glasses = tonumber(cur.glasses) or -1, glassesTxt = tonumber(cur.glassesTxt) or 0,
        watch = tonumber(cur.watch) or -1, watchTxt = tonumber(cur.watchTxt) or 0,
        mask = tonumber(cur.mask) or 0, maskTxt = tonumber(cur.maskTxt) or 0,
    }

    -- Cosmetic option lists: a "None" entry (-1 props / 0 mask) + the configured indices
    -- that actually exist on this ped model.
    local function buildPropOpts(list, slot)
        local n = GetNumberOfPedPropDrawableVariations(ped, slot)
        local out = { -1 }
        for _, d in ipairs(list or {}) do if d >= 0 and (n <= 0 or d < n) then out[#out + 1] = d end end
        return out
    end
    local function buildMaskOpts(list)
        local n = GetNumberOfPedDrawableVariations(ped, 1)
        local out = { 0 }
        for _, d in ipairs(list or {}) do if d > 0 and (n <= 0 or d < n) then out[#out + 1] = d end end
        return out
    end
    local hatOpts     = buildPropOpts(cp.hats, 0)
    local glassesOpts = buildPropOpts(cp.glasses, 1)
    local watchOpts   = buildPropOpts(cp.watches, 6)
    local maskOpts    = buildMaskOpts(cp.masks)

    local menu = NativeUI.CreateMenu('Clothing Store', ('Cash: $%s · Scroll to preview'):format(payload.cash or 0))
    pool:Add(menu)

    local function setComp(comp, drawable, txt)
        SetPedComponentVariation(ped, comp, drawable or 0, txt or 0, 0)
    end
    local function applyProp(slot, drawable, txt)
        if (drawable or -1) < 0 then ClearPedProp(ped, slot)
        else SetPedPropIndex(ped, slot, drawable, txt or 0, true) end
    end
    -- Only categories the player actually scrolls are previewed (and later charged/applied),
    -- so opening the store or browsing past a category never changes the character.
    local touched = {}
    local function previewSel()
        if touched.top then
            setComp(3, cp.arms or 0, 0)                              -- arms / sleeves
            setComp(8, cp.undershirt or 15, cp.undershirtTxt or 0)  -- undershirt
            setComp(11, tops[sel.topIdx] or 0, sel.topTxt)          -- top
        end
        if touched.pants then setComp(4, pants[sel.pantsIdx] or 0, sel.pantsTxt) end
        if touched.shoes then setComp(6, shoes[sel.shoesIdx] or 0, sel.shoesTxt) end
        if touched.mask  then setComp(1, sel.mask or 0, sel.maskTxt) end
        if touched.hat     then applyProp(0, sel.hat, sel.hatTxt) end
        if touched.glasses then applyProp(1, sel.glasses, sel.glassesTxt) end
        if touched.watch   then applyProp(6, sel.watch, sel.watchTxt) end
    end

    -- Highest valid texture for a drawable; selectors clamp to it so the checkerboard
    -- "missing texture" can never be selected.
    local function maxTexFor(comp, drawable)
        local n = GetNumberOfPedTextureVariations(ped, comp, drawable or 0)
        return (n and n > 0) and (n - 1) or 0
    end

    -- Valid top textures for a top drawable: 0..count minus the configured blacklist
    -- (freemode over-reports counts, so some indices render as checkerboard).
    local function allowedTopTex(drawable)
        local maxTex = GetNumberOfPedTextureVariations(ped, 11, drawable or 0)
        maxTex = (maxTex and maxTex > 0) and math.min(15, maxTex - 1) or 15
        local blset = {}
        local bl = cp.topTexBlacklist and cp.topTexBlacklist[drawable]
        if bl then for _, t in ipairs(bl) do blset[t] = true end end
        local out = {}
        for t = 0, maxTex do if not blset[t] then out[#out + 1] = t end end
        if #out == 0 then out = { 0 } end
        return out
    end

    local handlers = {}
    local function slider(label, minV, maxV, cur, onChange)
        local vals = {}
        for i = minV, maxV do vals[#vals + 1] = i end
        local idx = math.max(1, math.min(#vals, (cur - minV) + 1))
        local item = NativeUI.CreateSliderItem(label, vals, idx, false)
        menu:AddItem(item)
        handlers[item] = onChange
        return item
    end

    local topTex, pantsTex, shoesTex
    if not isCop then
    local topItem = slider(('Top ($%d)'):format(prices.top or 0), 1, math.max(1, #tops),
        math.max(1, math.min(#tops > 0 and #tops or 1, sel.topIdx)), function(v)
            touched.top = true
            sel.topIdx = v
            local allowed = allowedTopTex(tops[sel.topIdx])
            local pos = idxOf(allowed, sel.topTxt)
            sel.topTxt = allowed[pos]
            if topTex then topTex:Index(pos) end
        end)
    -- Top Texture is position-based over the allowed (non-blacklisted) textures.
    local topAllowed0 = allowedTopTex(tops[sel.topIdx])
    sel.topTxt = topAllowed0[idxOf(topAllowed0, sel.topTxt)]
    topTex = slider('Top Texture', 0, 15, idxOf(topAllowed0, sel.topTxt) - 1, function(v)
        touched.top = true
        local allowed = allowedTopTex(tops[sel.topIdx])
        local pos = math.max(0, math.min(v, #allowed - 1))
        sel.topTxt = allowed[pos + 1]
        if pos ~= v and topTex then topTex:Index(pos + 1) end
    end)
    local pantsItem = slider(('Bottoms ($%d)'):format(prices.pants or 0), 1, math.max(1, #pants),
        math.max(1, math.min(#pants > 0 and #pants or 1, sel.pantsIdx)), function(v)
            touched.pants = true
            sel.pantsIdx = v
            local mx = maxTexFor(4, pants[sel.pantsIdx])
            if sel.pantsTxt > mx then sel.pantsTxt = mx; if pantsTex then pantsTex:Index(mx + 1) end end
        end)
    pantsTex = slider('Bottoms Texture', 0, 15, sel.pantsTxt, function(v)
        touched.pants = true
        local mx = maxTexFor(4, pants[sel.pantsIdx])
        if v > mx then v = mx; if pantsTex then pantsTex:Index(v + 1) end end
        sel.pantsTxt = v
    end)
    local shoesItem = slider(('Shoes ($%d)'):format(prices.shoes or 0), 1, math.max(1, #shoes),
        math.max(1, math.min(#shoes > 0 and #shoes or 1, sel.shoesIdx)), function(v)
            touched.shoes = true
            sel.shoesIdx = v
            local mx = maxTexFor(6, shoes[sel.shoesIdx])
            if sel.shoesTxt > mx then sel.shoesTxt = mx; if shoesTex then shoesTex:Index(mx + 1) end end
        end)
    shoesTex = slider('Shoes Texture', 0, 15, sel.shoesTxt, function(v)
        touched.shoes = true
        local mx = maxTexFor(6, shoes[sel.shoesIdx])
        if v > mx then v = mx; if shoesTex then shoesTex:Index(v + 1) end end
        sel.shoesTxt = v
    end)
    end   -- if not isCop (full-outfit sliders)

    -- Cosmetics: a drawable selector (position-based, with a None entry) + a texture
    -- selector clamped to the chosen item's real texture count.
    local function texCountFor(isMask, slot, drawable)
        if isMask then
            if (drawable or 0) <= 0 then return 0 end
            local n = GetNumberOfPedTextureVariations(ped, 1, drawable)
            return (n and n > 0) and (n - 1) or 0
        end
        if (drawable or -1) < 0 then return 0 end
        local n = GetNumberOfPedPropTextureVariations(ped, slot, drawable)
        return (n and n > 0) and (n - 1) or 0
    end
    local function addCosmetic(label, opts, slot, isMask, dkey, tkey)
        local texItem
        slider(label, 1, math.max(1, #opts), math.max(1, idxOf(opts, sel[dkey])), function(pos)
            touched[dkey] = true
            sel[dkey] = opts[pos] or opts[1]
            local mx = texCountFor(isMask, slot, sel[dkey])
            if (sel[tkey] or 0) > mx then sel[tkey] = mx; if texItem then texItem:Index(mx + 1) end end
        end)
        texItem = slider(label .. ' Texture', 0, 15, sel[tkey] or 0, function(v)
            touched[dkey] = true
            local mx = texCountFor(isMask, slot, sel[dkey])
            if v > mx then v = mx; if texItem then texItem:Index(v + 1) end end
            sel[tkey] = v
        end)
    end
    -- Only offer a cosmetic category if this gender has a configured list for it.
    if not isCop and cp.hats and #cp.hats > 0 then addCosmetic(('Hat ($%d)'):format(prices.hat or 0),  hatOpts,     0, false, 'hat',     'hatTxt') end
    if cp.glasses and #cp.glasses > 0 then addCosmetic(('Glasses ($%d)'):format(prices.glasses or 0), glassesOpts, 1, false, 'glasses', 'glassesTxt') end
    if cp.watches and #cp.watches > 0 then addCosmetic(('Watch ($%d)'):format(prices.watch or 0),     watchOpts,   6, false, 'watch',   'watchTxt') end
    if not isCop and cp.masks and #cp.masks > 0 then addCosmetic(('Mask ($%d)'):format(prices.mask or 0), maskOpts, 1, true,  'mask',    'maskTxt') end

    local buyItem = NativeUI.CreateItem('Pay & Apply', 'Total for the items you changed')
    menu:AddItem(buyItem)

    -- Running total: each changed category adds its cost. Shown on the buy row.
    local function recalcTotal()
        local total = 0
        if touched.top     then total = total + (prices.top or 0) end
        if touched.pants   then total = total + (prices.pants or 0) end
        if touched.shoes   then total = total + (prices.shoes or 0) end
        if touched.hat     then total = total + (prices.hat or 0) end
        if touched.glasses then total = total + (prices.glasses or 0) end
        if touched.watch   then total = total + (prices.watch or 0) end
        if touched.mask    then total = total + (prices.mask or 0) end
        pcall(function() buyItem:RightLabel('$' .. total) end)
    end
    recalcTotal()

    -- No initial previewSel(): opening the store leaves the character exactly as-is.

    local revertLook   -- forward declaration (assigned below)

    menu.OnSliderChange = function(_, item, index)
        local h = handlers[item]
        if h then h(item:IndexToItem(index)); previewSel(); recalcTotal() end
    end

    menu.OnItemSelect = function(_, item)
        if item == buyItem then
            -- Only send the categories the player actually changed; nothing is committed
            -- (or charged) for items left untouched.
            local data = {}
            if touched.top     then data.topIdx = sel.topIdx;     data.topTxt = sel.topTxt end
            if touched.pants   then data.pantsIdx = sel.pantsIdx; data.pantsTxt = sel.pantsTxt end
            if touched.shoes   then data.shoesIdx = sel.shoesIdx; data.shoesTxt = sel.shoesTxt end
            if touched.hat     then data.hat = sel.hat;         data.hatTxt = sel.hatTxt end
            if touched.glasses then data.glasses = sel.glasses; data.glassesTxt = sel.glassesTxt end
            if touched.watch   then data.watch = sel.watch;     data.watchTxt = sel.watchTxt end
            if touched.mask    then data.mask = sel.mask;       data.maskTxt = sel.maskTxt end
            if not next(data) then
                CnR.NativeUI.notify('Pick something to buy first.')
                return
            end
            -- Send to the server, then immediately revert the local preview. The purchase
            -- is only applied for real by the server's applyClothing reply (sent ONLY after
            -- a successful charge), so a player who can't afford it keeps their old look.
            TriggerServerEvent('cnr:server:buyClothing', data)
            revertLook()
            menu:Visible(false)
        end
    end

    -- Restore the worn look (used on buy and on close). On a successful buy the server
    -- re-applies the purchased items a moment later via cnr:client:applyClothing.
    revertLook = function()
        setComp(11, snap.top, snap.topTxt)
        setComp(4, snap.pants, snap.pantsTxt)
        setComp(6, snap.shoes, snap.shoesTxt)
        setComp(3, snap.arms, 0)
        setComp(8, snap.undershirt, snap.undershirtTxt)
        setComp(1, snap.mask, snap.maskTxt)
        applyProp(0, snap.hat, snap.hatTxt)
        applyProp(1, snap.glasses, snap.glassesTxt)
        applyProp(6, snap.watch, snap.watchTxt)
    end
    menu.OnMenuClosed = revertLook

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)
end

-- Free-form clothing customizer (the old creator's clothing sliders) for capturing looks.
-- Opened via /outfitlab. Adjust components live on your current ped, then run /caprobber
-- to print a Config.RobberOutfits line. Does NOT affect spawn — it's a capture tool.
function CnR.NativeMenus.openOutfitLab()
    closeAll()
    local ped = PlayerPedId()
    local d = {
        top = GetPedDrawableVariation(ped, 11), topTxt = GetPedTextureVariation(ped, 11),
        arms = GetPedDrawableVariation(ped, 3),
        undershirt = GetPedDrawableVariation(ped, 8), undershirtTxt = GetPedTextureVariation(ped, 8),
        pants = GetPedDrawableVariation(ped, 4), pantsTxt = GetPedTextureVariation(ped, 4),
        shoes = GetPedDrawableVariation(ped, 6), shoesTxt = GetPedTextureVariation(ped, 6),
        mask = GetPedDrawableVariation(ped, 1), maskTxt = GetPedTextureVariation(ped, 1),
        -- props: -1 means "none / cleared"
        hat = GetPedPropIndex(ped, 0), hatTxt = GetPedPropTextureIndex(ped, 0),
        glasses = GetPedPropIndex(ped, 1), glassesTxt = GetPedPropTextureIndex(ped, 1),
        watch = GetPedPropIndex(ped, 6), watchTxt = GetPedPropTextureIndex(ped, 6),
    }

    -- How many vanilla variations exist for this model, so sliders stop at the real max.
    local maxMask     = math.max(0, GetNumberOfPedDrawableVariations(ped, 1) - 1)
    local maxMaskTxt  = math.max(0, GetNumberOfPedTextureVariations(ped, 1, d.mask >= 0 and d.mask or 0) - 1)
    local maxHat      = math.max(0, GetNumberOfPedPropDrawableVariations(ped, 0) - 1)
    local maxGlasses  = math.max(0, GetNumberOfPedPropDrawableVariations(ped, 1) - 1)
    local maxWatch    = math.max(0, GetNumberOfPedPropDrawableVariations(ped, 6) - 1)

    local menu = NativeUI.CreateMenu('Outfit Lab', 'Adjust, then /capoutfit to capture the full set')
    pool:Add(menu)
    -- Keep chat keys usable so /capoutfit works while the menu is open.
    menu:AddEnabledControl(0, 245)
    menu:AddEnabledControl(0, 246)

    local handlers = {}
    local function setProp(slot, drawable, txt)
        local p = PlayerPedId()
        if (drawable or -1) < 0 then ClearPedProp(p, slot)
        else SetPedPropIndex(p, slot, drawable, txt or 0, true) end
    end
    local function apply()
        local p = PlayerPedId()
        CnR.Util.SetComponentSafe(p, 11, d.top, d.topTxt, 0)
        CnR.Util.SetComponentSafe(p, 3, d.arms, 0, 0)
        CnR.Util.SetComponentSafe(p, 8, d.undershirt, d.undershirtTxt, 0)
        CnR.Util.SetComponentSafe(p, 4, d.pants, d.pantsTxt, 0)
        CnR.Util.SetComponentSafe(p, 6, d.shoes, d.shoesTxt, 0)
        CnR.Util.SetComponentSafe(p, 1, d.mask >= 0 and d.mask or 0, d.maskTxt, 0)
        setProp(0, d.hat, d.hatTxt)
        setProp(1, d.glasses, d.glassesTxt)
        setProp(6, d.watch, d.watchTxt)
    end

    local function slider(label, minV, maxV, cur, setter)
        if maxV < minV then maxV = minV end
        local vals = {}
        for i = minV, maxV do vals[#vals + 1] = i end
        local idx = math.max(1, math.min(#vals, ((cur or minV) - minV) + 1))
        local item = NativeUI.CreateSliderItem(label, vals, idx, false)
        menu:AddItem(item)
        handlers[item] = setter
    end

    slider('Shirt',              0, 160, d.top,           function(v) d.top = v end)
    slider('Shirt Texture',      0, 25,  d.topTxt,        function(v) d.topTxt = v end)
    slider('Arms / Sleeves',     0, 35,  d.arms,          function(v) d.arms = v end)
    slider('Undershirt',         0, 35,  d.undershirt,    function(v) d.undershirt = v end)
    slider('Undershirt Texture', 0, 25,  d.undershirtTxt, function(v) d.undershirtTxt = v end)
    slider('Pants',              0, 110, d.pants,         function(v) d.pants = v end)
    slider('Pants Texture',      0, 25,  d.pantsTxt,      function(v) d.pantsTxt = v end)
    slider('Shoes',              0, 95,  d.shoes,         function(v) d.shoes = v end)
    slider('Shoes Texture',      0, 25,  d.shoesTxt,      function(v) d.shoesTxt = v end)
    -- Props & mask: browse every vanilla item for this model. -1 on hat/glasses/watch = none.
    slider('Mask',               0, maxMask,    d.mask,       function(v) d.mask = v end)
    slider('Mask Texture',       0, maxMaskTxt, d.maskTxt,    function(v) d.maskTxt = v end)
    slider('Hat',               -1, maxHat,     d.hat,        function(v) d.hat = v end)
    slider('Hat Texture',        0, 15,         d.hatTxt,     function(v) d.hatTxt = v end)
    slider('Glasses',           -1, maxGlasses, d.glasses,    function(v) d.glasses = v end)
    slider('Glasses Texture',    0, 15,         d.glassesTxt, function(v) d.glassesTxt = v end)
    slider('Watch',             -1, maxWatch,   d.watch,      function(v) d.watch = v end)
    slider('Watch Texture',      0, 15,         d.watchTxt,   function(v) d.watchTxt = v end)

    menu.OnSliderChange = function(_, item, index)
        local h = handlers[item]
        if h then h(item:IndexToItem(index)); apply() end
    end

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)
end

function CnR.NativeMenus.openBarberShop(payload)
    payload = payload or {}
    closeAll()

    local skin = payload.skin or {}
    if not skin.isCustom then
        CnR.NativeUI.notify('Barber changes require a custom character.')
        return
    end

    local draft = {
        hair = tonumber(skin.hair) or 0,
        hairColor = tonumber(skin.hairColor) or 0,
        beard = tonumber(skin.beard) or 0,
        beardColor = tonumber(skin.beardColor) or 0,
    }
    -- Original values + per-item prices: only styles the player actually changes are charged.
    local orig = { hair = draft.hair, hairColor = draft.hairColor, beard = draft.beard, beardColor = draft.beardColor }
    local prices = payload.prices or {}
    local recalcTotal   -- forward declaration (assigned after the buy row is built)

    local previewSkin = {}
    for k, v in pairs(skin) do previewSkin[k] = v end

    local function values(minVal, maxVal)
        local out = {}
        for i = minVal, maxVal do out[#out + 1] = i end
        return out
    end

    local sliderHandlers = {}
    local function addSlider(menu, label, minVal, maxVal, current, key)
        local opts = values(minVal, maxVal)
        local idx = math.max(1, math.min(#opts, ((current or minVal) - minVal) + 1))
        local row = NativeUI.CreateSliderItem(label, opts, idx, false)
        menu:AddItem(row)
        sliderHandlers[row] = function(value)
            draft[key] = value
            previewSkin[key] = value
            TriggerEvent('cnr:client:previewBarber', { skin = previewSkin, rankId = payload.rankId or 1 })
            if recalcTotal then recalcTotal() end
        end
    end

    local menu = NativeUI.CreateMenu('Barbershop', ('Cash: $%s · each change adds its cost'):format(payload.cash or 0))
    pool:Add(menu)

    addSlider(menu, ('Hair Style ($%d)'):format(prices.hair or 0), 0, 74, draft.hair, 'hair')
    addSlider(menu, ('Hair Color ($%d)'):format(prices.hairColor or 0), 0, 63, draft.hairColor, 'hairColor')
    if skin.gender ~= 'female' then
        addSlider(menu, ('Beard ($%d)'):format(prices.beard or 0), 0, 28, draft.beard, 'beard')
        addSlider(menu, ('Beard Color ($%d)'):format(prices.beardColor or 0), 0, 63, draft.beardColor, 'beardColor')
    end

    local applyRow = NativeUI.CreateItem('Pay & Apply', 'Total for the styles you changed')
    menu:AddItem(applyRow)

    -- Running total: each style that differs from the original adds its cost.
    recalcTotal = function()
        local total = 0
        if draft.hair       ~= orig.hair       then total = total + (prices.hair or 0) end
        if draft.hairColor  ~= orig.hairColor  then total = total + (prices.hairColor or 0) end
        if draft.beard      ~= orig.beard      then total = total + (prices.beard or 0) end
        if draft.beardColor ~= orig.beardColor then total = total + (prices.beardColor or 0) end
        pcall(function() applyRow:RightLabel('$' .. total) end)
    end
    recalcTotal()

    menu.OnSliderChange = function(_, item, index)
        local handler = sliderHandlers[item]
        if handler then handler(item:IndexToItem(index)) end
    end

    menu.OnItemSelect = function(_, item)
        if item == applyRow then
            -- Send to the server, then immediately revert the preview. The new style is
            -- only applied for real by the server's applyBarber reply (sent only after a
            -- successful charge) — so it never sticks when the player can't afford it.
            TriggerServerEvent('cnr:server:buyBarberStyle', draft)
            TriggerEvent('cnr:client:previewBarber', { skin = skin, rankId = payload.rankId or 1 })
            menu:Visible(false)
        end
    end

    -- Always restore the original look when the menu closes. A successful purchase
    -- re-applies the new style a moment later via cnr:client:applyBarber.
    menu.OnMenuClosed = function()
        TriggerEvent('cnr:client:previewBarber', { skin = skin, rankId = payload.rankId or 1 })
    end

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)
end

function CnR.NativeMenus.openPrisonFood(payload)
    payload = payload or {}
    closeAll()

    local price = tonumber(payload.price) or 0
    local heal  = tonumber(payload.heal) or 20
    local priceText = price > 0 and ('$' .. price) or 'Free'

    local menu = NativeUI.CreateMenu('Prison Canteen', ('Cash: $%s'):format(payload.cash or 0))
    pool:Add(menu)

    local row = NativeUI.CreateItem('Prison Food', ('%s · Restores %d HP'):format(priceText, heal))
    menu:AddItem(row)

    menu.OnItemSelect = function(_, item)
        TriggerServerEvent('cnr:server:buyPrisonFood')
        menu:Visible(false)
    end

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)
end

function CnR.NativeMenus.openTattooShop(payload)
    payload = payload or {}
    closeAll()

    local menu = NativeUI.CreateMenu('Tattoo Parlor',
        ('Cash: $%s · scroll a design to preview it, then Pay & Apply'):format(payload.cash or 0))
    pool:Add(menu)

    -- Flat list of every design with its PRICE on the right. Scrolling previews it live on
    -- your character and marks it as the "selected" design; the Pay & Apply row at the
    -- bottom buys whatever is currently selected (same flow as the clothing store). #12
    local pending = nil   -- catalog id of the design currently being previewed
    local firstId
    for id, t in ipairs((Config and Config.Tattoos) or {}) do
        local item = NativeUI.CreateItem(t.label or ('Design ' .. id), 'Scroll to preview · Enter to apply')
        item._tatId = id
        pcall(function() item:RightLabel(('$%d'):format(t.price or 500)) end)
        menu:AddItem(item)
        firstId = firstId or id
    end

    local buy = NativeUI.CreateItem('Pay & Apply', 'Purchase and apply the selected tattoo')
    buy._buy = true
    menu:AddItem(buy)

    local rem = NativeUI.CreateItem('Remove All Tattoos', 'Clears every tattoo (free)')
    rem._removeTattoos = true
    menu:AddItem(rem)

    local function applyPending()
        if not pending then return end
        TriggerServerEvent('cnr:server:buyTattoo', { id = pending })
        -- Drop the preview immediately; the design only reappears if the server confirms
        -- the purchase (cnr:client:applyTattoos). If you can't afford it, nothing sticks. #12
        if CnR.Tattoo then CnR.Tattoo.cancelPreview() end
        menu:Visible(false)
    end

    -- Live preview while browsing. On the Pay/Remove rows keep the last design's preview.
    menu.OnIndexChange = function(_, index)
        local item = menu.Items and menu.Items[index]
        if item and item._tatId then
            pending = item._tatId
            if CnR.Tattoo then CnR.Tattoo.preview(pending) end
        end
    end

    menu.OnItemSelect = function(_, item)
        if item._tatId then
            pending = item._tatId
            applyPending()
        elseif item._buy then
            applyPending()
        elseif item._removeTattoos then
            TriggerServerEvent('cnr:server:removeTattoos')
            if CnR.Tattoo then CnR.Tattoo.cancelPreview() end
            menu:Visible(false)
        end
    end

    -- Restore the outfit + owned-only look when the shop closes.
    menu.OnMenuClosed = function()
        if CnR.Tattoo then CnR.Tattoo.cancelPreview() end
    end

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)
    -- Preview the first design right away so it's obvious you're choosing designs.
    if firstId and CnR.Tattoo then pending = firstId; CnR.Tattoo.preview(firstId) end
end


function CnR.NativeMenus.openPrisonBikeShop(payload)
    payload = payload or {}
    closeAll()

    local subtitle = (payload.cooldown or 0) > 0 and ('Cooldown: %ss'):format(payload.cooldown) or 'Free transport'
    local menu = NativeUI.CreateMenu('Free Transport', subtitle)
    pool:Add(menu)

    for _, veh in ipairs(payload.vehicles or {}) do
        local row = NativeUI.CreateItem(veh.label or veh.model, 'Spawn outside the prison')
        row._model = veh.model
        menu:AddItem(row)
    end

    menu.OnItemSelect = function(_, item)
        if item._model then
            TriggerServerEvent('cnr:server:requestPrisonBike', { model = item._model })
            menu:Visible(false)
        end
    end

    menu:Visible(true)
end


function CnR.NativeMenus.openDealership(payload)
    payload = payload or {}
    closeAll()

    local menu = NativeUI.CreateMenu(
        'Premium Deluxe Motorsport',
        ('Cash: $%s · ↑↓ browse · look at preview · Enter buy'):format(payload.cash or 0)
    )
    pool:Add(menu)

    for _, car in ipairs(payload.cars or {}) do
        local priceText = (not car.price or car.price <= 0) and 'Free' or ('$' .. car.price)
        local row = NativeUI.CreateItem(
            car.label or car.model,
            ('%s · %s · Enter to get'):format(priceText, car.tier or 'Vehicle')
        )
        row._model = car.model
        row._price = car.price
        menu:AddItem(row)
    end

    menu.OnItemSelect = function(_, item)
        if item._model then
            if CnR.VehiclePreview then CnR.VehiclePreview.clear() end
            TriggerServerEvent('cnr:server:buyCar', { model = item._model })
            menu:Visible(false)
        end
    end

    -- Start the highlight on the first car, not the last.
    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)

    -- Bind the preview AFTER the menu is visible: bindMenu's initial preview bails out
    -- while the menu is hidden, which left the first car blank until you scrolled.
    if CnR.VehiclePreview then
        CnR.VehiclePreview.bindMenu(menu, 'dealership')
    end
end


-- Police desk NPC. Clothing browsing was removed — the desk now only lets the
-- player pick which station they spawn at. Uniforms are handled automatically
-- (level-gated), so there is no manual clothing selection here anymore.
function CnR.NativeMenus.openClothingStore(payload)
    payload = payload or {}
    closeAll()

    local menu = NativeUI.CreateMenu('Information', 'Spawn station, uniform and your stats')
    pool:Add(menu)

    local stationIdx = ((payload.station or 'missionRow') == 'vespucci') and 2 or 1
    local stationItem = NativeUI.CreateListItem('Spawn Station', { 'Mission Row PD', 'Vespucci PD' }, stationIdx,
        'Enter to save this as your default spawn station')
    menu:AddItem(stationItem)

    menu.OnListSelect = function(_, item, index)
        if item == stationItem then
            local newStation = (index == 2) and 'vespucci' or 'missionRow'
            local label = (index == 2) and 'Vespucci PD' or 'Mission Row PD'
            TriggerServerEvent('cnr:server:setStation', { station = newStation })
            -- The game feed silently suppresses a post identical to a recent one, so saving
            -- the same station twice in a row showed nothing. Cycle a run of trailing spaces
            -- (invisible) so each post is a unique string and always displays.
            CnR._spawnSaveTick = ((CnR._spawnSaveTick or 0) + 1) % 6
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName('Spawn station saved: ' .. label .. string.rep(' ', CnR._spawnSaveTick))
            EndTextCommandThefeedPostTicker(false, true)
        end
    end

    -- Police Clothing: uniform options. Currently just a toggle to remove the hat.
    -- Resolve the hat (prop 0) this cop's uniform uses, so the preview can put it back
    -- when toggling On — even if the hat is currently off (saved preference is Off).
    local previewPed = PlayerPedId()
    local hatProp = GetPedPropIndex(previewPed, 0)
    local hatPropTxt = math.max(0, GetPedPropTextureIndex(previewPed, 0))
    if hatProp < 0 then
        if payload.clothes and payload.clothes.hat ~= nil then
            hatProp, hatPropTxt = payload.clothes.hat, payload.clothes.hatTxt or 0
        else
            local outfits = (Config and Config.Outfits) or {}
            local chosen = outfits[1]
            for _, o in ipairs(outfits) do if o.id == (payload.outfitId or 1) then chosen = o; break end end
            local gender = (type(payload.skin) == 'table' and payload.skin.gender) or 'male'
            local comp = chosen and ((gender == 'female') and chosen.female or chosen.male)
            if comp and comp.hat ~= nil then hatProp, hatPropTxt = comp.hat, comp.hatTxt or 0 end
        end
    end

    local function previewHat(hide)
        local p = PlayerPedId()
        if hide then
            ClearPedProp(p, 0)
        elseif hatProp and hatProp >= 0 then
            CnR.Util.SetPropSafe(p, 0, hatProp, hatPropTxt, true)
        end
    end

    local savedHide = payload.hideHat == true   -- the persisted choice (for revert-on-cancel)
    local clothingSub = pool:AddSubMenu(menu, 'Police Clothing', 'Uniform options')
    local hatItem = NativeUI.CreateListItem('Police Hat', { 'On', 'Off' }, savedHide and 2 or 1,
        'Enter to save · scroll to preview')
    clothingSub:AddItem(hatItem)

    -- Live preview as the value changes, before saving.
    clothingSub.OnListChange = function(_, item, index)
        if item == hatItem then previewHat(index == 2) end
    end

    clothingSub.OnListSelect = function(_, item, index)
        if item == hatItem then
            local hide = (index == 2)
            savedHide = hide
            previewHat(hide)
            TriggerServerEvent('cnr:server:setHat', { hide = hide })
            CnR._hatSaveTick = ((CnR._hatSaveTick or 0) + 1) % 6
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName((hide and 'Police hat removed.' or 'Police hat on.') .. string.rep(' ', CnR._hatSaveTick))
            EndTextCommandThefeedPostTicker(false, true)
        end
    end

    -- Leaving the submenu without pressing Enter reverts the preview to the saved choice.
    clothingSub.OnMenuClosed = function()
        previewHat(savedHide)
    end

    -- Stats: arrests + wanted-robber kills this life (#6).
    local statsItem = NativeUI.CreateItem('My Stats',
        'Standard / instant arrests and wanted-robber kills since your last new life')
    menu:AddItem(statsItem)
    menu.OnItemSelect = function(_, item)
        if item == statsItem then
            TriggerServerEvent('cnr:server:getStats')
        end
    end

    menu:Visible(true)
    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
end

-- Read-only "Officer Stats" sheet shown when the desk's Stats item is chosen (#6).
RegisterNetEvent('cnr:client:showStats', function(stats)
    stats = stats or {}
    local std  = stats.stdArrests or 0
    local inst = stats.instantArrests or 0
    local kills = stats.robberKills or 0
    closeAll()
    local m = NativeUI.CreateMenu('Officer Stats', 'This life · resets when you use /newlife')
    pool:Add(m)
    local function row(label, n)
        local it = NativeUI.CreateItem(label, '')
        it:RightLabel(tostring(n))
        m:AddItem(it)
    end
    row('Standard Arrests', std)
    row('Instant Arrests', inst)
    row('Total Arrests', std + inst)
    row('Wanted Robbers Killed', kills)
    m.Pagination.Min = 0
    m.Pagination.Max = m.Pagination.Total
    m:CurrentSelection(0)
    m:Visible(true)
end)


-- XP threshold for a cop level id, e.g. levelXp(2) -> 1000. nil if unknown.
local function levelXp(levelId)
    for _, r in ipairs((Config and Config.Ranks) or {}) do
        if r.id == levelId then return r.xp end
    end
    return nil
end

-- "Level 2 (1000 XP)" if the XP is known, otherwise "Level 2".
local function levelLabel(levelId)
    local xp = levelXp(tonumber(levelId))
    if xp ~= nil then return ('Level %s (%s XP)'):format(levelId, xp) end
    return ('Level %s'):format(levelId)
end

function CnR.NativeMenus.openArmory(payload)
    payload = payload or {}
    closeAll()

    local credits = tonumber(payload.credits) or 0
    local menu = NativeUI.CreateMenu('Weapon Locker', ('Credits: %d · spend on weapons & armor'):format(credits))
    pool:Add(menu)

    local function costText(cost)
        cost = tonumber(cost) or 0
        return cost == 0 and 'Free' or (cost .. ' credits')
    end

    local weaponsSub = pool:AddSubMenu(menu, 'Weapon locker', ('Credits: %d'):format(credits))

    for _, w in ipairs(payload.weapons or {}) do
        local label = w.label or w.weapon or 'Weapon'
        local desc = w.unlocked
            and ('%s · Enter to equip'):format(costText(w.cost))
            or ('Locked · %s'):format(costText(w.cost))
        if not w.unlocked then label = '~c~' .. label end  -- grey out locked entries
        local row = NativeUI.CreateItem(label, desc)
        row._weapon = w.weapon
        row._unlocked = w.unlocked
        row._cost = w.cost
        if not w.unlocked then
            row:SetLeftBadge(BadgeStyle.Lock)
        end
        weaponsSub:AddItem(row)
    end

    weaponsSub.OnItemSelect = function(_, item)
        if item._unlocked and item._weapon then
            TriggerServerEvent('cnr:server:armoryEquip', { weapon = item._weapon })
            -- Server re-sends the armory (cnr:client:openArmory) with the new balance, so
            -- locks/credits refresh in real time. Close the stale menu now.
            CnR.NativeUI.closeAll()
        elseif item._weapon then
            CnR.NativeUI.notify(('%d credits required.'):format(item._cost or 0))
        end
    end

    -- Body armor: tiers gated by credits (Super Light is free).
    local armorSub = pool:AddSubMenu(menu, 'Body armor', ('Credits: %d'):format(credits))
    for _, a in ipairs(payload.armor or {}) do
        local desc = a.unlocked
            and ('%s · Enter to equip'):format(costText(a.cost))
            or ('Locked · %s'):format(costText(a.cost))
        local alabel = a.label or 'Armor'
        if not a.unlocked then alabel = '~c~' .. alabel end  -- grey out locked entries
        local row = NativeUI.CreateItem(alabel, desc)
        row._armor = a.tier
        row._unlocked = a.unlocked
        row._cost = a.cost
        if not a.unlocked then
            row:SetLeftBadge(BadgeStyle.Lock)
        end
        armorSub:AddItem(row)
    end
    armorSub.OnItemSelect = function(_, item)
        if item._unlocked and item._armor then
            TriggerServerEvent('cnr:server:armoryArmor', { tier = item._armor })
            CnR.NativeUI.closeAll()  -- server re-sends a refreshed armory menu
        elseif item._armor then
            CnR.NativeUI.notify(('%d credits required.'):format(item._cost or 0))
        end
    end

    -- Refill last, so the menu order is: Weapon locker, Body armor, Refill all ammunition.
    local refillItem = NativeUI.CreateItem('Refill all ammunition', 'Top up every weapon in your issued pool')
    menu:AddItem(refillItem)

    menu.OnItemSelect = function(_, item)
        if item == refillItem then
            TriggerServerEvent('cnr:server:armoryRefill')
        end
    end

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)

    -- Submenus must also start at the top (Level 1 items), otherwise they open focused
    -- on the last/highest-level entry.
    for _, sub in ipairs({ weaponsSub, armorSub }) do
        if #sub.Items > 0 then
            sub.Pagination.Min = 0
            sub.Pagination.Max = sub.Pagination.Total
            sub:CurrentSelection(0)
        end
    end

    menu:Visible(true)
end


function CnR.NativeMenus.openVehiclePicker(payload)
    payload = payload or {}
    closeAll()

    local credits = tonumber(payload.credits) or 0
    local menu = NativeUI.CreateMenu(
        payload.heli and 'Police Air Support' or 'Vehicle Yard',
        ('Credits: %d · ↑↓ browse · Enter to spawn'):format(credits)
    )
    pool:Add(menu)

    local function costText(cost)
        cost = tonumber(cost) or 0
        return cost == 0 and 'Free' or (cost .. ' credits')
    end

    local labels = (Config and Config.VehicleLabels) or {}
    for _, v in ipairs(payload.vehicles or {}) do
        local unlocked = v.unlocked ~= false
        local desc = unlocked
            and ('%s · Enter to spawn'):format(costText(v.cost))
            or ('Locked · %s'):format(costText(v.cost))
        -- Prefer the folder-name label sent by the server (add-on vehicles), then the
        -- static Config.VehicleLabels (vanilla), then the raw model name.
        local displayName = v.label or labels[v.model] or v.model or 'vehicle'
        if not unlocked then displayName = '~c~' .. displayName end  -- grey out locked entries
        local row = NativeUI.CreateItem(displayName, desc)
        row._model = v.model
        row._unlocked = unlocked
        row._cost = v.cost
        if not unlocked then
            row:SetLeftBadge(BadgeStyle.Lock)
        end
        menu:AddItem(row)
    end

    menu.OnItemSelect = function(_, item)
        if item._unlocked and item._model then
            if CnR.VehiclePreview then CnR.VehiclePreview.clear() end
            TriggerServerEvent('cnr:server:requestVehicle', {
                model   = item._model,
                station = CnR.State and CnR.State.yardStation or nil,
            })
            menu:Visible(false)
        elseif item._model then
            CnR.NativeUI.notify(('%d credits required.'):format(item._cost or 0))
        end
    end

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)

    if CnR.VehiclePreview then
        CnR.VehiclePreview.bindMenu(menu, 'yard')
    end
end


function CnR.NativeMenus.openModShop(payload)
    payload = payload or {}
    closeAll()

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        CnR.NativeUI.notify('You must be driving a vehicle.')
        return
    end

    SetVehicleModKit(veh, 0)
    FreezeEntityPosition(veh, true)
    SetVehicleEngineOn(veh, false, true, true)

    local cfg = Config.ModShop or {}
    local repairPrice  = cfg.repairPrice or 250
    local modPrice     = cfg.modPrice or 500
    local turboPrice   = cfg.turboPrice or 1500
    local resprayPrice = cfg.resprayPrice or 750

    local function modLabel(vehicle, modType, modIndex)
        if modIndex == -1 then return 'Stock' end
        local lbl = GetModTextLabel(vehicle, modType, modIndex)
        if lbl and lbl ~= '' then
            local text = GetLabelText(lbl)
            if text and text ~= 'NULL' and text ~= '' then return text end
        end
        return ('Upgrade %d'):format(modIndex + 1)
    end

    local function bindModSelect(sub, defaultPrice)
        sub.OnItemSelect = function(_, item)
            if item._modType then
                TriggerServerEvent('cnr:server:modShopApply', {
                    modType  = item._modType,
                    modIndex = item._modIndex,
                    price    = item._price or defaultPrice,
                })
            end
        end
    end

    local function addModList(parent, label, entries, price)
        local sub = pool:AddSubMenu(parent, label, 'Vehicle upgrades')
        for _, entry in ipairs(entries) do
            if entry.toggle then
                local installed = IsToggleModOn(veh, entry.type)
                local row = NativeUI.CreateItem(
                    entry.label,
                    installed and ('Installed · $%s to remove'):format(turboPrice) or ('Not installed · $%s to install'):format(turboPrice)
                )
                row._modType = entry.type
                row._toggle = true
                row._enabled = not installed
                sub:AddItem(row)
                sub.OnItemSelect = function(_, item)
                    if item._toggle and item._modType then
                        TriggerServerEvent('cnr:server:modShopApply', {
                            toggle  = true,
                            modType = item._modType,
                            enabled = item._enabled,
                            price   = turboPrice,
                        })
                    end
                end
            else
                local catSub = pool:AddSubMenu(sub, entry.label, 'Select upgrade')
                local stockRow = NativeUI.CreateItem('Stock', 'Remove upgrade · $0')
                stockRow._modType = entry.type
                stockRow._modIndex = -1
                stockRow._price = 0
                catSub:AddItem(stockRow)
                local num = GetNumVehicleMods(veh, entry.type)
                for i = 0, num - 1 do
                    local row = NativeUI.CreateItem(modLabel(veh, entry.type, i), ('$%s · Enter to apply'):format(price))
                    row._modType = entry.type
                    row._modIndex = i
                    row._price = price
                    catSub:AddItem(row)
                end
                bindModSelect(catSub, price)
            end
        end
    end

    local menu = NativeUI.CreateMenu(
        'Los Santos Customs',
        ('Cash: $%s · Repair, upgrade, and respray'):format(payload.cash or 0)
    )
    pool:Add(menu)

    local repairRow = NativeUI.CreateItem('Repair & Clean', ('$%s · restore body and engine'):format(repairPrice))
    menu:AddItem(repairRow)

    addModList(menu, 'Performance', {
        { type = 11, label = 'Engine' },
        { type = 12, label = 'Brakes' },
        { type = 13, label = 'Transmission' },
        { type = 15, label = 'Suspension' },
        { type = 16, label = 'Armor' },
        { type = 18, label = 'Turbo', toggle = true },
    }, modPrice)

    addModList(menu, 'Body', {
        { type = 0, label = 'Spoiler' },
        { type = 1, label = 'Front Bumper' },
        { type = 2, label = 'Rear Bumper' },
        { type = 3, label = 'Side Skirt' },
        { type = 4, label = 'Exhaust' },
        { type = 7, label = 'Hood' },
        { type = 10, label = 'Roof' },
    }, modPrice)

    addModList(menu, 'Wheels', {
        { type = 23, label = 'Wheels' },
    }, modPrice)

    local paintSub = pool:AddSubMenu(menu, 'Respray', 'Change primary paint')
    local paints = {
        { name = 'Black', id = 0 }, { name = 'White', id = 111 },
        { name = 'Silver', id = 4 }, { name = 'Red', id = 27 },
        { name = 'Blue', id = 64 }, { name = 'Green', id = 53 },
        { name = 'Orange', id = 38 }, { name = 'Yellow', id = 88 },
        { name = 'Purple', id = 145 }, { name = 'Gold', id = 99 },
    }
    for _, p in ipairs(paints) do
        local row = NativeUI.CreateItem(p.name, ('$%s · Enter to apply'):format(resprayPrice))
        row._primary = p.id
        paintSub:AddItem(row)
    end
    paintSub.OnItemSelect = function(_, item)
        if item._primary then
            TriggerServerEvent('cnr:server:modShopApply', {
                action  = 'color',
                primary = item._primary,
                price   = resprayPrice,
            })
        end
    end

    menu.OnItemSelect = function(_, item)
        if item == repairRow then
            TriggerServerEvent('cnr:server:modShopRepair', { price = repairPrice })
        end
    end

    menu.OnMenuClosed = function()
        if DoesEntityExist(veh) then
            FreezeEntityPosition(veh, false)
            SetVehicleEngineOn(veh, true, true, false)
        end
    end

    -- Always open on the first row (Repair & Clean). Without this the menu inherited the
    -- last-added item as its selection and opened scrolled to the bottom. #5
    menu:CurrentSelection(0)
    menu:Visible(true)
end


function CnR.NativeMenus.openInventory(payload)
    payload = payload or {}
    closeAll()

    local menu = NativeUI.CreateMenu('Inventory', ('Cash: $%s · XP: %s'):format(payload.cash or 0, payload.xp or 0))
    pool:Add(menu)

    local itemDefs = payload.items or {}
    local hasItems = false

    for key, count in pairs(payload.inventory or {}) do
        if (count or 0) > 0 then
            hasItems = true
            local def = itemDefs[key] or {}
            local row = NativeUI.CreateItem(def.label or key, ('x%s · use item'):format(count))
            row._key = key
            menu:AddItem(row)
        end
    end

    for _, w in ipairs(payload.weapons or {}) do
        hasItems = true
        local row = NativeUI.CreateItem(w.name, ('Ammo: %s'):format(w.ammo or 0))
        row._readonly = true
        menu:AddItem(row)
    end

    if not hasItems then
        menu:AddItem(NativeUI.CreateItem('Empty', 'No items or weapons'))
    end

    menu.OnItemSelect = function(_, item)
        if item._key then
            TriggerServerEvent('cnr:server:useItem', { key = item._key })
        end
    end

    menu:Visible(true)
end

-- Turn a raw weapon hash like 'WEAPON_PISTOL' into readable 'Pistol'.
local function weaponLabel(name)
    local raw = tostring(name or ''):gsub('^WEAPON_', ''):gsub('^GADGET_', ''):gsub('_', ' '):lower()
    return (raw:gsub('(%a)([%w]*)', function(a, b) return a:upper() .. b end))
end

function CnR.NativeMenus.openInventory(payload)
    payload = payload or {}
    closeAll()

    local menu = NativeUI.CreateMenu('Inventory', ('Cash: $%s - XP: %s'):format(payload.cash or 0, payload.xp or 0))
    pool:Add(menu)

    local itemDefs = payload.items or {}
    local hasItems = false

    for key, count in pairs(payload.inventory or {}) do
        if (count or 0) > 0 then
            hasItems = true
            local def = itemDefs[key] or {}
            local label = def.label or key
            local sub = pool:AddSubMenu(menu, label, ('x%s - choose action'):format(count))

            local eat = NativeUI.CreateItem(def.action or 'Eat', ('Restore +%s HP'):format(def.heal or 0))
            eat._key = key
            eat._action = 'eat'
            sub:AddItem(eat)

            local remove = NativeUI.CreateItem('Remove', 'Discard one item')
            remove._key = key
            remove._action = 'remove'
            sub:AddItem(remove)

            sub.OnItemSelect = function(_, item)
                if item._key and item._action == 'eat' then
                    TriggerServerEvent('cnr:server:useItem', { key = item._key })
                    sub:Visible(false)
                elseif item._key and item._action == 'remove' then
                    TriggerServerEvent('cnr:server:removeItem', { key = item._key })
                    sub:Visible(false)
                end
            end

            -- Open the Eat/Remove submenu highlighted on the first row, not the last.
            sub.Pagination.Min = 0
            sub.Pagination.Max = sub.Pagination.Total
            sub:CurrentSelection(0)
        end
    end

    for _, w in ipairs(payload.weapons or {}) do
        hasItems = true
        local row = NativeUI.CreateItem(weaponLabel(w.name), ('Ammo: %s'):format(w.ammo or 0))
        row._readonly = true
        menu:AddItem(row)
    end

    if not hasItems then
        menu:AddItem(NativeUI.CreateItem('Empty', 'No items or weapons'))
    end

    -- Start the highlight on the first row, not the last.
    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)
end

function CnR.NativeMenus.openPlayerList(payload)
    payload = payload or {}
    closeAll()

    local players = payload.players or {}
    local menu = NativeUI.CreateMenu('Online Players', ('%s online'):format(#players))
    pool:Add(menu)

    if #players == 0 then
        menu:AddItem(NativeUI.CreateItem('No players online', ''))
    else
        for _, p in ipairs(players) do
            local role = p.role or 'none'
            -- Capitalise the first letter for display (cop -> Cop, robber -> Robber). #playerlist
            role = role:sub(1, 1):upper() .. role:sub(2)
            local label = ('[%s] %s'):format(p.id or '?', p.name or 'Unknown')
            local desc = ('Role: %s'):format(role)
            menu:AddItem(NativeUI.CreateItem(label, desc))
        end
    end

    menu:Visible(true)
end


function CnR.NativeMenus.openHelp(sections)
    closeAll()

    local menu = NativeUI.CreateMenu('Server Guide', 'Cops & Robbers')
    pool:Add(menu)

    for _, sec in ipairs(sections or {}) do
        local lines = table.concat(sec.lines or {}, '\n')
        local row = NativeUI.CreateItem(sec.title or 'Section', lines)
        menu:AddItem(row)
    end

    menu.OnItemSelect = function(_, item)
        if item:Description() then
            CnR.NativeUI.notify(item:Description())
        end
    end

    menu:Visible(true)
end

function CnR.NativeMenus.openNewLifeConfirm()
    closeAll()

    local menu = NativeUI.CreateMenu('New Life', 'Wipe progression and reselect team?')
    pool:Add(menu)

    local yesItem = NativeUI.CreateItem('Yes — reset everything', 'Requires a clean record (no jail debt, sentence, or wanted)')
    local noItem = NativeUI.CreateItem('No — cancel', 'Keep current character')
    menu:AddItem(yesItem)
    menu:AddItem(noItem)

    menu.OnItemSelect = function(_, item)
        if item == yesItem then
            TriggerServerEvent('cnr:server:newLife')
        end
        menu:Visible(false)
    end

    menu:Visible(true)
end

-- Arrest options for a cuffed suspect (cop only). Standard = escort to a chosen station
-- for full credits; Instant = jail now for fewer credits.
function CnR.NativeMenus.openArrestOptions(targetSid)
    closeAll()
    local menu = NativeUI.CreateMenu('Arrest Options', 'Choose how to process the suspect')
    pool:Add(menu)

    local function entranceFor(station)
        for _, e in ipairs((Config and Config.ArrestEntrances) or {}) do
            if (e.station or 'missionRow') == station then return e end
        end
        return nil
    end

    -- Standard Arrest → submenu to choose which station to escort the suspect to.
    local stdSub = pool:AddSubMenu(menu, 'Standard Arrest (6 credits)', 'Escort the suspect to a station — full credits')
    local function addStation(label, station)
        local item = NativeUI.CreateItem(label, 'Set GPS and escort the suspect here')
        item._station = station
        stdSub:AddItem(item)
    end
    addStation('Mission Row', 'missionRow')
    addStation('Vespucci',    'vespucci')
    -- Open the station list at the top (Mission Row), not the last item.
    stdSub.Pagination.Min = 0
    stdSub.Pagination.Max = stdSub.Pagination.Total
    stdSub:CurrentSelection(0)
    stdSub.OnItemSelect = function(_, item)
        if item._station then
            local e = entranceFor(item._station)
            if e and e.center then
                SetNewWaypoint(e.center.x + 0.0, e.center.y + 0.0)
                CnR.NativeUI.notify(('Take the suspect to the ~b~%s~s~ arrest point — GPS set.'):format(
                    item._station == 'vespucci' and 'Vespucci' or 'Mission Row'))
            end
            closeAll()   -- fully close the menu (incl. this submenu) after choosing #5
        end
    end

    -- Instant Arrest → jail immediately for fewer credits.
    local instant = NativeUI.CreateItem('Instant Arrest (3 credits)', 'Jail the suspect immediately for fewer credits')
    instant._instant = true
    menu:AddItem(instant)

    menu.OnItemSelect = function(_, item)
        if item._instant then
            TriggerServerEvent('cnr:server:instantArrest', { target = targetSid })
            closeAll()   -- close the menu after choosing #5
        end
    end

    menu.Pagination.Min = 0
    menu.Pagination.Max = menu.Pagination.Total
    menu:CurrentSelection(0)
    menu:Visible(true)
end

