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

    -- The itembuttons use BankFrame.selectedTab to know where
    -- to put something that's clicked.
    BankFrame.selectedTab = n

    -- The AutoSortButton uses activeTabIndex to know which tooltip to
    -- show (and what to sort, but we override that).
    BankFrame.activeTabIndex = n
end

function LiteBagBankMixin:OnLoad()
    LiteBagFrameMixin.OnLoad(self)

    self.CloseButton:SetScript('OnClick',
        function ()
            local pos = self:GetOption('position')
            if pos then
                self:Hide()
            else
                HideUIPanel(LiteBagBankPlacer)
            end
        end)

    -- Attach in the reagent bank wrapper.
    self:AddPanel(LiteBagReagentBank)

    -- Bank frame specific events
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')
end

function LiteBagBankMixin:OnEvent(event, ...)
    LB.EventDebug(self, event, ...)
    local pos = self:GetOption('position')
    if event == 'PLAYER_INTERACTION_MANAGER_FRAME_SHOW' then
        local type = ...
        if type == Enum.PlayerInteractionType.Banker then
            if pos then
                self:Show()
            else
                ShowUIPanel(LiteBagBankPlacer)
            end
        end
    elseif event == 'PLAYER_INTERACTION_MANAGER_FRAME_HIDE' then
        local type = ...
        if type == Enum.PlayerInteractionType.Banker then
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
    LiteBagFrameMixin.OnShow(self)

    local n = PanelTemplates_GetSelectedTab(self)
    self:ShowPanel(n)

    OpenAllBags(self)
end

function LiteBagBankMixin:OnHide()
    LiteBagFrameMixin.OnHide(self)

    CloseAllBags(self)

    -- Call this so the server knows we closed and it needs to send us a
    -- new open event if we interact with the NPC again.
    CloseBankFrame()
end

function LiteBagBankMixin:ResizeToPanel()
    local w, h = LiteBagFrameMixin.ResizeToPanel(self)
    local s = self:GetScale()
    LiteBagBankPlacer:SetSize(w*s, h*s)
    if LiteBagBankPlacer:IsShown() then
        UpdateUIPanelPositions(LiteBagBankPlacer)
    end
end
