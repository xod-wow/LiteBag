--[[----------------------------------------------------------------------------

  LiteBag/InventoryFrame.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local OPEN_EVENTS = {
    "BAG_OPEN",
    "BANKFRAME_OPENED",
    "OBLITERUM_FORGE_SHOW",
}

-- Note BAG_CLOSED is not here, it fires when you drag bags into and out of
-- their slots so it's part of the regular events (and we don't close the
-- frame based on it).

local CLOSE_EVENTS = {
    "BANKFRAME_CLOSED",
    "OBLITERUM_FORGE_CLOSE",
}

-- This updates the highlights for the bag open/closed buttons that are
-- part of the MainMenuBar at the bottom in the default Blizzard interface.

local function SetMainMenuBarButtons(self, checked)
    MainMenuBarBackpackButton:SetChecked(checked)
    CharacterBag0Slot:SetChecked(checked)
    CharacterBag1Slot:SetChecked(checked)
    CharacterBag2Slot:SetChecked(checked)
    CharacterBag3Slot:SetChecked(checked)
end

function LiteBagInventory_OnLoad(self)
    self.bagIDs = { 0, 1, 2, 3, 4 }
    self.default_columns = 8
    self.isBackpack = true

    LiteBagFrame_OnLoad(self)

    -- Close with ESC key
    tinsert(UISpecialFrames, self:GetName())

    -- Set up search / sort
    self.searchBox = BagItemSearchBox
    self.sortButton = BagItemAutoSortButton

    -- Select the right search box 
    self.searchBox = BagItemSearchBox
    self.sortButton = BagItemAutoSortButton

    -- Frame open/close events for Inventory
    for _, event in ipairs(OPEN_EVENTS) do self:RegisterEvent(event) end
    for _, event in ipairs(CLOSE_EVENTS) do self:RegisterEvent(event) end
end

function LiteBagInventory_OnEvent(self, event, ...)
    if tContains(OPEN_EVENTS, event) then
        self:Show()
    elseif tContains(CLOSE_EVENTS, event) then
        self:Hide()
    else
        LiteBagFrame_OnEvent(self, event, ...)
    end

end

function LiteBagInventory_OnShow(self, ...)
    self.TitleText:SetText(GetBagName(self.bagIDs[1]))
    self.portrait:SetTexture("Interface\\MERCHANTFRAME\\UI-BuyBack-Icon")
    SetMainMenuBarButtons(true)
    LiteBagFrame_SetPosition(self)
    LiteBagFrame_OnShow(self, ...)
end

function LiteBagInventory_OnHide(self, ...)
    SetMainMenuBarButtons(false)
    LiteBagFrame_OnShow(self, ...)
end
