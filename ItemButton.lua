--[[----------------------------------------------------------------------------

  LiteBag/ItemButton.lua

  Copyright 2013-2018 Mike Battersby

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
        Gold coin icon on grey items, shown when a vendor is open.
    self.flash (Texture level=OVERLAY/1)
        Edge flash for new items, used by an associated Animation.
    self.NewItemTexture (Texture level=OVERLAY/1)
        Edge glow for "new" items whatever the API returns one is.
    self.BattlePayItemTexture (Texture level=OVERLAY/1)
        Highlight for imaginary items you paid good money for.
    $parentCooldown (Cooldown)
        Normal item cooldown frame (does the sweep etc.).
    self.UpgradeItem
        Arrow shown when an item is an upgrade (added in 7.1).

  Added by LiteBagItemButtonTemplate:
    self.BackgroundTexture
        Slot background to show through if the slot is empty.

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

    local minQuality = LiteBag_GetGlobalOption("ThickerIconBorder")
    if quality and minQuality then
        minQuality = tonumber(minQuality) or 0
        if quality >= minQuality and self.IconBorder:GetTexture() == [[Interface\Common\WhiteIconFrame]] then
            self.IconBorder:SetTexture([[Interface\Addons\LiteBag\Artwork\IconBorder]])
        end
    end

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

-- Make sure to do this after the search overlay update.
--
-- Note that the caller must ContainerFrame_CloseSpecializedTutorialForItem
-- before updating all its buttons if it was parented to one of the bags.

function LiteBagItemButton_UpdateTutorials(self)

    if self.searchOverlay:IsShown() then return end
    if BagHelpBox:IsShown() then return end

    local bag = self:GetParent():GetID()
    local slot = self:GetID()
    local itemID = select(10, GetContainerItemInfo(bag, slot))

    if not GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_AZERITE_ITEM_IN_SLOT) then
        -- Sets the .owner of the tutorial to bag:GetParent()
        ContainerFrame_ConsiderItemButtonForAzeriteTutorial(self, itemID)
    end

    if not GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_ARTIFACT_RELIC_MATCH) then
        -- Sets the .owner of the tutorial to bag:GetParent()
        ContainerFrame_ConsiderItemButtonForRelicTutorial(self, itemID)
    end
end

-- This is a little weird inside, because apparently "is this an upgrade"
-- is calculated on the server from some algorithm and may not be available
-- immediately. So the ContainerFrameItemButton_UpdateItemUpgradeIcon function
-- (from ContainerFrame.lua) puts temporary OnUpdate handler on the button to
-- keep checking every 0.5 seconds until it's ready (yuk). I don't know why
-- they didn't just have that trigger a new event.

function LiteBagItemButton_UpdateItemUpgrade(self)
    ContainerFrameItemButton_UpdateItemUpgradeIcon(self)
end

function LiteBagItemButton_Update(self)
    LiteBagItemButton_UpdateItem(self)
    LiteBagItemButton_UpdateLocked(self)
    LiteBagItemButton_UpdateQuestTexture(self)
    LiteBagItemButton_UpdateNewItemTexture(self)
    LiteBagItemButton_UpdateQuality(self)
    LiteBagItemButton_UpdateCooldown(self)
    LiteBagItemButton_UpdateFiltered(self)
    LiteBagItemButton_UpdateItemUpgrade(self)
    LiteBagItemButton_UpdateTutorials(self)

    -- For debugging layouts
    -- _G[self:GetName().."Count"]:SetText(format("%d,%d", self:GetParent():GetID(), self:GetID()))
    -- _G[self:GetName().."Count"]:Show()
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

-- No OnLeave, both bank and bags use ContainerframeItemButton_OnLeave
-- which is automatically inherited
