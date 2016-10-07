--[[----------------------------------------------------------------------------

  LiteBag/UIOptions.lua

  Copyright 2015-2016 Mike Battersby

----------------------------------------------------------------------------]]--


function LiteBagOptionsConfirmSort_OnLoad(self)
        self.Text:SetText("Confirm before sorting.")
        self.SetOption = function (self, setting)
                if not setting or setting == "0" then
                    LiteBag_SetGlobalOption("NoConfirmSort", true)
                else
                    LiteBag_SetGlobalOption("NoConfirmSort", nil)
                end
            end
        self.GetOption = function (self)
                return not LiteBag_GetGlobalOption("NoConfirmSort")
            end
        self.GetOptionDefault = function (self) return true end
        LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsEquipsetDisplay_OnLoad(self)
        self.Text:SetText("Display equipment set membership icons.")
        self.SetOption = function (self, setting)
                if not setting or setting == "0" then
                    LiteBag_SetGlobalOption("HideEquipsetIcon", true)
                else
                    LiteBag_SetGlobalOption("HideEquipsetIcon", nil)
                end
                LiteBagFrame_Update(LiteBagInventory)
                LiteBagFrame_Update(LiteBagBank)
            end
        self.GetOption = function (self)
                return not LiteBag_GetGlobalOption("HideEquipsetIcon")
            end
        self.GetOptionDefault = function (self) return true end
        LiteBagOptionsControl_OnLoad(self)
end

local function SetupColumnsControl(self, panel, default)
    local n = self:GetName()

    _G[n.."Low"]:SetText("8")
    _G[n.."High"]:SetText("24")
    self.SetOption = function (self, v)
            LiteBag_SetPanelOption(panel, "columns", v)
        end
    self.GetOption = function (self)
            return LiteBag_GetPanelOption(panel, "columns") or default
        end
    self.GetOptionDefault = function (self) return default end
end

local function SetupScaleControl(self, panel)
    local n = self:GetName()
    _G[n.."Low"]:SetText(0.75)
    _G[n.."High"]:SetText(1.25)
    self.SetOption = function (self, v)
            LiteBag_SetPanelOption(panel, "scale", v)
        end
    self.GetOption = function (self)
            return LiteBag_GetPanelOption(panel, "scale") or 1.0
        end
    self.GetOptionDefault = function (self) return 1.0 end
end

function LiteBagOptionsInventoryColumns_OnLoad(self)
    SetupColumnsControl(self, LiteBagInventory, 8)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Inventory columns: %d", self:GetValue()))
    LiteBagOptionsControl_OnChange(self)
end

function LiteBagOptionsInventoryScale_OnLoad(self)
    SetupScaleControl(self, LiteBagInventoryPanel)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryScale_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Inventory scale: %0.2f", self:GetValue()))
    LiteBagOptionsControl_OnChange(self)
end

function LiteBagOptionsBankColumns_OnLoad(self)
    SetupColumnsControl(self, LiteBagBankPanel, 14)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Bank columns: %d", self:GetValue()))
    LiteBagOptionsControl_OnChange(self)
end

function LiteBagOptionsBankScale_OnLoad(self)
    SetupScaleControl(self, LiteBagBankPanel)
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankScale_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Bank scale: %0.2f", self:GetValue()))
    LiteBagOptionsControl_OnChange(self)
end

