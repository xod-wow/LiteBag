--[[----------------------------------------------------------------------------

  LiteBag/UIOptions.lua

  Copyright 2016 Mike Battersby

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
            end
        self.GetOption = function (self)
                return not LiteBag_GetGlobalOption("HideEquipsetIcon")
            end
        self.GetOptionDefault = function (self) return true end
        LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryColumns_OnLoad(self)
    local n = self:GetName()

    _G[n.."Low"]:SetText("8")
    _G[n.."High"]:SetText("24")
    self.SetOption = function (self, v)
            LiteBag_SetFrameOption(LiteBagInventory, "columns", v)
            LiteBagInventory.columns = v
        end
    self.GetOption = function (self)
            return LiteBag_GetFrameOption(LiteBagInventory, "columns") or 8
        end
    self.GetOptionDefault = function (self) return 8 end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsInventoryColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Inventory columns: %d", self:GetValue()))
end

function LiteBagOptionsBankColumns_OnLoad(self)
    local n = self:GetName()

    _G[n.."Low"]:SetText("8")
    _G[n.."High"]:SetText("24")
    self.SetOption = function (self, v)
            LiteBag_SetFrameOption(LiteBagBank, "columns", v)
            LiteBagBank.columns = v
        end
    self.GetOption = function (self)
            return LiteBag_GetFrameOption(LiteBagBank, "columns") or 14
        end
    self.GetOptionDefault = function (self) return 14 end
    LiteBagOptionsControl_OnLoad(self)
end

function LiteBagOptionsBankColumns_OnValueChanged(self)
    local n = self:GetName()
    _G[n.."Text"]:SetText(format("Bank columns: %d", self:GetValue()))
end
