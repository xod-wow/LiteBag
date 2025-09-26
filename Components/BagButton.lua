--[[----------------------------------------------------------------------------

  LiteBag/BagButton.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

LiteBagBagButtonMixin = {}

function LiteBagBagButtonMixin:Update()

    local bagID = self:GetID()

    if bagID == Enum.BagIndex.Backpack then
        SetItemButtonTexture(self, 'Interface\\Buttons\\Button-Backpack-Up')
        return
    end

    self.slotID = C_Container.ContainerIDToInventoryID(self:GetID())

    local textureName = GetInventoryItemTexture('player', self.slotID)

    if textureName then
        SetItemButtonTexture(self, textureName)
    else
        textureName = select(2, GetInventorySlotInfo('Bag0Slot'))
        SetItemButtonTexture(self, textureName)
    end
end

function LiteBagBagButtonMixin:OnLoad()
    self:RegisterForDrag('LeftButton')
    self:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    self:RegisterEvent('INVENTORY_SEARCH_UPDATE')
end

function LiteBagBagButtonMixin:OnShow()
    self:RegisterEvent('BAG_UPDATE_DELAYED')
end

function LiteBagBagButtonMixin:OnHide()
    self:UnregisterEvent('BAG_UPDATE_DELAYED')
end

function LiteBagBagButtonMixin:OnEvent(event, ...)
    if event == 'INVENTORY_SEARCH_UPDATE' then
        local bagID = self:GetID()
        if C_Container.IsContainerFiltered(bagID) then
            self.searchOverlay:Show()
        else
            self.searchOverlay:Hide()
        end
    elseif event == 'BAG_UPDATE_DELAYED' then
        self:Update()
    end
end

-- Used for the callback that does the highlighting
function LiteBagBagButtonMixin:GetIsBarExpanded()
    return true
end

function LiteBagBagButtonMixin:GetBagID()
    return self:GetID()
end

function LiteBagBagButtonMixin:OnEnter()
    EventRegistry:TriggerEvent("BagSlot.OnEnter", self)

    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

    if self:GetID() == Enum.BagIndex.Backpack then
        GameTooltip_SetTitle(GameTooltip, BACKPACK_TOOLTIP)
        GameTooltip:AddLine(SETTINGS)
    else
        local hasItem = GetInventoryItemTexture('player', self.slotID) ~= nil
        if hasItem then
            GameTooltip:SetInventoryItem('player', self.slotID)
        else
            GameTooltip_SetTitle(GameTooltip, EQUIP_CONTAINER)
        end
    end
    GameTooltip:Show()
end

function LiteBagBagButtonMixin:OnLeave()
    GameTooltip:Hide()
    ResetCursor()
    EventRegistry:TriggerEvent("BagSlot.OnLeave", self)
end

function LiteBagBagButtonMixin:OnDragStart()
    local bagID = self:GetID()
    if bagID ~= Enum.BagIndex.Backpack then
        PickupBagFromSlot(self.slotID)
    end
end

-- luacheck: ignore 212/owner
local function GenerateMenu(owner, rootDescription)
    rootDescription:CreateTitle("LiteBag")
    rootDescription:CreateButton(SETTINGS, LB.OpenOptions)
    rootDescription:CreateCheckbox(LOCK_FRAME,
        function ()
            return LB.db and LB.GetTypeOption('BACKPACK', 'locked')
        end,
        function ()
            local isLocked = LB.GetTypeOption('BACKPACK', 'locked')
            LB.SetTypeOption('BACKPACK', 'locked', not isLocked)
        end
    )
end

function LiteBagBagButtonMixin:OnClick()
    local bagID = self:GetID()
    if CursorHasItem() then
        if bagID == Enum.BagIndex.Backpack then
            PutItemInBackpack()
        else
            PutItemInBag(self.slotID)
        end
    elseif bagID == Enum.BagIndex.Backpack then
        MenuUtil.CreateContextMenu(self, GenerateMenu)
    elseif bagID ~= Enum.BagIndex.Backpack then
        PickupBagFromSlot(self.slotID)
    end
end
