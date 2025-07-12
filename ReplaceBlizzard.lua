--[[----------------------------------------------------------------------------

  LiteBag/ReplaceBlizzard.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

local hiddenBagParent = CreateFrame('Frame')

local function ReplaceBlizzardInventory()
    local hideFunc =
        function (caller)
            LiteBagInventory:Hide()
        end
    local showFunc = function (caller)
            if LiteBagInventory:IsShown() then
                LiteBagFrame_Update(LiteBagInventory)
            else
                LiteBagInventory:Show()
            end
        end
    local toggleFunc = function (caller)
            if LiteBagInventory:IsShown() then
                LiteBagInventory:Hide()
            else
                LiteBagInventory:Show()
            end
        end

    hiddenBagParent:Hide()

    -- Turn the Blizzard frames off
    for i=1, NUM_CONTAINER_FRAMES do
        local f = _G['ContainerFrame'..i]
        f:SetParent(hiddenBagParent)
        f:UnregisterAllEvents()
    end
                
    -- Override or hook various Blizzard UI functions to operate on our
    -- frame instead.
    OpenBackpack = showFunc
    OpenAllBags = showFunc

    ToggleBag = toggleFunc
    ToggleAllBags = toggleFunc

    hooksecurefunc('CloseBackpack', hideFunc)
    hooksecurefunc('CloseAllBags', hideFunc)

    -- This one is called when you click on a loot popup and you have
    -- one of those items in your bag already.
    OpenBag = showFunc

    -- These are the bag buttons in the menu bar at the bottom which are
    -- highlighted when their particular bag is opened.
    BagSlotButton_UpdateChecked = function () end
end

local hiddenBankParent = CreateFrame('Frame')

local function ReplaceBlizzardBank()

    -- The reagent bank in WoW 6.0 changed UseContainerItem() to have a
    -- fourth argument which is true/false 'should we put this thing into
    -- the reagent bank', which ContainerFrameItemButton_OnClick sets with
    --      BankFrame:IsShown() and (BankFrame.selectedTab == 2)
    -- Since we can't override the secure OnClick handler and we can't
    -- change BankFrame without tainting, we have to reparent it, hide it
    -- via the parent, and set its selectedTab and hide/show manually in sync
    -- with ours.

    hiddenBankParent:Hide()
    BankFrame:SetParent(hiddenBankParent)
    BankFrame:ClearAllPoints()
    BankFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
    BankFrame:UnregisterAllEvents()
    BankFrame:SetScript('OnShow', function () end)
    BankFrame:SetScript('OnHide', function () end)

    LiteBagBank:HookScript('OnShow', function () BankFrame:Show() end)
    LiteBagBank:HookScript('OnHide', function () BankFrame:Hide() end)
end


-- Guild bank in classic has a bug if the search event triggers because
-- it listens but doesn't handle it properly.
local function FixClassicGuildBankSearch()
    if GuildBankFrame then
        for _, tab in ipairs(GuildBankFrame.BankTabs) do
            tab.Button:SetScript('OnEvent', nil)
        end
    end
end

local function ReplaceBlizzard()
    ReplaceBlizzardInventory()
    ReplaceBlizzardBank()
    FixClassicGuildBankSearch()

    -- Some other addons either replace the open functions themselves after
    -- us and cause the bag frames to show.
    for i=1, NUM_CONTAINER_FRAMES do
        local f = _G['ContainerFrame'..i]
        f:SetScript('OnShow', function (self)
                self:Hide()
                LiteBagInventory:Show()
                ReplaceBlizzardInventory()
            end)
        f:SetScript('OnHide', nil)
    end
end

-- This is a bit of an arms race with other addon authors who want to hook
-- the bags too, try to hook later than them all.

local replacer = CreateFrame('Frame', UIParent)
replacer:RegisterEvent('PLAYER_LOGIN')
replacer:RegisterEvent('GUILDBANKFRAME_OPENED')
replacer:RegisterEvent('GUILDBANKFRAME_CLOSED')
replacer:RegisterEvent('PLAYER_LOGIN')
replacer:RegisterEvent('ADDON_LOADED')
replacer:SetScript('OnEvent',
    function (self, event, ...)
        if event == 'GUILDBANKFRAME_OPENED' then
            OpenAllBags()
        elseif event == 'GUILDBANKFRAME_CLOSED' then
            CloseAllBags()
        elseif event == 'PLAYER_LOGIN' then
            ReplaceBlizzard()
        elseif event == 'ADDON_LOADED' then
            local addonName = ...
            if addonName == 'Blizzard_GuildBankUI' then
                FixClassicGuildBankSearch()
                self:UnregisterEvent('ADDON_LOADED')
            end
        end
end)
