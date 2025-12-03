local whisperQueue = {}
local whoPending = false
local currentQuery = nil

local function WhisperFilter(self, event, msg, sender, ...)
    sender = sender:match("([^%-]+)")

    table.insert(whisperQueue, {
        event = event,
        msg = msg,
        sender = sender,
        args = { ... },
    })

    if not whoPending then
        currentQuery = sender
        whoPending = true
        SendWho("n-" .. sender)
    end

    return true
end

local function BlockWhoResults(self, event, msg, ...)
	if ( whoPending and msg:find(currentQuery) ) or msg:match("(.+) players total") or msg:match("(.+) player total") then
		return true
	end
	return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", WhisperFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", WhisperFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", BlockWhoResults)

local frame = CreateFrame("Frame")

local function ProcessWhoResult()
	print("Processing who whisper results.")

	local found = false
	local playerClass, playerLevel

	for i = 1, GetNumWhoResults() do
		local name, guild, level, race, class = GetWhoInfo(i)
		if name == currentQuery then
			found = true
			playerClass = class
			playerLevel = level
			break
		end
	end

    for i = #whisperQueue, 1, -1 do
        local data = whisperQueue[i]
        if data.sender == currentQuery then
            local modifiedMsg

            if found then
                modifiedMsg = string.format("[%s %d] %s", playerClass, playerLevel, data.msg)
            else
                modifiedMsg = "[? ?] " .. data.msg
            end

            DEFAULT_CHAT_FRAME:AddMessage(
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
end

frame:RegisterEvent("WHO_LIST_UPDATE")

frame:SetScript("OnEvent", ProcessWhoResult)
