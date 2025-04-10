-----------------------------------------------------------------------------------
-- Addon Name: Dolgubon's Lazy Writ Crafter
-- Creator: Dolgubon (Joseph Heinzle)
-- Addon Ideal: Simplifies Crafting Writs as much as possible
-- Addon Creation Date: March 14, 2016
--
-- File Name: AlchGrab.lua
-- File Description: This file removes items required for writs from the bank
-- Load Order Requirements: None
-- 
-----------------------------------------------------------------------------------


WritCreater = WritCreater or {}


WritCreater.settings["panel"] =  
{
     type = "panel",
     name = "Lazy Writ Crafter",
     registerForRefresh = true,
     displayName = "|c8080FF Dolgubon's Lazy Writ Crafter|r",
     author = "@Dolgubon",
     registerForRefresh = true,
     registerForDefaults = true,
     resetFunction = WritCreater.resetSettings,
     donation = "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7CZ3LW6E66NAU"

}


local function z(eventType, addonName)
    
    local LibHarvensAddonSettings = LibHarvensAddonSettings
    
    local options = {
        allowDefaults = true, --will allow users to reset the settings to default values
        allowRefresh = true, --if this is true, when one of settings is changed, all other settings will be checked for state change (disable/enable)
        defaultsFunction = function() --this function is called when allowDefaults is true and user hit the reset button
            d("Reset")
        end,
    }
    --Create settings "container" for your addon
    --First parameter is the name that will be displayed in the options,
    --Second parameter is the options table (it is optional)
    local settings = LibHarvensAddonSettings:AddAddon("Settings Examples", options)
    if not settings then
        return
    end
 
    local areSettingsDisabled = false

end

function WritCreater.initializeSettingsMenu()
    local LHA = LibHarvensAddonSettings
    local options = {
        allowDefaults = true, --will allow users to reset the settings to default values
        allowRefresh = true, --if this is true, when one of settings is changed, all other settings will be checked for state change (disable/enable)
        defaultsFunction = function() --this function is called when allowDefaults is true and user hit the reset button
            d("Reset")
        end,
    }

    local settings = LHA:AddAddon("|c8080FF Dolgubon's Lazy Writ Crafter|r", options)
    if not settings then
        return
    end
local areSettingsDisabled = false
 
    --[[
        CHECKBOX
    --]]
    local checked = false

    local options =  {
        {
            type = LHA.ST_LABEL,
            label = function() 
                local profile = WritCreater.optionStrings.accountWide
                if WritCreater.savedVars.useCharacterSettings then
                    profile = WritCreater.optionStrings.characterSpecific
                end
                return  string.format(WritCreater.optionStrings.nowEditing, profile)  
            end, 
        },

        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings.useCharacterSettings,
            tooltip = WritCreater.optionStrings.useCharacterSettingsTooltip,
            getFunction = function() return WritCreater.savedVars.useCharacterSettings end,
            setFunction = function(value) 
                WritCreater.savedVars.useCharacterSettings = value
            end,
        },
        -- {
        --     type = "divider",
        --     height = 15,
        --     alpha = 0.5,
        --     width = "full",
        -- },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["autocraft"]  ,
            tooltip = WritCreater.optionStrings["autocraft tooltip"] ,
            getFunction = function() return WritCreater:GetSettings().autoCraft end,
            disabled = function() return not WritCreater:GetSettings().showWindow end,
            setFunction = function(value) 
                WritCreater:GetSettings().autoCraft = value 
            end,
        },
        
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['stealingProtection'], 
            getFunction = function() return WritCreater:GetSettings().stealProtection end,
            setFunction = function(value) WritCreater:GetSettings().stealProtection = value end,
            tooltip = WritCreater.optionStrings['stealingProtectionTooltip'], 
        } ,
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['suppressQuestAnnouncements'], 
            getFunction = function() return WritCreater:GetSettings().suppressQuestAnnouncements end,
            setFunction = function(value) WritCreater:GetSettings().suppressQuestAnnouncements = value end,
            tooltip = WritCreater.optionStrings['suppressQuestAnnouncementsTooltip'], 
        } ,
        {
            type =  LibHarvensAddonSettings.ST_DROPDOWN,
            label = WritCreater.optionStrings['dailyResetWarnType'],
            tooltip = WritCreater.optionStrings['dailyResetWarnTypeTooltip'],
            choices = WritCreater.optionStrings["dailyResetWarnTypeChoices"],
            choicesValues =  IsConsoleUI() and {"none","announcement","alert","chat","all"} or {"none","announcement","alert","chat","window","all"},
            items = {
                {
                    name = WritCreater.optionStrings["dailyResetWarnTypeChoices"][1],
                    data = "None",
                },
                {
                    name = WritCreater.optionStrings["dailyResetWarnTypeChoices"][2],
                    data = "Announcement",
                },
                {
                    name = WritCreater.optionStrings["dailyResetWarnTypeChoices"][3],
                    data = "Alert",
                },
                {
                    name = WritCreater.optionStrings["dailyResetWarnTypeChoices"][4],
                    data = "Chat",
                },
            },
            getFunction = function() return WritCreater:GetSettings().dailyResetWarnType end,
            setFunction = function(combobox, name, item) 
                WritCreater:GetSettings().dailyResetWarnType = item.data 
                WritCreater.showDailyResetWarnings("Example") -- Show the example warnings
            end
        },
        {
            type = LibHarvensAddonSettings.ST_SLIDER,
            label = WritCreater.optionStrings['dailyResetWarnTime'], 
            getFunction = function() return WritCreater:GetSettings().dailyResetWarnTime end,
            setFunction = function(value) WritCreater:GetSettings().dailyResetWarnTime = math.max(0,value) WritCreater.refreshWarning() end,
            min = 0,
            max = 300,
            step = 1, 
            unit = "m",
            tooltip = WritCreater.optionStrings['dailyResetWarnTimeTooltip'], 
            requiresReload = false, 
        } ,
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["master"].." (Unsupported, use Writ Worthy)",
            tooltip = WritCreater.optionStrings["master tooltip"],
            getFunction = function() return WritCreater.savedVarsAccountWide.masterWrits end,
            setFunction = function(value) 
            WritCreater.savedVarsAccountWide.masterWrits = value
            if LibCustomMenu or WritCreater.savedVarsAccountWide.rightClick then
                WritCreater.savedVarsAccountWide.rightClick = not value
            end
            WritCreater.LLCInteraction:cancelItem()
                if value  then
                    
                    for i = 1, 25 do WritCreater.MasterWritsQuestAdded(1, i,GetJournalQuestName(i)) end
                end
                
                
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["right click to craft"],
            tooltip = WritCreater.optionStrings["right click to craft tooltip"],
            getFunction = function() return WritCreater.savedVarsAccountWide.rightClick end,
            disabled = not LibCustomMenu or WritCreater.savedVarsAccountWide.rightClick,
            warning = "This option requires LibCustomMenu",
            setFunction = function(value) 
            WritCreater.savedVarsAccountWide.masterWrits = not value
            WritCreater.savedVarsAccountWide.rightClick = value
            WritCreater.LLCInteraction:cancelItem()
                if not value  then
                    
                    for i = 1, 25 do WritCreater.MasterWritsQuestAdded(1, i,GetJournalQuestName(i)) end
                end
            end,
        },
    }
    choicelabel = settings:AddSetting(options[1])
    for i = 1, #options do
        settings:AddSetting(options[i])
    end

end