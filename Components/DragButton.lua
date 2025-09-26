--[[----------------------------------------------------------------------------

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

LiteBagDragButtonMixin = {}

function LiteBagDragButtonMixin:OnLoad()
    local parent = self:GetParent()
    self:SetPoint("TOP", parent.TitleContainer, "TOP")
    self:SetPoint("BOTTOM", parent.TitleContainer, "BOTTOM")
    self:SetPoint("LEFT", parent.PortraitButton, "RIGHT")
    self:SetPoint("RIGHT", parent.CloseButton, "LEFT")
    self:SetFrameLevel(parent.TitleContainer:GetFrameLevel() + 1)
end

function LiteBagDragButtonMixin:OnMouseDown()
    local parent = self:GetParent()

    if LB.BagsManager:GetFrameOption(parent, "locked") then
        return
    end

    parent:StartMoving()

    -- Use the drag button OnUpdate handler to readjust the attachment
    -- points for the bag buttons and the reagent bag while we are moving.

    local totalElapsed = math.huge
    self:SetScript('OnUpdate',
        function (self, elapsed)
            totalElapsed = totalElapsed + elapsed
            if totalElapsed > 0.2 then
                LB.BagsManager:UpdateForMoveOrResize(parent)
                totalElapsed = 0
            end
        end)

    -- Show the snap anchor
    if LB.BagsManager:GetFrameOption(parent, "snap") then
        local defaultX, defaultY = LB.BagsManager:GetDefaultPosition(parent)
        LiteBagSnapAnchor:ClearAllPoints()
        LiteBagSnapAnchor:SetPoint("CENTER", UIParent, "BOTTOMRIGHT", defaultX, defaultY)
        LiteBagSnapAnchor:Show()
    end
end

local function GetDistanceSq(self, x, y)
    local selfX = self:GetRight() * self:GetScale() - UIParent:GetRight()
    local selfY = self:GetBottom() * self:GetScale() - UIParent:GetBottom()
    return (x - selfX)^2 + (y - selfY)^2
end

function LiteBagDragButtonMixin:OnMouseUp()
    self:SetScript('OnUpdate', nil)

    local parent = self:GetParent()
    parent:StopMovingOrSizing()

    LiteBagSnapAnchor:Hide()

    local snapX, snapY = LB.BagsManager:GetDefaultPosition(parent)

    if LB.BagsManager:GetFrameOption(parent, "snap") and GetDistanceSq(parent, snapX, snapY) < 64^2 then
        parent:ClearAllPoints()
        parent:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", snapX, snapY)
        LB.SetTypeOption("BACKPACK", "position", nil)
    else
        local scale = parent:GetScale()
        local point, _, _, x, y = parent:GetPoint(1)
        LB.SetTypeOption("BACKPACK", "position", { anchor=point, x=x/scale, y=y/scale })
    end
    LB.BagsManager:UpdateForMoveOrResize(parent)
    parent:SetUserPlaced(false)
end
