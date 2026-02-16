--[[----------------------------------------------------------------------------

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

-- All of the search boxes propagate text into each other so it doesn't
-- matter which one we use.
local BagItemSearchBox = BagItemSearchBox

local MATCHES = {}

MATCHES.ILevel = {
    check =
        function (text)
            local n = text:match('^(%d+)$')
            if n then return { '=', tonumber(n) } end

            local op, val = text:match('^([<>]=?)(%d+)$')
            if op and val then return { op, tonumber(val) } end

            local min, max = text:match('^(%d+)%-(%d+)$')
            if min and max then
                return { 'in', tonumber(min), tonumber(max) }
            end
        end,
    apply =
        function (link, op, ...)
            local equipLoc = select(4, C_Item.GetItemInfoInstant(link))
            if equipLoc == 'INVTYPE_NON_EQUIP_IGNORE' then
                return false
            end

            local ilevel = C_Item.GetDetailedItemLevelInfo(link)
            if not ilevel then
                return false
            end

            local val1, val2 = ...
            if op == '=' then
                return ilevel == val1
            elseif op == '>' then
                return ilevel > val1
            elseif op == '>=' then
                return ilevel >= val1
            elseif op == '<' then
                return ilevel < val1
            elseif op == '<=' then
                return ilevel <= val1
            elseif op == 'in' then
                return (ilevel >= val1 and ilevel <= val2)
            else
                return false
            end
        end
}

local function UpdateItemButton(button, result)
    if result == false then
        button:UpdateItemContextOverlayTextures(ItemButtonConstants.ContextMatch.Standard)
        button.ItemContextOverlay:Show()
    elseif result == true then
        button.ItemContextOverlay:Hide()
    end
end

local buttonsToUpdate = {}
local timerCB

-- This is a mildly ugly for effiency, and calculates which function applies
-- based on the text once, then uses it on all the buttons.

local function GetFuncForText(text)
    for _, match in pairs(MATCHES) do
        local args = match.check(text)
        if args then
            return function (link) return match.apply(link, unpack(args)) end
        end
    end
end

local function RunUpdateQueue()
    local text = BagItemSearchBox:GetText()
    local func = GetFuncForText(text)
    if func then
        local matchingBagIDs = {}
        for button, bagSlot in pairs(buttonsToUpdate) do
            local bag, slot = unpack(bagSlot)
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link then
                local result = func(link)
                UpdateItemButton(button, result)
                matchingBagIDs[bag] = result
            end
        end
        if next(matchingBagIDs) then
            for _, bagButton in ipairs(LB.BagsManager.bagButtons) do
                local bag = bagButton:GetID()
                bagButton.searchOverlay:SetShown(not matchingBagIDs[bag])
            end
        end
    end

    buttonsToUpdate = {}
    timerCB = nil
end

local function QueueButtonForUpdate(button, bag, slot)
    buttonsToUpdate[button] = { bag, slot }
    if not timerCB then
        timerCB = C_Timer.NewTimer(0, RunUpdateQueue)
    end
end

LB.RegisterHook('LiteBagItemButton_Update', QueueButtonForUpdate, true)
LB.Manager:AddPluginEvent('INVENTORY_SEARCH_UPDATE')
