CnR = CnR or {}
CnR.State = CnR.State or {
    sides = {},
}
CnR.Util  = CnR.Util  or {}

CnR.Sides = { COP = 'cop', ROBBER = 'robber', NONE = 'none' }

local DEFAULT_FREEMODE_SKINS = {
    male = {
        isCustom = true,
        gender = 'male',
        father = 0,
        mother = 0,
        shapeMix = 0.5,
        skinMix = 0.5,
        eyes = 0,
        hair = 4,
        hairColor = 2,
        beard = 0,
        beardColor = 0,
        top = 1,
        topTxt = 0,
        pants = 1,
        pantsTxt = 0,
        shoes = 1,
        shoesTxt = 0,
        arms = 0,
    },
    female = {
        isCustom = true,
        gender = 'female',
        father = 0,
        mother = 0,
        shapeMix = 0.5,
        skinMix = 0.5,
        eyes = 0,
        hair = 4,
        hairColor = 2,
        beard = 0,
        beardColor = 0,
        top = 3,
        topTxt = 0,
        pants = 1,
        pantsTxt = 0,
        shoes = 3,
        shoesTxt = 0,
        arms = 14,
    },
}

function CnR.Util.log(level, msg, ...)
    local prefix = '[cnr]'
    if level and level ~= '' then prefix = prefix .. '[' .. tostring(level) .. ']' end
    local ok, formatted = pcall(string.format, msg, ...)
    if not ok then formatted = tostring(msg) end
    print(prefix .. ' ' .. formatted)
end

