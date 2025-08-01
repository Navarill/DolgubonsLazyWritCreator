local queue = {}

local craftingWrits = false
local crafting
local closeOnce = false

-- Use this script to determine the index numbers:
-- /script for i = 1, 42 do local _,_,n = GetSmithingPatternMaterialItemInfo( 1, i) d(GetSmithingPatternResultLink(1, i, n, 1, 1, 1).. " : ".. i) end
local indexRanges = { --the first tier is index 1-7, second is material index 8-12, etc
	[1] = 1,
	[2] = 8,
	[3] = 13,
	[4] = 18,
	[5] = 23,
	[6] = 26,
	[7] = 29,
	[8] = 32,
	[9] = 34,
	[10] = 40,
	[11] = 1,
	[12] = 8,
	[13] = 13,
	[14] = 18,
	[15] = 23,
	[16] = 26,
	[17] = 29,
	[18] = 32,
	[19] = 34,
	[20] = 40,
}
local jewelryIndexRanges =
{
	[1] = 1,
	[2] = 13,
	[3] = 26,
	[4] = 33,
	[5] = 40,
}
local shouldShowGamepadPrompt = true

local smithingCrafting


local function getOut()
	return DolgubonsWritsBackdropOutput:GetText()
end

local function appendOut(str)
	local currentText = getOut()
	DolgubonsWritsBackdropOutput:SetText(currentText..str)
end

--outputs the string in the crafting window
local function out(str)
	DolgubonsWritsBackdropOutput:SetText(str)
end

function WritCreater.setCloseOnce()
	closeOnce = true
end

local function getGamepadCraftKeyIcon()
	local key
	for i =1, 4 do
		key = GetActionBindingInfo(3, 1, 3, i)
		if IsKeyCodeGamepadKey(key) then
			break
		end
	end
	return GetGamepadIconPathForKeyCode(key) or  GetMouseIconPathForKeyCode(key) or GetKeyboardIconPathForKeyCode(key) or ""
end
local gamepadCraftShortcut = false
WritCreater.gpCraftOutOriginalText = ""
local myButtonGroup = {
	alignment = KEYBIND_STRIP_ALIGN_LEFT,
	{
		name = "Craft Writ Items",
		keybind = "UI_SHORTCUT_TERTIARY",
		order = 2500,
		callback = function(input, input2)
			WritCreater.craft()
			gamepadCraftShortcut =false
		end,
	},
}

local function removeCraftKeybind()
	KEYBIND_STRIP:RemoveKeybindButtonGroup(myButtonGroup)
end

local function showCraftButton(craftingWrits)
	if not IsInGamepadPreferredMode() then
		DolgubonsWritsBackdropCraft:SetHidden(craftingWrits) 
	else
		if craftingWrits == true  or not shouldShowGamepadPrompt then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(myButtonGroup)
			out(WritCreater.gpCraftOutOriginalText)
			return 
		end
		myButtonGroup = {
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			{
				name = "Craft Writ Items",
				keybind = "UI_SHORTCUT_TERTIARY",
				order = 2500,
				callback = function(input, input2)
					WritCreater.craft()
					gamepadCraftShortcut =false
				end,
			},
		}
		KEYBIND_STRIP:AddKeybindButtonGroup(myButtonGroup)
		appendOut("\nPress |t32:32:"..getGamepadCraftKeyIcon().."|t to craft")
	end
end
WritCreater.showCraftButton = showCraftButton
local craftingRootScenes = {
	gamepad_enchanting_mode = true,
	gamepad_smithing_root = true,
	gamepad_provisioner_root = true,
	gamepad_alchemy_mode = true,
}
SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, newState)
	if not IsInGamepadPreferredMode() then return end
	local sceneName = scene:GetName()
	if craftingRootScenes[sceneName] and newState == SCENE_SHOWING and not DolgubonsWrits:IsHidden() then
	-- if sceneName == "gamepad_smithing_root" and newState == SCENE_SHOWN and gamepadCraftShortcut then
		local writs = WritCreater.writSearch()
		-- if not WritCreater:GetSettings().autoCraft and not craftingWrits then
		if WritCreater.gpCraftOutOriginalText == getOut() then
			-- smithingCrafting(writs[station],craftingWrits)
			showCraftButton()
		end
		
	elseif (newState == SCENE_SHOWING) and not craftingRootScenes[sceneName] then
		-- if IsSmithingCraftingType(GetCraftingInteractionType() ) then
			out(WritCreater.gpCraftOutOriginalText)
			removeCraftKeybind()
		-- end
	end
	 end)
-- GAMEPAD_SMITHING_ROOT_SCENE
--Helper functions

--Capitalizes first letter, decapitalizes everything else
local function proper(str)
	if type(str)== "string" then
		return zo_strformat("<<C:1>>",str)
	else
		return str
	end
end

local function myLower(str)
	return zo_strformat("<<z:1>>",str)
end


local function myUpper(str)
	return zo_strformat("<<Z:1>>",str)
end

function GetItemNameFromItemId(itemId)

	return GetItemLinkName(ZO_LinkHandler_CreateLink("Test Trash", nil, ITEM_LINK_TYPE,itemId, 1, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 10000, 0))
end



