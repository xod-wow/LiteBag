--[[----------------------------------------------------------------------------

  LiteBag/WrappedBankPanel.lua

  Copyright 2022 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

LiteBagWrappedBankMixin = {}

local hookedItemButtons = {}

function LiteBagWrappedBankMixin:HookItemButtons(methodName, func)
    for itemButton in self.wrappedPanel:EnumerateValidItems() do
        if not hookedItemButtons[itemButton] then
            hooksecurefunc(itemButton, methodName, func)
        end
    end
end

function LiteBagWrappedBankMixin:OnLoad()
    local id = self:GetID()
    local data = BANK_PANELS[id]

    self.bankType = data.bankType

    self.wrappedPanel = _G[data.name]

    self.wrappedPanel:SetParent(self)
    self.wrappedPanel:ClearAllPoints()
    self.wrappedPanel:SetPoint("TOPLEFT")

    self.wrappedPanel:SetWidth(data.size.x)
    self.wrappedPanel:SetHeight(data.size.y)
    self.wrappedPanel:Hide()

    if data.bankType == Enum.BankType.Character then
        -- Reagent bank
        hooksecurefunc("BankFrameItemButton_Update",
            function (itemButton)
                if itemButton.isBag then return end
                LB.CallHooks('LiteBagItemButton_Update', itemButton)
            end)
    elseif data.bankType == Enum.BankType.Account then
        hooksecurefunc(AccountBankPanel, 'GenerateItemSlotsForSelectedTab',
            function ()
                self:HookItemButtons('Refresh',
                    function (itemButton)
                        LB.CallHooks('LiteBagItemButton_Update', itemButton)
                    end)
            end)
        -- This is to fix a blizzard bug where it's both (a) not updated the
        -- first time AND spins on calling Clean() every frame.
        AccountBankPanel:MarkDirty()
    end
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

    self:GetParent():SetPortraitToUnit('npc')

    self.wrappedPanel:Show()

    if self.bankType == Enum.BankType.Character then
        self:RegisterEvent('INVENTORY_SEARCH_UPDATE')
        self:RegisterEvent('ITEM_LOCK_CHANGED')
        self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    end

    LB.RegisterPluginEvents(self)
end

function LiteBagWrappedBankMixin:OnHide()
    LB.FrameDebug(self, "OnHide")
    self.wrappedPanel:Hide()
    self:UnregisterAllEvents()
end

function LiteBagWrappedBankMixin:OnEvent(event, ...)
    LB.EventDebug(self, event, ...)
    if event == 'INVENTORY_SEARCH_UPDATE' then
        self.wrappedPanel:UpdateSearchResults()
    elseif event == 'ITEM_LOCK_CHANGED' then
        local bag, slot = ...
        if bag == Enum.BagIndex.Reagentbank then
            local button = ReagentBankFrame['Item'..slot]
            if button then
                BankFrameItemButton_UpdateLocked(button)
            end
        end
    elseif event == 'PLAYERREAGENTBANKSLOTS_CHANGED' then
        -- Could the reagent bank handle its own events please.
        local slot = ...
        local button = ReagentBankFrame['Item'..slot]
        if button then
            BankFrameItemButton_Update(button)
        end
    elseif LB.IsPluginEvent(event) then
        self:CallHooksForWrappedButtons()
    end
end
