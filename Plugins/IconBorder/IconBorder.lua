--[[----------------------------------------------------------------------------

  LiteBag/Plugin_IconBorder/IconBorder.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

local L = LB.Localize

local function Update(itemButton, bag, slot)

    -- Where did 651080 suddenly come from?
    if itemButton.IconBorder:GetTexture() ~= [[Interface\Common\WhiteIconFrame]] and
       itemButton.IconBorder:GetTexture() ~= 651080 then
        return
    end

    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not info or not info.quality then return end

    local minQuality = tonumber(LB.GetGlobalOption("thickerIconBorder"))

    if minQuality and info.quality >= minQuality then
        itemButton.IconBorder:SetTexture([[Interface\Addons\LiteBag\Plugins\IconBorder\IconBorder]])
    end
end

local function GetQualityText(i)
    if ITEM_QUALITY_COLORS[i] then
        local desc = _G['ITEM_QUALITY'..i..'_DESC']
        return ITEM_QUALITY_COLORS[i].color:WrapTextInColorCode(desc)
    else
        return NEVER
    end
end

local function IconBorderSorting()
    local out = { }
    for i = Enum.ItemQualityMeta.NumValues-1, 0, -1 do
        table.insert(out, i)
    end
    table.insert(out, false)
    return out
end

local function IconBorderValues()
    local out = {}
    for _,k in ipairs(IconBorderSorting()) do
        out[k] = GetQualityText(k)
    end
    return out
end

local options = {
    thickerIconBorder = {
        type = "select",
        style = "dropdown",
        name = L["Show thicker icon borders for this quality and above."],
        values = IconBorderValues,
        sorting = IconBorderSorting,
    }
}

LB.RegisterHook('LiteBagItemButton_Update', Update, true)
LB.AddPluginOptions(options)
