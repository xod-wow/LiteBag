--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

defaults = {
    profile = {
        BACKPACK = {
            columns = 10,
            scale = 1.0,
            xbreak = nil,
            ybreak = nil,
            layout = 'default',
            order = 'default',
            nosnap = false,
        },
        BANK = {
            columns = 14,
            scale = 1.0,
            xbreak = nil,
            ybreak = nil,
            layout = 'default',
            order = 'default',
        },
        REAGENTBANK = { },
        debug = nil,
        eventDebug = nil,
        eventFilter = { },
    }
}

LB.Options = CreateFrame('Frame')

local function Initialize()
    LiteBagDB = LiteBagDB or { }
    LB.db = LibStub("AceDB-3.0"):New("LiteBagDB", defaults, true)
end

function LB.Options:SetFrameOption(key, option, value, noTrigger)
    if type(key) == 'table' then
        key = key.FrameType
    end
    LB.db.profile[key][option] = value
    if not noTrigger then LB.db.callbacks:Fire('OnOptionsModified') end
end

function LB.Options:GetFrameOption(key, option)
    if type(key) == 'table' then
        key = key.FrameType
    end
    return LB.db.profile[key][option]
end

function LB.Options:SetGlobalOption(option, value, noTrigger)
    LB.db.profile[option] = value
    if not noTrigger then LB.db.callbacks:Fire('OnOptionsModified') end
end

function LB.Options:GetGlobalOption(option)
    return LB.db.profile[option]
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

local function SlashFunc(argstr)

    local cmd, arg1, arg2 = strsplit(' ', strlower(argstr))
    local onOff = CheckOnOff(arg1)

    if cmd == '' or cmd == 'options' then
        LiteBagOptionsPanel_Open()
        return
    end

    if cmd == 'confirmsort' and arg1 ~= nil then
        LB.Options:SetGlobalOption('NoConfirmSort', onOff)
        LB.Print(L["Bag sort confirmation popup:"].." "..tostring(onOff))
        return
    end

    if cmd == 'equipset' then
        LB.Options:SetGlobalOption('HideEquipsetIcon', onOff)
        LB.Print(L["Equipment set icon display:"].." "..tostring(onOff))
        return
    end

    if cmd == 'debug' then
        LB.Options:SetGlobalOption('DebugEnabled', onOff)
        LB.Print(L["Debugging:"].." "..tostring(onOff))
        return
    end

    if cmd == 'eventdebug' then
        LB.Options:SetGlobalOption('EventDebugEnabled', onOff)
        LB.Print(L["Event Debugging:"].." "..tostring(onOff))
        return
    end

    if cmd == 'inventory.snap' then
        LB.Options:SetFrameOption('BACKPACK', 'nosnap', not onOff)
        LB.Print(L["Backpack snap to default position:"].." "..tostring(onOff))
        return
    end

    if cmd == 'inventory.layout' then
        if arg1 == 'default' then arg1 = nil end
        LB.Options:SetFrameOption('BACKPACK', 'layout', arg1)
        LB.Print(L["Backpack button layout set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'inventory.order' then
        if arg1 == 'default' then arg1 = nil end
        LB.Options:SetFrameOption('BACKPACK', 'order', arg1)
        LB.Print(L["Backpack button order set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'inventory.columns' then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LB.Options:SetFrameOption('BACKPACK', 'columns', arg1)
            LB.Print(L["Backpack columns set to:"].." "..arg1)
        else
            LB.Print(L["Can't set number of columns to less than 8."])
        end
        return
    end

    if cmd == 'inventory.gaps' then
        local x = tonumber(arg1)
        local y = tonumber(arg2)
        if x == 0 then x = nil end
        if y == 0 then y = nil end
        LB.Options:SetFrameOption('BACKPACK', 'xbreak', x)
        LB.Options:SetFrameOption('BACKPACK', 'ybreak', y)
        LB.Print(format(L["Backpack gaps set to: %s %s"], tostring(x), tostring(y)))
        return
    end

    if cmd == 'inventory.scale' then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LB.Options:SetFrameOption('BACKPACK', 'scale', arg1)
            LB.Print(format(L["Backpack scale set to: %0.2f"], arg1))
        else
            LB.Print(L["Scale must be between 0 and 2."])
        end
        return
    end

    if cmd == 'bank.layout' then
        if arg1 == 'default' or arg1 == DEFAULT then arg1 = nil end
        LB.Options:SetFrameOption(LiteBagBankPanel, 'layout', arg1)
        LB.Print(L["Bank button layout set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'bank.order' then
        if arg1 == 'default' then arg1 = nil end
        LB.Options:SetFrameOption(LiteBagBankPanel, 'order', arg1)
        LB.Print(L["Bank button order set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'bank.columns' then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LB.Options:SetFrameOption(LiteBagBankPanel, 'columns', arg1)
            LB.Print(L["Bank columns set to:"].." "..arg1)
        else
            LB.Print("Can't set number of columns to less than 8.")
        end
        return
    end

    if cmd == 'bank.scale' then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LB.Options:SetFrameOption(LiteBagBank, 'scale', arg1)
            LB.Print(format(L["Bank scale set to: %0.2f"], arg1))
        else
            LB.Print(L["Scale must be between 0 and 2."])
        end
        return
    end
            
    LB.Print('Usage:')
    LB.Print('  /litebag bank.columns <n>')
    LB.Print('  /litebag bank.gaps <x> <y>')
    LB.Print('  /litebag bank.layout <default | bag | reverse>')
    LB.Print('  /litebag bank.order <default | blizzard | reverse>')
    LB.Print('  /litebag bank.scale <s>')
    LB.Print('  /litebag inventory.columns <n>')
    LB.Print('  /litebag inventory.gaps <x> <y>')
    LB.Print('  /litebag inventory.layout <default | bag | reverse>')
    LB.Print('  /litebag inventory.order <default | blizzard | reverse>')
    LB.Print('  /litebag inventory.scale <s>')
    LB.Print('  /litebag inventory.snap <on | off>')
    LB.Print('  /litebag confirmsort <on | off>')
    LB.Print('  /litebag equipset <on | off>')
    LB.Print('  /litebag iconborder <minquality>')
    LB.Print('  /litebag debug <on | off>')
end

--[[----------------------------------------------------------------------------
    Initialization.
----------------------------------------------------------------------------]]--

function LB.Options:OnEvent(event, arg1, ...)
    if event == 'ADDON_LOADED' and arg1 == addonName then
        Initialize()
        SlashCmdList['LiteBag'] = SlashFunc
        SLASH_LiteBag1 = '/litebag'
        SLASH_LiteBag2 = '/lbg'
        self:UnregisterEvent('ADDON_LOADED')
    end
end

LB.Options:SetScript('OnEvent', LB.Options.OnEvent)
LB.Options:RegisterEvent('ADDON_LOADED')
