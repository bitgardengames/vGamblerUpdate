local Name, AddOn = ...
local vGambler = AddOn.vGambler
local L = AddOn.L

local table = table
local string = string

local function AddMatchData(payload, wager, players)
	table.insert(payload, wager)

	for i = 1, #(players or {}) do
		table.insert(payload, players[i].name)
		table.insert(payload, players[i].roll)
	end

	return table.concat(payload, "\\")
end

vGambler.EventGroups = {
	{CHAT_MSG_PARTY = true, CHAT_MSG_PARTY_LEADER = true},
	{CHAT_MSG_RAID = true, CHAT_MSG_RAID_LEADER = true},
	{CHAT_MSG_GUILD = true},
}

function vGambler:ResetGame() -- Resets the game to its initial state, clearing all data, and enabling/disabling relevant buttons
	local GameChannel = self.GameChannel or self.Settings.Channel

	self.Rolled = 0
	self.Locked = false
	self.IsTestGame = nil
	self.Result = nil
	self.MatchPlayers = nil
	self.Host = nil
	self.GameChannel = nil
	self.GameWager = self.Settings.RollValue
	self.Players = table.wipe(self.Players)
	self.Tie = table.wipe(self.Tie)

	self:RemoveAllPlayersUI()

	if self:GetScript("OnUpdate") then
		self:SetScript("OnUpdate", nil)
	end

	if self.EventGroups[GameChannel] then
		for event in next, self.EventGroups[GameChannel] do
			self:UnregisterEvent(event)
		end
	end

	self:EnableGameButton("Start")
	self:EnableGameButton("Test")
	self:EnableGameButton("Channel")
	self:EnableGameButton("RollValue")
	self:DisableGameButton("LastCall")
	self:DisableGameButton("Reset")
	self:DisableGameButton("Close")

	self.Window.PlayButtons:Hide()
	self.Window.GameSettings:Show()

	self:DisablePlayButton("Join")
	self:DisablePlayButton("Withdraw")
	self:DisablePlayButton("Roll")

	self:SendMessage("|cffFFC44Dv|rGambler: Game has been reset.")

	self:SendEvent("ResetGame", UnitName("player"))
end

function vGambler:StartGame() --  Starts a new game, registers relevant events, and updates button states and UI
	self.Host = UnitName("player")
	self.GameChannel = self.Settings.Channel
	self.GameWager = self.Settings.RollValue
	if self.EventGroups[self.Settings.Channel] then
		for event in next, self.EventGroups[self.Settings.Channel] do
			self:RegisterEvent(event)
		end
	end

	self:DisableGameButton("Start")
	self:DisableGameButton("RollValue")
	self:DisableGameButton("Channel")
	self:EnableGameButton("LastCall")
	self:EnableGameButton("Reset")
	self:EnableGameButton("Close")

	self.Window.GameSettings:Hide()
	self.Window.PlayButtons:Show()

	self:EnablePlayButton("Join")
	self:DisablePlayButton("Withdraw")
	self:DisablePlayButton("Roll")

	self:SendMessage(string.format("|cffFFC44Dv|rGambler: New game started! Current roll is for %sg! type %s to enter (%s to withdraw).", self:Comma(self.Settings.RollValue), self.Settings.EnterCommand, self.Settings.LeaveCommand))

	self:SendEvent("NewGame", string.format("%s\\%s\\%d", UnitName("player"), self.Settings.Channel, self.Settings.RollValue))
end

function vGambler:LastCall() -- Sends a message announcing the last call for players to enter the game
	self:SendMessage("|cffFFC44Dv|rGambler: Last call to enter!")

	self:DisableGameButton("LastCall")
end

