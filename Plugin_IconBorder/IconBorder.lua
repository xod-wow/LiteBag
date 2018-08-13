--[[----------------------------------------------------------------------------

  LiteBag/Plugin_IconBorder/IconBorder.lua

  Copyright 2013-2018 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local function Update(self)
    if self.IconBorder:GetTexture() ~= [[Interface\Common\WhiteIconFrame]] then
        return
    end

    local minQuality = LiteBag_GetGlobalOption("ThickerIconBorder")
    if not minQuality then
        return
    end

    minQuality = tonumber(minQuality)

    local bag = self:GetParent():GetID()
    local slot = self:GetID()

    local _, _, _, quality, _, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)

    if not quality then
        return
    end

    if quality >= minQuality then
        self.IconBorder:SetTexture([[Interface\Addons\LiteBag\Plugin_IconBorder\IconBorder]])
    end

end

hooksecurefunc("LiteBagItemButton_UpdateQuality", Update)
