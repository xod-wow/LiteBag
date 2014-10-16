--[[----------------------------------------------------------------------------

  LiteBag/ReplaceBlizzard.lua

  Copyright 2013-2014 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local inventoryFrame, bankFrame

function LiteBagFrame_ReplaceBlizzard(inventory, bank)

    BankFrame:UnregisterAllEvents()

    inventoryFrame = inventory
    bankFrame = bank

    local hideFunc = function () LiteBagFrame_Hide(inventoryFrame) end
    local showFunc = function () LiteBagFrame_Show(inventoryFrame) end
    local toggleFunc = function () LiteBagFrame_ToggleShown(inventoryFrame) end

    OpenBackpack = showFunc
    OpenAllBags = showFunc

    ToggleBag = toggleFunc
    ToggleAllBags = toggleFunc

    hooksecurefunc('CloseBackpack', hideFunc)
    hooksecurefunc('CloseAllBags', hideFunc)

    BagSlotButton_UpdateChecked = function () end

end

LiteBagFrame_ReplaceBlizzard(LiteBagInventory, LiteBagBank)
