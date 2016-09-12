--[[----------------------------------------------------------------------------

  LiteBag/Tokens.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- Mostly copied from BackpackTokenFrame_Update in Blizzard_TokenUI.lua

function LiteBagTokensFrame_Update(self)
    local n = 0
    for i = 1,MAX_WATCHED_TOKENS do
        local name, count, icon, currencyID = GetBackpackCurrencyInfo(i)
        local tokenFrame = _G[self:GetName().."Token"..i]
        if name then
            tokenFrame.icon:SetTexture(icon)
            if count <= 99999 then
                tokenFrame.count:SetText(count)
            else
                tokenFrame.count:SetText("*")
            end
            tokenFrame.currencyID = currencyID
            tokenFrame:Show()
            n = n + 1
        else
            tokenFrame:Hide()
        end
    end
    if n > 0 then
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
    LiteBagTokens_Update(self)
end
