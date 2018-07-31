--[[----------------------------------------------------------------------------

  LiteBag/Plugin_BindsOn/BindsOn.lua

  Copyright 2013-2018 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- Map tooltip text to display text, from BindsWhen by phanx
--

local BoAText = BATTLENET_FONT_COLOR_CODE .. "BoA" .. FONT_COLOR_CODE_CLOSE
local BoEText = ORANGE_FONT_COLOR_CODE .. "BoE" .. FONT_COLOR_CODE_CLOSE
local BoPText = false
local NoBindText = false

local TextForBind = {
    [ITEM_ACCOUNTBOUND]        = BoAText,
    [ITEM_BNETACCOUNTBOUND]    = BoAText,
    [ITEM_BIND_TO_ACCOUNT]     = BoAText,
    [ITEM_BIND_TO_BNETACCOUNT] = BoAText,
    [ITEM_BIND_ON_EQUIP]       = BoEText,
    [ITEM_BIND_ON_USE]         = BoEText,
    [ITEM_SOULBOUND]           = false,
    [ITEM_BIND_ON_PICKUP]      = false,
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

local function GetBindText(bag, slot)
    scanTip:SetBagItem(bag, slot)
    for i = 1, 5 do
        local text = scanTip.leftTexts[i]:GetText()
        if not text then break end
        if strmatch(text, USE_COLON) then break end -- recipes
        if TextForBind[text] ~= nil
            then return TextForBind[text]
        end
    end
    return NoBindText
end

local function Update(button)
    if not button.bindsOnText then
        button.bindsOnText = button:CreateFontString(nil, "ARTWORK", "GameFontNormalOutline")
        button.bindsOnText:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    end

    if not LiteBag_GetGlobalOption("ShowBindsOnText") or not button.hasItem then
        button.bindsOnText:Hide()
        return
    end

    local bag = button:GetParent():GetID()
    local slot = button:GetID()

    local text = GetBindText(bag, slot)
    if not text then
        button.bindsOnText:Hide()
        return
    end

    button.bindsOnText:SetText(text)
    button.bindsOnText:Show()
end

hooksecurefunc("LiteBagItemButton_Update", function (b) Update(b) end)
