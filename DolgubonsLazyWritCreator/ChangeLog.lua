local changelog = {
	{4030,
[[Changelog window
 - You're looking at it! It will be used primarily to communicate new features and important bugfixes
Improved Craft Multiplier
 - Will now craft for a full cycle of writs when you interact with a station (equipable gear only for now)
 - Checks the current contents of your bag, and crafts up to x amount of each item. e.g., if you have a multiplier of 3, and currently have 1 sword, it will craft two swords
 - If you want the old behaviour, you can turn the smart multiplier off in the settings menu
]],
[[
QR codes for settings links (Console only)
 - Will pop up a QR code for you to scan, for example if you want to go to the forum thread for posting bugs
 - LibQRCode added as a dependency to facilitate this behaviour
]]

}
}

local welcomeMessage = "Thanks for installing Dolgubon's Lazy Writ Crafter! Please check out the settings to customize the behaviour of the addon"

local function displayText(text)
	WritCreater.initializeResetWarnerScene()
	DolgubonsLazyWritChangelogBackdropOutput:SetText(text)
	SCENE_MANAGER:Show("dlwcannouncer")
end

function WritCreater.displayChangelog()
	-- if WritCreater.savedVarsAccountWide.initialInstall then
	-- 	WritCreater.savedVarsAccountWide.initialInstall = false
	-- 	displayText(welcomeMessage)
	-- 	if GetDisplayName() == "@Dolgubon" then
	-- 		return
	-- 	end
	-- 	for i = 1, #changelog do
	-- 		WritCreater.savedVarsAccountWide.viewedChangelogs[changelog[i][1]] = true
	-- 	end
	-- 	return
	-- end
	WritCreater.savedVarsAccountWide.initialInstall = false
	for i = 1, #changelog do
		if not WritCreater.savedVarsAccountWide.viewedChangelogs[changelog[i][1]] then
			WritCreater.savedVarsAccountWide.viewedChangelogs[changelog[i][1]] = true
			local text = changelog[i][2]
			if IsConsoleUI() then
				text = text..changelog[i][3]
			end 
			displayText(text)
			return
		end
	end
	-- WritCreater.expectedVersion
end

if GetDisplayName() == "@Dolgubon" then
	SLASH_COMMANDS['/resetchangelog'] = function() WritCreater.savedVarsAccountWide.viewedChangelogs = {} WritCreater.savedVarsAccountWide.initialInstall = true WritCreater.displayChangelog() end
end

function WritCreater.initializeResetWarnerScene()
	if WritCreater.announcementScreen then return end
	local announcementScreen = ZO_Scene:New("dlwcannouncer", SCENE_MANAGER)
	WritCreater.announcementScreen = announcementScreen
	WritCreater.announcementScreen:AddFragment(ZO_SimpleSceneFragment:New(DolgubonsLazyWritChangelog))
end