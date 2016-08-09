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


--[[----------------------------------------------------------------------------
    Slash command function for setting options.
----------------------------------------------------------------------------]]--

function LiteBag_OptionSlashFunc(argstr)

    local args = { strsplit(" ", argstr) }

    if #args == 1 then
        InterfaceOptionsFrame:Show()
        InterfaceOptionsFrame_OpenToCategory(LiteBagOptions)
        return
    end

    for i = 2, #args do
        local arg = strlower(args[i])
        if arg == "confirm" then
            if args[i+1] == "on" then
                LiteBag_SetGlobalOption("NoConfirmSort", nil)
                LiteBag_Print("Bag sort confirmation popup enabled.")
            elseif args[i+1] == "off" then
                LiteBag_SetGlobalOption("NoConfirmSort", true)
                LiteBag_Print("Bag sort confirmation popup disabled.")
            end
            return
        end
        if arg == "equipset" then
            if args[i+1] == "on" then
                LiteBag_SetGlobalOption("HideEquipsetIcon", nil)
                LiteBag_Print("Equipment set icon display enabled.")
            elseif args[i+1] == "off" then
                LiteBag_SetGlobalOption("HideEquipsetIcon", true)
                LiteBag_Print("Equipment set icon display disabled.")
            end
            return
        end
        if arg == "inventory.columns" then
            local n = tonumber(args[i+1])
            if n and n >= 8 then
                LiteBag_SetFrameOption(LiteBagInventory, "columns", n)
                LiteBagFrame_Initialize(LiteBagInventory)
                LiteBag_Print("Inventory frame width set to "..n.." columns")
            end
            return
        end
        if arg == "bank.columns" then
            local n = tonumber(args[i+1])
            if n and n >= 8 then
                LiteBag_SetFrameOption(LiteBagBank, "columns", n)
                LiteBagFrame_Initialize(LiteBagBank)
                LiteBag_Print("Bank frame width set to "..n.." columns")
            end
            return
        end
    end
end


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


--[[----------------------------------------------------------------------------
    Initialization.
----------------------------------------------------------------------------]]--

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function (self, event, arg1, ...)
        if event == "ADDON_LOADED" and arg1 == addonName then
            LiteBag_InitializeOptions()
            SlashCmdList["LiteBag"] = LiteBag_OptionSlashFunc
            SLASH_LiteBag1 = "/litebag"
            SLASH_LiteBag2 = "/lbg"
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
f:RegisterEvent("ADDON_LOADED")
