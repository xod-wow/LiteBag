--[[----------------------------------------------------------------------------

  LiteBag/BankFrame.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

LiteBagBankMixin = {}

function LiteBagBankMixin:OnShowReagentBank()
    -- Use the title text from the Bank Frame itself
    BANK_PANELS[2].SetTitle()
    self:SetTitle(addonName .. ' : ' .. BankFrameTitleText:GetText())

    -- Reagent bank doesn't manage its own search box. It's not really clear
    -- if it would be better to just have the frame handle the search box
    -- for both.

    BankItemAutoSortButton.anchorBag = self
    BankItemAutoSortButton:SetParent(self)
    BankItemAutoSortButton:ClearAllPoints()
    BankItemAutoSortButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -7, -33)
    BankItemAutoSortButton:Show()
    BankItemSearchBox:SetParent(self)
    BankItemSearchBox:ClearAllPoints()
    BankItemSearchBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -38, -37)
    BankItemSearchBox:SetWidth(256)
    BankItemSearchBox:Show()
end

function LiteBagBankMixin:ShowPanel(n)
    LiteBagFrameMixin.ShowPanel(self, n)
    if n == 2 then
        self:OnShowReagentBank()
    end
    -- The itembuttons use BankFrame.selectedTab to know where
    -- to put something that's clicked.
    BankFrame.selectedTab = n
    -- The AutoSortButton uses activeTabIndex to know which tooltip to
    -- show (and what to sort, but we override that).
    BankFrame.activeTabIndex = n
end


function LiteBagBankMixin:OnLoad()
    LiteBagFrameMixin.OnLoad(self)
    -- local placer = self:GetParent()
    -- self.CloseButton:SetScript('OnClick', function () HideUIPanel(placer) end)

    -- Attach in the other Blizzard bank panels. Note that we are also
    -- responsible for handling their events!

    for i = 2, #BANK_PANELS do
        local data = BANK_PANELS[i]
        panel = _G[data.name]
        panel:ClearAllPoints()
        panel:SetSize(data.size.x, data.size.y)
        self:AddPanel(panel, _G['BankFrameTab'..i]:GetText())
    end

    -- Bank frame specific events
    self:RegisterEvent('BANKFRAME_OPENED')
    self:RegisterEvent('BANKFRAME_CLOSED')
end

function LiteBagBankMixin:OnEvent(event, ...)
    LB.EventDebug(self, event, ...)
    if event == 'BANKFRAME_OPENED' then
        self:Show()
        -- ShowUIPanel(self:GetParent())
    elseif event == 'BANKFRAME_CLOSED' then
        HideUIPanel(self:GetParent())
    elseif event == 'INVENTORY_SEARCH_UPDATE' then
        if self:GetCurrentPanel() == ReagentBankFrame then
            ContainerFrameMixin.UpdateSearchResults(ReagentBankFrame)
        end
    elseif event == 'ITEM_LOCK_CHANGED' then
        local bag, slot = ...
        if self:GetCurrentPanel() == ReagentBankFrame and bag == REAGENTBANK_CONTAINER then
            local button = ReagentBankFrame['Item'..slot]
            if button then
                BankFrameItemButton_UpdateLocked(button)
            end
        end
    elseif event == 'PLAYERREAGENTBANKSLOTS_CHANGED' then
        if self:GetCurrentPanel() == ReagentBankFrame then
            local slot = ...
            local button = ReagentBankFrame['Item'..slot]
            if button then
                BankFrameItemButton_Update(button)
            end
        end
    end
end

-- Note that the reagent bank frame refreshes all its own slots in its
-- OnShow handler so we don't have to do that for it.

function LiteBagBankMixin:OnShow()
    LiteBagFrameMixin.OnShow(self)

    -- local placer = self:GetParent()
    -- self:ClearAllPoints()
    -- self:SetPoint("TOPLEFT", placer, "TOPLEFT")

    self:RegisterEvent('ITEM_LOCK_CHANGED')
    self:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
    self:RegisterEvent('PLAYERBANKBAGSLOTS_CHANGED')
    self:RegisterEvent('INVENTORY_SEARCH_UPDATE')

    -- For the reagent bank
    self:RegisterEvent('INVENTORY_SEARCH_UPDATE')
    self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')

    -- OpenAllBags(self)
end

function LiteBagBankMixin:OnHide()
    LiteBagFrameMixin.OnHide(self)

    self:UnregisterEvent('ITEM_LOCK_CHANGED')
    self:UnregisterEvent('INVENTORY_SEARCH_UPDATE')
    self:UnregisterEvent('PLAYERBANKSLOTS_CHANGED')
    self:UnregisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    self:UnregisterEvent('PLAYERBANKBAGSLOTS_CHANGED')
    self:UnregisterEvent('INVENTORY_SEARCH_UPDATE')

    CloseAllBags(self)

    -- Call this so the server knows we closed and it needs to send us a
    -- new BANKFRAME_OPENED event if we interact with the NPC again.
    CloseBankFrame()
end

function LiteBagBankMixin:OnSizeChanged(w, h)
    LB.Debug(format("LiteBagBank OnSizeChanged %s %d,%d",self:GetName(), w, h))
    LiteBagFrameMixin.OnSizeChanged(self, w, h)
--[[
    local placer = self:GetParent()
    local s = self:GetScale()
    placer:SetSize(w*s, h*s)
    if placer:IsShown() then
        UpdateUIPanelPositions(placer)
    end
]]
end
