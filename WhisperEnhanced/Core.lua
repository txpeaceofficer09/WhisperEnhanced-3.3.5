local frame = CreateFrame("Frame")

local whisperQueue = {}
local whoPending = false
local currentQuery = nil
local PlayerData = {}
local whoQueue = {}

function frame:print(msg)
	print(("|cffffaaff[WHISPERENHANCED]:|r %s"):format(msg))
end

local function ChatFilter(self, event, msg, sender, ...)
	sender = sender:match("([^%-]+)")

	if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
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
	elseif event == "CHAT_MSG_SYSTEM" then
		for k,v in ipairs(whoQueue) do
			if msg:find(v) then
				table.remove(whoQueue, k)
				return true
			end
		end
        
		if msg:find("player total") then
			return true
		end

		return false, msg, sender, ...
	end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ChatFilter)

local function OnEvent(self, event, ...)
	if event == "WHO_LIST_UPDATE" then
		self:print("Who list updated.")

		local numResults = GetNumWhoResults()

		for i = 1, GetNumWhoResults(), 1 do
			local name, guild, level, race, class = GetWhoInfo(i)
			PlayerData[name] = {
				["guild"] = guild,
				["level"] = level,
				["race"] = race,
				["class"] = class,
			}
		end
	end
end

frame:RegisterEvent("WHO_LIST_UPDATE")
frame:SetScript("OnEvent", OnEvent)
