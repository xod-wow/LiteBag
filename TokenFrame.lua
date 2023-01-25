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
    if C_CurrencyInfo.GetBackpackCurrencyInfo then
        for i = 1, MAX_WATCHED_TOKENS do
            local watchButton = self.Tokens[i]
            local currencyInfo = C_CurrencyInfo.GetBackpackCurrencyInfo(i)

            if currencyInfo then
                local count = currencyInfo.quantity
                watchButton.icon:SetTexture(currencyInfo.iconFileID)

                local currencyText = BreakUpLargeNumbers(count)
                if strlenutf8(currencyText) > 5 then
                    currencyText = AbbreviateNumbers(count)
                end

                watchButton.count:SetText(currencyText)
                watchButton.currencyID = currencyInfo.currencyTypesID
                watchButton:Show()

                self.shouldShow = true
                self.numWatchedTokens = i
            else
                watchButton:Hide()
                if i == 1 then
                    self.shouldShow = nil
                end
            end
        end
    elseif GetBackpackCurrencyInfo and LiteBagInventoryTokenFrameToken1 then
        for i = 1, MAX_WATCHED_TOKENS do
            local watchButton = _G["LiteBagInventoryTokenFrameToken"..i]
            if watchButton then
                local name, count, icon, itemID = GetBackpackCurrencyInfo(i)

                if name then
                    watchButton.icon:SetTexture(icon)

                    local currencyText = BreakUpLargeNumbers(count)
                    if strlenutf8(currencyText) > 5 then
                        currencyText = AbbreviateNumbers(count)
                    end

                    watchButton.count:SetText(currencyText)
                    watchButton.currencyID = itemID
                    watchButton:Show()

                    self.shouldShow = true
                    self.numWatchedTokens = i
                else
                    watchButton:Hide()
                    if i == 1 then
                        self.shouldShow = nil
                    end
                end
            end
        end
    else
        return
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
end

function LiteBagTokenFrameMixin:OnShow()
    self:Update()
end
