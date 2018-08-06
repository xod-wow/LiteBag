--[[----------------------------------------------------------------------------

  LiteBag/UIOptions.lua

  Copyright 2015-2016 Mike Battersby

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

local function ThickerIconBorder_Initialize(self, level)
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
function LiteBagOptionsThickerIconBorder_OnLoad(self)
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
    UIDropDownMenu_Initialize(self, ThickerIconBorder_Initialize)
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

function LiteBagOptionsInventoryColumns_OnLoad(self)
    SetupColumnsControl(self, "LiteBagInventoryPanel", 8)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Inventory columns: %d", self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsInventoryScale_OnLoad(self)
    SetupScaleControl(self, "LiteBagInventory")
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryScale_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Inventory scale: %0.2f", self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankColumns_OnLoad(self)
    SetupColumnsControl(self, "LiteBagBankPanel", 14)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Bank columns: %d", self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

function LiteBagOptionsBankScale_OnLoad(self)
    SetupScaleControl(self, "LiteBagBank")
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankScale_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Bank scale: %0.2f", self:GetValue()))
    LiteBagOptionsControl_OnChanged(self)
end

