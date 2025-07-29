--[[----------------------------------------------------------------------------

  LiteBag/Core.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

LB.Manager = CreateFrame('Frame', "LiteBagManager", UIParent)

local InitializeHooks = {}

function LB.Manager:RegisterInitializeHook(f)
    table.insert(InitializeHooks, f)
end

function LB.Manager:CallInitializeHooks()
    for _,f in ipairs(InitializeHooks) do
        f()
    end
end


local function HookBlizzardBank()
    local hookedButtons = {}
    local function hook(self)
        for itemButton in self:EnumerateValidItems() do
            if not hookedButtons[itemButton] then
                hooksecurefunc(itemButton, 'Refresh',
                    function (itemButton)
                        LB.CallHooks('LiteBagItemButton_Update', itemButton)
                    end)
                hookedButtons[itemButton] = true
            end
        end
    end
    hooksecurefunc(BankPanel, 'GenerateItemSlotsForSelectedTab', hook)
end

local BlizzardContainerFrames = {
    ContainerFrameCombinedBags,
    ContainerFrame1,
    ContainerFrame2,
    ContainerFrame3,
    ContainerFrame4,
    ContainerFrame5,
    ContainerFrame6,
}

local function HookBlizzardBags()
    for _, f in ipairs(BlizzardContainerFrames) do
        hooksecurefunc(f, 'UpdateItems',
            function (self)
                for _, itemButton in self:EnumerateValidItems() do
                    LB.CallHooks('LiteBagItemButton_Update', itemButton)
                end
            end)
    end
end

-- register here some other open/close events I liked.

function LB.Manager:OnEvent(event, ...)
    if LB.db then LB.EventDebug(self, event, ...) end
    if event == 'PLAYER_INTERACTION_MANAGER_FRAME_SHOW' then
        local type = ...
        if type == Enum.PlayerInteractionType.GuildBanker then
            OpenAllBags()
        end
    elseif event == 'PLAYER_INTERACTION_MANAGER_FRAME_HIDE' then
        local type = ...
        if type == Enum.PlayerInteractionType.GuildBanker then
            CloseAllBags()
        end
    elseif event == 'PLAYER_LOGIN' then
        LB.InitializeOptions()
        LB.InitializeGUIOptions()
        LB.PatchCombinedBags()
        HookBlizzardBags()
        HookBlizzardBank()
        self:CallInitializeHooks()
        self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
        self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')
    end
end

LB.Manager:RegisterEvent('PLAYER_LOGIN')
LB.Manager:SetScript('OnEvent', LB.Manager.OnEvent)

--@debug@
_G.LB = LB
--@end-debug@
