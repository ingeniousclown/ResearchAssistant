
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

		showUntrackedOrnate = true,
		showUntrackedIntricate = true,

		showTooltips = false,

		textureName = "Modern"
	}

	settings = ZO_SavedVars:New("ResearchAssistant_Settings", 2, nil, defaults)

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
	local panel = LAM:CreateControlPanel("ResearchAssistantSettingsPanel", "Research Assistant Settings")
	LAM:AddHeader(panel, "RA_Settings_Header", "Research Assistant")

	local icon = WINDOW_MANAGER:CreateControl("RA_Icon", ZO_OptionsWindowSettingsScrollChild, CT_TEXTURE)
	icon:SetColor(1, 1, 1, 1)
	icon:SetHandler("OnShow", function()
			self:SetTexture(CAN_RESEARCH_TEXTURES[settings.textureName].texturePath)
			icon:SetDimensions(CAN_RESEARCH_TEXTURES[settings.textureName].textureSize, CAN_RESEARCH_TEXTURES[settings.textureName].textureSize)
		end)
	local dropdown = LAM:AddDropdown(panel, "RA_Icon_Dropdown", "Research icon", "Choose which icon to display as your research assistant.", 
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

	LAM:AddColorPicker(panel, "RA_Can_Research_Color_Picker", "Researchable trait color", 
					"What color should the research assistant icon be if the trait is researchable?",
					function()
						local r, g, b, a = HexToRGBA(settings.canResearchColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.canResearchColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddColorPicker(panel, "RA_Duplicate_Can_Research_Color_Picker", "Duplicate researchable trait color", 
					"What color should the research assistant icon be if the item is researchable?",
					function()
						local r, g, b, a = HexToRGBA(settings.duplicateUnresearchedColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.duplicateUnresearchedColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddColorPicker(panel, "RA_Already_Researched_Color_Picker", "Already researched color", 
					"What color should the research assistant icon be if the item is already researched?",
					function()
						local r, g, b, a = HexToRGBA(settings.alreadyResearchedColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.alreadyResearchedColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddColorPicker(panel, "RA_Ornate_Color_Picker", "Ornate item color", 
					"What color should the icon be for an ornate item?",
					function()
						local r, g, b, a = HexToRGBA(settings.ornateColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.ornateColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddColorPicker(panel, "RA_Intricate_Color_Picker", "Intricate item color", 
					"What color should the icon be for an intricate item?",
					function()
						local r, g, b, a = HexToRGBA(settings.intricateColor)
						return r, g, b
					end,
					function(r, g, b)
						settings.intricateColor = RGBAToHex(r, g, b, 1)
					end)

	LAM:AddCheckbox(panel, "RA_Is_Blacksmith", "Track Blacksmithing?", "Toggle the Research Assistant for Blacksmithing.",
					function() return settings.isBlacksmith end,	--getFunc
					function(value)							--setFunc
						settings.isBlacksmith = value
					end)

	LAM:AddCheckbox(panel, "RA_Is_Clothier", "Track Clothier?", "Toggle the Research Assistant for Clothier.",
					function() return settings.isClothier end,	--getFunc
					function(value)							--setFunc
						settings.isClothier = value
					end)

	LAM:AddCheckbox(panel, "RA_Is_Woodworking", "Track Woodworking?", "Toggle the Research Assistant for Woodworking.",
					function() return settings.isWoodworking end,	--getFunc
					function(value)							--setFunc
						settings.isWoodworking = value
					end)

	LAM:AddCheckbox(panel, "RA_Show_Untracked_Ornate", "Always show Ornate?", "Should Ornate be shown for untracked skills?",
					function() return settings.showUntrackedOrnate end,	--getFunc
					function(value)							--setFunc
						settings.showUntrackedOrnate = value
					end)

	LAM:AddCheckbox(panel, "RA_Show_Untracked_Intricate", "Always show Intricate?", "Should Intricate be shown for untracked skills?",
					function() return settings.showUntrackedIntricate end,	--getFunc
					function(value)							--setFunc
						settings.showUntrackedIntricate = value
					end)

	LAM:AddCheckbox(panel, "RA_Show_Tooltips", "Show icon tooltips?", "Should tooltips tell you what are? (recommended OFF)",
					function() return settings.showTooltips end,	--getFunc
					function(value)							--setFunc
						settings.showTooltips = value
					end)
end

function ResearchAssistantSettings:GetLanguage()
	local lang = GetCVar("language.2")

	--check for supported languages
	if(lang == "de" or lang == "en") then return lang end

	--return english if not supported
	return "en"
end