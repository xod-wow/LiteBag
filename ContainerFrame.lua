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


--------------------------------------------------------------------------------

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
        local rows = override.GetRows(self)
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
        local columns = override.GetColumns(self)
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
end

local hooks = { "UpdateFrameSize", "UpdateItemLayout", "SetSearchBoxPoint" }

function LB.PatchBags()
    for _, hook in ipairs(hooks) do
        hooksecurefunc(ContainerFrameCombinedBags, hook, override[hook])
    end
    HookBlizzardBags()
end

function LB.CallHooksOnBags()
    for _, f in ipairs(BlizzardContainerFrames) do
        if f:IsShown() then
            ContainerUpdateHook(f)
        end
    end
end
