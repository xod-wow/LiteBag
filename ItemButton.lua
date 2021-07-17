--[[----------------------------------------------------------------------------

  LiteBag/ItemButton.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

LiteBagItemButtonMixin = {}

function LiteBagItemButtonMixin:OnLoad()
    self.GetInventorySlot = ButtonInventorySlot
    self.UpdateTooltip = self.OnEnter
end

function LiteBagItemButtonMixin:OnEnter()
    local bag = self:GetParent():GetID()
    if bag == BANK_CONTAINER then
        BankFrameItemButton_OnEnter(self)
    else
        ContainerFrameItemButton_OnEnter(self)
    end
end

