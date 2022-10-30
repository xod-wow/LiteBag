--[[----------------------------------------------------------------------------

  LiteBag/FilterDropdown.lua

  Copyright 2022 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

  A copy of the bag filtering drop down, because using Blizzards causes taint.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local ContainerFrameFilterDropDownCombined_Initialize

do
    local function ContainerFrame_IsGenericHeldBag(id)
        return id >= 0 and id <= NUM_BAG_FRAMES;
    end

    local function OnBagFilterClicked(bagID, filterID, value)
        C_Container.SetBagSlotFlag(bagID, filterID, value)
        ContainerFrameSettingsManager:SetFilterFlag(bagID, filterID, value)
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
        [0] = BAG_NAME_BACKPACK,
        [1] = BAG_NAME_BAG_1,
        [2] = BAG_NAME_BAG_2,
        [3] = BAG_NAME_BAG_3,
        [4] = BAG_NAME_BAG_4,
    }

    ContainerFrameFilterDropDownCombined_Initialize = function(self, level)
        if level == 1 then
            local info = LibDD:UIDropDownMenu_CreateInfo()

            info.text = BAG_FILTER_TITLE_SORTING
            info.isTitle = 1
            info.notCheckable = 1
            LibDD:UIDropDownMenu_AddButton(info, level)

            for i = 0, NUM_BAG_FRAMES do
                local info = LibDD:UIDropDownMenu_CreateInfo()
                info.text = bagNames[i]
                info.hasArrow = true
                info.notCheckable = true
                info.value = i; -- save off the bag id to use on level 2, it will be stored in the global UIDROPDOWNMENU_MENU_VALUE
                LibDD:UIDropDownMenu_AddButton(info, level)
            end

        elseif level == 2 then
            AddButtons_BagFilters(L_UIDROPDOWNMENU_MENU_VALUE, level)
        end
    end
end

LiteBagFilterDropDownMixin = {}

function LiteBagFilterDropDownMixin:OnLoad()
    LibDD:Create_UIDropDownMenu(self)
    LibDD:UIDropDownMenu_SetInitializeFunction(self, ContainerFrameFilterDropDownCombined_Initialize)
    LibDD:UIDropDownMenu_SetDisplayMode(self, "MENU")
end

LiteBagPortraitButtonMixin = {}

function LiteBagPortraitButtonMixin:OnMouseDown()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    LibDD:ToggleDropDownMenu(1, nil, self:GetParent().FilterDropDown, self, 0, self:GetHeight()/2);
end
