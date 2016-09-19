--[[----------------------------------------------------------------------------

  LiteBag/Frame.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local MIN_COLUMNS = 8

function LiteBagFrame_IsMyBag(self, id)
    -- For some reason BAG_UPDATE_COOLDOWN sometimes doesn't have a bag
    -- argument. Since we can't tell if it's us we better assume it is.
    if not id then return true end
    return tContains(self.bagIDS, id)
end

-- SavedVariables aren't available at OnLoad time, only once ADDON_LOADED fires.
function LiteBagFrame_Initialize(self)

    self.items.ncols = LiteBag_GetFrameOption(self, "columns")
                        or self.default_columns
                        or MIN_COLUMNS

    self.items.ncols = max(self.columns, MIN_COLUMNS)

end

function LiteBagFrame_OnLoad(self)

    if not self.bagIDs then
        -- Error!  Needs self.bagIDs set before calling!
        --  <Frame ... inherits="LiteBagFrameTemplate">
        --      <Scripts>
        --          <OnLoad>
        --              self.bagIDs = { 0, 1, 2, 3 }
        --              LiteBagFrame_OnLoad(self)
        return
    end

    LiteBagPanel_Initialize(self.items, self.bagIDs)

    -- We hook ADDON_LOADED to do an initial layout of the frame, as we
    -- will know how big the bags are at that point and still not be
    -- InCombatLockown().

    self:RegisterEvent("ADDON_LOADED")
end

-- These events are only registered while the frames are shown, so we can call
-- the update functions without worrying that we don't need to.
--
-- Some events that fire a lot have specific code to just update the
-- bags or changes that they fire for (where possible).  Others are
-- rare enough it's OK to call LiteBagFrame_Update to do everything.
function LiteBagFrame_OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        LiteBagFrame_Initialize(self)
        LiteBagFrame_Update(self)
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_HIDE" then
        LiteBagPanel_UpdateQuality(self.items)
        local bag = ...
        LiteBagPanel_UpdateQuality(self, bag)
    elseif event == "BAG_UPDATE" or event == "BAG_NEW_ITEMS_UPDATED" then
        local bag = ...
        LiteBagPanel_Update(self.items, bag)
    elseif event == "BAG_CLOSED" then
        -- BAG_CLOSED fires when you drag a bag out of a slot but for the
        -- bank GetContainerNumSlots doesn't return the updated size yet,
        -- so we have to wait until BAG_UPDATE_DELAYED fires.
        local bag = ...
        self:RegisterEvent("BAG_UPDATE_DELAYED")
    elseif event == "BAG_UPDATE_DELAYED" then
        self:UnregisterEvent("BAG_UPDATE_DELAYED")
        LiteBagPanel_Update(self.items)
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        LiteBagPanel_Update(self.items)
    elseif event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
        local slot = ...
        LiteBagPanel_Update(self.items)
    elseif event == "PLAYER_MONEY" then
        -- The only way to notice we bought a bag button is to see that we
        -- spent money while the bank is open.
        LiteBagPanel_Update(self.items)
    elseif event == "ITEM_LOCK_CHANGED" then
        local bag, slot = ...
        LiteBagPanel_UpdateLocked(self.items, bag)
    elseif event == "BAG_UPDATE_COOLDOWN" then
        local bag = ...
        LiteBagPanel_UpdateCooldowns(self.items, bag)
    elseif event == "QUEST_ACCEPTED" or event == "UNIT_QUEST_LOG_CHANGED" then
        LiteBagPanel_UpdateQuestTextures(self.items)
    elseif event == "INVENTORY_SEARCH_UPDATE" then
        LiteBagPanel_UpdateSearchResults(self.items)
    elseif event == "DISPLAY_SIZE_CHANGED" then
        self:SetSize(LiteBagFrame_CalcSize(self, self.columns))
        LiteBagPanel_Layout(self.items)
    else
        LiteBagPanel_Update(self.items)
    end
end

local function GetDistanceFromBackpackDefault(self)
    local defaultX = UIParent:GetRight() - CONTAINER_OFFSET_X
    local defaultY = UIParent:GetBottom() + CONTAINER_OFFSET_Y
    local selfX = self:GetRight()
    local selfY = self:GetBottom()
    return sqrt((defaultX-selfX)^2 + (defaultY-selfY)^2)
end

-- CONTAINER_OFFSET_* are globals that are updated by the Blizzard
-- code depending on which (default) action bars are shown.

function LiteBagFrame_SetPosition(self)
    if self:IsUserPlaced() then return end
    self:ClearAllPoints()
    self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y)
end

function LiteBagFrame_StartMoving(self)
    self:StartMoving()
end

function LiteBagFrame_StopMoving(self)
    self:StopMovingOrSizing()

    -- Snap back into place
    if self.isBackpack and GetDistanceFromBackpackDefault(self) < 64 then
        self:SetUserPlaced(false)
        LiteBagFrame_SetPosition(self)
    end
end

function LiteBagFrame_StopSizing(self)
    self:StopMovingOrSizing()
    local w, h = LiteBagFrame_CalcSize(self, self.columns)
    self:SetSize(w, h)
    LiteBag_SetFrameOption(self, "columns", self.columns)
end

function LiteBagFrame_OnSizeChanged(self, w, h)
    if not self.sizing then return end
    self.items.ncolumns = LiteBagFrame_CalcCols(self, w)
    local w, h = LiteBagFrame_CalcSize(self, self.columns)
    self:SetHeight(h)
    LiteBagPanel_Layout(self.items)
end

function LiteBagFrame_OnHide(self)
    self:UnregisterEvent("BAG_CLOSED")
    self:UnregisterEvent("BAG_UPDATE")
    self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:UnregisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
    self:UnregisterEvent("ITEM_LOCK_CHANGED")
    self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
    self:UnregisterEvent("DISPLAY_SIZE_CHANGED")
    self:UnregisterEvent("INVENTORY_SEARCH_UPDATE")
    self:UnregisterEvent("QUEST_ACCEPTED")
    self:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")
    self:UnregisterEvent("PLAYER_MONEY")
    self:UnregisterEvent("BAG_NEW_ITEMS_UPDATED")
    self:UnregisterEvent("BAG_SLOT_FLAGS_UPDATED")
    self:UnregisterEvent("MERCHANT_SHOW")
    self:UnregisterEvent("MERCHANT_CLOSED")

    PlaySound("igBackPackClose")
end

function LiteBagFrame_OnShow(self)
    self:RegisterEvent("BAG_CLOSED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
    self:RegisterEvent("ITEM_LOCK_CHANGED")
    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("DISPLAY_SIZE_CHANGED")
    self:RegisterEvent("INVENTORY_SEARCH_UPDATE")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
    self:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_CLOSED")

    LiteBagFrame_AttachSearchBox(self)
    LiteBagFrame_Update(self)
    LiteBagTokensFrame_Update(self)

    PlaySound("igBackPackOpen")
end

function LiteBagFrame_AttachSearchBox(self)
    self.searchBox:SetParent(self)
    self.searchBox:ClearAllPoints()
    self.searchBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -38, -35)
    self.searchBox.anchorBag = self
    self.searchBox:Show()

    self.sortButton:SetParent(self)
    self.sortButton:ClearAllPoints()
    self.sortButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -7, -32)
    self.sortButton.anchorBag = self
    self.sortButton:Show()
end

function LiteBagFrame_UpdateBankItemButtons(panel)
    for i = 1, panel.size do
        BankFrameItemButton_Update(panel["Item"..i])
    end
end

function LiteBagFrame_Update(self)
    if not self:IsShown() then return end
    LiteBagPanel_UpdateItemButtons(self.items)
end
