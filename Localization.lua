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
    L["Bottom"]           = "Unten"
    L["Bottom Left"]      = "Unten links"
    L["Bottom Right"]     = "Unten rechts"
    L["Center"]           = "Mitte"
    L["Left"]             = "Links"
    L["Right"]            = "Rechts"
    L["Top"]              = "Oben"
    L["Top Left"]         = "Oben links"
    L["Top Right"]        = "Oben rechts"
end

-- esES / esMX -----------------------------------------------------------------

if locale == "esES" or locale == "esMX" then
    L                     = L or {}
    L["Bottom"]           = "Abajo"
    L["Bottom Left"]      = "Inferior izquierda"
    L["Bottom Right"]     = "Inferior derecha"
    L["Top Left"]         = "Superior izquierda"
    L["Top Right"]        = "Superior derecha"
end

-- frFR ------------------------------------------------------------------------

if locale == "frFR" then
    L                     = L or {}
    L["Bags"]             = "Sacs"
    L["BoE"]              = "LqE"
    L["Bottom"]           = "Bas"
    L["Bottom Left"]      = "Bas gauche"
    L["Bottom Right"]     = "Bas droit"
    L["Display equipment set membership icons."] = "Afficher les icônes sur les Ensembles d'Équipements"
    L["Display text for BoA and BoE items."] = "Afficher un texte sur les objets \"Lié au Compte\" (Blizzard) et \"Lié quand Équipé\" (LqE)."
    L["Pet"]              = "Pet"
    L["Reverse"]          = "Inverse"
    L["Top Left"]         = "Haut gauche"
    L["Top Right"]        = "Haut droit"
end

-- itIT ------------------------------------------------------------------------

if locale == "itIT" then
    L                     = L or {}
    L["Bags"]             = "Zaini"
    L["BoA"]              = "BoA"
    L["BoE"]              = "BoE"
    L["Bottom Left"]      = "In basso a sinistra‎"
    L["Bottom Right"]     = "In basso a destra"
    L["Display equipment set membership icons."] = "Visualizza icone tipologia equipaggiamento."
    L["Display text for BoA and BoE items."] = "Mostra testo per oggetti BoA e BoE."
    L["Pet"]              = "Mascotte"
    L["Reverse"]          = "Inversa"
    L["Top Left"]         = "In alto a sinistra"
    L["Top Right"]        = "In alto a destra"
end

-- koKR ------------------------------------------------------------------------

if locale == "koKR" then
    L                     = L or {}
    L["Another addon is managing the Blizzard bag buttons."] = "다른 애드온에서 블리자드 가방 버튼의 설정을 변경합니다."
    L["Bags"]             = "가방"
    L["BoA"]              = "BoA"
    L["BoE"]              = "BoE"
    L["Bottom"]           = "아래"
    L["Bottom Left"]      = "좌측 하단"
    L["Bottom Right"]     = "우측 하단"
    L["Column gaps"]      = "칸 간격"
    L["Columns"]          = "칸 수"
    L["Display equipment set membership icons."] = "착용 세트에 멤버쉽 아이콘을 표시합니다."
    L["Display text for BoA and BoE items."] = "BoA 및 BoE 아이템에 글자를 표시합니다."
    L["Frame Options"]    = "프레임 설정"
    L["Hide Blizzard bag buttons."] = "블리자드 가방 버튼 숨김"
    L["Pet"]              = "애완동물"
    L["Reverse"]          = "역순"
    L["Row gaps"]         = "줄 간격"
    L["Scale"]            = "크기"
    L["Show options panel."] = "설정 창을 표시합니다."
    L["Show thicker icon borders for this quality and above."] = "두꺼운 테두리를 사용할 최소 아이템 등급"
    L["Top Left"]         = "좌측 상단"
    L["Top Right"]        = "우측 상단"
end

-- ptBR ------------------------------------------------------------------------

if locale == "ptBR" then
    L                     = L or {}
    L["Bottom"]           = "Embaixo"
    L["Bottom Left"]      = "Em Baixo a Esquerda"
    L["Bottom Right"]     = "Em Baixo a Direita"
    L["Top Left"]         = "Em Cima a Esquerda"
    L["Top Right"]        = "Em Cima a Direita"
end

-- ruRU ------------------------------------------------------------------------

