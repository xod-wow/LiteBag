--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

LB.Options = CreateFrame('Frame')
LB.Options.callbacks = {}

function LB.Options:RegisterCallback(f, method, ...)
    LB.Debug('Register on ' .. f:GetName())
    self.callbacks[f] = self.callbacks[f] or { }
    if type(method) == 'function' then
        table.insert(self.callbacks[f], { method, f, ... })
    else
        table.insert(self.callbacks[f], { f[method], f, ... })
    end
end

function LB.Options:UnregisterAllCallbacks(f)
    self.callbacks[f] = nil
end

function LB.Options:Fire()
    for f, callbacks in pairs(self.callbacks) do
        LB.Debug('Firing on ' .. f:GetName())
        for _,t in ipairs(callbacks) do
            local method = t[1]
            method(select(2, unpack(t)))
        end
    end
end

function LB.Options:Initialize()
    LiteBag_OptionsDB = LiteBag_OptionsDB or { }
    self.db = LiteBag_OptionsDB
end

function LB.Options:SetFrameOption(frame, option, value, noTrigger)
    frame = _G[frame] or frame
    local n = 'Frame:' .. frame:GetName()
    self.db[n] = self.db[n] or { }
    self.db[n][option] = value
    if not noTrigger then self:Fire() end
end

function LB.Options:GetFrameOption(frame, option)
    if self.db then
        frame = _G[frame] or frame
        local n = 'Frame:' .. frame:GetName()
        self.db[n] = self.db[n] or { }
        return self.db[n][option]
    end
end

function LB.Options:SetGlobalOption(option, value, noTrigger)
    self.db[option] = value
    if not noTrigger then self:Fire() end
end

function LB.Options:GetGlobalOption(option)
    if self.db then
        return self.db[option]
    end
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
        InterfaceOptionsFrame:Show()
        InterfaceOptionsFrame_OpenToCategory(LiteBagOptions)
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

    if cmd == 'inventory.snap' then
        LB.Options:SetFrameOption(LiteBagInventoryPanel, 'NoSnapToPosition', onOff)
        LB.Print(L["Inventory snap to default position:"].." "..tostring(onOff))
        return
    end

    if cmd == 'inventory.layout' then
        if arg1 == 'default' then arg1 = nil end
        LB.Options:SetFrameOption(LiteBagInventoryPanel, 'layout', arg1)
        LB.Print(L["Inventory button layout set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'inventory.order' then
        if arg1 == 'default' then arg1 = nil end
        LB.Options:SetFrameOption(LiteBagInventoryPanel, 'order', arg1)
        LB.Print(L["Inventory button order set to:"].." "..tostring(arg1))
        return
    end

    if cmd == 'inventory.columns' then
        arg1 = tonumber(arg1)
        if arg1 and arg1 >= 8 then
            LB.Options:SetFrameOption(LiteBagInventoryPanel, 'columns', arg1)
            LB.Print(L["Inventory columns set to:"].." "..arg1)
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
        LB.Options:SetFrameOption(LiteBagInventoryPanel, 'xbreak', x)
        LB.Options:SetFrameOption(LiteBagInventoryPanel, 'ybreak', y)
        LB.Print(format(L["Inventory gaps set to: %s %s"], tostring(x), tostring(y)))
        return
    end

    if cmd == 'inventory.scale' then
        arg1 = tonumber(arg1)
        if arg1 > 0 and arg1 <= 2 then
            LB.Options:SetFrameOption(LiteBagInventory, 'scale', arg1)
            LB.Print(format(L["Inventory scale set to: %0.2f"], arg1))
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
    if event == 'PLAYER_LOGIN' then
        self:Initialize()
        SlashCmdList['LiteBag'] = SlashFunc
        SLASH_LiteBag1 = '/litebag'
        SLASH_LiteBag2 = '/lbg'
    end
end

LB.Options:SetScript('OnEvent', LB.Options.OnEvent)
LB.Options:RegisterEvent('PLAYER_LOGIN')
