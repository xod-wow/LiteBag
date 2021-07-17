--[[----------------------------------------------------------------------------

  LiteBag/Print.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

--[[----------------------------------------------------------------------------
    Printing to active chat frame.
----------------------------------------------------------------------------]]--

function LiteBag_Print(...)
    local f = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME
    f:AddMessage('|cff00ff00LiteBag:|r ' .. format(...))
end

function LiteBag_Debug(...)
    if LB.Options:GetGlobalOption('DebugEnabled') then
        -- Outputs into the first chat tab instead of LiteBag_Print. Even I
        -- find the spam too much.
        DEFAULT_CHAT_FRAME:AddMessage('|cff00ff00LiteBag:|r ' .. format(...))
    end
end
