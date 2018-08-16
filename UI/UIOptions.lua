--[[----------------------------------------------------------------------------

  LiteBag/UIOptions.lua

  Copyright 2015-2018 Mike Battersby

----------------------------------------------------------------------------]]--


function LiteBagOptionsConfirmSort_OnLoad(self)
    self.Text:SetText("Confirm before sorting.")
    self.SetOption =
        function (self, setting)
            if not setting or setting == "0" then
                LiteBag_SetGlobalOption("NoConfirmSort", true)
            else
                LiteBag_SetGlobalOption("NoConfirmSort", nil)
            end
        end
    self.GetOption =
        function (self)
            return not LiteBag_GetGlobalOption("NoConfirmSort")
        end
    self.GetOptionDefault =
        function (self) return true end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsEquipsetDisplay_OnLoad(self)
    self.Text:SetText("Display equipment set membership icons.")
    self.SetOption =
        function (self, setting)
            if not setting or setting == "0" then
                LiteBag_SetGlobalOption("HideEquipsetIcon", true)
            else
                LiteBag_SetGlobalOption("HideEquipsetIcon", nil)
            end
            LiteBagPanel_UpdateItemButtons(LiteBagInventoryPanel)
            LiteBagPanel_UpdateItemButtons(LiteBagBankPanel)
        end
    self.GetOption =
        function (self)
            return not LiteBag_GetGlobalOption("HideEquipsetIcon")
        end
    self.GetOptionDefault =
        function (self) return true end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBindsOnDisplay_OnLoad(self)
    self.Text:SetText("Display text for BoA and BoE items.")
    self.SetOption =
        function (self, setting)
            if not setting or setting == "0" then
                LiteBag_SetGlobalOption("ShowBindsOnText", nil)
            else
                LiteBag_SetGlobalOption("ShowBindsOnText", true)
            end
            LiteBagPanel_UpdateItemButtons(LiteBagInventoryPanel)
            LiteBagPanel_UpdateItemButtons(LiteBagBankPanel)
        end
    self.GetOption =
        function (self)
            return LiteBag_GetGlobalOption("ShowBindsOnText")
        end
    self.GetOptionDefault =
        function (self) return false end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsSnapToPosition_OnLoad(self)
    self.Text:SetText("Snap inventory frame to default backpack position.")
    self.SetOption =
        function (self, setting)
            if not setting or setting == "0" then
                LiteBag_SetGlobalOption("NoSnapToPosition", true)
            else
                LiteBag_SetGlobalOption("NoSnapToPosition", false)
            end
        end
    self.GetOption =
        function (self)
            return not LiteBag_GetGlobalOption("NoSnapToPosition")
        end
    self.GetOptionDefault =
        function (self) return false end
    LiteBagOptionsControl_OnLoad(self)
end

local function GetQualityText(i)
    if ITEM_QUALITY_COLORS[i] then
        local desc = _G["ITEM_QUALITY"..i.."_DESC"]
        return ITEM_QUALITY_COLORS[i].hex..desc ..FONT_COLOR_CODE_CLOSE
    else
        return NEVER
    end
end

local function IconBorder_Initialize(self, level)
    if level == 1 then
        local info = UIDropDownMenu_CreateInfo()
        local current = LiteBag_GetGlobalOption("ThickerIconBorder")

        info.func =
             function (button, arg1, arg2, checked)
                 self.value = arg1
                 self:SetOption(arg1)
                 UIDropDownMenu_SetText(self, GetQualityText(arg1))
             end

        info.text = GetQualityText(nil)
        info.checked = ( current == nil )
        info.arg1 = nil
        UIDropDownMenu_AddButton(info)

        UIDropDownMenu_AddSeparator()

        for i = NUM_LE_ITEM_QUALITYS-1, 0, -1 do
            info.text = GetQualityText(i)
            info.checked = ( current == i )
            info.arg1 = i
            UIDropDownMenu_AddButton(info)
        end
    end
end

function LiteBagOptionsIconBorder_OnLoad(self)
    self.SetOption =
        function (self, setting)
            LiteBag_SetGlobalOption("ThickerIconBorder", setting)
        end
    self.GetOption =
        function (self)
            return LiteBag_GetGlobalOption("ThickerIconBorder")
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
            UIDropDownMenu_SetText(self, GetQualityText(v))
        end
    UIDropDownMenu_Initialize(self, IconBorder_Initialize)
    LiteBagOptionsControl_OnLoad(self)
end

local function PanelOrder_Initialize(self, level)
    if level == 1 then
        local info = UIDropDownMenu_CreateInfo()
        local current = LiteBag_GetFrameOption(self.panel, "order")

        info.func =
             function (button, arg1, arg2, checked)
                 self.value = arg1
                 self:SetOption(arg1)
                 UIDropDownMenu_SetText(self, arg2 or DEFAULT)
             end

        info.text = DEFAULT
        info.checked = ( current == nil )
        info.arg1 = nil
        info.arg2 = info.text
        UIDropDownMenu_AddButton(info)

        info.text = "Blizzard"
        info.checked = ( current == "blizzard" )
        info.arg1 = "blizzard"
        info.arg2 = info.text
        UIDropDownMenu_AddButton(info)

        info.text = "Reverse"
        info.checked = ( current == "reverse" )
        info.arg1 = "reverse"
        info.arg2 = info.text
        UIDropDownMenu_AddButton(info)
    end
end

local function PanelOrder_OnLoad(self, panel)
    self.SetOption =
        function (self, setting)
            LiteBag_SetFrameOption(panel, "order", setting)
        end
    self.GetOption =
        function (self)
            return LiteBag_GetFrameOption(panel, "layout")
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
            UIDropDownMenu_SetText(self, v or DEFAULT)
        end
    self.panel = panel
    UIDropDownMenu_Initialize(self, PanelOrder_Initialize)
    LiteBagOptionsControl_OnLoad(self)
