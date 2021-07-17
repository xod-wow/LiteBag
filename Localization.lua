--[[----------------------------------------------------------------------------

  LiteBag/Localization.lua

  LiteBag translations into other languages.

  Copyright 2013-2020 Mike Battersby

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
    L["%s: No confirmation"] = "%s: Ne pas confirmer"
    L["Bag sort confirmation popup:"] = "Popup de confirmation du tri du sac"
    L["Bags"]             = "Sacs"
    L["Bank button layout set to:"] = "Disposition des boutons de banque définie sur:"
    L["Bank button order set to:"] = "Ordre des boutons de banque défini sur:"
    L["Bank columns set to:"] = "Colonnes de la banque définies sur:"
    L["Bank scale set to: %0.2f"] = "Échelle de la banque définie sur: %0.2f"
    L["BoE"]              = "LqE"
    L["Can't set number of columns to less than 8."] = "Impossible de définir un nombre de colonnes inférieur à 8."
    L["Columns: %d"]      = "Colonnes: %d"
    L["Confirm before sorting."] = "Confirmer avant de trier"
    L["Debugging:"]       = "Débogage"
    L["Display equipment set membership icons."] = "Afficher les icônes sur les Ensembles d'Équipements"
    L["Display text for BoA and BoE items."] = "Afficher un texte sur les objets \"Lié au Compte\" (Blizzard) et \"Lié quand Équipé\" (LqE)."
    L["Equipment set icon display:"] = "Afficher les icônes sur l'Équipement"
    L["Gap: %d columns"]  = "Écart: %d colonne(s)"
    L["Gap: %d rows"]     = "Écart: %d rangée(s)"
    L["Inventory button layout set to:"] = "Disposition du bouton d'inventaire définie sur:"
    L["Inventory button order set to:"] = "Ordre du bouton d'inventaire défini sur:"
    L["Inventory columns set to:"] = "Colonnes de l'inventaire définies sur:"
    L["Inventory gaps set to: %s %s"] = "Écarts de l'inventaire définis sur:"
    L["Inventory scale set to: %0.2f"] = "Échelle de l'inventaire définie sur: %0.2f"
    L["Inventory snap to default position:"] = "Inventaire ancré à la position par défaut:"
    L["No column gaps"]   = "Écart de colonnes nul"
    L["No row gaps"]      = "Écart de rangées nul"
    L["Pet"]              = "Pet"
    L["Reverse"]          = "Inverse"
    L["Scale must be between 0 and 2."] = "L'écart doit être entre 0 et 2."
    L["Scale: %0.2f"]     = "Échelle : %0.2f"
    L["Snap inventory frame to default backpack position."] = "Ancrer le cadre d'inventaire sur la position par défaut du sac à dos."
end

-- itIT ------------------------------------------------------------------------

if locale == "itIT" then
    L                     = L or {}
    L["%s: No confirmation"] = "%s: Non confermata"
    L["Bag sort confirmation popup:"] = "Popup di conferma per l'ordinamento dello zaino"
    L["Bags"]             = "Zaini"
    L["Bank button layout set to:"] = "Disposizione dei pulsanti della banca impostata su:"
    L["Bank button order set to:"] = "Ordine dei pulsanti della banca impostati su:"
    L["Bank columns set to:"] = "Colonne della banca impostate su:"
    L["Bank scale set to: %0.2f"] = "Scala della banca impostata su: %0.2f"
    L["BoA"]              = "BoA"
    L["BoE"]              = "BoE"
    L["Can't set number of columns to less than 8."] = "Non puoi impostare il numero delle colonne meno di 8."
    L["Columns: %d"]      = "Colonne: %d"
    L["Confirm before sorting."] = "Conferma prima di riordinare."
    L["Debugging:"]       = "Debug:"
    L["Display equipment set membership icons."] = "Visualizza le icone di appartenenza dell'equipaggiamento."
    L["Display text for BoA and BoE items."] = "Mostra testo per oggetti BoA e BoE."
    L["Equipment set icon display:"] = "Mostra icone sull'equipaggiamento:"
    L["Gap: %d columns"]  = "Spaziatura: %d tra colonne"
    L["Gap: %d rows"]     = "Spaziatura: %d tra righe"
    L["Inventory button layout set to:"] = "Disposizione dei pulsanti dell'inventario impostata su:"
    L["Inventory button order set to:"] = "Ordine dei pulsanti dell'inventario impostato su:"
    L["Inventory columns set to:"] = "Colonne dell'inventario impostate su:"
    L["Inventory gaps set to: %s %s"] = "Spaziature nell'inventario impostate su: %s %s"
    L["Inventory scale set to: %0.2f"] = "Scala dell'inventario impostata su: %0.2f"
    L["Inventory snap to default position:"] = "Posizione inventario predefinita:"
    L["No column gaps"]   = "No spaziatura tra colonne"
    L["No row gaps"]      = "No spaziatura tra righe"
    L["Pet"]              = "Pet"
    L["Reverse"]          = "Inversione"
    L["Scale must be between 0 and 2."] = "La scala deve essere compresa tra 0 e 2."
    L["Scale: %0.2f"]     = "Scala: %0.2f"
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
    L["%s: No confirmation"] = "按住%s點擊: 不用確認"
    L["Bag sort confirmation popup:"] = "清理背包確認彈出通知:"
    L["Bags"]             = "背包"
    L["Bank button layout set to:"] = "銀行按鈕位置設為:"
    L["Bank button order set to:"] = "銀行按鈕順序設為:"
    L["Bank columns set to:"] = "銀行直欄設為:"
    L["Bank scale set to: %0.2f"] = "銀行縮放大小設為: %0.2f"
    L["BoA"]              = "帳綁"
    L["BoE"]              = "裝綁"
    L["Can't set number of columns to less than 8."] = "欄位數目不能小於 8。"
    L["Columns: %d"]      = "欄數: %d"
    L["Confirm before sorting."] = "清理前需要確認"
    L["Debugging:"]       = "除錯:"
    L["Display equipment set membership icons."] = "顯示裝備設定相關圖示"
    L["Display text for BoA and BoE items."] = "帳號綁定和裝備綁定的物品顯示文字"
    L["Equipment set icon display:"] = "裝備設定圖示顯示:"
    L["Gap: %d columns"]  = "間距: 每 %d 欄"
    L["Gap: %d rows"]     = "間距: 每 %d 列"
    L["Inventory button layout set to:"] = "背包按鈕位置設為:"
    L["Inventory button order set to:"] = "背包按鈕順序設為:"
    L["Inventory columns set to:"] = "背包直欄設為:"
    L["Inventory gaps set to: %s %s"] = "背包間距設為:"
    L["Inventory scale set to: %0.2f"] = "背包縮放大小設為: %0.2f"
    L["Inventory snap to default position:"] = "背包靠齊預設位置:"
    L["No column gaps"]   = "沒有欄間距"
    L["No row gaps"]      = "沒有列間距"
    L["Pet"]              = "寵物"
    L["Reverse"]          = "反向"
    L["Scale must be between 0 and 2."] = "縮放大寫必須介於 0 和 2 之間。"
    L["Scale: %0.2f"]     = "縮放大小: %0.2f"
    L["Snap inventory frame to default backpack position."] = "背包框架靠齊到預設位置"
end
