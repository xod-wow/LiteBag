--[[----------------------------------------------------------------------------

  LiteBag/LiteBagItemButtonTemplate.lua

  Copyright 2013-2015 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

--[[----------------------------------------------------------------------------
  Frame components of a LiteBagItemButtonTemplate frame.

  Inherited from ItemButtonTemplate:
    $parentIconTexture (Texture level=BORDER/0) also self.icon
        The main icon image for the item
    self.IconBorder (Texture level=OVERLAY/0)
        An overlay for the button border that colors it according to the
        quality of the item.
    $parentCount (FontString level=ARTWORK/2)
        The stack count (a number) attached at the bottom right.
    $parentStock (FontString level=ARTWORK/2)
        The number in stock at the vendor.
    self.searchOverlay (Texture level=OVERLAY/0)
        Shown when the item does not match a bag search.  It's a black texture
        with 0.8 alpha that covers the entire icon and blacks it out.
    $parentNormalTexture (Texture)
        This is the button outline stuff.  There's also corresponding Pushed
        and Highlight texture that aren't named.  We don't touch this, it's
        just part of the normal button click behaviour stuff.

  Inherited from ContainerFrameItemButtonTemplate:
    $parentIconQuestTexture (Texture level=ARTWORK/1)
        Shows the gold ! on items that will start a quest if you click them.
    self.JunkIcon (Texture level=OVERLAY/1)
        Gold coin icon shown when a vendor is open for grey items.
    self.flash (Texture level=OVERLAY/1)
        Edge flash for new items, used by an associated Animation.
    self.NewItemTexture (Texture level=OVERLAY/1)
        Edge glow for "new" items whatever the API returns one is.
    self.BattlePayItemTexture (Texture level=OVERLAY/1)
        Highlight for imaginary items you paid good money for.
    $parentCooldown (Cooldown)
        Normal item cooldown frame (does the sweep etc.).

  Added by LiteBagItemButtonTemplate:
    self.backgroundTexture (Texture level=BACKGROUND/0)
        The slot background, so that empty slots have a texture.
    self.eqTexture1/2/3/4 (Texture level=ARTWORK/1)
        Textures shown when the item is part of one of the first
        four EquipmentSets.

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

    local _, _, _, quality, _, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)

    SetItemButtonQuality(self, quality, itemID)

    self.JunkIcon:SetShown(quality == LE_ITEM_QUALITY_POOR and not noValue and MerchantFrame:IsShown())

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

function LiteBagItemButton_UpdateRelicTutorial(self)

    if self.searchOverlay:IsShown() then return end
    if GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_ARTIFACT_RELIC_MATCH) then return end

    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local itemID = select(10, GetContainerItemInfo(bag, slot))
    ContainerFrame_ConsiderItemButtonForRelicTutorial(self, itemID);

    -- Blizzard sets the owner to the container frame but we set it to the
    -- itembutton that contains the Artifact.

    if ArtifactRelicHelpBox.owner == self:GetParent() then
        ArtifactRelicHelpBox.owner = self
    end
end

function  LiteBagItemButton_UpdateItemLevel(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    -- XXX FIXME XXX self.itemLevel isn't in the XML yet.
    local _, _, _, quality, _, _, link, _ = GetContainerItemInfo(bag, slot)
    if link then
        local iLevel = select(4, GetItemInfo(link))
        if iLevel then
            local r, g, b = GetItemQualityColor(quality)
            self.itemLevel:SetText(iLevel)
            self.itemLevel:Show()
            self.itemLevel:SetTextColor(r,g,b)
            return
        end
    end

    stockText:Hide()
end

local function ContainerItemIsPartOfEquipmentSet(bag, slot, i)
    local _,equipSetNames = GetContainerItemEquipmentSetInfo(bag, slot)

    if not equipSetNames then return end

    local name = GetEquipmentSetInfo(i)
    for _,n in ipairs({ strsplit(", " , equipSetNames) }) do
        if n == name then return true end
    end
    return false

end

function LiteBagItemButton_UpdateEquipmentSets(self)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    for i=1,4 do
        local tex = self["eqTexture"..i]
        if LiteBag_GetGlobalOption("HideEquipsetIcon") == nil and
           ContainerItemIsPartOfEquipmentSet(bag, slot, i) then
            tex:Show()
        else
            tex:Hide()
        end
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
    -- LiteBagItemButton_UpdateRelicTutorial(self)
    -- LiteBagItemButton_UpdateItemLevel(self)
end


function LiteBagItemButton_OnLoad(self)
    ContainerFrameItemButton_OnLoad(self)
    self.GetInventorySlot = ButtonInventorySlot
    self.UpdateTooltip = LiteBagItemButton_OnEnter
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
    -- Bank inherits the ContainerFrameItemButton_OnLeave so no "if" test
    ContainerFrameItemButton_OnLeave(self)
end

function LiteBagItemButton_OnHide(self)
    if self.hasStackSplit and self.hasStackSplit == 1 then
        StackSplitFrame:Hide()
    end
end
