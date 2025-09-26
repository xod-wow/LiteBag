--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Expansion/Expansion.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

local TextsByButton = {}

local function Update(button, bag, slot)
    if TextsByButton[button] == nil then
        TextsByButton[button] = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmallOutline")
        TextsByButton[button]:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)
        local layer, subLayer = button.IconBorder:GetDrawLayer()
        TextsByButton[button]:SetDrawLayer(layer, subLayer + 1)
    end

    if LB.GetGlobalOption("showExpansion") then
        local id = C_Container.GetContainerItemID(bag, slot)

        if id then
            local expansionID = select(15, C_Item.GetItemInfo(id))
            if expansionID then
                -- local name = GetExpansionName(expansionID)
                TextsByButton[button]:SetText(expansionID)
                TextsByButton[button]:Show()
                return
            end
        end
    end
    TextsByButton[button]:Hide()
end

-- LiteBag
LB.RegisterHook('LiteBagItemButton_Update', Update, true)
