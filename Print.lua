--[[----------------------------------------------------------------------------

  LiteBag/Print.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, addonTable = ...

local debugEnabled = true

--[[----------------------------------------------------------------------------
    Printing to active chat frame.
----------------------------------------------------------------------------]]--

local function ActiveChatFrame()
    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i]
        if f and f:IsShown() then return f end
    end
    return DEFAULT_CHAT_FRAME
end

function LiteBag_Print(msg)
    ActiveChatFrame():AddMessage("|cff00ff00LiteBag:|r " .. msg)
end

function LiteBag_SetDebug(onOff)
    if onOff then
        debugEnabled = true
    else
        debugEnabled = false
    end
end

function LiteBag_Debug(fmt, ...)
    if debugEnabled then
        ActiveChatFrame():AddMessage(format(fmt, ...))
    end
end

