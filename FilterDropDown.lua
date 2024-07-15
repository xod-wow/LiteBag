--[[----------------------------------------------------------------------------

  LiteBag/FilterDropdown.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

  A copy of the bag filtering drop down, because the Blizzard one can't be
  accessed from outside.

  Redone with Blizzard_Menu for 11.0, see
    Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

local function bankName(i)
    return BANK .. " " .. BAG_NAME_BAG_1:gsub('1', i-NUM_TOTAL_BAG_FRAMES)
end

local bagNames = {
    [-1] = BANK,
    [0] = BAG_NAME_BACKPACK,
    [1] = BAG_NAME_BAG_1,
    [2] = BAG_NAME_BAG_2,
    [3] = BAG_NAME_BAG_3,
    [4] = BAG_NAME_BAG_4,
    [5] = L["Reagent Bag"],
}

setmetatable(bagNames, { __index=function(t, k) return bankName(k) end })

-- These are copied with minor fixups from ContainerFrame. Sadly they are not
-- exported and can't be gotten out of there without calling the whole OnLoad.

local function AddButtons_BagFilters(description, bagID)
    if not ContainerFrame_CanContainerUseFilterMenu(bagID) then
        return
    end

    description:CreateTitle(BAG_FILTER_ASSIGN_TO)

    local function IsSelected(flag)
        return C_Container.GetBagSlotFlag(bagID, flag)
    end

    local function SetSelected(flag)
        local value = not IsSelected(flag)
        C_Container.SetBagSlotFlag(bagID, flag, value)
        ContainerFrameSettingsManager:SetFilterFlag(bagID, flag, value)
    end

    for i, flag in ContainerFrameUtil_EnumerateBagGearFilters() do
        local checkbox = description:CreateCheckbox(BAG_FILTER_LABELS[flag], IsSelected, SetSelected, flag)
        checkbox:SetResponse(MenuResponse.Close)
    end
end

local function AddButtons_BagCleanup(description, bagID)
    description:CreateTitle(BAG_FILTER_IGNORE)

    do
        local function IsSelected()
            if bagID == Enum.BagIndex.Bank then
                return C_Container.GetBankAutosortDisabled()
            elseif bagID == Enum.BagIndex.Backpack then
                return C_Container.GetBackpackAutosortDisabled()
            end
            return C_Container.GetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort)
        end

        local function SetSelected()
            local value = not IsSelected()
            if bagID == Enum.BagIndex.Bank then
                C_Container.SetBankAutosortDisabled(value)
            elseif bagID == Enum.BagIndex.Backpack then
                C_Container.SetBackpackAutosortDisabled(value)
            else
                C_Container.SetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort, value)
            end
        end

        local checkbox = description:CreateCheckbox(BAG_FILTER_CLEANUP, IsSelected, SetSelected)
        checkbox:SetResponse(MenuResponse.Close)
    end

    -- ignore junk selling from this bag or backpack
    if bagID ~= Enum.BagIndex.Bank then
        local function IsSelected()
            if bagID == Enum.BagIndex.Backpack then
                return C_Container.GetBackpackSellJunkDisabled()
            end
            return C_Container.GetBagSlotFlag(bagID, Enum.BagSlotFlags.ExcludeJunkSell)
        end

        local function SetSelected()
            local value = not IsSelected()
            if bagID == Enum.BagIndex.Backpack then
                C_Container.SetBackpackSellJunkDisabled(value)
            else
                C_Container.SetBagSlotFlag(bagID, Enum.BagSlotFlags.ExcludeJunkSell, value)
            end
        end

            local checkbox = description:CreateCheckbox(SELL_ALL_JUNK_ITEMS_EXCLUDE_FLAG, IsSelected, SetSelected)
            checkbox:SetResponse(MenuResponse.Close)
        end
end


LiteBagPortraitButtonMixin = {}

function LiteBagPortraitButtonMixin:Initialize()
    local parent = self:GetParent()
    self:SetupMenu(
        function (dropdown, rootDescription)
            rootDescription:SetTag("LITEBAG_FILTER_MENU")
            rootDescription:CreateTitle(BAG_SETTINGS_TOOLTIP)
            rootDescription:CreateButton(SETTINGS, LB.OpenOptions)
            rootDescription:CreateDivider()
            rootDescription:CreateTitle(BAG_FILTER_TITLE_SORTING)

            for _, bagID in ipairs(parent.bagIDs) do
                local submenu = rootDescription:CreateButton(bagNames[bagID])
                AddButtons_BagFilters(submenu, bagID)
                AddButtons_BagCleanup(submenu, bagID)
            end

        end)
end

function LiteBagPortraitButtonMixin:OnEnter()
    local parent = self:GetParent()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    if parent:MatchesBagID(Enum.BagIndex.Backpack) then
        GameTooltip:SetText(BACKPACK_TOOLTIP, 1.0, 1.0, 1.0)
        GameTooltip:AddLine(CLICK_BAG_SETTINGS)
        GameTooltip:Show()
    elseif parent:MatchesBagID(Enum.BagIndex.Bank) then
        GameTooltip:SetText(BANK, 1.0, 1.0, 1.0)
        GameTooltip:AddLine(CLICK_BAG_SETTINGS)
        GameTooltip:Show()
    else
        local id = parent.bagIDs[1]
        local link = GetInventoryItemLink("player", C_Container.ContainerIDToInventoryID(id))
        local name = GetItemInfo(link)
        if name then
            GameTooltip:SetText(name, 1.0, 1.0, 1.0)
            GameTooltip:AddLine(CLICK_BAG_SETTINGS)
            GameTooltip:Show()
        end
    end
end

function LiteBagPortraitButtonMixin:OnLeave()
    GameTooltip_Hide()
end
