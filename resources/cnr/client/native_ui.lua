
CnR = CnR or {}
CnR.NativeUI = CnR.NativeUI or {}

CnR.NativeUI.pool = NativeUI.CreatePool()

local MENU_WIDTH_OFFSET = 70
local MENU_TOP = 118
local MENU_RIGHT_MARGIN = 28

local function menuLeft()
    local aspectRatio = GetAspectRatio(false)

    if not aspectRatio or aspectRatio <= 0 then
        aspectRatio = 16.0 / 9.0
    end

    -- NativeUI uses a 1080-height coordinate system.
    local width = 1080.0 * aspectRatio

    return math.max(
        0,
        width - (431 + MENU_WIDTH_OFFSET) - MENU_RIGHT_MARGIN
    )
end


local function moveMenu(menu)
    if not menu then return end

    local x = menuLeft()
    local y = MENU_TOP
    local width = 431 + MENU_WIDTH_OFFSET

    menu.Position.X = x
    menu.Position.Y = y

    if menu.Logo then
        menu.Logo:Position(x, y)
        menu.Logo:Size(width, 107)
    end

    if menu.Banner then
        menu.Banner:Position(x, y)
        menu.Banner:Size(width, 107)
    end

    if menu.Title then
        menu.Title:Position(x + (width / 2), y + 18)
        menu.Title.Scale = 1.05
        menu.Title.Font = 1
        menu.Title:Colour(255, 255, 255, 255)
    end

    if menu.Subtitle then
        if menu.Subtitle.Rectangle then
            menu.Subtitle.Rectangle:Position(x, y + 107)
            menu.Subtitle.Rectangle:Size(width, menu.Subtitle.ExtraY or 37)
            menu.Subtitle.Rectangle:Colour(0, 0, 0, 225)
        end
        if menu.Subtitle.Text then
            menu.Subtitle.Text:Position(x + 12, y + 110)
            menu.Subtitle.Text.Scale = 0.37
            menu.Subtitle.Text:Colour(65, 130, 225, 255)
        end
    end

    if menu.PageCounter and menu.PageCounter.Text then
        menu.PageCounter.Text:Position(x + width - 8, y + 110)
        menu.PageCounter.Text:Colour(65, 130, 225, 255)
    end

    if menu.Background then
        menu.Background:Position(x, y + 144 - 37 + (menu.Subtitle.ExtraY or 0))
        menu.Background:Size(width, menu.Background.Height or 25)
        menu.Background:Colour(0, 0, 0, 155)
    end

    if menu.Description then
        if menu.Description.Bar then menu.Description.Bar:Colour(0, 0, 0, 255) end
        if menu.Description.Rectangle then menu.Description.Rectangle:Colour(0, 0, 0, 185) end
        if menu.Description.Text then menu.Description.Text:Colour(245, 245, 245, 255) end
    end

    if menu.Extra then
        if menu.Extra.Up then menu.Extra.Up:Colour(0, 0, 0, 210) end
        if menu.Extra.Down then menu.Extra.Down:Colour(0, 0, 0, 210) end
    end

    for i = 1, #(menu.Items or {}) do
        local item = menu.Items[i]
        if item and item.Offset then
            item:Offset(x, y)
        end
    end

    menu.ReDraw = true
end

local function styleMenu(menu)
    if not menu then return end

    if not menu.CnRStyled then
        if menu.Logo then
            menu:SetMenuWidthOffset(MENU_WIDTH_OFFSET)
        else
            menu.WidthOffset = MENU_WIDTH_OFFSET
        end
        menu:SetBannerRectangle(UIResRectangle.New(menuLeft(), MENU_TOP, 431 + MENU_WIDTH_OFFSET, 107, 0, 0, 0, 230))
        menu.CnRStyled = true
    end

    moveMenu(menu)
end

local rawCreateMenu = NativeUI.CreateMenu
function NativeUI.CreateMenu(title, subtitle, x, y, txtDictionary, txtName)
    local menu = rawCreateMenu(title, subtitle, menuLeft(), MENU_TOP, txtDictionary, txtName)
    styleMenu(menu)
    return menu
