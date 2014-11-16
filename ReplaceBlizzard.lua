--[[----------------------------------------------------------------------------

  LiteBag/ReplaceBlizzard.lua

  Copyright 2013-2014 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local inventoryFrame, bankFrame

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

local function DoOrStaticPopup(text, func)
    if IsShiftKeyDown() then
        func()
    else
        StaticPopup_Show("LM_CONFIRM_SORT", text, nil, func)
    end
end

function LiteBagFrame_ReplaceBlizzard(inventory, bank)


    inventoryFrame = inventory
    bankFrame = bank

    -- The reagent bank in WoW 6.0 changed UseContainerItem() to have a
    -- fourth argument which is true/false "should we put this thing into
    -- the reagent bank", which ContainerFrameItemButton_OnClick sets with
    --      BankFrame:IsShown() and (BankFrame.selectedTab == 2)
    -- Since we can't override the secure OnClick handler we have to do
    -- something with BankFrame.  I have a horrible feeling this might
    -- cause taint.

    BankFrame:UnregisterAllEvents()
    BankFrame = bankFrame

    local hideFunc = function () LiteBagFrame_Hide(inventoryFrame) end
    local showFunc = function () LiteBagFrame_Show(inventoryFrame) end
    local toggleFunc = function () LiteBagFrame_ToggleShown(inventoryFrame) end

    OpenBackpack = showFunc
    OpenAllBags = showFunc

    ToggleBag = toggleFunc
    ToggleAllBags = toggleFunc

    hooksecurefunc('CloseBackpack', hideFunc)
    hooksecurefunc('CloseAllBags', hideFunc)

    BagSlotButton_UpdateChecked = function () end

    BankItemAutoSortButton:SetScript("OnEnter", function (self)
            GameTooltip:SetOwner(self)
            if self:GetParent().selectedTab == 1 then
                GameTooltip:SetText(BAG_CLEANUP_BANK)
            else
                GameTooltip:SetText(BAG_CLEANUP_REAGENT_BANK)
            end
            GameTooltip:Show()
        end)

    BankItemAutoSortButton:SetScript("OnClick", function (self)
            local parent = self:GetParent()
            if (parent.selectedTab == 1) then
                DoOrStaticPopup(BAG_CLEANUP_BANK, SortBankBags)
            elseif (parent.selectedTab == 2) then
                DoOrStaticPopup(BAG_CLEANUP_REAGENT_BANK, SortReagentBankBags)
            end
        end)

    BagItemAutoSortButton:SetScript("OnClick", function (self)
            DoOrStaticPopup(BAG_CLEANUP_BAGS, SortBags)
        end)
end

LiteBagFrame_ReplaceBlizzard(LiteBagInventory, LiteBagBank)