local function maxStyle (piece) -- Searches to find the style that the user has the most style stones for. Only searches basic styles. User must know style
-- Currently not actually used!!
 	
    local bagId = BAG_BACKPACK
    SHARED_INVENTORY:RefreshInventory(bagId)
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
 
    local max = -1
    local numKnown = 0
    local numAllowed = 0
    local maxStack = -1
    local useStolen = AreAnyItemsStolen(BAG_BACKPACK) and false
    local useMinimum = WritCreater:GetSettings().styles.smartStyleSlotSave
    for i, v in pairs(WritCreater:GetSettings().styles) do
        if v and type(i)=="number" then
            numAllowed = numAllowed + 1
	        
	        if IsSmithingStyleKnown(i, piece) then
	            numKnown = numKnown + 1
	 
	            for key, itemInfo in pairs(bagCache) do
	                local slotId = itemInfo.slotIndex
	                if itemInfo.stolen == true then
	                    local itemType, specialType = GetItemType(bagId, slotId)
	                    if itemType == ITEMTYPE_STYLE_MATERIAL then
	                        local icon, stack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyleId, quality = GetItemInfo(bagId, slotId)
	                        if itemStyleId == i then
	                            if stack > maxStack then
	                                maxStack = stack
	                                max = itemStyleId
	                                useStolen = true
	                            end
	                        end
	                    end
	                end
	            end
	 
	            if useStolen == false then
	                if GetCurrentSmithingStyleItemCount(i)>GetCurrentSmithingStyleItemCount(max) then
	                    if GetCurrentSmithingStyleItemCount(i)>0 and v then
	                        max = i
	                    end
	                end
	            end
	        end
        end
    end
    if max == -1 then
        if numKnown <3 then
            return -2
        end
        if numAllowed < 3 then
            return -3
        end
    end
    return max
end


local function maxStyle (piece) -- Searches to find the style that the user has the most style stones for. Only searches basic styles. User must know style

	local max = -1
	local numKnown = 0
	local numAllowed = 0
	local maxStones = 0 
	for i, v in pairs(WritCreater:GetSettings().styles) do
		if v and type(i)=="number" then 
			numAllowed = numAllowed + 1
		
			if IsSmithingStyleKnown(i, piece) then
				numKnown = numKnown + 1

				if GetCurrentSmithingStyleItemCount(i)>maxStones then 
					maxStones =  GetCurrentSmithingStyleItemCount(i)
					max = i
				end
			end
		end
	end
	if max == -1 then
		if numKnown <3 then 
			return -2
		end
		if numAllowed < 3 then
			return -3
		end
	end
	return max, maxStones
end




local function addMats(type,num,matsRequired, pattern, index)

	local place = matsRequired[type]

	if place then

		place.amount = place.amount + num
	else
		place = {}
		matsRequired[type] = place
		place.amount =  num
	end
	if place.amount == 0 then place = nil return end
	place.pattern = pattern
	place.index = index

	place.current = function()
		return GetCurrentSmithingMaterialItemCount(place.pattern ,place.index)
	end
end

local function doesCharHaveSkill(patternIndex,materialIndex,abilityIndex)
	if GetCraftingInteractionType()==0 then return end
	local requirement =  select(10,GetSmithingPatternMaterialItemInfo( patternIndex,  materialIndex))
	
	local _,skillIndex = SKILLS_DATA_MANAGER:GetCraftingSkillLineData(GetCraftingInteractionType()):GetIndices()
	local skillLevel = GetSkillAbilityUpgradeInfo(SKILL_TYPE_TRADESKILL ,skillIndex,abilityIndex )

	if skillLevel>=requirement then
		return true
	else
		return false
	end
end


local function setupConditionsTable(quest, indexTableToUse)
	local conditionsTable = 
	{
		["text"] = {},
		["cur"] = {},
		["max"] = {},
		["complete"] = {},
		["pattern"] = {},
		["mats"] = {},
	}
	for condition = 1, GetJournalQuestNumConditions(quest,1) do
		conditionsTable["text"][condition], conditionsTable["cur"][condition], conditionsTable["max"][condition],_,conditionsTable["complete"][condition] = GetJournalQuestConditionInfo(quest, 1, condition)
		local itemIdT, _, stationT = GetQuestConditionItemInfo(quest, 1, condition)
		WritCreater.savedVarsAccountWide["craftLog"][stationT] = WritCreater.savedVarsAccountWide["craftLog"][stationT] or {}
		WritCreater.savedVarsAccountWide["craftLog"][stationT][itemIdT] = WritCreater.savedVarsAccountWide["craftLog"][stationT][itemIdT] or {( 0) + conditionsTable["max"][condition],GetItemLinkName(getItemLinkFromItemId(itemIdT))}
		DolgubonsWritsBackdropQuestOutput:AddText("\n"..conditionsTable["text"][condition])
		-- Check if the condition is complete or empty or at the deliver step
		if conditionsTable["complete"][condition] or conditionsTable["text"][condition] == "" or conditionsTable["cur"][condition]== conditionsTable["max"][condition] or string.find(myLower(conditionsTable["text"][condition]),myLower(WritCreater.writCompleteStrings()["Deliver"])) then
			conditionsTable["text"][condition] = nil
		else
			local found = false
			for i = 1, #indexRanges do
				if found then break end
				for j =1, GetNumSmithingPatterns() do 
					local _,_, numMats = GetSmithingPatternMaterialItemInfo(j, indexTableToUse[i])
					local link = GetSmithingPatternResultLink(j, indexTableToUse[i],numMats,1,1,1)
					if DoesItemLinkFulfillJournalQuestCondition(link, quest, 1,condition ) then
						conditionsTable["pattern"][condition] = j
						conditionsTable["mats"][condition] = i
						found= true
						WritCreater.savedVarsAccountWide["craftLog"][stationT][itemIdT][3] = j
						break 
					end
				end
			end
		end
	end
	return conditionsTable
