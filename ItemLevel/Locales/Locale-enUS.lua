
ItemLevel_Localization = {
	["Font:"] = true,
	["Text Size"] = true,
	["Anchor:"] = true,
	["Use Quality Color Text"] = true,
	["Border Alpha"] = true,
	["Show Average ItemLevel"] = true,
	["Show Transmog Icons"] = true,
	["Reset"] = true,
	["Are you sure you want to reset all settings to default?"] = true,
	["Yes"] = true,
	["No"] = true,
	["Displays ilvl and border color on the character and inspect panels.\nAllows you to choose between original and transmog icons.\n\nAuthor: |cffc41f3bKhal|r\nVersion: %s"] = true,
}

function ItemLevel_Localization:CreateLocaleTable(t)
	for k,v in pairs(t) do
		self[k] = (v == true and k) or v
	end
end

ItemLevel_Localization:CreateLocaleTable(ItemLevel_Localization)