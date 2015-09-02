--[[----------------------------------------------------------------------------

  LiteBag/ReplaceBlizzard.lua

  Copyright 2013-2015 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- A popup dialog for confirming the bag sort.
StaticPopupDialogs["LM_CONFIRM_SORT"] = {
    preferredIndex = STATICPOPUPS_NUMDIALOGS,
    text = "%s\n"..CONFIRM_CONTINUE,
    button1 = YES,
    button2 = NO,
    -- sound = "UI_BagSorting_01",
    OnAccept = function (self, func) func() end,
    hideOnEscape = 1,
    timeout = 0,
}

-- Don't show the confirm popup if the shift key is held.
local function DoOrStaticPopup(text, func)
    if IsShiftKeyDown() or LiteBag_GetGlobalOption("NoConfirmSort") then
        func()
    else
        StaticPopup_Show("LM_CONFIRM_SORT", text, nil, func)
    end
end

-- Added to the bag sort tooltip.  Would be nice if it were localized.
local TOOLTIP_NOCONFIRM_TEXT = format("%s: No confirmation", SHIFT_KEY)

function LiteBag_ReplaceBlizzardInventory()
    local hideFunc = function () LiteBagFrame_Hide(LiteBagInventory) end
    local showFunc = function () LiteBagFrame_Show(LiteBagInventory) end
    local toggleFunc = function () LiteBagFrame_ToggleShown(LiteBagInventory) end

    -- Turn our Inventory frame on.
    LiteBagFrame_RegisterHideShowEvents(LiteBagInventory)

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
    OpenBag = function (bag)
                    if LiteBagFrame_IsMyBag(LiteBagInventory, bag) then
                        LiteBagFrame_Show(LiteBagInventory)
                    end
                end

    -- These are the bag buttons in the menu bar at the bottom which are
    -- highlighted when their particular bag is opened.
    BagSlotButton_UpdateChecked = function () end

    -- Add the confirm text to the sort button mouseover tooltip.
    BagItemAutoSortButton:HookScript("OnEnter", function (self)
        if not LiteBag_GetGlobalOption("NoConfirmSort") then
            GameTooltip:AddLine(TOOLTIP_NOCONFIRM_TEXT, 1, 1, 1)
        end
        GameTooltip:Show()
        end)

    -- Change the sort button to call our confirm function.
    BagItemAutoSortButton:SetScript("OnClick", function (self)
            DoOrStaticPopup(BAG_CLEANUP_BAGS, SortBags)
        end)
end

function LiteBag_ReplaceBlizzardBank()

    -- Turn our Bag frame on.
    LiteBagFrame_RegisterHideShowEvents(LiteBagBank)

    -- The reagent bank in WoW 6.0 changed UseContainerItem() to have a
    -- fourth argument which is true/false "should we put this thing into
    -- the reagent bank", which ContainerFrameItemButton_OnClick sets with
    --      BankFrame:IsShown() and (BankFrame.selectedTab == 2)
    -- Since we can't override the secure OnClick handler and we can't
    -- change BankFrame without tainting, we have to reparent it, hide it
    -- via the parent, and set its selectedTab and hide/show manually in sync
    -- with ours.

    local hiddenBankParent = CreateFrame("Frame")
    hiddenBankParent:Hide()
    BankFrame:SetParent(hiddenBankParent)
    BankFrame:ClearAllPoints()
    BankFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    BankFrame:UnregisterAllEvents()
    BankFrame:SetScript("OnShow", function () end)
    BankFrame:SetScript("OnHide", function () end)

    LiteBagBank.Tab1:HookScript("OnClick", function () BankFrame.selectedTab = 1 end)
    LiteBagBank.Tab2:HookScript("OnClick", function () BankFrame.selectedTab = 2 end)
    LiteBagBank:HookScript("OnShow", function () BankFrame:Show() end)
    LiteBagBank:HookScript("OnHide", function () BankFrame:Hide() end)


    -- Add the confirm text to the sort button tooltip. I think we could
    -- probably HookScript this now instead of SetScript.  The SetScript is
    -- left over from when we weren't doing the BankFrame tab fake-up, above.
    -- 
    -- BankItemAutoSortButton:HookScript("OnEnter", function (self)
    --     if not LM_GetGlobalOption("NoConfirmSort") then
    --         GameTooltip:AddLine(TOOLTIP_NOCONFIRM_TEXT, 1, 1, 1)
    --     end
    --     GameTooltip:Show()
    --     end)
    BankItemAutoSortButton:SetScript("OnEnter", function (self)
            GameTooltip:SetOwner(self)
            if self:GetParent().selectedTab == 1 then
                GameTooltip:SetText(BAG_CLEANUP_BANK)
            else
                GameTooltip:SetText(BAG_CLEANUP_REAGENT_BANK)
            end
            GameTooltip:AddLine(TOOLTIP_NOCONFIRM_TEXT, 1, 1, 1)
            GameTooltip:Show()
        end)

    -- Change the sort button to call our confirm function.
    BankItemAutoSortButton:SetScript("OnClick", function (self)
            local parent = self:GetParent()
            if (parent.selectedTab == 1) then
                DoOrStaticPopup(BAG_CLEANUP_BANK, SortBankBags)
            elseif (parent.selectedTab == 2) then
                DoOrStaticPopup(BAG_CLEANUP_REAGENT_BANK, SortReagentBankBags)
            end
        end)
end

LiteBag_ReplaceBlizzardInventory()
LiteBag_ReplaceBlizzardBank()
