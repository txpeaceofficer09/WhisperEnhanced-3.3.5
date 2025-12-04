local PlayerData = {}
local whoQueue = {}

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
		--local name, level, race, class, guild, zone = msg:match("^(.-): Level (%d+) (%w+) (%w+) <%s*(.-)%s*> %- (.+)$")
		--print(("|Hplayer:Abracadaver|h[Abracadaver]|h: Level 48 Undead Mage <Reign of Darkness> - Searing Gorge"):match(^|Hplayer:(%w)|h%[%w+%]|h: Level (%d+) (%w+) (%w+) <%s*(.-)%s*> %- (.+)$"))
		local name, level, race, class, guild, zone = msg:match(^|Hplayer:(%w)|h%[%w+%]|h: Level (%d+) (%w+) (%w+) <%s*(.-)%s*> %- (.+)$"))

		if name then
			--name = name:match("^|Hplayer:([^|]+)|h")

			PlayerData[name] = {
				["level"] = level,
				["race"] = race,
				["class"] = class,
				["guild"] = guild,
				["zone"] = zone,
			}
		end

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

--|Hplayer:Abracadaver|h[Abracadaver]|h: Level 48 Undead Mage <Reign of Darkness> - Searing Gorge
