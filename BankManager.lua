--[[----------------------------------------------------------------------------

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

LB.BankManager = {}

--------------------------------------------------------------------------------

-- Update a single button
local function ItemButtonUpdateHook(itemButton)
    LB.CallHooks('LiteBagItemButton_Update', itemButton)
end


function LB.BankManager:GenerateItemSlotsForSelectedTab(frame)
    for itemButton in frame:EnumerateValidItems() do
        if not self.hookedButtons[itemButton] then
            hooksecurefunc(itemButton, 'Refresh', ItemButtonUpdateHook)
            self.hookedButtons[itemButton] = true
        end
    end
end

-- This fixes a Blizzard mistake where they failed to handle items not in cache
-- in BankPanelMixin the same way they do in ContainerFrameMixin. Items not
-- in cache don't get their quality borders set.

function LB.BankManager:RefreshBankPanel(frame)
    local cc = ContinuableContainer:Create()
    for itemButton in frame:EnumerateValidItems() do
        local item = Item:CreateFromItemLocation(itemButton:GetItemLocation())
        if not item:IsItemEmpty() then
            cc:AddContinuable(item)
        end
    end
    cc:ContinueOnLoad(function () frame:MarkDirty() end)
end

local hooks = { "RefreshBankPanel", "GenerateItemSlotsForSelectedTab", }

function LB.BankManager:Initialize()
    self.hookedButtons = {}
    for _, method in ipairs(hooks) do
        local hook = function (...) self[method](self, ...) end
        hooksecurefunc(BankPanel, method, hook)
    end
end

function LB.CallHooksOnBank()
    if BankFrame:IsShown() then
        for itemButton in BankPanel:EnumerateValidItems() do
            ItemButtonUpdateHook(itemButton)
        end
    end
end
