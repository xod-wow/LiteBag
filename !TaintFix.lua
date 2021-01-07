-- https://www.townlong-yak.com/bugs/Mx7CWN-RefreshOverread

if (UIDD_REFRESH_OVERREAD_PATCH_VERSION or 0) < 3 then
	UIDD_REFRESH_OVERREAD_PATCH_VERSION = 3
	local function drop(t, k)
		local c = 42
		t[k] = nil
		while not issecurevariable(t, k) do
			if t[c] == nil then
				t[c] = nil
			end
			c = c + 1
		end
	end
	hooksecurefunc("UIDropDownMenu_InitializeHelper", function()
		if UIDD_REFRESH_OVERREAD_PATCH_VERSION ~= 3 then
			return
		end
		for i=1, UIDROPDOWNMENU_MAXLEVELS do
			for j=1+_G["DropDownList" .. i].numButtons, UIDROPDOWNMENU_MAXBUTTONS do
				local b, _ = _G["DropDownList" .. i .. "Button" .. j]
				_ = issecurevariable(b, "checked")      or drop(b, "checked")
				_ = issecurevariable(b, "notCheckable") or drop(b, "notCheckable")
			end
		end
	end)
end
