--[[----------------------------------------------------------------------------

  LiteBag/ContainerPanel.lua

  Copyright 2022 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local BagInfoByType = {
    BACKPACK = {
        bagIDs = { 0, 1, 2, 3, 4, 5 },
        showTokenTracker = true,
        showMoneyFrame = true,
        showBagButtons = true,
        showSearchBox = true,
        showInfoButton = true,
        resizingAllowed = true,
    },
    BANK = {
        bagIDs = { -1, 6, 7, 8, 9, 10, 11, 12 },
        showTokenTracker = false,
        showMoneyFrame = true,
        showBagButtons = true,
        showSearchBox = true,
        showInfoButton = true,
        resizingAllowed = true,
    },
    REAGENTBAG = {
        bagIDs = { 5 },
        showTokenTracker = false,
        showMoneyFrame = false,
        showBagButtons = false,
        showSearchBox = false,
        showInfoButton = false,
        resizingAllowed = false,
    },
}

-- This is as small as you can go
local MIN_COLUMNS = 8

-- These are the gaps between the buttons
local BUTTON_X_GAP, BUTTON_Y_GAP = 5, 4

-- This is some gnarly magic to position the item buttons in a pleasing and
-- appropriate place inside the PortraitFrame. The big gap at the top is where
-- we put the bag buttons and search bar (plus the title bar).

local TITLEBAR_HEIGHT = 25
local BAGBUTTON_HEIGHT = C_XMLUtil.GetTemplateInfo('LiteBagBagButtonTemplate').height
local SEARCHBOX_HEIGHT = BagItemSearchBox:GetHeight()
local TOPELEMENT_GAP = 4
local BAGBUTTON_OFFSET = TITLEBAR_HEIGHT + TOPELEMENT_GAP
local LEFT_OFFSET = 8
local RIGHT_OFFSET = 8
local MINIMUM_TOP_OFFSET = TITLEBAR_HEIGHT + 18
local BOTTOM_OFFSET = 8


LiteBagContainerPanelMixin = CreateFromMixins(ContainerFrameCombinedBagsMixin)

function LiteBagContainerPanelMixin:OnLoad()

    Mixin(self, BagInfoByType[self.FrameType])

    if self.showTokenTracker then
        local name = self:GetName() .. "TokenFrame"
        self.TokenTracker = CreateFrame("Frame", name, self, "BackpackTokenFrameTemplate")
        self.TokenTracker:SetHeight(16)
        -- The Blizzard token tracker is hard coded to be a single tracker which is updated
        -- by direct call from the TokenFrame UI, Also the event handling for it is done
        -- in MainMenuBar. It's a mess.
        hooksecurefunc('TokenFrame_Update', function () self.TokenTracker:Update() end)
    end

    if self.showMoneyFrame then
        local name = self:GetName() .. "MoneyFrame"
        self.MoneyFrame = CreateFrame("Frame", name, self, "ContainerMoneyFrameTemplate")
    end

    if self.showInfoButton then
        self.InfoButton:Show()
        self.InfoButton:SetScript('OnClick',
            function ()
                LB.OpenOptions()
                -- Blizzard options hides all frame, re-show this one
                self:GetParent():Show()
            end)
    end

    self.Items = { }

    self.containsBags = { }
    for _, id in ipairs(self.bagIDs) do self.containsBags[id] = true end

    -- In 2013 I thought making my owner dummy container frames to be the
    -- button parents was stupid. In 2022 Blizzard are more or less doing it.
    -- It would be nicer (for debugging at least) if these were named for the
    -- id instead of the index, but the bank is -1.
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

    self.PortraitButton:SetPoint("CENTER", self:GetParent():GetPortrait(), "CENTER", 3, -3)
end

function LiteBagContainerPanelMixin:GetBagFrameByID(id)
    for _, bag in ipairs(self.bagFrames) do
        if bag:GetID() == id then
            return bag
        end
    end
end

-- The Blizzard code doesn't handle the 28 base bank slots because they fire
-- a different event (PLAYERBANKSLOTS_CHNAGED), so we register and translate
-- it in our event handler before it reaches the Blizzard code.

function LiteBagContainerPanelMixin:OnShow()
    LB.FrameDebug(self, "OnShow")

    self:GenerateFrame()

    ContainerFrameCombinedBagsMixin.OnShow(self)

    if self:MatchesBagID(Enum.BagIndex.Bank) then
        self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
        self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
    end

    -- Blizzard does these in OnLoad for no good reason at all, because they check if
    -- the frame is shown in the event handler anyway. Derp?
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    self:RegisterEvent("BAG_CONTAINER_UPDATE")

    LB.RegisterPluginEvents(self)

    LB.db.RegisterCallback(self, 'OnOptionsModified', self.GenerateFrame, self)
end

function LiteBagContainerPanelMixin:OnHide()
    LB.FrameDebug(self, "OnHide")

    LB.db.UnregisterAllCallbacks(self)

    ContainerFrameCombinedBagsMixin.OnHide(self)

    self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:UnregisterEvent("PLAYERBANKBAGSLOTS_CHANGED")

    self:UnregisterEvent("QUEST_ACCEPTED")
    self:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")
    self:UnregisterEvent("BAG_CONTAINER_UPDATE")

    LB.UnregisterPluginEvents(self)
end

-- We need to pre-handle some problematic events before ContainerFrame_OnEvent
-- gets to them and does something we don't like inside the default bags.

function LiteBagContainerPanelMixin:OnEvent(event, ...)
    LB.EventDebug(self, event, ...)
    if event == "BAG_CONTAINER_UPDATE" then
        self:GenerateFrame()
    elseif event == "BAG_CLOSED" then
        -- Nothing, don't close single bags because this fires when you
        -- move a bag from slot to slot.
    elseif event == "ITEM_LOCK_CHANGED" then
        -- The way Blizzard does uses all kinds of ContainerFrameUtil stuff
        -- that won't work for us.
        local bag = self:GetBagFrameByID(arg1)
        if arg2 and bag then
            local _, _, locked = GetContainerItemInfo(bag:GetID(), arg2)
            SetItemButtonDesaturated(bag.Items[arg2], locked)
        end
    elseif event == "DISPLAY_SIZE_CHANGED" then
        -- We aren't doing any multi-frame reflowing stuff so do nothing
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        -- The bank actually gives you the slot, unlike the bags, but
        -- there's nothing we can send through to make it efficient.
        ContainerFrame_OnEvent(self, "BAG_UPDATE", Enum.BagIndex.Bank)
    elseif event == "PLAYERBANKBAGSLOTS_CHANGED" then
        -- As of DF reliably fires when buying bank slots, but the new info
        -- isn't available right now so delay.
        C_Timer.After(0, function () self:GenerateFrame() end)
    elseif LB.IsPluginEvent(event) then
        self:Update()
    else
        ContainerFrame_OnEvent(self, event, ...)
    end

end

-- Essentially ContainerFrame_GenerateFrame without the bad stuff. If it
-- wasn't for their naming this would be called :Open()

function LiteBagContainerPanelMixin:GenerateFrame()
    LB.FrameDebug(self, "GenerateFrame")

    -- Should check if dirty, probably.
    self:SetUpBags()
    self:Show()
    self:Raise()
    self:UpdateMiscellaneousFrames()
    self:UpdateItemLayout()
    self:UpdateFrameSize()
    self:Update()
    self:CheckUpdateDynamicContents()
end

function LiteBagContainerPanelMixin:CheckUpdateDynamicContents()
    LB.FrameDebug(self, "CheckUpdateDynamicContents")
    if self.TokenTracker then
        self.TokenTracker:Update()
    end
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
        bag.Items[i]:SetID(i)
        bag.Items[i]:SetParent(bag)
        LB.CallHooks('LiteBagItemButton_Create', bag.Items[i])
    end
    return bag.Items[i]
end

function LiteBagContainerPanelMixin:SetUpBags()
    LB.FrameDebug(self, "SetUpBags")

    self.Items = {}

    for _, bag in ipairs(self.bagFrames) do
        bag.size = C_Container.GetContainerNumSlots(bag:GetID())
        for i = 1, bag.size do
            local b = GetBagItemButton(bag, i)
            table.insert(self.Items, b)
        end
        for i,b in ipairs(bag.Items) do
            b:SetShown(i <= bag.size)
        end
    end

    self.size = #self.Items
end

function LiteBagContainerPanelMixin:IsBagOpen(id)
    return self:IsShown() and self.containsBags[id]
end

function LiteBagContainerPanelMixin:SetBagID(id)
    return
end

function LiteBagContainerPanelMixin:MatchesBagID(id)
    return self.containsBags[id]
end

function LiteBagContainerPanelMixin:UpdateBagButtons()
    for _, bagButton in ipairs(self.bagButtons) do
        bagButton:Update()
        bagButton:Show()
    end
end

function LiteBagContainerPanelMixin:UpdateTokenTracker()
    LB.FrameDebug(self, "UpdateTokenTracker")
    if self.TokenTracker and self.TokenTracker:ShouldShow() then
        self.TokenTracker:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 8, 8)
        self.TokenTracker:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 8)
        self.TokenTracker:Show()
        if self.MoneyFrame then
            self.MoneyFrame:SetPoint("BOTTOMLEFT", self.TokenTracker, "TOPLEFT", 0, 3)
            self.MoneyFrame:SetPoint("BOTTOMRIGHT", self.TokenTracker, "TOPRIGHT", 0, 3)
            self.MoneyFrame:Show()
        end
    elseif self.MoneyFrame then
        self.MoneyFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 8, 8)
        self.MoneyFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 8)
        self.MoneyFrame:Show()
    end
