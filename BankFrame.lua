--[[----------------------------------------------------------------------------

  LiteBag/BankFrame.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

LiteBagBankMixin = {}

function LiteBagBankMixin:ShowPanel(n)
    LiteBagFrameMixin.ShowPanel(self, n)

    -- The itembuttons use these to know where to put something that's clicked.
    -- C_Container.UseContainerItem(
    --      self:GetBagID(),
    --      self:GetID(),
    --      nil,
    --      BankFrame:GetActiveBankType(),
    --      BankFrame:IsShown() and BankFrame.selectedTab == 2
    -- )
    BankFrame.selectedTab = n
    BankFrame.activeTabIndex = n
end

function LiteBagBankMixin:Close()
    if LiteBagBankPlacer:IsShown() then
        HideUIPanel(LiteBagBankPlacer)
    else
        self:Hide()
    end
end

function LiteBagBankMixin:OnLoad()
    LiteBagFrameMixin.OnLoad(self)

    self.CloseButton:SetScript('OnClick', function () self:Close() end)

    -- Attach in the reagent bank wrapper.
    self:AddPanel(LiteBagReagentBank)

    -- Attach in the account bank wrapper.
    self:AddPanel(LiteBagAccountBank)

    -- Bank frame specific events
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')
end

local BankInteractionTypes = {
    [Enum.PlayerInteractionType.AccountBanker] = true,
    [Enum.PlayerInteractionType.Banker] = true,
    [Enum.PlayerInteractionType.CharacterBanker] = true,
}

function LiteBagBankMixin:OnEvent(event, ...)
    LB.EventDebug(self, event, ...)
    local pos = self:GetOption('position')
    if event == 'PLAYER_INTERACTION_MANAGER_FRAME_SHOW' then
        local type = ...
        if BankInteractionTypes[type] then
            if pos then
                self:Show()
            else
                ShowUIPanel(LiteBagBankPlacer)
            end
        end
    elseif event == 'PLAYER_INTERACTION_MANAGER_FRAME_HIDE' then
        local type = ...
        if BankInteractionTypes[type] then
            if pos then
                self:Hide()
            else
                HideUIPanel(LiteBagBankPlacer)
            end
        end
    end
end

function LiteBagBankMixin:RestorePosition()
    -- This handles switching back and forth between UIPanel placement and
    -- user placement. In most cases the Show/HideUIPanel will not do anything
    -- since they will reflect the current state already.

    LB.FrameDebug(self, "RestorePosition (Bank)")
    local pos = self:GetOption('position')
    if pos then
        self:ClearAllPoints()
        self:SetPoint(pos.anchor, UIParent, pos.anchor, pos.x, pos.y)
        if not tContains(UISpecialFrames, self:GetName()) then
            table.insert(UISpecialFrames, self:GetName())
        end
        HideUIPanel(LiteBagBankPlacer)
    else
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", LiteBagBankPlacer, "TOPLEFT")
        tDeleteItem(UISpecialFrames, self:GetName())
        ShowUIPanel(LiteBagBankPlacer)
    end
end

function LiteBagBankMixin:OnShow()

    -- Tab/panel visibility based on what is allowed. Have to do this in two
    -- passes because if only 1 panel is visible we don't show the tabs at all

    local enabledPanels = {}
    for i in pairs(self.panels) do
        if C_Bank.CanViewBank(BANK_PANELS[i].bankType) then
            table.insert(enabledPanels, i)
        end
    end

    if #enabledPanels == 0 then
        self:Close()
        return
    end

    local multiPanelView  = ( #enabledPanels > 1 )
    for i, panel in ipairs(self.panels) do
        local enabled = multiPanelView and tContains(enabledPanels, i)
        PanelTemplates_SetTabShown(self, i, enabled)
    end

    LiteBagFrameMixin.OnShow(self)

    local n = PanelTemplates_GetSelectedTab(self)
    if not tContains(enabledPanels, n) then
        n = enabledPanels[1]
    end

    self:ShowPanel(n)

    OpenAllBags(self)
end

function LiteBagBankMixin:OnHide()
    LiteBagFrameMixin.OnHide(self)
    CloseAllBags(self)

    -- Call this so the server knows we closed and it needs to send us a
    -- new open event if we interact with the NPC again.
    C_Bank.CloseBankFrame()
end

function LiteBagBankMixin:ResizeToPanel()
    local w, h = LiteBagFrameMixin.ResizeToPanel(self)
    local s = self:GetScale()
    LiteBagBankPlacer:SetSize(w*s, h*s)
    if LiteBagBankPlacer:IsShown() then
        UpdateUIPanelPositions(LiteBagBankPlacer)
    end
end
