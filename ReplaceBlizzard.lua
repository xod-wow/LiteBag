--[[----------------------------------------------------------------------------

  LiteBag/ReplaceBlizzard.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

-- A popup dialog for confirming the bag sort.
StaticPopupDialogs['LB_CONFIRM_SORT'] = {
    preferredIndex = STATICPOPUP_NUMDIALOGS,
    text = '%s\n'..CONFIRM_CONTINUE,
    button1 = YES,
    button2 = NO,
    -- sound = 'UI_BagSorting_01',
    OnAccept = function (self, func) func() end,
    hideOnEscape = 1,
    timeout = 0,
}

-- Don't show the confirm popup if the shift key is held.
local function DoOrStaticPopup(text, func)
    if IsShiftKeyDown() or LB.Options:GetGlobalOption('NoConfirmSort') then
        func()
    else
        StaticPopup_Show('LB_CONFIRM_SORT', text, nil, func)
    end
end

-- Added to the bag sort tooltip.  Would be nice if it were localized.
local TOOLTIP_NOCONFIRM_TEXT = format(L["%s: No confirmation"], SHIFT_KEY)

local hiddenParent = CreateFrame('Frame')
hiddenParent:Hide()

local REPLACEMENT_GLOBALS = {

    OpenBag =
        function (id)
        if LiteBagBackpack:MatchesBagID(id) then
            LiteBagBackpack:Show()
        end
    end,

    CloseBag =
        function (id)
        end,

    ToggleBag =
        function (id)
        end,

    OpenAllBags =
        function ()
            LiteBagBackpack:Show()
            EventRegistry:TriggerEvent("ContainerFrame.OpenAllBags");
        end,

    CloseAllBags =
        function ()
            LiteBagBackpack:Hide()
            EventRegistry:TriggerEvent("ContainerFrame.CloseAllBags");
        end,

    ToggleAllBags =
        function ()
            if LiteBagBackpack:IsShown() then
                CloseAllBags()
            else
                OpenAllBags()
            end
        end,

    OpenBackpack =
         function ()
            LiteBagBackpack:Show()
        end,

    CloseBackpack =
        function ()
            LiteBagBackpack:Hide()
        end,

    ToggleBackpack =
        function ()
            LiteBagBackpack:SetShown(not LiteBagBackpack:IsShown())
        end,

    IsBagOpen =
        function (id)
            if LiteBagBackpack:IsShown() then
                return LiteBagBackpack:GetCurrentPanel():MatchesBagID(id)
            elseif LiteBagBank:IsShown() then
                return LiteBagBank:GetCurrentPanel():MatchesBagID(id)
            end
        end,

    -- The ReagentBag and Professions tutorials need this.
    -- I don't feel good about this at all. I see taint on the horizon.

    ContainerFrameUtil_GetShownFrameForID =
        function (id)
            if LiteBagBackpackPanel:IsShown() and LiteBagBackpackPanel:MatchesBagID(id) then
                return LiteBagBackpackPanel, 1
            end
        end,
}

local function ReplaceGlobals()
    for n, f in pairs(REPLACEMENT_GLOBALS) do
        _G[n] = f
    end
end

local function HideBlizzardBags()

    -- Turn the Blizzard frames off
    for i=1, NUM_CONTAINER_FRAMES do
        local f = _G['ContainerFrame'..i]
        f:SetParent(hiddenParent)
        f:UnregisterAllEvents()
    end
    ContainerFrameCombinedBags:SetParent(hiddenParent)
    ContainerFrameCombinedBags:UnregisterAllEvents()
end

local function HideBlizzardBank()

    -- The reagent bank in WoW 6.0 changed UseContainerItem() to have a
    -- fourth argument which is true/false 'should we put this thing into
    -- the reagent bank', which ContainerFrameItemButton_OnClick sets with
    --      BankFrame:IsShown() and (BankFrame.selectedTab == 2)
    -- Since we can't override the secure OnClick handler and we can't
    -- change BankFrame without tainting, we have to reparent it, hide it
    -- via the parent, and set its selectedTab and hide/show manually in sync
    -- with ours.

    BankFrame:SetParent(hiddenParent)
    BankFrame:ClearAllPoints()
    BankFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
    BankFrame:UnregisterAllEvents()
    BankFrame:SetScript('OnShow', function () end)
    BankFrame:SetScript('OnHide', function () end)

    LiteBagBank:HookScript('OnShow', function () BankFrame:Show() end)
    LiteBagBank:HookScript('OnHide', function () BankFrame:Hide() end)
end

local function AddSortConfirmations()

    -- Add the confirm text to the sort button mouseover tooltip.
    BagItemAutoSortButton:HookScript('OnEnter', function (self)
        if not LB.Options:GetGlobalOption('NoConfirmSort') then
            GameTooltip:AddLine(TOOLTIP_NOCONFIRM_TEXT, 1, 1, 1)
        end
        GameTooltip:Show()
        end)

    -- Change the sort button to call our confirm function.
    BagItemAutoSortButton:SetScript('OnClick', function (self)
            DoOrStaticPopup(BAG_CLEANUP_BAGS, C_Container.SortBags)
        end)
    -- Add the confirm text to the sort button tooltip.

    BankItemAutoSortButton:HookScript('OnEnter', function (self)
        if not LB.Options:GetGlobalOption('NoConfirmSort') then
            GameTooltip:AddLine(TOOLTIP_NOCONFIRM_TEXT, 1, 1, 1)
        end
        GameTooltip:Show()
        end)

    -- Change the sort button to call our confirm function.

    BankItemAutoSortButton:SetScript('OnClick', function ()
            local self = BankFrame
            if (self.activeTabIndex == 1) then
                DoOrStaticPopup(BAG_CLEANUP_BANK, C_Container.SortBankBags)
            elseif (self.activeTabIndex == 2) then
                DoOrStaticPopup(BAG_CLEANUP_REAGENT_BANK, C_Container.SortReagentBankBags)
            end
        end)
end

-- This is a bit of an arms race with other addon authors who want to hook
-- the bags too, try to hook later than them all.
-- Also register here some other open/close events I liked.

local LiteBagManager = CreateFrame('Frame', 'LiteBagManager', UIParent)

function LiteBagManager:ReplaceBlizzard()
    HideBlizzardBags()
    HideBlizzardBank()
    ReplaceGlobals()
    AddSortConfirmations()
end

function LiteBagManager:ManageBlizzardBagButtons()
    local show = not LB.Options:GetGlobalOption('HideBlizzardBagButtons')
    for _, bagButton in MainMenuBarBagManager:EnumerateBagButtons() do
        bagButton:SetShown(show)
        bagButton:SetParent(show and MicroButtonAndBagsBar or hiddenParent)
    end
    BagBarExpandToggle:SetShown(show)
end

function LiteBagManager:OnEvent(event, ...)
    -- As far as I can tell this doesn't work. Why?
    if event == 'PLAYER_INTERACTION_MANAGER_FRAME_SHOW' then
        local type = ...
        if type == Enum.PlayerInteractionType.GuildBanker then
            OpenAllBags()
        end
    elseif event == 'PLAYER_INTERACTION_MANAGER_FRAME_HIDE' then
        local type = ...
        if type == Enum.PlayerInteractionType.GuildBanker then
            CloseAllBags()
        end
    elseif event == 'PLAYER_LOGIN' then
        self:ReplaceBlizzard()
        self:ManageBlizzardBagButtons()
        self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
        self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')
        LB.db.RegisterCallback(self, 'OnOptionsModified', self.ManageBlizzardBagButtons)
    end
end

LiteBagManager:RegisterEvent('PLAYER_LOGIN')
LiteBagManager:SetScript('OnEvent', LiteBagManager.OnEvent)

_G.LB = LB