end

local function PanelLayout_Initialize(self, level)
    if level == 1 then
        local info = UIDropDownMenu_CreateInfo()
        local current = LiteBag_GetFrameOption(self.panel, "layout")

        info.func =
             function (button, arg1, arg2, checked)
                 self.value = arg1
                 self:SetOption(arg1)
                 UIDropDownMenu_SetText(self, arg2 or DEFAULT)
             end

        info.text = DEFAULT
        info.checked = ( current == nil )
        info.arg1 = nil
        info.arg2 = info.text
        UIDropDownMenu_AddButton(info)

        info.text = "Bags"
        info.checked = ( current == "bag" )
        info.arg1 = "bag"
        info.arg2 = info.text
        UIDropDownMenu_AddButton(info)

        info.text = "Reverse"
        info.checked = ( current == "reverse" )
        info.arg1 = "reverse"
        info.arg2 = info.text
        UIDropDownMenu_AddButton(info)
    end
end

local function PanelLayout_OnLoad(self, panel)
    self.SetOption =
        function (self, setting)
            LiteBag_SetFrameOption(panel, "layout", setting)
        end
    self.GetOption =
        function (self)
            return LiteBag_GetFrameOption(panel, "layout")
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
            UIDropDownMenu_SetText(self, v or DEFAULT)
        end
    self.panel = panel
    UIDropDownMenu_Initialize(self, PanelLayout_Initialize)
    LiteBagOptionsControl_OnLoad(self)
end

local function SetupColumnsControl(self, panel, default)
    local n = self:GetName()

    _G[n.."Low"]:SetText("8")
    _G[n.."High"]:SetText("24")
    self.SetOption =
            function (self, v)
            LiteBag_SetFrameOption(panel, "columns", v)
        end
    self.GetOption =
        function (self)
            return LiteBag_GetFrameOption(panel, "columns") or default
        end
    self.GetOptionDefault =
            function (self) return default end
end

local function SetupScaleControl(self, frame)
    local n = self:GetName()
    _G[n.."Low"]:SetText(0.75)
    _G[n.."High"]:SetText(1.25)
    self.SetOption =
            function (self, v)
            LiteBag_SetFrameOption(frame, "scale", v)
        end
    self.GetOption =
            function (self)
            return LiteBag_GetFrameOption(frame, "scale") or 1.0
        end
    self.GetOptionDefault =
            function (self) return 1.0 end
end

local function SetupBreakControl(self, frame, varname)
    local n = self:GetName()
    _G[n.."Low"]:SetText(0)
    _G[n.."High"]:SetText(24)
    self.SetOption =
            function (self, v)
            if v == 0 then
                LiteBag_SetFrameOption(frame, varname, nil)
            else
                LiteBag_SetFrameOption(frame, varname, v)
            end
        end
    self.GetOption =
            function (self)
            return LiteBag_GetFrameOption(frame, varname) or 0
        end
    self.GetOptionDefault =
            function (self) return 0 end
end

function LiteBagOptionsInventoryColumns_OnLoad(self)
    SetupColumnsControl(self, "LiteBagInventoryPanel", 8)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Columns: %d", self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsInventoryScale_OnLoad(self)
    SetupScaleControl(self, "LiteBagInventory")
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryScale_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Scale: %0.2f", self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankColumns_OnLoad(self)
    SetupColumnsControl(self, "LiteBagBankPanel", 14)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Columns: %d", self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankScale_OnLoad(self)
    SetupScaleControl(self, "LiteBagBank")
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankScale_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Scale: %0.2f", self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsInventoryXBreak_OnLoad(self)
    SetupBreakControl(self, "LiteBagInventoryPanel", "xbreak")
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryYBreak_OnLoad(self)
    SetupBreakControl(self, "LiteBagInventoryPanel", "ybreak")
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryXBreak_OnValueChanged(self)
    local n = self:GetName()
    local v = self:GetValue()
    if v == 0 then v = NONE end
    _G[n.."Text"]:SetText(format("Col gap: " .. v))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsInventoryYBreak_OnValueChanged(self)
    local n = self:GetName()
    local v = self:GetValue()
    if v == 0 then v = NONE end
    _G[n.."Text"]:SetText(format("Row gap: " .. v))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankXBreak_OnLoad(self)
    SetupBreakControl(self, "LiteBagBankPanel", "xbreak")
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankYBreak_OnLoad(self)
    SetupBreakControl(self, "LiteBagBankPanel", "ybreak")
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankXBreak_OnValueChanged(self)
    local n = self:GetName()
    local v = self:GetValue()
    if v == 0 then v = NONE end
    _G[n.."Text"]:SetText(format("Col gap: " .. v))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankYBreak_OnValueChanged(self)
    local n = self:GetName()
    local v = self:GetValue()
    if v == 0 then v = NONE end
    _G[n.."Text"]:SetText(format("Row gap:" .. v))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankOrder_OnLoad(self)
    PanelOrder_OnLoad(self, "LiteBagBankPanel")
end

function LiteBagOptionsBankLayout_OnLoad(self)
    PanelLayout_OnLoad(self, "LiteBagBankPanel")
end

function LiteBagOptionsInventoryOrder_OnLoad(self)
    PanelOrder_OnLoad(self, "LiteBagInventoryPanel")
end

function LiteBagOptionsInventoryLayout_OnLoad(self)
    PanelLayout_OnLoad(self, "LiteBagInventoryPanel")
end

