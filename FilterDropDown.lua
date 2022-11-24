--[[----------------------------------------------------------------------------

  LiteBag/FilterDropdown.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

  A copy of the bag filtering drop down, because using Blizzards causes taint.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local Initialize

do
    local function OnBagFilterClicked(bagID, filterID, value)
        C_Container.SetBagSlotFlag(bagID, filterID, value)
        ContainerFrameSettingsManager:SetFilterFlag(bagID, filterID, value)
    end

    local function AddButtons_BagCleanup(bagID, level)
        local info = LibDD:UIDropDownMenu_CreateInfo()

        info.text = BAG_FILTER_CLEANUP
        info.isTitle = 1
        info.notCheckable = 1
        LibDD:UIDropDownMenu_AddButton(info, level)

        info = LibDD:UIDropDownMenu_CreateInfo()
        info.text = BAG_FILTER_IGNORE
        info.func = function(_, _, _, value)
            if bagID == Enum.BagIndex.Bank then
                C_Container.SetBankAutosortDisabled(not value)
            elseif bagID == Enum.BagIndex.Backpack then
                C_Container.SetBackpackAutosortDisabled(not value)
            else
                C_Container.SetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort, not value)
            end
        end

        if bagID == Enum.BagIndex.Bank then
            info.checked = C_Container.GetBankAutosortDisabled()
        elseif bagID == Enum.BagIndex.Backpack then
            info.checked = C_Container.GetBackpackAutosortDisabled()
        else
            info.checked = C_Container.GetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort)
        end

        LibDD:UIDropDownMenu_AddButton(info, level)
    end

    local function AddButtons_BagFilters(bagID, level)
        if not ContainerFrame_CanContainerUseFilterMenu(bagID) then
            return
        end

        local info = LibDD:UIDropDownMenu_CreateInfo()
        info.text = BAG_FILTER_ASSIGN_TO
        info.isTitle = 1
        info.notCheckable = 1
        LibDD:UIDropDownMenu_AddButton(info, level)

        info = LibDD:UIDropDownMenu_CreateInfo()
        local activeBagFilter = ContainerFrameSettingsManager:GetFilterFlag(bagID)

        for i, flag in ContainerFrameUtil_EnumerateBagGearFilters() do
            info.text = BAG_FILTER_LABELS[flag]
            info.checked = activeBagFilter == flag
            info.func = function(_, _, _, value)
                return OnBagFilterClicked(bagID, flag, not value)
            end

            LibDD:UIDropDownMenu_AddButton(info, level)
        end
    end

    local bagNames =
    {
        [-1] = BANK,
        [0] = BAG_NAME_BACKPACK,
        [1] = BAG_NAME_BAG_1,
        [2] = BAG_NAME_BAG_2,
        [3] = BAG_NAME_BAG_3,
        [4] = BAG_NAME_BAG_4,
        [5] = "Reagent Bag",
    }

    local function bankName(i)
        return BANK .. " " .. BAG_NAME_BAG_1:gsub('1', i-NUM_TOTAL_BAG_FRAMES)
    end

    setmetatable(bagNames, { __index=function(t, k) return bankName(k) end })

    Initialize = function(self, level)
        if level == 1 then
            local parent = self:GetParent()

            for _, bag in ipairs(parent.bagFrames) do
                local i = bag:GetID()
                local info = LibDD:UIDropDownMenu_CreateInfo()
                info.text = bagNames[i]
                info.hasArrow = true
                info.notCheckable = true
                info.value = i
                LibDD:UIDropDownMenu_AddButton(info, level)
            end
        elseif level == 2 then
            if L_UIDROPDOWNMENU_MENU_VALUE ~= Enum.BagIndex.Bank then
                AddButtons_BagFilters(L_UIDROPDOWNMENU_MENU_VALUE, level)
            end
            AddButtons_BagCleanup(L_UIDROPDOWNMENU_MENU_VALUE, level)
        end
    end
end

LiteBagFilterDropDownMixin = {}

function LiteBagFilterDropDownMixin:OnLoad()
    LibDD:Create_UIDropDownMenu(self)
    LibDD:UIDropDownMenu_SetInitializeFunction(self, Initialize)
    LibDD:UIDropDownMenu_SetDisplayMode(self, "MENU")
end

LiteBagPortraitButtonMixin = {}

function LiteBagPortraitButtonMixin:OnMouseDown()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    LibDD:ToggleDropDownMenu(1, nil, self:GetParent().FilterDropDown, self, 0, 0)
end

function LiteBagPortraitButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    if self:GetParent():MatchesBagID(Enum.BagIndex.Backpack) then
        GameTooltip:SetText(BACKPACK_TOOLTIP, 1.0, 1.0, 1.0)
        GameTooltip:AddLine(CLICK_BAG_SETTINGS)
        GameTooltip:Show()
    elseif self:GetParent():MatchesBagID(Enum.BagIndex.Bank) then
        GameTooltip:SetText(BANK, 1.0, 1.0, 1.0)
        GameTooltip:AddLine(CLICK_BAG_SETTINGS)
        GameTooltip:Show()
    end
end

function LiteBagPortraitButtonMixin:OnLeave()
    GameTooltip_Hide()
end
