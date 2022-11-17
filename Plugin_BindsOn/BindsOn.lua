--[[----------------------------------------------------------------------------

  LiteBag/Plugin_BindsOn/BindsOn.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

-- If there's no translation use these icons. No idea what a good icon for
-- BoE would be though.

local PetIconString = [[|TInterface\CURSOR\WildPetCapturable:14|t]]
local BoAIconString = [[|TInterface\Addons\LiteBag\Plugin_BindsOn\Blizz:12:32|t]]

local BoAText = rawget(L, 'BoA') or BoAIconString
local BoEText = L["BoE"]
local PetText = rawget(L, 'Pet') or PetIconString
local NoBindText = false

-- Map tooltip text to display text, from BindsWhen by phanx
-- Looks through the first five tooltip left texts for these keys.

local TextForBind = {
    [ITEM_ACCOUNTBOUND]        = BATTLENET_FONT_COLOR:WrapTextInColorCode( BoAText ),
    [ITEM_BNETACCOUNTBOUND]    = BATTLENET_FONT_COLOR:WrapTextInColorCode( BoAText ),
    [ITEM_BIND_TO_ACCOUNT]     = BATTLENET_FONT_COLOR:WrapTextInColorCode( BoAText ),
    [ITEM_BIND_TO_BNETACCOUNT] = BATTLENET_FONT_COLOR:WrapTextInColorCode( BoAText ),
    [ITEM_BIND_ON_EQUIP]       = GREEN_FONT_COLOR:WrapTextInColorCode( BoEText ),
    [ITEM_BIND_ON_USE]         = GREEN_FONT_COLOR:WrapTextInColorCode( BoEText ),
    [ITEM_SOULBOUND]           = false,
    [ITEM_BIND_ON_PICKUP]      = false,
    [TOOLTIP_BATTLE_PET]       = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode( PetText ),
}

local lineQuery = { Enum.TooltipDataLineType.ItemBinding }

local function GetBindText(bag, slot)
    local _, info

    if bag == Enum.BagIndex.Bank then
        local id = BankButtonIDToInvSlotID(slot)
        info = C_TooltipInfo.GetInventoryItem('player', id)
    elseif bag == Enum.BagIndex.ReagentBank then
        local id = ReagentBankButtonIDToInvSlotID(slot)
        info = C_TooltipInfo.GetInventoryItem('player', id)
    else
        info = C_TooltipInfo.GetBagItem(bag, slot)
    end

    TooltipUtil.SurfaceArgs(info)

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

local function Update(button)
    if not button.LiteBagBindsOnText then
        button.LiteBagBindsOnText = button:CreateFontString(nil, "ARTWORK", "GameFontNormalOutline")
        button.LiteBagBindsOnText:SetPoint("TOP", button, "TOP", 0, -2)
    end

    if not LB.Options:GetGlobalOption("ShowBindsOnText") or not button.hasItem then
        button.LiteBagBindsOnText:Hide()
        return
    end

    local bag = button:GetBagID()
    local slot = button:GetID()

    local text = GetBindText(bag, slot)
    if not text then
        button.LiteBagBindsOnText:Hide()
    else
        button.LiteBagBindsOnText:SetText(text)
        button.LiteBagBindsOnText:Show()
    end
end

LB.RegisterHook('LiteBagItemButton_Update', Update)
