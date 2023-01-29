--[[----------------------------------------------------------------------------

  LiteBag/Plugin_IconBorder/IconBorder.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local function Update(self)
    -- Where did 651080 suddenly come from?
    if self.IconBorder:GetTexture() ~= [[Interface\Common\WhiteIconFrame]] and
       self.IconBorder:GetTexture() ~= 651080 then
        return
    end

    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local quality = select(4, GetContainerItemInfo(bag, slot))
    if not quality then return end

    local minQuality = tonumber(LB.Options:GetGlobalOption("ThickerIconBorder"))

    if quality and minQuality and quality >= minQuality then
        self.IconBorder:SetTexture([[Interface\Addons\LiteBag\Plugin_IconBorder\IconBorder]])
    end

    self.IconBorder:Show()
    self.IconBorder:SetVertexColor(ITEM_QUALITY_COLORS[quality].color:GetRGB())
end

LB.RegisterHook('LiteBagItemButton_Update', Update)
