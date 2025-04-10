-----------------------------------------------------------------------------------
-- Addon label: Dolgubon's Lazy Writ Crafter
-- Creator: Dolgubon (Joseph Heinzle)
-- Addon Ideal: Simplifies Crafting Writs as much as possible
-- Addon Creation Date: March 14, 2016
--
-- File label: AlchGrab.lua
-- File Description: This file removes items required for writs from the bank
-- Load Order Requirements: None
-- 
-----------------------------------------------------------------------------------


WritCreater = WritCreater or {}


WritCreater.settings["panel"] =  
{
     type = "panel",
     label = "Lazy Writ Crafter",
     registerForRefresh = true,
     displaylabel = "|c8080FF Dolgubon's Lazy Writ Crafter|r",
     author = "@Dolgubon",
     registerForRefresh = true,
     registerForDefaults = true,
     resetFunction = WritCreater.resetSettings,
     donation = "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7CZ3LW6E66NAU"

}


local function z(eventType, addonlabel)
    
    local LibHarvensAddonSettings = LibHarvensAddonSettings
    
    local options = {
        allowDefaults = true, --will allow users to reset the settings to default values
        allowRefresh = true, --if this is true, when one of settings is changed, all other settings will be checked for state change (disable/enable)
        defaultsFunction = function() --this function is called when allowDefaults is true and user hit the reset button
            d("Reset")
        end,
    }
    --Create settings "container" for your addon
    --First parameter is the label that will be displayed in the options,
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
    WritCreater.consoleSettingsMenu = settings
    local areSettingsDisabled = false
 
    --[[
        CHECKBOX
    --]]
    local checked = false
    -- Long, so that hopefully the various hide callLaters won't overlap
    local statusBarSampleTimeout = 20000

    local options =  {
        {
            type = LHA.ST_SECTION,
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
                WritCreater.consoleSettingsMenu:UpdateControls()
            end,
        },
        {
            type = LHA.ST_SECTION,
            label = "Main Settings", 
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
            disable = function() return not WritCreater:GetSettings().showWindow end,
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
            choicesValues = {"none","announcement","alert","chat","all"},
            items = {
                {
                    name = WritCreater.optionStrings["dailyResetWarnTypeChoices"][1],
                    data = "none",
                },
                {
                    name = WritCreater.optionStrings["dailyResetWarnTypeChoices"][2],
                    data = "announcement",
                },
                {
                    name = WritCreater.optionStrings["dailyResetWarnTypeChoices"][3],
                    data = "alert",
                },
                {
                    name = WritCreater.optionStrings["dailyResetWarnTypeChoices"][4],
                    data = "chat",
                },
            },
            getFunction = function()
                -- Do I like this? No. Is it a simple and fast way? Yes.
                local labelMap = 
                {
                    ["none"] = WritCreater.optionStrings["dailyResetWarnTypeChoices"][1],
                    ["announcement"] = WritCreater.optionStrings["dailyResetWarnTypeChoices"][2],
                    ["alert"] = WritCreater.optionStrings["dailyResetWarnTypeChoices"][3],
                    ["chat"] = WritCreater.optionStrings["dailyResetWarnTypeChoices"][4],
                }

                return labelMap[WritCreater:GetSettings().dailyResetWarnType] end,
            setFunction = function(combobox, label, item)
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
                    
                    for i = 1, 25 do WritCreater.MasterWritsQuestAdded(1, i,GetJournalQuestlabel(i)) end
                end
                
                
            end,
        },
        -- {
        --     type = LHA.ST_CHECKBOX,
        --     label = WritCreater.optionStrings["right click to craft"],
        --     tooltip = WritCreater.optionStrings["right click to craft tooltip"],
        --     getFunction = function() return WritCreater.savedVarsAccountWide.rightClick end,
        --     disable = not LibCustomMenu or WritCreater.savedVarsAccountWide.rightClick,
        --     warning = "This option requires LibCustomMenu",
        --     setFunction = function(value) 
        --     WritCreater.savedVarsAccountWide.masterWrits = not value
        --     WritCreater.savedVarsAccountWide.rightClick = value
        --     WritCreater.LLCInteraction:cancelItem()
        --         if not value  then
                    
        --             for i = 1, 25 do WritCreater.MasterWritsQuestAdded(1, i,GetJournalQuestlabel(i)) end
        --         end
        --     end,
        -- },
        {
            type = LHA.ST_SECTION,
            label = WritCreater.optionStrings["timesavers submenu"],
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["automatic complete"],
            tooltip = WritCreater.optionStrings["automatic complete tooltip"],
            getFunction = function() return WritCreater:GetSettings().autoAccept end,
            setFunction = function(value) WritCreater:GetSettings().autoAccept = value end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['autoCloseBank'],
            tooltip = WritCreater.optionStrings['autoCloseBankTooltip'],
            getFunction = function() return  WritCreater:GetSettings().autoCloseBank end,
            setFunction = function(value) 
                WritCreater:GetSettings().autoCloseBank = value
                if not value then
                    EVENT_MANAGER:RegisterForEvent(WritCreater.label, EVENT_OPEN_BANK, WritCreater.alchGrab)
                else
                    EVENT_MANAGER:UnregisterForEvent(WritCreater.label)
                end
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['despawnBanker'],
            tooltip = WritCreater.optionStrings['despawnBankerTooltip'],
            getFunction = function() return  WritCreater:GetSettings().despawnBanker end,
            setFunction = function(value) 
                WritCreater:GetSettings().despawnBanker = value
            end,
            disable = function() return not WritCreater:GetSettings().autoCloseBank end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['despawnBankerDeposit'],
            tooltip = WritCreater.optionStrings['despawnBankerDepositTooltip'],
            getFunction = function() return  WritCreater:GetSettings().despawnBankerDeposits end,
            setFunction = function(value) 
                WritCreater:GetSettings().despawnBankerDeposits = value
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["exit when done"],
            tooltip = WritCreater.optionStrings["exit when done tooltip"],
            getFunction = function() return WritCreater:GetSettings().exitWhenDone end,
            setFunction = function(value) WritCreater:GetSettings().exitWhenDone = value end,
        },
        {
            type = "dropdown",
            label = WritCreater.optionStrings["autoloot behaviour"]  ,
            tooltip = WritCreater.optionStrings["autoloot behaviour tooltip"],
            choices = WritCreater.optionStrings["autoloot behaviour choices"],
            choicesValues = {1,2,3},
            getFunction = function() if not WritCreater:GetSettings().ignoreAuto then return 1 elseif WritCreater:GetSettings().autoLoot then return 2 else return 3 end end,
            setFunction = function(value) 
                if value == 1 then 
                    WritCreater:GetSettings().ignoreAuto = false
                elseif value == 2 then  
                    WritCreater:GetSettings().autoLoot = true
                    WritCreater:GetSettings().ignoreAuto = true
                elseif value == 3 then
                    WritCreater:GetSettings().ignoreAuto = true
                    WritCreater:GetSettings().autoLoot = false
                    WritCreater:GetSettings().lootContainerOnReceipt  = false
                end
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["loot container"],
            tooltip = WritCreater.optionStrings["loot container tooltip"],
            disable = function() return not WritCreater:GetSettings().autoLoot end,
            getFunction = function() 
                if not WritCreater:GetSettings().autoLoot then
                    WritCreater:GetSettings().lootContainerOnReceipt  = false
                end
                return WritCreater:GetSettings().lootContainerOnReceipt 
            end,
            setFunction = function(value) 
            WritCreater:GetSettings().lootContainerOnReceipt = value                    
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["new container"],
            tooltip = WritCreater.optionStrings["new container tooltip"],
            getFunction = function() return WritCreater:GetSettings().keepNewContainer end,
            setFunction = function(value) 
            WritCreater:GetSettings().keepNewContainer = value          
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["master writ saver"],
            tooltip = WritCreater.optionStrings["master writ saver tooltip"],
            getFunction = function() return WritCreater:GetSettings().preventMasterWritAccept end,
            setFunction = function(value) 
            WritCreater:GetSettings().preventMasterWritAccept = value                   
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["loot output"],
            tooltip = WritCreater.optionStrings["loot output tooltip"],
            getFunction = function() return WritCreater:GetSettings().lootOutput end,
            setFunction = function(value) 
            WritCreater:GetSettings().lootOutput = value                    
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['reticleColour'],
            tooltip = WritCreater.optionStrings['reticleColourTooltip'],
            getFunction = function() return  WritCreater:GetSettings().changeReticle end,
            setFunction = function(value) 
                WritCreater:GetSettings().changeReticle = value
            end,
        },
        -- {
        --     type = LHA.ST_CHECKBOX,
        --     label = WritCreater.optionStrings['noDELETEConfirmJewelry'],
        --     tooltip = WritCreater.optionStrings['noDELETEConfirmJewelryTooltip'],
        --     getFunction = function() return  WritCreater:GetSettings().EZJewelryDestroy end,
        --     setFunction = function(value) 
        --         WritCreater:GetSettings().EZJewelryDestroy = value
        --     end,
        -- },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['questBuffer'],
            tooltip = WritCreater.optionStrings['questBufferTooltip'],
            getFunction = function() return  WritCreater:GetSettings().keepQuestBuffer end,
            setFunction = function(value) 
                WritCreater:GetSettings().keepQuestBuffer = value
            end,
        },
        {
            type = LibHarvensAddonSettings.ST_SLIDER,
            label = WritCreater.optionStrings['craftMultiplier'],
            tooltip = WritCreater.optionStrings['craftMultiplierTooltip'],
            min = 1,
            max = 8,
            step = 1,
            getFunction = function() return  WritCreater:GetSettings().craftMultiplier end,
            setFunction = function(value) 
                WritCreater:GetSettings().craftMultiplier = value
            end,
        },
        {
            type = "dropdown",
            label = WritCreater.optionStrings["hireling behaviour"]  ,
            tooltip = WritCreater.optionStrings["hireling behaviour tooltip"],
            choices = WritCreater.optionStrings["hireling behaviour choices"],
            choicesValues = {1,2,3},
            getFunction = function() if WritCreater:GetSettings().mail.delete then return 2 elseif WritCreater:GetSettings().mail.loot then return 3 else return 1 end end,
            setFunction = function(value) 
                if value == 1 then 
                    WritCreater:GetSettings().mail.delete = false
                    WritCreater:GetSettings().mail.loot = false
                elseif value == 2 then  
                    WritCreater:GetSettings().mail.delete = true
                    WritCreater:GetSettings().mail.loot = true
                elseif value == 3 then
                    WritCreater:GetSettings().mail.delete = false
                    WritCreater:GetSettings().mail.loot = true
                end
            end,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings["scan for unopened"],
            tooltip = WritCreater.optionStrings["scan for unopened tooltip"],
            getFunction = function() return  WritCreater:GetSettings().scanForUnopened end,
            setFunction = function(value) 
                WritCreater:GetSettings().scanForUnopened = value
            end,
        },
        {
            type = LHA.ST_SECTION,
            label = WritCreater.optionStrings["status bar submenu"],
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['showStatusBar'], 
            getFunction = function() return WritCreater:GetSettings().showStatusBar end,
            setFunction = function(value) 
                WritCreater:GetSettings().showStatusBar = value
                WritCreater.toggleQuestStatusWindow()
                zo_callLater(WritCreater.updateQuestStatus, statusBarSampleTimeout)
            end,
            tooltip = WritCreater.optionStrings['showStatusBarTooltip'], 
        } ,
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['statusBarInventory'], 
            getFunction = function() return WritCreater:GetSettings().statusBarInventory end,
            disable = function() return not WritCreater:GetSettings().showStatusBar end,
            setFunction = function(value) WritCreater:GetSettings().statusBarInventory = value
                WritCreater.updateQuestStatus()
                WritCreater.toggleQuestStatusWindow(false)
                zo_callLater(WritCreater.updateQuestStatus, statusBarSampleTimeout)
            end,
            tooltip = WritCreater.optionStrings['statusBarInventoryTooltip'], 
            default = WritCreater.default.statusBarIcons,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['statusBarIcons'], 
            getFunction = function() return WritCreater:GetSettings().statusBarIcons end,
            disable = function() return not WritCreater:GetSettings().showStatusBar end,
            setFunction = function(value) WritCreater:GetSettings().statusBarIcons = value
                WritCreater.updateQuestStatus()
                WritCreater.toggleQuestStatusWindow(false)
                zo_callLater(WritCreater.updateQuestStatus, statusBarSampleTimeout)
            end,
            tooltip = WritCreater.optionStrings['statusBarIconsTooltip'], 
            default = WritCreater.default.statusBarIcons,
        },
        {
            type = LHA.ST_CHECKBOX,
            label = WritCreater.optionStrings['transparentStatusBar'], 
            getFunction = function() return WritCreater:GetSettings().transparentStatusBar end,
            disable = function() return not WritCreater:GetSettings().showStatusBar end,
            setFunction = function(value) WritCreater:GetSettings().transparentStatusBar = value
                WritCreater.updateQuestStatus()
                WritCreater.toggleQuestStatusWindow(false)
                zo_callLater(WritCreater.updateQuestStatus, statusBarSampleTimeout)
            end,
            tooltip = WritCreater.optionStrings['transparentStatusBarTooltip'], 
            default = WritCreater.default.transparentStatusBar,
        } ,
        {
            type = LHA.ST_COLOR,
            label = WritCreater.optionStrings['incompleteColour'], 
            getFunction = function() return unpack(WritCreater:GetSettings().incompleteColour) end,
            disable = function() return not WritCreater:GetSettings().showStatusBar end,
            setFunction = function(...) WritCreater:GetSettings().incompleteColour = {...}
                WritCreater.updateQuestStatus()
                WritCreater.toggleQuestStatusWindow(false)
                zo_callLater(WritCreater.updateQuestStatus, statusBarSampleTimeout)
            end,
            default = WritCreater.default.incompleteColour,
        } ,
        {
            type = LHA.ST_COLOR,
            label = WritCreater.optionStrings['completeColour'], 
            getFunction = function() return unpack(WritCreater:GetSettings().completeColour) end,
            disable = function() return not WritCreater:GetSettings().showStatusBar end,
            setFunction = function(...) WritCreater:GetSettings().completeColour = {...}
                WritCreater.updateQuestStatus()
                WritCreater.toggleQuestStatusWindow(false)
                zo_callLater(WritCreater.updateQuestStatus, statusBarSampleTimeout)
            end,
            default = WritCreater.default.completeColour,
        } ,
        {
            type = LHA.ST_SECTION,
            label = WritCreater.optionStrings["writRewards submenu"],
        },
        {
            type = LHA.ST_SECTION,
            label = WritCreater.optionStrings["crafting submenu"],
        },
        {
            type = LHA.ST_SECTION,
            label = WritCreater.optionStrings["style stone menu"],
        },
    }
    for i = 1, #options do
        settings:AddSetting(options[i])
    end

end