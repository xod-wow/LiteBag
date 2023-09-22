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

-- Because we don't override CloseX due to taint issues, we have to have some
-- way of telling CloseAllWindows() / pressing escape that something was closed
-- so it doesn't show the menu. Hide and Show this along with the backpack
-- frame to achieve that.

local specialCloser = CreateFrame('Frame', 'LiteBagSpecialCloser', hiddenParent)
table.insert(UISpecialFrames, specialCloser:GetName())

local REPLACEMENT_GLOBALS = {

    OpenBag =
        function (id)
            LB.GlobalDebug('OpenBag %d', id)
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            if LiteBagBackpack:OpenToBag(id) then
                return
            end
        end,

    ToggleBag =
        function (id)
            LB.GlobalDebug('ToggleBag %d', id)
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            ToggleBackpack()
        end,

    OpenBackpack =
         function ()
            LB.GlobalDebug('OpenBackpack')
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            LiteBagBackpack:Show()
        end,

    ToggleBackpack =
        function ()
            LB.GlobalDebug('ToggleBackpack')
            -- if not ContainerFrame_AllowedToOpenBags() then return end
            if LiteBagBackpack:IsShown() then
                CloseAllBags()
            else
                OpenBackpack()
            end
        end,

    OpenAllBags =
        function (frame, forceUpdate)
            LB.GlobalDebug('OpenAllBags %s', frame and frame:GetName() or "NONE")
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

    ToggleAllBags =
        function ()
            LB.GlobalDebug('ToggleAllBags')
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

--[[
    ContainerFrameUtil_GetShownFrameForID =
        function (id)
            if LiteBagBackpackPanel:IsShown() and LiteBagBackpackPanel:MatchesBagID(id) then
                return LiteBagBackpackPanel, 1
            end
        end,
]]

}

local HOOKED_GLOBALS = {

    -- The return values here are not used, but retain them anyway

    CloseAllBags =
        function (frame, forceUpdate)
            LB.GlobalDebug('CloseAllBags %s', frame and frame:GetName() or "NONE")
            if frame and frame:GetName() ~= FRAME_THAT_OPENED_BAGS then
                return false
            end
            FRAME_THAT_OPENED_BAGS = nil

            local wasShown = CloseBackpack()
            EventRegistry:TriggerEvent("ContainerFrame.CloseAllBags");
            return wasShown
        end,

    CloseBackpack =
        function ()
            LB.GlobalDebug('CloseBackpack')
            local wasShown = LiteBagBackpack:IsShown()
            LiteBagBackpack:Hide()
            return wasShown
        end,

    CloseBag =
        function (id)
            LB.GlobalDebug('CloseBag %d', id)
            return CloseBackpack()
        end,
}

local function ReplaceGlobals()
    for n, f in pairs(REPLACEMENT_GLOBALS) do
        _G[n] = f
    end
    for n, f in pairs(HOOKED_GLOBALS) do
        hooksecurefunc(n, f)
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

    -- PlayerInteractionManager has somehow copied BankFrame_Open such that
    -- hooking it doesn't work, so get creative.

    LiteBagBank:HookScript('OnShow',
        function () HideUIPanel(BankFrame) BankFrame:Show() end)
    LiteBagBank:HookScript('OnHide',
        function () BankFrame:Hide() end)
end

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

function LB.Manager:ReplaceBlizzard()
    HideBlizzardBags()
    HideBlizzardBank()
    ReplaceGlobals()

    -- See the note about LiteBagSpecialCloser earlier
    hooksecurefunc(LiteBagBackpack, 'Show', function () specialCloser:Show() end)
    hooksecurefunc(LiteBagBackpack, 'Hide',
        function () RunNextFrame(function () specialCloser:Hide() end) end)

    -- Force show the Bag Buttons in Edit Mode
    EventRegistry:RegisterCallback("EditMode.Enter",
        function () LB.Manager:ManageBlizzardBagButtons(true) end)
    EventRegistry:RegisterCallback("EditMode.Exit",
        function () LB.Manager:ManageBlizzardBagButtons() end)
end

function LB.Manager:CanManageBagButtons()
    if BagsBar then
        if BagsBar:GetParent() ~= UIParent and BagsBar:GetParent() ~= hiddenParent then
            return false
        end
    else
        for _, b in MainMenuBarBagManager:EnumerateBagButtons() do
            if b:GetParent() ~= MicroButtonAndBagsBar and b:GetParent() ~= hiddenParent then
                return false
            end
        end
    end
    return true
end

function LB.Manager:ManageBlizzardBagButtons(editMode)
    if self:CanManageBagButtons() then
        local show = editMode or not LB.GetGlobalOption('hideBlizzardBagButtons')
        if BagsBar then
            local newParent = show and UIParent or hiddenParent
            BagsBar:SetShown(show)
            BagsBar:SetParent(newParent)
        else
            local newParent = show and MicroButtonAndBagsBar or hiddenParent
            for _, bagButton in MainMenuBarBagManager:EnumerateBagButtons() do
                bagButton:SetShown(show)
                bagButton:SetParent(newParent)
            end
            BagBarExpandToggle:SetShown(show)
            BagBarExpandToggle:SetParent(newParent)
        end
    end
end

-- This is a bit of an arms race with other addon authors who want to hook
-- the bags too, try to hook later than them all.
-- Also register here some other open/close events I liked.

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
        self:CallInitializeHooks()
        self:ReplaceBlizzard()
        self:ManageBlizzardBagButtons()
        self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
        self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')
        LB.db:RegisterCallback('OnOptionsModified',
            function () self:ManageBlizzardBagButtons() end)
    end
end

LB.Manager:RegisterEvent('PLAYER_LOGIN')
LB.Manager:SetScript('OnEvent', LB.Manager.OnEvent)

--@debug@
_G.LB = LB
--@end-debug@
