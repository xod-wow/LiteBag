--[[----------------------------------------------------------------------------

  LiteBag/LiteBagItemButtonTemplate.lua

  Copyright 2013-2014 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

--[[----------------------------------------------------------------------------
  Frame components of a LiteBagItemButtonTemplate frame.

  Inherited from ContainerFrameItemButtonTemplate:
    $parentIconTexture (Texture) also frame.icon
        The main icon image for the item
    $parentCount (FontString)
        The stack count (a number) attached at the bottom right.
    $parentStock (FontString)
        The number in stock at the vendor.  It's unused in for the bag items
        so we re-size it and re-font it and use it for the Equipment Set name.
        Attached at the top left.
    $parentSearchOverlay (Texture)
        Shown when the item does not match a bag search.  It's a black texture
        with 0.8 alpha that covers the entire icon and blacks it out.
    $parentNormalTexture (Texture)
        This is the button outline stuff.  There's also corresponding Pushed
        and Highlight texture that aren't named.  We don't touch this, it's
        just part of the normal button click behaviour stuff.
    $parentIconQuestTexture (Texture)
        Shows the gold ! on items that will start a quest if you click them.
    $parentNewItemTexture (Texture)
        Show something (not sure what yet) for items you just bought from the
        in-game store.
    $parentCooldown (Cooldown)
        Normal item cooldown frame (does the sweep etc.).
    $parent.IconBorder
        An overlay for the button border that colors it according to the
        quality of the item.  Used to be LiteBag's qualityTexture prior to
        Blizzard adding it in 6.0.2.

  Added by LiteBagItemButtonTemplate:
    $parentBackgroundTexture (Texture) also frame.backgroundTexture
        The slot background, so that empty slots have a texture.

----------------------------------------------------------------------------]]--

function LiteBagItemButton_UpdateItem(self)

    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local texture, count, _, _, readable = GetContainerItemInfo(bag, slot)

    SetItemButtonCount(self, count)

    self.readable = readable

    -- local normalTexture = _G[self:GetName() .. "NormalTexture"]
    if texture then
        self.icon:SetTexture(texture)
        self.hasItem = 1
    else
        self.icon:SetTexture(nil)
        self.hasItem = nil
    end

    if self == GameTooltip:GetOwner() then
        if self.hasItem then
            self:UpdateTooltip()
        else
            GameTooltip:Hide()
        end
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
    local questTexture = _G[self:GetName() .. "IconQuestTexture"]

    if questId and not isActive then
        questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
        questTexture:Show()
    elseif questId or isQuestItem then
        questTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
        questTexture:Show()
    else
        questTexture:Hide()
    end

end

function LiteBagItemButton_UpdateQuality(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local quality, _, _, _, noValue = select(4, GetContainerItemInfo(bag, slot))

    self.JunkIcon:Hide()
    self.IconBorder:Hide()

    if not quality then return end

    if quality >= LE_ITEM_QUALITY_COMMON and BAG_ITEM_QUALITY_COLORS[quality] then
        self.IconBorder:SetVertexColor(BAG_ITEM_QUALITY_COLORS[quality].r,
                                       BAG_ITEM_QUALITY_COLORS[quality].g,
                                       BAG_ITEM_QUALITY_COLORS[quality].b)
        self.IconBorder:Show()
    elseif quality == LE_ITEM_QUALITY_POOR and not noValue and MerchantFrame:IsShown() then
        self.JunkIcon:Show()
    end

end

function LiteBagItemButton_ClearNewItem(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()
    C_NewItems.RemoveNewItem(bag, slot)
end

function LiteBagItemButton_UpdateNewItemTexture(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local newItemTexture = self.NewItemTexture
    local battlepayItemTexture = self.BattlepayItemTexture
    local isNewItem = C_NewItems.IsNewItem(bag, slot)
    local isBattlePayItem = IsBattlePayItem(bag, slot)
    local flash = self.flashAnim
    local newItemAnim = self.newitemglowAnim

    local quality = select(4, GetContainerItemInfo(bag, slot))

    if isNewItem and isBattlePayItem then
        newItemTexture:Hide()
        battlepayItemTexture:Show()
    elseif isNewItem then
        if quality and NEW_ITEM_ATLAS_BY_QUALITY[quality] then
            newItemTexture:SetAtlas(NEW_ITEM_ATLAS_BY_QUALITY[quality])
        else
            newItemTexture:SetAtlas("bags-glow-white")
        end
        if not flash:IsPlaying() and not newItemAnim:IsPlaying() then
            flash:Play()
            newItemAnim:Play()
        end
        newItemTexture:Show()
        battlepayItemTexture:Hide()
    else
        newItemTexture:Hide()
        battlepayItemTexture:Hide()
        if flash:IsPlaying() or newItemAnim:IsPlaying() then
            flash:Stop()
            newItemAnim:Stop()
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

function LiteBagItemButton_UpdateEquipmentSets(self)
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
    LiteBagItemButton_UpdateLocked(self)
    LiteBagItemButton_UpdateQuestTexture(self)
    LiteBagItemButton_UpdateNewItemTexture(self)
    LiteBagItemButton_UpdateQuality(self)
    LiteBagItemButton_UpdateCooldown(self)
    LiteBagItemButton_UpdateEquipmentSets(self)
    LiteBagItemButton_UpdateFiltered(self)
end


function LiteBagItemButton_OnLoad(self)
    ContainerFrameItemButton_OnLoad(self)
    self.GetInventorySlot = ButtonInventorySlot
    self.UpdateTooltip = LiteBagItemButton_OnEnter

    -- We (mis)use the "number in stock at vendor" text to show the equipset.
    -- By default it's only attached at TOPLEFT.  Attach it to BOTTOMRIGHT as
    -- well so we get multiline and automatic truncation of the text.  And
    -- set the font size a little smaller (by default it uses
    -- NumberFontNormalYellow (see FontStyles.xml in the Blizzard UI source).

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

