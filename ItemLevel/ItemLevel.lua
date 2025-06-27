local addonName = 'ItemLevel';
local version = GetAddOnMetadata(addonName, "Version")
local addon = CreateFrame('Button', addonName);
local defaultSlotWidth, defaultSlotHeight = 68, 68;
local L = ItemLevel_Localization;

-- Default Values
local ilvlDefaultConfig = {
    ['size'] = 11,
    ['anchor'] = 'top',
    ['rgb'] = 0,
    ['border'] = 0.6,
    ['icon'] = 0,
    ['avg'] = 1,
    ['font'] = "Friz Quadrata",
}

local FontMapping = {
    ["Friz Quadrata"] = "Fonts\\FRIZQT__.TTF",
    ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
    ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
    ["Skurri"] = "Fonts\\SKURRI.TTF",
}

local CustomFontFiles = {
    "Accidental Presidency",
    "Adventure",
    "AvQest",
    "Bazooka",
    "Big Noodle Titling",
    "Black Chancery",
    "Emblem",
    "Enigmatic",
    "Myriad Condensed Web",
    "Porky's",
    "Prototype",
    "RM Midserif",
    "Tw Cen MT",
    "Ultima Campagnoli",
    "Yellow Jacket",
}

for _, fontName in ipairs(CustomFontFiles) do
    local fontPath = "Interface\\AddOns\\ItemLevel\\Fonts\\" .. fontName .. ".TTF"
    FontMapping[fontName] = fontPath
end

local HelpTextList = {
    '  |cff8788ee================ ItemLevel Slash Commands ================|r',
    '  |cff00FF98/ilvl size #|r : Define text font size (from 8 to 18).',
    '  |cff00FF98/ilvl anchor X|r : Define text anchor point (X : top, center, bottom).',
    '  |cff00FF98/ilvl rgb|r : Toggle ilvl text color between White or Quality RGB.',
    '  |cff00FF98/ilvl border #|r : Define border alpha (from 0 to 1).',
    '  |cff00FF98/ilvl avg|r : Toggle average ilvl text display on character panel.',
    '  |cff00FF98/ilvl icon|r : Toggle item icon between Transmog or Original.',
    '  |cff00FF98/ilvl reset|r : Reset parameters to default values.',
    '  |cff8788ee========================================================|r'
}

-- Slots considered in the Character Panel
local CharacterFrameSlotTypes = {
    'Head',
    'Neck',
    'Shoulder',
    'Back',
    'Chest',
    'Shirt',
    'Tabard',
    'Wrist',
    'Hands',
    'Waist',
    'Legs',
    'Feet',
    'Finger0',
    'Finger1',
    'Trinket0',
    'Trinket1',
    'MainHand',
    'SecondaryHand',
    'Ranged',
    'Ammo',
};

-- Slots considered in the Inspect Panel
local InspectFrameSlotTypes = {
    'Head',
    'Neck',
    'Shoulder',
    'Back',
    'Chest',
    'Shirt',
    'Tabard',
    'Wrist',
    'Hands',
    'Waist',
    'Legs',
    'Feet',
    'Finger0',
    'Finger1',
    'Trinket0',
    'Trinket1',
    'MainHand',
    'SecondaryHand',
    'Ranged',
    'Ammo',
};

addon:RegisterEvent('VARIABLES_LOADED');
addon:RegisterEvent('ADDON_LOADED');
addon:RegisterEvent('PLAYER_ENTERING_WORLD');
addon:RegisterEvent('UNIT_INVENTORY_CHANGED');
addon:RegisterEvent('INSPECT_READY');
addon:RegisterEvent('PLAYER_TARGET_CHANGED');
addon:RegisterEvent('BAG_UPDATE_COOLDOWN')

addon:SetScript('OnEvent', function(self, event, arg1, arg2)
    if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        addon:UpdateSlots('player', 'Character');
        self:SetScript("OnUpdate", function(self, elapsed)
            addon:UpdateSlots('player', 'Character');
            self:SetScript("OnUpdate", nil);
        end);
    elseif event == "BAG_UPDATE_COOLDOWN" then
        self:SetScript("OnUpdate", function(self, elapsed)
            addon:UpdateSlots("player", "Character");
            self:SetScript("OnUpdate", nil);
        end);
    elseif event == "INSPECT_READY" then
        addon:UpdateSlots('target', 'Inspect');
    elseif event == "PLAYER_TARGET_CHANGED" then
        if InspectFrame and InspectFrame:IsShown() then
            addon:UpdateSlots('target', 'Inspect');
        end
    elseif self[event] then
        self[event](self, arg1);
    end
end);

-- Initialize Settings
function addon:VARIABLES_LOADED()
    if (not ilvlConfig) then
        ilvlConfig = {}
    end
    for k, v in pairs(ilvlDefaultConfig) do
        if (not ilvlConfig[k]) then
            ilvlConfig[k] = ilvlDefaultConfig[k]; -- Default if no settings
        end
    end
    for k, v in pairs(ilvlConfig) do
        if (not ilvlDefaultConfig[k]) then
            ilvlConfig[k] = nil; -- Clear nil values
        end
    end
