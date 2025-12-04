local whisperQueue = {}
local whoPending = false
local currentQuery = nil
local PlayerData = {}
local whoQueue = {}

local function WhisperFilter(self, event, msg, sender, ...)
	sender = sender:match("([^%-]+)")

	--if event == "CHAT_MSG_WHISPER" then
		if PlayerData[sender] then
			if PlayerData[sender].guild then
				return false, ("[%s %d] <%s>: %s"):format(PlayerData[sender].class, PlayerData[sender].level, PlayerData[sender].guild, msg), sender, ...
			else
				return false, ("[%s %d]: %s"):format(PlayerData[sender].class, PlayerData[sender].level, msg), sender, ...
			end
		else
			table.insert(whoQueue, sender)
			SendWho("n-"..sender)

			return false, msg, sender, ...
		end
	--elseif event == "CHAT_MSG_WHISPER_INFORM" then
		
	--end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", WhisperFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", WhisperFilter)

local frame = CreateFrame("Frame")
frame:RegisterEvent("WHO_LIST_UPDATE")

local function ProcessWhoResult()
    local found = false
    local playerClass, playerLevel

    for i = 1, GetNumWhoResults() do
        local name, guild, level, race, class = GetWhoInfo(i)
	PlayerData[name] = {
		["guild"] = guild,
		["level"] = level,
		["race"] = race,
		["class"] = class,
	}
	print("|cffffaa00[WHISPERENHANCED]:|r added |cff336699"..name.."|r player data.")
	--[[
        if name == currentQuery then
            found = true
            playerClass = class
            playerLevel = level
            break
        end
	]]
    end

	--[[
    for i = #whisperQueue, 1, -1 do
        local data = whisperQueue[i]
        if data.sender == currentQuery then
            local modifiedMsg

            if found then
                modifiedMsg = string.format("[%s %d] %s", playerClass, playerLevel, data.msg)
            else
                modifiedMsg = "[? ?] " .. data.msg
            end

            ChatFrame1:AddMessage(
                string.format("|cffFFFF00(Delayed Whisper)|r [%s]: %s",
                    data.sender, modifiedMsg
                )
            )

            table.remove(whisperQueue, i)
        end
    end

    currentQuery = nil
    whoPending = false

    if whisperQueue[1] then
        currentQuery = whisperQueue[1].sender
        whoPending = true
        SendWho("n-" .. currentQuery)
    end
	]]
end

frame:SetScript("OnEvent", ProcessWhoResult)

local function BlockWhoResults(self, event, msg, ...)
	for k,v in ipairs(whoQueue) do
		if msg:find(v) then
			table.remove(whoQueue, k)
			return true
		end
	end
        
        if msg:find("player total") then
            return true
        end

	return false, msg, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", BlockWhoResults)
