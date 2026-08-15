local Name, AddOn = ...
local vGambler = AddOn.vGambler

local table = table
local string = string
local CT = ChatThrottleLib

vGambler.Events = {}

vGambler.Events.Message = function(self, message)
	if (not self.ChatWindow) then -- Window is load on demand, so it doesn't exist until we open the window. Do something to capture earlier messages until we load our window?
		return
	end

	self.ChatWindow:AddMessage(message)
end

vGambler.Events.NewGame = function(self, args)
	local Leader, Channel, Wager = string.match(args, "([^\\]+)\\(%d+)\\(%d+)")

	self:DisableGameButton("Start")
	self:DisableGameButton("RollValue")
	self:DisableGameButton("Channel")
	self:DisableGameButton("LastCall")
	self:DisableGameButton("Reset")
	self:DisableGameButton("Close")

	self.Window.GameSettings:Hide()
	self.Window.PlayButtons:Show()

	self.Host = Leader
	self.GameChannel = tonumber(Channel)
	self.GameWager = tonumber(Wager)
	self.Rolled = 0
	self.Locked = false
	self.Players = table.wipe(self.Players)
	self:RemoveAllPlayersUI()
	self:EnablePlayButton("Join")
	self:DisablePlayButton("Withdraw")
	self:DisablePlayButton("Roll")
end

vGambler.Events.ResetGame = function(self)
	self:RemoveAllPlayers()
	self.Players = table.wipe(self.Players)
	self:UnregisterEvent("CHAT_MSG_SYSTEM")

	self:EnableGameButton("Start")

	self.Window.PlayButtons:Hide()
	self.Window.GameSettings:Show()

	self.Host = nil
	self.GameChannel = nil
	self.GameWager = self.Settings.RollValue
	self.Locked = false
	self.Rolled = 0
	self:DisablePlayButton("Join")
	self:DisablePlayButton("Withdraw")
	self:DisablePlayButton("Roll")
end

vGambler.Events.AddPlayer = function(self, args)
	local Name, GUID = string.match(args, "([^\\]+)\\(%S+)")

	self:AddPlayer(Name, GUID)

	if (Name == UnitName("player")) then
		self:DisablePlayButton("Join")
		self:EnablePlayButton("Withdraw")
	end
end

