--[[----------------------------------------------------------------------------

  LiteBag/BankFrame.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local BANK_BAG_IDS = { -1, 5, 6, 7, 8, 9, 10, 11 }

function LiteBagBank_OnLoad(self)
    LiteBagFrame_OnLoad(self)

    local placer = self:GetParent()
    self.CloseButton:SetScript('OnClick', function () HideUIPanel(placer) end)

    self:RegisterEvent('ADDON_LOADED')
end

function LiteBagBank_Initialize(self)
    -- Basic slots panel for the bank slots

    local panel = CreateFrame('Frame', 'LiteBagBankPanel', self, 'LiteBagPanelTemplate')
    LiteBagPanel_Initialize(panel, BANK_BAG_IDS)
    panel.defaultColumns = 16
    panel.canResize = true
    LiteBagFrame_AddPanel(self, panel, BANK)

    -- Attach in the other Blizzard bank panels. Note that we are also
    -- responsible for handling their events!

    for i = 2, #BANK_PANELS do
        local data = BANK_PANELS[i]
        panel = _G[data.name]
        panel:ClearAllPoints()
        panel:SetSize(data.size.x, data.size.y)
        LiteBagFrame_AddPanel(self, panel, _G['BankFrameTab'..i]:GetText())
    end

    self.OnShowPanel = function (self, n)
            -- Use the title text from the Bank Frame itself
            BANK_PANELS[n].SetTitle()
            self.TitleText:SetText(BankFrameTitleText:GetText())
            -- The itembuttons use BankFrame.selectedTab to know where
            -- to put something that's clicked.
            BankFrame.selectedTab = n
            -- The AutoSortButton uses activeTabIndex to know which tooltip to
            -- show (and what to sort, but we override that).
            BankFrame.activeTabIndex = n
        end

    -- Different inset texture for the bank

    self.Inset.Bg:SetTexture("Interface\\BankFrame\\Bank-Background", true, true)
    self.Inset.Bg:SetVertexColor(0.4, 0.4, 0.4, 1)

    -- Select the right search box 
    self.searchBox = BankItemSearchBox
    self.sortButton = BankItemAutoSortButton

    -- Bank frame specific events
    self:RegisterEvent('BANKFRAME_OPENED')
    self:RegisterEvent('BANKFRAME_CLOSED')

end

function LiteBagBank_OnEvent(self, event, arg1, arg2, ...)

    LB.Debug(format("Bank OnEvent %s %s %s", event, tostring(arg1), tostring(arg2)))
    if event == 'ADDON_LOADED' then
        if arg1 == 'LiteBag' then
            LiteBagBank_Initialize(self)
        end
    elseif event == 'BANKFRAME_OPENED' then
        LiteBagFrame_ShowPanel(self, 1)
        ShowUIPanel(self:GetParent())
    elseif event == 'BANKFRAME_CLOSED' then
        HideUIPanel(self:GetParent())
    elseif event == 'INVENTORY_SEARCH_UPDATE' then
        ContainerFrame_UpdateSearchResults(ReagentBankFrame)
    elseif event == 'ITEM_LOCK_CHANGED' then
        -- bag, slot = arg1, arg2
        if arg1 == REAGENTBANK_CONTAINER then
            local button = ReagentBankFrame['Item'..(arg2)]
            if button then
                BankFrameItemButton_UpdateLocked(button)
            end
        end
    elseif event == 'PLAYERREAGENTBANKSLOTS_CHANGED' then
        -- slot = arg1
        local button = ReagentBankFrame['Item'..(arg1)]
        if button then
            BankFrameItemButton_Update(button)
        end
    elseif event == 'PLAYER_MONEY' then
        if self.selectedTab == 1 then
            LiteBagPanel_UpdateBagSlotCounts(LiteBagBankPanel)
            LiteBagPanel_UpdateSizeAndLayout(LiteBagBankPanel)
            LiteBagPanel_UpdateAllBags(LiteBagBankPanel)
        end
    end
end

-- Note that the reagent bank frame refreshes all its own slots in its
-- OnShow handler so we don't have to do that for it.

function LiteBagBank_OnShow(self)
    LiteBagFrame_OnShow(self)

    SetPortraitTexture(self.portrait, 'npc')

    self:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
    self:RegisterEvent('INVENTORY_SEARCH_UPDATE')
    self:RegisterEvent('ITEM_LOCK_CHANGED')
    self:RegisterEvent('PLAYER_MONEY')
    if ReagentBankFrame then
        self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    end
end

function LiteBagBank_OnHide(self)
    -- Call this so the server knows we closed and it needs to send us a
    -- new BANKFRAME_OPENED event if we interact with the NPC again.
    CloseBankFrame()
    self:UnregisterEvent('PLAYERBANKSLOTS_CHANGED')
    self:UnregisterEvent('INVENTORY_SEARCH_UPDATE')
    self:UnregisterEvent('ITEM_LOCK_CHANGED')
    self:UnregisterEvent('PLAYER_MONEY')
    if ReagentBankFrame then
        self:UnregisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    end
end
