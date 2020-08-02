--[[----------------------------------------------------------------------------

  LiteBag/ItemButton.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

-- hooksecurefunc is just too slow
local hooks = { }

function LiteBagItemButton_RegisterHook(func, hook)
    hooks[func] = hooks[func] or { }
    hooks[func][hook] = true
end

function LiteBagItemButton_UnregisterHook(func, hook)
    hooks[func][hook] = nil
end

function LiteBagItemButton_CallHooks(func, self)
    for f in pairs(hooks[func] or {}) do
         f(self)
    end
end
