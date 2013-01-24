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

    local quality, _, _, _, isFiltered = select(4, GetContainerItemInfo(bag, slot))

    if isFiltered then
        self.qualityTexture:Hide()
        self.searchOverlay:Show()
    else
        if GetContainerItemQuestInfo(bag, slot) then
            self.qualityTexture:Hide()
        elseif not quality or quality < 2 then
            self.qualityTexture:Hide()
        else
            local r, g, b = GetItemQualityColor(quality)
            self.qualityTexture:SetVertexColor(r, g, b)
            self.qualityTexture:Show()
        end
        self.searchOverlay:Hide()
    end
end

function LiteBagItemButton_Update(self)
    LiteBagItemButton_UpdateItem(self)
    LiteBagItemButton_UpdateQuestTexture(self)
    LiteBagItemButton_UpdateLocked(self)
    LiteBagItemButton_UpdateCooldown(self)
    LiteBagItemButton_UpdateFiltered(self)
end


function LiteBagItemButton_OnLoad(self)
    -- ContainerFrameItemButtonTemplate:GetScript("OnLoad")(self)
    ContainerFrameItemButton_OnLoad(self)
end

function LiteBagItemButton_OnClick(self, button)
    -- ContainerFrameItemButtonTemplate:GetScript("OnClick")(self)

    -- This buggering around with IsModifiedClick taken from the OnClick
    -- handler for ContainerFrameItemButtonTemplate.  See ContainerFrame.xml.

    local treatAsModified = IsModifiedClick()
    if button ~= "LeftButton" and treatAsModified and IsModifiedClick("AUTOLOOTTOGGLE") then
        local bag = self:GetParent():GetID()
        local slot = self:GetID()
        local lootable = select(6, GetContainerItemInfo(bag, slot))
        if lootable then
            treatAsModified = false
        end
    end

    if treatAsModified then
        ContainerFrameItemButton_OnModifiedClick(self, button)
    else
        ContainerFrameItemButton_OnClick(self, button)
    end
end

function LiteBagItemButton_OnEnter(self)
    -- ContainerFrameItemButtonTemplate:GetScript("OnEnter")(self)
    ContainerFrameItemButton_OnEnter(self)
end

function LiteBagItemButton_OnLeave(self)
    -- ContainerFrameItemButtonTemplate:GetScript("OnLeave")(self)
    Gametooltip:Hide()
    ResetCursor()
end

function LiteBagItemButton_OnHide(self)
    -- ContainerFrameItemButtonTemplate:GetScript("OnHide")(self)
    if self.hasStackSplit and self.hasStackSplit == 1 then
        StackSplitFrame:Hide()
    end
end

function LiteBagItemButton_OnDrag(self)
    -- ContainerFrameItemButtonTemplate:GetScript("OnDrag")(self)
    ContainerFrameItemButton_OnDrag(self)
end

