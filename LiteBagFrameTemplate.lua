--[[----------------------------------------------------------------------------

  LiteBag/LiteBagTemplate.lua

  Copyright 2013 Mike Battersby

----------------------------------------------------------------------------]]--

function LiteBagFrame_IsMyBag(self, id)
    -- For some reason BAG_UPDATE_COOLDOWN sometimes doesn't have a bag
    -- argument. Since we can't tell if it's us we better assume it is.
    if not id then return true end

    -- Otherwise test each of our bags.
    for _,bag in ipairs(self.bagIDs) do
        if id == bag then return true end
    end
end

function LiteBagFrame_UpdateTokens(self)
    for i = 1,MAX_WATCHED_TOKENS do
        local name,count,icon,currencyID = GetBackpackCurrencyInfo(i)
        local tokenFrame = _G[self:GetName().."Token"..i]
        if name then
            tokenFrame.icon:SetTexture(icon)
            if count <= 99999 then
                tokenFrame.count:SetText(count)
            else
                tokenFrame.count:SetText("*")
            end
            tokenFrame.currencyID = currencyID
            tokenFrame:Show()
        else
            tokenFrame:Hide()
        end
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

    for _,bag in ipairs(self.bagIDs) do
        local bagName = self:GetName() .. "ContainerFrame" .. bag
        self.dummyContainerFrames[bag] = CreateFrame("Frame",  name, self)
        self.dummyContainerFrames[bag]:SetID(bag)
    end

    -- The UIPanelLayout stuff makes the Blizzard UIParent code position a
    -- frame automatically in the stack from the left side.  See
    --   http://www.wowwiki.com/Creating_standard_left-sliding_frames
    -- but note that UIPanelLayout-enabled isn't a thing at all.
    if LiteBagFrame_IsMyBag(self, BANK_CONTAINER) then
        self.isBank = 1
        self:SetAttribute("UIPanelLayout-defined", true)
        self:SetAttribute("UIPanelLayout-area", "left")
        self:SetAttribute("UIPanelLayout-pushable", 6)
        local insetBg = _G[self:GetName() .."InsetBg"]
        insetBg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", true, true)
    elseif LiteBagFrame_IsMyBag(self, BACKPACK_CONTAINER) then
        self.isBackpack = 1
        tinsert(UISpecialFrames, self:GetName())
    end

    self.size = 0
    self.itemButtons = { }

    -- If we knew a point where we definitely had the bag size info
    -- but weren't already InCombatLockdown at that point we could do
    -- that there (later).  Then we'd make only the exact number of
    -- buttons needed.

    LiteBagFrame_CreateItemButtons(self)

    -- There's no event for token updates, we just hook off the
    -- Blizzard function that updates it (which is fired when the user
    -- changes the selection in the full token frame).  We don't replace
    -- the function because parts of the TokenFrame rely on the
    -- BackpackTokenFrame even though it's hidden.

    hooksecurefunc('BackpackTokenFrame_Update',
                   function () LiteBagFrame_UpdateTokens(self) end)

    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("BAG_OPEN")
    self:RegisterEvent("BAG_CLOSED")

    -- We hook ADDON_LOADED to do an initial layout of the frame, as we
    -- will know how big the bags are at that point and still not be
    -- InCombatLockown().

    self:RegisterEvent("ADDON_LOADED")
end

-- Because the bank is a managed frame (Blizzard code sets its position)
-- we have to use Show/HideUIPanel for it.
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
        self:Hide()
    end
end

function LiteBagFrame_ToggleShown(self)
    if self:IsShown() then
        LiteBagFrame_Hide(self)
    else
        LiteBagFrame_Show(self)
    end
end

-- Apart from BAG_OPEN/CLOSED and BANKFRAME_OPENED/CLOSED these events
-- are only registered while the frames are shown, so we can call the
-- update functions without worrying that we don't need to.
function LiteBagFrame_OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        LiteBagFrame_Update(self)
    elseif event == "BAG_OPEN" then
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
    elseif event == "BAG_UPDATE" then
        local bag = ...
        if LiteBagFrame_IsMyBag(self, bag) then
            LiteBagFrame_Update(self)
        end
    elseif event == "BAG_CLOSED" then
        -- BAG_CLOSED fires when you drag a bag out of a slot but for
        -- the bank GetContainerNumSlots doesn't update until _DELAYED
        local bag = ...
        if LiteBagFrame_IsMyBag(self, bag) then
            self:RegisterEvent("BAG_UPDATE_DELAYED")
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        self:UnregisterEvent("BAG_UPDATE_DELAYED")
        LiteBagFrame_Update(self)
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        local slot = ...
        if self.isBank then
            LiteBagFrame_Update(self)
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
        LiteBagFrame_LayoutFrame(self)
    end
end

