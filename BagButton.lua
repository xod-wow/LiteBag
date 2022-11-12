--[[----------------------------------------------------------------------------

  LiteBag/BagButton.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local BankContainers = { [BANK_CONTAINER]  = true }
do
    for i = 1,NUM_BANKBAGSLOTS do
        BankContainers[NUM_TOTAL_EQUIPPED_BAG_SLOTS+i] = true
    end
end

LiteBagBagButtonMixin = {}

function LiteBagBagButtonMixin:Update()

    self.bagID = self:GetID()
    self.isBank = BankContainers[self:GetID()]

    if self.bagID == BACKPACK_CONTAINER then
        SetItemButtonTexture(self, 'Interface\\Buttons\\Button-Backpack-Up')
        return
    elseif self.bagID == BANK_CONTAINER then
        SetItemButtonTexture(self, 'Interface\\Buttons\\Button-Backpack-Up')
        return
    end

    self.slotID = ContainerIDToInventoryID(self:GetID())

    local textureName = GetInventoryItemTexture('player', self.slotID)

    local numBankSlots, bankFull = GetNumBankSlots()
    local buyBankSlot = numBankSlots + NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1

    if self.bagID == buyBankSlot then
        self.purchaseCost = GetBankSlotCost()
    else
        self.purchaseCost = nil
    end

    if textureName then
        SetItemButtonTexture(self, textureName)
    elseif self.purchaseCost then
        SetItemButtonTexture(self, 'Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab')
    else
        textureName = select(2, GetInventorySlotInfo('Bag0Slot'))
        SetItemButtonTexture(self, textureName)
    end

    if self.isBank and self.bagID > buyBankSlot then
        SetItemButtonTextureVertexColor(self, 1, 0, 0)
    else
        SetItemButtonTextureVertexColor(self, 1, 1, 1)
    end

end

function LiteBagBagButtonMixin:OnLoad()
    self:RegisterForDrag('LeftButton')
    self:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

    if WOW_PROJECT_ID == 1 then
        self:RegisterEvent('INVENTORY_SEARCH_UPDATE')
    end
end

function LiteBagBagButtonMixin:OnEvent(event, ...)
    if event == 'INVENTORY_SEARCH_UPDATE' then
        if IsContainerFiltered(self.bagID) then
            self.searchOverlay:Show()
        else
            self.searchOverlay:Hide()
        end
    end
end

function LiteBagBagButtonMixin:OnEnter()

    local frame = self:GetParent()
    frame:SetItemsMatchingBagHighlighted(self:GetID(), true)

    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

    if self:GetID() == BACKPACK_CONTAINER then
        GameTooltip:SetText(BACKPACK_TOOLTIP)
    elseif self:GetID() == BANK_CONTAINER then
        GameTooltip:SetText(BANK)
    else
        local hasItem = GameTooltip:SetInventoryItem('player', self.slotID)
        if not hasItem then
            if self.purchaseCost then
                GameTooltip:ClearLines()
                GameTooltip:AddLine(BANK_BAG_PURCHASE)
                GameTooltip:AddDoubleLine(COSTS_LABEL, GetCoinTextureString(self.purchaseCost))
            elseif self.isBank and self.bagID > GetNumBankSlots() + 4 then
                GameTooltip:SetText(BANK_BAG_PURCHASE)
            elseif self.isBank then
                GameTooltip:SetText(BANK_BAG)
            else
                GameTooltip:SetText(BAGSLOT)
            end
        end
    end
    GameTooltip:Show()
end

function LiteBagBagButtonMixin:OnLeave()
    local frame = self:GetParent()
    frame:SetItemsMatchingBagHighlighted(self:GetID(), false)
    GameTooltip:Hide()
    ResetCursor()
end

function LiteBagBagButtonMixin:OnDragStart()
    if self.bagID ~= BACKPACK_CONTAINER and self.bagID ~= BANK_CONTAINER then
        PickupBagFromSlot(self.slotID)
    end
end

function LiteBagBagButtonMixin:OnClick()
    if CursorHasItem() then
        if self.bagID == BACKPACK_CONTAINER then
            PutItemInBackpack()
        elseif not self.purchaseCost then
            PutItemInBag(self.slotID)
        end
    elseif self.purchaseCost then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        BankFrame.nextSlotCost = self.purchaseCost
        StaticPopup_Show('CONFIRM_BUY_BANK_SLOT')
    elseif self.bagID ~= BACKPACK_CONTAINER and self.bagID ~= BANK_CONTAINER then
        PickupBagFromSlot(self.slotID)
    end
end
