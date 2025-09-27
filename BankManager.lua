--[[----------------------------------------------------------------------------

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...


--[[------------------------------------------------------------------------]]--

-- Modify the tabs on the BankPanel to accept drag/drop to move items.

LB.BankTabManager = {}

function LB.BankTabManager:AcceptItem(tabFrame, isClick)
    if CursorHasItem() and not InCombatLockdown() then
        local bagID = tabFrame.tabData.ID
        local freeSlots = C_Container.GetContainerFreeSlots(bagID)
        if freeSlots and #freeSlots > 0 then
            -- "Picking Up" the destination will put the item there
            C_Container.PickupContainerItem(bagID, freeSlots[1])
            if isClick then
                self.restoreTabScript = true
                tabFrame:SetScript('OnClick', nil)
            end
        end
    end
end

function LB.BankTabManager:RestoreScript(tabFrame)
    if self.restoreTabScript then
        tabFrame:SetScript('OnClick', BankPanelTabMixin.OnClick)
        self.restoreTabScript = nil
    end
end

function LB.BankTabManager:InitializeTab(tabFrame)
    tabFrame:RegisterForDrag()
    tabFrame:SetScript('OnReceiveDrag', function (tabFrame) self:AcceptItem(tabFrame) end)
    tabFrame:SetScript('PreClick', function (tabFrame) self:AcceptItem(tabFrame, true) end)
    tabFrame:SetScript('PostClick', function (tabFrame) self:RestoreScript(tabFrame) end)
end

--[[------------------------------------------------------------------------]]--

LB.BankManager = {}

-- Call hooks on a single item button
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

function LB.BankManager:RefreshBankTabs(frame)
    for tabFrame in frame.bankTabPool:EnumerateActive() do
        LB.BankTabManager:InitializeTab(tabFrame)
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

local hooks = { "RefreshBankTabs", "RefreshBankPanel", "GenerateItemSlotsForSelectedTab", }

function LB.BankManager:Initialize()
    self.hookedButtons = {}
    for _, method in ipairs(hooks) do
        local hook = function (...) self[method](self, ...) end
        hooksecurefunc(BankPanel, method, hook)
    end
end

function LB.BankManager:CallHooks()
    if BankFrame:IsShown() then
        for itemButton in BankPanel:EnumerateValidItems() do
            ItemButtonUpdateHook(itemButton)
        end
    end
end
