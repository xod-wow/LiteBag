--[[----------------------------------------------------------------------------

  LiteBag/ContainerFrame.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

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

--[[ Bag Buttons -----------------------------------------------------------]]--

local bagButtons = {}

local function AddBagButtons(frame, bagIDs)
    for i, bagID in ipairs(bagIDs) do
        local name = format("%sBag%dSlot", frame:GetName(), i)
        local bagButton = CreateFrame('ItemButton', name, frame, "LiteBagBagButtonTemplate")
        bagButton:SetID(bagID)
        bagButton:SetFrameLevel(frame.TitleContainer:GetFrameLevel() + 1)
        table.insert(bagButtons, bagButton)
    end
end

local function UpdateBagButtons(frame)
    if not LB.GetTypeOption('BACKPACK', 'bagButtons') then
        for i, bagButton in ipairs(bagButtons) do
            bagButton:Hide()
        end
    else
        local point, relativePoint
        if frame:GetLeft() and frame:GetLeft() < 20 then
            point, relativePoint = "TOPLEFT", "TOPRIGHT"
        else
            point, relativePoint = "TOPRIGHT", "TOPLEFT"
        end
        for i, bagButton in ipairs(bagButtons) do
            local prev = bagButtons[i-1]
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


--[[ Override "Mixin" ------------------------------------------------------]]--

local override = {}

local function BagsOffsetFunction(row, col)
    local xoff, yoff = 0, 0
    local xBreak = LB.GetTypeOption('BACKPACK', 'xbreak') or 0
    if xBreak > 0 then
        xoff = xoff + math.floor((col-1)/xBreak) * ITEM_SPACING_X * 2
    end
    local yBreak = LB.GetTypeOption('BACKPACK', 'ybreak') or 0
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

local function UpdateItemSort(items)
    if not IsAccountSecured() then
        table.sort(items, SortItemsByExtendedState)
    end
end

function override:UpdateItemLayout()
    local itemsToLayout = {}
    for _, itemButton in self:EnumerateValidItems() do
        table.insert(itemsToLayout, itemButton)
    end
    UpdateItemSort(itemsToLayout)
    local columns = override.GetColumns(self)
    local layout = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.BottomRightToTopLeft, columns, ITEM_SPACING_X, ITEM_SPACING_Y)
    layout:SetCustomOffsetFunction(BagsOffsetFunction)
    AnchorUtil.GridLayout(itemsToLayout, self:GetInitialItemAnchor(), layout)
end

function override:CalculateHeight()
    local rows = override.GetRows(self)
    local templateInfo = C_XMLUtil.GetTemplateInfo(self.itemButtonPool:GetTemplate())
    local itemsHeight = (rows * templateInfo.height) + ((rows - 1) * ITEM_SPACING_Y)
    local h = itemsHeight + self:GetPaddingHeight() + self:CalculateExtraHeight()
    local yBreak = LB.GetTypeOption('BACKPACK', 'ybreak') or 0
    if yBreak > 0 then
        local gapHeight = math.floor((rows-1)/3)* ITEM_SPACING_X * 2
        return h + gapHeight
    else
        return h
    end
end

function override:CalculateWidth()
    local columns = override.GetColumns(self)
    local templateInfo = C_XMLUtil.GetTemplateInfo(self.itemButtonPool:GetTemplate())
    local itemsWidth = (columns * templateInfo.width) + ((columns - 1) * ITEM_SPACING_X)
    local w = itemsWidth + self:GetPaddingWidth()
    local xBreak = LB.GetTypeOption('BACKPACK', 'xbreak') or 0
    if xBreak > 0 then
        local gapWidth = math.floor((columns-1)/xBreak) * ITEM_SPACING_Y * 2
        return w + gapWidth
    else
        return w
    end
end

function override:UpdateFrameSize()
    local width = override.CalculateWidth(self)
    local height = override.CalculateHeight(self)
    self:SetSize(width, height)
end

function override:GetColumns()
    local default = ContainerFrameMixin.GetColumns(self)
    local nCols = LB.GetTypeOption('BACKPACK', 'columns') or default
    return nCols
end

function override:GetRows()
    return math.ceil(self:GetBagSize() / override.GetColumns(self))
end

function override:SetSearchBoxPoint(searchBox)
    searchBox:ClearAllPoints()
    searchBox:SetPoint("RIGHT", BagItemAutoSortButton, "LEFT", -12, 0)
    searchBox:SetWidth(math.min(330, self:GetWidth() - 110))
end

--[[ Moving ----------------------------------------------------------------]]--

local ContainerFrameCombinedBagsDragButtonMixin = {}

-- Adapted from UpdateContainerFrameAnchors()
local function GetDefaultPosition(self)
    local containerScale = self:GetScale()
    local xOffset = ( EditModeUtil:GetRightActionBarWidth() + 10 ) / containerScale
    local yOffset = CONTAINER_OFFSET_Y / containerScale
    return -xOffset, yOffset
end

local function GetSqDistanceFromSnap(self)
    local defaultX, defaultY = GetDefaultPosition(self)
    local selfX = self:GetRight() * self:GetScale() - UIParent:GetRight()
    local selfY = self:GetBottom() * self:GetScale() - UIParent:GetBottom()
    return (defaultX - selfX)^2 + (defaultY - selfY)^2
end

local function AttachReagentBag()
    -- if the backpack is too far to the left, move the reagent bag to
    -- the right hand side instead of the left. The 11 here is hard-coded
    -- in UpdateContainerFrameAnchors()

    if ContainerFrame6:IsShown() then
        local neededWidth = ContainerFrame6:GetWidth() + 11
        ContainerFrame6:ClearAllPoints()
        if ContainerFrameCombinedBags:GetLeft() < neededWidth then
            ContainerFrame6:SetPoint("BOTTOMLEFT", ContainerFrameCombinedBags, "BOTTOMRIGHT", 11, 0)
        else
            ContainerFrame6:SetPoint("BOTTOMRIGHT", ContainerFrameCombinedBags, "BOTTOMLEFT", -11, 0)
        end
    end
end

function ContainerFrameCombinedBagsDragButtonMixin:OnLoad()
    self:SetPoint("TOP", ContainerFrameCombinedBags.TitleContainer, "TOP")
    self:SetPoint("BOTTOM", ContainerFrameCombinedBags.TitleContainer, "BOTTOM")
    self:SetPoint("LEFT", ContainerFrameCombinedBags.PortraitButton, "RIGHT")
    self:SetPoint("RIGHT", ContainerFrameCombinedBags.CloseButton, "LEFT")
    self:SetFrameLevel(ContainerFrameCombinedBags.TitleContainer:GetFrameLevel() + 1)
    --[[
    self.Background = self:CreateTexture()
    self.Background:SetAllPoints(true)
    self.Background:SetColorTexture(0.5, 1, 0.5)
    ]]
end

function ContainerFrameCombinedBagsDragButtonMixin:OnMouseDown()
    local parent = self:GetParent()
    local defaultX, defaultY = GetDefaultPosition(parent)
    parent:StartMoving()

    -- Use the drag button OnUpdate handler to readjust the attachment
    -- points for the bag buttons and the reagent bag while we are moving.

    local totalElapsed = 1000
    self:SetScript('OnUpdate',
        function (self, elapsed)
            totalElapsed = totalElapsed + elapsed
            if totalElapsed > 0.2 then
                AttachReagentBag()
                UpdateBagButtons(ContainerFrameCombinedBags)
                totalElapsed = 0
            end
        end)

    -- Show the snap anchor
    if LB.GetTypeOption("BACKPACK", "snap") then
        LiteBagSnapAnchor:SetPoint("CENTER", UIParent, "BOTTOMRIGHT", defaultX, defaultY)
        LiteBagSnapAnchor:Show()
    end
end

function ContainerFrameCombinedBagsDragButtonMixin:OnMouseUp()
    self:SetScript('OnUpdate', nil)

    local parent = self:GetParent()
    parent:StopMovingOrSizing()
    LiteBagSnapAnchor:Hide()
    if LB.GetTypeOption("BACKPACK", "snap") and GetSqDistanceFromSnap(parent) < 64^2 then
        local defaultX, defaultY = GetDefaultPosition(parent)
        parent:ClearAllPoints()
        parent:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", defaultX, defaultY)
        LB.SetTypeOption("BACKPACK", "position", nil)
    else
        local scale = parent:GetScale()
        local point, _, _, x, y = parent:GetPoint(1)
        LB.SetTypeOption("BACKPACK", "position", { anchor=point, x=x/scale, y=y/scale })
    end
    parent:SetUserPlaced(false)
end

local function UpdateContainerFrameAnchorsHook()
    local pos = LB.GetTypeOption("BACKPACK", "position")
    if pos and tContains(ContainerFrameSettingsManager:GetBagsShown(), ContainerFrameCombinedBags) then
        local scale = ContainerFrameCombinedBags:GetScale()
        local parent = ContainerFrameCombinedBags:GetParent()
        ContainerFrameCombinedBags:ClearAllPoints()
        ContainerFrameCombinedBags:SetPoint(pos.anchor, parent, pos.anchor, pos.x/scale, pos.y/scale)
    end
    AttachReagentBag()
end

local function AllowMovingCombinedBags()
    local dragButton = CreateFrame("Button", "ContainerFrameCombinedBagsDragButton", ContainerFrameCombinedBags)
    Mixin(dragButton, ContainerFrameCombinedBagsDragButtonMixin)
    dragButton:OnLoad()
    dragButton:SetScript("OnMouseDown", dragButton.OnMouseDown)
    dragButton:SetScript("OnMouseUp", dragButton.OnMouseUp)
    dragButton:Show()

    ContainerFrameCombinedBags:SetMovable(true)
    ContainerFrameCombinedBags:SetClampedToScreen(true)
    hooksecurefunc("UpdateContainerFrameAnchors", UpdateContainerFrameAnchorsHook)
    -- In case we are hidden while moving/sizing
    ContainerFrameCombinedBags:HookScript("OnHide", function (self) dragButton:SetScript('OnUpdate', nil) end)
end


--[[ Hooks -----------------------------------------------------------------]]--

-- Update all the buttons
local function ContainerUpdateHook(self)
    for _, itemButton in self:EnumerateValidItems() do
        LB.CallHooks('LiteBagItemButton_Update', itemButton)
    end
end

local function HookBlizzardBags()
    for _, f in ipairs(BlizzardContainerFrames) do
        hooksecurefunc(f, 'UpdateItems', ContainerUpdateHook)
    end
    hooksecurefunc(ContainerFrameCombinedBags, 'UpdateItems', UpdateBagButtons)
    -- The first time UpdateItems is called, the frame hasn't been SetPoint yet
    -- and we don't know what side to attach the buttons, so do it again.
    ContainerFrameCombinedBags:HookScript('OnShow', UpdateBagButtons)
end

local hooks = { "UpdateFrameSize", "UpdateItemLayout", "SetSearchBoxPoint" }

function LB.PatchBags()
    for _, hook in ipairs(hooks) do
        hooksecurefunc(ContainerFrameCombinedBags, hook, override[hook])
    end
    AddBagButtons(ContainerFrameCombinedBags, BagButtonIDs)
    HookBlizzardBags()
    AllowMovingCombinedBags()
end

function LB.CallHooksOnBags()
    for _, f in ipairs(BlizzardContainerFrames) do
        if f:IsShown() then
            ContainerUpdateHook(f)
        end
    end
end
