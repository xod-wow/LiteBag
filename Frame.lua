--[[----------------------------------------------------------------------------

  LiteBag/Frame.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, addonTable = ...

local function GetSqDistanceFromBackpackDefault(self)
    local defaultX = UIParent:GetRight() - CONTAINER_OFFSET_X
    local defaultY = UIParent:GetBottom() + CONTAINER_OFFSET_Y
    local selfX = self:GetRight()
    local selfY = self:GetBottom()
    return (defaultX-selfX)^2 + (defaultY-selfY)^2
end

-- CONTAINER_OFFSET_* are globals that are updated by the Blizzard
-- code depending on which (default) action bars are shown.

function LiteBagFrame_SetPosition(self)
    LiteBag_Debug("Frame SetPosition " .. self:GetName())
    if self:IsUserPlaced() then return end
    self:ClearAllPoints()
    self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y)
end

function LiteBagFrame_StartMoving(self)
    LiteBag_Debug("Frame StartMoving " .. self:GetName())
    self:StartMoving()
end

function LiteBagFrame_StopMoving(self)
    LiteBag_Debug("Frame StopMoving " .. self:GetName())
    self:StopMovingOrSizing()

    if not self.currentPanel or not self.currentPanel.isBackpack then
        return
    end

    if GetSqDistanceFromBackpackDefault(self) < 64^2 then
        self:SetUserPlaced(false)
        LiteBagFrame_SetPosition(self)
    end
end

function LiteBagFrame_StartSizing(self, point)
    LiteBag_Debug("Frame StartSizing " .. self:GetName())
    if not self.currentPanel or not self.currentPanel.canResize then
        return
    end

    self.sizing = true
    self:StartSizing(point)
end

function LiteBagFrame_StopSizing(self)
    LiteBag_Debug("Frame StopSizing " .. self:GetName())
    self:StopMovingOrSizing()
    self.sizing = nil

    self:SetSize(self.currentPanel:GetSize())
end

function LiteBagFrame_OnSizeChanged(self, w, h)
    LiteBag_Debug(format("Frame OnSizeChanged %s %d,%d",self:GetName(), w, h))
    if not self.sizing then return end

    LiteBagPanel_SetWidth(self.currentPanel, w)
    self:SetHeight(self.currentPanel:GetHeight())
end

function LiteBagFrame_OnHide(self)
    LiteBag_Debug("Frame OnHide " .. self:GetName())
    PlaySound("igBackPackClose")
end

function LiteBagFrame_OnShow(self)
    LiteBag_Debug("Frame OnShow " .. self:GetName())

    self:SetSize(self.currentPanel:GetSize())

    LiteBagFrame_AttachSearchBox(self)

    PlaySound("igBackPackOpen")
end

function LiteBagFrame_AttachSearchBox(self)
    self.searchBox:SetParent(self)
    self.searchBox:ClearAllPoints()
    self.searchBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -38, -35)
    self.searchBox.anchorBag = self
    self.searchBox:Show()

    self.sortButton:SetParent(self)
    self.sortButton:ClearAllPoints()
    self.sortButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -7, -32)
    self.sortButton.anchorBag = self
    self.sortButton:Show()
end

function LiteBagFrame_TabOnClick(tab)
    LiteBag_Debug("Frame TabOnClick " .. tab:GetName())
    local parent = tab:GetParent()
    PanelTemplates_SetTab(parent, tab:GetID())
    LiteBagFrame_ShowPanel(parent, tab:GetID())
end

function LiteBagFrame_AddPanel(self, panel, tabTitle)
    LiteBag_Debug(format("Frame AddPanel %s %s", self:GetName(), panel:GetName()))
    panel:SetParent(self)
    panel:SetPoint("TOPLEFT", self, "TOPLEFT")

    tinsert(self.panels, panel)

    if #self.panels < 2 then
        self.currentPanel = panel
        self.selectedTab = 1
        return
    end

    for i = 1, #self.panels do
        self.Tabs[i]:SetText(tabTitle)
        self.Tabs[i]:Show()
    end
    PanelTemplates_SetNumTabs(self, #self.panels)
end

function LiteBagFrame_ShowPanel(self, n)
    LiteBag_Debug(format("Frame ShowPanel %s %d", self:GetName(), n))
    for i,panel in ipairs(self.panels) do
        panel:SetShown(i == n)
    end

    self.currentPanel = self.panels[n]
    self:SetSize(self.currentPanel:GetSize())
    self.TitleText:SetText(self.currentPanel.title)

    if #self.panels > 1 then
        PanelTemplates_SetTab(self, n)
    end
    self.selectedTab = n

    if self.OnShowPanel then
        self.OnShowPanel(self, n)
    end
end

function LiteBagFrame_OnLoad(self)
    LiteBag_Debug("Frame OnLoad " .. self:GetName())
    self.panels = { }
    self.currentPanel = nil
end

