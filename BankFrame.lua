--[[----------------------------------------------------------------------------

  LiteBag/Core.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local mixin = {}

--[[
function mixin:GenerateItemSlotsForSelectedTab()
    self.itemButtonPool:ReleaseAll()

    if not self.selectedTabID or self.selectedTabID == PURCHASE_TAB_ID then
        return
    end

    local numRows = 7
    local numSubColumns = 2
    local lastColumnStarterButton
    local lastCreatedButton
    local currentColumn = 1
    for containerSlotID = 1, C_Container.GetContainerNumSlots(self.selectedTabID) do
        local button = self.itemButtonPool:Acquire()

        local isFirstButton = containerSlotID == 1
        local needNewColumn = (containerSlotID % numRows) == 1
        if isFirstButton then
            local xOffset, yOffset = 26, -63
            button:SetPoint("TOPLEFT", self, "TOPLEFT", currentColumn * xOffset, yOffset)
            lastColumnStarterButton = button
        elseif needNewColumn then
            currentColumn = currentColumn + 1

            local xOffset, yOffset = 5, 0
            -- We reached the last subcolumn, time to add space for a new "big" column
            local startNewBigColumn = (currentColumn % numSubColumns == 1)
            if startNewBigColumn then
                xOffset = 10
            end
            button:SetPoint("TOPLEFT", lastColumnStarterButton, "TOPRIGHT", xOffset, yOffset)
            lastColumnStarterButton = button
        else
            local xOffset, yOffset = 0, -5
            button:SetPoint("TOPLEFT", lastCreatedButton, "BOTTOMLEFT", xOffset, yOffset)
        end

        button:Init(self.bankType, self.selectedTabID, containerSlotID)
        button:Show()

        lastCreatedButton = button
    end
end
]]

--------------------------------------------------------------------------------

-- Update a single button
local function ItemButtonUpdateHook(itemButton)
    LB.CallHooks('LiteBagItemButton_Update', itemButton)
end

local hookedButtons = {}

local function HookContainerItemButtons(self)
    for itemButton in self:EnumerateValidItems() do
        if not hookedButtons[itemButton] then
            hooksecurefunc(itemButton, 'Refresh', ItemButtonUpdateHook)
            hookedButtons[itemButton] = true
        end
    end
end

-- This fixes a Blizzard mistake where they failed to handle items not in cache
-- in BankPanelMixin the same way they do in ContainerFrameMixin. Items not
-- in cache don't get their quality borders set.

local function FixBlizzardCacheBugHook(self)
    local cc = ContinuableContainer:Create()
    for itemButton in self:EnumerateValidItems() do
        local item = Item:CreateFromItemLocation(itemButton:GetItemLocation())
        if not item:IsItemEmpty() then
            cc:AddContinuable(item)
        end
    end
    cc:ContinueOnLoad(function () self:MarkDirty() end)
end

function LB.PatchBank()
    hooksecurefunc(BankPanel, 'GenerateItemSlotsForSelectedTab', HookContainerItemButtons)
    hooksecurefunc(BankPanel, 'RefreshBankPanel', FixBlizzardCacheBugHook)
end
