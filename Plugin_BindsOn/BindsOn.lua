--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Equipsets/EquipSets.lua

  Copyright 2013-2018 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- Map tooltip text to display text, from BindsWhen by phanx
--

local TextForBind = {
        [ITEM_ACCOUNTBOUND]        = "BoA",
        [ITEM_BNETACCOUNTBOUND]    = "BoA",
        [ITEM_BIND_TO_ACCOUNT]     = "BoA",
        [ITEM_BIND_TO_BNETACCOUNT] = "BoA",
        [ITEM_BIND_ON_EQUIP]       = "BoE",
        [ITEM_BIND_ON_USE]         = "BoE",
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

    local quality = select(4, GetContainerItemInfo(bag, slot))
    if quality > LE_ITEM_QUALITY_COMMON then
        button.bindsOnText:SetVertexColor(
                BAG_ITEM_QUALITY_COLORS[quality].r,
                BAG_ITEM_QUALITY_COLORS[quality].g,
                BAG_ITEM_QUALITY_COLORS[quality].b,
                1.0
            )
    else
        button.bindsOnText:SetVertexColor(1.0, 1.0, 1.0, 1.0)
    end
    button.bindsOnText:Show()
end

hooksecurefunc("LiteBagItemButton_Update", function (b) Update(b) end)
