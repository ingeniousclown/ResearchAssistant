
ResearchAssistantSettings = ZO_Object:Subclass()

local LAM = LibStub("LibAddonMenu-1.0")
local settings = nil

local CAN_RESEARCH_TEXTURES = {
	["Classic"] = {
		texturePath = [[/esoui/art/buttons/edit_disabled.dds]],
		textureSize = 30
	},
	["Modern"] =  {
		texturePath = [[/esoui/art/buttons/checkbox_indeterminate.dds]],
		textureSize = 16
	}
}

local TEXTURE_OPTIONS = { "Classic", "Modern" }

-----------------------------
--UTIL FUNCTIONS
-----------------------------

local function RGBAToHex( r, g, b, a )
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x%02x", r * 255, g * 255, b * 255, a * 255)
end

local function HexToRGBA( hex )
    local rhex, ghex, bhex, ahex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6), string.sub(hex, 7, 8)
    return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255
end

------------------------------
--OBJECT FUNCTIONS
------------------------------

function ResearchAssistantSettings:New()
	local obj = ZO_Object.New(self)
	obj:Initialize()
	return obj
end

function ResearchAssistantSettings:Initialize()
	local defaults = {
		raToggle = true,

		canResearchColor = RGBAToHex(1, .25, 0, 1),
		duplicateUnresearchedColor = RGBAToHex(1, 1, 0, 1),
		alreadyResearchedColor = RGBAToHex(.5, .5, .5, 1),

		ornateColor = RGBAToHex(1, 1, 0, 1),
		intricateColor = RGBAToHex(0, 1, 1, 1),

		isBlacksmith = true,
		isWoodworking = true,
		isClothier = true,

		showResearched = true,
		showUntrackedOrnate = true,
		showUntrackedIntricate = true,

		showTooltips = false,

		textureName = "Modern"
	}

	settings = ZO_SavedVars:NewAccountWide("ResearchAssistant_Settings", 2, nil, defaults)

    self:CreateOptionsMenu()
end

function ResearchAssistantSettings:IsActivated()
	return settings.raToggle
end

function ResearchAssistantSettings:GetCanResearchColor()
	local r, g, b, a = HexToRGBA(settings.canResearchColor)
	return {r, g, b, a}
end

function ResearchAssistantSettings:GetDuplicateUnresearchedColor()
	local r, g, b, a = HexToRGBA(settings.duplicateUnresearchedColor)
	return {r, g, b, a}
end

function ResearchAssistantSettings:GetAlreadyResearchedColor()
	local r, g, b, a = HexToRGBA(settings.alreadyResearchedColor)
	return {r, g, b, a}
end

function ResearchAssistantSettings:GetOrnateColor()
	local r, g, b, a = HexToRGBA(settings.ornateColor)
	return {r, g, b, a}
end

function ResearchAssistantSettings:GetIntricateColor()
	local r, g, b, a = HexToRGBA(settings.intricateColor)
	return {r, g, b, a}
end

function ResearchAssistantSettings:IsBlacksmith()
	return settings.isBlacksmith
end

function ResearchAssistantSettings:IsWoodworking()
	return settings.isWoodworking
end

function ResearchAssistantSettings:IsClothier()
	return settings.isClothier
end

function ResearchAssistantSettings:ShowResearched()
	return settings.showResearched
end

function ResearchAssistantSettings:ShowUntrackedOrnate()
	return settings.showUntrackedOrnate
end

function ResearchAssistantSettings:ShowUntrackedIntricate()
	return settings.showUntrackedIntricate
end

function ResearchAssistantSettings:ShowTooltips()
	return settings.showTooltips
end

function ResearchAssistantSettings:IsCraftingSkillEnabled( craftingSkillType )
	if( craftingSkillType == CRAFTING_TYPE_BLACKSMITHING ) then
		return self:IsBlacksmith()
	elseif( craftingSkillType == CRAFTING_TYPE_CLOTHIER ) then
		return self:IsClothier()
	elseif( craftingSkillType == CRAFTING_TYPE_WOODWORKING ) then
		return self:IsWoodworking()
	else
		return true
	end
end

function ResearchAssistantSettings:GetTexturePath()
	return CAN_RESEARCH_TEXTURES[settings.textureName].texturePath
end

function ResearchAssistantSettings:GetTextureSize()
	return CAN_RESEARCH_TEXTURES[settings.textureName].textureSize
end