function vGambler:CloseGame() -- Closes the game, stops accepting players, and triggers the rolling process
	if self.Locked then -- There's a roll going currently. Announce who still needs to roll.
		local List = {}

		for i = 1, #self.Players do
			if (self.Players[i].Roll == 0) then
				table.insert(List, self.Players[i].DisplayName)
			end
		end

		self:SendMessage(string.format("|cffFFC44Dv|rGambler: The following players still need to roll: %s", table.concat(List, ", ")))
	elseif (#self.Players > 1) then -- Stop accepting players, and start rolling
		self.Rolled = 0
		self.Locked = true

		local GameChannel = self.GameChannel or self.Settings.Channel
		if self.EventGroups[GameChannel] then
			for event in next, self.EventGroups[GameChannel] do
				self:UnregisterEvent(event)
			end
		end

		self:RegisterEvent("CHAT_MSG_SYSTEM")

		self:DisableGameButton("Start")
		self:DisableGameButton("LastCall")
		self:DisableGameButton("Close")
		self:DisableGameButton("RollValue")
		self:DisableGameButton("Channel")
		self:EnableGameButton("Reset")

		self:DisablePlayButton("Join")
		self:DisablePlayButton("Withdraw")

		for i = 1, #self.Players do
			if (self.Players[i].Name == UnitName("player")) then
				self:EnablePlayButton("Roll")
				break
			end
		end

		if self.Settings.PlaySounds then
			PlaySoundFile(string.format("Interface\\AddOns\\vGambler\\Assets\\FX_BoardTilesDice_0%d.ogg", math.random(2, 4)))
		end

		self:SendMessage("|cffFFC44Dv|rGambler: Game is now closed! Roll!")
		self:SendEvent("CloseGame", UnitName("player"))

		if self.IsTestGame then
			self:RollTestPlayers()
		end
	else
		self:SendMessage("|cffFFC44Dv|rGambler: Not enough players!")
	end
end

function vGambler:CloseTiedGame()
	if (#self.Players > 1) then
		self.Rolled = 0
		self.Locked = true
		self.TiedGame = true
		self.Tie = table.wipe(self.Tie)

		local GameChannel = self.GameChannel or self.Settings.Channel
		if self.EventGroups[GameChannel] then
			for event in next, self.EventGroups[GameChannel] do
				self:UnregisterEvent(event)
			end
		end

		self:RegisterEvent("CHAT_MSG_SYSTEM")

		self:DisableGameButton("Start")
		self:DisableGameButton("LastCall")
		self:DisableGameButton("Channel")
		self:DisableGameButton("RollValue")
		--self:DisableGameButton("Close")
		self:EnableGameButton("Reset")
		self:DisablePlayButton("Roll")

		for i = 1, #self.Players do
			if (self.Players[i].Name == UnitName("player")) then
				self:EnablePlayButton("Roll")
				break
			end
		end

		if self.IsTestGame then
			self:RollTestPlayers()
		end
	end
end

function vGambler:CloseDrawGame()
	self.Locked = false
	self.TiedGame = false

	if self.Settings.PlaySounds then
		PlaySound(SOUNDKIT.LFG_DENIED)
	end

	self:AddStat("draw", 1)
	self:AddMatchHistory("Draw", "Draw", 0, self.GameWager or self.Settings.RollValue, self.MatchPlayers or {})

	if self.IsTestGame then -- Just debugging to loop test games
		self.Ela = 0
		self:SetScript("OnUpdate", self.ResetOnUpdate)
	end

	self:SendMessage("|cffFFC44Dv|rGambler: The game has resulted in a draw!")
	self:SendEvent("GameDraw", AddMatchData({}, self.GameWager or self.Settings.RollValue, self.MatchPlayers))
end

function vGambler:UpdateGameResults() -- Sorts the player rolls and determines the winners and losers
	local High = self.Players[1].Roll
	local Low = self.Players[#self.Players].Roll
	local Winners = {}
	local Losers = {}

	for i = 1, #self.Players do
		if (self.Players[i].Roll == High) then
			table.insert(Winners, self.Players[i])
		elseif (self.Players[i].Roll == Low) then
			table.insert(Losers, self.Players[i])
		end

		self:AddPlayerStat(self.Players[i].DisplayName, "games", 1)
	end

	if (not self.Result) then
		if (#Losers == 0) then -- If all players roll the same value on the first roll, we've drawn
			self:CloseDrawGame()

			return
		else
			self.Result = {Winners, Losers, Winners[1].Roll, Losers[1].Roll or 0} -- Store the top and bottom rolls. The tie breakers will secure these rolls after ties are broken.
		end
	else
        if (#self.Result[1] > 1) then
			self.Result[1] = (#Winners > 0 and Winners) or Losers
        elseif (#self.Result[2] > 1) then
			self.Result[2] = (#Losers > 0 and Losers) or Winners
        end
	end

	if (#self.Result[1] > 1 and #self.Result[2] > 0) then
		for i = 1, #self.Result[1] do
			table.insert(self.Tie, self.Result[1][i])
		end

		self:SendMessage(string.format("|cffFFC44Dv|rGambler: Winning tie found (%s). %s need to roll again to determine the winner", self.Result[3], self:ListPlayers(self.Tie)))
	elseif (#self.Result[2] > 1 and #self.Result[1] > 0) then
		for i = 1, #self.Result[2] do
			table.insert(self.Tie, self.Result[2][i])
		end

		self:SendMessage(string.format("|cffFFC44Dv|rGambler: Losing tie found (%s). %s need to roll again to determine the loser", self.Result[4], self:ListPlayers(self.Tie)))
	end

    if (#self.Tie > 0) then
		self:SetTieMatch()
    else
		self:DeclareWinner()
    end
end

function vGambler:SortRolls()
	self:UnregisterEvent("CHAT_MSG_SYSTEM")

	table.sort(self.Players, function(a, b)
		return a.Roll > b.Roll
	end)

	if (not self.Result) then
		self.MatchPlayers = {}

		for i = 1, #self.Players do
			table.insert(self.MatchPlayers, {name = self.Players[i].DisplayName, roll = self.Players[i].Roll})
		end
	end

	self:UpdateGameResults()
end

function vGambler:SetTieMatch() -- Handles the situation where there is a tie, prompting tied players to roll again
	if self.IsTestGame then
		self:SetScript("OnUpdate", self.PauseOnUpdate)
	else
		local Players = {}

		for i = 1, #self.Tie do
			table.insert(Players, self.Tie[i].Name)
		end

		self:SendEvent("GameTie", table.concat(Players, "\\"))
		self:RemoveAllPlayersUI()

		for i = #self.Players, 1, -1 do
			table.remove(self.Players, 1)
		end

		for i = 1, #self.Tie do
			table.insert(self.Players, self.Tie[i])
		end

		for i = 1, #self.Players do
			self.Players[i].Roll = 0
			self:AddPlayerUI()
			self:AddPlayerStat(self.Players[i].DisplayName, "ties", 1)
		end

		self:AddStat("ties", 1)

		self:CloseTiedGame()
	end

	if self.Settings.PlaySounds then
		PlaySound(SOUNDKIT[string.format("ALARM_CLOCK_WARNING_%d", math.random(2, 3))])
	end
end

function vGambler:DeclareWinner() -- Declares the winner of the game, calculates earnings, and updates statistics
	local Winner = self.Result[1][1].DisplayName
	local Loser = self.Result[2][1].DisplayName
	local Earnings = self.Result[3] - self.Result[4]

	self.SessionGames = (self.SessionGames or 0) + 1

	self:AddStat("games", 1)
	self:AddStat("totalgold", Earnings)
	self:AddMaxStat("topwin", self.Result[3])
	self:AddMaxStat("toppayout", Earnings)
	self:AddMaxStat("topwager", self.GameWager or self.Settings.RollValue)
	self:AddMaxStat("sessiongames", self.SessionGames)

	self:AddPlayerStat(Winner, "wins", 1)
	self:AddPlayerStat(Winner, "earnings", Earnings)
	self:AddPlayerStat(Loser, "losses", 1)
	self:AddPlayerStat(Loser, "loss", Earnings)

	if self.TiedGame then
		self:AddPlayerStat(Winner, "tieswon", 1)
		self:AddPlayerStat(Loser, "tieslost", 1)
	end

	self:UpdateBasicStats()
	self:UpdateStatGrid()

	if self.Settings.PlaySounds then
		PlaySound(SOUNDKIT.LOOT_WINDOW_COIN_SOUND)
	end

	self.Locked = false
	self.TiedGame = false

	self:SendMessage(string.format("|cffFFC44Dv|rGambler: %s (%s) owes %s (%s) %s gold!", self.Result[2][1].DisplayName, self.Result[4], self.Result[1][1].DisplayName, self.Result[3], self:Comma(Earnings)))

	self:SendEvent("GameEnded", AddMatchData({Winner, Loser, self.Result[3], self.Result[4]}, self.GameWager or self.Settings.RollValue, self.MatchPlayers))
	self:AddMatchHistory(Winner, Loser, Earnings, self.GameWager or self.Settings.RollValue, self.MatchPlayers or {})

	if self.IsTestGame then -- Just debugging to loop test games
		self.Ela = 0
		self:SetScript("OnUpdate", self.ResetOnUpdate)
	end
end

function vGambler:CHAT_MSG_SYSTEM(message)
	local Name, Roll, Min, Max = string.match(message, "^(%S+)%s%S+%s(%d+)%s%((%d+)-(%d+)%)")

	if (tonumber(Min) == 1 and tonumber(Max) == (self.GameWager or self.Settings.RollValue)) then
		for i = 1, #self.Players do
			if (self.Players[i].Name == Name and self.Players[i].Roll == 0) then
				self.Players[i].Roll = tonumber(Roll)
				self.Rolled = self.Rolled + 1

				if (tonumber(Roll) == (self.GameWager or self.Settings.RollValue) and (self.GameWager or self.Settings.RollValue) > 99) then -- If a player hit the max possible roll, and the wager was 100 or higher
					PlaySoundFile(569593)
				end

				self:AddStat("rolls", 1)

				if (self.Rolled == #self.Players and self.Host == UnitName("player")) then
					self:SortRolls()
				end

				self:SortPlayerList(true)

				break
			end
		end

		--self:SortPlayerList(true)
	end
end

function vGambler:ChatMessageEvent(message, sender, lang, channel, player, flags, zone, channel, base, lang, line, guid)
	sender = string.match(sender, "(%S+)-.-") -- Remove server name.

	if (message == self.Settings.EnterCommand) then
		local Banned, Reason = self:IsBanned(sender)

		if (not Banned) then
			self:AddPlayer(sender, guid)

			self:SendEvent("AddPlayer", string.format("%s\\%s", sender, guid))
		else
			if (Reason == true) then -- No reason specified for this player being banned.
				self:SendMessage(string.format("|cffFFC44Dv|rGambler: %s is banned from entering.", sender))
			else -- Let them know why they were banned.
				self:SendMessage(string.format("|cffFFC44Dv|rGambler: %s is banned from entering. Reason: %s.", sender, Reason))
			end
		end
	elseif (message == self.Settings.LeaveCommand) then
		self:RemovePlayer(sender)
		self:AddStat("withdraw", 1)

		self:SendEvent("RemovePlayer", sender)
	end
end
