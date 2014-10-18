--[[----------------------------------------------------------------------------

  LiteBag/ReplaceBlizzard.lua

  Copyright 2013-2014 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local inventoryFrame, bankFrame

function LiteBagFrame_ReplaceBlizzard(inventory, bank)

    BankFrame:UnregisterAllEvents()

    inventoryFrame = inventory
    bankFrame = bank

    PanelTemplates_SetNumTabs(bank, 2)
    bank.selectedTab = 1

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
            PlaySound("UI_BagSorting_01")
            if (parent.selectedTab == 1) then
                    SortBankBags();
            elseif (parent.selectedTab == 2) then
                    SortReagentBankBags()
            end
        end)
end

LiteBagFrame_ReplaceBlizzard(LiteBagInventory, LiteBagBank)
