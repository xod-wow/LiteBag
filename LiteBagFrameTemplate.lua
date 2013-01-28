--[[----------------------------------------------------------------------------

  LiteBag/LiteBagTemplate.lua

  Copyright 2013 Mike Battersby

----------------------------------------------------------------------------]]--

function LiteBagFrame_IsMyBag(self, id)
    for _,bag in ipairs(self.bagIDs) do
        if id == bag then return true end
    end
end

function LiteBagFrame_OnLoad(self)

    if not self.bagIDs then
        -- Error!  Needs self.bagIDs set before calling!
        --  <Frame ... inherits="LiteBagFrameTemplate">
        --      <Scripts>
        --          <OnLoad>
        --              self.bagIDs = { 0, 1, 2, 3 }
        --              LiteBagFrame_OnLoad(self)
        return
    end

    self.dummyContainerFrames = { }
    self.itemButtons = { }
    self.size = 0

    for _,bag in ipairs(self.bagIDs) do
        local bagName = self:GetName() .. "ContainerFrame" .. bag
        self.dummyContainerFrames[bag] = CreateFrame("Frame",  name, self)
        self.dummyContainerFrames[bag]:SetID(bag)
    end

    local insetBg = _G[self:GetName() .."InsetBg"]

    if LiteBagFrame_IsMyBag(self, BANK_CONTAINER) then
        self.isBank = 1
        self:SetAttribute("UIPanelLayout-defined", true)
        self:SetAttribute("UIPanelLayout-area", "left")
        self:SetAttribute("UIPanelLayout-pushable", 6)
        insetBg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", true, true)
    elseif LiteBagFrame_IsMyBag(self, BACKPACK_CONTAINER) then
        self.isBackpack = 1
        tinsert(UISpecialFrames, self:GetName())
    end

    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("BAG_CLOSED")
end

function LiteBagFrame_Show(self)
    if self.isBank then
        ShowUIPanel(self)
    else
        self:Show()
    end
end

function LiteBagFrame_Hide(self)
    if self.isBank then
        HideUIPanel(self)
    else
        self:Show()
    end
end

function LiteBagFrame_OnEvent(self, event, ...)
    if event == "BAG_OPEN" then
        local bag = ...
        if LiteBagFrame_IsMyBag(self, bag) then
            LiteBagFrame_Show(self)
        end
    elseif event == "BANKFRAME_OPENED" then
        if self.isBank then
            LiteBagFrame_Show(self)
        end
    elseif event == "BANKFRAME_CLOSED" then
        if self.isBank then
            LiteBagFrame_Hide(self)
        end
    elseif event == "BAG_UPDATE" or event == "BAG_CLOSED" then
        local bag = ...
        if LiteBagFrame_IsMyBag(self, bag) then
            LiteBagFrame_Update(self)
        end
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        local slot = ...
        if self.isBank then
            if slot <= NUM_BANKGENERIC_SLOTS then
                LiteBagFrame_Update(self)
            end
        end
    elseif event == "ITEM_LOCK_CHANGED" then
        local bag, slot = ...
        if bag and slot and LiteBagFrame_IsMyBag(self, bag) then
            LiteBagFrame_UpdateLocked(self)
        end
    elseif event == "BAG_UPDATE_COOLDOWN" then
        local bag = ...
        if LiteBagFrame_IsMyBag(self, bag) then
            LiteBagFrame_UpdateCooldowns(self)
        end
    elseif event == "QUEST_ACCEPTED" or event == "UNIT_QUEST_LOG_CHANGED" then
        LiteBagFrame_UpdateQuestTextures(self)
    elseif event == "INVENTORY_SEARCH_UPDATE" then
        LiteBagFrame_UpdateSearchResults(self)
    elseif event == "DISPLAY_SIZE_CHANGED" then
        LiteBagFrame_PositionItemButtons(self)
    end
end

function LiteBagFrame_SetMainMenuBarButtons(self, checked)
    if self.isBackpack then
        MainMenuBarBackpackButton:SetChecked(checked)
    end

    for n = 1, NUM_CONTAINER_FRAMES do
        if LiteBagFrame_IsMyBag(self, n) then
            local button = _G["CharacterBag"..(n-1).."Slot"]
            if button then
                button:SetChecked(checked)
            end
        end
    end
end