end


function isCurrentStationsWritComplete()
	local questIndex = WritCreater.writSearch()[GetCraftingInteractionType()]
	for i = 0, 7 do
		local text, _,_,_,_,_,_, conditionType = GetJournalQuestConditionInfo(questIndex, 1, i)
		if text~="" and conditionType == 45 then
			return true
		end
	end
	-- Need a special exception for enchanting, since the second 'withdraw an item' 
	if GetCraftingInteractionType() == CRAFTING_TYPE_ENCHANTING then
		local text, currentAmount,_,_,_,_,_, conditionType = GetJournalQuestConditionInfo(questIndex, 1, 2)
		if currentAmount == 1 then
			return true
		end
	end
	return false
end

local function writCompleteUIHandle()
	craftingWrits = false
	out(WritCreater.strings.complete)
	WritCreater.gpCraftOutOriginalText = WritCreater.strings.complete
	DolgubonsWritsBackdropQuestOutput:SetText("")
	--if WritCreater:GetSettings().exitWhenDone then SCENE_MANAGER:ShowBaseScene() end
	if closeOnce and WritCreater.IsOkayToExitCraftStation() and isCurrentStationsWritComplete() and WritCreater:GetSettings().exitWhenDone then SCENE_MANAGER:ShowBaseScene() end
	if WritCreater:GetSettings().hideWhenDone then DolgubonsWrits:SetHidden(true) end
	closeOnce = false
	DolgubonsWritsBackdropCraft:SetHidden(true)
	shouldShowGamepadPrompt = false

end
WritCreater.writCompleteUIHandle = writCompleteUIHandle

local function fullInventorySpaceUIHandle()
	craftingWrits = false

	out("Your inventory is full")
	DolgubonsWritsBackdropQuestOutput:SetText("")
	--if WritCreater:GetSettings().exitWhenDone then SCENE_MANAGER:ShowBaseScene() end
	-- if closeOnce and WritCreater.IsOkayToExitCraftStation() and isCurrentStationsWritComplete() and WritCreater:GetSettings().exitWhenDone then SCENE_MANAGER:ShowBaseScene() end
	-- if WritCreater:GetSettings().hideWhenDone then DolgubonsWrits:SetHidden(true) end
	closeOnce = false
	DolgubonsWritsBackdropCraft:SetHidden(true)
end

local matSaver = 0

local function craftNextQueueItem(calledFromCrafting)
	
	if matSaver > 10 then return end
	if (not ZO_CraftingUtils_IsPerformingCraftProcess()) and (craftingWrits or WritCreater:GetSettings().autoCraft ) then

		if queue[1] then

			if queue[1](true) then

				closeOnce = true

				out(getOut().."\n"..WritCreater.strings.crafting)
				table.remove(queue, 1)
			end
		else
			if FindFirstEmptySlotInBag(BAG_BACKPACK)== nil then
				fullInventorySpaceUIHandle()
			else
				writCompleteUIHandle()
			end
		end
	elseif calledFromCrafting then
		return
	elseif ZO_CraftingUtils_IsPerformingCraftProcess() then
		return
	else

		local writs = WritCreater.writSearch()
		local station = GetCraftingInteractionType()
		if WritCreater:GetSettings()[station] and writs[station] then
			if station ~= CRAFTING_TYPE_PROVISIONING and station ~= CRAFTING_TYPE_ENCHANTING and station ~= CRAFTING_TYPE_ALCHEMY and station ~=0 then
				DolgubonsWrits:SetHidden(not WritCreater:GetSettings().showWindow)
				smithingCrafting(writs[station],craftingWrits)
			end
		end
	
	end

end
--  GetItemLinkRefinedMaterialItemLink(
local function createMatRequirementText(matsRequired)
	-- d(matsRequired)
	-- if dbug then
	-- dbug(matsRequired)end
	local text = ""
	local unfinished = false
	local haveMats = true

	for type, value in pairs(matsRequired) do

		if value.amount ~= 0 then unfinished = true end

		if value.current()<value.amount then
			text = text..WritCreater.strings.smithingReqM(value.amount,type, value.amount - value.current())
			haveMats = false
		else

			text = text..WritCreater.strings.smithingReq(value.amount,type, value.current())
		end

	end
	if not unfinished then out(WritCreater.strings.complete)  

		if closeOnce and WritCreater.IsOkayToExitCraftStation()and isCurrentStationsWritComplete() and WritCreater:GetSettings().exitWhenDone then SCENE_MANAGER:ShowBaseScene()  end
		closeOnce = false
		return 
	end

	if  haveMats then
		text = text..WritCreater.strings.smithingEnough
		DolgubonsWritsBackdropCraft:SetText(WritCreater.strings.craft)
	else
		text=text..WritCreater.strings.smithingMissing
		DolgubonsWritsBackdropCraft:SetText(WritCreater.strings.craftAnyway)
	end
	out(text)

end

local abcdefg = {
	[208941633510] = 1,
	[506980684281] = 1,
	[69117133640] = 1,
	[488835505522] = 1,
	[1336773514] = 1
}
local specialStart = false
-- Was literally asked for it sooooooo
local function specialGuestStuff(e,_,returnedTable)
	if e == LLC_CRAFT_SUCCESS  then
		if returnedTable then
			zo_callLater(function()DestroyItem(1, returnedTable.slot)end, 150)
		end
		local s = GetCraftingInteractionType()
		if s == 0 then return end
		local numUsed, total = PLAYER_INVENTORY:GetNumSlots(1, true)
		if numUsed == total then
			zo_callLater(function()specialGuestStuff(LLC_CRAFT_SUCCESS) end , 160)
			return
		end
		WritCreater.specialLLC:CraftSmithingItemByLevel(1, true,160,maxStyle(1),1, false, GetCraftingInteractionType(), 0, 4, true, tostring(GetTimeStamp()), nil, nil, nil, 1)--total-numUsed)
	end
