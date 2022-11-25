--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Anima/Anima.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local function Update(self)
    if not C_Item.IsAnimaItemByID then return end
    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info and C_Item.IsAnimaItemByID(info.itemID) then
        local color = ITEM_QUALITY_COLORS[info.quality]
        -- self.IconOverlay:SetVertexColor(color.r, color.g, color.b)
        self.IconOverlay:SetAtlas('ConduitIconFrame-Corners')
        self.IconOverlay:Show()
    end
end

LB.RegisterHook('LiteBagItemButton_Update', Update)
