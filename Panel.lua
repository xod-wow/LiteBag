--[[----------------------------------------------------------------------------

  LiteBag/Panel.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- These are the gaps between the buttons
local BUTTON_X_GAP, BUTTON_Y_GAP = 5, 4

-- Because this Panel should overlay a PortraitFrame, this will position the
-- buttons into the Inset part of the PortraitFrame.
local LEFT_OFFSET, TOP_OFFSET = 14, 70
local RIGHT_OFFSET, BOTTOM_OFFSET = 15, 35

function LiteBagPanel_Initialize(self, bagIDs)
    LiteBag_Print("Initialize " .. self:GetName())

    -- Create the dummy container frames, so each itembutton can be parented
    -- by one allowing us to use all the Blizzard container frame code

    for i, id in ipairs(bagIDs) do
        local name = format("%sContainerFrame%d", self:GetName(), i)
        local bagFrame = CreateFrame("Frame", name, self)
        bagFrame:SetID(id)
        tinsert(self.bagFrames, bagFrame)
    end

    -- Set up the bag buttons with their bag IDs

    for i, b in ipairs(self.bagButtons) do
        if bagIDs[i] then
            b:SetID(bagIDs[i])
            LiteBagBagButton_Update(b)
            b:Show()
        else
            b:Hide()
        end
    end

    -- And update ourself for the bag sizes

    LiteBagPanel_UpdateBagSizes(self)
end

function LiteBagPanel_UpdateBagSizes(self)
    local n = 0

    for _, bag in ipairs(self.bagFrames) do
        for slot = 1, GetContainerNumSlots(bag:GetID()) do
            n = n + 1
            if not self.itemButtons[n] then
                local name = format("%sItemButton%d", self:GetName(), n)
                self.itemButtons[n] = CreateFrame("Button", name, nil, "LiteBagItemButtonTemplate")
                self.itemButtons[n]:SetSize(37, 37)
            end
            self.itemButtons[n]:SetID(slot)
            self.itemButtons[n]:SetParent(bag)
        end
    end

    self.size = n
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

        if i <= self.size then
            itemButton:Show()
        else
            itemButton:Hide()
        end
    end
end

-- Note again, this is overlayed onto a Portrait frame, so there is
-- padding on the edges to align the buttons into the inset.

function LiteBagPanel_UpdateSize(self)
    local w, h = self.itemButtons[1]:GetSize()
    local nrows = ceil(self.size / self.ncols)

    local frameW = self.ncols * w + (self.ncols-1) * BUTTON_X_GAP + LEFT_OFFSET + RIGHT_OFFSET
    local frameH = nrows * h + (nrows-1) * BUTTON_Y_GAP + TOP_OFFSET + BOTTOM_OFFSET

    self:SetSize(frameW, frameH)
end

function LiteBagPanel_SetColsFromWidth(self, width)
    local w = self.itemButtons[1]:GetWidth()
    local ncols = floor( (width - LEFT_OFFSET - RIGHT_OFFSET + BUTTON_X_GAP) / (w + BUTTON_X_GAP) )
    self.ncols = ncols
    return ncols
end

function LiteBagPanel_HideArtifactHelpBoxIfOwned(self)
    if tContains(self.bagFrames, ArtifactRelicHelpBox.owner) then
        ArtifactRelicHelpBox:Hide()
    end
end
local function IterateItemButtons(self)
    local n = 0
    return function ()
        n = n + 1
        if n > self.size then return end
        return self.itemButtons[n]
    end
end

local function IterateItemButtonsByBag(self, bagID)
    local n = 0
    return function ()
        while true do
            n = n + 1
            if n > self.size then return end
            if self.itemButtons[n]:GetParent():GetID() == bagID then
                return self.itemButtons[n]
            end
        end
    end
end
        
function LiteBagPanel_HighlightBagButtons(self, bagID)
    for b in IterateItemButtonsByBag(self, bagID) do
        b:LockHighlight()
    end
end

function LiteBagPanel_UnhighlightBagButtons(self, bagID)
    for b in IterateItemButtonsByBag(self, bagID) do
        b:UnlockHighlight()
    end
end

function LiteBagPanel_ClearNewItems(self)
    for b in IterateItemButtons(self) do
        LiteBagItemButton_ClearNewItem(b)
    end
end


function LiteBagPanel_UpdateItemButtons(self)
    LiteBagPanel_HideArtifactHelpBoxIfOwned(self)

    for b in IterateItemButtons(self) do
        LiteBagItemButton_Update(b)
    end
end

function LiteBagPanel_UpdateCooldowns(self)
    for b in IterateItemButtons(self) do
        LiteBagItemButton_UpdateCooldown(b)
    end
end

function LiteBagPanel_UpdateSearchResults(self)
    for b in IterateItemButtons(self) do
        LiteBagItemButton_UpdateFiltered(b)
    end
end

function LiteBagPanel_UpdateLocked(self)
    for b in IterateItemButtons(self) do
        LiteBagItemButton_UpdateLocked(b)
    end
end

function LiteBagPanel_UpdateQuality(self)
    for b in IterateItemButtons(self) do
        LiteBagItemButton_UpdateQuality(b)
    end
end

function LiteBagPanel_UpdateQuestTextures(self)
    for b in IterateItemButtons(self) do
        LiteBagItemButton_UpdateQuestTexture(b)
    end
end

function LiteBagPanel_OnLoad(self)
    LiteBag_Print("OnLoad " .. self:GetName())
    self.size = 0
    self.ncols = 8
    self.itemButtons = { }
    self.bagFrames = { }
end

function LiteBagPanel_OnShow(self)
    LiteBag_Print("OnShow")
    LiteBagPanel_UpdateItemButtons(self)
end

function LiteBagPanel_OnHide(self)
    LiteBag_Print("OnHide")
    -- Judging by the code in FrameXML/ContainerFrame.lua items are tagged
    -- by the server as "new" in some cases, and you're supposed to clear
    -- the new flag after you see it the first time.
    LiteBagPanel_ClearNewItems(self)
    LiteBagPanel_HideArtifactHelpBoxIfOwned(self)
end
