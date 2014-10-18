--[[----------------------------------------------------------------------------

  LiteBag/LiteBagTemplate.lua

  Copyright 2013-2014 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

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
    local border = _G[self:GetName() .. "TokenFrameBorder"]
    local n = 0
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
            n = n + 1
        else
            tokenFrame:Hide()
        end
    end
    if n > 0 then
        border:Show()
    else
        border:Hide()
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
        if bag ~= BACKPACK_CONTAINER and bag ~= BANK_CONTAINER then
            self.dummyContainerFrames[bag].slotID = ContainerIDToInventoryID(bag)
        end
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
        self.Tab1:Show()
        self.Tab2:Show()
        PanelTemplates_SetNumTabs(self, 2)
        PanelTemplates_SetTab(self, 1)
        self.selectedTab = 1
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

    -- It might be simpler to watch event CURRENCY_DISPLAY_UPDATE instead.
    -- Don't replace the function because parts of the TokenFrame rely on
    -- the BackpackTokenFrame even though it's hidden.

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
--
-- Some events that fire a lot have specific code to just update the
-- bags or changes that they fire for (where possible).  Others are
-- rare enough it's OK to call LiteBagFrame_Update to do everything.
function LiteBagFrame_OnEvent(self, event, ...)
    -- if self.isBank then print("DEBUG " .. event) end

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
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_HIDE" then
        local bag = ...
        if LiteBagFrame_IsMyBag(self, bag) then
            LiteBagFrame_UpdateQuality(self)
        end
    elseif event == "BAG_UPDATE" or event == "BAG_NEW_ITEMS_UPDATED" then
        local bag = ...
        if LiteBagFrame_IsMyBag(self, bag) then
            LiteBagFrame_Update(self)
        end
    elseif event == "BAG_CLOSED" then
        -- BAG_CLOSED fires when you drag a bag out of a slot but for the
        -- bank GetContainerNumSlots doesn't return the updated size yet,
        -- so we have to wait until BAG_UPDATE_DELAYED fires.
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
    elseif event == "PLAYER_MONEY" then
        -- The only way to notice we bought a bag button is to see we
        -- spent money while the bank is open.
        if self.isBank then
            LiteBagFrame_UpdateBagButtons(self)
        end
    elseif event == "ITEM_LOCK_CHANGED" then
        local bag, slot = ...
        if bag and slot and LiteBagFrame_IsMyBag(self, bag) then
            LiteBagFrame_UpdateLocked(self)
        end
    elseif event == "EQUIPMENT_SETS_CHANGED" then
        LiteBagFrame_Update(self)
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


-- This updates the highlights for the bag open/closed buttons that are
-- part of the MainMenuBar at the bottom in the default Blizzard interface.

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

local function GetDistanceFromBackpackDefault(self)
    local defaultX = UIParent:GetRight() - CONTAINER_OFFSET_X
    local defaultY = UIParent:GetBottom() + CONTAINER_OFFSET_Y
    local selfX = self:GetRight()
    local selfY = self:GetBottom()
    return sqrt((defaultX-selfX)^2 + (defaultY-selfY)^2)
end

-- CONTAINER_OFFSET_* are globals that are updated by the Blizzard
-- code depending on which (default) action bars are shown.

function LiteBagFrame_SetPosition(self)
    if self:IsUserPlaced() then return end
    self:ClearAllPoints()
    self:SetClampedToScreen(nil)
    self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y)
end

function LiteBagFrame_StartMoving(self)
    if self.isBank then return end
    self:StartMoving()
    self:SetClampedToScreen(true)
end

function LiteBagFrame_StopMoving(self)
    if self.isBank then return end
    self:StopMovingOrSizing()

    -- Snap back into place
    if self.isBackpack and GetDistanceFromBackpackDefault(self) < 64 then
        self:SetUserPlaced(false)
        LiteBagFrame_SetPosition(self)
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
    self:UnregisterEvent("EQUIPMENT_SETS_CHANGED")
    self:UnregisterEvent("PLAYER_MONEY")
    self:UnregisterEvent("BAG_NEW_ITEMS_UPDATED")
    self:UnregisterEvent("BAG_SLOT_FLAGS_UPDATED")
    self:UnregisterEvent("MERCHANT_SHOW")
    self:UnregisterEvent("MERCHANT_CLOSED")

    -- Judging by the code in FrameXML/ContainerFrame.lua items are tagged
    -- by the server as "new" in some cases, and you're supposed to clear
    -- the new flag after you see it the first time.
    LiteBagFrame_ClearNewItems(self)

    LiteBagFrame_SetMainMenuBarButtons(self, false)
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
    self:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
    self:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_CLOSED")

    local titleText =_G[self:GetName() .. "TitleText"]

    if self.isBackpack then
        LiteBagFrame_SetPosition(self)

        -- WTB backpack icon
        self.portrait:SetTexture("Interface\\MERCHANTFRAME\\UI-BuyBack-Icon")
        titleText:SetText(GetBagName(self.bagIDs[1]))
    elseif self.isBank then
        SetPortraitTexture(self.portrait, "npc")
        titleText:SetText(UnitName("npc"))
    else
        LiteBagFrame_SetPosition(self)
        SetBagPortraitTexture(self.portrait, self.bagIDs[1])
        titleText:SetText(GetBagName(self.bagIDs[1]))
    end

    LiteBagFrame_Update(self)
    LiteBagFrame_UpdateTokens(self)

    LiteBagFrame_SetMainMenuBarButtons(self, true)

    PlaySound("igBackPackOpen")
end

function LiteBagFrame_AttachSearchBox(self)
    local box, button
    if self.isBank then
        box = BankItemSearchBox
        button = BankItemAutoSortButton
    else
        box = BagItemSearchBox
        button = BagItemAutoSortButton
    end

    box:SetParent(self)
    box:SetPoint("TOPRIGHT", self, "TOPRIGHT", -38, -35)
    box.anchorBag = self
    box:Show()

    button:SetParent(self)
    button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -7, -32)
    button.anchorBag = self
    button:Show()
end

function LiteBagFrame_UpdateBagButtons(self)
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

function LiteBagFrame_ClearNewItems(self)
    for i = 1, self.size do
        -- C_NewItems.ClearAll()
        LiteBagItemButton_ClearNewItem(self.itemButtons[i])
    end
end

function LiteBagFrame_UpdateItemButtons(self)
    -- First set the families (bag type) of the parent containers
    for id,dummy in pairs(self.dummyContainerFrames) do
        if dummy.slotID then
            local bagItemID = GetInventoryItemID("player", dummy.slotID)
            dummy.family = GetItemFamily(bagItemID)
        end
    end

    -- Then update all the buttons
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

function LiteBagFrame_UpdateQuality(self)
    for i = 1, self.size do
        LiteBagItemButton_UpdateQuality(self.itemButtons[i])
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
            itemButton:SetPoint("TOPLEFT", name, "TOPLEFT", 14, -70)
        elseif i % ncols == 1 then
            itemButton:SetPoint("TOPLEFT", self.itemButtons[i-ncols], "BOTTOMLEFT", 0, -hgap)
        else
            itemButton:SetPoint("TOPLEFT", self.itemButtons[i-1], "TOPRIGHT", wgap, 0)
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

    LiteBagFrame_UpdateBagButtons(self)
end

function LiteBagFrame_TabOnClick(self)
    if self:GetID() == 2 then
        UIErrorsFrame:AddMessage("LiteBag doesn't support Reagent Bank yet...", 1.0, 0.1, 0.1, 1.0)
    end
end
