--[[----------------------------------------------------------------------------

  LiteBag/Panel.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local MIN_COLUMNS = 8

-- These are the gaps between the buttons
local BUTTON_X_GAP, BUTTON_Y_GAP = 5, 4

-- Because this Panel should overlay a PortraitFrame, this will position the
-- buttons into the Inset part of the PortraitFrame.
local LEFT_OFFSET, TOP_OFFSET = 14, 70
local RIGHT_OFFSET, BOTTOM_OFFSET = 15, 35

function LiteBagPanel_Initialize(self, bagIDs)
    LiteBag_Print("Panel Initialize " .. self:GetName())

    -- Create the dummy container frames, so each itembutton can be parented
    -- by one allowing us to use all the Blizzard container frame code

    for i, id in ipairs(bagIDs) do
        local name = format("%sContainerFrame%d", self:GetName(), i)
        local bagFrame = CreateFrame("Frame", name, self)
        bagFrame:SetID(id)
        tinsert(self.bagFrames, bagFrame)
    end

    if tContains(bagIDs, BANK_CONTAINER) then
        self.isBank = true
    end

    if tContains(bagIDs, BACKPACK_CONTAINER) then
        self.isBackpack = true
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

    -- And update ourself for the bag sizes. Need to watch PLAYER_LOGIN
    -- because the size of the bags isn't known until then the first
    -- time you start the game.
    self:RegisterEvent("PLAYER_LOGIN")
    LiteBagPanel_UpdateBagSizes(self)
end

function LiteBagPanel_UpdateBagSizes(self)
    LiteBag_Print("Panel UpdateBagSizes " .. self:GetName())
    local n = 0

    for _, b in ipairs(self.bagButtons) do
        LiteBagBagButton_Update(b)
    end

    for _, bag in ipairs(self.bagFrames) do
        local bagID = bag:GetID()
        for slot = 1, GetContainerNumSlots(bagID) do
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

-- Note again, this is overlayed onto a Portrait frame, so there is
-- padding on the edges to align the buttons into the inset.

function LiteBagPanel_UpdateSizeAndLayout(self)
    LiteBag_Print("Panel UpdateSize " .. self:GetName())
    local ncols = LiteBag_GetPanelOption(self, "columns") or
                    self.defaultColumns or
                    MIN_COLUMNS
    local nrows = ceil(self.size / ncols)
    local w, h = self.itemButtons[1]:GetSize()

    local frameW = ncols * w + (ncols-1) * BUTTON_X_GAP + LEFT_OFFSET + RIGHT_OFFSET
    local frameH = nrows * h + (nrows-1) * BUTTON_Y_GAP + TOP_OFFSET + BOTTOM_OFFSET

    LiteBag_Print(format("Panel SetSize %d,%d", frameW, frameH))

    self:SetSize(frameW, frameH)

    LiteBag_Print("Panel Layout " .. self:GetName())
    -- We process all the ItemButtons even if many of them are not
    -- shown, so that we hide the leftovers

    for i, itemButton in ipairs(self.itemButtons) do
        itemButton:ClearAllPoints()
        if i == 1 then
            itemButton:SetPoint("TOPLEFT", self, LEFT_OFFSET, -TOP_OFFSET)
        elseif i % ncols == 1 then
            itemButton:SetPoint("TOPLEFT", self.itemButtons[i-ncols], "BOTTOMLEFT", 0, -BUTTON_Y_GAP)
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

function LiteBagPanel_SetWidth(self, width)
    LiteBag_Print(format("Panel SetWidth %s %d", self:GetName(), width))
    local w = self.itemButtons[1]:GetWidth()
    local ncols = floor( (width - LEFT_OFFSET - RIGHT_OFFSET + BUTTON_X_GAP) / (w + BUTTON_X_GAP) )
    ncols = min(ncols, self.size)
    ncols = max(ncols, MIN_COLUMNS)
    LiteBag_SetPanelOption(self, "columns", ncols)
    LiteBagPanel_UpdateSizeAndLayout(self)
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
    LiteBag_Print("Panel OnLoad " .. self:GetName())
    self.size = 0
    self.itemButtons = { }
    self.bagFrames = { }
end

function LiteBagPanel_OnShow(self)
    LiteBag_Print("Panel OnShow " .. self:GetName())
    LiteBagPanel_UpdateBagSizes(self)
    LiteBagPanel_UpdateSizeAndLayout(self)
    LiteBagPanel_UpdateItemButtons(self)

    self:RegisterEvent("BAG_CLOSED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("ITEM_LOCK_CHANGED")
    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("INVENTORY_SEARCH_UPDATE")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
    self:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_CLOSED")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    if self.isBank then
        self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    end
end

function LiteBagPanel_OnHide(self)
    LiteBag_Print("Panel OnHide " .. self:GetName())
    -- Judging by the code in FrameXML/ContainerFrame.lua items are tagged
    -- by the server as "new" in some cases, and you're supposed to clear
    -- the new flag after you see it the first time.
    LiteBagPanel_ClearNewItems(self)
    LiteBagPanel_HideArtifactHelpBoxIfOwned(self)

    self:UnregisterEvent("BAG_CLOSED")
    self:UnregisterEvent("BAG_UPDATE")
    self:UnregisterEvent("ITEM_LOCK_CHANGED")
    self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
    self:UnregisterEvent("INVENTORY_SEARCH_UPDATE")
    self:UnregisterEvent("QUEST_ACCEPTED")
    self:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")
    self:UnregisterEvent("PLAYER_MONEY")
    self:UnregisterEvent("BAG_NEW_ITEMS_UPDATED")
    self:UnregisterEvent("BAG_SLOT_FLAGS_UPDATED")
    self:UnregisterEvent("MERCHANT_SHOW")
    self:UnregisterEvent("MERCHANT_CLOSED")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    if self.isBank then
        self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
    end
end

-- These events are only registered while the panel is shown, so we can call
-- the update functions without worrying that we don't need to.
--
-- Some events that fire a lot have specific code to just update the
-- bags or changes that they fire for (where possible).  Others are
-- rare enough it's OK to call LiteBagPanel_UpdateItemButtons to do everything.
function LiteBagPanel_OnEvent(self, event, ...)
    LiteBag_Print(format("Panel OnEvent %s %s", self:GetName(), event))

    if event == "PLAYER_LOGIN" then
        LiteBagPanel_UpdateBagSizes(self)
        return
    end

    if event == "MERCHANT_SHOW" or event == "MERCHANT_HIDE" then
        local bag = ...
        LiteBagPanel_UpdateQuality(self, bag)
        return
    end

    if event == "BAG_CLOSED" then
        -- BAG_CLOSED fires when you drag a bag out of a slot but for the
        -- bank GetContainerNumSlots doesn't return the updated size yet,
        -- so we have to wait until BAG_UPDATE_DELAYED fires.
        self:RegisterEvent("BAG_UPDATE_DELAYED")
        return
    end

    if event == "BAG_UPDATE_DELAYED" then
        self:UnregisterEvent("BAG_UPDATE_DELAYED")
        LiteBagPanel_UpdateBagSizes(self)
        -- FALLTHROUGH
    end

    if event == "PLAYER_MONEY" then
        -- The only way to notice we bought a bag button is to see that we
        -- spent money while the bank is open.
        LiteBagPanel_UpdateBagSizes(self)
        -- FALLTHROUGH
    end

    if event == "ITEM_LOCK_CHANGED" then
        local bag, slot = ...
        LiteBagPanel_UpdateLocked(self, bag)
        return
    end

    if event == "BAG_UPDATE_COOLDOWN" then
        local bag = ...
        LiteBagPanel_UpdateCooldowns(self, bag)
        return
    end

    if event == "QUEST_ACCEPTED" or event == "UNIT_QUEST_LOG_CHANGED" then
        LiteBagPanel_UpdateQuestTextures(self)
        return
    end

    if event == "INVENTORY_SEARCH_UPDATE" then
        LiteBagPanel_UpdateSearchResults(self)
        return
    end

    if event == "PLAYERBANKSLOTS_CHANGED" then
        local slot = ...
        if self.isBank and slot > NUM_BANKGENERIC_SLOTS then
            LiteBagPanel_UpdateBagSizes(self)
        end
    end

    -- Default action (some above fall through to do this as well).
    LiteBagPanel_UpdateItemButtons(self)
end
