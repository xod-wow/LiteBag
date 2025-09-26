--[[----------------------------------------------------------------------------

  LiteBag/Plugin_IconBorder/IconBorder.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

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

-- LiteBag
LB.RegisterHook('LiteBagItemButton_Update', Update, true)
