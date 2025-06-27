
if GetLocale() ~= "esMX" then return end

ItemLevel_Localization:CreateLocaleTable({
	["Font:"] = "Fuente:",
	["Text Size"] = "Tamaño de Texto",
	["Anchor:"] = "Anclaje:",
	["Use Quality Color Text"] = "Texto con Color de Calidad",
	["Border Alpha"] = "Opacidad del borde",
	["Show Average ItemLevel"] = "Mostrar ItemLevel Promedio",
	["Show Transmog Icons"] = "Iconos de Transfiguración",
	["Reset"] = "Resetear",
	["Are you sure you want to reset all settings to default?"] = "Estás seguro que deseas restablecer la configuración a los valores por defecto?",
	["Yes"] = "Si",
	["No"] = "No",
	["Displays ilvl and border color on the character and inspect panels.\nAllows you to choose between original and transmog icons.\n\nAuthor: |cffc41f3bKhal|r\nVersion: %s"] = "Muestra el ilvl y color de borde en los paneles de personaje e inspección.\nPermite elegir entre íconos originales o de transfiguración.\n\nAutor: |cffc41f3bKhal|r\nVersión: %s",
})