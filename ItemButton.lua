--[[----------------------------------------------------------------------------

  LiteBag/ItemButton.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

function LiteBagItemButton_OnLoad(self)
    self.GetInventorySlot = ButtonInventorySlot
    self.UpdateTooltip = LiteBagItemButton_OnEnter
end

function LiteBagItemButton_OnEnter(self)
    local bag = self:GetParent():GetID()
    if bag == BANK_CONTAINER then
        BankFrameItemButton_OnEnter(self)
    else
        ContainerFrameItemButton_OnEnter(self)
    end
end

