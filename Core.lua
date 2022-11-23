--[[----------------------------------------------------------------------------

  LiteBag/Core.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

local FRAME_THAT_OPENED_BAGS = nil

local hiddenParent = CreateFrame('Frame')
hiddenParent:Hide()

local REPLACEMENT_GLOBALS = {

    OpenBag =
        function (id)
            LB.Debug('OpenBag %d', id)
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            if LiteBagBackpack:OpenToBag(id) then
                return
            end
        end,

    CloseBag =
        function (id)
            LB.Debug('CloseBag %d', id)
            return CloseBackpack()
        end,

    ToggleBag =
        function (id)
            LB.Debug('ToggleBag %d', id)
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            ToggleBackpack()
        end,

    OpenBackpack =
         function ()
            LB.Debug('OpenBackpack')
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            LiteBagBackpack:Show()
        end,

    CloseBackpack =
        function ()
            LB.Debug('CloseBackpack')
            local wasShown = LiteBagBackpack:IsShown()
            LiteBagBackpack:Hide()
            return wasShown
        end,

    ToggleBackpack =
        function ()
            LB.Debug('ToggleBackpack')
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            if LiteBagBackpack:IsShown() then
                CloseAllBags()
            else
                OpenBackpack()
            end
        end,

    OpenAllBags =
        function (frame, forceUpdate)
            LB.Debug('OpenAllBags %s', frame and frame:GetName() or "NONE")
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            if LiteBagBackpack:IsShown() then
                if forceUpdate then
                    local panel = LiteBagBackpack:GetCurrentPanel()
                    if panel.Update then panel:UpdateIfShown() end
                end
                return
            end
            if LiteBagBackpack:IsShown() then
                return
            end
            if frame and not FRAME_THAT_OPENED_BAGS then
                FRAME_THAT_OPENED_BAGS = frame:GetName()
            end

            OpenBackpack()
            EventRegistry:TriggerEvent("ContainerFrame.OpenAllBags");
        end,

    CloseAllBags =
        function (frame, forceUpdate)
            LB.Debug('CloseAllBags %s', frame and frame:GetName() or "NONE")
            if frame and frame:GetName() ~= FRAME_THAT_OPENED_BAGS then
                return false
            end
            FRAME_THAT_OPENED_BAGS = nil

            local wasShown = CloseBackpack()
            EventRegistry:TriggerEvent("ContainerFrame.CloseAllBags");
            return wasShown
        end,

    ToggleAllBags =
        function ()
            LB.Debug('ToggleAllBags')
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            if LiteBagBackpack:IsShown() then
                CloseAllBags()
            else
                OpenAllBags()
            end
        end,

    IsBagOpen =
        function (id)
            if LiteBagBackpack:IsShown() then
                return LiteBagBackpack:GetCurrentPanel():MatchesBagID(id)
            elseif LiteBagBank:IsShown() then
                return LiteBagBank:GetCurrentPanel():MatchesBagID(id)
            end
        end,

    -- The ReagentBag and Professions tutorials need this.
    -- I don't feel good about this at all. I see taint on the horizon.

    ContainerFrameUtil_GetShownFrameForID =
        function (id)
            if LiteBagBackpackPanel:IsShown() and LiteBagBackpackPanel:MatchesBagID(id) then
                return LiteBagBackpackPanel, 1
            end
        end,
}

local function ReplaceGlobals()
    for n, f in pairs(REPLACEMENT_GLOBALS) do
        _G[n] = f
    end
end

local function HideBlizzardBags()

    -- Turn the Blizzard frames off
    for i=1, NUM_CONTAINER_FRAMES do
        local f = _G['ContainerFrame'..i]
        f:SetParent(hiddenParent)
        f:UnregisterAllEvents()
    end
    ContainerFrameCombinedBags:SetParent(hiddenParent)
    ContainerFrameCombinedBags:UnregisterAllEvents()
end

local function HideBlizzardBank()

    -- The reagent bank in WoW 6.0 changed UseContainerItem() to have a
    -- fourth argument which is true/false 'should we put this thing into
    -- the reagent bank', which ContainerFrameItemButton_OnClick sets with
    --      BankFrame:IsShown() and (BankFrame.selectedTab == 2)
    -- Since we can't override the secure OnClick handler and we can't
    -- change BankFrame without tainting, we have to reparent it, hide it
    -- via the parent, and set its selectedTab and hide/show manually in sync
    -- with ours.

    BankFrame:SetParent(hiddenParent)
    BankFrame:ClearAllPoints()
    BankFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
    BankFrame:UnregisterAllEvents()
    BankFrame:SetScript('OnShow', function () end)
    BankFrame:SetScript('OnHide', function () end)

    LiteBagBank:HookScript('OnShow', function () BankFrame:Show() end)
    LiteBagBank:HookScript('OnHide', function () BankFrame:Hide() end)
end

-- This is a bit of an arms race with other addon authors who want to hook
-- the bags too, try to hook later than them all.
-- Also register here some other open/close events I liked.

local LiteBagManager = CreateFrame('Frame', 'LiteBagManager', UIParent)

function LiteBagManager:ReplaceBlizzard()
    HideBlizzardBags()
    HideBlizzardBank()
    ReplaceGlobals()
end

function LiteBagManager:ManageBlizzardBagButtons()
    local show = not LB.GetGlobalOption('hideBlizzardBagButtons')
    for _, bagButton in MainMenuBarBagManager:EnumerateBagButtons() do
        bagButton:SetShown(show)
        bagButton:SetParent(show and MicroButtonAndBagsBar or hiddenParent)
    end
    BagBarExpandToggle:SetShown(show)
end

function LiteBagManager:OnEvent(event, ...)
    -- As far as I can tell this doesn't work. Why?
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
        self:ReplaceBlizzard()
        self:ManageBlizzardBagButtons()
        self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
        self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')
        LB.db.RegisterCallback(self, 'OnOptionsModified', self.ManageBlizzardBagButtons)
    end
end

LiteBagManager:RegisterEvent('PLAYER_LOGIN')
LiteBagManager:SetScript('OnEvent', LiteBagManager.OnEvent)

--@debug@
_G.LB = LB
--@end-debug@
