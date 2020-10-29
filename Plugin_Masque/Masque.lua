--[[----------------------------------------------------------------------------

  LiteBag/Plugin_Masque/Masque.lua

  Copyright 2013-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

if LibStub then
    local Masque = LibStub('Masque', true)

    if Masque then

        local group = Masque:Group('LiteBag')

        LiteBag_RegisterHook(
                'LiteBagItemButton_Create',
                function (b)
                    group:AddButton(b)
                end
            )
    end
end
