--[[----------------------------------------------------------------------------

  LiteBag/Localization.lua

  LiteBag translations into other languages.

  Copyright 2013 Mike Battersby

----------------------------------------------------------------------------]]--

-- Vim reformatter from curseforge "Global Strings" export.
-- %s/^\(L\..*\) = \(.*\)/\=printf('%-24s= %s', submatch(1), submatch(2))/

local addonName, LB = ...

LB.Localize = setmetatable({ }, {__index=function (t,k) return k end})

local L = LB.Localize

local locale = GetLocale()

-- These are overrides for the defaults, which is the icons

if locale == "enUS" or locale == "enGB" then
    L["Pet"] = "Pet"
    L["BoA"] = "BoA"
end

-- :r! sh fetchlocale.sh -------------------------------------------------------

-- deDE ------------------------------------------------------------------------

if locale == "deDE" then
    L                     = L or {}
end

-- esES / esMX -----------------------------------------------------------------

if locale == "esES" or locale == "esMX" then
    L                     = L or {}
end

-- frFR ------------------------------------------------------------------------

if locale == "frFR" then
    L                     = L or {}
    L["Bags"]             = "Sacs"
    L["BoE"]              = "LqE"
    L["Display equipment set membership icons."] = "Afficher les icônes sur les Ensembles d'Équipements"
    L["Display text for BoA and BoE items."] = "Afficher un texte sur les objets \"Lié au Compte\" (Blizzard) et \"Lié quand Équipé\" (LqE)."
    L["Pet"]              = "Pet"
    L["Reverse"]          = "Inverse"
    L["Snap inventory frame to default backpack position."] = "Ancrer le cadre d'inventaire sur la position par défaut du sac à dos."
end

-- itIT ------------------------------------------------------------------------

if locale == "itIT" then
    L                     = L or {}
    L["Bags"]             = "Zaini"
    L["BoA"]              = "BoA"
    L["BoE"]              = "BoE"
    L["Display equipment set membership icons."] = "Visualizza icone tipologia equipaggiamento."
    L["Display text for BoA and BoE items."] = "Mostra testo per oggetti BoA e BoE."
    L["Pet"]              = "Mascotte"
    L["Reverse"]          = "Inversa"
    L["Snap inventory frame to default backpack position."] = "Posiziona l'inventario nella posizione dello zaino predefinita."
end

-- koKR ------------------------------------------------------------------------

if locale == "koKR" then
    L                     = L or {}
end

-- ptBR ------------------------------------------------------------------------

if locale == "ptBR" then
    L                     = L or {}
end

-- ruRU ------------------------------------------------------------------------

if locale == "ruRU" then
    L                     = L or {}
end

-- zhCN ------------------------------------------------------------------------

if locale == "zhCN" then
    L                     = L or {}
end

-- zhTW ------------------------------------------------------------------------

if locale == "zhTW" then
    L                     = L or {}
    L["Bags"]             = "背包"
    L["BoA"]              = "帳綁"
    L["BoE"]              = "裝綁"
    L["Display equipment set membership icons."] = "顯示裝備設定相關圖示"
    L["Display text for BoA and BoE items."] = "帳號綁定和裝備綁定的物品顯示文字"
    L["Pet"]              = "寵物"
    L["Reverse"]          = "反向"
    L["Snap inventory frame to default backpack position."] = "背包框架靠齊到預設位置"
end
