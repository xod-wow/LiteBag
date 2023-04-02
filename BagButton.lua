--[[----------------------------------------------------------------------------

  LiteBag/BagButton.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local BankContainers = { [BANK_CONTAINER]  = true }
do
    for i = 1,NUM_BANKBAGSLOTS do
        BankContainers[NUM_BAG_SLOTS+i] = true
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
    elseif self.bagID == KEYRING_CONTAINER then
        SetItemButtonTexture(self, 'Interface\\ContainerFrame\\KeyRing-Bag-Icon')
        return
    end

    self.slotID = C_Container.ContainerIDToInventoryID(self:GetID())

    local textureName = GetInventoryItemTexture('player', self.slotID)

    local numBankSlots, bankFull = GetNumBankSlots()
    local buyBankSlot = numBankSlots + ITEM_INVENTORY_BANK_BAG_OFFSET + 1

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
end

function LiteBagBagButtonMixin:OnEnter()

    local frame = self:GetParent()
    LiteBagPanel_HighlightBagButtons(frame, self:GetID())

    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

    if self.bagID == BACKPACK_CONTAINER then
        GameTooltip:SetText(BACKPACK_TOOLTIP)
    elseif self.bagID == BANK_CONTAINER then
        GameTooltip:SetText(BANK_BAG)
    elseif self.bagID == KEYRING_CONTAINER then
        GameTooltip:SetText(KEYRING)
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
    LiteBagPanel_UnhighlightBagButtons(frame, self:GetID())
    GameTooltip:Hide()
    ResetCursor()
end

function LiteBagBagButtonMixin:OnDrag()
    if self.bagID ~= BACKPACK_CONTAINER
        and self.bagID ~= BANK_CONTAINER
        and self.bagID ~= KEYRING_CONTAINER then
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
        return
    end

    if self.purchaseCost then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        BankFrame.nextSlotCost = self.purchaseCost
        StaticPopup_Show('CONFIRM_BUY_BANK_SLOT')
        return
    end
end