vGambler.Events.RemovePlayer = function(self, name)
	if self:RemovePlayer(name) then
		self:AddStat("withdraw", 1)
	end

	if (name == UnitName("player")) then
		self:EnablePlayButton("Join")
		self:DisablePlayButton("Withdraw")
	end

	self.Window.Label:SetText(string.format("|cffFFC44DvGambler|r  (%s / %s)", self.Rolled or 0, #self.Players))
end

vGambler.Events.CloseGame = function(self)
	self.Locked = true
	self.Rolled = 0
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:DisablePlayButton("Join")
	self:DisablePlayButton("Withdraw")

	for i = 1, #self.Players do
		if (self.Players[i].Name == UnitName("player")) then
			self:EnablePlayButton("Roll")
			break
		end
	end
end

vGambler.Events.PlayerRoll = function(self, args)
	local Name, Roll = string.match(args, "([^\\]+)\\(%d+)")

	for i = 1, #self.Players do
		if (self.Players[i].Name == Name and self.Players[i].Roll == 0) then
			Roll = tonumber(Roll)

			self.Players[i].Roll = Roll
			self.Rolled = (self.Rolled or 0) + 1

			if (Roll == self.GameWager and self.GameWager > 99) then
				PlaySoundFile(569593)
			end

			-- Update the header as well to display number of players
			self.Window.Label:SetText(string.format("|cffFFC44DvGambler|r  (%s / %s)", self.Rolled or 0, #self.Players))

			self:AddStat("rolls", 1)

			self:SortPlayerList(true)

			break
		end
	end
end

vGambler.Events.GameEnded = function(self, args)
	local Winner, Loser, High, Low = string.match(args, "(%S+)\\(%S+)\\(%d+)\\(%d+)")
	local Value = tonumber(High) - tonumber(Low)

	self:AddStat("games", 1)
	self:AddStat("totalgold", Value)
	self:AddMaxStat("topwin", High)
	self:AddMaxStat("toppayout", Value)
	self:AddMaxStat("topwager", self.GameWager)

	self:AddPlayerStat(Winner, "wins", 1)
	self:AddPlayerStat(Winner, "earnings", Value)
	self:AddPlayerStat(Loser, "losses", 1)
	self:AddPlayerStat(Loser, "loss", Value)

	self:UpdateBasicStats()
	self:UpdateStatGrid()

	if self.Settings.PlaySounds then
		PlaySound(SOUNDKIT.LOOT_WINDOW_COIN_SOUND)
	end

	self.Locked = false
	self.TiedGame = false
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:DisablePlayButton("Roll")

	-- If we're in silent, add the message
	--self:SendMessage(string.format("|cffFFC44Dv|rGambler: %s (%s) owes %s (%s) %s gold!", self.Result[2][1].DisplayName, self.Result[4], self.Result[1][1].DisplayName, self.Result[3], self:Comma(Earnings)))
end

vGambler.Events.GameDraw = function(self)
	if self.Settings.PlaySounds then
		PlaySound(SOUNDKIT.LFG_DENIED)
	end

	self:AddStat("draw", 1)
	self.Locked = false
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:DisablePlayButton("Roll")
end

vGambler.Events.GameTie = function(self, args)
	local Players = {}

	for Name in string.gmatch(args, "[^\\]+") do
		Players[Name] = true
	end

	self:RemoveAllPlayersUI()

	for i = #self.Players, 1, -1 do
		if Players[self.Players[i].Name] then
			self.Players[i].Roll = 0
		else
			table.remove(self.Players, i)
		end
	end

	for i = 1, #self.Players do
		self:AddPlayerUI()
	end

	self.Rolled = 0
	self.Locked = true
	self.TiedGame = true
	self:DisablePlayButton("Roll")

	if Players[UnitName("player")] then
		self:EnablePlayButton("Roll")
	end

end

vGambler.Events.Toggle = function(self) -- Just a testing event, remove for release
	if (not self.Window) then
		self:CreateWindow()
	end

	if (not self.Window:IsShown()) then
		self:ShowWindow()
	end
end

vGambler.Events.Version = function(self, message)
	local Version = tonumber(message)

	if (Version > (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)("vGambler", "Version")) then
		print(string.format("vGambler: A new version is available (%s)", Version))
	end
end

function vGambler:CHAT_MSG_ADDON(prefix, message, chattype, sender)
	sender = string.match(sender, "^([^-]+)") or sender

	if (prefix ~= "vGambler" or sender == UnitName("player")) then
		return
	end

	local Event, Args = string.match(message, "^(%a+)\\(.+)$")

	if self.Events[Event] then
		if (Event ~= "NewGame" and self.Host and sender ~= self.Host) then
			return
		end

		if (not self.Window) then
			self:CreateWindow()
		end

		self.Events[Event](self, Args)
	end
end

function vGambler:SendEvent(event, args)
	if (self.Settings.Channel == 4) then
		return
	end

	local Message = string.format("%s\\%s", event, args or " ")

	CT:SendAddonMessage("NORMAL", "vGambler", Message, self.ChannelSelections[self.Settings.Channel])
end

function vGambler:JoinGame()
	SendChatMessage(self.Settings.EnterCommand, self.ChannelSelections[self.GameChannel or self.Settings.Channel])
	self:DisablePlayButton("Join")
	self:EnablePlayButton("Withdraw")
end

function vGambler:WithdrawGame()
	SendChatMessage(self.Settings.LeaveCommand, self.ChannelSelections[self.GameChannel or self.Settings.Channel])
	self:EnablePlayButton("Join")
	self:DisablePlayButton("Withdraw")
end

function vGambler:RollGame()
	RandomRoll(1, self.GameWager or self.Settings.RollValue)
	self:DisablePlayButton("Roll")
end

vGambler:RegisterEvent("CHAT_MSG_ADDON")

C_ChatInfo.RegisterAddonMessagePrefix("vGambler")
