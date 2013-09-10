--[[----------------------------------------------------------------------------

  LiteBag/LiteBagItemButtonTemplate.lua

  Copyright 2013 Mike Battersby

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

  Added by LiteBagItemButtonTemplate:
    $parentQualityTexture (Texture) also frame.qualityTexture
        An overlay for the button border that colors it according to the
        quality of the item.
    $parentBackgroundTexture (Texture) also frame.backgroundTexture
        The slot background, so that empty slots have a texture.

----------------------------------------------------------------------------]]--

-- See http://wowprogramming.com/docs/api/GetItemFamily
local TradeBagColorTable = {
    [0x8]       = { 1.00, 0.60, 0.45 },             -- Leatherworking
    [0x10]      = { 0.64, 1.00, 0.82 },             -- Inscription
    [0x20]      = { 0.50, 1.00, 0.50 },             -- Herbalism
    [0x40]      = { 0.64, 0.83, 1.00 },             -- Enchanting
    [0x80]      = { 0.68, 0.63, 0.25 },             -- Engineering
    [0x200]     = { 1.00, 0.65, 0.98 },             -- Jewelcrafting
    [0x400]     = { 1.00, 0.81, 0.38 },             -- Mining
    [0x8000]    = { 0.42, 0.59, 1.00 },             -- Fishing
    [0x10000]   = { 1.00, 0.50, 0.50 },             -- Cooking
}

local function GetTradeBagColor(self)
    local family = self:GetParent().family

    if family and family ~= 0 then
        local c = TradeBagColorTable[family]
        if c then return c[1], c[2], c[3] end
    end

    return 1, 1, 1
end

function LiteBagItemButton_UpdateItem(self)

    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local texture, count, _, _, readable = GetContainerItemInfo(bag, slot)

    SetItemButtonCount(self, count)

    self.readable = readable

    -- local normalTexture = _G[self:GetName() .. "NormalTexture"]
    if texture then
        self.icon:SetTexture(texture)
        --self.icon:SetBlendMode("BLEND")
        --normalTexture:SetVertexColor(1, 1, 1)
        self.hasItem = 1
    else
        self.icon:SetTexture(nil)
        -- self.icon:SetTexture(GetTradeBagColor(self))
        -- self.icon:SetBlendMode("MOD")
        --normalTexture:SetVertexColor(GetTradeBagColor(self))
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

function LiteBagItemButton_ClearNewItem(self)
    -- Test for 5.4 and onwards, can remove after 5.4 goes live
    if not C_NewItems then return end

    local bag = self:GetParent():GetID()
    local slot = self:GetID()
    C_NewItems.RemoveNewItem(bag, slot)
end

function LiteBagItemButton_UpdateNewItemTexture(self)
    -- Test for 5.4 and onwards, can remove after 5.4 goes live
    if not C_NewItems then return end

    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local newItemTexture = _G[self:GetName() .. "NewItemTexture"]
    local isNewItem = C_NewItems.IsNewItem(bag, slot)
    local isBattlePayItem = IsBattlePayItem(bag, slot)
    if isNewItem and isBattlePayItem then
        newItemTexture:Show()
    else
        newItemTexture:Hide()
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
    LiteBagItemButton_UpdateNewItemTexture(self)
    LiteBagItemButton_UpdateQuestTexture(self)
    LiteBagItemButton_UpdateLocked(self)
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

