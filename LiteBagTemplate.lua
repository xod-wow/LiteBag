--[[------------------------------------------------------------------------------

  LiteBag/LiteBagTemplate.lua

  Copyright 2013 Mike Battersby

------------------------------------------------------------------------------]]--

function LiteBag_IsMyBag(self, id)
    for _,bag in ipairs(self.bagIDs) do
        if id == bag then return true end
    end
end

function LiteBag_OnLoad(self)

    if not self.bagIDs then
        -- Error!  Needs self.bagIDs set before calling!
        --  <Frame ... inherits="LiteBagTemplate">
        --      <Scripts>
        --          <OnLoad>
        --              self.bagIDs = { 0, 1, 2, 3 }
        --              LiteBag_OnLoad(self)
        return
    end

    self.dummyContainerFrames = { }
    self.itemButtons = { }

    for _,bag in ipairs(self.bagIDs) do
        self.dummyContainerFrames[bag] = CreateFrame("Frame", self:GetName() .. "ContainerFrame" .. bag, self)
        self.dummyContainerFrames[bag]:SetID(bag)
    end

    SetBagPortraitTexture(self.portrait, self.bagIDs[1])

    self:RegisterEvent("BAG_OPEN")
    self:RegisterEvent("BAG_CLOSED")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
end

function LiteBag_OnEvent(self, event, ...)
    if event == "BAG_OPEN" then
        local bag = ...
        if LiteBag_IsMyBag(self, bag) then
            self:Show()
        end
    elseif event == "BAG_CLOSED" then
        local bag = ...
        if LiteBag_IsMyBag(self, bag) then
            self:Hide()
        end
    elseif event == "BAG_UPDATE" then
        local bag = ...
        if LiteBag_IsMyBag(self, bag) then
            LiteBag_Update(self)
        end
    elseif event == "ITEM_LOCK_CHANGED" then
        local bag, slot = ...
        if bag and slot and LiteBag_IsMyBag(self, bag) then
            LiteBag_UpdateLocked(self)
        end
    elseif event == "BAG_UPDATE_COOLDOWN" then
        local bag = ...
        if LiteBag_IsMyBag(self, bag) then
            LiteBag_UpdateCooldowns(self)
        end
    elseif event == "QUEST_ACCEPTED" or event == "UNIT_QUEST_LOG_CHANGED" then
        LiteBag_UpdateQuestTextures(self)
    elseif event == "INVENTORY_SEARCH_UPDATE" then
        LiteBag_UpdateSearchResults(self)
    elseif event == "DISPLAY_SIZE_CHANGED" then
        LiteBag_PositionItemButtons(self)
    end
end

function LiteBag_SetMainMenuBarButtons(self, checked)
    if LiteBag_IsMyBag(BACKPACK_CONTAINER) then
        MainMenuBarBackpackButton:SetChecked(checked)
    end

    for n = 1, NUM_CONTAINER_FRAMES do
        if LiteBag_IsMyBag(n) then
            local button = _G["CharacterBag"..(n-1).."Slot"]
            if button then
                button:SetChecked(checked)
            end
        end
    end
end

function LiteBag_OnHide(self)
    self:UnregisterEvent("BAG_UPDATE")
    self:UnregisterEvent("ITEM_LOCK_CHANGED")
    self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
    self:UnregisterEvent("DISPLAY_SIZE_CHANGED")
    self:UnregisterEvent("INVENTORY_SEARCH_UPDATE")

    LiteBag_SetMainMenuBarButtons(self, 0)

    PlaySound("igBackPackClose")
end

function LiteBag_OnShow(self)
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("ITEM_LOCK_CHANGED")
    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("DISPLAY_SIZE_CHANGED")
    self:RegisterEvent("INVENTORY_SEARCH_UPDATE")

    LiteBag_Update(self)

    LiteBag_SetMainMenuBarButtons(self, 1)

    PlaySound("igBackPackOpen")
end

function LiteBag_AttachSearchBox(self)
    BagItemSearchBox:SetParent(self)
    BagItemSearchBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -26)
    BagItemSearchBox.anchorBag = self
    BagItemSearchBox:Show()
end

function LiteBag_UpdateCooldowns(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateCooldown(self.itemButtons[i])
    end
end

function LiteBag_UpdateSearchResults(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateFiltered(self.itemButtons[i])
    end
end

function LiteBag_UpdateLocked(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateLocked(self.itemButtons[i])
    end
end

function LiteBag_UpdateQuestTextures(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateQuestTexture(self.itemButtons[i])
    end
end

function LiteBag_CreateItemButton(self, i)
    local b = CreateFrame("Button", self:GetName().."Item"..i, self, "LiteBagItemButtonTemplate")
    self.itemButtons[i] = b
end

function LiteBag_CreateItemButtons(self)
    local n = 1

    self.size = 0

    for _,bag in ipairs(self.bagIDs) do
        for slot = GetContainerNumSlots(bag), 1, -1 do
            if not self.itemButtons[n] then
                LiteBag_CreateItemButton(self, n)
            end
            self.itemButtons[n]:SetID(slot)
            self.itemButtons[n]:SetParent(self.dummyContainerFrames[bag])
            self.size = self.size + 1
            n = n + 1
        end
    end
end

function LiteBag_PositionItemButtons(self)
    local name = self:GetName()

    for i = 1, self.size do
        local itemButton = self.itemButtons[i]
        if i == 1 then
            self.itemButtons[i]:SetPoint("BOTTOMRIGHT", name, "BOTTOMRIGHT", -12, 9 + self.moneyFrame:GetHeight())
        elseif i % 8 == 1 then
            self.itemButtons[i]:SetPoint("BOTTOMRIGHT", self.itemButtons[i-8], "TOPRIGHT", 0, 2)
        else
            self.itemButtons[i]:SetPoint("BOTTOMRIGHT", self.itemButtons[i-1]:GetName(), "BOTTOMLEFT", -2, 0)
        end
            
    end
end

function LiteBag_Update(self)

    if not self:IsShown() then return end

    LiteBag_AttachSearchBox(self)

    LiteBag_CreateItemButtons(self)
    LiteBag_PositionItemButtons(self)

    for i,itemButton in ipairs(self.itemButtons) do
        if i <= self.size then
            LiteBagItemButton_Update(itemButton)
            itemButton:Show()
        else
            itemButton:Hide()
        end
    end
end
