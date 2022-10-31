--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Equipsets/EquipSets.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

  Adds:
    self.LiteBagEQTexture1/2/3/4 (Texture level=ARTWORK/1)
        Textures shown when the item is part of one of the first
        four EquipmentSets.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

-- This is a guess at something I don't really understand, ItemLocations.
-- On one hand this seems pretty inefficient. On the other hand, the Blizzard
-- equivalent makes you use strsplit, so frankly this has to be faster.

local function GetEquipmentSetMemberships(bag, slot)
    local ids = { }

    for i, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local locations = C_EquipmentSet.GetItemLocations(id) or {}
        for _, l in pairs(locations) do
            local lplayer, lbank, lbags, lvoid, lslot, lbag = EquipmentManager_UnpackLocation(l)
            if lbank == true and lbags == false then
                lbag = -1
                lslot = lslot - BankButtonIDToInvSlotID(1) + 1
            end
            if slot == lslot and bag == lbag then
                ids[i] = true
            end
        end
    end
    return ids
end

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

    local memberships = GetEquipmentSetMemberships(bag, slot)

    for i,td in ipairs(texData) do
        local tex = button[td.parentKey]
        if LB.Options:GetGlobalOption("HideEquipsetIcon") == nil and
           memberships[i] == true then
            tex:Show()
        else
            tex:Hide()
        end
    end
end

LB.RegisterHook('LiteBagItemButton_Update', Update)
LB.RegisterUpdateEvent("EQUIPMENT_SETS_CHANGED")
