--[[----------------------------------------------------------------------------

  LiteBag/UIOptions.lua

  Copyright 2015-2020 Mike Battersby

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

local LibDD = LibStub("LibUIDropDownMenu-4.0")

local MenuTextMapping  = {
    ['default'] = DEFAULT,
    ['bag'] = L['Bags'],
    ['reverse'] = L['Reverse'],
    ['blizzard'] = 'Blizzard'
}

function LiteBagOptionsHideBlizzardBagButtons_OnLoad(self)
    self.Text:SetText(L["Hide Blizzard Bag Buttons."])
    self.SetOption =
        function (self, setting)
            if not setting or setting == '0' then
                LB.SetGlobalOption('HideBlizzardBagButtons', nil)
            else
                LB.SetGlobalOption('HideBlizzardBagButtons', true)
            end
        end
    self.GetOption =
        function (self)
            return LB.GetGlobalOption('HideBlizzardBagButtons')
        end
    self.GetOptionDefault =
        function (self) return false end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsConfirmSort_OnLoad(self)
    self.Text:SetText(L["Confirm before sorting."])
    self.SetOption =
        function (self, setting)
            if not setting or setting == '0' then
                LB.SetGlobalOption('NoConfirmSort', true)
            else
                LB.SetGlobalOption('NoConfirmSort', nil)
            end
        end
    self.GetOption =
        function (self)
            return not LB.GetGlobalOption('NoConfirmSort')
        end
    self.GetOptionDefault =
        function (self) return true end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsEquipsetDisplay_OnLoad(self)
    self.Text:SetText(L["Display equipment set membership icons."])
    self.SetOption =
        function (self, setting)
            if not setting or setting == '0' then
                LB.SetGlobalOption('HideEquipsetIcon', true)
            else
                LB.SetGlobalOption('HideEquipsetIcon', nil)
            end
        end
    self.GetOption =
        function (self)
            return not LB.GetGlobalOption('HideEquipsetIcon')
        end
    self.GetOptionDefault =
        function (self) return true end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBindsOnDisplay_OnLoad(self)
    self.Text:SetText(L["Display text for BoA and BoE items."])
    self.SetOption =
        function (self, setting)
            if not setting or setting == '0' then
                LB.SetGlobalOption('ShowBindsOnText', nil)
            else
                LB.SetGlobalOption('ShowBindsOnText', true)
            end
        end
    self.GetOption =
        function (self)
            return LB.GetGlobalOption('ShowBindsOnText')
        end
    self.GetOptionDefault =
        function (self) return false end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsSnapToPosition_OnLoad(self)
    self.Text:SetText(L["Snap backpack frame to default backpack position."])
    self.SetOption =
        function (self, setting)
            if not setting or setting == '0' then
                LB.SetTypeOption('BACKPACK', 'nosnap', true)
            else
                LB.SetTypeOption('BACKPACK', 'nosnap', false)
            end
        end
    self.GetOption =
        function (self)
            return not LB.GetTypeOption('BACKPACK', 'nosnap')
        end
    self.GetOptionDefault =
        function (self) return false end
    LiteBagOptionsControl_OnLoad(self)
end

local function GetQualityText(i)
    if ITEM_QUALITY_COLORS[i] then
        local desc = _G['ITEM_QUALITY'..i..'_DESC']
        return ITEM_QUALITY_COLORS[i].hex..desc ..FONT_COLOR_CODE_CLOSE
    else
        return NEVER
    end
end

local function IconBorder_Initialize(self, level)
    if level == 1 then
        local info = LibDD:UIDropDownMenu_CreateInfo()
        local current = LB.GetGlobalOption('ThickerIconBorder')

        info.func =
             function (button, arg1, arg2, checked)
                self.value = arg1
                LiteBagOptionsControl_OnChanged(self)
             end

        info.text = GetQualityText(nil)
        info.checked = ( current == nil )
        info.arg1 = nil
        LibDD:UIDropDownMenu_AddButton(info)

        LibDD:UIDropDownMenu_AddSeparator()

        for i = Enum.ItemQualityMeta.NumValues-1, 0, -1 do
            info.text = GetQualityText(i)
            info.checked = ( current == i )
            info.arg1 = i
            LibDD:UIDropDownMenu_AddButton(info)
        end
    end
end

function LiteBagOptionsIconBorder_OnLoad(self)
    LibDD:Create_UIDropDownMenu(self)
    self.SetOption =
        function (self, setting)
            LB.SetGlobalOption('ThickerIconBorder', setting)
        end
    self.GetOption =
        function (self)
            return LB.GetGlobalOption('ThickerIconBorder')
        end
    self.GetOptionDefault =
        function (self)
            return nil
        end
    self.GetControl =
        function (self)
            return self.value
        end
    self.SetControl =
        function (self, v)
            self.value = v
            LibDD:UIDropDownMenu_SetText(self, GetQualityText(v))
        end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsIconBorder_OnShow(self)
    if not self:GetAttribute('initmenu') then
        LibDD:UIDropDownMenu_Initialize(self, IconBorder_Initialize)
    end
end

local function PanelOrder_Initialize(self, level)
    if level == 1 then
        local info = LibDD:UIDropDownMenu_CreateInfo()
        local current = LB.GetTypeOption(self.FrameType, 'order')

        info.func =
            function (button, arg1, arg2, checked)
                self.value = arg1
                LiteBagOptionsControl_OnChanged(self)
            end

        info.text = DEFAULT
        info.checked = ( current == "default" )
        info.arg1 = 'default'
        info.arg2 = info.text
        LibDD:UIDropDownMenu_AddButton(info)

        info.text = MenuTextMapping['blizzard']
        info.checked = ( current == 'blizzard' )
        info.arg1 = 'blizzard'
        info.arg2 = info.text
        LibDD:UIDropDownMenu_AddButton(info)

        info.text = MenuTextMapping['reverse']
        info.checked = ( current == 'reverse' )
        info.arg1 = 'reverse'
        info.arg2 = info.text
        LibDD:UIDropDownMenu_AddButton(info)
    end
end

local function PanelOrder_OnLoad(self, FrameType)
    LibDD:Create_UIDropDownMenu(self)
    self.SetOption =
        function (self, setting)
            LB.SetTypeOption(FrameType, 'order', setting)
        end
    self.GetOption =
        function (self)
            return LB.GetTypeOption(FrameType, 'order')
        end
    self.GetOptionDefault =
        function (self)
            return nil
        end
    self.GetControl =
        function (self)
            return self.value
        end
    self.SetControl =
        function (self, v)
            self.value = v
            if v then
                LibDD:UIDropDownMenu_SetText(self, MenuTextMapping[v])
            else
                LibDD:UIDropDownMenu_SetText(self, DEFAULT)
            end
        end
    self.FrameType = FrameType
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsPanelOrder_OnShow(self)
    LibDD:UIDropDownMenu_Initialize(self, PanelOrder_Initialize)
end

local function PanelLayout_Initialize(self, level)
    if level == 1 then
        local info = LibDD:UIDropDownMenu_CreateInfo()
        local current = LB.GetTypeOption(self.FrameType, 'layout')

        info.func =
            function (button, arg1, arg2, checked)
                self.value = arg1
                LiteBagOptionsControl_OnChanged(self)
            end

        info.text = DEFAULT
        info.checked = ( current == "default" )
        info.arg1 = 'default'
        info.arg2 = info.text
        LibDD:UIDropDownMenu_AddButton(info)

        info.text = MenuTextMapping['bag']
        info.checked = ( current == 'bag' )
        info.arg1 = 'bag'
        info.arg2 = info.text
        LibDD:UIDropDownMenu_AddButton(info)

        info.text = MenuTextMapping['reverse']
        info.checked = ( current == 'reverse' )
        info.arg1 = 'reverse'
        info.arg2 = info.text
        LibDD:UIDropDownMenu_AddButton(info)
    end
end

local function PanelLayout_OnLoad(self, FrameType)
    LibDD:Create_UIDropDownMenu(self)
    self.SetOption =
        function (self, setting)
            LB.SetTypeOption(FrameType, 'layout', setting)
        end
    self.GetOption =
        function (self)
            return LB.GetTypeOption(FrameType, 'layout')
        end
    self.GetOptionDefault =
        function (self)
            return nil
        end
    self.GetControl =
        function (self)
            return self.value
        end
    self.SetControl =
        function (self, v)
            self.value = v
            if v then
                LibDD:UIDropDownMenu_SetText(self, MenuTextMapping[v])
            else
                LibDD:UIDropDownMenu_SetText(self, DEFAULT)
            end
        end
    self.FrameType = FrameType
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsPanelLayout_OnShow(self)
    if not self:GetAttribute('initmenu') then
        LibDD:UIDropDownMenu_Initialize(self, PanelLayout_Initialize)
    end
end

local function SetupColumnsControl(self, FrameType, default)
    local n = self:GetName()

    _G[n..'Low']:SetText('8')
    _G[n..'High']:SetText('24')
    self.SetOption =
            function (self, v)
            LB.SetTypeOption(FrameType, 'columns', v)
        end
    self.GetOption =
        function (self)
            return LB.GetTypeOption(FrameType, 'columns') or default
        end
    self.GetOptionDefault =
            function (self) return default end
end

local function SetupScaleControl(self, FrameType)
    local n = self:GetName()
    _G[n..'Low']:SetText(0.75)
    _G[n..'High']:SetText(1.25)
    self.SetOption =
            function (self, v)
            LB.SetTypeOption(FrameType, 'scale', v)
        end
    self.GetOption =
            function (self)
            return LB.GetTypeOption(FrameType, 'scale') or 1.0
        end
    self.GetOptionDefault =
            function (self) return 1.0 end
end

local function SetupBreakControl(self, FrameType, varname)
    local n = self:GetName()
    _G[n..'Low']:SetText(0)
    _G[n..'High']:SetText(24)
    self.SetOption =
            function (self, v)
            if v == 0 then
                LB.SetTypeOption(FrameType, varname, nil)
            else
                LB.SetTypeOption(FrameType, varname, v)
            end
        end
    self.GetOption =
            function (self)
            return LB.GetTypeOption(FrameType, varname) or 0
        end
    self.GetOptionDefault =
            function (self) return 0 end
end

function LiteBagOptionsBackpackColumns_OnLoad(self)
    SetupColumnsControl(self, 'BACKPACK', 10)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBackpackColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n..'Text']:SetText(format(L["Columns: %d"], self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBackpackScale_OnLoad(self)
    SetupScaleControl(self, 'BACKPACK')
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBackpackScale_OnValueChanged(self)
    local n = self:GetName()
    _G[n..'Text']:SetText(format(L["Scale: %0.2f"], self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankColumns_OnLoad(self)
    SetupColumnsControl(self, 'BANK', 14)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n..'Text']:SetText(format(L["Columns: %d"], self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankScale_OnLoad(self)
    SetupScaleControl(self, 'BANK')
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankScale_OnValueChanged(self)
    local n = self:GetName()
    _G[n..'Text']:SetText(format(L["Scale: %0.2f"], self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsXBreak_OnValueChanged(self)
    local n = self:GetName()
    local v = self:GetValue()
    if v == 0 then
        _G[n..'Text']:SetText(L["No column gaps"])
    else
        _G[n..'Text']:SetText(format(L["Gap: %d columns"], v))
    end
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsYBreak_OnValueChanged(self)
    local n = self:GetName()
    local v = self:GetValue()
    if v == 0 then
        _G[n..'Text']:SetText(L["No row gaps"])
    else
        _G[n..'Text']:SetText(format(L["Gap: %d rows"], v))
    end
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBackpackXBreak_OnLoad(self)
    SetupBreakControl(self, 'BACKPACK', 'xbreak')
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBackpackYBreak_OnLoad(self)
    SetupBreakControl(self, 'BACKPACK', 'ybreak')
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankXBreak_OnLoad(self)
    SetupBreakControl(self, 'BANK', 'xbreak')
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankYBreak_OnLoad(self)
    SetupBreakControl(self, 'BANK', 'ybreak')
    LiteBagOptionsControl_OnLoad(self)
end


function LiteBagOptionsBankOrder_OnLoad(self)
    PanelOrder_OnLoad(self, 'BANK')
end

function LiteBagOptionsBankLayout_OnLoad(self)
    PanelLayout_OnLoad(self, 'BANK')
end

function LiteBagOptionsBackpackOrder_OnLoad(self)
    PanelOrder_OnLoad(self, 'BACKPACK')
end

function LiteBagOptionsBackpackLayout_OnLoad(self)
    PanelLayout_OnLoad(self, 'BACKPACK')
end

