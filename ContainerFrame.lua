--[[----------------------------------------------------------------------------

  LiteBag/ContainerFrame.lua

  Copyright 2013 Mike attersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local ITEM_SPACING_X = 5
local ITEM_SPACING_Y = 5

local mixin = {}

local function BagsOffsetFunction(row, col)
    local xoff, yoff = 0, 0
    local xBreak = LB.GetTypeOption('BACKPACK', 'xbreak') or 0
    if xBreak > 0 then
        xoff = math.floor((col-1)/xBreak) * ITEM_SPACING_X * 2
    end
    local yBreak = LB.GetTypeOption('BACKPACK', 'ybreak') or 0
    if yBreak > 0 then
        yoff = math.floor((row-1)/yBreak) * ITEM_SPACING_Y * 2
    end
    return -xoff, yoff
end

function mixin:GetAnchorLayout()
    local layout = ContainerFrameMixin.GetAnchorLayout(self)
    layout:SetCustomOffsetFunction(BagsOffsetFunction)
    return layout
end

function mixin:CalculateHeight()
    local h = ContainerFrameCombinedBagsMixin.CalculateHeight(self)
    local yBreak = LB.GetTypeOption('BACKPACK', 'ybreak') or 0
    if yBreak > 0 then
        local rows = self:GetRows()
        local gapHeight = math.floor((rows-1)/3)* ITEM_SPACING_X * 2
        return h + gapHeight
    else
        return h
    end
end

function mixin:CalculateWidth()
    local w = ContainerFrameCombinedBagsMixin.CalculateWidth(self)
    local xBreak = LB.GetTypeOption('BACKPACK', 'xbreak') or 0
    if xBreak > 0 then
        local columns = self:GetColumns()
        local gapWidth = math.floor((columns-1)/xBreak) * ITEM_SPACING_Y * 2
        return w + gapWidth
    else
        return w
    end
end

function mixin:GetColumns()
    local default = ContainerFrameMixin.GetColumns(self)
    local nCols = LB.GetTypeOption('BACKPACK', 'columns') or default
    return nCols
end

function mixin:SetSearchBoxPoint(searchBox)
    searchBox:SetPoint("RIGHT", BagItemAutoSortButton, "LEFT", -12, 0)
    searchBox:SetWidth(math.min(330, self:GetWidth() - 110))
end

function LB.PatchCombinedBags()
    Mixin(ContainerFrameCombinedBags, mixin)
end
