--[[----------------------------------------------------------------------------

  LiteBag/Core.lua

  Copyright 2013 Mike attersby

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

function LB.PatchBankFrame()
end
