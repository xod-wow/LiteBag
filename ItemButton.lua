--[[----------------------------------------------------------------------------

  LiteBag/ItemButton.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

LiteBagItemButtonMixin = {}

function LiteBagItemButtonMixin:OnLoad()
    ContainerFrameItemButtonMixin.OnLoad(self)
    self.UpdateTooltip = self.OnEnter
    -- This is for BankFrameItemButton_OnEnter
    self.GetInventorySlot = ButtonInventorySlot
end

function LiteBagItemButtonMixin:OnEnter(...)
    local bag = self:GetBagID()
    if bag == Enum.BagIndex.Bank then
        BankFrameItemButton_OnEnter(self, ...)
    else
        ContainerFrameItemButtonMixin.OnEnter(self, ...)
    end
end

function LiteBagItemButtonMixin:SetBagID(id)
    -- Do nothing, avoid taint? This only works because the Blizzard
    -- ContainerFrameItemButtonMixin:GetBagID() looks up the ID of
    -- the parent if .bagID isn't set.
    LB.Print('%s:SetBagID(%d) THIS IS BAD, please tell the addon author what you were doing when this happened', self:GetName(), id)
end

--[[
/run LBI:GenerateFrame()
/run SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME, false)
/dump GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME)
]]

