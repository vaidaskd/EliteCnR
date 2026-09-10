CnR = CnR or {}
CnR.RankPreview = CnR.RankPreview or {}

local savedState = nil

local function requestModelBlocking(model)
    local hash = (type(model) == 'string') and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 200 do
        Wait(25); tries = tries + 1
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

function CnR.RankPreview.save()
    local ped = PlayerPedId()
    savedState = {
        model = GetEntityModel(ped),
        skin  = CnR.RankPreview._profileSkin,
        outfitId = CnR.RankPreview._profileOutfit or 1,
    }
end

function CnR.RankPreview.setProfileContext(skin, outfitId)
    CnR.RankPreview._profileSkin = skin
    CnR.RankPreview._profileOutfit = outfitId or 1
end

function CnR.RankPreview.apply(outfitId, skinName, profileSkin)
    local ped = PlayerPedId()
    profileSkin = profileSkin or CnR.RankPreview._profileSkin

    if type(profileSkin) == 'table' and profileSkin.isCustom then
        local modelName = (profileSkin.gender == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
        local hash = requestModelBlocking(modelName)
        if hash and GetEntityModel(ped) ~= hash then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            Wait(100)
            ped = PlayerPedId()
        end
        CnR.Util.ApplyCustomAppearance(ped, profileSkin, 'cop', outfitId or 1)
    elseif CnR.Util and CnR.Util.NormalizeCopSkin then
        local skin = CnR.Util.NormalizeCopSkin(skinName)
        CnR.RankPreview.apply(outfitId, nil, skin)
    elseif skinName then
        local hash = requestModelBlocking(skinName)
        if hash then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            Wait(100)
        end
    end
end

function CnR.RankPreview.restore()
    if not savedState then return end
    if savedState.skin then
        CnR.RankPreview.apply(savedState.outfitId, type(savedState.skin) == 'string' and savedState.skin or nil, savedState.skin)
    else
        local hash = requestModelBlocking(savedState.model)
        if hash then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            Wait(100)
        end
    end
    savedState = nil
end

function CnR.RankPreview.clear()
    savedState = nil
end
