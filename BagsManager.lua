--[[----------------------------------------------------------------------------

  LiteBag/ContainerFrame.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

local ITEM_SPACING_X = 5
local ITEM_SPACING_Y = 5

local BlizzardContainerFrames = {
    ContainerFrameCombinedBags,
    ContainerFrame1,
    ContainerFrame2,
    ContainerFrame3,
    ContainerFrame4,
    ContainerFrame5,
    ContainerFrame6,
}

local BagButtonIDs = {
    Enum.BagIndex.Backpack,
    Enum.BagIndex.Bag_1,
    Enum.BagIndex.Bag_2,
    Enum.BagIndex.Bag_3,
    Enum.BagIndex.Bag_4,
    Enum.BagIndex.ReagentBag,
}

--[[ BagsManager -----------------------------------------------------------]]--

LB.BagsManager = {
    bagButtons = {}
}

function LB.BagsManager:GetFrameOption(frame, option)
    if frame == ContainerFrameCombinedBags then
        return LB.GetTypeOption('BACKPACK', option)
    end
end

function LB.BagsManager:AddBagButtons(frame, bagIDs)
    for i, bagID in ipairs(bagIDs) do
        local name = string.format("%sBag%dSlot", frame:GetName(), i)
        local bagButton = CreateFrame('ItemButton', name, frame, "LiteBagBagButtonTemplate")
        bagButton:SetID(bagID)
        bagButton:SetFrameLevel(frame.TitleContainer:GetFrameLevel() + 1)
        table.insert(self.bagButtons, bagButton)
    end
end

function LB.BagsManager:UpdateBagButtons(frame)
    if not self:GetFrameOption(frame, 'bagButtons') then
        for _, bagButton in ipairs(self.bagButtons) do
            bagButton:Hide()
        end
    else
        local point, relativePoint
        if frame:GetLeft() and frame:GetLeft() < 20 then
            point, relativePoint = "TOPLEFT", "TOPRIGHT"
        else
            point, relativePoint = "TOPRIGHT", "TOPLEFT"
        end
        for i, bagButton in ipairs(self.bagButtons) do
            local prev = self.bagButtons[i-1]
            bagButton:ClearAllPoints()
            if prev then
                bagButton:SetPoint("TOP", prev, "BOTTOM", 0, 0)
            else
                bagButton:SetPoint(point, frame, relativePoint, 0, -48)
            end
            bagButton:Update()
            bagButton:Show()
        end
    end
end


function LB.BagsManager:BagsOffsetFunction(frame, row, col)
    local xoff, yoff = 0, 0
    local xBreak = self:GetFrameOption(frame, 'xbreak') or 0
    if xBreak > 0 then
        xoff = xoff + math.floor((col-1)/xBreak) * ITEM_SPACING_X * 2
    end
    local yBreak = self:GetFrameOption(frame, 'ybreak') or 0
    if yBreak > 0 then
        yoff = yoff + math.floor((row-1)/yBreak) * ITEM_SPACING_Y * 2
    end
    return -xoff, yoff
end

local function SortItemsByExtendedState(item1, item2)
    local extended1, extended2 = item1:IsExtended(), item2:IsExtended()
    if extended1 ~= extended2 then return not extended1 end

    local bag1, bag2 = item1:GetBagID(), item2:GetBagID()
    if bag1 ~= bag2 then return bag1 > bag2 end

    local id1, id2 = item1:GetID(), item2:GetID()
    return id1 < id2
end

function LB.BagsManager:UpdateItemSort(items)
    if not IsAccountSecured() then
        table.sort(items, SortItemsByExtendedState)
    end
end

function LB.BagsManager:UpdateItemLayout(frame)
    local itemsToLayout = {}
    for _, itemButton in frame:EnumerateValidItems() do
        table.insert(itemsToLayout, itemButton)
    end
    self:UpdateItemSort(itemsToLayout)
    local columns = self:GetColumns(frame)
    local layout = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.BottomRightToTopLeft, columns, ITEM_SPACING_X, ITEM_SPACING_Y)
    layout:SetCustomOffsetFunction(function (row, col) return self:BagsOffsetFunction(frame, row, col) end)
    AnchorUtil.GridLayout(itemsToLayout, frame:GetInitialItemAnchor(), layout)
end

function LB.BagsManager:CalculateHeight(frame)
    local rows = self:GetRows(frame)
    local templateInfo = C_XMLUtil.GetTemplateInfo(frame.itemButtonPool:GetTemplate())
    local itemsHeight = (rows * templateInfo.height) + ((rows - 1) * ITEM_SPACING_Y)
    local h = itemsHeight + frame:GetPaddingHeight() + frame:CalculateExtraHeight()
    local yBreak = LB.GetTypeOption('BACKPACK', 'ybreak') or 0
    if yBreak > 0 then
        local gapHeight = math.floor((rows-1)/3)* ITEM_SPACING_X * 2
        return h + gapHeight
    else
        return h
    end
end

function LB.BagsManager:CalculateWidth(frame)
    local columns = self:GetColumns(frame)
    local templateInfo = C_XMLUtil.GetTemplateInfo(frame.itemButtonPool:GetTemplate())
    local itemsWidth = (columns * templateInfo.width) + ((columns - 1) * ITEM_SPACING_X)
    local w = itemsWidth + frame:GetPaddingWidth()
    local xBreak = LB.GetTypeOption('BACKPACK', 'xbreak') or 0
    if xBreak > 0 then
        local gapWidth = math.floor((columns-1)/xBreak) * ITEM_SPACING_Y * 2
        return w + gapWidth
    else
        return w
    end
end

function LB.BagsManager:UpdateFrameSize(frame)
    local width = self:CalculateWidth(frame)
    local height = self:CalculateHeight(frame)
    frame:SetSize(width, height)
end

function LB.BagsManager:GetColumns(frame)
    local default = ContainerFrameMixin.GetColumns(frame)
    local nCols = LB.GetTypeOption('BACKPACK', 'columns') or default
    return nCols
end

function LB.BagsManager:GetRows(frame)
    return math.ceil(frame:GetBagSize() / self:GetColumns(frame))
end

function LB.BagsManager:SetSearchBoxPoint(frame, searchBox)
    searchBox:ClearAllPoints()
    searchBox:SetPoint("RIGHT", BagItemAutoSortButton, "LEFT", -12, 0)
    searchBox:SetWidth(math.min(330, frame:GetWidth() - 110))
end

-- Adapted from UpdateContainerFrameAnchors()
function LB.BagsManager:GetDefaultPosition(frame)
    local containerScale = frame:GetScale()
    local xOffset = ( EditModeUtil:GetRightActionBarWidth() + 10 ) / containerScale
    local yOffset = CONTAINER_OFFSET_Y / containerScale
    return -xOffset, yOffset
end

function LB.BagsManager:AttachReagentBag(frame)
    -- if the backpack is too far to the left, move the reagent bag to
    -- the right hand side instead of the left. The 11 here is hard-coded
    -- in UpdateContainerFrameAnchors()

    if ContainerFrame6:IsShown() then
        local neededWidth = ContainerFrame6:GetWidth() + 11
        ContainerFrame6:ClearAllPoints()
        if ContainerFrameCombinedBags:GetLeft() < neededWidth then
            ContainerFrame6:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 11, 0)
        else
            ContainerFrame6:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -11, 0)
        end
    end
