--[[----------------------------------------------------------------------------

  LiteBag/BagButton.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local BankContainers = { [Enum.BagIndex.Bank]  = true }
do
    for i = 1,NUM_BANKBAGSLOTS do
        BankContainers[NUM_TOTAL_EQUIPPED_BAG_SLOTS+i] = true
    end
end

LiteBagBagButtonMixin = {}

function LiteBagBagButtonMixin:Update()

    local bagID = self:GetID()
    self.isBank = BankContainers[self:GetID()]

    if bagID == Enum.BagIndex.Backpack then
        SetItemButtonTexture(self, 'Interface\\Buttons\\Button-Backpack-Up')
        return
    elseif bagID == Enum.BagIndex.Bank then
        SetItemButtonTexture(self, 'Interface\\Buttons\\Button-Backpack-Up')
        return
    end

    self.slotID = C_Container.ContainerIDToInventoryID(self:GetID())

    local textureName = GetInventoryItemTexture('player', self.slotID)

    local numBankSlots = GetNumBankSlots()
    local buyBankSlot = numBankSlots + NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1

    if bagID == buyBankSlot then
        self.purchaseCost = GetBankSlotCost()
    else
        self.purchaseCost = nil
    end

    if textureName then
        SetItemButtonTexture(self, textureName)
    elseif self.purchaseCost then
        SetItemButtonTexture(self, 'Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab')
        local icon = self:GetItemButtonIconTexture()
        icon:SetTexCoord(0.1, 1, 0.1, 1)
    else
        textureName = select(2, GetInventorySlotInfo('Bag0Slot'))
        SetItemButtonTexture(self, textureName)
    end

    if self.isBank and bagID > buyBankSlot then
        SetItemButtonTextureVertexColor(self, 1, 0, 0)
    else
        SetItemButtonTextureVertexColor(self, 1, 1, 1)
    end

    local hide = LB.GetGlobalOption('hideBagIDs')
    if hide[bagID] then
        self:GetNormalTexture():SetDesaturated(true)
        self:GetNormalTexture():SetAlpha(0.5)
        self.icon:SetDesaturated(true)
        self.icon:SetAlpha(0.5)
    else
        self:GetNormalTexture():SetDesaturated(false)
        self:GetNormalTexture():SetAlpha(1)
        self.icon:SetDesaturated(false)
        self.icon:SetAlpha(1)
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
    LB.EventDebug(self, event, ...)
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
    elseif self:GetID() == Enum.BagIndex.Bank then
        GameTooltip_SetTitle(GameTooltip, BANK)
    else
        local hasItem = GameTooltip:SetInventoryItem('player', self.slotID)
        if not hasItem then
            local bagID = self:GetID()
            GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
            if self.purchaseCost then
                GameTooltip:ClearLines()
                GameTooltip_SetTitle(GameTooltip, BANK_BAG_PURCHASE)
                GameTooltip:AddDoubleLine(COSTS_LABEL, GetCoinTextureString(self.purchaseCost))
            elseif self:GetID() == Enum.BagIndex.ReagentBag then
                GameTooltip_SetTitle(GameTooltip, EQUIP_CONTAINER_REAGENT)
            elseif self.isBank and bagID > GetNumBankSlots() + NUM_TOTAL_EQUIPPED_BAG_SLOTS then
                GameTooltip_SetTitle(GameTooltip, BANK_BAG_PURCHASE)
            elseif self.isBank then
                GameTooltip_SetTitle(GameTooltip, BANK_BAG)
            else
                GameTooltip_SetTitle(GameTooltip, EQUIP_CONTAINER)
            end
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
    if bagID ~= Enum.BagIndex.Backpack and bagID ~= Enum.BagIndex.Bank then
        PickupBagFromSlot(self.slotID)
    end
end

function LiteBagBagButtonMixin:OnClick()
    local bagID = self:GetID()
    if CursorHasItem() then
        if bagID == Enum.BagIndex.Backpack then
            PutItemInBackpack()
        elseif not self.purchaseCost then
            PutItemInBag(self.slotID)
        end
    elseif self.purchaseCost then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        BankFrame.nextSlotCost = self.purchaseCost
        StaticPopup_Show('CONFIRM_BUY_BANK_SLOT')
    elseif IsShiftKeyDown() then
        local allow = LB.GetGlobalOption('allowHideBagIDs')
        if allow[bagID] then
            local hide = LB.GetGlobalOption('hideBagIDs')
            hide[bagID] = not hide[bagID] or nil
            LB.SetGlobalOption('hideBagIDs', hide)
        end
    elseif bagID ~= Enum.BagIndex.Backpack and bagID ~= Enum.BagIndex.Bank then
        PickupBagFromSlot(self.slotID)
    end
end

function LiteBagBagButtonMixin:SetBagID()
    -- Total unnecessary taint paranoia
end
