--[[----------------------------------------------------------------------------

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

local hiddenParent = CreateFrame('Frame')
hiddenParent:Hide()

--[[ LiteBagManager --------------------------------------------------------]]--


LB.Manager = CreateFrame('Frame', "LiteBagManager", UIParent)

function LB.Manager:CanManageBagButtons()
    if BagsBar then
        if BagsBar:GetParent() ~= UIParent and BagsBar:GetParent() ~= hiddenParent then
            return false
        end
        for _, b in MainMenuBarBagManager:EnumerateBagButtons() do
            if b:GetParent() ~= BagsBar and b:GetParent() ~= hiddenParent then
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

-- register here some other open/close events I liked.

function LB.Manager:Initialize()
    LB.InitializeOptions()
    LB.InitializeGUIOptions()
    LB.BagsManager:Initialize()
    LB.BankManager:Initialize()

    -- Force show the Bag Buttons in Edit Mode
    EventRegistry:RegisterCallback("EditMode.Enter", function () self:ManageBlizzardBagButtons(true) end)
    EventRegistry:RegisterCallback("EditMode.Exit", function () self:ManageBlizzardBagButtons() end)
    self:ManageBlizzardBagButtons()
    LB.db:RegisterCallback('OnOptionsModified', function () self:ManageBlizzardBagButtons() end)

end

function LB.Manager:OnEvent(event, ...)
    if event == 'PLAYER_LOGIN' then
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