function LiteBagFrame_OnHide(self)
    self:UnregisterEvent("BAG_UPDATE")
    self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:UnregisterEvent("ITEM_LOCK_CHANGED")
    self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
    self:UnregisterEvent("DISPLAY_SIZE_CHANGED")
    self:UnregisterEvent("INVENTORY_SEARCH_UPDATE")
    self:UnregisterEvent("QUEST_ACCEPTED")
    self:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")

    LiteBagFrame_SetMainMenuBarButtons(self, 0)
    if self.isBank then
       CloseBankFrame()
    end

    PlaySound("igBackPackClose")
end

function LiteBagFrame_OnShow(self)
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:RegisterEvent("ITEM_LOCK_CHANGED")
    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("DISPLAY_SIZE_CHANGED")
    self:RegisterEvent("INVENTORY_SEARCH_UPDATE")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")

    local titleText =_G[self:GetName() .. "TitleText"]

    if self.isBackpack then
        SetPortraitTexture(self.portrait, "player")
        titleText:SetText(GetBagName(self.bagIDs[1]))
    elseif self.isBank then
        SetPortraitTexture(self.portrait, "npc")
        titleText:SetText(UnitName("npc"))
    else
        SetBagPortraitTexture(self.portrait, self.bagIDs[1])
        titleText:SetText(GetBagName(self.bagIDs[1]))
    end

    self:RegisterEvent("BAG_OPEN")
    LiteBagFrame_Update(self)

    LiteBagFrame_SetMainMenuBarButtons(self, 1)

    PlaySound("igBackPackOpen")
end

function LiteBagFrame_AttachSearchBox(self)
    local box
    if self.isBank then
        box = BankItemSearchBox
    else
        box = BagItemSearchBox
    end

    box:SetParent(self)
    box:SetPoint("TOPRIGHT", self, "TOPRIGHT", -14, -34)
    box.anchorBag = self
    box:Show()
end

function LiteBagFrame_UpdateCooldowns(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateCooldown(self.itemButtons[i])
    end
end

function LiteBagFrame_UpdateSearchResults(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateFiltered(self.itemButtons[i])
    end
end

function LiteBagFrame_UpdateLocked(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateLocked(self.itemButtons[i])
    end
end

function LiteBagFrame_UpdateQuestTextures(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateQuestTexture(self.itemButtons[i])
    end
end

function LiteBagFrame_CreateItemButton(self, i)
    local b = CreateFrame("Button", self:GetName().."Item"..i, self, "LiteBagItemButtonTemplate")
    self.itemButtons[i] = b
end

function LiteBagFrame_CreateItemButtons(self)
    local n = 1

    self.size = 0

    for _,bag in ipairs(self.bagIDs) do
        for slot = 1, GetContainerNumSlots(bag) do
            if not self.itemButtons[n] then
                LiteBagFrame_CreateItemButton(self, n)
            end
            self.itemButtons[n]:SetID(slot)
            self.itemButtons[n]:SetParent(self.dummyContainerFrames[bag])
            self.size = self.size + 1
            n = n + 1
        end
    end
end

function LiteBagFrame_PositionItemButtons(self)
    local name = self:GetName()

    local wgap, hgap = 5, 4
    local ncols = self.columns or 8

    for i = 1, self.size do
        local itemButton = self.itemButtons[i]
            itemButton:ClearAllPoints()
        if i == 1 then
            self.itemButtons[i]:SetPoint("TOPLEFT", name, "TOPLEFT", 14, -70)
        elseif i % ncols == 1 then
            self.itemButtons[i]:SetPoint("TOPLEFT", self.itemButtons[i-ncols], "BOTTOMLEFT", 0, -hgap)
        else
            self.itemButtons[i]:SetPoint("TOPLEFT", self.itemButtons[i-1]:GetName(), "TOPRIGHT", wgap, 0)
        end

    end

    local nrows = ceil(self.size / ncols)
    local w, h = self.itemButtons[1]:GetSize()

    self:SetWidth(29 + ncols * w + (ncols-1) * wgap)
    self:SetHeight(105 + nrows * h + (nrows-1) * hgap)
end

function LiteBagFrame_Update(self)

    if not self:IsShown() then return end

    LiteBagFrame_AttachSearchBox(self)

    LiteBagFrame_CreateItemButtons(self)
    LiteBagFrame_PositionItemButtons(self)

    for i,itemButton in ipairs(self.itemButtons) do
        if i <= self.size then
            LiteBagItemButton_Update(itemButton)
            itemButton:Show()
        else
            itemButton:Hide()
        end
    end
end
