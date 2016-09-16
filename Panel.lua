--[[----------------------------------------------------------------------------

  LiteBag2/Panel.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- These are the gaps between the buttons
local BUTTON_X_GAP, BUTTON_Y_GAP = 5, 4

-- Because this Panel is meant to go SetAllPoints onto a PortraitFrame, this
-- is to position the buttons into the Inset part of the PortraitFrame.
local LEFT_OFFSET, TOP_OFFSET = 14, 70
local RIGHT_OFFSET, BOTTOM_OFFSET = 15, 35

function LiteBagPanel_Initialize(bagIDs)

    -- Create the dummy container frames, so each itembutton can be parented
    -- by one allowing us to use all the Blizzard container frame code

    for i, id in bagIDs do
        local name = format("%sContainerFrame%d", self:GetName(), i)
        local bagFrame = CreateFrame("Frame", name, self)
        bagFrame:SetID(id)
        tinsert(self.bagFrames, bagFrame)
    end

    LiteBagPanel_UpdateBagSizes(self)
end

function LiteBagPanel_UpdateBagSizes(self)
    local n = 0

    for _, bag in self.bagFrames do
        for slot = 1, GetContainerNumSlots(bag:GetID())
            n = n + 1
            if not self.itemButtons[n] then
                local name = format("%sItemButton%d", self:GetName(), n)
                self.itemButtons[n] = CreateFrame("Button", name, nil, "ContainerFrameItemButtonTemplate")
                self.itemButtons[n]:SetSize(37, 37)
            end
            self.itemButtons[n]:SetID(slot)
            self.itemButtons[n]:SetParent(bag)
        end
    end

    self.size = n
end

function LiteBagPanel_SetColumns(self, ncols)
    self.ncols = ncols
    if self:IsShown() then
        LiteBagPanel_Layout(self)
    end
end

function LiteBagPanel_Layout(self)
    -- We process all the ItemButtons even if many of them are not
    -- shown, so that we hide the leftovers

    for i, itemButton in ipairs(self.itemButtons) do
        itemButton:ClearAllPoints()
        if i == 1 then
            itemButton:SetPoint("TOPLEFT", self, LEFT_OFFSET, -TOP_OFFSET)
        elseif i % self.ncols == 1 then
            itemButton:SetPoint("TOPLEFT", self.itemButtons[i-self.ncols], "BOTTOMLEFT", 0, -BUTTON_Y_GAP)
        else
            itemButton:SetPoint("TOPLEFT", self.itemButtons[i-1], "TOPRIGHT", BUTTON_X_GAP, 0)
        end

        if i < = self.size then
            itemButton:Show()
        else
            itemButton:Hide()
        end
    end
end

function LiteBagPanel_CalcSize(self,  ncols)
    local w, h = self.itemButtons[1]:GetSize()
    local nrows = ceil(self.size / ncols)

    local frameW = ncols * w + (ncols-1) * BUTTON_X_GAP + LEFT_OFFSET + RIGHT_OFFSET
    local frameH = nrows * h + (nrows-1) * BUTTON_Y_GAP + TOP_OFFSET + BOTTOM_OFFSET

    return frameW, frameH
end

function LiteBagPanel_CalcCols(self, width)
    local w = self.itemButtons[1]:GetWidth()
    local ncols = floor( (width - LEFT_OFFSET - RIGHT_OFFSET + BUTTON_X_GAP) / (w + BUTTON_X_GAP) )
    return ncols
end

function LiteBagPanel_IterateItemButtons(self)
    local n = 0
    return function ()
        n = n + 1
        if n > self.size then return end
        return self.itemButtons[n]
    end
end

function LiteBagPanel_IterateItemButtonsByBag(self, bagID)
    local n = 0
    return function ()
        while true do
            n = n + 1
            if n > self.size then return end
            if self.itemButtons[n]:GetID() == bagID then
                return self.itemButtons[n]
            end
        end
    end
end
        
function LiteBagPanel_HighlightBagButtons(self, bagID)
    for b in LiteBagPanel_IterateItemButtonsByBag(self, bagID) do
        b:LockHighlight()
    end
end

function LiteBagPanel_UnhighlightBagButtons(self, bagID)
    for b in LiteBagPanel_IterateItemButtonsByBag(self, bagID) do
        b:UnlockHighlight()
    end
end

function LiteBagPanel_OnLoad(self)
    self.size = 0
    self.ncols = 8
    self.itemButtons = { }
    self.bagFrames = { }
end

function LiteBagPanel_OnShow(self)
    LiteBagPanel_Layout(self)
end

function LiteBagPanel_OnHide(self)
end

function LiteBagPanel_OnSizeChanged(self)
    LiteBagPanel_Layout(self)
end