end

function addon:ADDON_LOADED(arg1)
    if (arg1 == addonName) then
        hooksecurefunc('ToggleCharacter', function() addon:characterFrame_OnToggle() end);
        hooksecurefunc("InspectUnit", function(unit)
            if unit == "target" then
                addon:UpdateSlots('target', 'Inspect');
            end
        end);
   	    -- Adds ItemLevel to the Addons List Interface
        local panel = CreateFrame("Frame")
        panel.name = "ItemLevel"
        panel:SetScript("OnShow", function(this)
            -- Title
            local t1 = this:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            t1:SetFont(GameFontNormalLarge:GetFont(), 18)
            t1:SetPoint("TOPLEFT", 16, -16)
            t1:SetJustifyH("LEFT")
            t1:SetJustifyV("TOP")
            t1:SetShadowColor(0, 0, 0)
            t1:SetShadowOffset(1, -1)
            t1:SetText(this.name)
            -- Description                  
            local t2 = this:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            t2:SetFont(GameFontHighlightSmall:GetFont(), 12)
            t2:SetPoint("TOPLEFT", t1, "BOTTOMLEFT", 0, -18)
            t2:SetPoint("RIGHT", this, "RIGHT", -32, 0)
            t2:SetJustifyH("LEFT")
            t2:SetJustifyV("TOP")
            t2:SetShadowColor(0, 0, 0)
            t2:SetShadowOffset(1, -1)
            t2:SetFormattedText(L["Displays ilvl and border color on the character and inspect panels.\nAllows you to choose between original and transmog icons.\n\nAuthor: |cffc41f3bKhal|r\nVersion: %s"], version)
            t2:SetNonSpaceWrap(true)
            -- Settings Button
            local b = CreateFrame("Button", nil, this, "UIPanelButtonTemplate")
            b:SetSize(100, 30)
            b:SetText("/ilvl")
            b:SetScript("OnClick", function() addon:BlizzUIButton() end)
            b:SetPoint("TOPLEFT", t2, "BOTTOMLEFT", 120, -18)
            b:GetFontString():SetPoint("CENTER", b, "CENTER", 0, 1)
            b:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 14)
            this:SetScript("OnShow", nil)
        end)
        InterfaceOptions_AddCategory(panel)
    end
end

function addon:BlizzUIButton()
    InterfaceOptionsFrameCancel_OnClick()
    HideUIPanel(GameMenuFrame)
    addon:ConfigUI()
end

