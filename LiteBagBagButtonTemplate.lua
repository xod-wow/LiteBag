--[[----------------------------------------------------------------------------

  LiteBag/LiteBagBagButtonTemplate.lua

  Copyright 2013 Mike Battersby

----------------------------------------------------------------------------]]--

local BankContainers = { [BANK_CONTAINER]  = true }
do
    for i = 1,NUM_BANKBAGSLOTS do
        BankContainers[NUM_BAG_SLOTS+i] = true
    end
end

function LiteBagBagButton_Update(self)

    self.bagID = self:GetID()
    self.isBank = BankContainers[self:GetID()]

    if self.bagID == BACKPACK_CONTAINER then
        SetItemButtonTexture(self, "Interface\\Buttons\\Button-Backpack-Up")
        self.tooltipText = BACKPACK_TOOLTIP
        return
    elseif self.bagID == BANK_CONTAINER then
        SetItemButtonTexture(self, "Interface\\Buttons\\Button-Backpack-Up")
        self.tooltipText = "Bank"
        return
    end

    self.slotID = ContainerIDToInventoryID(self:GetID())

    local texture = _G[self:GetName().."IconTexture"]
    local textureName = GetInventoryItemTexture("player", self.slotID)

    local numBankSlots, bankFull = GetNumBankSlots()
    local buyBankSlot = numBankSlots + 4 + 1

    if self.bagID == buyBankSlot then
        self.canBuy = 1
    else
        self.canBuy = nil
    end

    if textureName then
        SetItemButtonTexture(self, textureName)
    elseif self.canBuy then
        SetItemButtonTexture(self, "Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab")
        self.tooltipText = BANK_BAG_PURCHASE
    else
        textureName = select(2, GetInventorySlotInfo("Bag0Slot"))
        SetItemButtonTexture(self, textureName)
    end

    if self.isBank and self.bagID > buyBankSlot then
        self:Disable()
    else
        self:Enable()
    end

end

function LiteBagBagButton_OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self:RegisterEvent("INVENTORY_SEARCH_UPDATE")
end

function LiteBagBagButton_OnEvent(self)
    if event == "INVENTORY_SEARCH_UPDATE" then
        if IsContainerFiltered(self.slotID) then
            self.searchOverlay:Show()
        else
            self.searchOverlay:Hide()
        end
    end
end

function LiteBagBagButton_OnEnter(self)

    LiteBagFrame_HighlightBagButtons(self:GetParent(), self:GetID())

    if self.bagID == BACKPACK_CONTAINER or self.bagID == BANK_CONTAINER then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local hasItem = GameTooltip:SetInventoryItem("player", self.slotID)
    if not hasItem then
        if self.canBuy then
            GameTooltip:SetText(BANK_BAG_PURCHASE)
        elseif self.bagID == BACKPACK_CONTAINER then        
            GameTooltip:SetText(BACKPACK_TOOLTIP)
        elseif self.isBank then
            GameTooltip:SetText(BANK_BAG)
        else
            GameTooltip:AddLine(BAGSLOT)
        end
    end
end

function LiteBagBagButton_OnLeave(self)
    LiteBagFrame_UnhighlightBagButtons(self:GetParent(), self:GetID())
    GameTooltip:Hide()
    ResetCursor()
end

function LiteBagBagButton_OnDrag(self)
    if self.bagID ~= BACKPACK_CONTAINER and self.bagID ~= BANK_CONTAINER then
        PickupBagFromSlot(self.slotID)
    end
end

function LiteBagBagButton_OnClick(self)
    if self.bagID == BACKPACK_CONTAINER then
        PutItemInBackpack()
    else
        PutItemInBag(self.slotID)
    end
end