end

function LiteBagContainerPanelMixin:CalculateSearchBoxOffset()
    local searchBoxOffset = TITLEBAR_HEIGHT + TOPELEMENT_GAP
    if self.showBagButtons then
        searchBoxOffset = searchBoxOffset + BAGBUTTON_HEIGHT + TOPELEMENT_GAP
    end
    return searchBoxOffset
end

function LiteBagContainerPanelMixin:CalculateTopOffset()
    local topOffset = TITLEBAR_HEIGHT + TOPELEMENT_GAP * 2
    if self.showBagButtons then
        topOffset = topOffset + BAGBUTTON_HEIGHT + TOPELEMENT_GAP
    end
    if self.showSearchBox then
        topOffset = topOffset + SEARCHBOX_HEIGHT + TOPELEMENT_GAP
    end
    return math.max(topOffset, MINIMUM_TOP_OFFSET)
end

-- This accounts for the position gaps of the bottom elements
function LiteBagContainerPanelMixin:CalculateExtraHeight()
    local extraHeight = 0
    if self.MoneyFrame then
        extraHeight = extraHeight + self.MoneyFrame:GetHeight()
    end
    if self.TokenTracker and self.TokenTracker:ShouldShow() then
        extraHeight = extraHeight + self.TokenTracker:GetHeight()
    end
    if self.MoneyFrame and self.TokenTracker then
        extraHeight = extraHeight + 3
    end
    if self.MoneyFrame or self.TokenTraker then
        extraHeight = extraHeight + 6
    end
    return extraHeight
