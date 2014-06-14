
ResearchAssistantSettings = ZO_Object:Subclass()

local LAM = LibStub("LibAddonMenu-2.0")
local settings = nil
local _

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
		multiCharacter = false,

		textureName = "Modern",
		showTooltips = false,
		showInGrid = true,

		canResearchColor = RGBAToHex(1, .25, 0, 1),
		duplicateUnresearchedColor = RGBAToHex(1, 1, 0, 1),
		alreadyResearchedColor = RGBAToHex(.5, .5, .5, 1),
		ornateColor = RGBAToHex(1, 1, 0, 1),
		intricateColor = RGBAToHex(0, 1, 1, 1),

		isBlacksmith = {},
		isWoodworking = {},
		isClothier = {},

		showResearched = true,
		showTraitless = true,
		showUntrackedOrnate = true,
		showUntrackedIntricate = true,

		useCrossCharacter = {},
		blacksmithCharacter = {},
		woodworkingCharacter = {},
		clothierCharacter = {},

		--non settings variables
		acquiredTraits = {}
	}

	settings = ZO_SavedVars:NewAccountWide("ResearchAssistant_Settings", 2, nil, defaults)

	--initialize char-specific settings
	--first, set settings to empty table to support old version transition
	if(settings.isBlacksmith == true or settings.isBlacksmith == false) then
		settings.isBlacksmith = {}
	end
	if(settings.isWoodworking == true or settings.isWoodworking == false) then
		settings.isWoodworking = {}
	end
	if(settings.isClothier == true or settings.isClothier == false) then
		settings.isClothier = {}
	end

	--now actually initialize
	if(settings.isBlacksmith[GetUnitName("player")] == nil) then
		settings.isBlacksmith[GetUnitName("player")] = true
	end
	if(settings.isWoodworking[GetUnitName("player")] == nil) then
		settings.isWoodworking[GetUnitName("player")] = true
	end
	if(settings.isClothier[GetUnitName("player")] == nil) then
		settings.isClothier[GetUnitName("player")] = true
	end

	--initialize this character's x-char settings
	if(settings.useCrossCharacter[GetUnitName("player")] == nil)  then
		settings.useCrossCharacter[GetUnitName("player")] = false
	end

	--either all are nil or none are
	if(not settings.blacksmithCharacter[GetUnitName("player")]) then
		settings.blacksmithCharacter[GetUnitName("player")] = GetUnitName("player")
		settings.woodworkingCharacter[GetUnitName("player")] = GetUnitName("player")
		settings.clothierCharacter[GetUnitName("player")] = GetUnitName("player")
	end

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
	return settings.isBlacksmith[GetUnitName("player")]
end

function ResearchAssistantSettings:IsWoodworking()
	return settings.isWoodworking[GetUnitName("player")]
end

function ResearchAssistantSettings:IsClothier()
	return settings.isClothier[GetUnitName("player")]
end

function ResearchAssistantSettings:ShowResearched()
	return settings.showResearched
end

function ResearchAssistantSettings:ShowTraitless()
	return settings.showTraitless
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

function ResearchAssistantSettings:ShowInGrid()
	return settings.showInGrid
end

function ResearchAssistantSettings:SetKnownTraits( traitsTable )
	settings.acquiredTraits[GetUnitName("player")] = traitsTable
end

function ResearchAssistantSettings:IsUseCrossCharacter()
	return settings.useCrossCharacter[GetUnitName("player")]
end

function ResearchAssistantSettings:GetCraftingCharacterTraits( craftingSkillType )
	if( not settings.useCrossCharacter[GetUnitName("player")] ) then
		return self:GetPlayerTraits()
	end

	if( craftingSkillType == CRAFTING_TYPE_BLACKSMITHING ) then
		return settings.acquiredTraits[settings.blacksmithCharacter[GetUnitName("player")]]
	elseif( craftingSkillType == CRAFTING_TYPE_CLOTHIER ) then
		return settings.acquiredTraits[settings.clothierCharacter[GetUnitName("player")]]
	elseif( craftingSkillType == CRAFTING_TYPE_WOODWORKING ) then
		return settings.acquiredTraits[settings.woodworkingCharacter[GetUnitName("player")]]
	else
		return self:GetPlayerTraits()
	end
