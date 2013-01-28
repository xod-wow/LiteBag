--[[----------------------------------------------------------------------------

  LiteBag/ReplaceBlizzard.lua

  Copyright 2013 Mike Battersby

----------------------------------------------------------------------------]]--

local inventoryFrame, bankFrame

function LiteBagFrame_ReplaceBlizzard(inventory, bank)

    BankFrame:UnregisterAllEvents()

    inventoryFrame = inventory
    bankFrame = bank

    OpenBackpack = function () inventoryFrame:Show() end
    OpenAllBags = OpenBackpack

    ToggleBag = function (id) if inventoryFrame:IsShown() then inventoryFrame:Hide() else inventoryFrame:Show() end end
    ToggleAllBags = ToggleBag

    hooksecurefunc('CloseBackpack', function () inventoryFrame:Hide() end)
    hooksecurefunc('CloseAllBags', function () inventoryFrame:Hide() end)

    BagSlotButton_UpdateChecked = function () end

end

LiteBagFrame_ReplaceBlizzard(LiteBagInventory, LiteBagBank)