end

function LiteBagContainerPanelMixin:UpdateMiscellaneousFrames()
    if self:MatchesBagID(Enum.BagIndex.Bank) then
        self:GetParent():SetPortraitToUnit('npc')
    else
        self:GetParent():SetPortraitToAsset("Interface/Icons/Inv_misc_bag_08");
    end
    self:UpdateBagButtons()
end

function LiteBagContainerPanelMixin:OnTokenWatchChanged()
    LB.FrameDebug(self, "OnTokenWatchChanged")

    self:UpdateTokenTracker()

    -- WARNING! These are in the reverse order from the superclass because
    -- it makes more sense to have the layout calculate the size for complex
    -- layouts than do it all twice.
    self:UpdateItemLayout()
    self:UpdateFrameSize()
end

function LiteBagContainerPanelMixin:SetTokenTracker(tokenFrame)
        -- tokenFrame:SetParent(self);
        -- tokenFrame:SetIsCombinedInventory(true)
end

local function inDiffBag(a, b)
    return a:GetParent():GetID() ~= b:GetParent():GetID()
end

local function isReagentBagDivide(a, b)
    if not a then
        return false
    end
    local aID, bID = a:GetBagID(), b:GetBagID()
    if aID == bID then
        return false
    else
        return aID == Enum.BagIndex.ReagentBag or bID == Enum.BagIndex.ReagentBag
    end
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

local ItemButtonTemplateInfo = C_XMLUtil.GetTemplateInfo('LiteBagItemButtonTemplate')

local LAYOUTS = { }

