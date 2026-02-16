--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2015 Mike Battersby

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

local LayoutValues  = {
    ['default'] = DEFAULT,
    ['topleft'] = L['Align to top left'],
    ['bags']    = L['Gap between bags'],
}

local LayoutSorting = { 'default', 'topleft', 'bags', }

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

local options = {
    type = "group",
    plugins = { ALL = {} },
    args = {
        -- First options are just for the command line
        options = {
            type = "execute",
            name = L["Show options panel."],
            hidden = true,
            cmdHidden = false,
            order = 1,
            func = function () LB.OpenOptions() end,
        },
        debug = {
            type = "toggle",
            name = L["Enable debugging."],
            hidden = true,
            order = 2,
            get = GlobalGetter,
            set = GlobalSetter,
        },
        GeneralHeader = {
            type = "header",
            name = GENERAL,
            order = 3,
        },
        hideBlizzardBagButtons = {
            type = "toggle",
            name = L["Hide Blizzard bag buttons."],
            order = 10,
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
        PluginsHeaderPreGap = {
            type = "description",
            name = "\n",
            order = 50,
        },
        PluginsHeader = {
            type = "header",
            name = L["Plugins"],
            order = 51,
        },
        FrameHeaderPreGap = {
            type = "description",
            name = "\n",
            order = 997,
        },
        FrameHeader = {
            type = "header",
            name = L["Frame Options"],
            order = 998,
        },
        FrameHeaderPostGap = {
            type = "description",
            name = "\n",
            order = 999,
        },
        BACKPACK = {
            type = "group",
            name = COMBINED_BAG_TITLE,
            order = 1000,
            args = {
                bagButtons = {
                    type = "toggle",
                    name = L["Show bag buttons."],
                    order = 1010,
                    width = "full",
                    get = TypeGetter,
                    set = TypeSetter,
                },
                snap = {
                    type = "toggle",
                    name = L["When moving snap frame to default position."],
                    order = 1020,
                    width = "full",
                    get = TypeGetter,
                    set = TypeSetter,
                },
                columns = {
                    type = "range",
                    name = L["Columns"],
                    min = 8,
                    max = 48,
                    step = 1,
                    order = 1030,
                    get = TypeGetter,
                    set = TypeSetter,
                },
                columnFillSpacer = {
                    type = "description",
                    name = "\n",
                    order = 1040,
                },
                xbreak = {
                    type = "range",
                    name = L["Column gaps"],
                    min = 0,
                    max = 32,
                    step = 1,
                    order = 1050,
                    get = TypeGetter,
                    set = TypeSetter,
                },
                ybreak = {
                    type = "range",
                    name = L["Row gaps"],
                    min = 0,
                    max = 32,
                    step = 1,
                    order = 1060,
                    get = TypeGetter,
                    set = TypeSetter,
                    disabled = function () return LB.db.profile.BACKPACK.layout == 'bags' end,
                },
                layout = {
                    type = "select",
                    style = "dropdown",
                    name = L["Icon layout:"],
                    values = LayoutValues,
                    sorting = LayoutSorting,
                    order = 1070,
                    width = 1.5,
                    get = TypeGetter,
                    set = TypeSetter,
                },
            },
        },
    },
}

local function GenerateOptions()
    local order = 100
    table.wipe(options.plugins.ALL)

    local nameList = GetKeysArray(LB.PluginOptions)
    table.sort(nameList,
        function (a, b)
            local nameA = L[LB.PluginOptions[a].name]
            local nameB = L[LB.PluginOptions[b].name]
            return nameA < nameB
        end)

    for _, name in ipairs(nameList) do
        local option = CopyTable(LB.PluginOptions[name])

        if option.type == "select" then
            local preGap = {
                type = "description",
                name = "",
                order = order,
            }
            options.plugins.ALL[name.."PreGap"] = preGap
            order = order + 10
        end

        option.order = order
        option.get = GlobalGetter
        option.set = GlobalSetter
        options.plugins.ALL[name] = option
        order = order + 10

        if option.type == "select" then
            local postGap = {
                type = "description",
                name = "",
                order = order,
            }
            options.plugins.ALL[name.."PostGap"] = postGap
            order = order + 10
        end

    end
    return options
end

-- The sheer amount of crap required here is ridiculous. I bloody well hate
-- frameworks, just give me components I can assemble. Dot-com weenies ruined
-- everything, even WoW.

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions =  LibStub("AceDBOptions-3.0")

-- AddOns are listed in the Blizzard panel in the order they are
-- added, not sorted by name. In order to mostly get them to
-- appear in the right order, add the main panel when loaded.

AceConfig:RegisterOptionsTable(addonName, GenerateOptions, { "litebag", "lb" })
local optionsPanel, category = AceConfigDialog:AddToBlizOptions(addonName) -- luacheck: ignore 211

function LB.InitializeGUIOptions()
    local profileOptions = AceDBOptions:GetOptionsTable(LB.db)
    AceConfig:RegisterOptionsTable(addonName.."Profiles", profileOptions)
    AceConfigDialog:AddToBlizOptions(addonName.."Profiles", profileOptions.name, addonName)
end

function LB.OpenOptions()
    Settings.OpenToCategory(category)
end
