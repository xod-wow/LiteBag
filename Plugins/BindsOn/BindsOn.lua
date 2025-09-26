--[[----------------------------------------------------------------------------

  LiteBag/Plugin_BindsOn/BindsOn.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

local L = LB.Localize

-- If there's no translation use these icons. No idea what a good icon for
-- BoE would be though.

local PetIconString = [[|TInterface\CURSOR\WildPetCapturable:14|t]]

local WarText = L["War"]
local BoEText = L["BoE"]
local PetText = rawget(L, 'Pet') or PetIconString
local NoBindText = false

-- Map tooltip text to display text, from BindsWhen by phanx
-- Looks through the first five tooltip left texts for these keys.

local TextForBind = {
    [ITEM_ACCOUNTBOUND]        =        BRIGHTBLUE_FONT_COLOR:WrapTextInColorCode( WarText ),
    [ITEM_BNETACCOUNTBOUND]    =        BRIGHTBLUE_FONT_COLOR:WrapTextInColorCode( WarText ),
    [ITEM_BIND_TO_ACCOUNT]     =        BRIGHTBLUE_FONT_COLOR:WrapTextInColorCode( WarText ),
    [ITEM_BIND_TO_BNETACCOUNT] =        BRIGHTBLUE_FONT_COLOR:WrapTextInColorCode( WarText ),
    [ITEM_ACCOUNTBOUND_UNTIL_EQUIP] =   GREEN_FONT_COLOR:WrapTextInColorCode( WarText ),
    [ITEM_BIND_ON_EQUIP]       =        GREEN_FONT_COLOR:WrapTextInColorCode( BoEText ),
    [ITEM_BIND_ON_USE]         =        GREEN_FONT_COLOR:WrapTextInColorCode( BoEText ),
    [ITEM_SOULBOUND]           =        false,
    [ITEM_BIND_ON_PICKUP]      =        false,
    [TOOLTIP_BATTLE_PET]       =        HIGHLIGHT_FONT_COLOR:WrapTextInColorCode( PetText ),
}

local lineQuery = { Enum.TooltipDataLineType.ItemBinding }

local function GetInfoBindText(info)
    if not info then
        return
    end

    if info.battlePetSpeciesID then
        return TextForBind[TOOLTIP_BATTLE_PET]
    end

    local bindingLines = TooltipUtil.FindLinesFromData(lineQuery, info)

    if #bindingLines == 1 then
        local text = bindingLines[1].leftText
        if text and TextForBind[text] ~= nil then
            return TextForBind[text]
        end
    end

    return NoBindText
end

local function GetButtonItemTooltipInfo(button)
    if button.GetBankTabID then
        return C_TooltipInfo.GetBagItem(button:GetBankTabID(), button:GetContainerSlotID())
    else
        return C_TooltipInfo.GetBagItem(button:GetBagID(), button:GetID())
    end
end

local BindTextsByButton = {}

local fontFile, fontSize = GameFontNormalSmall:GetFont()

local function Update(button)
    if BindTextsByButton[button] == nil then
        BindTextsByButton[button] = button:CreateFontString(nil, "OVERLAY")
        BindTextsByButton[button]:SetFont(fontFile, fontSize, "THICKOUTLINE")
        BindTextsByButton[button]:SetPoint("TOPRIGHT", button, "TOPRIGHT", 3, 2)
        BindTextsByButton[button]:SetJustifyH("RIGHT")
    end

    if LB.GetGlobalOption("showBindsOn") then
        local info = GetButtonItemTooltipInfo(button)
        local text = GetInfoBindText(info)

        if text then
            BindTextsByButton[button]:SetText(text)
            BindTextsByButton[button]:Show()
            return
        end
    end
    BindTextsByButton[button]:Hide()
end

-- LiteBag
LB.RegisterHook('LiteBagItemButton_Update', Update, true)