LAYOUTS.default =
    function (self, Items, ncols)
        local grid = { }

        local w, h = ItemButtonTemplateInfo.width, ItemButtonTemplateInfo.height

        local xBreak = LB.GetTypeOption(self.FrameType, 'xbreak')
        local yBreak = LB.GetTypeOption(self.FrameType, 'ybreak')

        local row, col, maxCol, maxXGap = 0, 0, 0, 0

        local xGap, yGap, yGapCounter = 0, 0, 0

        for i = 1, self.size do
            if isReagentBagDivide(Items[i-1], Items[i]) then
                xGap, col, row = 0, 0, row + 1
                yGap, yGapCounter = yGap + h/3, 0
            elseif col > 0 and col % ncols == 0 then
                xGap, col, row, yGapCounter = 0, 0, row + 1, yGapCounter + 1
                if yBreak and yGapCounter % yBreak == 0 then
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
    local layout = LB.GetTypeOption(self.FrameType, 'layout')
    if not layout or not LAYOUTS[layout] then layout = 'default' end

    local ncols
    local currentCols = LB.GetTypeOption(self.FrameType, 'columns') or MIN_COLUMNS

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
    local ncols = LB.GetTypeOption(self.FrameType, 'columns')
    local layout = LB.GetTypeOption(self.FrameType, 'layout')
    local order = LB.GetTypeOption(self.FrameType, 'order')

    if not layout or not LAYOUTS[layout] then layout = 'default' end
    if not order or not BUTTONORDERS[order] then order = 'default' end

    local Items = BUTTONORDERS[order](self)
    return LAYOUTS[layout](self, Items, ncols)
end

function LiteBagContainerPanelMixin:UpdateItemLayout()
    LB.FrameDebug(self, "UpdateItemLayout")
    local layoutGrid = GetLayoutGridForFrame(self)

    local anchor, m, xOff, yOff

    local adjustedBottomOffset = BOTTOM_OFFSET + self:CalculateExtraHeight()
    local adjustedTopOffset = self:CalculateTopOffset()

    if layoutGrid.reverseDirection then
        anchor, m, xOff, yOff = 'BOTTOMRIGHT', -1, -RIGHT_OFFSET, -adjustedBottomOffset
    else
        anchor, m, xOff, yOff = 'TOPLEFT', 1, LEFT_OFFSET, adjustedTopOffset
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
        if not self.showBagButtons then
            this:Hide()
        else
            if last then
                this:SetPoint("LEFT", last, "RIGHT", 0, 0)
            else
                this:SetPoint("TOPLEFT", self, "TOPLEFT", 32, -BAGBUTTON_OFFSET)
            end
            this:Show()
        end
    end

    self.width = layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET
    self.height = layoutGrid.totalHeight + adjustedTopOffset + adjustedBottomOffset
end

function LiteBagContainerPanelMixin:UpdateFrameSize()
    LB.FrameDebug(self, "UpdateFrameSize %d,%d", self.width, self.height)
    self:SetSize(self.width, self.height)
    self:GetParent().needsUpdate = true
end

function LiteBagContainerPanelMixin:ResizeToWidth(width)
    LB.FrameDebug(self, "ResizeToWidth %d", width)
    local cols = LB.GetTypeOption(self.FrameType, 'columns')
    local newCols = GetLayoutNColsForWidth(self, width)
    if cols ~= newCols then
        LB.SetTypeOption(self.FrameType, 'columns', newCols, true)
        self:UpdateItemLayout()
        self:UpdateFrameSize()
    end
end

function LiteBagContainerPanelMixin:UpdateSearchBox()
    if not self.showSearchBox then return end

    local searchBox, autoSortButton

    if self:MatchesBagID(Enum.BagIndex.Bank) then
        searchBox = BankItemSearchBox
        autoSortButton = BankItemAutoSortButton
    else
        searchBox = BagItemSearchBox
        autoSortButton = BagItemAutoSortButton
    end

    local searchBoxOffset = self:CalculateSearchBoxOffset()

    autoSortButton.anchorBag = self
    autoSortButton:SetParent(self)
    autoSortButton:ClearAllPoints()
    autoSortButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -14, -searchBoxOffset + 4)
    autoSortButton:Show()

    searchBox:SetParent(self)
    searchBox:ClearAllPoints()
    searchBox:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -48, -searchBoxOffset)
    searchBox:SetPoint('LEFT', self, 'LEFT', 48, 0)
    searchBox:Show()
end

function LiteBagContainerPanelMixin:UpdateItems()
    LB.FrameDebug(self, "UpdateItems")
    ContainerFrameMixin.UpdateItems(self)
    for _, itemButton in self:EnumerateValidItems() do
        LB.CallHooks('LiteBagItemButton_Update', itemButton)
    end
end
