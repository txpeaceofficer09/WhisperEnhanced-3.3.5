local addonName = "WhisperEnhanced"
local WhoWhisperer = CreateFrame("Frame", addonName)

--[[ Global Data Storage ]]
-- A queue to hold whisper data until the /who result returns.
local WhisperQueue = {}
-- A flag used within the chat filter to prevent the custom-printed message from being filtered.
local IsPrintingEnhanced = false

--local PlayerData = {}

-- Color constants for the prefix (White) and the enhanced info (Yellow)
local COLOR_INFO = "|cffFFFF00"
local COLOR_PREFIX = "|cffFFFFFF"
local COLOR_END = "|r"

-- Helper function to retrieve the class color hex code
local function GetClassColorHex(class)
    local color = RAID_CLASS_COLORS[class]
    if color then
        -- Convert RGB (0.0 to 1.0) to Hex (00 to FF)
        local r, g, b = color.r, color.g, color.b
        return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
    end
    -- Default to gray if class color not found
    return "|cffA0A0A0" 
end

--------------------------------------------------------------------------------
-- 1. WHISPER AND WHO PROCESSING
--------------------------------------------------------------------------------

-- Event Handler for Whispers and Who Results
local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_WHISPER" then
        local message, sender = ...
        
        WhisperQueue[sender] = {
            message = message,
            originalSender = sender,
        }
        
        SendWho(sender)   
    elseif event == "WHO_LIST_UPDATE" then
        
        local numResults = GetNumWhoResults()
        
        -- Iterate through the who results list to find the matching player
        for i = 1, numResults do
            -- GetWhoInfo returns: name, guild, level, race, class, zone, sex, BNet ID (WoTLK API)
            local name, guild, level, race, class, zone = GetWhoInfo(i)
            
            -- Look for this player's data in our queue
            local queuedData = WhisperQueue[name]
            
            if queuedData then
                local classColor = GetClassColorHex(class)
                local localizedClass = select(1, GetClassInfo(class)) or class
                local localizedRace = race

                -- 1. Create the Enhanced Sender String
                -- Format: [Level] [Class Icon] [Race] [Class] [Name (Class Colored)]
                local enhancedSender = string.format(
                    "%s[%s] |TInterface\\Garrison\\Garrison_Architect_ClassIcon_%s:16:16:0:0:64:64:4:60:4:60|t %s %s %s%s%s",
                    COLOR_INFO,
                    level,
                    string.lower(class), -- Use lowercase class name for the icon texture path
                    localizedRace,
                    localizedClass,
                    classColor, name, COLOR_END
                )

                -- 2. Create the Final Message
                local finalMessage = string.format(
                    "%s: %s",
                    enhancedSender,
                    queuedData.message -- The original message content
                )

                -- 3. Print the Enhanced Message Manually
                DEFAULT_CHAT_FRAME:AddMessage(finalMessage, 0.5, 0.7, 1.0, 1.0, 1) -- Print with slight blue tint

                -- 4. Clean up the queue
                WhisperQueue[name] = nil
                
                -- Optimization: If we found a match, we can break out of the WHO list loop
                break 
            end
        end
    end
end

WhoWhisperer:SetScript("OnEvent", OnEvent)
WhoWhisperer:RegisterEvent("CHAT_MSG_WHISPER")
WhoWhisperer:RegisterEvent("WHO_LIST_UPDATE")


--------------------------------------------------------------------------------
-- 2. CHAT FILTER (THE "HIDE WHO" AND "SUPPRESS WHISPER" LOGIC)
--------------------------------------------------------------------------------

function WhisperEnhanced:ChatFilter(self, event, msg, sender, ...)
    if event == "CHAT_MSG_WHISPER" then
	return true
    end
    
    -- Filter 2: Suppress the results of the automated /who command.
    -- The output of a /who command is CHAT_MSG_SYSTEM, and it usually contains "Found X matches" or the list lines.
    -- We can check for known system messages related to /who
	if event == "CHAT_MSG_SYSTEM" then
		if msg and string.find(msg, GetText("WHO_NO_MATCHES") or "No players matched" ) then
			-- Suppress the "No players matched" message if we have a pending whisper query
			for k, v in pairs(WhisperQueue) do
				if string.find(msg, k) then return false end
			end
			return true -- Also suppresses the "Found X matches" message.
		end

		for k, v in pairs(WhisperQueue) do
			if msg and string.find(msg, k) then return true end
		end
	end
    
    -- If the message is not a target for suppression, allow it to display.
    return false, msg, sender, ...
end

-- Hook the chat filter mechanism to apply our custom filtering logic
ChatFrame_AddMessageEventFilter(WhisperEnhanced[ChatFilter])

-- Initialization message
PrintMessage(COLOR_PREFIX .. "[" .. addonName .. "]: " .. COLOR_END .. "Enhanced whisper lookup active. Incoming whispers will be briefly delayed.")
