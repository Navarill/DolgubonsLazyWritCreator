local hirelingMailSubjects = WritCreater.hirelingMailSubjects

local hirelingMails = 
{}

local currentWorkingMail
local function lootMails()
	if #hirelingMails == 0 then
		-- CloseMailbox()
		d("Writ Crafter: Mail Looting complete")
		return
	else
		local mailId = hirelingMails[1]
		-- d(mailId)
		currentWorkingMail = mailId
		local requestResult = RequestReadMail(mailId)
		if requestResult and requestResult <= REQUEST_READ_MAIL_RESULT_SUCCESS_SERVER_REQUESTED then
		end
		zo_callLater(function()

				if currentWorkingMail == mailId and not IsReadMailInfoReady(mailId) then
					RequestReadMail(mailId)
				end 
			end, math.max(GetLatency()+10, 100))
	end
end

local function  findLootableMails()
	if not WritCreater:GetSettings().mail.loot then
		return
	end
	hirelingMails = {}
	local nextMail = GetNextMailId(nil)
	if not nextMail then
	 	-- CloseMailbox()
	 	-- d("No mails found")
	 	EVENT_MANAGER:UnregisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_READABLE)
	 	return
	end
	
	while nextMail do
		local  _,_,subject, _,_,system,customer, _, numAtt, money = GetMailItemInfo (nextMail)
		if not customer and money == 0 and system and hirelingMailSubjects[subject] then
			if WritCreater:GetSettings().mail.delete or numAtt > 0 then
			-- if #hirelingMails < 3 then
				-- hirelingMails[nextMail] = true
				table.insert(hirelingMails,  nextMail)
			end
			-- end
			-- DeleteMail(mailId, true)
		end
		nextMail = GetNextMailId(nextMail)
	end

	if #hirelingMails > 0 then
		d("Writ Crafter: "..#hirelingMails.. " hireling mails found")
		zo_callLater(lootMails, 10)
	else
		EVENT_MANAGER:UnregisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_READABLE)
		-- d("No hireling mails found")
	end
end
local lootReadMail
local function deleteLootedMail(mailId)
	local  _,_,subject, _,_,system,customer, _, numAtt, money = GetMailItemInfo(mailId)
	if (numAtt > GetNumBagFreeSlots(1)) then
		return
	end
	if (numAtt <= GetNumBagFreeSlots(1) or IsESOPlusSubscriber()) and numAtt>0 then
		-- d("Tried deleting but still attachments")
		lootReadMail(1, mailId)
		return
	end
	if WritCreater:GetSettings().mail.delete and numAtt == 0 then
		DeleteMail(mailId, true)
	end

	if hirelingMails[1] == mailId then
		table.remove(hirelingMails, 1)
		zo_callLater(lootMails, 250)
	end
	-- table.remove(hirelingMails, mailId)
	-- zo_callLater(lootMails, 40)
end

local antiKick = 0
function lootReadMail(event, mailId)
	if not IsReadMailInfoReady(mailId) and (FindFirstEmptySlotInBag(BAG_BACKPACK) or IsESOPlusSubscriber()) then
		-- d("Stop")
		zo_callLater(function() lootMails() end , 10 )
		return
	end
	local  _,_,subject, _,_,system,customer, _, numAtt, money = GetMailItemInfo(mailId)
	if not customer and money == 0 and system and hirelingMailSubjects[subject] then
		if antiKick>40 then
			antiKick = 0
			-- hopefully helps prevent kicks from server
			-- reset so if they go back in they can loot again
			return
		end
		if numAtt > 0 and (FindFirstEmptySlotInBag(BAG_BACKPACK) or IsESOPlusSubscriber()) then
			-- d("Writ Crafter: Looting "..subject)
			antiKick = antiKick + 1
			ZO_MailInboxShared_TakeAll(mailId)
			zo_callLater(function() deleteLootedMail(mailId) end, 250)
			return
		elseif FindFirstEmptySlotInBag(BAG_BACKPACK) == nil and numAtt > 0 then
			return
		else
			-- d("Mail empty. Delete it")
			deleteLootedMail(mailId)
			return
		end
	end
end


function WritCreater.lootHireling(event)
	-- d("BEGIN the bugs!")
	EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox",EVENT_MAIL_REMOVED, function(event, mailId)if hirelingMails[1] == mailId then
		table.remove(hirelingMails, 1)
		if #hirelingMails == 0 then
			-- d("COMPLETETIONS")
		else
			lootMails()
		end
	end
	end)
	EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox",EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, function(event, mailId) 
		local toremove
		for k, v in pairs(hirelingMails) do 
			if v == mailId then 
				local _,_,sub = GetMailItemInfo(mailId)
				-- d("Writ Crafter: "..sub.." looted")
				if not WritCreater:GetSettings().mail.delete then
					table.remove(hirelingMails, k)
					break
				end
			end 
		end 
	end )
	-- EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_OPEN_MAILBOX, 
	-- 	function ()
	-- 	EVENT_MANAGER:UnregisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_OPEN_MAILBOX)
	-- 		zo_callLater(function ()
	-- 			findLootableMails()
	-- 		end, 10)
	-- 	end)
	if WritCreater:GetSettings().mail.loot then
		findLootableMails()
		EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_READABLE, lootReadMail)
	end
end
EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox",EVENT_MAIL_OPEN_MAILBOX , function() WritCreater.lootHireling() end)

function WritCreater.triggerMailLooting()
	CloseMailbox()
	RequestOpenMailbox()
end

SLASH_COMMANDS['/testmail'] = WritCreater.triggerMailLooting
--EVENT_MAIL_INBOX_UPDATE

