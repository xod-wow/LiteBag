--[[----------------------------------------------------------------------------

  LiteBag/Frame.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local function GetSqDistanceFromBackpackDefault(self)
    local defaultX = UIParent:GetRight() - CONTAINER_OFFSET_X
    local defaultY = UIParent:GetBottom() + CONTAINER_OFFSET_Y
    local selfX = self:GetRight() * self:GetScale()
    local selfY = self:GetBottom() * self:GetScale()
    return (defaultX-selfX)^2 + (defaultY-selfY)^2
end

LiteBagFrameMixin = { }

-- CONTAINER_OFFSET_* are globals that are updated by the Blizzard
-- code depending on which (default) action bars are shown.

function LiteBagFrameMixin:SetSnapPosition()
    LB.Debug("Frame SetSnapPosition " .. self:GetName())
    self:ClearAllPoints()
    self:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y)
    -- false is don't save position, so we will reset it on reload
    self:SetUserPlaced(false)
end

function LiteBagFrameMixin:CheckSnapPosition()
    if LB.Options:GetGlobalOption('NoSnapToPosition') then
        return
    end

    if GetSqDistanceFromBackpackDefault(self) < 64^2 then
        self:SetSnapPosition()
    end
end

function LiteBagFrameMixin:OnSizeChanged(w, h)
    LB.Debug(format("Frame OnSizeChanged %s %d,%d",self:GetName(), w, h))
    if self.sizing then
        local currentPanel = self:GetCurrentPanel()
        currentPanel:ResizeToWidth(w)
        local clampedWidth = max(w, currentPanel:GetWidth())
        self:SetSize(clampedWidth, currentPanel:GetHeight())
    end
end

function LiteBagFrameMixin:ResizeToPanel(panel)
    local currentPanel = self:GetCurrentPanel()
    panel = panel or currentPanel
    LB.Debug(format("Frame ResizeToPanel %s %s",self:GetName(), panel:GetName()))
    if not self.sizing and panel == currentPanel then
        self:SetSize(panel:GetSize())
    end
end

function LiteBagFrameMixin:OnShow()
    LB.Debug("Frame OnShow " .. self:GetName())
    self:ShowPanel(self.selectedTab)
    local currentPanel = self:GetCurrentPanel()
    self:SetSize(currentPanel:GetSize())
    self:SetScale(LB.Options:GetFrameOption(self, 'scale') or 1.0)

    EventRegistry:RegisterCallback('LiteBag.FrameSize', self.ResizeToPanel, self)

    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
end

function LiteBagFrameMixin:OnHide()
    LB.Debug("Frame OnHide " .. self:GetName())
    EventRegistry:UnregisterCallback('LiteBag.FrameSize', self)
    PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
end

function LiteBagFrameMixin:SetTab(id)
    LB.Debug("Frame SetTab " .. id)
    PanelTemplates_SetTab(self, id)
    self:ShowPanel(id)
end

function LiteBagFrameMixin:GetCurrentPanel()
    return self.panels[self.selectedTab]
end

function LiteBagFrameMixin:AddPanel(panel, tabTitle)
    panel:SetParent(self)
    panel:SetPoint('TOPLEFT', self, 'TOPLEFT')

    tinsert(self.panels, panel)

    self.Tabs[#self.panels]:SetText(tabTitle)

    if #self.panels < 2 then
        self.selectedTab = 1
        return
    end

    for i = 1, #self.panels do
        self.Tabs[i]:Show()
    end
    self.numTabs = #self.panels
    for i = 2, self.numTabs do
        local lastTab = self.Tabs[i-1]
        local thisTab = self.Tabs[i]
        thisTab:SetPoint("TOPLEFT", lastTab, "TOPRIGHT", 3, 0);
    end
    -- PanelTemplates_SetNumTabs(self, #self.panels)
end

function LiteBagFrameMixin:ShowPanel(n)
    LB.Debug(format("Frame ShowPanel %s %d", self:GetName(), n))
    for i,panel in ipairs(self.panels) do
        panel:SetShown(i == n)
    end

    if self.panels[n].GenerateFrame then
        self.panels[n]:GenerateFrame()
    end

    if self.OnShowPanel then
        self:OnShowPanel(n)
    end

    self:SetSize(self.panels[n]:GetSize())

    if #self.panels > 1 then
        PanelTemplates_SetTab(self, n)
    end
    self.selectedTab = n
end

function LiteBagFrameMixin:OnLoad()
    self.selectedTab = 1
end

