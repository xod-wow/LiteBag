--[[----------------------------------------------------------------------------

  LiteBag/ContainerFrame.lua

  Copyright 2022 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...


local BagInfoByType = {
    BAGS = {
        bagIDs = { 0, 1, 2, 3, 4 },
        defaultColumns = 10,
    },
    BANK = {
        bagIDs = { -1, 6, 7, 8, 9, 10, 11, 12 },
        defaultColumns = 14,
    },
    REAGENTBAG = {
        bagIDs = { 5 },
        defaultColumns = 10,
    },
}

-- This is as small as you can go
local MIN_COLUMNS = 8

-- These are the gaps between the buttons
local BUTTON_X_GAP, BUTTON_Y_GAP = 5, 4

-- This is some gnarly magic to position the item buttons in a pleasing and
-- appropriate place inside the PortraitFrame. The big gap at the top is where
-- we put the bag buttons (plus the title bar).
local LEFT_OFFSET, TOP_OFFSET = 15, 70
local RIGHT_OFFSET, BOTTOM_OFFSET = 14, 16


LiteBagContainerFrameMixin = CreateFromMixins(ContainerFrameCombinedBagsMixin)

function LiteBagContainerFrameMixin:OnLoad()
    local info = BagInfoByType[self.FrameType]
    self.bagIDs = info.bagIDs
    self.defaultColumns = info.defaultColumns

    -- In 2013 I thought making my owner dummy container frames to be the
    -- button parents was stupid. In 2022 Blizzard are more or less doing it.
    self.bagFrames = {}
    for i, id in ipairs(self.bagIDs) do
        local name = format('%sBag%d', self:GetName(), i)
        local bagFrame = CreateFrame('Frame', name, self)
        bagFrame:SetID(id)
        bagFrame.Items = { }
        tinsert(self.bagFrames, bagFrame)
    end

    self.bagButtons = {}
    for i, id in ipairs(self.bagIDs) do
        local name = format("%sBag%dSlot", self:GetName(), i)
        local bagButton = CreateFrame('ItemButton', name, self, "LiteBagBagButtonTemplate")
        bagButton:SetID(id)
        table.insert(self.bagButtons, bagButton)
    end

    -- from ContainerFrame:OnLoad
    self:RegisterEvent("BAG_OPEN")
    self:RegisterEvent("BAG_CLOSED")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")

    -- from ContainerFrameCombinedBags:OnLoad
    self:RegisterEvent("BAG_CONTAINER_UPDATE")
    self.PortraitButton:SetPoint("CENTER", self:GetParent():GetPortrait(), "CENTER", 3, -3)
end

function LiteBagContainerFrameMixin:GetBagFrameByID(id)
    for _, bag in ipairs(self.bagFrames) do
        if bag:GetID() == id then
            return bag
        end
    end
end

-- The Blizzard code doesn't handle the 28 base bank slots because they fire
-- a different event, so we register and translate it.

function LiteBagContainerFrameMixin:OnShow()
    ContainerFrameCombinedBagsMixin.OnShow(self)
    if self:MatchesBagID(BANK_CONTAINER) then
        self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    end
end

function LiteBagContainerFrameMixin:OnHide()
    ContainerFrameCombinedBagsMixin.OnHide(self)
    self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
end

-- We need to pre-handle some problematic events before ContainerFrame_OnEvent
-- gets to them and does something we don't like inside the default bags.

function LiteBagContainerFrameMixin:OnEvent(event, ...)
    LB.Debug("ContainerFrame OnEvent " .. tostring(event))
    if event == "BAG_CONTAINER_UPDATE" then
        self:SetUpBags()
    elseif event == "ITEM_LOCK_CHANGED" then
        local bag = self:GetBagFrameByID(arg1)
        if arg2 and bag then
            local _, _, locked = GetContainerItemInfo(bag:GetID(), arg2)
            SetItemButtonDesaturated(bag.Items[arg2], locked)
        end
    elseif event == "DISPLAY_SIZE_CHANGED" then
        -- We aren't doing any crazy reflowing stuff so do nothing
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        -- The bank actually gives you the slot, unlike the bags, but
        -- there's nothing we can send through to make it efficient.
        ContainerFrame_OnEvent(self, "BAG_UPDATE", BANK_CONTAINER)
    else
        ContainerFrame_OnEvent(self, event, ...)
    end

end

-- Essentially ContainerFrame_GenerateFrame without the bad stuff. If it
-- wasn't for their naming this would be called :Open()

function LiteBagContainerFrameMixin:GenerateFrame()
    LB.Debug("ContainerFrame GenerateFrame " .. self:GetName())

    -- Should check if dirty, probably.
    self:SetUpBags()
    self:Show()
    self:Raise()
    self:UpdateName()
    self:UpdateMiscellaneousFrames()
    self:UpdateItemLayout()
    self:UpdateFrameSize()
    self:Update()
    self:CheckUpdateDynamicContents()
end

-- for the combined bag frame SetUpBags is done in
--  ContainerFrameSettingsManager:SetUpBagsGeneric
-- but we can't use it because it's pulling the ItemButtons out of the bag
-- frames (UIParent.ContainerFrames).
--
-- If I had been redoing this I would have stopped requiring 
--      bagID = itemButton:GetParent():GetID()
-- because then everything is so much simpler.

local function GetBagItemButton(bag, i)
    if not bag.Items[i] then
        local name = format('%sItem%d', bag:GetName(), i)
        bag.Items[i] = CreateFrame("ItemButton", name, nil, 'LiteBagItemButtonTemplate')
        bag.Items[i]:SetSize(37, 37)
        bag.Items[i]:SetID(i)
        bag.Items[i]:SetParent(bag)
        LB.CallHooks('LiteBagItemButton_Create', bag.Items[i])
    end
    return bag.Items[i]
end

function LiteBagContainerFrameMixin:SetUpBags()
    LB.Debug("ContainerFrame SetUpBags " .. self:GetName())

    self:HideItems()
    self:ClearItems()

    for _, bag in ipairs(self.bagFrames) do
        bag.size = GetContainerNumSlots(bag:GetID())
        for i = 1, bag.size do
            local b = GetBagItemButton(bag, i)
            self:AddItem(b)
        end
        for i,b in ipairs(bag.Items) do
            b:SetShown(i <= bag.size)
        end
    end

    if self:MatchesBagID(BACKPACK_CONTAINER) then
        -- Warning, this messes with the MoneyFrame too. If you
        -- call it on multiple frames they will steal each other's
        -- .MoneyFrame as well as the token tracker.
        ContainerFrameSettingsManager:SetTokenTrackerOwner(self)
    end

    self.size = #self.Items
end

function LiteBagContainerFrameMixin:IsBagOpen(id)
    if self:IsShown() and tContains(self.bagIDs, id) then
        return true
    end
end
    
function LiteBagContainerFrameMixin:SetBagSize()
    self.size = 0
    for _, id in ipairs(self.bagIDs) do
        self.size = self.size + GetContainerNumSlots(id)
    end
end

function LiteBagContainerFrameMixin:SetBagID(id)
    return
end

function LiteBagContainerFrameMixin:MatchesBagID(id)
    return tContains(self.bagIDs, id)
end

function LiteBagContainerFrameMixin:GetContainedBagIDs(outContainedBagIDs)
    Mixin(outContainedBagIDs, self.bagIDs)
end

function LiteBagContainerFrameMixin:UpdateBagButtons()
    for _, bagButton in ipairs(self.bagButtons) do
        bagButton:Update()
        bagButton:Show()
    end
end

function LiteBagContainerFrameMixin:UpdateMiscellaneousFrames()
    if self:MatchesBagID(BANK_CONTAINER) then
        self:GetParent():SetPortraitToUnit('npc')
    else
        self:GetParent():SetPortraitToAsset("Interface/Icons/Inv_misc_bag_08");
    end
    self:UpdateCurrencyFrames();
    self:UpdateBagButtons()
end

function LiteBagContainerFrameMixin:CalculateWidth()
    return self.width
end


function LiteBagContainerFrameMixin:CalculateHeight()
    return self.height
end

function LiteBagContainerFrameMixin:OnTokenWatchChanged()
    self:UpdateTokenTracker()

    -- WARNING! These are in the reverse order from the superclass because
    -- it makes more sense to have the layout calculate the size for complex
    -- layouts than do it all twice.
    self:UpdateItemLayout()
    self:UpdateFrameSize()
end

function LiteBagContainerFrameMixin:SetTokenTracker(tokenFrame)
        tokenFrame:SetParent(self);
        tokenFrame:SetIsCombinedInventory(true)
end

local function inDiffBag(a, b)
    return a:GetParent():GetID() ~= b:GetParent():GetID()
end

local BUTTONORDERS = { }

BUTTONORDERS.default =
    function (self)
        return self.Items
    end

BUTTONORDERS.blizzard =
    function (self)
        local Items = { }
        for b = #self.bagFrames, 1, -1 do
            local bag = self.bagFrames[b]
            for _, b in ipairs(bag.Items) do
                tinsert(Items, b)
            end
        end
        return Items
    end

BUTTONORDERS.reverse =
    function (self)
        local Items = { }
        for i = #self.Items, 1, -1 do
            tinsert(Items, self.Items[i])
        end
        return Items
    end

local LAYOUTS = { }

LAYOUTS.default =
    function (self, Items, ncols)
        local grid = { }

        local w, h = Items[1]:GetSize()

        local xBreak = LB.Options:GetFrameOption(self, 'xbreak')
        local yBreak = LB.Options:GetFrameOption(self, 'ybreak')

        local row, col, maxCol, maxXGap = 0, 0, 0, 0

        local xGap, yGap = 0, 0

        for i = 1, self.size do
            if col > 0 and col % ncols == 0 then
                xGap, col, row = 0, 0, row + 1
                if yBreak and row % yBreak == 0 then
                    yGap = yGap + h/3
                end
            elseif xBreak and col > 0 and col % xBreak == 0 then
                xGap = xGap + w/3
                maxXGap = max(maxXGap, xGap)
            end

            local x = col*(w+BUTTON_X_GAP)+xGap
            local y = row*(h+BUTTON_Y_GAP)+yGap
            tinsert(grid, { x=x, y=y, b=Items[i] })

            maxCol = max(col, maxCol)
            col = col + 1
        end

        grid.ncols = maxCol+1
        grid.totalWidth  = (maxCol+1)*w + maxCol*BUTTON_X_GAP + maxXGap
        grid.totalHeight = (row+1)*h + row*BUTTON_Y_GAP + yGap

        return grid
    end

LAYOUTS.reverse =
    function (self, Items, ncols)
        local grid = LAYOUTS.default(self, Items, ncols)
        grid.reverseDirection = true
        return grid
    end

LAYOUTS.bag =
    function (self, Items, ncols)
        local grid = { }

        local w, h = Items[1]:GetSize()

        local row, col, yGap, maxCol = 0, 0, 0, 0

        for i = 1, self.size do
            local newBag = i > 1 and inDiffBag(Items[i-1], Items[i])
            if col > 1 then
                if newBag then
                    col = 0
                    row = row + 1
                    yGap = yGap + w/3
                elseif col % ncols == 0 then
                    col = 0
                    row = row + 1
                end
            end
            local x = col * (w+BUTTON_X_GAP)
            local y = row * (h+BUTTON_Y_GAP) + yGap
            tinsert(grid, { x=x, y=y, b=Items[i] })
            maxCol = max(col, maxCol)
            col = col + 1
        end

        grid.ncols = maxCol+1
        grid.totalWidth  = (maxCol+1) * w + maxCol * BUTTON_X_GAP
        grid.totalHeight = (row+1) * h + row * BUTTON_Y_GAP + yGap

        return grid
    end

local function GetLayoutNColsForWidth(self, width)
    local layout = LB.Options:GetFrameOption(self, 'layout')
    if not layout or not LAYOUTS[layout] then layout = 'default' end

    local ncols
    local currentCols = LB.Options:GetFrameOption(self, 'columns') or
                            self.defaultColumns or
                            MIN_COLUMNS

    -- The BUTTONORDER doesn't matter for sizing so don't bother calling it.
    -- Search up or down from our current column size, for speed.

    if width < self:GetWidth() then
        ncols = MIN_COLUMNS
        for i = currentCols, MIN_COLUMNS, -1 do
            local layoutGrid = LAYOUTS[layout](self, self.Items, i)
            if layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET <= width then
                ncols = i
                break
            end
        end
    else
        ncols = self.size
        for i = currentCols+1, self.size+1, 1 do
            local layoutGrid = LAYOUTS[layout](self, self.Items, i)
            if layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET > width then
                ncols = i-1
                break
            end
        end
    end
    return ncols
end

local function GetLayoutGridForFrame(self)
    local ncols = LB.Options:GetFrameOption(self, 'columns') or self.defaultColumns
    local layout = LB.Options:GetFrameOption(self, 'layout')
    local order = LB.Options:GetFrameOption(self, 'order')

    if not layout or not LAYOUTS[layout] then layout = 'default' end
    if not order or not BUTTONORDERS[order] then order = 'default' end

    local Items = BUTTONORDERS[order](self)
    return LAYOUTS[layout](self, Items, ncols)
end

function LiteBagContainerFrameMixin:UpdateItemLayout()
    LB.Debug("ContainerFrame UpdateItemLayout " .. self:GetName())
    local layoutGrid = GetLayoutGridForFrame(self)

    local anchor, m, xOff, yOff

    -- Combined frame adds 10 for search bar but we already accounted for it
    local adjustedBottomOffset = BOTTOM_OFFSET + self:CalculateExtraHeight() - 10

    if layoutGrid.reverseDirection then
        anchor, m, xOff, yOff = 'BOTTOMRIGHT', -1, -RIGHT_OFFSET, -adjustedBottomOffset
    else
        anchor, m, xOff, yOff = 'TOPLEFT', 1, LEFT_OFFSET, TOP_OFFSET
    end

    local n = 1

    for _, pos in ipairs(layoutGrid) do
        local x = xOff + m * pos.x
        local y = -yOff - m * pos.y
        pos.b:ClearAllPoints()
        pos.b:SetPoint(anchor, self, x, y)
        pos.b:SetShown(true)
        n = n + 1
    end

    for i = 1, #self.bagButtons do
        local this = self.bagButtons[i]
        local last = self.bagButtons[i-1]
        this:ClearAllPoints()
        if last then
            this:SetPoint("LEFT", last, "RIGHT", 0, 0)
        else
            this:SetPoint("TOPLEFT", self, "TOPLEFT", 60, -31)
        end
        this:Show()
    end

    self.width = layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET
    self.height = layoutGrid.totalHeight + TOP_OFFSET + adjustedBottomOffset
end

function LiteBagContainerFrameMixin:UpdateFrameSize()
    LB.Debug(format("ContainerFrame UpdateFrameSize %s %d,%d", self:GetName(), self.width, self.height))
    self:SetSize(self.width, self.height)
    EventRegistry:TriggerEvent("LiteBag.FrameSize", self)
end

function LiteBagContainerFrameMixin:ResizeToWidth(width)
    LB.Debug(format("ContainerFrame ResizeToWidth %s %d", self:GetName(), width))
    local ncols = GetLayoutNColsForWidth(self, width)
    LB.Options:SetFrameOption(self, 'columns', ncols)
    self:UpdateItemLayout()
    self:UpdateFrameSize()
end

function LiteBagContainerFrameMixin:UpdateSearchBox()

    local searchBox, autoSortButton

    if self:MatchesBagID(BANK_CONTAINER) then
        searchBox = BankItemSearchBox
        autoSortButton = BankItemAutoSortButton
    else
        searchBox = BagItemSearchBox
        autoSortButton = BagItemAutoSortButton
    end

    autoSortButton.anchorBag = self
    autoSortButton:SetParent(self)
    autoSortButton:ClearAllPoints()
    autoSortButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -7, -33)
    autoSortButton:Show()

    local lastBag = self.bagButtons[#self.bagButtons]
    searchBox:SetParent(self)
    searchBox:ClearAllPoints()
    searchBox:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -38, -37)
    searchBox:SetPoint('LEFT', lastBag, 'RIGHT', 8, 0)
    searchBox:Show()
end

function LiteBagContainerFrameMixin:UpdateName()
    if self:MatchesBagID(BANK_CONTAINER) then
        self:GetParent():SetTitle(addonName .. " : " .. BANK)
    else
        self:GetParent():SetTitle(addonName .. " : " .. BAG_NAME_BACKPACK)
    end
end
