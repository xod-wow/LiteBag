--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Equipsets/EquipSets.lua

  Copyright 2013-2018 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- Map tooltip text to display text, from BindsWhen by phanx
--
local BoA = "|cffe6cc80BoA|r" -- heirloom item color
local BoE = "|cff1eff00BoE|r" -- uncommon item color
local BoP = false -- not displayed
local BindsNever = false

local textForBind = {
        [ITEM_ACCOUNTBOUND]        = BoA,
        [ITEM_BNETACCOUNTBOUND]    = BoA,
        [ITEM_BIND_TO_ACCOUNT]     = BoA,
        [ITEM_BIND_TO_BNETACCOUNT] = BoA,
        [ITEM_BIND_ON_EQUIP]       = BoE,
        [ITEM_BIND_ON_USE]         = BoE,
        [ITEM_SOULBOUND]           = BoP,
        [ITEM_BIND_ON_PICKUP]      = BoP,
}

local scanTip = CreateFrame("GameTooltip", "LiteBagBindOnScanTooltip")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
scanTip.leftTexts = { }
scanTip.rightTexts = { }

for i = 1, 5 do
    local left = scanTip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local right = scanTip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scanTip:AddFontStrings(left, right)
    scanTip.leftTexts[i] = left
    scanTip.rightTexts[i] = right
end

local function GetBindText(button)
    local bag = button:GetParent():GetID()
    local slot = button:GetID()
    scanTip:SetBagItem(bag, slot)

    for i = 1, 5 do
        local text = scanTip.leftTexts[i]:GetText()
        if not text then break end
        if strmatch(text, USE_COLON) then break end -- recipes
        if textForBind[text] ~= nil
            then return textForBind[text]
        end
    end
    return BindsNever
end

local function Update(button)
    if not button.bindsOnText then
        button.bindsOnText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightOutline")
        button.bindsOnText:SetPoint("TOP", button, "TOP", 0, -2)
    end

    if not LiteBag_GetGlobalOption("ShowBindsOnText") or not button.hasItem then
        button.bindsOnText:Hide()
        return
    end

    local text = GetBindText(button)
    if not text then
        button.bindsOnText:Hide()
        return
    end

    button.bindsOnText:SetText(text)
    button.bindsOnText:Show()
end

hooksecurefunc("LiteBagItemButton_Update", function (b) Update(b) end)