function ResearchAssistantSettings:CreateOptionsMenu()
	local str = RA_Strings[self:GetLanguage()].SETTINGS

	local panel = LAM:CreateControlPanel("ResearchAssistantSettingsPanel", "Research Assistant Settings")
	LAM:AddHeader(panel, "RA_Settings_Header", "General Options")

	local icon = WINDOW_MANAGER:CreateControl("RA_Icon", ZO_OptionsWindowSettingsScrollChild, CT_TEXTURE)
	icon:SetColor(1, 1, 1, 1)
	icon:SetHandler("OnShow", function()
			self:SetTexture(CAN_RESEARCH_TEXTURES[settings.textureName].texturePath)
			icon:SetDimensions(CAN_RESEARCH_TEXTURES[settings.textureName].textureSize, CAN_RESEARCH_TEXTURES[settings.textureName].textureSize)
		end)
	local dropdown = LAM:AddDropdown(panel, "RA_Icon_Dropdown", str.ICON_LABEL, str.ICON_TOOLTIP, 
					TEXTURE_OPTIONS,
					function() return settings.textureName end,	--getFunc
					function(value)							--setFunc
						settings.textureName = value
						icon:SetTexture(CAN_RESEARCH_TEXTURES[value].texturePath)
						icon:SetDimensions(CAN_RESEARCH_TEXTURES[settings.textureName].textureSize, CAN_RESEARCH_TEXTURES[settings.textureName].textureSize)
					end)
	icon:SetParent(dropdown)
	icon:SetTexture(CAN_RESEARCH_TEXTURES[settings.textureName].texturePath)
	icon:SetDimensions(CAN_RESEARCH_TEXTURES[settings.textureName].textureSize, CAN_RESEARCH_TEXTURES[settings.textureName].textureSize)
	icon:SetAnchor(RIGHT, dropdown:GetNamedChild("Dropdown"), LEFT, -12, 0)

	LAM:AddCheckbox(panel, "RA_Show_Tooltips", str.SHOW_TOOLTIPS_LABEL, str.SHOW_TOOLTIPS_TOOLTIP,
					function() return settings.showTooltips end,	--getFunc
					function(value)							--setFunc
						settings.showTooltips = value
					end)

	LAM:AddHeader(panel, "RA_Colors_Header", "Color options")
	LAM:AddColorPicker(panel, "RA_Can_Research_Color_Picker", str.RESEARCHABLE_LABEL, str.RESEARCHABLE_TOOLTIP,
					function()
						local r, g, b, a = HexToRGBA(settings.canResearchColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.canResearchColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddColorPicker(panel, "RA_Duplicate_Can_Research_Color_Picker", str.DUPLICATE_LABEL, str.DUPLICATE_TOOLTIP,
					function()
						local r, g, b, a = HexToRGBA(settings.duplicateUnresearchedColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.duplicateUnresearchedColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddColorPicker(panel, "RA_Already_Researched_Color_Picker", str.RESEARCHED_LABEL, str.RESEARCHED_TOOLTIP,
					function()
						local r, g, b, a = HexToRGBA(settings.alreadyResearchedColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.alreadyResearchedColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddColorPicker(panel, "RA_Ornate_Color_Picker", str.ORNATE_LABEL, str.ORNATE_TOOLTIP,
					function()
						local r, g, b, a = HexToRGBA(settings.ornateColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.ornateColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddColorPicker(panel, "RA_Intricate_Color_Picker", str.INTRICATE_LABEL, str.INTRICATE_TOOLTIP,
					function()
						local r, g, b, a = HexToRGBA(settings.intricateColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.intricateColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddHeader(panel, "RA_Tracking_Header", "Tracking Options")
	LAM:AddCheckbox(panel, "RA_Is_Blacksmith", str.BLACKSMITH_LABEL, str.BLACKSMITH_TOOLTIP,
					function() return settings.isBlacksmith end,	--getFunc
					function(value)							--setFunc
						settings.isBlacksmith = value
					end)

	LAM:AddCheckbox(panel, "RA_Is_Clothier", str.CLOTHIER_LABEL, str.CLOTHIER_TOOLTIP,
					function() return settings.isClothier end,	--getFunc
					function(value)							--setFunc
						settings.isClothier = value
					end)

	LAM:AddCheckbox(panel, "RA_Is_Woodworking", str.WOODWORKING_LABEL, str.WOODWORKING_TOOLTIP,
					function() return settings.isWoodworking end,	--getFunc
					function(value)							--setFunc
						settings.isWoodworking = value
					end)

	LAM:AddCheckbox(panel, "RA_Show_Researched", str.SHOW_RESEARCHED_LABEL, str.SHOW_RESEARCHED_TOOLTIP,
					function() return settings.showResearched end,	--getFunc
					function(value)							--setFunc
						settings.showResearched = value
					end)

	LAM:AddCheckbox(panel, "RA_Show_Untracked_Ornate", str.SHOW_ORNATE_LABEL, str.SHOW_ORNATE_TOOLTIP,
					function() return settings.showUntrackedOrnate end,	--getFunc
					function(value)							--setFunc
						settings.showUntrackedOrnate = value
					end)

	LAM:AddCheckbox(panel, "RA_Show_Untracked_Intricate", str.SHOW_INTRICATE_LABEL, str.SHOW_INTRICATE_TOOLTIP,
					function() return settings.showUntrackedIntricate end,	--getFunc
					function(value)							--setFunc
						settings.showUntrackedIntricate = value
					end)
end

function ResearchAssistantSettings:GetLanguage()
	local lang = GetCVar("language.2")

	--check for supported languages
	if(lang == "de" or lang == "en") then return lang end

	--return english if not supported
	return "en"
end