------------------------------------------------------------------
--ResearchAssistant.lua
--Author: ingeniousclown, with some minor modifications by tejón
		--German translation by Tonyleila
		--French translation by Ykses
--v0.7.1
--[[
Shows you when you can sell an item instead of saving it for
research.
]]
------------------------------------------------------------------

local BACKPACK = ZO_PlayerInventoryBackpack
local BANK = ZO_PlayerBankBackpack
local GUILD_BANK = ZO_GuildBankBackpack
local DECONSTRUCTION = ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack

local ORNATE_TEXTURE = [[/esoui/art/tradinghouse/tradinghouse_sell_tabicon_disabled.dds]]
local INTRICATE_TEXTURE = [[/esoui/art/progression/progression_indexicon_guilds_up.dds]]

local tooltips = {
	["en"] = {
		ornate = "Ornate: You should sell this!",
		intricate = "Intricate: You should deconstruct this!",
		duplicate = "Better research candidate available!",
		canResearch = "You don't know this trait!",
		alreadyResearched = "You know this trait!"
	},
	["de"] = {
		ornate = "Verkaufspreis: Beim Händer verkaufen!",
		intricate = "Inspiration: Verwerte dieses Item!",
		duplicate = "Besserer Analyse Kandidat vorhanden!",
		canResearch = "Unbekannte Eigenschaft!",
		alreadyResearched = "Bereits bekannt!"
	},
	["fr"] = {
		ornate = "Orn\195\169 : Vous devriez le vendre !",
		intricate = "Complexe : Vous devriez le d\195\169construire !",
		duplicate = "Vous poss\195\169dez d\195\169j\195\160 un objet de moins bonne qualit\195\169 pour effectuer cette recherche !",
		canResearch = "Vous ne connaissez pas encore ce trait !",
		alreadyResearched = "Vous connaissez d\195\169j\195\160 ce trait !"
	}
}

local RASettings = nil
local RAScanner = nil

local function AddTooltips( control, text )
	control:SetHandler("OnMouseEnter", function(self)
			ZO_Tooltips_ShowTextTooltip(self, TOP, text)
		end)
	control:SetHandler("OnMouseExit", function(self)
			ZO_Tooltips_HideTextTooltip()
		end)
end

local function RemoveTooltips( control )
	control:SetHandler("OnMouseEnter", nil)
	control:SetHandler("OnMouseExit", nil)
end

local function HandleTooltips( control, text )
	if(RASettings:ShowTooltips()) then
		control:SetMouseEnabled(true)
		AddTooltips(control, text)
	else
		control:SetMouseEnabled(false)
		RemoveTooltips(control)
	end
end

local function SetToOrnate( indicatorControl )
	indicatorControl:SetTexture(ORNATE_TEXTURE)
	indicatorControl:SetColor(unpack(RASettings:GetOrnateColor()))
	indicatorControl:SetDimensions(35, 35)
	indicatorControl:SetHidden(false)
	HandleTooltips(indicatorControl, tooltips[RASettings:GetLanguage()].ornate)
end

local function SetToIntricate( indicatorControl )
	indicatorControl:SetTexture(INTRICATE_TEXTURE)
	indicatorControl:SetColor(unpack(RASettings:GetIntricateColor()))
	indicatorControl:SetDimensions(40, 40)
	indicatorControl:SetHidden(false)
	HandleTooltips(indicatorControl, tooltips[RASettings:GetLanguage()].intricate)
end

local function SetToNormal( indicatorControl )
	indicatorControl:SetTexture(RASettings:GetTexturePath())
	indicatorControl:SetDimensions(RASettings:GetTextureSize(), RASettings:GetTextureSize())
	indicatorControl:SetHidden(true)
end

local function CreateIndicatorControl(parent)
	local control = WINDOW_MANAGER:CreateControl(parent:GetName() .. "Research", parent, CT_TEXTURE)
	control:SetAnchor(CENTER, parent, CENTER, 115)
	control:SetDrawTier(DT_HIGH)
	SetToNormal(control)

	return control
end

