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

local addonName, LB = ...

local EquipSetState = CreateFrame('Frame')

-- A partial opposite of EquipmentManager_UnpackLocation that only handles
-- bags and bank.

function EquipSetState.PackContainerItemLocation(bag, slot)
    local location = ITEM_INVENTORY_LOCATION_PLAYER

    if bag == Enum.BagIndex.Bank then
        return location + ITEM_INVENTORY_LOCATION_BANK + slot
    elseif bag > NUM_TOTAL_BAG_FRAMES then -- Bank Bag
        location = location + ITEM_INVENTORY_LOCATION_BANK + ITEM_INVENTORY_LOCATION_BAGS
        bag = bag - NUM_TOTAL_BAG_FRAMES
    else
        location = location + ITEM_INVENTORY_LOCATION_BAGS
    end
    location = location + bit.lshift(bag, ITEM_INVENTORY_BAG_BIT_OFFSET) + slot
    return location
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
    self.state = {}
    for i, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        if i < 4 then
            self:UpdateSet(i, id)
        end
    end
end

EquipSetState:SetScript('OnEvent', EquipSetState.Update)
EquipSetState:RegisterEvent('PLAYER_LOGIN')
EquipSetState:RegisterEvent('BAG_UPDATE_DELAYED')
EquipSetState:RegisterEvent('BANKFRAME_OPENED')
EquipSetState:RegisterEvent('BANKFRAME_CLOSED')
EquipSetState:RegisterEvent('EQUIPMENT_SETS_CHANGED')

local texData = {
    [1] = {
        parentKey = "LiteBagEQTexture1",
        point = "BOTTOMRIGHT",
        level = "ARTWORK",
        subLevel = 1,
        coords = { 0.0, 0.5, 0.0, 0.5 }
    },
    [2] = {
        parent = "LiteBagEquipSetsTexture",
        parentKey = "LiteBagEQTexture2",
        point = "BOTTOMLEFT",
        level = "ARTWORK",
        subLevel = 1,
        coords = { 0.5, 1.0, 0.0, 0.5 },
    },
    [3] = {
        parentKey = "LiteBagEQTexture3",
        point = "TOPLEFT",
        level = "ARTWORK",
        subLevel = 1,
        coords = { 0.5, 1.0, 0.5, 1.0 },
    },
    [4] = {
        parentKey = "LiteBagEQTexture4",
        point = "TOPRIGHT",
        level = "ARTWORK",
        subLevel = 1,
        coords = { 0.0, 0.5, 0.5, 1.0 },
    },
}

local function MakeTexture(frame, td)
    local tex = frame:CreateTexture(
                    frame:GetName() .. td.parentKey,
                    td.level,
                    "LiteBagEquipSetsTexture",
                    td.subLevel
                )
    tex:ClearAllPoints()
    tex:SetPoint(td.point, frame, "CENTER")
    tex:SetSize(16, 16)
    tex:SetTexCoord(unpack(td.coords))
    return tex
end

local function AddTextures(b)
    for i, td in ipairs(texData) do
        b[td.parentKey] = MakeTexture(b, td)
    end
end

local function Update(button)
    local bag = button:GetParent():GetID()
    local slot = button:GetID()

    if not button.LiteBagEQTexture1 then
        AddTextures(button)
    end

    local memberships = EquipSetState:GetEquipmentSetMemberships(bag, slot)

    for i,td in ipairs(texData) do
        local tex = button[td.parentKey]
        if LB.GetGlobalOption("HideEquipsetIcon") == nil and
           memberships and memberships[i] == true then
            tex:Show()
        else
            tex:Hide()
        end
    end
end

-- This is assuming the EQUIPMENT_SETS_CHNAGED for the state manager above
-- runs before the itembutton hooks. It does because we know they add and
-- remove OnShow/OnHide and this is therefore first, but I don't think
-- Blizzard guarantee that behavior.

-- Hopefully someday C_Container.GetContainerItemEquipmentSetInfo will work
-- and all of this state handling crap can be removed.

LB.RegisterHook('LiteBagItemButton_Update', Update)
LB.AddPluginEvent("EQUIPMENT_SETS_CHANGED")
