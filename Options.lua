--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2013-2018 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, addonTable = ...

local L = LiteBag_Localize

local function UpgradeDBVersion()
    local db = LiteBag_OptionsDB
end

function LiteBag_InitializeOptions()
    LiteBag_OptionsDB = LiteBag_OptionsDB or { }
    UpgradeDBVersion()
end

function LiteBag_SetFrameOption(frame, option, value)
    frame = _G[frame] or frame
    local n = 'Frame:' .. frame:GetName()
    LiteBag_OptionsDB[n] = LiteBag_OptionsDB[n] or { }
    LiteBag_OptionsDB[n][option] = value
end

function LiteBag_GetFrameOption(frame, option)
    frame = _G[frame] or frame
    local n = 'Frame:' .. frame:GetName()
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
    if not arg or arg == 'off' or arg == 'no' then
        return false
    else
        return true
    end
end

local function RefreshUI()
    if LiteBagInventory:IsShown() then
        LiteBagPanel_OnShow(LiteBagInventory.currentPanel)
        LiteBagFrame_OnShow(LiteBagInventory)
    end
    if LiteBagBank:IsShown() then
        LiteBagPanel_OnShow(LiteBagBank.currentPanel)
        LiteBagFrame_OnShow(LiteBagBank)
    end
end

function LiteBag_OptionSlashFunc(argstr)

    local cmd, arg1, arg2 = strsplit(' ', strlower(argstr))
    local onOff = CheckOnOff(arg1)

    if cmd == '' or cmd == 'options' then
        InterfaceOptionsFrame:Show()
        InterfaceOptionsFrame_OpenToCategory(LiteBagOptions)
        return
    end

    if cmd == 'confirmsort' and arg1 ~= nil then
        LiteBag_SetGlobalOption('NoConfirmSort', onOff)
        LiteBag_Print(L["Bag sort confirmation popup:"].." "..tostring(onOff))
        return
    end

    if cmd == 'equipset' then
        LiteBag_SetGlobalOption('HideEquipsetIcon', onOff)
        LiteBag_Print(L["Equipment set icon display:"].." "..tostring(onOff))
        RefreshUI()
        return
    end

    if cmd == 'debug' then
        LiteBag_SetGlobalOption('DebugEnabled', onOff)
        LiteBag_Print(L["Debugging:"].." "..tostring(onOff))
        return
    end

    if cmd == 'inventory.snap' then
        LiteBag_SetFrameOption(LiteBagInventoryPanel, 'NoSnapToPosition', onOff)
        LiteBag_Print(L["Inventory snap to default position:"].." "..tostring(onOff))
        return
    end

    if cmd == 'inventory.layout' then
        if arg1 == 'default' then arg1 = nil end
        LiteBag_SetFrameOption(LiteBagInventoryPanel, 'layout', arg1)
        LiteBag_Print(L["Inventory button layout set to:"].." "..tostring(arg1))
        RefreshUI()
        return
    end

    if cmd == 'inventory.order' then
        if arg1 == 'default' then arg1 = nil end
        LiteBag_SetFrameOption(LiteBagInventoryPanel, 'order', arg1)
        LiteBag_Print(L["Inventory button order set to:"].." "..tostring(arg1))
        RefreshUI()
        return
    end

    if cmd == 'inventory.columns' then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LiteBag_SetFrameOption(LiteBagInventoryPanel, 'columns', arg1)
            LiteBag_Print(L["Inventory columns set to:"].." "..arg1)
            RefreshUI()
        else
            LiteBag_Print(L["Can't set number of columns to less than 8."])
        end
        return
    end

    if cmd == 'inventory.gaps' then
        local x = tonumber(arg1)
        local y = tonumber(arg2)
        if x == 0 then x = nil end
        if y == 0 then y = nil end
        LiteBag_SetFrameOption(LiteBagInventoryPanel, 'xbreak', x)
        LiteBag_SetFrameOption(LiteBagInventoryPanel, 'ybreak', y)
        RefreshUI()
        LiteBag_Print(format(L["Inventory gaps set to: %s %s"], tostring(x), tostring(y)))
        return
    end

    if cmd == 'inventory.scale' then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LiteBag_SetFrameOption(LiteBagInventory, 'scale', arg1)
            LiteBag_Print(format(L["Inventory scale set to: %0.2f"], arg1))
            RefreshUI()
        else
            LiteBag_Print(L["Scale must be between 0 and 2."])
        end
        return
    end

    if cmd == 'bank.layout' then
        if arg1 == 'default' or arg1 == DEFAULT then arg1 = nil end
        LiteBag_SetFrameOption(LiteBagBankPanel, 'layout', arg1)
        LiteBag_Print(L["Bank button layout set to:"].." "..tostring(arg1))
        RefreshUI()
        return
    end

    if cmd == 'bank.order' then
        if arg1 == 'default' then arg1 = nil end
        LiteBag_SetFrameOption(LiteBagBankPanel, 'order', arg1)
        LiteBag_Print(L["Bank button order set to:"].." "..tostring(arg1))
        RefreshUI()
        return
    end

    if cmd == 'bank.columns' then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LiteBag_SetFrameOption(LiteBagBankPanel, 'columns', arg1)
            LiteBag_Print(L["Bank columns set to:"].." "..arg1)
            RefreshUI()
        else
            LiteBag_Print("Can't set number of columns to less than 8.")
        end
        return
    end

    if cmd == 'bank.scale' then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LiteBag_SetFrameOption(LiteBagBank, 'scale', arg1)
            LiteBag_Print(format(L["Bank scale set to: %0.2f"], arg1))
            RefreshUI()
        else
            LiteBag_Print(L["Scale must be between 0 and 2."])
        end
        return
    end
            
    LiteBag_Print('Usage:')
    LiteBag_Print('  /litebag bank.columns <n>')
    LiteBag_Print('  /litebag bank.gaps <x> <y>')
    LiteBag_Print('  /litebag bank.layout <default | bag | reverse>')
    LiteBag_Print('  /litebag bank.order <default | blizzard | reverse>')
    LiteBag_Print('  /litebag bank.scale <s>')
    LiteBag_Print('  /litebag inventory.columns <n>')
    LiteBag_Print('  /litebag inventory.gaps <x> <y>')
    LiteBag_Print('  /litebag inventory.layout <default | bag | reverse>')
    LiteBag_Print('  /litebag inventory.order <default | blizzard | reverse>')
    LiteBag_Print('  /litebag inventory.scale <s>')
    LiteBag_Print('  /litebag inventory.snap <on | off>')
    LiteBag_Print('  /litebag confirmsort <on | off>')
    LiteBag_Print('  /litebag equipset <on | off>')
    LiteBag_Print('  /litebag iconborder <minquality>')
    LiteBag_Print('  /litebag debug <on | off>')
end

--[[----------------------------------------------------------------------------
    Initialization.
----------------------------------------------------------------------------]]--

local f = CreateFrame('Frame')
f:SetScript('OnEvent', function (self, event, arg1, ...)
        if event == 'ADDON_LOADED' and arg1 == addonName then
            LiteBag_InitializeOptions()
            SlashCmdList['LiteBag'] = LiteBag_OptionSlashFunc
            SLASH_LiteBag1 = '/litebag'
            SLASH_LiteBag2 = '/lbg'
            self:UnregisterEvent('ADDON_LOADED')
        end
    end)
f:RegisterEvent('ADDON_LOADED')
