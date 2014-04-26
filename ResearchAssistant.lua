------------------------------------------------------------------
--ResearchAssistant.lua
--Author: ingeniousclown, with some minor modifications by tejón
		--German translation by Tonyleila
		--French translation by Ykses
--v0.6.6c
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
	control:SetAnchor(CENTER, parent, CENTER, 100)
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

	--hide the control for non-weapons and armor
	local magicTrait = RAScanner:CheckIsItemResearchable(bagId, slotIndex)
	if(magicTrait and magicTrait < 0) then
		indicatorControl:SetHidden(true)
		return
	end

	local craftingSkill = RAScanner:GetItemCraftingSkill(bagId, slotIndex)
	if(magicTrait and magicTrait == 9) then
		SetToOrnate(indicatorControl)
		if(craftingSkill and not RASettings:IsCraftingSkillEnabled(craftingSkill) and not RASettings:ShowUntrackedOrnate()) then
			indicatorControl:SetHidden(true)
		end
		return
	elseif(magicTrait and magicTrait == 10) then
		SetToIntricate(indicatorControl)
		if(craftingSkill and not RASettings:IsCraftingSkillEnabled(craftingSkill) and not RASettings:ShowUntrackedIntricate()) then
			indicatorControl:SetHidden(true)
		end
		return
	else
		SetToNormal(indicatorControl)
		if(craftingSkill and not RASettings:IsCraftingSkillEnabled(craftingSkill)) then
			return
		end
	end

	indicatorControl:SetHidden(false)
	if(magicTrait and magicTrait >= 0) then
		local thisValue = RAScanner:CreateItemPreferenceValue(bagId, slotIndex)
		local stackSize = control.dataEntry.data.stackCount or 0
		if(RAScanner:GetTrait(magicTrait) and (thisValue > RAScanner:GetTrait(magicTrait) or stackSize > 1)) then
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

local function AddResearchIndicators(self)
	for _,v in pairs(self.activeControls) do
		AddResearchIndicatorToSlot(v)
	end
end

local function CheckNow(self)
	if(#self.activeControls > 0 and not self.isGrid and not self:IsHidden()) then
        AddResearchIndicators(self)
    end
end

local function AreAllHidden()
	return BANK:IsHidden() and BACKPACK:IsHidden() and GUILD_BANK:IsHidden() and DECONSTRUCTION:IsHidden()
end

local bufferTime = 50 --ms
local elapsedTime = 0
local function RA_OnUpdate()
	elapsedTime = elapsedTime + GetFrameDeltaTimeMilliseconds()
	if(RAScanner:IsScanning() or elapsedTime < bufferTime) then return end
	elapsedTime = 0

	if(AreAllHidden()) then return end

	CheckNow(BANK)
	CheckNow(BACKPACK)
	CheckNow(GUILD_BANK)
	CheckNow(DECONSTRUCTION)
end

local function RA_InvUpdate( ... )
	RAScanner:RescanBags()
	if(RASettings:IsActivated() and not AreAllHidden()) then
		RA_Controller:SetHandler("OnUpdate", RA_OnUpdate)
	end
end

local function ResearchAssistant_Loaded(eventCode, addOnName)
	if(addOnName ~= "ResearchAssistant") then
        return
    end

	RASettings = ResearchAssistantSettings:New()
	RAScanner = ResearchAssistantScanner:New()

	EVENT_MANAGER:RegisterForEvent("RA_INV_SLOT_UPDATE", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RA_InvUpdate)
	RA_Controller:SetHandler("OnUpdate", RA_OnUpdate)
end

local function ResearchAssistant_Initialized()
	EVENT_MANAGER:RegisterForEvent("ResearchAssistantLoaded", EVENT_ADD_ON_LOADED, ResearchAssistant_Loaded)
end

ResearchAssistant_Initialized()