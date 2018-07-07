--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, addonTable = ...

local function UpgradeDBVersion()
    local db = LiteBag_OptionsDB
end

function LiteBag_InitializeOptions()
    LiteBag_OptionsDB = LiteBag_OptionsDB or { }
    UpgradeDBVersion()
end

function LiteBag_SetFrameOption(frame, option, value)
    frame = _G[frame] or frame
    local n = "Frame:" .. frame:GetName()
    LiteBag_OptionsDB[n] = LiteBag_OptionsDB[n] or { }
    LiteBag_OptionsDB[n][option] = value
end

function LiteBag_GetFrameOption(frame, option)
    frame = _G[frame] or frame
    local n = "Frame:" .. frame:GetName()
    LiteBag_OptionsDB[n] = LiteBag_OptionsDB[n] or { }
    return LiteBag_OptionsDB[n][option]
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

local function CheckOnOff(arg)
    if not arg or arg == "off" or arg == "no" then
        return false
    else
        return true
    end
end

function LiteBag_OptionSlashFunc(argstr)

    local cmd, arg1, arg2 = strsplit(" ", strlower(argstr))
    local onOff = CheckOnOff(arg1)

    if cmd == "" or cmd == "options" then
        InterfaceOptionsFrame:Show()
        InterfaceOptionsFrame_OpenToCategory(LiteBagOptions)
        return
    end

    if cmd == "confirmsort" and arg1 ~= nil then
        LiteBag_SetGlobalOption("NoConfirmSort", onOff)
        LiteBag_Print("Bag sort confirmation popup: " .. tostring(onOff))
        return
    end

    if cmd == "equipset" then
        LiteBag_SetGlobalOption("HideEquipsetIcon", onOff)
        LiteBag_Print("Equipment set icon display: " .. tostring(onOff))
        LiteBagPanel_UpdateItemButtons(LiteBagBankPanel)
        LiteBagPanel_UpdateItemButtons(LiteBagInventoryPanel)
        return
    end

    if cmd == "debug" then
        LiteBag_SetGlobalOption("DebugEnabled", onOff)
        LiteBag_Print("Debugging: " .. tostring(onOff))
        return
    end

    if cmd == "inventory.snap" then
        LiteBag_SetFrameOption(LiteBagInventoryPanel, "NoSnapToPosition", onOff)
        LiteBag_Print("Inventory snap to default position: " .. tostring(onOff))
        return
    end

    if cmd == "inventory.layout" then
        LiteBag_SetFrameOption(LiteBagInventoryPanel, "layout", arg1)
        LiteBag_Print("Inventory button layout set to: " .. tostring(arg1))
        return
    end

    if cmd == "inventory.columns" then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LiteBag_SetFrameOption(LiteBagInventoryPanel, "columns", arg1)
            LiteBagPanel_UpdateSizeAndLayout(LiteBagInventoryPanel)
            LiteBag_Print("Inventory columns set to "..arg1.." columns")
        else
            LiteBag_Print("Can't set number of columns to less than 8")
        end
        return
    end

    if cmd == "inventory.scale" then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LiteBag_SetFrameOption(LiteBagInventory, "scale", arg1)
            LiteBag_Print("Inventory scale set to "..arg1)
        else
            LiteBag_Print("Scale must be between 0 and 2.")
        end
        return
    end

    if cmd == "bank.layout" then
        LiteBag_SetFrameOption(LiteBagBankPanel, "layout", arg1)
        LiteBag_Print("Bank button layout set to: " .. tostring(arg1))
        return
    end

    if cmd == "bank.columns" then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LiteBag_SetFrameOption(LiteBagBankPanel, "columns", arg1)
            LiteBagPanel_UpdateSizeAndLayout(LiteBagBankPanel)
            LiteBag_Print("Bank columns set to "..arg1.." columns")
        else
            LiteBag_Print("Can't set number of columns to less than 8")
        end
        return
    end

    if cmd == "bank.scale" then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LiteBag_SetFrameOption(LiteBagBank, "scale", arg1)
            LiteBag_Print("Bank scale set to "..arg1)
        else
            LiteBag_Print("Scale must be between 0 and 2.")
        end
        return
    end
            
    LiteBag_Print("Usage:")
    LiteBag_Print("  /litebag bank.columns <n>")
    LiteBag_Print("  /litebag bank.scale <s>")
    LiteBag_Print("  /litebag inventory.columns <n>")
    LiteBag_Print("  /litebag inventory.scale <s>")
    LiteBag_Print("  /litebag inventory.snap <on | off>")
    LiteBag_Print("  /litebag confirmsort <on | off>")
    LiteBag_Print("  /litebag equipset <on | off>")
    LiteBag_Print("  /litebag debug <on | off>")
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
