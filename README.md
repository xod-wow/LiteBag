# LiteBag World of Warcraft Addon

For the addon, see:
- https://www.curseforge.com/wow/addons/litebag

## For Authors of Bag Icon-Plugin Addons

To support LiteBag you have two options:

1. Use LiteBag's built-in hooking by calling
   ```
   LiteBag_RegisterHook('LiteBagItemButton_Update', YourUpdateFunction)
   ```
   and optionally `LiteBag_AddUpdateEvent(eventName)` if you need LiteBag
   to update on additional events. Your function will be called once for
   every itembutton, with the itembutton as the argument.

2. Use `hooksecurefunc('LiteBagPanel_UpdateBag', yourUpdateFunc)`.
   This is equivalent to ContainerFrame_Update and you can iterate over
   the itembuttons with:
   ```
   for i = 1, self.size do local itemButton = self.itemButtons[i] end
   ```
   You can ipairs() over the itembuttons if you want but be aware
   there may be more than are actually displayed and the state of the
   non-displayed buttons is undefined.

Guild Bank and Reagent Bank are not handed by LiteBag and you will have
to hook the standard Blizzard frames for those.

The itembuttons inherit `ContainerFrameItemButtonTemplate` and anything
that works on that will also work on the LiteBag buttons.

E.g.,
```
function MyHookLiteBag()
    LiteBag_RegisterHook('LiteBagItemButton_Update',
        function (button)
            local slot = button:GetID()
            local bag = button:GetParent():GetID()
            -- your code
        end)
end
```
