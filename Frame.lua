--[[----------------------------------------------------------------------------

  LiteBag/Frame.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local function GetSqDistanceFromDefault(self)
    local anchor, defaultX, defaultY, selfX, selfY = self:GetAutoPosition()
    return (defaultX-selfX)^2 + (defaultY-selfY)^2
end

LiteBagFrameMixin = { }

-- CONTAINER_OFFSET_* are globals that are updated by the Blizzard
-- code depending on which (default) action bars are shown.

function LiteBagFrameMixin:GetAutoPosition()
    if self.FrameType == "BACKPACK" then
        local selfX = self:GetRight() * self:GetScale() - UIParent:GetRight()
        local selfY = self:GetBottom() * self:GetScale() - UIParent:GetBottom()
        return "BOTTOMRIGHT", CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y, selfX, selfY
    elseif self.FrameType == "BANK" then
        local x = UIParent:GetAttribute("LEFT_OFFSET")
        local y = UIParent:GetAttribute("TOP_OFFSET")
        local selfX = self:GetLeft() * self:GetScale() - UIParent:GetLeft()
        local selfY = self:GetTop() * self:GetScale() - UIParent:GetTop()
        return "TOPLEFT", x, y, selfX, selfY
    end
end

function LiteBagFrameMixin:ManagePosition()
    LB.FrameDebug(self, "ManagePosition")
    if not self:IsUserPlaced() then
        local anchor, x, y = self:GetAutoPosition()
        self:ClearAllPoints()
        self:SetPoint(anchor, UIParent, anchor, x, y)
    end
end

function LiteBagFrameMixin:SnapToAutoPosition()
    if not LB.GetTypeOption(self.FrameType, 'snap') then
        return
    end
    if GetSqDistanceFromDefault(self) < 64^2 then
        self:SetUserPlaced(false)
        self:ManagePosition()
    end
end

function LiteBagFrameMixin:ShowSnapAnchor()
    if LB.GetTypeOption(self.FrameType, 'snap') then
        local point, x, y = self:GetAutoPosition()
        LiteBagSnapAnchor:ClearAllPoints()
        LiteBagSnapAnchor:SetPoint("CENTER", UIParent, point, x, y)
        LiteBagSnapAnchor:Show()
    end
end

function LiteBagFrameMixin:HideSnapAnchor()
    LiteBagSnapAnchor:Hide()
end

function LiteBagFrameMixin:ResizeToPanel()
    local panel = self:GetCurrentPanel()
    LB.FrameDebug(self, "ResizeToPanel %s", panel:GetName())
    local w, h = panel:GetSize()
    self:SetSize(w, h)
    return w, h
end

function LiteBagFrameMixin:OnShow()
    LB.FrameDebug(self, "OnShow")
    self.needsUpdate = true
    self:ManagePosition()
    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
end

function LiteBagFrameMixin:OnHide()
    LB.FrameDebug(self, "OnHide")

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
    LB.FrameDebug(self, "ShowPanel %d", n)
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

function LiteBagFrameMixin:OnStartSizing()
    self.isSizing = true
    self:StartSizing("BOTTOMRIGHT")
end

function LiteBagFrameMixin:OnStopSizing()
    self:StopMovingOrSizing()
    self.isSizing = nil
    self.needsUpdate = true
    -- Should we tell the current panel to fire OnOptionsModified for columns
    -- now, in case anything else is hanging off it?
end

function LiteBagFrameMixin:OnSizeChanged(w, h)
    if self.isSizing then
        LB.FrameDebug(self, "OnSizeChanged %.1f %1.f", w, h)
        local currentPanel = self:GetCurrentPanel()
        currentPanel:ResizeToWidth(w)
        local clampedWidth = max(w, currentPanel:GetWidth())
        self:SetSize(clampedWidth, currentPanel:GetHeight())
    end
end

function LiteBagFrameMixin:OnUpdate()
    if self.needsUpdate and not self.isSizing then
        LB.FrameDebug(self, "OnUpdate")
        local currentPanel = self:GetCurrentPanel()
        for i, panel in ipairs(self.panels) do
            panel:SetShown(panel==currentPanel)
        end

        self.ResizeBottomRight:SetShown(currentPanel.resizingAllowed)

        self:SetTitle(format('%s : %s', addonName, currentPanel.Title))

        self:SetScale(LB.GetTypeOption(self.FrameType, 'scale') or 1.0)
        self:ResizeToPanel()
        self.needsUpdate = nil
    end
end


function LiteBagFrameMixin:IsLocked()
    return LB.GetTypeOption(self.panels[1].FrameType, 'locked')
end

function LiteBagFrameMixin:ToggleLocked()
    local v = self:IsLocked()
    LB.SetTypeOption(self.panels[1].FrameType, 'locked', not v)
end