function CnR.Util.tableCopy(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            local inner = {}
            for ik, iv in pairs(v) do inner[ik] = iv end
            out[k] = inner
        else
            out[k] = v
        end
    end
    return out
end

function CnR.Util.DefaultFreemodeSkin(gender)
    gender = (gender == 'female') and 'female' or 'male'
    return CnR.Util.tableCopy(DEFAULT_FREEMODE_SKINS[gender])
end

function CnR.Util.NormalizeCopSkin(skin)
    if type(skin) == 'table' and skin.isCustom then
        local out = CnR.Util.tableCopy(skin)
        out.isCustom = true
        out.gender = (out.gender == 'female') and 'female' or 'male'
        if out.gender == 'female' then
            out.beard = 0
            out.beardColor = 0
        end
        return out
    end
    if skin == 'mp_f_freemode_01' or skin == 'female' then
        return CnR.Util.DefaultFreemodeSkin('female')
    end
    return CnR.Util.DefaultFreemodeSkin('male')
end

function CnR.Util.contains(tbl, value)
    if type(tbl) ~= 'table' then return false end
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

function CnR.Util.now()
    return os.time()
end

function CnR.Util.rankFromXp(xp)
    xp = tonumber(xp) or 0
    local result = nil
    if not (Config and Config.Ranks) then return nil end
    for _, r in ipairs(Config.Ranks) do
        if xp >= (r.xp or 0) then
            result = r
        else
            break
        end
    end
    return result
end

function CnR.Util.rankById(id)
    if not (Config and Config.Ranks) then return nil end
    for _, r in ipairs(Config.Ranks) do
        if r.id == id then return r end
    end
    return nil
end

-- Robber progression (separate ladder from cops). Level derived from the same
-- profile.xp value, read against Config.RobberRanks.
function CnR.Util.robberRankFromXp(xp)
    xp = tonumber(xp) or 0
    local result = nil
    if not (Config and Config.RobberRanks) then return nil end
    for _, r in ipairs(Config.RobberRanks) do
        if xp >= (r.xp or 0) then result = r else break end
    end
    return result
end

function CnR.Util.robberLevel(xp)
    local r = CnR.Util.robberRankFromXp(xp)
    return r and r.id or 1
end

if not IsDuplicityVersion() then
    local function componentValue(ped, component, drawable, texture)
        local maxDrawable = GetNumberOfPedDrawableVariations(ped, component) or 0
        drawable = math.max(0, math.min(tonumber(drawable) or 0, math.max(0, maxDrawable - 1)))

        local maxTexture = GetNumberOfPedTextureVariations(ped, component, drawable) or 0
        texture = math.max(0, math.min(tonumber(texture) or 0, math.max(0, maxTexture - 1)))
        return drawable, texture
    end

    function CnR.Util.SetComponentSafe(ped, component, drawable, texture, palette)
        if not ped or not DoesEntityExist(ped) then return end
        local d, t = componentValue(ped, component, drawable, texture)
        SetPedComponentVariation(ped, component, d, t, palette or 0)
    end

    -- For STREAMED clothing (EUP / addon .ytd like prison_outfit): the texture must
    -- be preloaded into the ped's component-variation pool first, otherwise it shows
    -- as a checkerboard. Drawable indices here are the high *runtime* indices the game
    -- appends streamed drawables at — NOT the numbers in the filenames.
    function CnR.Util.SetComponentEUP(ped, component, drawable, texture)
        if not ped or not DoesEntityExist(ped) then return end
        local maxD = GetNumberOfPedDrawableVariations(ped, component) or 0
        drawable = math.max(0, math.min(tonumber(drawable) or 0, math.max(0, maxD - 1)))
        local maxT = GetNumberOfPedTextureVariations(ped, component, drawable) or 0
        texture  = math.max(0, math.min(tonumber(texture) or 0, math.max(0, maxT - 1)))
        SetPedPreloadVariationData(ped, component, drawable, texture)
        local deadline = GetGameTimer() + 600
        while not HasPedPreloadVariationDataFinished(ped) and GetGameTimer() < deadline do
            Wait(0)
        end
        SetPedComponentVariation(ped, component, drawable, texture, 0)
    end

    function CnR.Util.SetPropSafe(ped, prop, drawable, texture, attach)
        if not ped or not DoesEntityExist(ped) then return end
        drawable = tonumber(drawable)
        if not drawable or drawable < 0 then
            ClearPedProp(ped, prop)
            return
        end
        local maxDrawable = GetNumberOfPedPropDrawableVariations(ped, prop) or 0
        drawable = math.max(0, math.min(drawable, math.max(0, maxDrawable - 1)))
        local maxTexture = GetNumberOfPedPropTextureVariations(ped, prop, drawable) or 0
        texture = math.max(0, math.min(tonumber(texture) or 0, math.max(0, maxTexture - 1)))
        SetPedPropIndex(ped, prop, drawable, texture, attach == true)
    end

    -- Resolve a Police Clothing outfit (Config.Outfits) by id, falling back to the
    -- first entry. Returns the gender-specific component table.
    local function outfitComponents(gender, outfitId)
        local outfits = (Config and Config.Outfits) or {}
        local chosen = outfits[1]
        for _, o in ipairs(outfits) do
            if o.id == outfitId then chosen = o; break end
        end
        if not chosen then return nil end
        return (gender == 'female') and chosen.female or chosen.male
    end

    -- Apply a flat clothing table (the Config.Outfits / capture / clothing-store
    -- structure) to a freemode ped. EUP/streamed garments live at high drawable
    -- indices and must be preloaded or they checkerboard -> SetComponentEUP.
    -- Only applies the components actually present in `o`, so the clothing browser
    -- (which only touches the pack's slots) leaves everything else untouched.
    function CnR.Util.ApplyCopClothes(ped, o)
        if not ped or not DoesEntityExist(ped) or type(o) ~= 'table' then return end

        -- Queue ALL the streamed (EUP) garment slots first, then wait once, then
        -- apply. SetPedPreloadVariationData only tracks one pending request at a time,
        -- so preloading + applying each slot individually leaves the others
        -- untextured. Batching makes the whole uniform stream in together.
        local slots = {
            { 11, o.top,        o.topTxt },        -- jbib
            { 4,  o.pants,      o.pantsTxt },      -- lowr
            { 6,  o.shoes,      o.shoesTxt },      -- feet
            { 8,  o.undershirt, o.undershirtTxt }, -- accs
            { 9,  o.armor,      o.armorTxt },      -- task
            { 5,  o.gloves,     o.glovesTxt },     -- hand
            { 3,  o.arms,       o.armsTxt },       -- uppr
            { 10, o.decl,       o.declTxt },       -- decal/badge
        }
        local pending = {}
        for _, s in ipairs(slots) do
            local comp, draw, tex = s[1], s[2], s[3] or 0
            if draw ~= nil then
                local maxD = GetNumberOfPedDrawableVariations(ped, comp) or 0
                draw = math.max(0, math.min(tonumber(draw) or 0, math.max(0, maxD - 1)))
                local maxT = GetNumberOfPedTextureVariations(ped, comp, draw) or 0
                tex = math.max(0, math.min(tonumber(tex) or 0, math.max(0, maxT - 1)))
                SetPedPreloadVariationData(ped, comp, draw, tex)
                pending[#pending + 1] = { comp, draw, tex }
            end
        end
        if #pending > 0 then
            local deadline = GetGameTimer() + 3000
            while not HasPedPreloadVariationDataFinished(ped) and GetGameTimer() < deadline do
                Wait(0)
            end
            for _, s in ipairs(pending) do
                SetPedComponentVariation(ped, s[1], s[2], s[3], 0)
            end
        end

        if o.mask      ~= nil then CnR.Util.SetComponentSafe(ped, 1, o.mask, o.maskTxt or 0, 0) end
        if o.accessory ~= nil then CnR.Util.SetComponentSafe(ped, 7, o.accessory, o.accessoryTxt or 0, 0) end
        -- Headwear/eyewear: the uniform owns the hat (prop 0). Always strip any
        -- clothing-store glasses (prop 1) and earpieces (prop 2) so robber cosmetics
        -- don't bleed into the cop look.
        if o.hat ~= nil then CnR.Util.SetPropSafe(ped, 0, o.hat, o.hatTxt or 0)
        else CnR.Util.SetPropSafe(ped, 0, -1, 0) end
        CnR.Util.SetPropSafe(ped, 1, -1, 0)
        CnR.Util.SetPropSafe(ped, 2, -1, 0)
    end

    function CnR.Util.ApplyCopUniform(ped, gender, outfitId)
        if not ped or not DoesEntityExist(ped) then return end
        gender = (gender == 'female') and 'female' or 'male'
        outfitId = tonumber(outfitId) or 1
        CnR.Util.ApplyCopClothes(ped, outfitComponents(gender, outfitId))
    end

    function CnR.Util.ApplyPrisonerClothes(ped)
        if not ped or not DoesEntityExist(ped) then return end
        local model = GetEntityModel(ped)
        local female = model == `mp_f_freemode_01`
        if model ~= `mp_m_freemode_01` and not female then return end

        -- Prefer the configured prison_outfit indices; fall back to plain values.
        local cfg = Config and Config.Jail and Config.Jail.prisonOutfit
        local o = cfg and (female and cfg.female or cfg.male)
        if o then
            -- Regular freemode drawables (not streamed), so SetComponentSafe with the
            -- captured drawable+texture for every part, including arms/sleeve texture.
            CnR.Util.SetComponentSafe(ped, 11, o.top and o.top.drawable or 0,   o.top and o.top.texture or 0, 0)   -- top  (jbib)
            CnR.Util.SetComponentSafe(ped, 4,  o.legs and o.legs.drawable or 0, o.legs and o.legs.texture or 0, 0) -- legs (lowr)
            CnR.Util.SetComponentSafe(ped, 6,  o.shoes and o.shoes.drawable or 5,      o.shoes and o.shoes.texture or 0, 0)
            CnR.Util.SetComponentSafe(ped, 8,  o.undershirt and o.undershirt.drawable or 0, o.undershirt and o.undershirt.texture or 0, 0)
            CnR.Util.SetComponentSafe(ped, 3,  o.arms and o.arms.drawable or 0,        o.arms and o.arms.texture or 0, 0)
            return
        end

        local outfit = female
            and { top = 5, pants = 4, shoes = 5, undershirt = 2, arms = 4 }
            or  { top = 5, pants = 5, shoes = 5, undershirt = 15, arms = 5 }
        CnR.Util.SetComponentSafe(ped, 11, outfit.top, 0, 0)
        CnR.Util.SetComponentSafe(ped, 4, outfit.pants, 0, 0)
        CnR.Util.SetComponentSafe(ped, 6, outfit.shoes, 0, 0)
        CnR.Util.SetComponentSafe(ped, 8, outfit.undershirt, 0, 0)
        CnR.Util.SetComponentSafe(ped, 3, outfit.arms, 0, 0)
    end

    function CnR.Util.ApplyCustomAppearance(ped, skin, side, outfitId)
        if not ped or not DoesEntityExist(ped) then return end
        if type(skin) ~= 'table' or not skin.isCustom then return end


        local father = tonumber(skin.father) or 0
        local mother = tonumber(skin.mother) or 0
        local shapeMix = tonumber(skin.shapeMix) or 0.5
        local skinMix = tonumber(skin.skinMix) or 0.5

        SetPedHeadBlendData(ped, father, mother, 0, father, mother, 0, shapeMix, skinMix, 0.0, false)


        local hair = tonumber(skin.hair) or 0
        local hairColor = tonumber(skin.hairColor) or 0
        CnR.Util.SetComponentSafe(ped, 2, hair, 0, 0)
        SetPedHairColor(ped, hairColor, 0)


        local eyes = tonumber(skin.eyes) or 0
        SetPedEyeColor(ped, eyes)


        if skin.gender == 'male' then
            local beard = tonumber(skin.beard) or 0
            local beardColor = tonumber(skin.beardColor) or 0
            if beard > 0 then
                SetPedHeadOverlay(ped, 1, beard, 0.99)
                SetPedHeadOverlayColor(ped, 1, 1, beardColor, beardColor)
            else
                SetPedHeadOverlay(ped, 1, 0, 0.0)
            end
        else
            SetPedHeadOverlay(ped, 1, 0, 0.0)
        end


        if side == 'cop' then
            CnR.Util.ApplyCopUniform(ped, skin.gender, outfitId or 1)
        else
            -- Strip whatever props GTA randomly assigned when the freemode model was set
            -- (helmets/earpieces/masks). Any hat/glasses/watch the player bought is
            -- re-applied a few lines down; robbers from the spawn menu get nothing.
            ClearAllPedProps(ped)

            local top = tonumber(skin.top) or 1
            local topTxt = tonumber(skin.topTxt) or 0
            local pants = tonumber(skin.pants) or 1
            local pantsTxt = tonumber(skin.pantsTxt) or 0
            local shoes = tonumber(skin.shoes) or 1
            local shoesTxt = tonumber(skin.shoesTxt) or 0
            local arms = tonumber(skin.arms) or 0
            -- Undershirt (component 8) is part of the curated outfit so it matches the
            -- torso/jacket. It was previously hardcoded to 15, which left waist/torso gaps
            -- on tops that expect a different (or no) undershirt.
            local undershirt = tonumber(skin.undershirt) or 0
            local undershirtTxt = tonumber(skin.undershirtTxt) or 0

            CnR.Util.SetComponentSafe(ped, 11, top, topTxt, 0)
            CnR.Util.SetComponentSafe(ped, 4, pants, pantsTxt, 0)
            CnR.Util.SetComponentSafe(ped, 6, shoes, shoesTxt, 0)
            CnR.Util.SetComponentSafe(ped, 3, arms, 0, 0)
            CnR.Util.SetComponentSafe(ped, 8, undershirt, undershirtTxt, 0)
            CnR.Util.SetComponentSafe(ped, 1, tonumber(skin.mask) or 0, tonumber(skin.maskTxt) or 0, 0)  -- mask
            CnR.Util.SetComponentSafe(ped, 7, 0, 0, 0)
            -- Headwear / eyewear / watch: re-apply anything bought at the clothing store;
            -- otherwise clear it. Earpieces (prop 2) are always cleared.
            CnR.Util.SetPropSafe(ped, 0, tonumber(skin.hat)     or -1, tonumber(skin.hatTxt)     or 0, true)
            CnR.Util.SetPropSafe(ped, 1, tonumber(skin.glasses) or -1, tonumber(skin.glassesTxt) or 0, true)
            CnR.Util.SetPropSafe(ped, 6, tonumber(skin.watch)   or -1, tonumber(skin.watchTxt)   or 0, true)
            CnR.Util.SetPropSafe(ped, 2, -1, 0)
        end
    end
end
