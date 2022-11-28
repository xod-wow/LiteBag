--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2015-2020 Mike Battersby

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

local OrderValues  = {
    ['default'] = DEFAULT,
    ['blizzard'] = 'Blizzard',
    ['reverse'] = L['Reverse'],
}

local OrderSorting = { "default", "blizzard", "reverse", }

local LayoutValues  = {
    ['default'] = DEFAULT,
    ['bag'] = L['Bags'],
    ['reverse'] = L['Reverse'],
}

local LayoutSorting = { "default", "bag", "reverse", }

local function GetQualityText(i)
    if ITEM_QUALITY_COLORS[i] then
        local desc = _G['ITEM_QUALITY'..i..'_DESC']
        return ITEM_QUALITY_COLORS[i].hex..desc..FONT_COLOR_CODE_CLOSE
    else
        return NEVER
    end
end

local function IconBorderSorting()
    local out = { }
    for i = Enum.ItemQualityMeta.NumValues-1, 0, -1 do
        table.insert(out, i)
    end
    table.insert(out, false)
    return out
end

local function IconBorderValues()
    local out = {}
    for _,k in ipairs(IconBorderSorting()) do
        out[k] = GetQualityText(k)
    end
    return out
end

local function GlobalGetter(info)
    return LB.GetGlobalOption(info[#info])
end

local function GlobalSetter(info, val)
    LB.SetGlobalOption(info[#info], val)
end

local function TypeGetter(info)
    local type, arg = info[#info-1], info[#info]
    return LB.GetTypeOption(type, arg)
end

local function TypeSetter(info, val)
    local type, arg = info[#info-1], info[#info]
    return LB.SetTypeOption(type, arg, val)
end

local order
do
    local n = 0
    order = function () n = n + 1 return n end
end

local options = {
    type = "group",
    args = {
        -- First options are just for the command line
        options = {
            type = "execute",
            name = "Show options panel",
            hidden = true,
            cmdHidden = false,
            order = order(),
            func = function () LB.OpenOptions() end,
        },
        debug = {
            type = "toggle",
            name = "Toggle debugging",
            hidden = true,
            order = order(),
            get = GlobalGetter,
            set = GlobalSetter,
        },
        eventDebug = {
            type = "toggle",
            name = "Toggle event debugging",
            hidden = true,
            order = order(),
            get = GlobalGetter,
            set = GlobalSetter,
        },
        GeneralHeader = {
            type = "header",
            name = GENERAL,
            order = order(),
        },
        showBindsOn = {
            type = "toggle",
            name = L["Display text for BoA and BoE items."],
            order = order(),
            width = "full",
            get = GlobalGetter,
            set = GlobalSetter,
        },
        showEquipmentSets = {
            type = "toggle",
            name = L["Display equipment set membership icons."],
            order = order(),
            width = "full",
            get = GlobalGetter,
            set = GlobalSetter,
        },
        hideBlizzardBagButtons = {
            type = "toggle",
            name = L["Hide Blizzard bag buttons."],
            order = order(),
            width = "full",
            disabled = function () return not LB.Manager:CanManageBagButtons() end,
            desc = function ()
                if not LB.Manager:CanManageBagButtons() then
                    local c = RED_FONT_COLOR
                    return c:WrapTextInColorCode(L["Another addon is managing the Blizzard bag buttons."])
                end
            end,
            descStyle = "inline",
            get = GlobalGetter,
            set = GlobalSetter,
        },
        iconBorderPreGap = {
            type = "description",
            name = "",
            order = order(),
        },
        thickerIconBorder = {
            type = "select",
            style = "dropdown",
            name = L["Show thicker icon borders for this quality and above."],
            order = order(),
            values = IconBorderValues,
            sorting = IconBorderSorting,
            get = GlobalGetter,
            set = GlobalSetter,
        },
        FrameHeaderPreGap = {
            type = "description",
            name = "\n",
            order = order(),
        },
        FrameHeader = {
            type = "header",
            name = L["Frame Options"],
            order = order(),
        },
        FrameHeaderPostGap = {
            type = "description",
            name = "\n",
            order = order(),
        },
        BACKPACK = {
            type = "group",
            name = BAG_NAME_BACKPACK,
            order = order(),
            args = {
                snap = {
                    type = "toggle",
                    name = L["Snap backpack frame to default backpack position."],
                    order = order(),
                    width = "full",
                    get = TypeGetter,
                    set = TypeSetter,
                },
                snapPostGap = {
                    type = "description",
                    name = "",
                    order = order(),
                },
                columns = {
                    type = "range",
                    name = "Columns",
                    min = 8,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                scale = {
                    type = "range",
                    name = "Scale",
                    min = 0.75,
                    max = 1.25,
                    step = 0.05,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                xbreak = {
                    type = "range",
                    name = "Column gaps",
                    min = 0,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                ybreak = {
                    type = "range",
                    name = "Row gaps",
                    min = 0,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                __break1 = {
                    type = "description",
                    name = "\n",
                    width = "full",
                    order = order(),
                },
                order = {
                    type = "select",
                    style = "dropdown",
                    name = L["Icon order:"],
                    values = OrderValues,
                    sorting = OrderSorting,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                __break2 = {
                    type = "description",
                    name = "\n",
                    width = "full",
                    order = order(),
                },
                layout = {
                    type = "select",
                    style = "dropdown",
                    name = L["Icon layout:"],
                    values = LayoutValues,
                    sorting = LayoutSorting,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
            },
        },
        BANK = {
            type = "group",
            name = BANK,
            order = order(),
            args = {
                columns = {
                    type = "range",
                    name = "Columns",
                    min = 8,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                scale = {
                    type = "range",
                    name = "Scale",
                    min = 0.75,
                    max = 1.25,
                    step = 0.05,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                xbreak = {
                    type = "range",
                    name = "Column gaps",
                    min = 0,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                ybreak = {
                    type = "range",
                    name = "Row gaps",
                    min = 0,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                __break1 = {
                    type = "description",
                    name = "\n",
                    width = "full",
                    order = order(),
                },
                order = {
                    type = "select",
                    style = "dropdown",
                    name = L["Icon order:"],
                    values = OrderValues,
                    sorting = OrderSorting,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                __break2 = {
                    type = "description",
                    name = "\n",
                    width = "full",
                    order = order(),
                },
                layout = {
                    type = "select",
                    style = "dropdown",
                    name = L["Icon layout:"],
                    values = LayoutValues,
                    sorting = LayoutSorting,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
            },
        },
--@debug
        REAGENTBAG = {
            type = "group",
            name = "Reagent Bag",
            order = order(),
            args = {
                columns = {
                    type = "range",
                    name = "Columns",
                    min = 4,
                    max = 8,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                __break1 = {
                    type = "description",
                    name = "\n",
                    width = "full",
                    order = order(),
                },
                order = {
                    type = "select",
                    style = "dropdown",
                    name = L["Icon order:"],
                    values = OrderValues,
                    sorting = OrderSorting,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
            },
        },
--@end-debug@
    },
}

-- The sheer amount of crap required here is ridiculous. I bloody well hate
-- frameworks, just give me components I can assemble. Dot-com weenies ruined
-- everything, even WoW.

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions =  LibStub("AceDBOptions-3.0")

-- AddOns are listed in the Blizzard panel in the order they are
-- added, not sorted by name. In order to mostly get them to
-- appear in the right order, add the main panel when loaded.

AceConfig:RegisterOptionsTable(addonName, options, { "litebag", "lb" })
local optionsPanel, category = AceConfigDialog:AddToBlizOptions(addonName)

function LB.InitializeGUIOptions()
--  local profileOptions = AceDBOptions:GetOptionsTable(LB.db)
--  AceConfig:RegisterOptionsTable(addonName.."Profiles", profileOptions)
--  AceConfigDialog:AddToBlizOptions(addonName.."Profiles", "Profiles", addonName)
end

function LB.OpenOptions()
    Settings.OpenToCategory(category)
end
