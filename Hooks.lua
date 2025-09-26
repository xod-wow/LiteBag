--[[----------------------------------------------------------------------------

  LiteBag/Hooks.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local _, LB = ...

-- hooksecurefunc is just too slow
local hooks = { }

function LB.RegisterHook(func, hook, includeBlizzard)
    hooks[func] = hooks[func] or { }
    hooks[func][hook] = includeBlizzard and true or false
end

function LB.UnregisterHook(func, hook)
    hooks[func][hook] = nil
end

local function GetItemButtonBagAndSlot(button)
    if button.GetBankTabID then
        return button:GetBankTabID(), button:GetContainerSlotID()
    else
        return button:GetBagID(), button:GetID()
    end
end

function LB.CallHooks(func, itemButton)
    for hook, includeBlizzard in pairs(hooks[func] or {}) do
        if includeBlizzard or itemButton.isLiteBag then
            local bag, slot = GetItemButtonBagAndSlot(itemButton)
            hook(itemButton, bag, slot)
        end
    end
end

_G.LiteBag_RegisterHook = LB.RegisterHook
_G.LiteBag_AddPluginEvent = function (...) LB.Manager:AddPluginEvent(...) end
