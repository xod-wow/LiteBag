--[[----------------------------------------------------------------------------

  LiteBag/Panel.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local MIN_COLUMNS = 8

-- These are the gaps between the buttons
local BUTTON_X_GAP, BUTTON_Y_GAP = 5, 4

-- Because this Panel should overlay a PortraitFrame, this will position the
-- buttons into the Inset part of the PortraitFrame.
local LEFT_OFFSET, TOP_OFFSET = 15, 70
local RIGHT_OFFSET, BOTTOM_OFFSET = 14, 35

local PluginUpdateEvents = { }

local IsKeyRingEnabled = IsKeyRingEnabled or function () return GetCVarBool('showkeyring') end

function LiteBagPanel_Initialize(self, bagIDs)
    LB.Debug("Panel Initialize " .. self:GetName())

    -- Create the dummy container frames, so each itembutton can be parented
    -- by one allowing us to use all the Blizzard container frame code

    for i, id in ipairs(bagIDs) do
        local name = format('%sContainerFrame%d', self:GetName(), i)
        local bagFrame = CreateFrame('Frame', name, self)
        bagFrame:SetID(id)
        bagFrame.itemButtons = { }
        tinsert(self.bagFrames, bagFrame)
    end

    if tContains(bagIDs, BANK_CONTAINER) then
        self.isBank = true
    end

    if tContains(bagIDs, BACKPACK_CONTAINER) then
        self.isBackpack = true
    end

    -- Set up the bag buttons with their bag IDs. Classic doesn't support
    -- parentArray and appears to not make the buttons at all.

    if not self.bagButtons then
        self.bagButtons = {}
        local p
        for i = 1, 8 do
            local n = self:GetName() .. "Button" .. i
            local f = CreateFrame("Button", n, self, "LiteBagBagButtonTemplate")
            if p then
                f:SetPoint("LEFT", p, "RIGHT", 4, 0)
            else
                f:SetPoint("TOPLEFT", self, "TOPLEFT", 60, -31)
            end
            p = f
            table.insert(self.bagButtons, f)
        end
    end

    for i, b in ipairs(self.bagButtons) do
        if bagIDs[i] == KEYRING_CONTAINER and not IsKeyRingEnabled() then
            b:Hide()
        elseif bagIDs[i] then
            b:SetID(bagIDs[i])
            b:Update()
            b:Show()
        else
            b:Hide()
        end
    end

    self.showKeyring = false

    -- And update ourself for the bag sizes. Need to watch PLAYER_LOGIN
    -- because the size of the bags isn't known until then the first
    -- time you start the game.
    self:RegisterEvent('PLAYER_LOGIN')
end

local function GetBagFrame(self, id)
    for _, bag in ipairs(self.bagFrames) do
        if bag:GetID() == id then
            return bag
        end
    end
end

function LiteBagPanel_UpdateBagSlotCounts(self)
    LB.Debug("Panel UpdateBagSlotCounts " .. self:GetName())
    local size = 0

    for _, b in ipairs(self.bagButtons) do
        b:Update()
    end

    wipe(self.itemButtons)

    for _, bag in ipairs(self.bagFrames) do
        local bagID = bag:GetID()
        if bagID == KEYRING_CONTAINER then
            bag.size = IsKeyRingEnabled() and self.showKeyring and GetKeyRingSize() or 0
        else
            bag.size = C_Container.GetContainerNumSlots(bagID)
        end
        for i = 1, bag.size do
            if not bag.itemButtons[i] then
                local name = format('%sItem%d', bag:GetName(), i)
                bag.itemButtons[i] = CreateFrame('Button', name, nil, 'LiteBagItemButtonTemplate')
                bag.itemButtons[i]:SetSize(37, 37)
                LB.CallHooks('LiteBagItemButton_Create', bag.itemButtons[i])
            end
            bag.itemButtons[i]:SetID(i)
            bag.itemButtons[i]:SetParent(bag)
            size = size + 1
            self.itemButtons[size] = bag.itemButtons[i]
        end
        for i,b in ipairs(bag.itemButtons) do
            b:SetShown(i <= bag.size)
        end
    end
    self.size = size
end

local function inDiffBag(a, b)
    return a:GetParent():GetID() ~= b:GetParent():GetID()
end

local function isKeyringDivide(a, b)
    if not a then
        return false
    end
    local aID, bID = a:GetParent():GetID(), b:GetParent():GetID()
    if aID == bID then
        return false
    else
        return aID == KEYRING_CONTAINER or bID == KEYRING_CONTAINER
    end
end

local BUTTONORDERS = { }

BUTTONORDERS.default =
    function (self)
        return self.itemButtons
    end

BUTTONORDERS.blizzard =
    function (self)
        local itemButtons = { }
        for b = #self.bagFrames, 1, -1 do
            local bag = self.bagFrames[b]
            for i = 1, bag.size do
                tinsert(itemButtons, bag.itemButtons[i])
            end
        end
        return itemButtons
    end

BUTTONORDERS.reverse =
    function (self)
        local itemButtons = { }
        for i = #self.itemButtons, 1, -1 do
            tinsert(itemButtons, self.itemButtons[i])
        end
        return itemButtons
    end

local LAYOUTS = { }

LAYOUTS.default =
    function (self, itemButtons, ncols)
        local grid = { }

        local w, h = itemButtons[1]:GetSize()

        local xBreak = LB.Options:GetFrameOption(self, 'xbreak')
        local yBreak = LB.Options:GetFrameOption(self, 'ybreak')

        local row, col, maxCol, maxXGap = 0, 0, 0, 0

        local xGap, yGap = 0, 0

        for i = 1, self.size do
            if isKeyringDivide(itemButtons[i-1], itemButtons[i]) then
                xGap, col, row = 0, 0, row + 1
                yGap, yGapCounter = yGap + h/3, 0
            elseif col > 0 and col % ncols == 0 then
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
            tinsert(grid, { x=x, y=y, b=itemButtons[i] })

            maxCol = max(col, maxCol)
            col = col + 1
        end

        grid.ncols = maxCol+1
        grid.totalWidth  = (maxCol+1)*w + maxCol*BUTTON_X_GAP + maxXGap
        grid.totalHeight = (row+1)*h + row*BUTTON_Y_GAP + yGap

        return grid
    end

LAYOUTS.reverse =
    function (self, itemButtons, ncols)
        local grid = LAYOUTS.default(self, itemButtons, ncols)
        grid.reverseDirection = true
        return grid
    end

LAYOUTS.bag =
    function (self, itemButtons, ncols)
        local grid = { }

        local w, h = itemButtons[1]:GetSize()

        local row, col, yGap, maxCol = 0, 0, 0, 0


        for i = 1, self.size do
            local newBag = i > 1 and inDiffBag(itemButtons[i-1], itemButtons[i])
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
            tinsert(grid, { x=x, y=y, b=itemButtons[i] })
            maxCol = max(col, maxCol)
            col = col + 1
        end

        grid.ncols = maxCol+1
        grid.totalWidth  = (maxCol+1) * w + maxCol * BUTTON_X_GAP
        grid.totalHeight = (row+1) * h + row * BUTTON_Y_GAP + yGap

        return grid
    end

local function LiteBagPanel_ApplyLayout(self, layoutGrid)
    local anchor, m, xOff, yOff

    if layoutGrid.reverseDirection then
        anchor, m, xOff, yOff = 'BOTTOMRIGHT', -1, -RIGHT_OFFSET, -BOTTOM_OFFSET
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

    -- Return the total panel width and height
    return layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET,
           layoutGrid.totalHeight + TOP_OFFSET + BOTTOM_OFFSET
end

-- Note again, this is overlayed onto a Portrait frame, so there is
-- padding on the edges to align the buttons into the inset.

function LiteBagPanel_UpdateSizeAndLayout(self)
    LB.Debug("Panel UpdateSizeAndLayout " .. self:GetName())

    local ncols = LB.Options:GetFrameOption(self, 'columns') or self.defaultColumns
    local layout = LB.Options:GetFrameOption(self, 'layout')
    local order = LB.Options:GetFrameOption(self, 'order')

    if not layout or not LAYOUTS[layout] then layout = 'default' end
    if not order or not BUTTONORDERS[order] then order = 'default' end

    local itemButtons = BUTTONORDERS[order](self)
    local layoutGrid = LAYOUTS[layout](self, itemButtons, ncols)
    local frameW, frameH = LiteBagPanel_ApplyLayout(self, layoutGrid)

    LB.Debug(format("Panel SetSize %s %d,%d", self:GetName(), frameW, frameH))
    self:SetSize(frameW, frameH)
end

function LiteBagPanel_ResizeToFrame(self, width, height)
    LB.Debug(format("Panel ResizeToFrame %s %d,%d", self:GetName(), width, height))

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
            local layoutGrid = LAYOUTS[layout](self, self.itemButtons, i)
            if layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET <= width then
                ncols = i
                break
            end
        end
    else
        ncols = self.size
        for i = currentCols+1, self.size+1, 1 do
            local layoutGrid = LAYOUTS[layout](self, self.itemButtons, i)
            if layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET > width then
                ncols = i-1
                break
            end
        end
    end

    LB.Options:SetFrameOption(self, 'columns', ncols)
    LiteBagPanel_UpdateSizeAndLayout(self)
end

function LiteBagPanel_HighlightBagButtons(self, bagID)
    local bag = GetBagFrame(self, bagID)
    for i = 1, bag.size do
        bag.itemButtons[i]:LockHighlight()
    end
end

function LiteBagPanel_UnhighlightBagButtons(self, bagID)
    local bag = GetBagFrame(self, bagID)
    for i = 1, bag.size do
        bag.itemButtons[i]:UnlockHighlight()
    end
end

function LiteBagPanel_ClearNewItems(self)
    for i = 1, self.size do
        LiteBagItemButton_ClearNewItem(self.itemButtons[i])
    end
end

-- This is a modied copy of ContainerFrame_Update from FrameXML/ContainerFrame.lua

function LiteBagPanel_UpdateBag(self)
        local id = self:GetID()
        local name, itemButton
        local texture, itemCount, locked, quality, readable, _, isFiltered, noValue, itemID, isBound
        local tooltipOwner = GameTooltip:GetOwner()
        local baseSize = C_Container.GetContainerNumSlots(id)

        for i = 1, self.size or 0, 1 do
            itemButton = self.itemButtons[i]
            name  = itemButton:GetName()

            local info = C_Container.GetContainerItemInfo(id, itemButton:GetID())
            texture = info and info.iconFileID
            itemCount = info and info.stackCount
            locked = info and info.isLocked
            quality = info and info.quality
            readable = info and info.isReadable
            isFiltered = info and info.isFiltered
            noValue = info and info.hasNoValue
            itemID = info and info.itemID

            SetItemButtonTexture(itemButton, texture)
            SetItemButtonQuality(itemButton, quality, itemID)
            SetItemButtonCount(itemButton, itemCount)
            SetItemButtonDesaturated(itemButton, locked)

            ContainerFrame_UpdateQuestItem(self, i, itemButton)

            itemButton.BattlepayItemTexture:Hide()
            itemButton.NewItemTexture:Hide()

            itemButton.JunkIcon:Hide()

            if texture then
                ContainerFrame_UpdateCooldown(id, itemButton)
                itemButton.hasItem = 1
            else
                _G[name.."Cooldown"]:Hide()
                itemButton.hasItem = nil
            end
            itemButton.readable = readable

            if itemButton == tooltipOwner then
                if C_Container.GetContainerItemInfo(self:GetID(), itemButton:GetID()) then
                    itemButton.UpdateTooltip(itemButton)
                else
                    GameTooltip:Hide()
                end
            end

            if ( isFiltered ) then
                itemButton.searchOverlay:Show();
            else
                itemButton.searchOverlay:Hide();
            end

            LB.CallHooks('LiteBagItemButton_Update', itemButton)
        end
end

function LiteBagPanel_UpdateAllBags(self)
    for _, bag in ipairs(self.bagFrames) do
        LiteBagPanel_UpdateBag(bag)
    end
end

function LiteBagPanel_OnLoad(self)
    self.size = 0
    self.itemButtons = { }
    self.bagFrames = { }
end

function LB.AddUpdateEvent(e)
    if e == 'PLAYER_LOGIN' then return end
    PluginUpdateEvents[e] = true
end

function LiteBagPanel_Update(self)
    LiteBagPanel_UpdateBagSlotCounts(self)
    LiteBagPanel_UpdateSizeAndLayout(self)
    LiteBagPanel_UpdateAllBags(self)
    self:GetParent():SetHeight(self:GetHeight())
end

function LiteBagPanel_OnShow(self)
    LB.Debug("Panel OnShow " .. self:GetName())
    LiteBagPanel_Update(self)

    -- LB.Options:RegisterCallback(self, LiteBagPanel_UpdateAllBags)

    -- From ContainerFrame:OnLoad()
    -- self:RegisterEvent('BAG_OPEN')
    self:RegisterEvent('BAG_CLOSED')
    self:RegisterEvent('QUEST_ACCEPTED')
    self:RegisterEvent('UNIT_QUEST_LOG_CHANGED')

    -- From ContainerFrame:OnShow()
    self:RegisterEvent('BAG_UPDATE')
    self:RegisterEvent('UNIT_INVENTORY_CHANGED')
    self:RegisterEvent('ITEM_LOCK_CHANGED')
    self:RegisterEvent('BAG_UPDATE_COOLDOWN')
    -- self:RegisterEvent('DISPLAY_SIZE_CHANGED')
    self:RegisterEvent('INVENTORY_SEARCH_UPDATE')
    self:RegisterEvent('BAG_NEW_ITEMS_UPDATED')
    self:RegisterEvent('BAG_SLOT_FLAGS_UPDATED')

    if self.isBank then
        self:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
        self:RegisterEvent('PLAYERBANKBAGSLOTS_CHANGED')
    end

    for e in pairs(PluginUpdateEvents) do self:RegisterEvent(e) end
end

function LiteBagPanel_OnHide(self)
    LB.Debug("Panel OnHide " .. self:GetName())

    -- LB.Options:UnregisterAllCallbacks(self)
    self:UnregisterAllEvents()

    for _, bag in ipairs(self.bagFrames) do
        -- This is replacing UpdateNewItemsList
        local bagID = bag:GetID()
        for i = 1, bag.size do
            local slotID = bag.itemButtons[i]:GetID()
            C_NewItems.RemoveNewItem(bagID, slotID)
        end
        if ContainerFrame_CloseTutorial then
            ContainerFrame_CloseTutorial(bag)
        end
    end
end

-- These events are only registered while the panel is shown (except for
-- PLAYER_LOGIN), so we can call the update functions without worrying that we
-- don't need to.

--
-- Some events that fire a lot have specific code to just update the
-- bags or changes that they fire for (where possible).  Others are
-- rare enough it's OK to call LiteBagPanel_UpdateAllBags to do everything.
function LiteBagPanel_OnEvent(self, event, ...)
    local arg1, arg2 = ...
    LB.Debug(format("Panel OnEvent %s %s %s %s", self:GetName(), event, tostring(arg1), tostring(arg2)))

    if event == 'PLAYER_LOGIN' then
        LiteBagPanel_UpdateBagSlotCounts(self)
        return
    end

    if event == 'MERCHANT_SHOW' or event == 'MERCHANT_CLOSED' then
        LiteBagPanel_UpdateAllBags(self)
        return
    end

    if event == 'BAG_CLOSED' then
        -- BAG_CLOSED fires when you drag a bag out of a slot but for the
        -- bank GetContainerNumSlots doesn't return the updated size yet,
        -- so we have to wait until BAG_UPDATE_DELAYED fires.
        self:RegisterEvent('BAG_UPDATE_DELAYED')
        return
    end

    if event == 'BAG_UPDATE_DELAYED' then
        self:UnregisterEvent('BAG_UPDATE_DELAYED')
        LiteBagPanel_Update(self)
        return
    end

    if event == 'ITEM_LOCK_CHANGED' then
        if arg1 == BANK_CONTAINER and arg2 > NUM_BANKGENERIC_SLOTS then
            return
        end
        local bag = GetBagFrame(self, arg1)
        if arg2 and bag then
            -- the bags are packed in a weird way inside the blizz containers
            -- so we have to do some arithmetic to make it come out right
            ContainerFrame_UpdateLockedItem(bag, bag.size + 1 - arg2)
        end
        return
    end

    if event == 'BAG_UPDATE_COOLDOWN' then
        for _, bag in ipairs(self.bagFrames) do
            ContainerFrame_UpdateCooldowns(bag)
        end
        return
    end

    if event == 'QUEST_ACCEPTED' or (event == 'UNIT_QUEST_LOG_CHANGED' and arg1 == 'player') then
        LiteBagPanel_UpdateAllBags(self)
        return
    end

    if event == 'INVENTORY_SEARCH_UPDATE' then
        for _, bag in ipairs(self.bagFrames) do
            ContainerFrame_UpdateSearchResults(bag)
        end
        return
    end

    if event == 'PLAYERBANKSLOTS_CHANGED' then
        -- slot = arg1
        if self.isBank then
            if arg1 > NUM_BANKGENERIC_SLOTS then
                LiteBagPanel_UpdateBagSlotCounts(self)
                LiteBagPanel_UpdateSizeAndLayout(self)
                self:GetParent():SetHeight(self:GetHeight())
            end
            LiteBagPanel_UpdateAllBags(self)
        end
        return
    end

    if event == 'BAG_UPDATE' then
        local bag = GetBagFrame(self, arg1)
        if bag then
            LiteBagPanel_UpdateBag(bag)
        end
        return
    end

    if event == 'BAG_SLOT_FLAGS_UPDATED' then
        local bag = GetBagFrame(self, arg1)
        if bag then
            LiteBagPanel_UpdateBag(bag)
        end
        return
    end

    -- ContainerFrame handles this event but never registers it?
    if event == 'BANK_BAG_SLOT_FLAGS_UPDATED' then
        local bag = GetBagFrame(self, arg1 + NUM_BAG_SLOTS)
        if bag then
            LiteBagPanel_UpdateBag(bag)
        end
        return
    end

    -- Default action for the below plus whatever is added by plugins
    --
    -- BAG_NEW_ITEMS_UPDATED 

    LiteBagPanel_UpdateAllBags(self)
end

-- Exported interface for other addons
_G.LiteBag_AddUpdateEvent = LB.AddUpdateEvent