local function AddResearchIndicatorToSlot(control)
	local bagId = control.dataEntry.data.bagId
	local slotIndex = control.dataEntry.data.slotIndex
	
	--get indicator control, or create one if it doesnt exist
	local indicatorControl = control:GetNamedChild("Research")
	if(not indicatorControl) then
		indicatorControl = CreateIndicatorControl(control)
	end
	if(control:GetWidth() - control:GetHeight() < 5 and not RASettings:ShowInGrid()) then 
		indicatorControl:SetHidden(true)
		return 
	end

	--hide the control for non-weapons and armor
	local magicTrait = RAScanner:CheckIsItemResearchable(bagId, slotIndex)
	local craftingSkill = RAScanner:GetItemCraftingSkill(bagId, slotIndex)
	if(magicTrait == -1 
		or (magicTrait == 0 and not RASettings:ShowTraitless()) 
		or (magicTrait == false and not RASettings:ShowResearched() and not RASettings:IsUseCrossCharacter())
		or (RAScanner:IsBigThreeCrafting(craftingSkill) and RASettings:IsUseCrossCharacter() and RASettings:IsMultiCharSkillOff(craftingSkill))) then
		indicatorControl:SetHidden(true)
		return
	end

	if(magicTrait == 9) then
		SetToOrnate(indicatorControl)
		if(not RASettings:IsCraftingSkillEnabled(craftingSkill) and not RASettings:ShowUntrackedOrnate()) then
			indicatorControl:SetHidden(true)
		end
		return
	elseif(magicTrait == 10) then
		SetToIntricate(indicatorControl)
		if(not RASettings:IsCraftingSkillEnabled(craftingSkill) and not RASettings:ShowUntrackedIntricate()) then
			indicatorControl:SetHidden(true)
		end
		return
	else
		SetToNormal(indicatorControl)
		if(not RASettings:IsCraftingSkillEnabled(craftingSkill) and not RASettings:IsUseCrossCharacter()) then
			indicatorControl:SetHidden(true)
			return
		end
	end

	indicatorControl:ClearAnchors()
	if(control.isGrid or control:GetWidth() - control:GetHeight() < 5) then
		indicatorControl:SetAnchor(TOPLEFT, control, TOPLEFT, 3)
	else
		indicatorControl:SetAnchor(CENTER, control, CENTER, 115)
	end

	local trackedTraitKey
	if(magicTrait == false) then
		trackedTraitKey = RASettings:GetPreferenceValueForTrait(RAScanner:GetTraitKey(RAScanner:GetItemResearchInfo(bagId, slotIndex)))
	else
		trackedTraitKey = RASettings:GetPreferenceValueForTrait(magicTrait)
	end

	indicatorControl:SetHidden(false)
	if((magicTrait ~= false and magicTrait ~= 0 and trackedTraitKey ~= true) 
		or (RASettings:IsUseCrossCharacter() and trackedTraitKey ~= true and magicTrait ~= 0 and magicTrait ~= -1)) then
		local thisValue = RAScanner:CreateItemPreferenceValue(bagId, slotIndex)
		local stackSize = control.dataEntry.data.stackCount or 0
		if(trackedTraitKey and (thisValue > trackedTraitKey or stackSize > 1)) then
			indicatorControl:SetColor(unpack(RASettings:GetDuplicateUnresearchedColor()))
			HandleTooltips(indicatorControl, tooltips[RASettings:GetLanguage()].duplicate)
		else
			indicatorControl:SetColor(unpack(RASettings:GetCanResearchColor()))
			HandleTooltips(indicatorControl, tooltips[RASettings:GetLanguage()].canResearch)
		end
	else
		indicatorControl:SetColor(unpack(RASettings:GetAlreadyResearchedColor()))
		HandleTooltips(indicatorControl, tooltips[RASettings:GetLanguage()].alreadyResearched)
		if(not RASettings:ShowResearched()) then
			indicatorControl:SetHidden(true)
		end
	end

end

local function AreAllHidden()
	return BANK:IsHidden() and BACKPACK:IsHidden() and GUILD_BANK:IsHidden() and DECONSTRUCTION:IsHidden()
end

-- a simple event buffer to make sure that the scan doesn't happen more than once in a
-- single instance, as EVENT_INVENTORY_SINGLE_SLOT_UPDATE is very spammy, especially
-- with junk and bank management add-ons
local canUpdate = true
function ResearchAssistant_InvUpdate( ... )
	if(canUpdate) then
		canUpdate = false
		zo_callLater(function() 
				RAScanner:RescanBags()
				canUpdate = true
			end, 25)
	end
end

local function ResearchAssistant_Loaded(eventCode, addOnName)
	if(addOnName ~= "ResearchAssistant") then
        return
    end

	RASettings = ResearchAssistantSettings:New()
	RAScanner = ResearchAssistantScanner:New(RASettings)

	--inventories hook
	for _,v in pairs(PLAYER_INVENTORY.inventories) do
		local listView = v.listView
		if listView and listView.dataTypes and listView.dataTypes[1] then
			local hookedFunctions = listView.dataTypes[1].setupCallback				
			
			listView.dataTypes[1].setupCallback = 
				function(rowControl, slot)						
					hookedFunctions(rowControl, slot)
					AddResearchIndicatorToSlot(rowControl)
				end				
		end
	end

	--deconstruction hook
	local hookedFunctions = DECONSTRUCTION.dataTypes[1].setupCallback
	DECONSTRUCTION.dataTypes[1].setupCallback = function(rowControl, slot)
			hookedFunctions(rowControl, slot)
			AddResearchIndicatorToSlot(rowControl)
		end

	EVENT_MANAGER:RegisterForEvent("RA_INV_SLOT_UPDATE", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, ResearchAssistant_InvUpdate)
	-- RA_Controller:SetHandler("OnUpdate", RA_OnUpdate)
end

local function ResearchAssistant_Initialized()
	EVENT_MANAGER:RegisterForEvent("ResearchAssistantLoaded", EVENT_ADD_ON_LOADED, ResearchAssistant_Loaded)
end

ResearchAssistant_Initialized()