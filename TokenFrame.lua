--[[----------------------------------------------------------------------------

  LiteBag/Tokens.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- Mostly copied from BackpackTokenFrame_Update in Blizzard_TokenUI.lua

function LiteBagTokensFrame_Update(self)
    local watchButton
    local name, count, icon, currencyID

    self.shouldShow = false
    for i = 1,MAX_WATCHED_TOKENS do
        name, count, icon, currencyID = GetBackpackCurrencyInfo(i)
        watchButton = _G[self:GetName()..'Token'..i]
        if name then
            watchButton.icon:SetTexture(icon)
            watchButton.count:SetText(count <= 99999 and count or '*')
            watchButton.currencyID = currencyID
            watchButton:Show()
            self.shouldShow = true
        else
            watchButton:Hide()
        end
    end
    if self.shouldShow then
        self:Show()
    else
        self:Hide()
    end
end

-- It might be simpler to watch event CURRENCY_DISPLAY_UPDATE instead.
-- Don't replace the function because parts of the TokenFrame rely on
-- the BackpackTokenFrame even though it's hidden.

function LiteBagTokensFrame_OnLoad(self)
    hooksecurefunc(
            'BackpackTokenFrame_Update',
            function () LiteBagTokensFrame_Update(self) end
        )
end

function LiteBagTokensFrame_OnShow(self)
    LiteBagTokensFrame_Update(self)
end
