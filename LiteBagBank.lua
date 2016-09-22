--[[----------------------------------------------------------------------------

  LiteBag/BankFrame.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

function LiteBagBank_TabOnClick(self)
    local parent = self:GetParent()
    PanelTemplates_SetTab(parent, self:GetID())
    LiteBagBank_ShowPanel(parent, self:GetID())
end

local BANK_PANEL_NAMES = {
    [1] = function () return UnitName("npc") end,
    [2] = function () return REAGENT_BANK end,
}

function LiteBagBank_ShowPanel(self, n)
    local panel, data
    for i = 1, #BANK_PANELS do
        if i == 1 then
            panel = self.items
        else
            data = BANK_PANELS[i]
            panel = _G[data.name]
            if i == n then
                self:SetSize(data.size.x, data.size.y)
                panel:SetParent(self)
                panel:SetPoint("TOPLEFT", self, "TOPLEFT")
            end
        end
        if i == n then
            self.TitleText:SetText(BANK_PANEL_NAMES[i]())
            panel:Show()
        else
            panel:Hide()
        end
    end

    self.currentPanel = panel
end

function LiteBagBank_OnLoad(self)
    self.bagIDs = { -1, 5, 6, 7, 8, 9, 10, 11 }
    self.default_columns = 16
    self.isBank = true

    LiteBagFrame_OnLoad(self)

    -- UIPanelLayout stuff so the Blizzard UIParent code will position us
    -- automatically. See
    --   http://www.wowwiki.com/Creating_standard_left-sliding_frames
    -- but note that UIPanelLayout-enabled isn't a thing at all.

    self:SetAttribute("UIPanelLayout-defined", true)
    self:SetAttribute("UIPanelLayout-area", "left")
    self:SetAttribute("UIPanelLayout-pushable", 6)

    -- Different inset texture for the bank

    self.Inset.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", true, true)

    -- Set up the tabs

    self.Tab1:Show()
    self.Tab2:Show()
    PanelTemplates_SetNumTabs(self, 2)
    PanelTemplates_SetTab(self, 1)
    self.selectedTab = 1

    -- Start with normal bank items panel
    self.currentPanel = self.items

    -- Select the right search box 
    self.searchBox = BankItemSearchBox
    self.sortButton = BankItemAutoSortButton

    -- Bank frame specific events
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
end

function LiteBagBank_OnEvent(self, event, ...)
    if event == "BANKFRAME_OPENED" then
        LiteBagBank_ShowPanel(self, 1)
        ShowUIPanel(self)
    elseif event == "BANKFRAME_CLOSED" then
        HideUIPanel(self)
    elseif event == "INVENTORY_SEARCH_UPDATE" then
        ContainerFrame_UpdateSearchResults(ReagentbankFrame)
        LiteBagFrame_OnEvent(self, event, ...)
    elseif event == "ITEM_LOCK_CHANGED" then
        local bag, slot = ...
        if bag == REAGENTBANK_CONTAINER then
            local button = ReagentBankFrame["Item"..(slot)]
            if button then
                BankFrameItemButton_UpdateLocked(button)
            end
        else
            LiteBagFrame_OnEvent(self, event, ...)
        end
    elseif event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
        local slot = ...
        BankFrameItemButton_Update(ReagentBankFrame["Item"..(slot)])
    else
        LiteBagFrame_OnEvent(self, event, ...)
    end
end

function LiteBagBank_OnShow(self)
    LiteBagFrame_OnShow(self)
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
end

function LiteBagBank_OnHide(self)
    self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:UnregisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
end
