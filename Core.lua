--[[----------------------------------------------------------------------------

  LiteBag/Core.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize


--[[ LiteBagManager --------------------------------------------------------]]--


LB.Manager = CreateFrame('Frame', "LiteBagManager", UIParent)

-- register here some other open/close events I liked.

function LB.Manager:Initialize()
    LB.InitializeOptions()
    LB.InitializeGUIOptions()
    LB.PatchBags()
    LB.PatchBank()
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')
end

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
        self:Initialize()
    else
        LB.CallHooksOnBags()
        LB.CallHooksOnBank()
    end
end

function LB.Manager:AddPluginEvent(e)
    self:RegisterEvent(e)
end

LB.Manager:RegisterEvent('PLAYER_LOGIN')
LB.Manager:SetScript('OnEvent', LB.Manager.OnEvent)

--@debug@
_G.LB = LB
--@end-debug@