end

function ResearchAssistantSettings:GetPlayerTraits()
	return settings.acquiredTraits[GetUnitName("player")]
end

function ResearchAssistantSettings:GetTraits()
	return settings.acquiredTraits
end

function ResearchAssistantSettings:IsMultiCharSkillOff( craftingSkillType )
	if( craftingSkillType == CRAFTING_TYPE_BLACKSMITHING ) then
		return settings.blacksmithCharacter[GetUnitName("player")] == "off"
	elseif( craftingSkillType == CRAFTING_TYPE_CLOTHIER ) then
		return settings.clothierCharacter[GetUnitName("player")] == "off"
	elseif( craftingSkillType == CRAFTING_TYPE_WOODWORKING ) then
		return settings.woodworkingCharacter[GetUnitName("player")] == "off"
	else
		return assert(false, "Invalid crafting skill type: " .. (craftingSkillType or "nil"))
	end
end

function ResearchAssistantSettings:GetPreferenceValueForTrait( traitKey )
	if(not traitKey) then return nil end
	local traits = self:GetCraftingCharacterTraits(zo_floor(traitKey / 10000))
	return traits[traitKey]
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

	local panel = {
		type = "panel",
		name = "Research Assistant",
		author = "ingeniousclown",
		version = "0.7.2",
		slashCommand = "/researchassistant",
		registerForRefresh = true
	}

	local icon = WINDOW_MANAGER:CreateControl("RA_Icon", ZO_OptionsWindowSettingsScrollChild, CT_TEXTURE)
	icon:SetColor(1, 1, 1, 1)
	icon:SetHandler("OnShow", function()
			self:SetTexture(CAN_RESEARCH_TEXTURES[settings.textureName].texturePath)
			icon:SetDimensions(CAN_RESEARCH_TEXTURES[settings.textureName].textureSize, CAN_RESEARCH_TEXTURES[settings.textureName].textureSize)
		end)

	local knownCharacters = { "off" }
	for k,_ in pairs(settings.useCrossCharacter) do
		table.insert(knownCharacters, k)
	end

	local optionsData = {
		[1] = {
			type = "header",
			name = "General Options"
		},

		[2] = {
			type = "dropdown",
			name = str.ICON_LABEL,
			tooltip = str.ICON_TOOLTIP,
			choices = TEXTURE_OPTIONS,
			getFunc = function() return settings.textureName end,
			setFunc = function(value)
						settings.textureName = value
						icon:SetTexture(CAN_RESEARCH_TEXTURES[value].texturePath)
						icon:SetDimensions(CAN_RESEARCH_TEXTURES[settings.textureName].textureSize, CAN_RESEARCH_TEXTURES[settings.textureName].textureSize)
						ResearchAssistant_InvUpdate()
					end,
			reference = "RA_Icon_Dropdown"
		},

		[3] = {
			type = "checkbox",
			name = str.SHOW_TOOLTIPS_LABEL,
			tooltip = str.SHOW_TOOLTIPS_TOOLTIP,
			getFunc = function() return settings.showTooltips end,
			setFunc = function(value)
						settings.showTooltips = value
						ResearchAssistant_InvUpdate()
					end
		},

		[4] = {
			type = "checkbox",
			name = str.SHOW_IN_GRID_LABEL,
			tooltip = str.SHOW_IN_GRID_TOOLTIP,
			getFunc = function() return settings.showInGrid end,
			setFunc = function(value)
						settings.showInGrid = value
						ResearchAssistant_InvUpdate()
					end
		},

		[5] = {
			type = "header",
			name = "Color options"
		},

		[6] = {
			type = "colorpicker",
			name = str.RESEARCHABLE_LABEL,
			tooltip = str.RESEARCHABLE_TOOLTIP,
			getFunc = function()
						local r, g, b, a = HexToRGBA(settings.canResearchColor)
						return r, g, b
					end,
			setFunc = function(r, g, b)
						settings.canResearchColor = RGBAToHex(r, g, b, 1)
						ResearchAssistant_InvUpdate()
					end
		},

		[7] = {
			type = "colorpicker",
			name = str.DUPLICATE_LABEL,
			tooltip = str.DUPLICATE_TOOLTIP,
			getFunc = function()
						local r, g, b, a = HexToRGBA(settings.duplicateUnresearchedColor)
						return r, g, b
					end,
			setFunc = function(r, g, b)
						settings.duplicateUnresearchedColor = RGBAToHex(r, g, b, 1)
						ResearchAssistant_InvUpdate()
					end
		},

		[8] = {
			type = "colorpicker",
			name = str.RESEARCHED_LABEL,
			tooltip = str.RESEARCHED_TOOLTIP,
			getFunc = function()
						local r, g, b, a = HexToRGBA(settings.alreadyResearchedColor)
						return r, g, b
					end,
			setFunc = function(r, g, b)
						settings.alreadyResearchedColor = RGBAToHex(r, g, b, 1)
						ResearchAssistant_InvUpdate()
					end
		},

		[9] = {
			type = "colorpicker",
			name = str.ORNATE_LABEL,
			tooltip = str.ORNATE_TOOLTIP,
			getFunc = function()
						local r, g, b, a = HexToRGBA(settings.ornateColor)
						return r, g, b
					end,
			setFunc = function(r, g, b)
						settings.ornateColor = RGBAToHex(r, g, b, 1)
						ResearchAssistant_InvUpdate()
					end
		},

		[10] = {
			type = "colorpicker",
			name = str.INTRICATE_LABEL,
			tooltip = str.INTRICATE_TOOLTIP,
			getFunc = function()
						local r, g, b, a = HexToRGBA(settings.intricateColor)
						return r, g, b
					end,
			setFunc = function(r, g, b)
						settings.intricateColor = RGBAToHex(r, g, b, 1)
						ResearchAssistant_InvUpdate()
					end
		},

		[11] = {
			type = "header",
			name = "Character-Specific Tracking Options"
		},

		[12] = {
			type = "checkbox",
			name = str.BLACKSMITH_LABEL,
			tooltip = str.BLACKSMITH_TOOLTIP,
			getFunc = function() return settings.isBlacksmith[GetUnitName("player")] end,
			setFunc = function(value)
						settings.isBlacksmith[GetUnitName("player")] = value
						ResearchAssistant_InvUpdate()
					end
		},

		[13] = {
			type = "checkbox",
			name = str.CLOTHIER_LABEL,
			tooltip = str.CLOTHIER_TOOLTIP,
			getFunc = function() return settings.isClothier[GetUnitName("player")] end,
			setFunc = function(value)
						settings.isClothier[GetUnitName("player")] = value
						ResearchAssistant_InvUpdate()
					end
		},

		[14] = {
			type = "checkbox",
			name = str.WOODWORKING_LABEL,
			tooltip = str.WOODWORKING_TOOLTIP,
			getFunc = function() return settings.isWoodworking[GetUnitName("player")] end,
			setFunc = function(value)
						settings.isWoodworking[GetUnitName("player")] = value
						ResearchAssistant_InvUpdate()
					end
		},

		[15] = {
			type = "header",
			name = "Miscellaneous Tracking Options"
		},

		[16] = {
			type = "checkbox",
			name = str.SHOW_RESEARCHED_LABEL,
			tooltip = str.SHOW_RESEARCHED_TOOLTIP,
			getFunc = function() return settings.showResearched end,
			setFunc = function(value)
						settings.showResearched = value
						ResearchAssistant_InvUpdate()
					end
		},

		[17] = {
			type = "checkbox",
			name = str.SHOW_TRAITLESS_LABEL,
			tooltip = str.SHOW_TRAITLESS_TOOLTIP,
			getFunc = function() return settings.showTraitless end,
			setFunc = function(value)
						settings.showTraitless = value
						ResearchAssistant_InvUpdate()
					end,
			disabled = function() return not settings.showResearched end
		},

		[18] = {
			type = "checkbox",
			name = str.SHOW_ORNATE_LABEL,
			tooltip = str.SHOW_ORNATE_TOOLTIP,
			getFunc = function() return settings.showUntrackedOrnate end,
			setFunc = function(value)
						settings.showUntrackedOrnate = value
						ResearchAssistant_InvUpdate()
					end
		},

		[19] = {
			type = "checkbox",
			name = str.SHOW_INTRICATE_LABEL,
			tooltip = str.SHOW_INTRICATE_TOOLTIP,
			getFunc = function() return settings.showUntrackedIntricate end,
			setFunc = function(value)
						settings.showUntrackedIntricate = value
						ResearchAssistant_InvUpdate()
					end
		},

		[20] = {
			type = "header",
			name = "Cross-Character Tracking Options"
		},

		[21] = {
			type = "checkbox",
			name = str.CROSS_CHAR_LABEL,
			tooltip = str.CROSS_CHAR_TOOLTIP,
			getFunc = function() return settings.useCrossCharacter[GetUnitName("player")] end,
			setFunc = function(value)
						settings.useCrossCharacter[GetUnitName("player")] = value
						ResearchAssistant_InvUpdate()
					end
		},

		[22] = {
			type = "dropdown",
			name = str.BS_CHAR_LABEL,
			tooltip = str.BS_CHAR_TOOLTIP,
			choices = knownCharacters,
			getFunc = function() return settings.blacksmithCharacter[GetUnitName("player")] end,
			setFunc = function(value)
						settings.blacksmithCharacter[GetUnitName("player")] = value
						ResearchAssistant_InvUpdate()
					end,
			disabled = function() return not settings.useCrossCharacter[GetUnitName("player")] end
		},

		[23] = {
			type = "dropdown",
			name = str.CL_CHAR_LABEL,
			tooltip = str.CL_CHAR_TOOLTIP,
			choices = knownCharacters,
			getFunc = function() return settings.clothierCharacter[GetUnitName("player")] end,
			setFunc = function(value)
						settings.clothierCharacter[GetUnitName("player")] = value
						ResearchAssistant_InvUpdate()
					end,
			disabled = function() return not settings.useCrossCharacter[GetUnitName("player")] end
		},

		[24] = {
			type = "dropdown",
			name = str.WW_CHAR_LABEL,
			tooltip = str.WW_CHAR_TOOLTIP,
			choices = knownCharacters,
			getFunc = function() return settings.woodworkingCharacter[GetUnitName("player")] end,
			setFunc = function(value)
						settings.woodworkingCharacter[GetUnitName("player")] = value
						ResearchAssistant_InvUpdate()
					end,
			disabled = function() return not settings.useCrossCharacter[GetUnitName("player")] end
		}
	}

	LAM:RegisterAddonPanel("ResearchAssistantSettingsPanel", panel)
	LAM:RegisterOptionControls("ResearchAssistantSettingsPanel", optionsData)

	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated",
		function()
			icon:SetParent(RA_Icon_Dropdown)
			icon:SetTexture(CAN_RESEARCH_TEXTURES[settings.textureName].texturePath)
			icon:SetDimensions(CAN_RESEARCH_TEXTURES[settings.textureName].textureSize, CAN_RESEARCH_TEXTURES[settings.textureName].textureSize)
			icon:SetAnchor(CENTER, RA_Icon_Dropdown, CENTER, 36, 0)
		end)
end

function ResearchAssistantSettings:GetLanguage()
	local lang = GetCVar("language.2")

	--check for supported languages
	if(lang == "de" or lang == "en" or lang == "fr") then return lang end

	--return english if not supported
	return "en"
end