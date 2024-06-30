--[[----------------------------------------------------------------------------

  LiteBag/WrappedBankPanel.lua

  Copyright 2022 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

LiteBagWrappedBankMixin = {}

function LiteBagWrappedBankMixin:OnLoad()
    local id = self:GetID()
    local data = BANK_PANELS[id]
    self.wrappedPanel = _G[data.name]

    self.wrappedPanel:SetParent(self)
    self.wrappedPanel:ClearAllPoints()
    self.wrappedPanel:SetPoint("TOPLEFT")

    self.wrappedPanel:SetWidth(data.size.x)
    self.wrappedPanel:SetHeight(data.size.y)
    self.wrappedPanel:Hide()

    self:SetSize(self.wrappedPanel:GetSize())
end

function LiteBagWrappedBankMixin:OnShow()
    LB.FrameDebug(self, "OnShow")
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

    self.wrappedPanel:Show()

    self:RegisterEvent('INVENTORY_SEARCH_UPDATE')
    self:RegisterEvent('ITEM_LOCK_CHANGED')
    self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
end

function LiteBagWrappedBankMixin:OnHide()
    LB.FrameDebug(self, "OnHide")
    self.wrappedPanel:Hide()
    self:UnregisterAllEvents()
end

function LiteBagWrappedBankMixin:OnEvent(event, ...)
    LB.EventDebug(self, event, ...)
    if event == 'INVENTORY_SEARCH_UPDATE' then
        ContainerFrameMixin.UpdateSearchResults(self.wrappedPanel)
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
