--[[----------------------------------------------------------------------------

  LiteBag/ItemButton.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

LiteBagItemButtonMixin = {}

function LiteBagItemButtonMixin:OnLoad()
    ContainerFrameItemButtonMixin.OnLoad(self)
    self.UpdateTooltip = self.OnEnter
    -- This is for BankFrameItemButton_OnEnter
    self.GetInventorySlot = ButtonInventorySlot
end

-- The OnUpdate part of ContainerFrameItemButtonMixin taints everything when
-- it calls GetBagID() on these item buttons, so we have to copy the whole lot
-- minus whatever the crap at the end is. This is a pure cut-and-paste-and-hack
-- so I can just re-paste and diff

function LiteBagItemButtonMixin:OnUpdate(...)
        GameTooltip:SetOwner(self, "ANCHOR_NONE");

        C_NewItems.RemoveNewItem(self:GetBagID(), self:GetID());

        self.NewItemTexture:Hide();
        self.BattlepayItemTexture:Hide();

        if ( self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying() ) then
                self.flashAnim:Stop();
                self.newitemglowAnim:Stop();
        end

        local showSell = nil;
        local hasCooldown, repairCost, speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetBagItem(self:GetBagID(), self:GetID());
        if ( speciesID and speciesID > 0 ) then
                ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip); -- Battle pet tooltip uses the GameTooltip's anchor
                BattlePetToolTip_Show(speciesID, level, breedQuality, maxHealth, power, speed, name);
                return;
        else
                if ( BattlePetTooltip ) then
                        BattlePetTooltip:Hide();
                end
        end

        ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip);

        if ( IsModifiedClick("COMPAREITEMS") or GetCVarBool("alwaysCompareItems") ) then
                GameTooltip_ShowCompareItem(GameTooltip);
        end

        if ( InRepairMode() and (repairCost and repairCost > 0) ) then
                GameTooltip:AddLine(REPAIR_COST, nil, nil, nil, true);
                SetTooltipMoney(GameTooltip, repairCost);
                GameTooltip:Show();
        elseif ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 ) then
                showSell = 1;
        end

        if ( not SpellIsTargeting() ) then
                if ( IsModifiedClick("DRESSUP") and self:HasItem() ) then
                        ShowInspectCursor();
                elseif ( showSell ) then
                        ShowContainerSellCursor(self:GetBagID(), self:GetID());
                elseif ( self:IsReadable() ) then
                        ShowInspectCursor();
                else
                        ResetCursor();
                end
        end

--[[
        if ( not GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME) ) then
                local itemLocation = ItemLocation:CreateFromBagAndSlot(self:GetBagID(), self:GetID());
                if ( itemLocation and itemLocation:IsValid() and C_PlayerInfo.CanPlayerUseMountEquipment() and (not CollectionsJournal or not CollectionsJournal:IsShown()) ) then
                        local tabIndex = 1;
                        CollectionsMicroButton_SetAlertShown(tabIndex);
                end
        end
]]
end

function LiteBagItemButtonMixin:OnEnter(...)
    local bag = self:GetParent():GetID()
    if bag == BANK_CONTAINER then
        BankFrameItemButton_OnEnter(self, ...)
    else
        ContainerFrameItemButtonMixin.OnEnter(self, ...)
    end
end

--[[
/run LBI:GenerateFrame()
/run SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME, false)
/dump GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME)
]]