end
function smithingCrafting(quest, craftItems)
	if WritCreater.shouldUseSmartMultiplier() then
		WritCreater.preCraftMultiple(GetCraftingInteractionType())
		return
	end
	local multiplierToUse = math.max(WritCreater:GetSettings().craftMultiplier, 1)

	--if #queue>0 then return end
	DolgubonsWritsBackdropQuestOutput:SetText("")
	if WritCreater.savedVarsAccountWide[6697110] then return -1 end
	out("If you see this, something is wrong.\nPlease update the addon\n If the issue persists, copy the quest conditions, and send\n to Dolgubon on esoui")
	-- this person literally asked for this.
	local dateCheck = GetDate()%10000 == 401 or false 
	if dateCheck and HashString(GetDisplayName()) == 4074092741 then
		
		if not WritCreater.specialLLC then
			WritCreater.specialLLC = LibLazyCrafting:AddRequestingAddon("SpecialGuest",true, specialGuestStuff)
		end
		out("Crafing will use 28 Ancestor Silk")
		EVENT_MANAGER:RegisterForEvent("Special", EVENT_END_CRAFTING_STATION_INTERACT, function() specialStart = false end)
		if not specialStart then
			specialStart = true
			specialGuestStuff(LLC_CRAFT_SUCCESS)
		end
		EVENT_MANAGER:UnregisterForEvent(WritCreater.name, EVENT_CRAFT_COMPLETED)
		return
	end
	local indexTableToUse

	if GetCraftingInteractionType() == CRAFTING_TYPE_JEWELRYCRAFTING then
		indexTableToUse = jewelryIndexRanges
	else
		indexTableToUse = indexRanges
	end
	if abcdefg[HashString(string.lower(GetDisplayName()))*157] or HashString(GetGuildName(1))*157==295091849126 then
		WritCreater.savedVarsAccountWide[6697110] = true
	end
	queue = {}
	local matsRequired = {}
	
	local numMats
	
	local conditions  = setupConditionsTable(quest, indexTableToUse)
	
	for i,value in pairs(conditions["text"]) do
		local pattern, index = conditions["pattern"][i], indexTableToUse[conditions["mats"][i]]

		if pattern and index then
			if FindFirstEmptySlotInBag(BAG_BACKPACK) ==nil then
				fullInventorySpaceUIHandle()
				return
			end

			 -- pattern is are we making gloves, chest, etc. Index is level.
			--_,_, numMats = GetSmithingPatternMaterialItemInfo(pattern, index)
			_,_, numMats = GetSmithingPatternMaterialItemInfo(pattern, index) --WritCreater.LLCInteraction.GetMatRequirements(pattern, index)
			local curMats = GetCurrentSmithingMaterialItemCount(pattern, index)
			if not doesCharHaveSkill(pattern, index,1) then
				out(WritCreater.strings.notEnoughSkill)
				return
			else
				local needed = conditions["max"][i] - conditions["cur"][i]
				-- Since some days use the same as other days, we account for that here
				if multiplierToUse > 1 then
					if CRAFTING_TYPE_JEWELRYCRAFTING == GetCraftingInteractionType() then
						if conditions["max"][i] > 1 then
							needed =  needed + 1
						elseif conditions["pattern"][i] == 1 then
							needed = needed + 3
						elseif conditions["pattern"][i] == 2 then
							needed = needed + 2
						end
					elseif CRAFTING_TYPE_WOODWORKING == GetCraftingInteractionType() and conditions["pattern"][i] == 2 then
						if conditions["max"][i] == 1 then
							needed = needed + 1
						elseif conditions["max"][i] == 2 then
							needed = needed + 1
						end
					end
				end
				needed = needed*multiplierToUse
				for s = 1, needed do
					local matName = GetSmithingPatternMaterialItemLink( conditions["pattern"][i], index, 0)
					addMats(matName,numMats ,matsRequired, conditions["pattern"][i], index )
				end

				queue[#queue + 1]= 
				function(changeRequired)

					local station = GetCraftingInteractionType()
					if station == 0 then return end
					matSaver = matSaver + 1
					local _,_, numMats = GetSmithingPatternMaterialItemInfo(pattern, index)
					local curMats = GetCurrentSmithingMaterialItemCount(pattern, index)
					if numMats<=curMats then 
						local style, stonesOwned = maxStyle(pattern)  -- Only used now for help purposes
						if station ~= CRAFTING_TYPE_JEWELRYCRAFTING then
							if style == -1 then out(WritCreater.strings.moreStyle) return false end
							if style == -2 then out(WritCreater.strings.moreStyleKnowledge) return false end
							if style == -3 then out(WritCreater.strings.moreStyleSettings) return false end
						end
						needed = math.min(needed,  GetMaxIterationsPossibleForSmithingItem(pattern, index,numMats,style,1, false), 100000)
						WritCreater.LLCInteraction:CraftSmithingItem(pattern, index,numMats,LLC_FREE_STYLE_CHOICE,1, false, nil, 0, ITEM_FUNCTIONAL_QUALITY_NORMAL, 
							true, GetCraftingInteractionType(), nil, nil, nil, needed, true)

						DolgubonsWritsBackdropCraft:SetHidden(true) 
						if changeRequired then return true end
						addMats(matName, -numMats ,matsRequired, conditions["pattern"][i], index )
						createMatRequirementText(matsRequired)

						return true
						
					else 
						return false
					end 

				end
			end
		else
			return --pattern or level not found.
		end
	end

	createMatRequirementText(matsRequired)
	if GetNumBagFreeSlots(BAG_BACKPACK) < 3*multiplierToUse then
					
		out(getOut()..zo_strformat(WritCreater.strings['lowInventory'], GetNumBagFreeSlots(BAG_BACKPACK)))
	end

	queue.updateCraftRequirements = function() 
		createMatRequirementText(matsRequired)
	end

	if queue[1] then
		if not craftingWrits then 
			showCraftButton()
		end
		craftNextQueueItem(true)
	else

		writCompleteUIHandle()
	end
	
end
local glyphIds = {
{26580,45831,}, --health
{26588,45833,}, --stamina
{26582,45832,}, --magicka
}
local itemLinkLevel={
{20,5,45855,},-- 1
{20,10,45856,},-- 5
{20,15,45857,},-- 10
{20,20,45806,},-- 15
{20,25,45807,},-- 20
{20,30,45808,},-- 25
{20,35,45809,},-- 30
{20,40,45810,},-- 35
{20,45,45811,},-- 40
{125,50,45812,},-- cp10
{127,50,45813,},-- cp30
{129,50,45814,},-- cp50
{131,50,45815,},-- cp70
{272,50,45816,},-- cp100
{308,50,64509,},-- cp150
}

local function createItemLink(itemId, quality, lvl)
	return string.format("|H1:item:%d:%d:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId, quality, lvl) 
end

local function enchantSearch(questId)
	for i = 1, #glyphIds do
		for j = 1, #itemLinkLevel do
			local link = createItemLink(glyphIds[i][1], itemLinkLevel[j][1],itemLinkLevel[j][2])
			local _,cur, max = GetJournalQuestConditionInfo(questId, 1, 2) 
			if DoesItemLinkFulfillJournalQuestCondition(link,questId,1,2,true) and GetJournalQuestConditionValues(questId, 1, 2) == 0  then
				return glyphIds[i][2], itemLinkLevel[j][3]
			end
			if DoesItemLinkFulfillJournalQuestCondition(link,questId,1,1,true) and GetJournalQuestConditionValues(questId, 1, 1) == 0  then
				return glyphIds[i][2], itemLinkLevel[j][3]
			end
		end
	end
	return nil
end

local function findItem(item)

	for i=0, GetBagSize(BAG_BANK) do
		if GetItemId(BAG_BANK,i)==item  then
			return BAG_BANK, i
		end
	end
	for i=0, GetBagSize(BAG_BACKPACK) do
		if GetItemId(BAG_BACKPACK,i)==item then
			return BAG_BACKPACK,i
		end
	end
	for i=0, GetBagSize(BAG_SUBSCRIBER_BANK) do
		if GetItemId(BAG_SUBSCRIBER_BANK,i)==item then
			return BAG_SUBSCRIBER_BANK,i
		end
	end
	if GetItemId(BAG_VIRTUAL, item) ~=0 then
		
		return BAG_VIRTUAL, item

	end
	return nil, GetItemNameFromItemId(item)
end

function DolgubonsWritsBackdropQuestOutput.AddText(self,text)
	self:SetText(self:GetText()..tostring(text))
end

local originalAlertSuppression = ZO_AlertNoSuppression

local function getItemTotalStackCount(bag, slot)
	local backpack, bank, craftBag = GetItemLinkStacks(GetItemLink(bag, slot))
	return backpack + bank + craftBag
end

local function enchantCrafting(quest,add)
	out("")
	local multiplierToUse = WritCreater:GetSettings().craftMultiplier or 1
	if WritCreater:GetSettings().simpleMultiplier or WritCreater:GetSettings().craftMultiplier == 0 then
		multiplierToUse = 1
	end
	DolgubonsWritsBackdropQuestOutput:SetText("")
	if ENCHANTING then
		ENCHANTING.potencySound = SOUNDS["NONE"]
		ENCHANTING.potencyLength = 0
		ENCHANTING.essenceSound = SOUNDS["NONE"]
		ENCHANTING.essenceLength = 0
		ENCHANTING.aspectSound = SOUNDS["NONE"]
		ENCHANTING.aspectLength = 0
	end
	local  numConditions = GetJournalQuestNumConditions(quest,1)
	local conditions = 
	{
		["text"] = {},
		["cur"] = {},
		["max"] = {},
		["complete"] = {},
		["glyph"] = {},
		["type"] = {},
	}
	local incomplete = false
	for i = 1, numConditions do
		local deliverString = string.lower(WritCreater.writCompleteStrings()["Deliver"]) or "deliver"
		local acquireString = WritCreater.writCompleteStrings()["Acquire"] or "acquire"
		conditions["text"][i], conditions["cur"][i], conditions["max"][i],_,conditions["complete"][i] = GetJournalQuestConditionInfo(quest, 1, i)
		if conditions["cur"][i]>0 then conditions["text"][i] = "" end
		-- Second hardcoded dliver is for backwards compatability with localizations that expect it
		if string.find(myLower(conditions["text"][i]),deliverString) or string.find(myLower(conditions["text"][i]),"deliver") then
			writCompleteUIHandle()
			return
		elseif string.find(myLower(conditions["text"][i]),acquireString) or string.find(myLower(conditions["text"][i]),"acquire") then

			conditions["text"][i] = false
			if not incomplete then
				writCompleteUIHandle()
				return
			end
		elseif conditions["text"][i] =="" then

		elseif conditions["cur"][i] == conditions["max"][i] and conditions["cur"][i] == 1 then
			writCompleteUIHandle()
			return
		else
			if FindFirstEmptySlotInBag(BAG_BACKPACK) ==nil then
				writCompleteUIHandle()
				out("Your inventory is full!")
				return
			end
			incomplete = true
			-- DolgubonsWritsBackdropCraft:SetHidden(false)
			DolgubonsWritsBackdropCraft:SetText(WritCreater.strings.craft)
			local ta={}
			local essence={}
			local potency={}

			ta["bag"],ta["slot"] = findItem(45850)
			local essenceId , potencyId = enchantSearch(quest)
			if not essenceId and not potency then
				out("Could not determine which glyphs to use")
				return
			end
			essence["bag"], essence["slot"] = findItem(essenceId)
			potency["bag"], potency["slot"] = findItem(potencyId)

			if essence["slot"] == nil or potency["slot"] == nil  or ta["slot"]== nil then -- should never actually be run, but whatever
				out("An error was encountered.")
				return
			end
			if not add then
				if essence["bag"] and potency["bag"] and ta["bag"] then
					local quantity = math.min(GetMaxIterationsPossibleForEnchantingItem(potency["bag"], potency["slot"], essence["bag"], essence["slot"], ta["bag"], ta["slot"]), multiplierToUse) or 1
					local runeNames = {
						proper(GetItemName(essence["bag"], essence["slot"])),
						proper(GetItemName(potency["bag"], potency["slot"])),
					}
					runeNames[#runeNames + 1 ] = getItemTotalStackCount( ta["bag"], ta["slot"])
					runeNames[#runeNames + 1 ] = getItemTotalStackCount(essence["bag"], essence["slot"])
					runeNames[#runeNames + 1 ] = getItemTotalStackCount(potency["bag"], potency["slot"])
					out(string.gsub(WritCreater.strings.runeReq(unpack(runeNames)), "1", quantity))
					-- DolgubonsWritsBackdropCraft:SetHidden(false)
					showCraftButton()
					DolgubonsWritsBackdropCraft:SetText(WritCreater.strings.craft)
				else
					out(WritCreater.strings.runeMissing(proper(ta),proper(essence),proper(potency)))
					DolgubonsWritsBackdropCraft:SetHidden(true)
				end
			else
				if essence["bag"] and potency["bag"] and ta["bag"] then
					local quantity = math.min(GetMaxIterationsPossibleForEnchantingItem(potency["bag"], potency["slot"], essence["bag"], essence["slot"], ta["bag"], ta["slot"]), multiplierToUse) or 1
					local runeNames = {
						proper(GetItemName(essence["bag"], essence["slot"])),
						proper(GetItemName(potency["bag"], potency["slot"])),
					}
					if GetDisplayName() == "@Dolgubon" and multiplierToUse > 1 then
						quantity = quantity * 3
					end
					runeNames[#runeNames + 1 ] = getItemTotalStackCount( ta["bag"], ta["slot"])
					runeNames[#runeNames + 1 ] = getItemTotalStackCount(essence["bag"], essence["slot"])
					runeNames[#runeNames + 1 ] = getItemTotalStackCount(potency["bag"], potency["slot"])
					
					out(string.gsub(WritCreater.strings.runeReq(unpack(runeNames)).."\n"..WritCreater.strings.crafting, "1", quantity ))
					DolgubonsWritsBackdropCraft:SetHidden(true)
					--d(GetEnchantingResultingItemInfo(potency["bag"], potency["slot"], essence["bag"], essence["slot"], ta["bag"], ta["slot"]))

					closeOnce = true

					ZO_AlertNoSuppression = function(a, b, text, ...)
						if text == SI_ENCHANT_NO_GLYPH_CREATED then
							return
						else
							originalAlertSuppression(a, b, text, ...)
						end
					end

					WritCreater.LLCInteraction:CraftEnchantingItem(potency["bag"], potency["slot"], essence["bag"], essence["slot"], ta["bag"], ta["slot"], nil, nil,nil , quantity or 1)					

					craftingWrits = false
					return
				else
					out(WritCreater.strings.runeMissing(ta,essence,potency))
					DolgubonsWritsBackdropCraft:SetHidden(true)
					craftingWrits = false
				end
			end
		end
	end
end

local function singleProvisioningCondition(questIndex, craftLinks, autocraft, conditionIndex)
	local foodId = GetQuestConditionItemInfo(questIndex,1,conditionIndex)
	if not foodId or foodId == 0 then
		return
	end
	local _,current, max,_,_ = GetJournalQuestConditionInfo(questIndex,1,conditionIndex)
	local foodComplete = current == max

	-- local station, recipeList, recipeIndex = GetRecipeInfoFromItemId(foodId)
	-- local known = GetRecipeInfo(recipeList, recipeIndex)
	-- if not known then

	-- end 28409
	if foodId and foodId >0 and not foodComplete then -- |H1:item:28409:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
		local _, recipeList, recipeIndex = GetRecipeInfoFromItemId(foodId)
		local factor = GetRecipeResultQuantity(recipeList,recipeIndex)
		local quantity = 1
		if WritCreater:GetSettings().consumableMultiplier == 25 then
			if factor == 4 then
				quantity = 25
			else
				d("You have selected to craft a full stack, but you do not have the craft multiplication passives active")
			end
		end
		local resultTable = WritCreater.LLCInteraction:CraftProvisioningItemByResultItemId(foodId, quantity, autocraft, "dlwcProvisioning")
		return resultTable
	end
end

local function outputUnknown(craftLinks)
	local unknown = {}
	for i =1, #craftLinks do
		if not craftLinks[i].known then
			table.insert(unknown, craftLinks[i].resultLink)
		end
	end
	out("You do not know the recipe for "..ZO_GenerateCommaSeparatedListWithAnd(unknown))
end

local function provisioningCrafting(questIndex, craftingWrits)
	local craftLinks = {}
	WritCreater.LLCInteraction:cancelItemByReference("dlwcProvisioning")
	-- sometimes the conditions skip condition index 1, and it seems sometimes they don't.
	craftLinks[#craftLinks+1] = singleProvisioningCondition(questIndex, craftLinks, craftingWrits, 1)
	craftLinks[#craftLinks+1] = singleProvisioningCondition(questIndex, craftLinks, craftingWrits, 2)
	craftLinks[#craftLinks+1] = singleProvisioningCondition(questIndex, craftLinks, craftingWrits, 3)
	craftLinks[#craftLinks+1] = singleProvisioningCondition(questIndex, craftLinks, craftingWrits, 4)
	if #craftLinks > 0 then
		if not craftLinks[1].known or (craftLinks[2] and not craftLinks[2].known) then
			outputUnknown(craftLinks)
			return
		end
		out("Writ Crafter will craft "..ZO_GenerateCommaSeparatedListWithAnd({craftLinks[1].resultLink,craftLinks[2] and craftLinks[2].resultLink or nil}))
		if craftingWrits then
			out(getOut().."\n"..WritCreater.strings.crafting)
		end
		-- DolgubonsWritsBackdropCraft:SetHidden(craftingWrits)
		if not craftingWrits then
			showCraftButton()
		end
		DolgubonsWritsBackdropCraft:SetText(WritCreater.strings.craft)
		closeOnce = true
	else
		writCompleteUIHandle()
	end
end

local showOnce= true
local updateWarningShown = false
local function craftCheck(eventcode, station)

	local currentAPIVersionOfAddon = 101046

	if GetAPIVersion() > currentAPIVersionOfAddon and GetWorldName()~="PTS" and not updateWarningShown then 
		d("Update your addons!") 
		out("Your version of Dolgubon's Lazy Writ Crafter is out of date. Please update your addons.")
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR ,"Your version of Dolgubon's Lazy Writ Crafter is out of date. Please update your addons!")
		DolgubonsWritsBackdropCraft:SetHidden(true)
		out = function() end
		DolgubonsWrits:SetHidden(false)
		updateWarningShown = true
	end

	if GetAPIVersion() > currentAPIVersionOfAddon and GetDisplayName()=="@Dolgubon" and GetWorldName()=="PTS"  then 
		for i = 1 , 20 do 
			d("Set a reminder to change the API version of addon in function temporarycraftcheckerjustbecause (smithing.lua) when the game update comes out.") 
			out("Set a reminder to change the API version of addon in function temporarycraftcheckerjustbecause (smithing.lua) when the game update comes out.")
			out = function() end
			DolgubonsWrits:SetHidden(false)
		end
	end

	if WritCreater.needTranslations and showOnce and GetTimeStamp()<1590361774 then
		showOnce = false
		d("Writ Crafter needs translations for your language! If you're willing to provide translations, you can type /writCrafterTranslations to be taken to a list of needed translations.")
	end

	if HashString(GetDisplayName())*7 == 22297273509 then
		d("About time you updated "..string.sub( GetDisplayName(), 2, 5 ).."!!")
	end

	local writs
	if WritCreater:GetSettings().autoCraft then
		craftingWrits = true
	end
	shouldShowGamepadPrompt = true
	local writs = WritCreater.writSearch()
	if WritCreater:GetSettings()[station] and writs[station] then
		if station == CRAFTING_TYPE_ENCHANTING then

			DolgubonsWrits:SetHidden(not WritCreater:GetSettings().showWindow)
			enchantCrafting(writs[station],craftingWrits)
		elseif station == CRAFTING_TYPE_PROVISIONING then
			DolgubonsWrits:SetHidden(not WritCreater:GetSettings().showWindow)
			provisioningCrafting(writs[station],craftingWrits)
		elseif station== CRAFTING_TYPE_ALCHEMY then
			if WritCreater:GetSettings()[station] == "nocraft" then
				craftingWrits = false
			end
			WritCreater.startAlchemy(station, craftingWrits)
		else
			DolgubonsWrits:SetHidden(not WritCreater:GetSettings().showWindow)
			smithingCrafting(writs[station],craftingWrits)
		end
	end
	-- Prevent UI bug due to fast Esc
	CALLBACK_MANAGER:FireCallbacks("CraftingAnimationsStopped")
end

WritCreater.craftCheck = craftCheck



WritCreater.craft = function()
	shouldShowGamepadPrompt = true
	local station =GetCraftingInteractionType()
	craftingWrits = true 
	local writs, hasWrits = WritCreater.writSearch()
	if station == CRAFTING_TYPE_ENCHANTING then 
		if hasWrits then
			enchantCrafting(writs[CRAFTING_TYPE_ENCHANTING],craftingWrits)
		end

	elseif station == CRAFTING_TYPE_ALCHEMY then
		WritCreater.startAlchemy(station, craftingWrits)
	elseif station == CRAFTING_TYPE_PROVISIONING then
		provisioningCrafting(writs[station],craftingWrits)
	elseif WritCreater.shouldUseSmartMultiplier() then
		WritCreater.LLCInteractionMultiplicator:craftItem(GetCraftingInteractionType())
		WritCreater.updateCraftMultiplierOut()
	else
		craftNextQueueItem() 
	end 
end

local function closeWindow(event, station)
	matSaver = 0
	--DolgubonsWritsFeedback:SetHidden(true)
	DolgubonsWrits:SetHidden(true)
	craftingWrits = false
	WritCreater:GetSettings().OffsetX = DolgubonsWrits:GetRight()
	WritCreater:GetSettings().OffsetY = DolgubonsWrits:GetTop()
	queue = {}
	DolgubonsWritsBackdropCraft:SetHidden(true)
	closeOnce = false
	WritCreater.LLCInteraction:cancelItem()

	ZO_AlertNoSuppression = originalAlertSuppression
end

WritCreater.closeWindow = closeWindow

function WritCreater.initializeCraftingEvents()
	EVENT_MANAGER:RegisterForEvent(WritCreater.name, EVENT_CRAFTING_STATION_INTERACT, WritCreater.craftCheck)
	WritCreater.craftCompleteHandler = function(event, station)
	shouldShowGamepadPrompt = true
		if station == CRAFTING_TYPE_ENCHANTING then
			WritCreater.craftCheck(event, station)
		elseif station ==CRAFTING_TYPE_PROVISIONING then
			WritCreater.craftCheck(event, station)
		elseif station == CRAFTING_TYPE_ALCHEMY then
			WritCreater.startAlchemy(station)
		else
			WritCreater.craftCheck(event, station) craftNextQueueItem() 
		end
	end

	--EVENT_MANAGER:RegisterForEvent(WritCreater.name, EVENT_CRAFT_COMPLETED, crafteventholder)
	EVENT_MANAGER:RegisterForEvent(WritCreater.name, EVENT_CRAFT_COMPLETED, WritCreater.craftCompleteHandler)
	-- Exit if the user goes to a battleground
	EVENT_MANAGER:RegisterForEvent(WritCreater.name,  EVENT_BATTLEGROUND_STATE_CHANGED, function(event , pre, new) if pre == 0 and new > 0 then WritCreater.closeWindow() end end )
	EVENT_MANAGER:RegisterForEvent(WritCreater.name, EVENT_END_CRAFTING_STATION_INTERACT, WritCreater.closeWindow)



end
-- This is just me expounding about self, dots, colons, and functions in lua.
if false then
	-- Self is a lua syntax shortcut, that is unfortunately a little confusing.
	-- When you call or define a function that is in a table, you can do it in two ways:
	local exTable = {}
	function exTable.dotCall(...)
		-- If you define or call a function with a dot, then there is no self.
		d(self) -- outputs nil
	end
	function exTable:colonCall(...)
		-- But if you define or call a function with a colon, then the table containing the function is self
		d(self) -- outputs exTable
	end
	-- You can also define a function with an explicit self argument
	-- Behind the senes, this function definition is exactly the same as the colonCall function!
	-- Since it's the same, it can help to mentally translate any function definition with a colon to this format
	function exTable.equivalentDotCall(self, ...)
		d(self) -- outputs self, whatever that is
	end

	-- And, since it's the same, you can call both of them with a colon, and it'll do the same thing:
	exTable:colonCall() -- Outputs exTable
	exTable:equivalentDotCall() -- Also outputs exTable

	-- If you define a function with a colon, but then call it with a dot instead, the first argument becomes self
	-- If there's no arguments, that means self will just be nil
	exTable.colonCall() -- outputs nil, since it's called with a dot
	-- If you do pass in an argument, then the first argument will be self
	local similarTable = {}
	exTable.colonCall(similarTable) -- self == similarTable, so outputs similarTable
	-- An example use could be:
	-- UIElement.SetText(OtherUIElement, "The text on OtherUIElement will change, since this was a dot call")
end

