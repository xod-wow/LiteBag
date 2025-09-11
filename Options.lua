--[[----------------------------------------------------------------------------

  LiteBag/Options.lua

  Copyright 2013 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

local defaults = {
    profile = {
        BACKPACK = {
            columns = 10,
            xbreak = 0,
            ybreak = 0,
            anchor = 'TOPLEFT',
            layout = 'default',
            order = 'default',
        },
        BANK = {
            columns = 14,
            xbreak = 0,
            ybreak = 0,
            anchor = 'TOPLEFT',
            layout = 'default',
            order = 'default',
        },
        showEquipmentSets = false,
        showBindsOn = false,
        hideBlizzardBagButtons = false,
        thickerIconBorder = false,
        debug = nil,
        eventDebug = nil,
        eventFilter = { },
    }
}

function LB.InitializeOptions()
    LiteBagDB = LiteBagDB or { }
    LB.db = LibStub("AceDB-3.0"):New("LiteBagDB", defaults, true)

    local ReFirer = {
        Fire = function () LB.db.callbacks:Fire('OnOptionsModified') end
    }

    LB.db.RegisterCallback(ReFirer, 'OnProfileChanged', 'Fire')
    LB.db.RegisterCallback(ReFirer, 'OnProfileReset', 'Fire')
    LB.db.RegisterCallback(ReFirer, 'OnProfileCopied', 'Fire')
end

function LB.SetTypeOption(key, option, value, noTrigger)
    LB.db.profile[key][option] = value
    if not noTrigger then LB.db.callbacks:Fire('OnOptionsModified') end
end

function LB.GetTypeOption(key, option)
    return LB.db.profile[key][option]
end

function LB.SetGlobalOption(option, value, noTrigger)
    LB.db.profile[option] = value
    if not noTrigger then LB.db.callbacks:Fire('OnOptionsModified') end
end

function LB.GetGlobalOption(option)
    return LB.db.profile[option]
end
