# LiteBag World of Warcraft Addon

For the addon, see:
- https://www.curseforge.com/wow/addons/litebag

The classic branch is still a full bag addon providing unified bag
and bank frames. The retail branch is now only a restyler of the
Blizzard frames.


## For Authors of Bag Icon-Plugin Addons

This is really only relevant for classic. On retail you can just hook
all of the Blizzard stuff and it'll work. On the other hand, this will
conveniently hook all the Blizzard stuff without you having to find it
all.

To support LiteBag you can hook into ItemButton update and create as follows:

1. Update:
   ```
   LiteBag_RegisterHook('LiteBagItemButton_Update', YourUpdateFunction)
   ```
   and optionally `LiteBag_AddPluginEvent(eventName)` if you need LiteBag
   to update on additional events. Your function will be called once for
   every itembutton, with the itembutton as the argument.

2. Create:
   ```
   LiteBag_RegisterHook(`LiteBagItemButton_Create', YourFunction)
   ```

Guild Bank and Reagent Bank are not handed by LiteBag and you will have
to hook the standard Blizzard frames for those.

The itembuttons inherit `ContainerFrameItemButtonTemplate` and anything
that works on that will also work on the LiteBag buttons.

E.g.,
```
if LiteBag_RegisterHook then
    LiteBag_RegisterHook('LiteBagItemButton_Update',
        function (button)
            local bag, slot = button:GetBagID(), button:GetID()
            -- your code
        end)
end
```
