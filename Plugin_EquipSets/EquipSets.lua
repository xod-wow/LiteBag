--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Equipsets/EquipSets.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

  Adds:
    self.eqTexture1/2/3/4 (Texture level=ARTWORK/1)
        Textures shown when the item is part of one of the first
        four EquipmentSets.

----------------------------------------------------------------------------]]--

local function ContainerItemIsPartOfEquipmentSet(bag, slot, i)
    local _,equipSetNames = GetContainerItemEquipmentSetInfo(bag, slot)

    if not equipSetNames then return end

    local name = GetEquipmentSetInfo(i)
    for _,n in ipairs({ strsplit(", " , equipSetNames) }) do
        if n == name then return true end
    end
    return false

end

local function Update(button)
    local bag = button:GetParent():GetID()
    local slot = button:GetID()

    for i = 1,4 do
        local tex = button["eqTexture"..i]
        if LiteBag_GetGlobalOption("HideEquipsetIcon") == nil and
           ContainerItemIsPartOfEquipmentSet(bag, slot, i) then
            tex:Show()
        else
            tex:Hide()
        end
    end
end

local texData = {
    [1] = {
        point = "BOTTOMRIGHT",
        coords = { 0.0, 0.5, 0.0, 0.5 }
    },
    [2] = {
        point = "BOTTOMLEFT",
        coords = { 0.5, 1.0, 0.0, 0.5 },
    },
    [3] = {
        point = "TOPLEFT",
        coords = { 0.5, 1.0, 0.5, 1.0 },
    },
    [4] = {
        point = "TOPRIGHT",
        coords = { 0.0, 0.5, 0.5, 1.0 },
    },

local function AddTextures(b)
    for i = 1,4 do
        local n = button:GetName() .. "eqTexture" .. i
        local tex = b:CreateTexture(n, "ARTWORK", "LiteBagEquipSetsTexture", 1)
        tex:SetSize(16, 16)
        tex:SetPoint(texData[i].point, b, "CENTER")
        tex:SetTexCoords(unpack(texData[i].coords))
    end
end

hooksecurefunc("LiteBagItemButton_OnLoad", function (b) AddTextures(b) end)
hooksecurefunc("LiteBagItemButton_Update", function (b) Update(b) end)