function LiteBagFrame_SetMainMenuBarButtons(self, checked)
    if self.isBackpack then
        MainMenuBarBackpackButton:SetChecked(checked)
    end

    -- Since BACKPACK_CONTAINER is 1, CharacterBag0Slot doesn't exist and
    -- the "if button then" check fails.  It would probably be clearer to
    -- incorporate the above into the loop instead.

    for n = 1, NUM_CONTAINER_FRAMES do
        if LiteBagFrame_IsMyBag(self, n) then
            local button = _G["CharacterBag"..(n-1).."Slot"]
            if button then
                button:SetChecked(checked)
            end
        end
    end
end

-- The bag buttons call these to highlight the relevant buttons
-- for their particular bag when they are moused over.

function LiteBagFrame_HighlightBagButtons(self, id)
    if not LiteBagFrame_IsMyBag(self, id) then
        return
    end

    for i = 1, self.size do
        local button = self.itemButtons[i]
        if button:GetParent():GetID() == id then
            button:LockHighlight()
        end
    end
end

function LiteBagFrame_UnhighlightBagButtons(self, id)
    if not LiteBagFrame_IsMyBag(self, id) then
        return
    end

    for i = 1, self.size do
        local button = self.itemButtons[i]
        if button:GetParent():GetID() == id then
            button:UnlockHighlight()
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
        -- CONTAINER_OFFSET_* are globals that are updated by the Blizzard
        -- code depending on what (default) action bars are shown.
        self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y)

        -- This would probably be better as a backpack icon of some sort but
        -- there isn't one: the backpack "portrait" is part of the frame
        -- artwork for the backpack.
        SetPortraitTexture(self.portrait, "player")
        titleText:SetText(GetBagName(self.bagIDs[1]))
    elseif self.isBank then
        SetPortraitTexture(self.portrait, "npc")
        titleText:SetText(UnitName("npc"))
    else
        SetBagPortraitTexture(self.portrait, self.bagIDs[1])
        titleText:SetText(GetBagName(self.bagIDs[1]))
    end

    LiteBagFrame_Update(self)
    LiteBagFrame_UpdateTokens(self)

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

function LiteBagFrame_UpdateItemButtons(self)
    for i = 1, self.size do
        LiteBagItemButton_Update(self.itemButtons[i])
    end
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

-- We make the maximum number of buttons, because we make them at init
-- time when we are guaranteed not to be InCombatLockdown.  Later when bag
-- sizes are known or changed we might not be able to safely make protected
-- buttons.

function LiteBagFrame_CreateItemButtons(self)

    local n = 0

    for _,bag in ipairs(self.bagIDs) do
        for i = 1, MAX_CONTAINER_ITEMS do
            n = n + 1
            if not self.itemButtons[n] then
                LiteBagFrame_CreateItemButton(self, n)
            end
        end
    end
end

-- Assign the buttons to their bag/slot. Because the buttons are
-- protected we are using the Blizzard code for them, and that relies on
-- button:GetID() being the slot ID and button:GetParent():GetID() being
-- the bag ID. That's why we have the dummy parent containers.

function LiteBagFrame_SetupItemButtons(self)
    local n = 0

    for _,bag in ipairs(self.bagIDs) do
        for slot = 1, GetContainerNumSlots(bag) do
            n = n + 1
            self.itemButtons[n]:SetID(slot)
            self.itemButtons[n]:SetParent(self.dummyContainerFrames[bag])
        end
    end

    self.size = n
end

function LiteBagFrame_LayoutFrame(self)
    if InCombatLockdown() then return end

    local name = self:GetName()

    local wgap, hgap = 5, 4
    local ncols = self.columns or 8

    for i = 1, #self.itemButtons do
        local itemButton = self.itemButtons[i]

        itemButton:ClearAllPoints()
        if i == 1 then
            self.itemButtons[i]:SetPoint("TOPLEFT", name, "TOPLEFT", 14, -70)
        elseif i % ncols == 1 then
            self.itemButtons[i]:SetPoint("TOPLEFT", self.itemButtons[i-ncols], "BOTTOMLEFT", 0, -hgap)
        else
            self.itemButtons[i]:SetPoint("TOPLEFT", self.itemButtons[i-1]:GetName(), "TOPRIGHT", wgap, 0)
        end

        if i <= self.size then
            itemButton:Show()
        else
            itemButton:Hide()
        end
    end

    local nrows = ceil(self.size / ncols)
    local w, h = self.itemButtons[1]:GetSize()

    self:SetWidth(29 + ncols * w + (ncols-1) * wgap)
    self:SetHeight(105 + nrows * h + (nrows-1) * hgap)
end

function LiteBagFrame_Update(self)

    -- It might be better to detach these from _Update and call them
    -- explicitly from any event that might change the number or
    -- layout of the buttons.

    LiteBagFrame_SetupItemButtons(self)
    LiteBagFrame_LayoutFrame(self)

    if not self:IsShown() then return end

    LiteBagFrame_AttachSearchBox(self)

    LiteBagFrame_UpdateItemButtons(self)

    -- This is a temporary ugly hack.
    for i = 1,8 do
        local b = _G[self:GetName().."BagButton"..i]
        if self.bagIDs[i] then
            b:SetID(self.bagIDs[i])
            LiteBagBagButton_Update(b)
            b:Show()
        else
            b:Hide()
        end
    end
end