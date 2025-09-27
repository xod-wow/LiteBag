--[[----------------------------------------------------------------------------

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

-- This precalculates the number of yBreak for each column so we aren't
-- looping so many times per itemButton in BagsOffsetFunctionBags.
function LB.BagsManager:CalculateBagBreaks(frame)
    self.bagBreaksByRow = {}

    if self:GetFrameOption(frame, 'layout') == 'bags' then
        local columns = self:GetColumns(frame)
        local bagRowCounts = {}
        for bagID = Enum.BagIndex.Bag_4, Enum.BagIndex.Backpack, -1 do
            local slots = C_Container.GetContainerNumSlots(bagID)
            table.insert(bagRowCounts, math.ceil(slots / columns))
        end
        for bagIndex, rowCount in ipairs(bagRowCounts) do
            for i = 1, rowCount do  -- luacheck: ignore 213
                table.insert(self.bagBreaksByRow, bagIndex-1)
            end
        end
    else
        local yBreak = self:GetFrameOption(frame, 'ybreak') or 0
        for i = 1, self:GetRows(frame) do
            if yBreak > 0 then
                self.bagBreaksByRow[i] = math.floor((i-1)/yBreak)
            else
                self.bagBreaksByRow[i] = 0
            end
        end
    end
end

function LB.BagsManager:BagsOffsetFunction(frame, row, col)
    local xoff = 0

    local xBreak = self:GetFrameOption(frame, 'xbreak') or 0
    if xBreak > 0 then
        xoff = math.floor((col-1)/xBreak) * ITEM_SPACING_X * 2
    end

    local yoff = self.bagBreaksByRow[row] * ITEM_SPACING_Y * 2
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

-- Rather than implementing my own layout code, just use GridLayout but add
-- spacers to fill out rows where necessary. This seems to be good enough for
-- the buttons not to be shown.
--
-- It is possible to make GridLayout work in other directions but then I
-- would have to figure out the top offset.
--
-- Be careful the spacer is the same size as the other itembuttons as it
-- will often be itemsToLayout[1] and used by AnchorUtil to get the size.
--
-- I'm also 80% sure if the spacer is not secure taint will go everywhere, so
-- don't be tempted to make it some kind of non-frame (even though that would
-- be super nice, to implement the minimum API for LayoutGrid which are all
-- no-op).

local hiddenParent = CreateFrame('Frame')
hiddenParent:Hide()
local spacerItemButton = CreateFrame('ItemButton', nil, hiddenParent, "ContainerFrameItemButtonTemplate")

local function inDiffBag(a, b) return not b or a:GetBagID() ~= b:GetBagID() end

function LB.BagsManager:AddSpacersToItemList(frame, itemsToLayout)
    local columns = self:GetColumns(frame)
    if self:GetFrameOption(frame, 'layout') == 'topleft' then
        -- Add spacers so the gap is bottom-right not top-left.
        local nExtra = -#itemsToLayout % columns
        for i = 1, nExtra do    -- luacheck: ignore 213
            table.insert(itemsToLayout, 1, spacerItemButton)
        end
    elseif self:GetFrameOption(frame, 'layout') == 'bags' then
        -- This is a bit funky in order to put the spaces at the bottomright
        -- of the bag when the layout starts at the bottomright. They have to
        -- come before the first layout item from that bag, which is the last
        -- item in the bag.
        local i = 1
        while i < #itemsToLayout do
            if inDiffBag(itemsToLayout[i], itemsToLayout[i-1]) then
                local bagID = itemsToLayout[i]:GetBagID()
                local slots = C_Container.GetContainerNumSlots(bagID)
                while slots % columns ~= 0 do
                    table.insert(itemsToLayout, i, spacerItemButton)
                    i = i + 1
                    slots = slots + 1
                end
            end
            i = i + 1
        end
    end
end

function LB.BagsManager:UpdateItemLayout(frame)
    local itemsToLayout = {}
    for _, itemButton in frame:EnumerateValidItems() do
        table.insert(itemsToLayout, itemButton)
    end
    self:UpdateItemSort(itemsToLayout)
    self:CalculateBagBreaks(frame)
    self:AddSpacersToItemList(frame, itemsToLayout)
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

    if self:GetFrameOption(frame, 'layout') == 'bags' then
        -- Always 5 bags, 4 gaps
        return h + 4 * ITEM_SPACING_Y * 2
    elseif yBreak > 0 then
        local gapHeight = math.floor((rows-1)/yBreak) * ITEM_SPACING_Y * 2
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
        local gapWidth = math.floor((columns-1)/xBreak) * ITEM_SPACING_X * 2
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
    local columns = self:GetColumns(frame)
    if self:GetFrameOption(frame, 'layout') == 'bags' then
        local rows = 0
        for bagID = Enum.BagIndex.Backpack, Enum.BagIndex.Bag_4 do
            local slots = C_Container.GetContainerNumSlots(bagID)
            rows = rows + math.ceil(slots / columns)
        end
        return rows
    else
        return math.ceil(frame:GetBagSize() / columns)
    end
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
function LB.BagsManager:CallItemHooks(frame)
    for _, itemButton in frame:EnumerateValidItems() do
        LB.CallHooks('LiteBagItemButton_Update', itemButton)
    end
end

function LB.BagsManager:UpdateItems(frame)
    self:CallItemHooks(frame)
    self:UpdateBagButtons(frame)
end

local directHooks = { "UpdateItems", "UpdateFrameSize", "UpdateItemLayout", "SetSearchBoxPoint" }

function LB.BagsManager:Initialize()
    for _, method in ipairs(directHooks) do
        local hook = function (...) self[method](self, ...) end
        hooksecurefunc(ContainerFrameCombinedBags, method, hook)
    end

    for _, f in ipairs(BlizzardContainerFrames) do
        hooksecurefunc(f, 'UpdateItems', function () self:CallItemHooks(f) end)
    end

    self:AddBagButtons(ContainerFrameCombinedBags, BagButtonIDs)

    -- The first time UpdateItems is called, the frame hasn't been SetPoint yet
    -- and we don't know what side to attach the buttons, so do it again.
    ContainerFrameCombinedBags:HookScript('OnShow', function (f) self:UpdateBagButtons(f) end)

    self:AllowMoving(ContainerFrameCombinedBags)
end

function LB.BagsManager:CallHooks()
    for _, f in ipairs(BlizzardContainerFrames) do
        if f:IsShown() then
            ContainerUpdateHook(f)
        end
    end
end
