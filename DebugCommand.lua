local eqTextures = {
    ["plain" ] = "Interface\\Addons\\LiteBag\\Artwork\\EquipSets",
    ["abcd"]   = "Interface\\Addons\\LiteBag\\Artwork\\EquipSetsABCD",
    ["bb"]     = "Interface\\Addons\\LiteBag\\Artwork\\EquipSetsBB",
    ["num"]    = "Interface\\Addons\\LiteBag\\Artwork\\EquipSetsNum",
    ["shield"] = "Interface\\Addons\\LiteBag\\Artwork\\EquipSetsShield",
}

function LiteBag_SlashCommandFunc(argstr)

    local inv, bank = LiteBagInventory, LiteBagBank

    if not eqTextures[argstr] then
        print("Usage: /lb {plain,abcd,bb,num,shield}")
        return
    end

    local buttons = { }
    for _,b in ipairs(inv.itemButtons) do tinsert(buttons, b) end
    for _,b in ipairs(bank.itemButtons) do tinsert(buttons, b) end

    for _,b in ipairs(buttons) do
        b.eqTexture1:SetTexture(eqTextures[argstr])
        b.eqTexture2:SetTexture(eqTextures[argstr])
        b.eqTexture3:SetTexture(eqTextures[argstr])
        b.eqTexture4:SetTexture(eqTextures[argstr])
    end
end

SlashCmdList["LiteBag"] = LiteBag_SlashCommandFunc
SLASH_LiteBag1 = "/lb"
SLASH_LiteBag2 = "/litebag"