if locale == "ruRU" then
    L                     = L or {}
    L["Bottom"]           = "Снизу"
    L["Bottom Left"]      = "Снизу слева"
    L["Bottom Right"]     = "Снизу справа"
    L["Top Left"]         = "Вверху cлева"
    L["Top Right"]        = "Вверху cправа"
end

-- zhCN ------------------------------------------------------------------------

if locale == "zhCN" then
    L                     = L or {}
    L["Another addon is managing the Blizzard bag buttons."] = "另外一个插件正在管理暴雪背包按钮"
    L["Bags"]             = "背包"
    L["Blizzard"]         = "暴雪"
    L["BoA"]              = "账绑"
    L["BoE"]              = "装绑"
    L["Bottom"]           = "下"
    L["Bottom Left"]      = "左下"
    L["Bottom Right"]     = "右下"
    L["Center"]           = "中心"
    L["Column gaps"]      = "列间距"
    L["Columns"]          = "列数"
    L["Display equipment set membership icons."] = "显示装备设定相关图示"
    L["Display text for BoA and BoE items."] = "在物品上显示账号绑定和装备绑定的缩写文字"
    L["First icon position:"] = "第一个图标位置"
    L["Frame Options"]    = "框架选项"
    L["Hide Blizzard bag buttons."] = "隐藏暴雪背包按钮"
    L["Icon layout:"]     = "图标布局:"
    L["Icon order:"]      = "图标顺序:"
    L["Left"]             = "左边"
    L["Pet"]              = "宠物"
    L["Reagent Bag"]      = "装备材料包"
    L["Reverse"]          = "反向"
    L["Right"]            = "右边"
    L["Row gaps"]         = "行间距"
    L["Scale"]            = "缩放"
    L["Shift Click to Hide/Show Bag"] = "按住 Shift 键点击隐藏或显示背包"
    L["Show bag buttons."] = "显示背包按钮"
    L["Show options panel."] = "显示选项面板"
    L["Show thicker icon borders for this quality and above."] = "在此品质及以上的物品显示更粗的图标边框"
    L["Top"]              = "顶部"
    L["Top Left"]         = "左上"
    L["Top Right"]        = "右上"
    L["War"]              = "战团"
    L["When moving snap frame to default position."] = "移动时将框架固定到默认位置"
end

-- zhTW ------------------------------------------------------------------------

if locale == "zhTW" then
    L                     = L or {}
    L["Another addon is managing the Blizzard bag buttons."] = "另一個插件是管理暴雪背包按鈕。"
    L["Bags"]             = "背包"
    L["Blizzard"]         = "暴雪"
    L["BoA"]              = "帳綁"
    L["BoE"]              = "裝綁"
    L["Bottom"]           = "下"
    L["Bottom Left"]      = "左下"
    L["Bottom Right"]     = "右下"
    L["Center"]           = "中央"
    L["Column gaps"]      = "行距"
    L["Columns"]          = "行數"
    L["Display equipment set membership icons."] = "顯示裝備設定相關圖示"
    L["Display text for BoA and BoE items."] = "帳號綁定和裝備綁定的物品顯示文字"
    L["First icon position:"] = "第一個圖示位置:"
    L["Frame Options"]    = "框架選項"
    L["Hide Blizzard bag buttons."] = "隱藏暴雪背包按鈕。"
    L["Icon layout:"]     = "圖示布局："
    L["Icon order:"]      = "圖示順序："
    L["Left"]             = "左"
    L["Pet"]              = "寵物"
    L["Reagent Bag"]      = "材料背包"
    L["Reverse"]          = "反向"
    L["Right"]            = "右"
    L["Row gaps"]         = "欄距"
    L["Scale"]            = "縮放"
    L["Shift Click to Hide/Show Bag"] = "Shift點擊來隱藏/顯示背包"
    L["Show bag buttons."] = "顯示背包按鈕。"
    L["Show options panel."] = "顯示選項面板。"
    L["Show thicker icon borders for this quality and above."] = "在此品質及以上物品顯示更粗的圖示邊框。"
    L["Top"]              = "上"
    L["Top Left"]         = "左上"
    L["Top Right"]        = "右上"
    L["War"]              = "戰隊"
    L["When moving snap frame to default position."] = "當移動快照框至預設位置時。"
end
