--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2013-2015 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, addonTable = ...

function LiteBag_InitializeOptions()
    if not LiteBag_OptionsDB then
        LiteBag_OptionsDB = { }
    end
end

function LiteBag_SetFrameOption(frame, option, value)
    local n = "Frame:" .. frame:GetName()
    if not LiteBag_OptionsDB[n] then
        LiteBag_OptionsDB[n] = { }
    end
    LiteBag_OptionsDB[n][option] = value
end

function LiteBag_GetFrameOption(frame, option)
    local n = "Frame:" .. frame:GetName()
    if LiteBag_OptionsDB[n] then
        return LiteBag_OptionsDB[n][option]
    end
end

function LiteBag_SetGlobalOption(option, value)
    LiteBag_OptionsDB[option] = value
end

function LiteBag_GetGlobalOption(option)
    return LiteBag_OptionsDB[option]
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function (self, event, arg1, ...)
        if event == "ADDON_LOADED" and arg1 == addonName then
            print("Initializing options from ADDON_LOADED handler.")
            LiteBag_InitializeOptions()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
f:RegisterEvent("ADDON_LOADED")
