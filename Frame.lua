--[[----------------------------------------------------------------------------

  LiteBag/Frame.lua

  Copyright 2013 Mike Battersby

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
    if LB.GetTypeOption(self.FrameType, 'nosnap') then
        return
    end
    if GetSqDistanceFromBackpackDefault(self) < 64^2 then
        self:SetSnapPosition()
    end
end

function LiteBagFrameMixin:ResizeToPanel()
    local panel = self:GetCurrentPanel()
    LB.Debug(format("Frame ResizeToPanel %s %s", self:GetName(), panel:GetName()))
    local w, h = panel:GetSize()
    self:SetSize(w, h)
    return w, h
end

function LiteBagFrameMixin:OnShow()
    LB.Debug("Frame OnShow " .. self:GetName())
    local n = PanelTemplates_GetSelectedTab(self)
    self.needsUpdate = true
    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
end

function LiteBagFrameMixin:OnHide()
    LB.Debug("Frame OnHide " .. self:GetName())

    -- Current panel OnHide was called before this due to parenting so won't
    -- get called again. When it was called it returned IsShown() as true, and
    -- the main menu bar bag buttons used that to decide wheter to highlight,
    -- We manually retrigger them. An alternative would be to be responsible
    -- for calling the OnHide for panel and not having them register their own.
    local panel = self:GetCurrentPanel()
    panel:Hide()
    if panel.GetBagID then
        EventRegistry:TriggerEvent("ContainerFrame.CloseBag", panel)
    end

    PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
end

function LiteBagFrameMixin:AnyPanelMatchesBagID(id)
    for _,panel in ipairs(self.panels) do
        if panel.MatchesBagID and panel:MatchesBagID(id) then
            return true
        end
    end
end

function LiteBagFrameMixin:OpenToBag(id)
    for i,panel in ipairs(self.panels) do
        if panel.MatchesBagID and panel:MatchesBagID(id) then
            self:ShowPanel(i)
            self:Show()
            return true
        end
    end
end

function LiteBagFrameMixin:GetCurrentPanel()
    local n = PanelTemplates_GetSelectedTab(self)
    return self.panels[n]
end

function LiteBagFrameMixin:SetUpPanels()
    local n = #self.panels

    for i, panel in ipairs(self.panels) do
        self.Tabs[i]:SetText(panel.Title)
        if n >= 2 then
            PanelTemplates_ShowTab(self, i)
        end
    end

    local i = PanelTemplates_GetSelectedTab(self)
    PanelTemplates_SetNumTabs(self, n)
    PanelTemplates_SetTab(self, i)
end

function LiteBagFrameMixin:AddPanel(panel)
    panel:SetParent(self)
    panel:ClearAllPoints()
    panel:SetPoint('TOPLEFT', self, 'TOPLEFT')
    panel:Hide()

    tinsert(self.panels, panel)
    self:SetUpPanels()
end

function LiteBagFrameMixin:ShowPanel(n)
    LB.Debug(format("Frame ShowPanel %s %d", self:GetName(), n))
    PanelTemplates_SetTab(self, n)
    self.needsUpdate = true
end

function LiteBagFrameMixin:OnLoad()
    self:SetPortraitTextureSizeAndOffset(36, -4, 1);

    self.Tabs[1]:SetText(self.panels[1].Title)
    PanelTemplates_SetNumTabs(self, 1)
    PanelTemplates_SetTab(self, 1)
    self:SetUpPanels()
    self.needsUpdate = true
end

function LiteBagFrameMixin:OnUpdate()
    if self.needsUpdate then
        local currentPanel = self:GetCurrentPanel()
        for i, panel in ipairs(self.panels) do
            panel:SetShown(panel==currentPanel)
        end

        self:SetTitle(format('%s : %s', addonName, currentPanel.Title))

        self:SetScale(LB.GetTypeOption(self.FrameType, 'scale') or 1.0)
        self:ResizeToPanel()
        self.needsUpdate = nil
    end
end
