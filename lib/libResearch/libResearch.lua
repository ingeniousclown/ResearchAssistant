local MAJOR, MINOR = "libResearch", 2
local libResearch, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not libResearch then return end	--the same or newer version of this lib is already loaded into memory 
--thanks to Seerah for the previous lines and library

local BLACKSMITH = CRAFTING_TYPE_BLACKSMITHING
local CLOTHIER = CRAFTING_TYPE_CLOTHIER
local WOODWORK = CRAFTING_TYPE_WOODWORKING

local researchMap = {
	[BLACKSMITH] = {
		WEAPON = {
			[WEAPONTYPE_AXE] = 1,
			[WEAPONTYPE_HAMMER] = 2,
			[WEAPONTYPE_SWORD] = 3,
			[WEAPONTYPE_TWO_HANDED_AXE] = 4,
			[WEAPONTYPE_TWO_HANDED_HAMMER] = 5,
			[WEAPONTYPE_TWO_HANDED_SWORD] = 6,
			[WEAPONTYPE_DAGGER] = 7
		},
		ARMOR = {
			[EQUIP_TYPE_CHEST] = 8,
			[EQUIP_TYPE_FEET] = 9,
			[EQUIP_TYPE_HAND] = 10,
			[EQUIP_TYPE_HEAD] = 11,
			[EQUIP_TYPE_LEGS] = 12,
			[EQUIP_TYPE_SHOULDERS] = 13,
			[EQUIP_TYPE_WAIST] = 14
		}
	},

	--normal for light, +7 for medium
	[CLOTHIER] = {
		ARMOR =  {
			[EQUIP_TYPE_CHEST] = 1,
			[EQUIP_TYPE_FEET] = 2,
			[EQUIP_TYPE_HAND] = 3,
			[EQUIP_TYPE_HEAD] = 4,
			[EQUIP_TYPE_LEGS] = 5,
			[EQUIP_TYPE_SHOULDERS] = 6,
			[EQUIP_TYPE_WAIST] = 7
		}
	},

	[WOODWORK] = {
		WEAPON = {
			[WEAPONTYPE_BOW] = 1,
			[WEAPONTYPE_FIRE_STAFF] = 2,
			[WEAPONTYPE_FROST_STAFF] = 3,
			[WEAPONTYPE_LIGHTNING_STAFF] = 4,
			[WEAPONTYPE_HEALING_STAFF] = 5
		},
		ARMOR = {
			[EQUIP_TYPE_OFF_HAND] = 6
		}
	},
}


--anything greater than 10 is researchable
function libResearch:DetailedIsItemResearchable( bagId, slotIndex )
	local itemType = GetItemType(bagId, slotIndex)
	if(itemType ~= ITEMTYPE_ARMOR and itemType ~= ITEMTYPE_WEAPON) then
		return -1 -- (-1) is unresearchable
	end

	local craftingSkillType, researchLineIndex, traitIndex = self:GetItemResearchInfo(bagId, slotIndex)

	if(traitIndex == 9 or traitIndex == 10) then
		return traitIndex -- 9 and 10 are not researchable but are special traits
	end

	if(craftingSkillType == -1 or researchLineIndex == -1 or traitIndex == -1) then
		if(craftingSkillType ~= -1) then
			return 0  -- 0 means no traits, but is a deconstructable type
		end
		return -1 -- (-1) is unresearchable
	end

	if (CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingSkillType, researchLineIndex, traitIndex)
		and not GetSmithingResearchLineTraitTimes(craftingSkillType, researchLineIndex, traitIndex)) then --if not nil, then researching
		return self:GetTraitKey(craftingSkillType, researchLineIndex, traitIndex)
	end
	return false -- false is already researched
end

function libResearch:IsItemResearchable( bagId, slotIndex )
	local result = libResearch:DetailedIsItemResearchable(bagId, slotIndex)
	if(result and result > 10) then
		return true
	else
		return false
	end
end

function libResearch:GetTraitKey( craftingSkillType, researchLineIndex, traitIndex )
	return craftingSkillType * 10000 + researchLineIndex * 100 + traitIndex
end

function libResearch:GetItemCraftingSkill( bagId, slotIndex )
	if(CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, BLACKSMITH)) then return BLACKSMITH end
	if(CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, CLOTHIER)) then return CLOTHIER end
	if(CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, WOODWORK)) then return WOODWORK end
	return -1
end

function libResearch:GetResearchTraitIndex( bagId, slotIndex )
	local traitType = GetItemTrait(bagId, slotIndex)
	local traitIndex = traitType

	if(traitIndex == ITEM_TRAIT_TYPE_ARMOR_ORNATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_ORNATE) then
		return 9
	elseif(traitIndex == ITEM_TRAIT_TYPE_ARMOR_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE) then
		return 10
	end

	--this used to be "if(itemType == ITEMTYPE_ARMOR)", but shields are not armor even though they are armor
	if(traitIndex > 10) then
		traitIndex = traitIndex - 10;
	end

	if(not (traitIndex >= 1 and traitIndex <=8)) then
		return -1
	end

	return traitIndex
end

function libResearch:GetResearchLineIndex( bagId, slotIndex )
	local itemLink = GetItemLink(bagId, slotIndex)
	local craftingSkillType = self:GetItemCraftingSkill(bagId, slotIndex)
	local armorType = GetItemArmorType(itemLink)
	local _,_,_,_,_,equipType = GetItemInfo(bagId, slotIndex)

	if(craftingSkillType ~= BLACKSMITH and craftingSkillType ~= WOODWORK and craftingSkillType ~= CLOTHIER) then
		return -1
	end

	local researchLineIndex
	--if is armor
	if(armorType ~= ARMORTYPE_NONE or equipType == EQUIP_TYPE_OFF_HAND) then
		researchLineIndex = researchMap[craftingSkillType].ARMOR[equipType]
		if(armorType == ARMORTYPE_MEDIUM) then
			researchLineIndex = researchLineIndex + 7
		end
	--else is weapon or nothing
	else
		--check if actually is weapon first
		local weaponType = GetItemWeaponType(itemLink)
		if(weaponType == WEAPONTYPE_NONE) then
			return -1
		end
		researchLineIndex = researchMap[craftingSkillType].WEAPON[weaponType]
	end

	return researchLineIndex or -1
end

function libResearch:GetItemResearchInfo( bagId, slotIndex )
	return self:GetItemCraftingSkill(bagId,slotIndex), self:GetResearchLineIndex(bagId, slotIndex), self:GetResearchTraitIndex(bagId, slotIndex)
end

function libResearch:IsCraftingTraitKnownOrResearching( craftingSkillType, researchLineIndex, traitIndex )
	local _,_,known = GetSmithingResearchLineTraitInfo(craftingSkillType, researchLineIndex, traitIndex)
	if (known or GetSmithingResearchLineTraitTimes(craftingSkillType, researchLineIndex, traitIndex)) then --if not nil, then researching
		return true
	else
		return false
	end
end

function libResearch:IsBigThreeCrafting( craftingSkillType )
	if(craftingSkillType == BLACKSMITH or craftingSkillType == CLOTHIER or craftingSkillType == WOODWORK) then
		return true
	end
	return false
end

function libResearch:GetResearchMap()
	return researchMap
end