function addon:ConfigUI()
    if not ILVLConfigUIglobalFrame then
        local f = CreateFrame("Frame", "ILVLConfigUIglobalFrame", UIParent, "UIPanelDialogTemplate")
        f:SetScale(0.65/UIParent:GetScale())
        f:SetSize(300, 520)
        f:SetPoint("CENTER")
        local localScale = 1.5  
        -- Function to crop and scale border textures
        local texHstretch = 0.00
        local topTexCrop = 0.57
        local topBordergrowth = topTexCrop * _G[f:GetName() .. "Top"]:GetHeight() * (localScale-1)
        local function CropAndResizeTexture(suffix,HCrop,VCrop)
            local texture = _G[f:GetName() .. suffix]
            if not texture then return end
            local left, bottom, right, top = select(3, texture:GetTexCoord())
            local Hoffset = ((suffix:match("Left$") and 1) or (suffix:match("Right$") and -1) or 0) * texHstretch
            texture:SetTexCoord(left + (right-left) * math.max(0, -HCrop) + Hoffset,
                                right + (left-right) * math.max(0, HCrop) + Hoffset,
                                top + (bottom-top) * math.max(0, VCrop),
                                bottom + (top-bottom) * math.max(0, -VCrop))
            if suffix == "BottomLeft" or suffix == "BottomRight" then
                texture:SetPoint(texture:GetPoint(1), 0, select(5, texture:GetPoint(1)) - topBordergrowth)
            end
            texture:SetWidth(texture:GetWidth() * localScale * (1-math.abs(HCrop)))
            texture:SetHeight(texture:GetHeight() * localScale * (1-math.abs(VCrop)))
        end
        CropAndResizeTexture("Top",0,0)
        CropAndResizeTexture("Bottom",0,0)
        CropAndResizeTexture("Left",0,0)
        CropAndResizeTexture("Right",0,0)
        CropAndResizeTexture("TopRight",-0.47,-topTexCrop) --Crops 47% from the left and 'topTexCrop' from the bottom
        CropAndResizeTexture("TopLeft",0.7,-topTexCrop) --Crops 70% from the right and 'topTexCrop' from the bottom
        CropAndResizeTexture("BottomLeft",0.7,0.7) --Crops 70% from the right and 70% from the top
        CropAndResizeTexture("BottomRight",-0.7,0.7) --Crops 70% from the left and 70% from the top
        -- Adjust Close button
        local closeButton = _G[f:GetName() .. "Close"]
        if closeButton then
            local point, relativeTo, relativePoint, x, y = closeButton:GetPoint(1)  -- TOPLEFT
            closeButton:SetPoint(point, relativeTo, relativePoint, (x + 500*texHstretch)*localScale, y*localScale)
            closeButton:SetHeight(closeButton:GetHeight() * localScale)
            closeButton:SetWidth(closeButton:GetWidth() * localScale)
        end  
        closeButton:SetScript("OnClick", function()
            f:Hide() -- Hide frame
            f:ClearAllPoints() -- Reset frame to center
            f:SetScale(0.65/UIParent:GetScale()) -- Reset frame scale
        end)
        -- Adjust Title Background
        local titleBG = _G[f:GetName() .. "TitleBG"]
        if titleBG then
            local point1, relativeTo1, relativePoint1, x1, y1 = titleBG:GetPoint(1)  -- TOPLEFT
            local point2, relativeTo2, relativePoint2, x2, y2 = titleBG:GetPoint(2)  -- BOTTOMRIGHT
            titleBG:SetPoint(point1, relativeTo1, relativePoint1, (x1-500*texHstretch)*localScale, y1*localScale)
            titleBG:SetPoint(point2, relativeTo2, relativePoint2, (x2+500*texHstretch)*localScale, y2*localScale)   
        end
        -- Adjust Dialog Background
        local dialogBG = _G[f:GetName() .. "DialogBG"]
        if dialogBG then
            local point1, relativeTo1, relativePoint1, x1, y1 = dialogBG:GetPoint(1) -- TOPLEFT
            local point2, relativeTo2, relativePoint2, x2, y2 = dialogBG:GetPoint(2) -- BOTTOMRIGHT
            dialogBG:SetPoint(point1, relativeTo1, relativePoint1, (x1-500*texHstretch)*localScale, y1*localScale)
            dialogBG:SetPoint(point2, relativeTo2, relativePoint2, (x2+500*texHstretch)*localScale, y2*localScale-topBordergrowth)
            dialogBG:SetAlpha(0.75)
        end  
        -- Define Title
        f.title:SetFont("Fonts\\FRIZQT__.TTF", 18)  
        f.title:SetTextColor(1, 0.82, 0)  
        f.title:ClearAllPoints()
        f.title:SetPoint("TOPLEFT", titleBG, "TOPLEFT", 0, 0)
        f.title:SetPoint("BOTTOMRIGHT", titleBG, "BOTTOMRIGHT", -12*localScale, 1.5*localScale)
        f.title:SetText("ItemLevel")  
        -- Dropdown to change the ilvl text font type
        local FontDropdown = CreateFrame("Frame", "ILVLConfigUIFontDropdown", f, "UIDropDownMenuTemplate")
        local FontLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        FontLabel:SetPoint("RIGHT", FontDropdown, "LEFT", 15, 4)
        FontLabel:SetText(L["Font:"])
        FontLabel:SetFont(GameFontNormal:GetFont(), 13)
        FontDropdown:SetPoint("TOPRIGHT", dialogBG, "TOPRIGHT", -15, -30)
        UIDropDownMenu_SetWidth(FontDropdown, 125)
        UIDropDownMenu_SetText(FontDropdown, ilvlConfig.font or ilvlDefaultConfig.font)
        FontDropdown:SetScale(1.15)
        local dropdownText = _G[FontDropdown:GetName().."Text"]
        dropdownText:SetFont(dropdownText:GetFont(), 12)
        dropdownText:ClearAllPoints()
        dropdownText:SetPoint("CENTER", FontDropdown, "CENTER", -4, 4)
        dropdownText:SetJustifyH("CENTER")
        UIDropDownMenu_Initialize(FontDropdown, function(self, level)
            for fontName in pairs(FontMapping) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = fontName
                info.checked = (ilvlConfig.font == fontName)  -- Compare with the font path
                info.func = function()
                    ilvlConfig.font = fontName -- Saves the mapped font name, not the path
                    UIDropDownMenu_SetText(FontDropdown, fontName)  -- DropDown selected font
                    _G[FontDropdown:GetName() .. "Text"]:SetFont(FontMapping[fontName] or FontMapping[ilvlDefaultConfig.font], 12, "OUTLINE")
                    addon:UpdateSlots("player", "Character")
                    addon:UpdateSlots("target", "Inspect")
                end
                info.fontObject = CreateFont("Ilvl_DropdownFont_" .. fontName)
                info.fontObject:SetFont(FontMapping[fontName], 13, "OUTLINE")
                info.fontObject:SetTextColor(1, 1, 1, 1)
                UIDropDownMenu_AddButton(info, level) -- DropDown font list
            end
        end)
        -- Slider for text size
        local sizeSlider = CreateFrame("Slider", "ILVLConfigUISizeSlider", f, "OptionsSliderTemplate")
        local sizeThumb = sizeSlider:GetThumbTexture()
        sizeSlider:SetSize(200, 20)
        sizeSlider:SetPoint("TOP", dialogBG, "TOP", 0, -100)
        sizeSlider:SetMinMaxValues(8, 18)
        sizeSlider:SetValueStep(1)
        sizeSlider:SetValue(ilvlConfig.size)
        local sizeLabel = sizeSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        sizeLabel:SetPoint("TOP", sizeSlider, "BOTTOM", 0, 2)
        sizeLabel:SetText(L["Text Size"])
        sizeLabel:SetFont(GameFontNormal:GetFont(), 13)
        local sizeValueText = sizeSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        sizeValueText:SetPoint("BOTTOM", sizeThumb, "TOP", 0, 0) -- Anchor current value text to slider thumb
        sizeValueText:SetText(ilvlConfig.size)
        sizeValueText:SetFont(GameFontHighlight:GetFont(), 13)
        _G[sizeSlider:GetName() .. "Low"]:SetFont(_G[sizeSlider:GetName() .. "Low"]:GetFont(), 12)  
        _G[sizeSlider:GetName() .. "High"]:SetFont(_G[sizeSlider:GetName() .. "High"]:GetFont(), 12)
        _G[sizeSlider:GetName() .. "Low"]:SetText("8")
        _G[sizeSlider:GetName() .. "High"]:SetText("18") -- Slider range labels
        sizeSlider:SetScript("OnValueChanged", function(self, value)
            local roundedValue = math.floor(value + 0.5)
            ilvlConfig.size = roundedValue
            sizeValueText:SetText(roundedValue)
            addon:UpdateSlots("player", "Character")
            addon:UpdateSlots("target", "Inspect")
        end)
        -- DropDown to change the text anchor
        local AnchorDropdown = CreateFrame("Frame", "ILVLConfigUIAnchorDropdown", f, "UIDropDownMenuTemplate")
        local AnchorLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        AnchorLabel:SetPoint("RIGHT", AnchorDropdown, "LEFT", 15, 4)
        AnchorLabel:SetText(L["Anchor:"])
        AnchorLabel:SetFont(GameFontNormal:GetFont(), 13)
        AnchorDropdown:SetPoint("TOPRIGHT", dialogBG, "TOPRIGHT", -15, -130)
        UIDropDownMenu_SetWidth(AnchorDropdown, 70)
        UIDropDownMenu_SetText(AnchorDropdown, ilvlConfig.anchor)
        AnchorDropdown:SetScale(1.15)
        local dropdownText = _G[AnchorDropdown:GetName().."Text"]
        dropdownText:SetFont(dropdownText:GetFont(), 12)
        dropdownText:ClearAllPoints()
        dropdownText:SetPoint("CENTER", AnchorDropdown, "CENTER", -5, 4)
        dropdownText:SetJustifyH("CENTER")
        UIDropDownMenu_Initialize(AnchorDropdown, function(self, level)
            local anchors = {"top", "center", "bottom"}
            for _, anchor in ipairs(anchors) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = anchor
                info.checked = (ilvlConfig.anchor == anchor)
                info.func = function()
                    ilvlConfig.anchor = anchor
                    UIDropDownMenu_SetText(AnchorDropdown, anchor)
                    addon:UpdateSlots("player", "Character")
                    addon:UpdateSlots("target", "Inspect")
                end
                local AnchorDropFont = CreateFont("ILvl_AnchorFont")
                AnchorDropFont:SetFont(GameFontNormal:GetFont(), 13)
                AnchorDropFont:SetTextColor(1, 1, 1, 1)
                info.fontObject = AnchorDropFont
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        -- Checkbox to color text based on item quality
        local rgbCheckbox = CreateFrame("CheckButton", "ILVLConfigUIRGBCheckbox", f, "UICheckButtonTemplate")
        rgbCheckbox:SetPoint("TOPLEFT", dialogBG, "TOPLEFT", 34, -200)
        rgbCheckbox:SetSize(24, 24)
        rgbCheckbox.text = _G[rgbCheckbox:GetName().."Text"]
        rgbCheckbox.text:SetText(L["Use Quality Color Text"])
        rgbCheckbox.text:ClearAllPoints()
        rgbCheckbox.text:SetPoint("LEFT", rgbCheckbox, "RIGHT", 1, 1)
        rgbCheckbox.text:SetFont(GameFontNormal:GetFont(), 13)
        rgbCheckbox.text:SetTextColor(1, 1, 1, 1)
        rgbCheckbox:SetChecked(ilvlConfig.rgb == 1)
        rgbCheckbox:SetScript("OnClick", function(self)
            ilvlConfig.rgb = self:GetChecked() and 1 or 0
            addon:UpdateSlots('player', 'Character')
            addon:UpdateSlots('target', 'Inspect')
        end)   
        -- Slider for border alpha
        local borderSlider = CreateFrame("Slider", "ILVLConfigUIBorderSlider", f, "OptionsSliderTemplate")
        local borderThumb = borderSlider:GetThumbTexture()
        borderSlider:SetPoint("TOP", dialogBG, "TOP", 0, -270)
        borderSlider:SetMinMaxValues(0, 10)
        borderSlider:SetValueStep(1)
        borderSlider:SetSize(200, 20)
        borderSlider:SetValue(ilvlConfig.border * 10) -- Use scaled integers to avoid rounding issues
        local borderLabel = borderSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        borderLabel:SetPoint("TOP", borderSlider, "BOTTOM", 0, 2)
        borderLabel:SetText(L["Border Alpha"])
        borderLabel:SetFont(GameFontNormal:GetFont(), 13)
        local borderValueText = borderSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        borderValueText:SetPoint("BOTTOM", borderThumb, "TOP", 0, 0)
        borderValueText:SetText(string.format("%.1f", ilvlConfig.border))
        borderValueText:SetFont(GameFontHighlight:GetFont(), 13)
        _G[borderSlider:GetName() .. "Low"]:SetFont(_G[borderSlider:GetName() .. "Low"]:GetFont(), 12)  
        _G[borderSlider:GetName() .. "High"]:SetFont(_G[borderSlider:GetName() .. "High"]:GetFont(), 12)
        _G[borderSlider:GetName() .. "Low"]:SetText("0") 
        _G[borderSlider:GetName() .. "High"]:SetText("1")  -- Slider range labels      
        borderSlider:SetScript("OnValueChanged", function(self, value)
            local correctedValue = value / 10 -- Convert back to original scale (0-10 -> 0-1)
            ilvlConfig.border = correctedValue
            borderValueText:SetText(string.format("%.1f", correctedValue))
            if CharacterFrame and CharacterFrame:IsShown() then
                addon:UpdateSlots("player", "Character")
            end
            if InspectFrame and InspectFrame:IsShown() then
                addon:UpdateSlots("target", "Inspect")
            end
        end)
        -- Checkbox to show Average ILvl
        local avgCheckbox = CreateFrame("CheckButton", "ILVLConfigUIAVGCheckbox", f, "UICheckButtonTemplate")
        avgCheckbox:SetPoint("TOPLEFT", dialogBG, "TOPLEFT", 34, -335)
        avgCheckbox:SetSize(24, 24)
        avgCheckbox.text = _G[avgCheckbox:GetName().."Text"]
        avgCheckbox.text:SetText(L["Show Average ItemLevel"])
        avgCheckbox.text:SetPoint("LEFT", avgCheckbox, "RIGHT", 1, 1)
        avgCheckbox.text:SetFont(GameFontNormal:GetFont(), 13)
        avgCheckbox.text:SetTextColor(1, 1, 1, 1)
        avgCheckbox:SetChecked(ilvlConfig.avg == 1)
        avgCheckbox:SetScript("OnClick", function(self)
            ilvlConfig.avg = self:GetChecked() and 1 or 0 
            if _G["Ileveltxt"] and _G["Ilevelnr"] then
                if ilvlConfig.avg == 1 then
                    _G["Ileveltxt"]:Show()
                    _G["Ilevelnr"]:Show()
                else
                    _G["Ileveltxt"]:Hide()
                    _G["Ilevelnr"]:Hide()
                end
            end
        end)
        -- Checkbox to toogle Transmog/Original icons
        local iconCheckbox = CreateFrame("CheckButton", "ILVLConfigUIIconCheckbox", f, "UICheckButtonTemplate")
        iconCheckbox:SetPoint("TOPLEFT", dialogBG, "TOPLEFT", 34, -380)
        iconCheckbox:SetSize(24, 24)
        iconCheckbox.text = _G[iconCheckbox:GetName().."Text"]
        iconCheckbox.text:SetText(L["Show Transmog Icons"])
        iconCheckbox.text:SetPoint("LEFT", iconCheckbox, "RIGHT", 1, 1)
        iconCheckbox.text:SetFont(GameFontNormal:GetFont(), 13)
        iconCheckbox.text:SetTextColor(1, 1, 1, 1)
        iconCheckbox:SetChecked(ilvlConfig.icon == 1)
        iconCheckbox:SetScript("OnClick", function(self)
            ilvlConfig.icon = self:GetChecked() and 1 or 0
            addon:UpdateSlots("player", "Character")
            addon:UpdateSlots("target", "Inspect")
        end)
        -- Reset Button
        local resetButton = CreateFrame("Button", "ILVLConfigUIresetButton", f, "UIPanelButtonTemplate")
        resetButton:SetSize(110, 30)
        resetButton:GetFontString():SetPoint("CENTER", resetButton, "CENTER", 0, 1) 
        resetButton:GetFontString():SetFont(resetButton:GetFontString():GetFont(), 14.5)
        resetButton:SetPoint("BOTTOM", ILVLConfigUIglobalFrame, "BOTTOM", 0, 15)
        resetButton:SetText(L["Reset"])
        resetButton:SetScript("OnClick", function()
            StaticPopupDialogs["CONFIRM_RESET_ILVL_CONFIG"] = {
                text = L["Are you sure you want to reset all settings to default?"],
                button1 = L["Yes"],
                button2 = L["No"],
                OnAccept = function()
                    for k, v in pairs(ilvlDefaultConfig) do
                        ilvlConfig[k] = v
                    end
                    addon:UpdateSlots("player", "Character")
                    addon:UpdateSlots("target", "Inspect")
                    addon:UpdateConfigUI()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("CONFIRM_RESET_ILVL_CONFIG")
        end)
        -- Script to move and scale frame
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:EnableMouseWheel(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not self.isMoving then
                self:StartMoving();
                self.isMoving = true;
            end
        end)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self.isMoving then
                self:StopMovingOrSizing();
                self.isMoving = false;
            end
        end)
        f:SetScript("OnHide", function(self)
            if (self.isMoving) then
                self:StopMovingOrSizing();
                self.isMoving = false;
            end
        end)
        f:SetScript("OnMouseWheel", function(self, delta)
            local scale = self:GetScale()
            if delta > 0 then
                self:SetScale(math.min(scale + 0.1, 1/UIParent:GetScale()))
            else
                self:SetScale(math.max(scale - 0.1, 0.5/UIParent:GetScale()))
            end
        end)
        f:Show()
    end
    -- Reset frame position to center when closed
    if not ILVLConfigUIglobalFrame:IsShown() then
        ILVLConfigUIglobalFrame:ClearAllPoints()
        ILVLConfigUIglobalFrame:SetPoint("CENTER")
        ILVLConfigUIglobalFrame:Show()
    end
end

function addon:UpdateConfigUI()
    if not ILVLConfigUIglobalFrame or not ILVLConfigUIglobalFrame:IsShown() then return end
    if _G["ILVLConfigUISizeSlider"] then _G["ILVLConfigUISizeSlider"]:SetValue(ilvlConfig.size) end
    if _G["ILVLConfigUIAnchorDropdown"] then UIDropDownMenu_SetText(_G["ILVLConfigUIAnchorDropdown"], ilvlConfig.anchor) end
    if _G["ILVLConfigUIFontDropdown"] then
        UIDropDownMenu_SetText(_G["ILVLConfigUIFontDropdown"], ilvlConfig.font)
        _G["ILVLConfigUIFontDropdownText"]:SetFont(FontMapping[ilvlConfig.font], 12, "OUTLINE")
    end
    if _G["ILVLConfigUIRGBCheckbox"] then _G["ILVLConfigUIRGBCheckbox"]:SetChecked(ilvlConfig.rgb == 1) end
    if _G["ILVLConfigUIBorderSlider"] then _G["ILVLConfigUIBorderSlider"]:SetValue(ilvlConfig.border * 10) end
    if _G["ILVLConfigUIAVGCheckbox"] then _G["ILVLConfigUIAVGCheckbox"]:SetChecked(ilvlConfig.avg == 1) end
    if _G["ILVLConfigUIIconCheckbox"] then _G["ILVLConfigUIIconCheckbox"]:SetChecked(ilvlConfig.icon == 1) end
end

function addon:characterFrame_OnToggle()
    if (CharacterFrame:IsShown()) then
        addon:UpdateSlots('player', 'Character');
    end
end

-- Function to update slots in the character or inspect panel
function addon:UpdateSlots(unit, frameType)
    local slotTypes = (frameType == 'Character') and CharacterFrameSlotTypes or InspectFrameSlotTypes;
    
    for _, charSlot in ipairs(slotTypes) do
        local id, _ = GetInventorySlotInfo(charSlot .. 'Slot');
        local itemLink = GetInventoryItemLink(unit, id);
        local itemID = GetInventoryItemID(unit, id);
        local slotName = frameType .. charSlot .. 'Slot';
        if (_G[slotName]) then
            local slot = _G[slotName];
            -- Create the border if it doesn't exist
            if (not slot.qborder) then
                local height = defaultSlotHeight;
                local width = defaultSlotWidth;
                if charSlot == 'Ammo' then
                    height = 58
                    width = 58
                end
                slot.qborder = addon:createBorder(slotName, _G[slotName], width, height);
            end
            -- Create the ilvl text if it doesn't exist
            if (not slot.itemlvlText) then
                slot.itemlvlText = slot:CreateFontString(nil, "OVERLAY");
                slot.itemlvlText:ClearAllPoints();
                if(ilvlConfig.anchor == 'top') then
                    slot.itemlvlText:SetPoint("TOP", slot, "TOP", 0, -1);
                elseif (ilvlConfig.anchor == 'center') then
                    slot.itemlvlText:SetPoint("CENTER", slot, "CENTER", 0, 0);
                elseif (ilvlConfig.anchor == 'bottom') then
                    slot.itemlvlText:SetPoint("BOTTOM", slot, "BOTTOM", 0, 2);
                end
                slot.itemlvlText:SetFont([[Fonts\FRIZQT__.TTF]], ilvlConfig.size, "OUTLINE")
                slot.itemlvlText:SetShadowColor(0, 0, 0, 1);
                slot.itemlvlText:SetShadowOffset(1, -1);
            end     
            if (itemLink) then
                local _, _, itemQuality, itemLevel, _, _, _, _, _, itemTexture = GetItemInfo(itemLink);
                -- Change Item Icon Texture
                slot.icon = _G[slotName .. "IconTexture"];
                if (itemTexture) then
                    if (ilvlConfig.icon == 1) then
                        slot.icon:SetTexture(GetInventoryItemTexture(unit, id)); -- Transmog icon
                    else
                        slot.icon:SetTexture(itemTexture); -- Original item icon
                    end
                else
                    slot.icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. charSlot); -- Empty Slot Texture
                end
                if (itemQuality) then
                    local r, g, b = GetItemQualityColor(itemQuality)
                    slot.qborder:SetVertexColor(r, g, b);
                    slot.qborder:SetAlpha(ilvlConfig.border);
                    slot.qborder:Show();  
                    if itemLevel then
                        slot.itemlvlText:SetText(itemLevel);
                        slot.itemlvlText:ClearAllPoints();
                        if(ilvlConfig.anchor == 'top') then
                            slot.itemlvlText:SetPoint("TOP", slot, "TOP", 0, -1);
                        elseif (ilvlConfig.anchor == 'center') then
                            slot.itemlvlText:SetPoint("CENTER", slot, "CENTER", 0, 0);
                        elseif (ilvlConfig.anchor == 'bottom') then
                            slot.itemlvlText:SetPoint("BOTTOM", slot, "BOTTOM", 0, 2);
                        end
                        local fontPath = FontMapping[ilvlConfig.font] or FontMapping[ilvlDefaultConfig.font] -- Convert font name to path 
                        slot.itemlvlText:SetFont(fontPath, ilvlConfig.size, "OUTLINE") -- Apply the path
                        slot.itemlvlText:SetShadowColor(0, 0, 0, 1);
                        slot.itemlvlText:SetShadowOffset(1, -1);
                        if ilvlConfig.rgb == 1 then
                            slot.itemlvlText:SetTextColor(r, g, b);
                        else
                            slot.itemlvlText:SetTextColor(1, 1, 1);
                        end
                        slot.itemlvlText:Show();
                        if charSlot == 'Shirt' or charSlot == 'Tabard' or charSlot == 'Ammo' then
                            slot.itemlvlText:Hide();
                        end
                    else
                        slot.itemlvlText:Hide();
                    end
                else
                    slot.qborder:Hide();
                    slot.itemlvlText:Hide();
                end
            else
                slot.qborder:Hide();
                slot.itemlvlText:Hide();
            end
        end
    end
    -- Average Ilvl
    if not _G["Ileveltxt"] then
        _G["Ileveltxt"] = PaperDollFrame:CreateFontString("Ileveltxt")
        _G["Ileveltxt"]:SetFont("Fonts\\FRIZQT__.TTF", 10)
        _G["Ileveltxt"]:SetText("ItemLevel")
        _G["Ileveltxt"]:SetPoint("BOTTOMRIGHT", PaperDollFrame, "TOPLEFT", 291, -265)
    end
    _G["Ileveltxt"]:Show()
    local ItemCount, TotalIlvl, AvgIlvl, ilvltemp = 0, 0, 0, 0
    local TotalR, TotalG, TotalB = 0, 0, 0
    local AvgR, AvgG, AvgB = 1, 1, 1
      for k = 1,18 do																	
        if not (k == 4) then														
            if (GetInventoryItemLink("player", k)) then                             
                _, _, iQualitytemp, ilvltemp  = GetItemInfo(GetInventoryItemLink("player", k))  
                if ilvltemp then
                    TotalIlvl = TotalIlvl + ilvltemp
                    ItemCount = ItemCount + 1
                    if iQualitytemp and ITEM_QUALITY_COLORS[iQualitytemp] then
                        TotalR = TotalR + ITEM_QUALITY_COLORS[iQualitytemp].r
                        TotalG = TotalG + ITEM_QUALITY_COLORS[iQualitytemp].g
                        TotalB = TotalB + ITEM_QUALITY_COLORS[iQualitytemp].b
                    end
                end                        
            end
        end
    end
    if (ItemCount > 0) then
        AvgIlvl = TotalIlvl / ItemCount
        AvgR = TotalR / ItemCount
        AvgG = TotalG / ItemCount
        AvgB = TotalB / ItemCount
    end
    if not _G["Ilevelnr"] then
        _G["Ilevelnr"] = PaperDollFrame:CreateFontString("Ilevelnr")
        _G["Ilevelnr"]:SetFont("Fonts\\FRIZQT__.TTF", 10)
        _G["Ilevelnr"]:SetPoint("BOTTOMRIGHT", PaperDollFrame, "TOPLEFT", 291, -253)
    end
    _G["Ilevelnr"]:SetFormattedText("%.1f", AvgIlvl)
    _G["Ilevelnr"]:SetTextColor(AvgR, AvgG, AvgB, 1)

    _G["Ilevelnr"]:Show()
    if (ilvlConfig.avg == 0) then
        _G["Ileveltxt"]:Hide()
        _G["Ilevelnr"]:Hide()
    end
