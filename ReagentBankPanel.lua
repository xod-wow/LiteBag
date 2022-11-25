--[[----------------------------------------------------------------------------

  LiteBag/ReagentBankFrame.lua

  Copyright 2022 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

LiteBagReagentBankMixin = {}

function LiteBagReagentBankMixin:OnLoad()
    local data = BANK_PANELS[2]

    ReagentBankFrame:SetParent(self)
    ReagentBankFrame:ClearAllPoints()
    ReagentBankFrame:SetPoint("TOPLEFT")

    ReagentBankFrame:SetWidth(data.size.x)
    ReagentBankFrame:SetHeight(data.size.y)
    ReagentBankFrame:Hide()

    self:SetSize(ReagentBankFrame:GetSize())
end

function LiteBagReagentBankMixin:OnShow()
    BankItemAutoSortButton.anchorBag = self
    BankItemAutoSortButton:SetParent(self)
    BankItemAutoSortButton:ClearAllPoints()
    BankItemAutoSortButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -7, -27)
    BankItemAutoSortButton:Show()

    BankItemSearchBox:SetParent(self)
    BankItemSearchBox:ClearAllPoints()
    BankItemSearchBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -38, -31)
    BankItemSearchBox:SetWidth(256)
    BankItemSearchBox:Show()

    ReagentBankFrame:Show()

    self:RegisterEvent('INVENTORY_SEARCH_UPDATE')
    self:RegisterEvent('ITEM_LOCK_CHANGED')
    self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
end

function LiteBagReagentBankMixin:OnHide()
    ReagentBankFrame:Hide()
    self:UnregisterAllEvents()
end

function LiteBagReagentBankMixin:OnEvent(event, ...)
    LB.EventDebug(self, event, ...)
    if event == 'INVENTORY_SEARCH_UPDATE' then
        ContainerFrameMixin.UpdateSearchResults(ReagentBankFrame)
    elseif event == 'ITEM_LOCK_CHANGED' then
        local bag, slot = ...
        if bag == Enum.BagIndex.ReagentBank then
            local button = ReagentBankFrame['Item'..slot]
            if button then
                BankFrameItemButton_UpdateLocked(button)
            end
        end
    elseif event == 'PLAYERREAGENTBANKSLOTS_CHANGED' then
        local slot = ...
        local button = ReagentBankFrame['Item'..slot]
        if button then
            BankFrameItemButton_Update(button)
        end
    end
end
