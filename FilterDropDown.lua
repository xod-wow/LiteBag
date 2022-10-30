--[[----------------------------------------------------------------------------

  LiteBag/FilterDropdown.lua

  Copyright 2022 Mike Battersby

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

    local function AddButtons_BagCleanup(id, level)
        local info = UIDropDownMenu_CreateInfo()

        info.text = BAG_FILTER_CLEANUP
        info.isTitle = 1
        info.notCheckable = 1
        LibDD:UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = BAG_FILTER_IGNORE
        info.func = function(_, _, _, value)
            if id == BANK_CONTAINER then
                SetBankAutosortDisabled(not value)
            elseif id == BACKPACK_CONTAINER then
                SetBackpackAutosortDisabled(not value)
            else
                C_Container.SetBagSlotFlag(id, Enum.BagSlotFlags.DisableAutoSort, not value)
            end
        end

        if id == BANK_CONTAINER then
            info.checked = GetBankAutosortDisabled()
        elseif id == BACKPACK_CONTAINER then
            info.checked = GetBackpackAutosortDisabled()
        else
            info.checked = C_Container.GetBagSlotFlag(id, Enum.BagSlotFlags.DisableAutoSort)
        end

        LibDD:UIDropDownMenu_AddButton(info, level)
    end

    local function AddButtons_BagFilters(bagID, level)
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
    }

    local function bankName(i)
        return BANK .. " " .. BAG_NAME_BAG_1:gsub('1', i-NUM_BAG_FRAMES)
    end

    setmetatable(bagNames, { __index=function(t, k) return bankName(k) end })

    Initialize = function(self, level)
        if level == 1 then
            local parent = self:GetParent()

            local info = LibDD:UIDropDownMenu_CreateInfo()

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
            if L_UIDROPDOWNMENU_MENU_VALUE ~= BANK_CONTAINER then
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
