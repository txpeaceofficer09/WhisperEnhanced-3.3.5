local PlayerData = {}
local whoQueue = {}
local whisperQueue = {}

local function GetClassColorHex(class)
	if not class then return "FFFFFF" end  -- fallback: white

	class = class:upper()

	local c = RAID_CLASS_COLORS[class]
	if not c then return "FFFFFF" end  -- unknown class → white

	return string.format("%02X%02X%02X",
		c.r * 255,
		c.g * 255,
		c.b * 255
	)
end

local function ChatFilter(self, event, msg, sender, ...)
	sender = sender:match("([^%-]+)")

	if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		if PlayerData[sender] then
			--local classIcon =  ("|TInterface\\Icons\\ClassIcon_%s:14:14|t"):format(PlayerData[sender].class:upper())
			--local raceIcon = ("|TInterface\\TargetingFrame\\UI-TargetingFrame-%s:14:14|t"):format(PlayerData[sender].race)

			--local classIcon = ("|TInterface\\Icons\\ClassIcon_%s:14:14|t"):format(PlayerData[sender].class:upper())
			--local raceIcon = ("|TInterface\\TargetingFrame\\UI-TargetingFrame-%s:14:14|t"):format(PlayerData[sender].race:gsub("%s+", ""))

			if PlayerData[sender].guild then
				return false, ("[|cffffffff%s %s %d|r] <|cffaaffaa%s|r>: %s"):format(PlayerData[sender].race, PlayerData[sender].class, PlayerData[sender].level, PlayerData[sender].guild, msg), sender, ...
			else
				return false, ("[|cffffffff%s %s %d|r]: %s"):format(raceIcon, classIcon, PlayerData[sender].level, msg), sender, ...
			end
		else
			table.insert(whoQueue, sender)
			SendWho("n-"..sender)

			table.insert(whisperQueue, {
				["event"] = event,
				["name"] = sender,
				["msg"] = msg,
			})

			--return false, msg, sender, ...
			return true
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		--local name, level, race, class, guild, zone = msg:match("^(.-): Level (%d+) (%w+) (%w+) <%s*(.-)%s*> %- (.+)$")
		--print(("|Hplayer:Abracadaver|h[Abracadaver]|h: Level 48 Undead Mage <Reign of Darkness> - Searing Gorge"):match(^|Hplayer:(%w)|h%[%w+%]|h: Level (%d+) (%w+) (%w+) <%s*(.-)%s*> %- (.+)$"))
		local name, level, race, class, guild, zone = msg:match("^|Hplayer:([^|]+)|h%[[^%]]+%]|h: Level (%d+) (%w+) (%w+) <%s*(.-)%s*> %- (.+)$")

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

		for k,v in ipairs(whisperQueue) do
			if PlayerData[v.name] then
				if v.event == "CHAT_MSG_WHISPER" then
					if PlayerData[v.name].guild then
						print("|cffff80ff|Hplayer:%s|h[|cff%s%s|cffff80ff]|h: [|cffffffff%s %s %d|cffff80ff] <|cffaaffaa%s|r>: %s|r":format(v.name, GetClassColor(PlayerData[v.name].class), v.name, PlayerData[v.name].race, PlayerData[v.name].class, PlayerData[v.name].level, PlayerData[v.name].guild, v.msg)
					else
						print("|cffff80ff|Hplayer:%s|h[|cff%s%s|cffff80ff]|h: [|cffffffff%s %s %d|cffff80ff]: %s|r":format(v.name, GetClassColor(PlayerData[v.name].class), v.name, PlayerData[v.name].race, PlayerData[v.name].class, PlayerData[v.name].level, v.msg)
					end
				elseif v.event == "CHAT_MSG_WHISPER_INFORM" then
					if PlayerData[v.name].guild then
						print("|cffff80ffTo |Hplayer:%s|h[|cff%s%s|cffff80ff]|h: [|cffffffff%s %s %d|cffff80ff] <|cffaaffaa%s|r>: %s|r":format(v.name, GetClassColor(PlayerData[v.name].class), v.name, PlayerData[v.name].race, PlayerData[v.name].class, PlayerData[v.name].level, PlayerData[v.name].guild, v.msg)
					else
						print("|cffff80ffTo |Hplayer:%s|h[|cff%s%s|cffff80ff]|h: [|cffffffff%s %s %d|cffff80ff]: %s|r":format(v.name, GetClassColor(PlayerData[v.name].class), v.name, PlayerData[v.name].race, PlayerData[v.name].class, PlayerData[v.name].level, v.msg)
					end
				end
				table.remove(whisperQueue, k)
			end
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
