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

local PluginUpdateEvents = { }

-- XXX FIXME XXX unimplemented
function LB.AddUpdateEvent(e)
    if e == 'PLAYER_LOGIN' then return end
    PluginUpdateEvents[e] = true
end

function LB.RegisterPluginEvents(frame)
    for e in pairs(PluginUpdateEvents) do
        frame:RegisterEvent(e)
    end
end

function LB.IsPluginEvent(e)
    return PluginUpdateEvents[e]
end

function LB.UnregisterPluginEvents(frame)
    for e in pairs(PluginUpdateEvents) do
        frame:UnregisterEvent(e)
    end
end

-- Exported interface for other addons
_G.LiteBag_AddUpdateEvent = LB.AddUpdateEvent
_G.LiteBag_RegisterHook = LB.RegisterHook