end

function addon:createBorder(name, parent, width, height, x, y)
    local x = x or 0;
    local y = y or 1;
    local border = parent:CreateTexture(name .. 'Quality', 'OVERLAY');
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");
    border:SetBlendMode('ADD');
    border:SetAlpha(ilvlConfig.border);
    border:SetHeight(height);
    border:SetWidth(width);
    border:SetPoint('CENTER', parent, 'CENTER', x, y);
    border:Hide();
    return border;
end

-- Chat Slash Commands
SLASH_ILVL1 = "/ilvl"
SlashCmdList["ILVL"] = function(msg)
    msg = string.lower(msg);
    local _, _, cmd, args = string.find(msg, '%s?(%w+)%s?(.*)')
    if (not cmd or cmd == '') then
        addon:ConfigUI()
    elseif (cmd == 'help') then
        for _, line in ipairs(HelpTextList) do
            print(line)
        end
    elseif (cmd == 'size') then
        if (not args or args == '') then
            print(' |cff8788ee[ItemLevel]|r Current text size: ' .. ilvlConfig.size);
        else
            local value = tonumber(args);
            if (value ~= nil) then
                if (value > 18) then value = 18 end
                if (value < 8) then value = 8 end
                ilvlConfig.size = value;
                print(' |cff8788ee[ItemLevel]|r Text size set to: ' .. ilvlConfig.size);       
            else
                print(' |cff8788ee[ItemLevel]|r Value is not a number');
            end
        end
    elseif (cmd == 'anchor') then
        if (not args or args == '') then
            print(' |cff8788ee[ItemLevel]|r Current text anchor point: ' .. ilvlConfig.anchor);
        else
            if (args == 'top' or args == 'center' or args == 'bottom') then
                ilvlConfig.anchor = args;
                print(' |cff8788ee[ItemLevel]|r Text anchor point set to: ' .. ilvlConfig.anchor);
            else
                print(' |cff8788ee[ItemLevel]|r Argument is not valid');
            end
        end
    elseif (cmd == 'rgb') then
        if (ilvlConfig.rgb == 1) then 
            ilvlConfig.rgb = 0;
            print(' |cff8788ee[ItemLevel]|r Text color toggled to: White');
        else 
            ilvlConfig.rgb = 1;
            print(' |cff8788ee[ItemLevel]|r Text color toggled to: Quality RGB');
        end
    elseif (cmd == 'border') then
        if (not args or args == '') then
            print(' |cff8788ee[ItemLevel]|r Current border alpha: ' .. ilvlConfig.border);
        else
            local value = tonumber(args);
            if (value ~= nil) then
                if (value > 1) then value = 1 end
                if (value < 0) then value = 0 end
                ilvlConfig.border = value;
                print(' |cff8788ee[ItemLevel]|r Border alpha set to: ' .. ilvlConfig.border);
            else
                print(' |cff8788ee[ItemLevel]|r Value is not a number');
            end
        end
    elseif (cmd == 'icon') then
        if (ilvlConfig.icon == 1) then 
            ilvlConfig.icon = 0;
            print(' |cff8788ee[ItemLevel]|r Item icon set to: Original');
        else 
            ilvlConfig.icon = 1;
            print(' |cff8788ee[ItemLevel]|r Item icon set to: Transmog');
        end
    elseif (cmd == 'avg') then
        if (ilvlConfig.avg == 1) then 
            ilvlConfig.avg = 0;
            print(' |cff8788ee[ItemLevel]|r Average ilvl disabled');
        else 
            ilvlConfig.avg = 1;
            print(' |cff8788ee[ItemLevel]|r Average ilvl enabled');
        end
    elseif (cmd == 'reset') then
        for k, v in pairs(ilvlDefaultConfig) do
            ilvlConfig[k] = ilvlDefaultConfig[k];
        end
        print(' |cff8788ee[ItemLevel]|r Default config set');
    else
        print(' |cff8788ee[ItemLevel]|r Argument is not valid');
    end
    addon:UpdateSlots('player', 'Character')
    addon:UpdateSlots('target', 'Inspect')
    if InspectFrame and InspectFrame:IsShown() then InspectFrame_OnShow(InspectFrame) end
    addon:UpdateConfigUI()
end
