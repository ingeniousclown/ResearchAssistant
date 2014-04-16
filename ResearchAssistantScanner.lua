
ResearchAssistantScanner = ZO_Object:Subclass()

local BLACKSMITH = CRAFTING_TYPE_BLACKSMITHING
local CLOTHIER = CRAFTING_TYPE_CLOTHIER
local WOODWORK = CRAFTING_TYPE_WOODWORKING

function ResearchAssistantScanner:New()
	local obj = ZO_Object.New(self)
	obj:Initialize()
	return obj
end

function ResearchAssistantScanner:Initialize()
	self.ownedTraits = {}
	self.isScanning = false
	self.scanMore = 0

	self:RescanBags()
end

function ResearchAssistantScanner:IsScanning()
	return self.isScanning
end

function ResearchAssistantScanner:GetItemCraftingSkill(bagId, slotIndex)
	if(CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, BLACKSMITH)) then return BLACKSMITH end
	if(CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, CLOTHIER)) then return CLOTHIER end
	if(CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, WOODWORK)) then return WOODWORK end
	return nil
end

function ResearchAssistantScanner:CreateItemPreferenceValue(bagId, slotIndex)
    local _,_,_,_,_,_,_,quality = GetItemInfo(bagId, slotIndex)
    if (not quality) then
        quality = 0
    end

    local level = GetItemLevel(bagId, slotIndex)
    if (not level) then
        level = 0
    end

    local where = 0
    if(bagId == BAG_BACKPACK) then
    	where = 2
	elseif(bagId == BAG_BANK) then
		where = 1
	elseif(bagId == BAG_GUILDBANK) then
		where = 3
	end

    --wxxxyzzz
    --the lowest preference value is the "preferred" value
    --bank is lowest number, will be orange if you have a dupe in your inventory
    --bag is middle number, will be yellow if you have a dupe in the inventory
    --gbank is highest number, will be yellow if you have a dupe in the inventory
    return quality * 10000000 + level * 10000 + where * 1000 + slotIndex
end

function ResearchAssistantScanner:CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, craftingSkillType, traitIndex)
	--if it can't be extracted or refined here, then it can't be researched!
	if not CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, craftingSkillType) then return nil end
	
	local numLines = GetNumSmithingResearchLines(craftingSkillType)

	for i=1, numLines do
		if (CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingSkillType, i, traitIndex)) then
			return craftingSkillType * 1000000 + equipType * 10000 + i * 100 + traitIndex
		end
	end

	return nil  --nil will evaluate as false
end

function ResearchAssistantScanner:CheckIsItemResearchable(bagId, slotIndex)
	local itemType = GetItemType(bagId, slotIndex)
	if(itemType ~= ITEMTYPE_ARMOR and itemType ~= ITEMTYPE_WEAPON) then
		return -1
	end

	local traitType = GetItemTrait(bagId, slotIndex)
	local traitIndex = traitType

	if(traitIndex == ITEM_TRAIT_TYPE_ARMOR_ORNATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_ORNATE) then
		return 9
	elseif(traitIndex == ITEM_TRAIT_TYPE_ARMOR_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE) then
		return 10
	end

	local _,_,_,_,_,equipType = GetItemInfo(bagId, slotIndex)
	if(equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_AMULET) then
		return -1
	end

	--this used to be "if(itemType == ITEMTYPE_ARMOR)", but shields are not armor even though they are armor
	if(traitIndex > 10) then
		traitIndex = traitIndex - 10;
	end

	if(not (traitIndex >= 1 and traitIndex <=8)) then
		return nil
	end

	return self:CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, BLACKSMITH, traitIndex)
		or self:CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, CLOTHIER, traitIndex)
	 	or self:CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, WOODWORK, traitIndex)
end

function ResearchAssistantScanner:ScanBag( bagId )
	local _, numSlots = GetBagInfo(bagId)
	for i=1, numSlots do
		local magicNumber = self:CheckIsItemResearchable(bagId, i)
		if(magicNumber and magicNumber >= 0) then 
			local prefValue = self:CreateItemPreferenceValue(bagId, i)
			if(self.ownedTraits[magicNumber]) then
				if(prefValue < self.ownedTraits[magicNumber]) then
					self.ownedTraits[magicNumber] = prefValue
				end
			else
				self.ownedTraits[magicNumber] = prefValue
			end
		end
	end
end

function ResearchAssistantScanner:RescanBags()
	if(self.isScanning) then
		self.scanMore = self.scanMore + 1 
		return
	end
	self.isScanning = true

	for _,v in pairs(self.ownedTraits) do
		v = nil
	end
	self.ownedTraits = {}

	self:ScanBag(BAG_BACKPACK)
	self:ScanBag(BAG_BANK)

	if(self.scanMore ~= 0) then
		self.scanMore = self.scanMore - 1
		self.isScanning = false
		self:RescanBags()
	else
		self.isScanning = false
	end
end

function ResearchAssistantScanner:GetTrait( traitKey )
	return self.ownedTraits[traitKey]
end