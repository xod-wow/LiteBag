--[[------------------------------------------------------------------------------

  LiteBag/LiteBagItemButtonTemplate.lua

  Copyright 2013 Mike Battersby

------------------------------------------------------------------------------]]--

function LiteBagItemButton_UpdateItem(self)

    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local texture, count, _, _, readable = GetContainerItemInfo(bag, slot)

    SetItemButtonTexture(self, texture)
    SetItemButtonCount(self, count)

    self.readable = readable

    if texture then
        self.hasItem = 1
    else
        self.hasItem = nil
    end

    if self == tooltipOwner then
        LiteBagItemButton_UpdateTooltip(self)
    end

end

function LiteBagItemButton_UpdateLocked(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local locked = select(3, GetContainerItemInfo(bag, slot))
    SetItemButtonDesaturated(self, locked)
end

function LiteBagItemButton_UpdateQuestTexture(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local isQuestItem, questId, isActive = GetContainerItemQuestInfo(bag, slot)
    local quality, _, _, link = select(4, GetContainerItemInfo(bag, slot))
    if link and quality < 0 then
        quality = select(3, GetItemInfo(link))
    end

    local questTexture = _G[self:GetName() .. "IconQuestTexture"]

    self.qualityTexture:Hide()

    if questId and not isActive then
        questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
        questTexture:Show()
    elseif questId or isQuestItem then
        questTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
        questTexture:Show()
    else
        questTexture:Hide()
        if quality and quality > 1 then
            local r, g, b = GetItemQualityColor(quality)
            self.qualityTexture:SetVertexColor(r, g, b)
            self.qualityTexture:Show()
        end
    end
end

function LiteBagItemButton_UpdateCooldown(self)
    local bag = self:GetParent():GetID()

    if self.hasItem then
        ContainerFrame_UpdateCooldown(bag, self)
    else
        _G[self:GetName() .. "Cooldown"]:Hide()
    end
end

function LiteBagItemButton_UpdateFiltered(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local isFiltered = select(8, GetContainerItemInfo(bag, slot))

    if isFiltered then
        self.searchOverlay:Show()
    else
        self.searchOverlay:Hide()
    end
end

function LiteBagItemButton_UpdateItemSets(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local stockText = _G[self:GetName() .. "Stock"]

    local _, equipsetName = GetContainerItemEquipmentSetInfo(bag, slot)
    if equipsetName then
        stockText:SetText(gsub(equipsetName, ", ", "\n"))
        stockText:Show()
    else
        stockText:Hide()
    end
end

function LiteBagItemButton_Update(self)
    LiteBagItemButton_UpdateItem(self)
    LiteBagItemButton_UpdateQuestTexture(self)
    LiteBagItemButton_UpdateLocked(self)
    LiteBagItemButton_UpdateCooldown(self)
    LiteBagItemButton_UpdateItemSets(self)
    LiteBagItemButton_UpdateFiltered(self)
end


function LiteBagItemButton_OnLoad(self)
    ContainerFrameItemButton_OnLoad(self)
    self.GetInventorySlot = ButtonInventorySlot
    self.UpdateTooltip = LiteBagItemButton_OnEnter

    -- We (mis)use the stock count text to show the equipset.  By default it's
    -- only attached at TOPLEFT.  Attach it to BOTTOMRIGHT as well so we
    -- get automatic truncation of the text.
    local stockText = _G[self:GetName() .. "Stock"]
    stockText:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 2)
    stockText:SetJustifyV("TOP")
    stockText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
end

function LiteBagItemButton_OnEnter(self)
    local bag = self:GetParent():GetID()
    if bag == BANK_CONTAINER then
        BankFrameItemButton_OnEnter(self)
    else
        ContainerFrameItemButton_OnEnter(self)
    end
end

function LiteBagItemButton_OnLeave(self)
    GameTooltip:Hide()
    ResetCursor()
end

function LiteBagItemButton_OnHide(self)
    if self.hasStackSplit and self.hasStackSplit == 1 then
        StackSplitFrame:Hide()
    end
end

function LiteBagItemButton_OnDrag(self)
    ContainerFrameItemButton_OnDrag(self)
end

