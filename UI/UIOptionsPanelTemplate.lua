--[[----------------------------------------------------------------------------

  LiteBag/UIOptionsPanelTemplate.lua

  Copyright 2015-2020 Mike Battersby

  This is a half-baked reimplementation of what Blizzard have done in their
  OptionsPanelTemplates.lua, except I want the controls to update live and
  the "Cancel" button to revert them all to the original value.

  I suspect you can probably do that with the Blizzard code as well if you try,
  but that would take me longer than writing my own.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

function LiteBagOptionsPanel_Open()
    SettingsPanel:Show()
    InterfaceOptionsFrame_OpenToCategory(LiteBagOptions)
end

function LiteBagOptionsPanel_SaveOldOptions(self)
    for _,control in ipairs(self.controls or {}) do
        control.oldValue = control:GetOption()
    end
end

function LiteBagOptionsPanel_ClearOldOptions(self)
    for _,control in ipairs(self.controls or {}) do
        control.oldValue = nil
    end
end

function LiteBagOptionsPanel_RestoreOldOptions(self)
    for _,control in ipairs(self.controls or {}) do
        if control.oldValue ~= nil then
            control:SetOption(control.oldValue)
            control.oldValue = nil
        end
    end
end

function LiteBagOptionsPanel_Refresh(self)
    LB.Debug('Refresh ' .. self:GetName())
    for _,control in ipairs(self.controls or {}) do
        control:SetControl(control:GetOption())
    end
end

function LiteBagOptionsPanel_Default(self)
    LB.Debug('Default ' .. self:GetName())
    for _,control in ipairs(self.controls or {}) do
        if control.GetOptionDefault then
            control:SetOption(control:GetOptionDefault())
        end
    end
end

function LiteBagOptionsPanel_Okay(self)
    LiteBagOptionsPanel_ClearOldOptions(self)
end

function LiteBagOptionsPanel_Cancel(self)
    LiteBagOptionsPanel_RestoreOldOptions(self)
    LiteBagOptionsPanel_ClearOldOptions(self)
end

function LiteBagOptionsPanel_RegisterControl(control, parent)
    parent = parent or control:GetParent()
    parent.controls = parent.controls or { }
    tinsert(parent.controls, control)
end

function LiteBagOptionsPanel_OnShow(self)
    LiteBagOptions.CurrentOptionsPanel = self
    LB.Options:RegisterCallback(self, 'refresh')

    LiteBagOptionsPanel_SaveOldOptions(self)
    LiteBagOptionsPanel_Refresh(self)
end

function LiteBagOptionsPanel_OnHide(self)
    LB.Options:UnregisterAllCallbacks(self)
    LiteBagOptionsPanel_Okay(self)
end

function LiteBagOptionsPanel_OnLoad(self)

    self.Title:SetText(self.name)

    self.okay = self.okay or LiteBagOptionsPanel_Okay
    self.cancel = self.cancel or LiteBagOptionsPanel_Cancel
    self.default = self.default or LiteBagOptionsPanel_Default
    self.refresh = self.refresh or LiteBagOptionsPanel_Refresh

    InterfaceOptions_AddCategory(self)
end

function LiteBagOptionsControl_GetControl(self)
    if self.GetValue then
        return self:GetValue()
    elseif self.GetChecked then
        return self:GetChecked()
    elseif self.GetText then
        self:GetText()
    end
end

function LiteBagOptionsControl_SetControl(self, v)
    if self.SetValue then
        self:SetValue(v)
    elseif self.SetChecked then
        if v then self:SetChecked(true) else self:SetChecked(false) end
    elseif self.SetText then
        self:SetText(v or "")
    end
end

function LiteBagOptionsControl_OnChanged(self)
    if self.GetControl and self:GetControl() ~= self:GetOption() then
        LB.Debug('OnChanged ' .. self:GetName())
        self:SetOption(self:GetControl())
    end
end

function LiteBagOptionsControl_OnLoad(self, parent)
    self.GetOption = self.GetOption or function (self) end
    self.SetOption = self.SetOption or function (self, v) end
    self.GetControl = self.GetControl or LiteBagOptionsControl_GetControl
    self.SetControl = self.SetControl or LiteBagOptionsControl_SetControl

    -- Note we don't set an OnShow per control, the panel handler takes care
    -- of running the refresh for all the controls in its OnShow

    LiteBagOptionsPanel_RegisterControl(self, parent)
end

function LiteBagOptionsSlider_OnMouseWheel(self, direction)
    self:SetValue(self:GetValue() + direction * self:GetValueStep())
end