end

function LB.BagsManager:UpdateForMoveOrResize(frame)
    self:AttachReagentBag(frame)
    self:UpdateBagButtons(frame)
end

local function UpdateContainerFrameAnchorsHook()
    local pos = LB.GetTypeOption("BACKPACK", "position")
    if pos and tContains(ContainerFrameSettingsManager:GetBagsShown(), ContainerFrameCombinedBags) then
        local scale = ContainerFrameCombinedBags:GetScale()
        local parent = ContainerFrameCombinedBags:GetParent()
        ContainerFrameCombinedBags:ClearAllPoints()
        ContainerFrameCombinedBags:SetPoint(pos.anchor, parent, pos.anchor, pos.x/scale, pos.y/scale)
        LB.BagsManager:AttachReagentBag(ContainerFrameCombinedBags)
    end
end

function LB.BagsManager:AllowMoving(frame)
    local name = frame:GetName() .. "DragButton"
    local dragButton = CreateFrame("Button", name, frame, "LiteBagDragButtonTemplate")
    dragButton:Show()

    ContainerFrameCombinedBags:SetMovable(true)
    ContainerFrameCombinedBags:SetClampedToScreen(true)
    hooksecurefunc("UpdateContainerFrameAnchors", UpdateContainerFrameAnchorsHook)
    -- In case we are hidden while moving/sizing
    ContainerFrameCombinedBags:HookScript("OnHide", function () dragButton:SetScript('OnUpdate', nil) end)
end


--[[ Hooks -----------------------------------------------------------------]]--

-- Update all the buttons
local function ContainerUpdateHook(self)
    for _, itemButton in self:EnumerateValidItems() do
        LB.CallHooks('LiteBagItemButton_Update', itemButton)
    end
end

function LB.BagsManager:HookBlizzardBags()
    for _, f in ipairs(BlizzardContainerFrames) do
        hooksecurefunc(f, 'UpdateItems', ContainerUpdateHook)
    end

    local UpdateBagButtons = function (frame) self:UpdateBagButtons(frame) end

    hooksecurefunc(ContainerFrameCombinedBags, 'UpdateItems', UpdateBagButtons)
    -- The first time UpdateItems is called, the frame hasn't been SetPoint yet
    -- and we don't know what side to attach the buttons, so do it again.
    ContainerFrameCombinedBags:HookScript('OnShow', UpdateBagButtons)
end

local hooks = { "UpdateFrameSize", "UpdateItemLayout", "SetSearchBoxPoint" }

function LB.BagsManager:Initialize()
    for _, method in ipairs(hooks) do
        local hook = function (...) self[method](self, ...) end
        hooksecurefunc(ContainerFrameCombinedBags, method, hook)
    end
    self:AddBagButtons(ContainerFrameCombinedBags, BagButtonIDs)
    self:HookBlizzardBags()
    self:AllowMoving(ContainerFrameCombinedBags)
end

function LB.CallHooksOnBags()
    for _, f in ipairs(BlizzardContainerFrames) do
        if f:IsShown() then
            ContainerUpdateHook(f)
        end
    end
end
