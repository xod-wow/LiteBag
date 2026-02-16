--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Anima/Anima.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

local L = LB.Localize

local function Update(self, bag, slot)
    if not LB.GetGlobalOption('showAnima') then return end
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info and C_Item.IsAnimaItemByID(info.itemID) then
        -- local color = ITEM_QUALITY_COLORS[info.quality]
        -- self.IconOverlay:SetVertexColor(color.r, color.g, color.b)
        self.IconOverlay:SetAtlas('ConduitIconFrame-Corners')
        self.IconOverlay:Show()
    end
end

local options = {
    showAnima = {
        type = "toggle",
        width = "full",
        name = L["Display icon corners on Anima items."],
    }
}

LB.AddPluginOptions(options)

LB.RegisterHook('LiteBagItemButton_Update', Update, true)
