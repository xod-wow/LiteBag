--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Equipsets/EquipSets.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

  Adds:
    self.LiteBagEQTexture1/2/3/4 (Texture level=ARTWORK/1)
        Textures shown when the item is part of one of the first
        four EquipmentSets.

----------------------------------------------------------------------------]]--

local _, LB = ...

local EquipSetState = CreateFrame('Frame')

-- A partial opposite of EquipmentManager_UnpackLocation that only handles
-- bags and bank.

function EquipSetState.PackContainerItemLocation(bag, slot)
   if bag >= Enum.BagIndex.Backpack and bag <= Enum.BagIndex.ReagentBag then
      return ITEM_INVENTORY_LOCATION_PLAYER
      + ITEM_INVENTORY_LOCATION_BAGS
      + bit.lshift(bag, ITEM_INVENTORY_BAG_BIT_OFFSET)
      + slot
   end

   if bag >= Enum.BagIndex.CharacterBankTab_1 and bag <= Enum.BagIndex.CharacterBankTab_6 then
      return ITEM_INVENTORY_LOCATION_BANK
      + ITEM_INVENTORY_LOCATION_BAGS
      + bit.lshift(bag - ITEM_INVENTORY_BANK_BAG_OFFSET, ITEM_INVENTORY_BAG_BIT_OFFSET)
      + slot
   end
end

function EquipSetState:GetEquipmentSetMemberships(bag, slot)
    local l = self.PackContainerItemLocation(bag, slot)
    return self.state[l]
end

function EquipSetState:UpdateSet(n, id)
    local locations = C_EquipmentSet.GetItemLocations(id) or {}
    for _, l in pairs(locations) do
        if bit.band(l, ITEM_INVENTORY_LOCATION_BANK+ITEM_INVENTORY_LOCATION_BAGS) ~= 0 then
            self.state[l] = self.state[l] or {}
            self.state[l][n] = true
        end
    end
end

function EquipSetState:Update()
    if self.isDirty then
        self.state = {}
        for i, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
            self:UpdateSet(i, id)
        end
        self.isDirty = nil
    end
end

function EquipSetState:MarkDirty()
    self.isDirty = true
end

EquipSetState:SetScript('OnEvent', EquipSetState.MarkDirty)
EquipSetState:RegisterEvent('PLAYER_LOGIN')
EquipSetState:RegisterEvent('BAG_UPDATE_DELAYED')
EquipSetState:RegisterEvent('BANKFRAME_OPENED')
EquipSetState:RegisterEvent('BANKFRAME_CLOSED')
EquipSetState:RegisterEvent('EQUIPMENT_SETS_CHANGED')

local texData = {
    [1] = {
        parentKey = "LiteBagEQTexture1",
        anchor = { "CENTER", "CENTER", -10, 10 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 1, 0.5, 0.5 },
    },
    [2] = {
        parentKey = "LiteBagEQTexture2",
        anchor = { "CENTER", "CENTER", 0, 10 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 1, 0.67, 0.0 },
    },
    [3] = {
        parentKey = "LiteBagEQTexture3",
        anchor = { "CENTER", "CENTER", 10, 10 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 1, 1, 0.33 },
    },
    [4] = {
        parentKey = "LiteBagEQTexture4",
        anchor = { "CENTER", "CENTER", -10, 0 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 0.0, 1, 0.0 },
    },
    [5] = {
        parentKey = "LiteBagEQTexture5",
        anchor = { "CENTER", "CENTER", 0, 0 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 0.33, 0.67, 1 },
    },
    [6] = {
        parentKey = "LiteBagEQTexture6",
        anchor = { "CENTER", "CENTER", 10, 0 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 0.0, 0.33, 1 },
    },
    [7] = {
        parentKey = "LiteBagEQTexture7",
        anchor = { "CENTER", "CENTER", -10, -10 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 1, 0.33, 1 },
    },
    [8] = {
        parentKey = "LiteBagEQTexture8",
        anchor = { "CENTER", "CENTER", 0, -10 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 0.67, 0.0, 1 }
    },
    [9] = {
        parentKey = "LiteBagEQTexture9",
        anchor = { "CENTER", "CENTER", 10, -10 },
        level = "ARTWORK",
        subLevel = 1,
        color = { 1, 1, 1 },
    },
}

local ButtonTextures = {}

local function MakeTexture(frame, td)
    local tex = frame:CreateTexture(
                    nil,
                    td.level,
                    "LiteBagEquipSetsTexture",
                    td.subLevel
                )
    tex:ClearAllPoints()
    local point, relPoint, xOff, yOff = unpack(td.anchor)
    tex:SetPoint(point, frame, relPoint, xOff, yOff)
    tex:SetSize(11, 11)
    tex:SetVertexColor(unpack(td.color))
    return tex
end

local function GetTexture(frame, i, td)
    if not ButtonTextures[frame] or not ButtonTextures[frame][i] then
        ButtonTextures[frame] = ButtonTextures[frame] or {}
        ButtonTextures[frame][i] = MakeTexture(frame, td)
    end
    return ButtonTextures[frame][i]
end

local function Update(button, bag, slot)
    EquipSetState:Update()

    local memberships = EquipSetState:GetEquipmentSetMemberships(bag, slot)
    for i,td in ipairs(texData) do
        local tex = GetTexture(button, i, td)
        if LB.GetGlobalOption("showEquipmentSets") and memberships and memberships[i] == true then
            tex:Show()
        else
            tex:Hide()
        end
    end
end

-- This is assuming the EQUIPMENT_SETS_CHANGED for the state manager above
-- runs before the itembutton hooks. It does because we know they add and
-- remove OnShow/OnHide and this is therefore first, but I don't think
-- Blizzard guarantee that behavior.

-- C_Container.GetContainerItemEquipmentSetInfo does seem to kind of work now
-- but not all that helpfully because it returns a human-readable string with
-- ambiguous parsing.

LB.RegisterHook('LiteBagItemButton_Update', Update, true)
LB.Manager:AddPluginEvent("EQUIPMENT_SETS_CHANGED")
