--[[----------------------------------------------------------------------------

  LiteBag/BagButton.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local BankContainers = { [BANK_CONTAINER]  = true }
do
    for i = 1,NUM_BANKBAGSLOTS do
        BankContainers[NUM_BAG_SLOTS+i] = true
    end
end

-- Copied from Interface/FrameXML/ContainerFrame.lua and then replaced with
-- LibDD calls. I've even left all their horrible ; so I can easily re-paste
-- it later.

local function FilterDropDown_Initialize(self, level)
	local frame = self:GetParent();
	local id = frame:GetID();
	
	if (id > NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
		return;
	end

	local info = LibDD:UIDropDownMenu_CreateInfo();	

	if (id > 0 and not IsInventoryItemProfessionBag("player", ContainerIDToInventoryID(id))) then -- The actual bank has ID -1, backpack has ID 0, we want to make sure we're looking at a regular or bank bag
		info.text = BAG_FILTER_ASSIGN_TO;
		info.isTitle = 1;
		info.notCheckable = 1;
		LibDD:UIDropDownMenu_AddButton(info);

		info.isTitle = nil;
		info.notCheckable = nil;
		info.tooltipWhileDisabled = 1;
		info.tooltipOnButton = 1;

		for i = LE_BAG_FILTER_FLAG_EQUIPMENT, NUM_LE_BAG_FILTER_FLAGS do
			if ( i ~= LE_BAG_FILTER_FLAG_JUNK ) then
				info.text = BAG_FILTER_LABELS[i];
				info.func = function(_, _, _, value)
					value = not value;
					if (id > NUM_BAG_SLOTS) then
						SetBankBagSlotFlag(id - NUM_BAG_SLOTS, i, value);
					else
						SetBagSlotFlag(id, i, value);
					end
					if (value) then
						frame.localFlag = i;
						frame.FilterIcon.Icon:SetAtlas(BAG_FILTER_ICONS[i]);
						frame.FilterIcon:Show();
					else
						frame.FilterIcon:Hide();
						frame.localFlag = -1;						
					end
				end;
				if (frame.localFlag) then
					info.checked = frame.localFlag == i;
				else
					if (id > NUM_BAG_SLOTS) then
						info.checked = GetBankBagSlotFlag(id - NUM_BAG_SLOTS, i);
					else
						info.checked = GetBagSlotFlag(id, i);
					end
				end
				info.disabled = nil;
				info.tooltipTitle = nil;
				LibDD:UIDropDownMenu_AddButton(info);
			end
		end
	end

	info.text = BAG_FILTER_CLEANUP;
	info.isTitle = 1;
	info.notCheckable = 1;
	LibDD:UIDropDownMenu_AddButton(info);

	info.isTitle = nil;
	info.notCheckable = nil;
	info.isNotRadio = true;
	info.disabled = nil;

	info.text = BAG_FILTER_IGNORE;
	info.func = function(_, _, _, value)
		if (id == -1) then
			SetBankAutosortDisabled(not value);
		elseif (id == 0) then
			SetBackpackAutosortDisabled(not value);
		elseif (id > NUM_BAG_SLOTS) then
			SetBankBagSlotFlag(id - NUM_BAG_SLOTS, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, not value);
		else
			SetBagSlotFlag(id, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, not value);
		end
	end;
	if (id == -1) then
		info.checked = GetBankAutosortDisabled();
	elseif (id == 0) then
		info.checked = GetBackpackAutosortDisabled();
	elseif (id > NUM_BAG_SLOTS) then
		info.checked = GetBankBagSlotFlag(id - NUM_BAG_SLOTS, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP);
	else
		info.checked = GetBagSlotFlag(id, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP);
	end
	LibDD:UIDropDownMenu_AddButton(info);
end

LiteBagBagButtonMixin = {}

function LiteBagBagButtonMixin:GetFilter()

    if self.bagID == BACKPACK_CONTAINER or self.bagID == BANK_CONTAINER then
        return
    end

    if IsInventoryItemProfessionBag('player', self.slotID) then
        return
    end

    for i = LE_BAG_FILTER_FLAG_EQUIPMENT, NUM_LE_BAG_FILTER_FLAGS do
        if self.isBank and GetBankBagSlotFlag(self.bagID - NUM_BAG_SLOTS, i) then
            return i
        elseif GetBagSlotFlag(self.bagID, i) then
            return i
        end
    end
end

function LiteBagBagButtonMixin:SetFilterIcon()

    local i = self:GetFilter()
    if i then
        self.FilterIcon:SetAtlas(BAG_FILTER_ICONS[i], true)
        self.FilterIcon:Show()
    else
        self.FilterIcon:Hide()
    end

end

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

    self:SetFilterIcon()

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
    LiteBagPanel_HighlightBagButtons(frame, self:GetID())

    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

    if self.bagID == BACKPACK_CONTAINER then
        GameTooltip:SetText(BACKPACK_TOOLTIP)
    elseif self.bagID == BANK_CONTAINER then
        GameTooltip:SetText(BANK_BAG)
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
        else
            local i = self:GetFilter()
            if i then
                GameTooltip:AddLine(BAG_FILTER_ASSIGNED_TO:format(BAG_FILTER_LABELS[i]))
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
        return
    end

    if self.purchaseCost then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        BankFrame.nextSlotCost = self.purchaseCost
        StaticPopup_Show('CONFIRM_BUY_BANK_SLOT')
        return
    end
end
