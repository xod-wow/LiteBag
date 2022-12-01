--[[----------------------------------------------------------------------------

  LiteBag/Hooks.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

-- hooksecurefunc is just too slow
local hooks = { }

function LB.RegisterHook(func, hook)
    hooks[func] = hooks[func] or { }
    hooks[func][hook] = true
end

function LB.UnregisterHook(func, hook)
    hooks[func][hook] = nil
end

function LB.CallHooks(func, self)
    for f in pairs(hooks[func] or {}) do
         f(self)
    end
end

local PluginEvents = { }

function LB.AddPluginEvent(e)
    if e == 'PLAYER_LOGIN' then return end
    PluginEvents[e] = true
end

function LB.RegisterPluginEvents(frame)
    for e in pairs(PluginEvents) do
        frame:RegisterEvent(e)
    end
end

function LB.IsPluginEvent(e)
    return PluginEvents[e]
end

function LB.UnregisterPluginEvents(frame)
    for e in pairs(PluginEvents) do
        frame:UnregisterEvent(e)
    end
end

-- Exported interface for other addons
_G.LiteBag_AddPluginEvent = LB.AddPluginEvent
_G.LiteBag_AddUpdateEvent = LB.AddPluginEvent
_G.LiteBag_RegisterHook = LB.RegisterHook
