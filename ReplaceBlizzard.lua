--[[----------------------------------------------------------------------------

  LiteBag/ReplaceBlizzard.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local L = LiteBag_Localize

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
    if IsShiftKeyDown() or LiteBag_GetGlobalOption('NoConfirmSort') then
        func()
    else
        StaticPopup_Show('LB_CONFIRM_SORT', text, nil, func)
    end
end

-- Added to the bag sort tooltip.  Would be nice if it were localized.
local TOOLTIP_NOCONFIRM_TEXT = format(L["%s: No confirmation"], SHIFT_KEY)

local hiddenBagParent = CreateFrame('Frame')

local function ReplaceBlizzardInventory()
    local hideFunc =
        function (caller)
            LiteBagInventory:Hide()
        end
    local showFunc = function (caller)
            if LiteBagInventory:IsShown() then
                LiteBagInventory:UpdateAllBags()
            else
                LiteBagInventory:Show()
            end
        end
    local toggleFunc = function (caller)
            if LiteBagInventory:IsShown() then
                LiteBagInventory:Hide()
            else
                LiteBagInventory:Show()
            end
        end

    hiddenBagParent:Hide()

    -- Turn the Blizzard frames off
    for i=1, NUM_CONTAINER_FRAMES do
        local f = _G['ContainerFrame'..i]
        f:SetParent(hiddenBagParent)
        f:UnregisterAllEvents()
    end
                
    -- Override or hook various Blizzard UI functions to operate on our
    -- frame instead.
    OpenBackpack = showFunc
    OpenAllBags = showFunc

    ToggleBag = toggleFunc
    ToggleAllBags = toggleFunc

    hooksecurefunc('CloseBackpack', hideFunc)
    hooksecurefunc('CloseAllBags', hideFunc)

    -- This one is called when you click on a loot popup and you have
    -- one of those items in your bag already.
    OpenBag = showFunc

    -- These are the bag buttons in the menu bar at the bottom which are
    -- highlighted when their particular bag is opened.
    BagSlotButton_UpdateChecked = function () end

    -- Add the confirm text to the sort button mouseover tooltip.
    BagItemAutoSortButton:HookScript('OnEnter', function (self)
        if not LiteBag_GetGlobalOption('NoConfirmSort') then
            GameTooltip:AddLine(TOOLTIP_NOCONFIRM_TEXT, 1, 1, 1)
        end
        GameTooltip:Show()
        end)

    -- Change the sort button to call our confirm function.
    BagItemAutoSortButton:SetScript('OnClick', function (self)
            DoOrStaticPopup(BAG_CLEANUP_BAGS, SortBags)
        end)

end

local hiddenBankParent = CreateFrame('Frame')

local function ReplaceBlizzardBank()

    -- The reagent bank in WoW 6.0 changed UseContainerItem() to have a
    -- fourth argument which is true/false 'should we put this thing into
    -- the reagent bank', which ContainerFrameItemButton_OnClick sets with
    --      BankFrame:IsShown() and (BankFrame.selectedTab == 2)
    -- Since we can't override the secure OnClick handler and we can't
    -- change BankFrame without tainting, we have to reparent it, hide it
    -- via the parent, and set its selectedTab and hide/show manually in sync
    -- with ours.

    hiddenBankParent:Hide()
    BankFrame:SetParent(hiddenBankParent)
    BankFrame:ClearAllPoints()
    BankFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
    BankFrame:UnregisterAllEvents()
    BankFrame:SetScript('OnShow', function () end)
    BankFrame:SetScript('OnHide', function () end)

    LiteBagBank:HookScript('OnShow', function () BankFrame:Show() end)
    LiteBagBank:HookScript('OnHide', function () BankFrame:Hide() end)

    -- Add the confirm text to the sort button tooltip.

    BankItemAutoSortButton:HookScript('OnEnter', function (self)
        if not LiteBag_GetGlobalOption('NoConfirmSort') then
            GameTooltip:AddLine(TOOLTIP_NOCONFIRM_TEXT, 1, 1, 1)
        end
        GameTooltip:Show()
        end)

    -- Change the sort button to call our confirm function.

    BankItemAutoSortButton:SetScript('OnClick', function (self)
            local parent = self:GetParent()
            if (parent.selectedTab == 1) then
                DoOrStaticPopup(BAG_CLEANUP_BANK, SortBankBags)
            elseif (parent.selectedTab == 2) then
                DoOrStaticPopup(BAG_CLEANUP_REAGENT_BANK, SortReagentBankBags)
            end
        end)
end

local function ReplaceBlizzard()
    ReplaceBlizzardInventory()
    ReplaceBlizzardBank()

    -- Some other addons either replace the open functions themselves after
    -- us and cause the bag frames to show.
    for i=1, NUM_CONTAINER_FRAMES do
        local f = _G['ContainerFrame'..i]
        f:SetScript('OnShow', function (self)
                self:Hide()
                LiteBagInventory:Show()
                ReplaceBlizzardInventory()
            end)
        f:SetScript('OnHide', nil)
    end
end

-- This is a bit of an arms race with other addon authors who want to hook
-- the bags too, try to hook later than them all.

local replacer = CreateFrame('Frame', UIParent)
replacer:SetScript('OnEvent', function () ReplaceBlizzard() end)
replacer:RegisterEvent('PLAYER_LOGIN')
