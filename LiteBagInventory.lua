--[[----------------------------------------------------------------------------

  LiteBag/LiteBagInventory.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local OPEN_EVENTS = {
    'BAG_OPEN',
    'BANKFRAME_OPENED',
}

-- Note BAG_CLOSED is not here, it fires when you drag bags into and out of
-- their slots so it's part of the regular events (and we don't close the
-- frame based on it).

local CLOSE_EVENTS = {
    'BANKFRAME_CLOSED',
}

function LiteBagInventory_OnLoad(self)
    LiteBagFrame_OnLoad(self)
    self:RegisterEvent('ADDON_LOADED')
end

function LiteBagInventory_Initialize(self)

    self:SetPortraitToAsset("Interface/Icons/Inv_misc_bag_08");

    local panel = CreateFrame('Frame', 'LiteBagInventoryPanel', self, 'LiteBagPanelTemplate')
    LiteBagPanel_Initialize(panel, INVENTORY_BAG_IDS)
    panel.defaultColumns = 8
    panel.canResize = true
    LiteBagFrame_AddPanel(self, panel, GetBagName(0))

    -- Close with ESC key
    tinsert(UISpecialFrames, self:GetName())

    -- Set up search / sort
    self.searchBox = BagItemSearchBox
    self.sortButton = BagItemAutoSortButton

    -- Frame open/close events for Inventory
    for _, event in ipairs(OPEN_EVENTS) do self:RegisterEvent(event) end
    for _, event in ipairs(CLOSE_EVENTS) do self:RegisterEvent(event) end
end

function LiteBagInventory_OnEvent(self, event, arg1, arg2, ...)
    if event == 'ADDON_LOADED' then
        if arg1 == 'LiteBag' then
            LiteBagInventory_Initialize(self)
        end
    elseif tContains(OPEN_EVENTS, event) then
        self:Show()
    elseif tContains(CLOSE_EVENTS, event) then
        self:Hide()
    end
end

function LiteBagInventory_OnShow(self, ...)
    self:SetTitle(GetBagName(0))
    LiteBagFrame_OnShow(self, ...)
    SetMainMenuBarButtons(true)
    LiteBagFrame_SetPosition(self)
end

function LiteBagInventory_OnHide(self, ...)
    LiteBagFrame_OnHide(self, ...)
    SetMainMenuBarButtons(false)
end
