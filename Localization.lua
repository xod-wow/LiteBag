--[[----------------------------------------------------------------------------

  LiteBag/Localization.lua

  LiteBag translations into other languages.

  Copyright 2013-2018 Mike Battersby

----------------------------------------------------------------------------]]--

-- Vim reformatter from curseforge "Global Strings" export.
-- %s/^\(L\..*\) = \(.*\)/\=printf('%-24s= %s', submatch(1), submatch(2))/

LiteBag_Localize = setmetatable({ }, {__index=function (t,k) return k end})

local L = LiteBag_Localize

local locale = GetLocale()

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
end

-- itIT ------------------------------------------------------------------------

if locale == "itIT" then
    L                     = L or {}
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
end

