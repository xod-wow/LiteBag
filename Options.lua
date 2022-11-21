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

LB.Options = { }

function LB.Options:Initialize()
    LiteBagDB = LiteBagDB or { }
    LB.db = LibStub("AceDB-3.0"):New("LiteBagDB", defaults, true)
    SlashCmdList['LiteBag'] = function (...) self:SlashFunc(...) end
    SLASH_LiteBag1 = '/litebag'
end

function LB.Options:SetTypeOption(key, option, value, noTrigger)
    LB.db.profile[key][option] = value
    if not noTrigger then LB.db.callbacks:Fire('OnOptionsModified') end
end

function LB.Options:GetTypeOption(key, option)
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

function LB.Options:SlashFunc(argstr)

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

    if cmd == 'backpack.snap' then
        LB.Options:SetTypeOption('BACKPACK', 'nosnap', not onOff)
        LB.Print(L["Backpack snap to default position:"].." "..tostring(onOff))
        return
    end

    if cmd == 'backpack.layout' then
        if arg1 == 'default' then arg1 = nil end
        LB.Options:SetTypeOption('BACKPACK', 'layout', arg1)
        LB.Print(L["Backpack button layout set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'backpack.order' then
        if arg1 == 'default' then arg1 = nil end
        LB.Options:SetTypeOption('BACKPACK', 'order', arg1)
        LB.Print(L["Backpack button order set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'backpack.columns' then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LB.Options:SetTypeOption('BACKPACK', 'columns', arg1)
            LB.Print(L["Backpack columns set to:"].." "..arg1)
        else
            LB.Print(L["Can't set number of columns to less than 8."])
        end
        return
    end

    if cmd == 'backpack.gaps' then
        local x = tonumber(arg1)
        local y = tonumber(arg2)
        if x == 0 then x = nil end
        if y == 0 then y = nil end
        LB.Options:SetTypeOption('BACKPACK', 'xbreak', x)
        LB.Options:SetTypeOption('BACKPACK', 'ybreak', y)
        LB.Print(format(L["Backpack gaps set to: %s %s"], tostring(x), tostring(y)))
        return
    end

    if cmd == 'backpack.scale' then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LB.Options:SetTypeOption('BACKPACK', 'scale', arg1)
            LB.Print(format(L["Backpack scale set to: %0.2f"], arg1))
        else
            LB.Print(L["Scale must be between 0 and 2."])
        end
        return
    end

    if cmd == 'bank.layout' then
        if arg1 == 'default' or arg1 == DEFAULT then arg1 = nil end
        LB.Options:SetTypeOption(LiteBagBankPanel, 'layout', arg1)
        LB.Print(L["Bank button layout set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'bank.order' then
        if arg1 == 'default' then arg1 = nil end
        LB.Options:SetTypeOption(LiteBagBankPanel, 'order', arg1)
        LB.Print(L["Bank button order set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'bank.columns' then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LB.Options:SetTypeOption(LiteBagBankPanel, 'columns', arg1)
            LB.Print(L["Bank columns set to:"].." "..arg1)
        else
            LB.Print("Can't set number of columns to less than 8.")
        end
        return
    end

    if cmd == 'bank.scale' then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LB.Options:SetTypeOption(LiteBagBank, 'scale', arg1)
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
    LB.Print('  /litebag backpack.columns <n>')
    LB.Print('  /litebag backpack.gaps <x> <y>')
    LB.Print('  /litebag backpack.layout <default | bag | reverse>')
    LB.Print('  /litebag backpack.order <default | blizzard | reverse>')
    LB.Print('  /litebag backpack.scale <s>')
    LB.Print('  /litebag backpack.snap <on | off>')
    LB.Print('  /litebag confirmsort <on | off>')
    LB.Print('  /litebag equipset <on | off>')
    LB.Print('  /litebag iconborder <minquality>')
    LB.Print('  /litebag debug <on | off>')
    LB.Print('  /litebag eventdebug <on | off>')
end
