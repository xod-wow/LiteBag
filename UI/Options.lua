--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2015 Mike Battersby

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local L = LB.Localize

local function GetQualityText(i)
    if ITEM_QUALITY_COLORS[i] then
        local desc = _G['ITEM_QUALITY'..i..'_DESC']
        return ITEM_QUALITY_COLORS[i]:WrapTextInColorCode(desc)
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
            name = L["Show options panel."],
            hidden = true,
            cmdHidden = false,
            order = order(),
            func = function () LB.OpenOptions() end,
        },
        debug = {
            type = "toggle",
            name = L["Enable debugging."],
            hidden = true,
            order = order(),
            get = GlobalGetter,
            set = GlobalSetter,
        },
        allowhide = {
            type = "multiselect",
            name = L["Allow hiding a bag ID."],
            values =
                function ()
                    local t = tInvert(Enum.BagIndex)
                    t[Enum.BagIndex.Backpack] = nil
                    t[Enum.BagIndex.Bank] = nil
                    t[Enum.BagIndex.Reagentbank] = nil
                    t[Enum.BagIndex.Bankbag] = nil
                    t[Enum.BagIndex.Keyring] = nil
                    return t
                end,
            hidden = true,
            order = order(),
            get =
                function (info, i) -- luacheck: ignore 212/info
                    local allow = LB.GetGlobalOption('allowHideBagIDs')
                    return allow[i] == true
                 end,
            set =
                function (info, i, val) -- luacheck: ignore 212/info
                    local allow = LB.GetGlobalOption('allowHideBagIDs')
                    allow[i] = val or nil
                    LB.SetGlobalOption('allowHideBagIDs', allow)
                    -- Force it to be shown again if it was hidden
                    if not val then
                        local hide = LB.GetGlobalOption('hideBagIDs')
                        hide[i] = nil
                        LB.SetGlobalOption('hideBagIDs', hide)
                    end
                end,
        },
        eventDebug = {
            type = "toggle",
            name = L["Enable event debugging."],
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
            name = L["Display text for Warbound and BoE items."],
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
            name = COMBINED_BAG_TITLE,
            order = order(),
            args = {
                bagButtons = {
                    type = "toggle",
                    name = L["Show bag buttons."],
                    order = order(),
                    width = "full",
                    get = TypeGetter,
                    set = TypeSetter,
                },
                snap = {
                    type = "toggle",
                    name = L["When moving snap frame to default position."],
                    order = order(),
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
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                columnFillSpacer = {
                    type = "description",
                    name = "\n",
                    order = order(),
                },
                xbreak = {
                    type = "range",
                    name = L["Column gaps"],
                    min = 0,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                ybreak = {
                    type = "range",
                    name = L["Row gaps"],
                    min = 0,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
--[[
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
                    width = "1",
                    get = TypeGetter,
                    set = TypeSetter,
                },
                anchor = {
                    type = "select",
                    style = "dropdown",
                    name = L["First icon position:"],
                    values = AnchorValues,
                    sorting = AnchorSorting,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
]]
            },
        },
--[[
        BANK = {
            type = "group",
            name = BANK,
            order = order(),
            args = {
                columns = {
                    type = "range",
                    name = L["Columns"],
                    min = 8,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                columnFillSpacer = {
                    type = "description",
                    name = "\n",
                    order = order(),
                },
                xbreak = {
                    type = "range",
                    name = L["Column gaps"],
                    min = 0,
                    max = 32,
                    step = 1,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
                ybreak = {
                    type = "range",
                    name = L["Row gaps"],
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
                anchor = {
                    type = "select",
                    style = "dropdown",
                    name = L["First icon position:"],
                    values = AnchorValues,
                    sorting = AnchorSorting,
                    order = order(),
                    get = TypeGetter,
                    set = TypeSetter,
                },
            },
        },
]]
    },
}

-- The sheer amount of crap required here is ridiculous. I bloody well hate
-- frameworks, just give me components I can assemble. Dot-com weenies ruined
-- everything, even WoW.

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions =  LibStub("AceDBOptions-3.0")

-- AddOns are listed in the Blizzard panel in the order they are
-- added, not sorted by name. In order to mostly get them to
-- appear in the right order, add the main panel when loaded.

AceConfig:RegisterOptionsTable(addonName, options, { "litebag", "lb" })
local optionsPanel, category = AceConfigDialog:AddToBlizOptions(addonName) -- luacheck: ignore 211

function LB.InitializeGUIOptions()
    local profileOptions = AceDBOptions:GetOptionsTable(LB.db)
    AceConfig:RegisterOptionsTable(addonName.."Profiles", profileOptions)
    AceConfigDialog:AddToBlizOptions(addonName.."Profiles", profileOptions.name, addonName)
end

function LB.OpenOptions()
    Settings.OpenToCategory(category)
end
