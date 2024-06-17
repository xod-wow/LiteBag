--[[----------------------------------------------------------------------------

  LiteBag/Tokens.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]] --

local addonName, LB = ...

-- Mostly copied from BackpackTokenFrame_Update in Blizzard_TokenUI.lua

LiteBagTokenFrameMixin = {}

function LiteBagTokenFrameMixin:Update()
    for i = 1, MAX_WATCHED_TOKENS do
        local watchButton = _G[ self:GetName().."Token"..i]

        local name, count, icon, itemID = GetBackpackCurrencyInfo(i)
        if name then
            if itemID == Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID then
                -- Honor points. This seems logically pointless but it's what Blizz does.
                local factionGroup = UnitFactionGroup("player")
                if factionGroup then
                    watchButton.icon:SetTexture(icon)
                    watchButton.icon:SetTexCoord( 0.03125, 0.59375, 0.03125, 0.59375 )
                end
            else
                watchButton.icon:SetTexture(icon)
                watchButton.icon:SetTexCoord(0, 1, 0, 1)
            end

            -- Improve on Blizzard's handling of big numbers
            local currencyText = BreakUpLargeNumbers(count)
            if strlenutf8(currencyText) > 5 then
                currencyText = AbbreviateNumbers(count)
            end

            watchButton.count:SetText(currencyText)
            watchButton.itemID = itemID
            watchButton:Show()

            self.shouldShow = true
            self.numWatchedTokens = i
        else
            watchButton:Hide()
            if i == 1 then
                self.shouldShow = nil
            end
            watchButton.itemID = nil
        end
    end
    self:SetShown(self.shouldShow)
end

-- It might be simpler to watch event CURRENCY_DISPLAY_UPDATE instead.
-- Don't replace the function because parts of the TokenFrame rely on
-- the BackpackTokenFrame even though it's hidden.

function LiteBagTokenFrameMixin:OnLoad()
    hooksecurefunc(
        "BackpackTokenFrame_Update",
        function()
            self:Update()
        end
    )
    if C_EventUtils.IsEventValid('CURRENCY_DISPLAY_UPDATE') then
        self:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
    end
end

function LiteBagTokenFrameMixin:OnEvent()
    self:Update()
end

function LiteBagTokenFrameMixin:OnShow()
    self:Update()
end
