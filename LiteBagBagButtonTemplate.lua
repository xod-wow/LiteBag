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
    self.slotID = ContainerIDToInventoryID(self:GetID())
    self.isBank = BankContainers[self:GetID()]

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
    elseif self.bagID == BACKPACK_CONTAINER then        
        SetItemButtonTexture(self, "Interface\\Buttons\\Button-Backpack-Up")
        self.tooltipText = BACKPACK_TOOLTIP
    elseif self.canBuy then
        SetItemButtonTexture(self, "Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab")
        self.tooltipText = BANK_BAG_PURCHASE
    else
        textureName = select(2, GetInventorySlotInfo("Bag0Slot"))
        SetItemButtonTexture(self, textureName)
    end

    if self.isBank and self.bagID > buyBagSlot then
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
    LiteBagFrame_HighlightBagButtons(self:GetParent(), self:GetID())
end

function LiteBagBagButton_OnLeave(self)
    GameTooltip:Hide()
    ResetCursor()
    LiteBagFrame_UnhighlightBagButtons(self:GetParent(), self:GetID())
end

function LiteBagBagButton_OnDrag(self)
    PickupBagFromSlot(self.slotID)
end

function LiteBagBagButton_OnClick(self)
    PutItemInBag(self.slotID)
end