end

local rawUIMenuItemNew = UIMenuItem.New
function UIMenuItem.New(text, description)
    local item = rawUIMenuItemNew(text, description)
    item.Rectangle:Colour(0, 0, 0, 115)
    item.Text.Scale = 0.34
    item.SelectedSprite:Colour(255, 255, 255, 245)
    item.Label.MainColour = {R = 245, G = 245, B = 245, A = 255}
    item.Label.HighlightColour = {R = 0, G = 0, B = 0, A = 255}
    return item
end


local function harden(menu)
    if not menu or not menu.Settings then return end

    styleMenu(menu)
    menu.Settings.MouseControlsEnabled = false
    menu.Settings.MouseEdgeEnabled = false
    menu.Settings.ResetCursorOnOpen = false


    menu.Settings.ControlDisablingEnabled = false
end

local rawAdd = CnR.NativeUI.pool.Add
function CnR.NativeUI.pool:Add(menu)
    rawAdd(self, menu)
    harden(menu)
end

local rawAddSubMenu = CnR.NativeUI.pool.AddSubMenu
function CnR.NativeUI.pool:AddSubMenu(menu, text, description, keepPosition, keepBanner)
    local sub = rawAddSubMenu(self, menu, text, description, keepPosition, keepBanner)
    harden(sub)
    return sub
end


CnR.NativeUI.pool:MouseEdgeEnabled(false)


local MENU_BLOCKED_CONTROLS = {
    24, 25, 37, 44, 47, 58, 140, 141, 142, 143,
}


local MENU_NAV_CONTROLS = {
    172, 173, 174, 175, 176, 177,
    187, 188, 189, 190,
    191, 194, 195, 196,
    201, 202, 217,
    241, 242,
}

local LOOK_CONTROLS = { 1, 2, 3, 4, 5, 6 }

local function prepareMenuControls()
    for i = 1, #MENU_NAV_CONTROLS do
        DisableControlAction(0, MENU_NAV_CONTROLS[i], true)
    end
    for i = 1, #LOOK_CONTROLS do
        EnableControlAction(0, LOOK_CONTROLS[i], true)
    end
end

local function suppressGameplayControls()
    for i = 1, #MENU_BLOCKED_CONTROLS do
        DisableControlAction(0, MENU_BLOCKED_CONTROLS[i], true)
    end
end
CnR.NativeUI.suppressGameplayControls = suppressGameplayControls

function CnR.NativeUI.isOpen()
    for _, m in pairs(CnR.NativeUI.pool.Menus or {}) do
        if m and m:Visible() then
            return true
        end
    end
    return false
end

function CnR.NativeUI.closeAll()
    for _, m in pairs(CnR.NativeUI.pool.Menus or {}) do
        if m and m:Visible() then
            m:Visible(false)
        end
    end
end


CreateThread(function()
    while true do
        Wait(0)
        if CnR.NativeUI.isOpen() then
            prepareMenuControls()
            suppressGameplayControls()
            DisablePlayerFiring(PlayerId(), true)
        end
        CnR.NativeUI.pool:ProcessMenus()
    end
end)

-- Show a single notification at a time: remove the previous one before posting the next.
-- The GTA feed both de-dupes identical posts AND queues a backlog, so spamming lock/unlock
-- made it freeze after a handful. Replacing the prior item keeps it instant and unstuck.
local _lastNotif = nil
function CnR.NativeUI.notify(text)
    if _lastNotif then pcall(ThefeedRemoveItem, _lastNotif) end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(text))
    _lastNotif = EndTextCommandThefeedPostTicker(false, true)
end

function CnR.NativeUI.keyboardInput(title, default, maxLen)
    AddTextEntry('CNR_KB', title)
    DisplayOnscreenKeyboard(1, 'CNR_KB', '', default or '', '', '', '', maxLen or 120)
    while UpdateOnscreenKeyboard() == 0 do Wait(0) end
    if UpdateOnscreenKeyboard() == 1 then
        return GetOnscreenKeyboardResult()
    end
    return nil
end
