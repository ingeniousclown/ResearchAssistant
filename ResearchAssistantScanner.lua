
ResearchAssistantScanner = ZO_Object:Subclass()
libResearch = LibStub("libResearch")

local BLACKSMITH = CRAFTING_TYPE_BLACKSMITHING
local CLOTHIER = CRAFTING_TYPE_CLOTHIER
local WOODWORK = CRAFTING_TYPE_WOODWORKING

function ResearchAssistantScanner:New( ... )
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function ResearchAssistantScanner:Initialize( settings )
	self.ownedTraits = {}
	self.isScanning = false
	self.scanMore = 0
	self.settingsPtr = settings

	self:RescanBags()
end

function ResearchAssistantScanner:IsScanning()
	return self.isScanning
end

function ResearchAssistantScanner:CreateItemPreferenceValue( bagId, slotIndex )
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

function ResearchAssistantScanner:ScanBag( bagId )
	local _, numSlots = GetBagInfo(bagId)
	for i=1, numSlots do
		local magicNumber = self:CheckIsItemResearchable(bagId, i)
		local prefValue = self:CreateItemPreferenceValue(bagId, i)
		if(magicNumber and magicNumber >= 10) then 
			if(self.ownedTraits[magicNumber] and self.ownedTraits[magicNumber] ~= true) then
				if(prefValue < self.ownedTraits[magicNumber]) then
					self.ownedTraits[magicNumber] = prefValue
				end
			else
				self.ownedTraits[magicNumber] = prefValue
			end
		end
	end
end

function ResearchAssistantScanner:ScanKnownTraits()
	for researchLineIndex=1,GetNumSmithingResearchLines(BLACKSMITH) do
		for traitIndex=1,8 do
			if (libResearch:IsCraftingTraitKnownOrResearching(BLACKSMITH, researchLineIndex, traitIndex)) then --if not nil, then researching
				self.ownedTraits[self:GetTraitKey(BLACKSMITH, researchLineIndex, traitIndex)] = true
			end
		end
	end
	for researchLineIndex=1,GetNumSmithingResearchLines(CLOTHIER) do
		for traitIndex=1,8 do
			if (libResearch:IsCraftingTraitKnownOrResearching(CLOTHIER, researchLineIndex, traitIndex)) then --if not nil, then researching
				self.ownedTraits[self:GetTraitKey(CLOTHIER, researchLineIndex, traitIndex)] = true
			end
		end
	end
	for researchLineIndex=1,GetNumSmithingResearchLines(WOODWORK) do
		for traitIndex=1,8 do
			if (libResearch:IsCraftingTraitKnownOrResearching(WOODWORK, researchLineIndex, traitIndex)) then --if not nil, then researching
				self.ownedTraits[self:GetTraitKey(WOODWORK, researchLineIndex, traitIndex)] = true
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

	self:ScanKnownTraits()
	self.settingsPtr:SetKnownTraits(self.ownedTraits)

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

--wrapping the libResearch so I can use it but not have to search for all the references :P
--oh, look! rudimentary version-checking :3
ResearchAssistantScanner.isExposed = true  --deprecated
--anything greater than 10 is researchable
function ResearchAssistantScanner:CheckIsItemResearchable( bagId, slotIndex )
	return libResearch:DetailedIsItemResearchable(bagId, slotIndex)
end

function ResearchAssistantScanner:IsItemResearchable( bagId, slotIndex )
	return libResearch:IsItemResearchable(bagId,slotIndex)
end

function ResearchAssistantScanner:GetTraitKey( craftingSkillType, researchLineIndex, traitIndex )
	return libResearch:GetTraitKey(craftingSkillType, researchLineIndex, traitIndex)
end

function ResearchAssistantScanner:GetItemCraftingSkill( bagId, slotIndex )
	return libResearch:GetItemCraftingSkill(bagId, slotIndex)
end

function ResearchAssistantScanner:GetResearchTraitIndex( bagId, slotIndex )
	return libResearch:GetResearchTraitIndex(bagId, slotIndex)
end

function ResearchAssistantScanner:GetResearchLineIndex( bagId, slotIndex )
	return libResearch:GetResearchLineIndex(bagId, slotIndex)
end

function ResearchAssistantScanner:GetItemResearchInfo( bagId, slotIndex )
	return libResearch:GetItemResearchInfo(bagId, slotIndex)
end