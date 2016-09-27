--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, addonTable = ...

local function UpgradeDBVersion()
    local db = LiteBag_OptionsDB
    local oldkey, newkey

    for _,frameName in ipairs({ "LiteBagInventory", "LiteBagBank" }) do
        oldkey = format("Frame:%s", frameName)
        newkey = format("Panel:%sPanel", frameName)
        if db[oldkey] then
            db[newkey] = db[oldkey]
            db[oldkey] = nil
        end
    end

end

function LiteBag_InitializeOptions()
    if not LiteBag_OptionsDB then
        LiteBag_OptionsDB = { }
    else
        UpgradeDBVersion()
    end
end

function LiteBag_SetPanelOption(frame, option, value)
    local n = "Panel:" .. frame:GetName()
    LiteBag_OptionsDB[n] = LiteBag_OptionsDB[n] or { }
    LiteBag_OptionsDB[n][option] = value
end

function LiteBag_GetPanelOption(frame, option)
    local n = "Panel:" .. frame:GetName()
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

function LiteBag_OptionSlashFunc(argstr)

    local args = { strsplit(" ", argstr) }

    for i = 1, #args do
        local arg = strlower(args[i])
        if arg == "" then
            InterfaceOptionsFrame:Show()
            InterfaceOptionsFrame_OpenToCategory(LiteBagOptions)
            return
        end
        if arg == "confirmsort" then
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
            LiteBagPanel_UpdateItemButtons(LiteBagBankPanel)
            LiteBagPanel_UpdateItemButtons(LiteBagInventoryPanel)
            return
        end
        if arg == "inventory.columns" then
            local n = tonumber(args[i+1])
            if n and n >= 8 then
                LiteBag_SetPanelOption(LiteBagInventoryPanel, "columns", n)
                LiteBagPanel_UpdateSizeAndLayout(LiteBagInventoryPanel)
                LiteBag_Print("Inventory frame width set to "..n.." columns")
            else
                LiteBag_Print("Can't set frame width to less than 8")
            end
            return
        end
        if arg == "bank.columns" then
            local n = tonumber(args[i+1])
            if n and n >= 8 then
                LiteBag_SetPanelOption(LiteBagBankPanel, "columns", n)
                LiteBagPanel_UpdateSizeAndLayout(LiteBagBankPanel)
                LiteBag_Print("Bank frame width set to "..n.." columns")
            else
                LiteBag_Print("Can't set frame width to less than 8")
            end
            return
        end
        if arg == "debug" then
            if args[i+1] == "on" then
                LiteBag_SetDebug(true)
            elseif args[i+1] == "on" then
                LiteBag_SetDebug(false)
            end
            return
        end
        LiteBag_Print("Usage:")
        LiteBag_Print("  /litebag bank.columns <n>")
        LiteBag_Print("  /litebag inventory.columns <n>")
        LiteBag_Print("  /litebag equipset <on | off>")
        LiteBag_Print("  /litebag confirmsort <on | off>")
    end
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
