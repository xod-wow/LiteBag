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

function LB.Print(...)
    local f = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME
    f:AddMessage('|cff00ff00LiteBag:|r ' .. format(...))
end

function LB.Debug(...)
    if LB.Options:GetGlobalOption('DebugEnabled') then
        -- Outputs into the first chat tab instead of LiteBag_Print. Even I
        -- find the spam too much.
        DEFAULT_CHAT_FRAME:AddMessage('|cff00ff00LiteBag:|r ' .. format(...))
    end
end

function LB.EventDebug(frame, event, ...)
    if LB.db.profile.eventFilter[event] then return end
    if LB.Options:GetGlobalOption('EventDebugEnabled') then
        -- Outputs into the first chat tab instead of LiteBag_Print. Even I
        -- find the spam too much.
        local msg = frame:GetName() .. " " .. string.join(' ', event, ...)
        DEFAULT_CHAT_FRAME:AddMessage('|cff00ff00LiteBag:|r ' .. msg)
    end
end
