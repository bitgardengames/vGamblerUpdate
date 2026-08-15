local Name, AddOn = ...
local GambleBuddy = AddOn.GambleBuddy

local string = string
local CT = ChatThrottleLib

GambleBuddy.Events = {}

GambleBuddy.Events.Message = function(self, message)
	if (not self.ChatWindow) then -- Window is load on demand, so it doesn't exist until we open the window. Do something to capture earlier messages until we load our window?
		return
	end

	self.ChatWindow:AddMessage(message)
end

GambleBuddy.Events.NewGame = function(self, args)
	local Leader, Channel, Wager = string.match(args, "(%a+)\\(%d+)\\(%d+)")

	self:DisableGameButton("Start")
	self:DisableGameButton("RollValue")
	self:DisableGameButton("Channel")
	self:DisableGameButton("LastCall")
	self:DisableGameButton("Reset")
	self:DisableGameButton("Close")

	self.Window.GameSettings:Hide()
	self.Window.PlayButtons:Show()

	self.Host = Leader
	self.GameWager = tonumber(Wager)
end

GambleBuddy.Events.ResetGame = function(self)
	self:RemoveAllPlayers()

	self:EnableGameButton("Start")

	self.Window.PlayButtons:Hide()
	self.Window.GameSettings:Show()

	self.Host = nil
	self.GameWager = self.Settings.RollValue
end

GambleBuddy.Events.AddPlayer = function(self, args)
	local Name, GUID = string.match(args, "(%a+)\\(%S+)")

	self:AddPlayer(Name, GUID)
end

GambleBuddy.Events.RemovePlayer = function(self, name)
	self:RemovePlayer(name)
	self:AddStat("withdraw", 1)

	self.Window.Label:SetText(string.format("|cffFFC44DGamble|r|cffFFFFFFBuddy|r  (%s / %s)", self.Rolled or 0, #self.Players))
end

GambleBuddy.Events.PlayerRoll = function(self, args)
	local Name, Roll = string.match(args, "(%a+)\\(%d+)")

	for i = 1, #self.Players do
		if (self.Players[i].Name == Name and self.Players[i].Roll == 0) then
			Roll = tonumber(Roll)

			self.Players[i].Roll = Roll
			self.Players[i].RollValue:SetText(self:Comma(Roll))

			self.Players[i].Bar:SetMinMaxValues(0, self.GameWager)

			self.Players[i].Bar.Progress:SetChange(self.Players[i].Roll)
			self.Players[i].Bar.PlayIn:Play()
			self.Rolled = self.Rolled or 0 + 1

			if (Roll == self.GameWager and self.GameWager > 99) then
				PlaySoundFile(569593)
			end

			-- Update the header as well to display number of players
			self.Window.Label:SetText(string.format("|cffFFC44DGamble|r|cffFFFFFFBuddy|r  (%s / %s)", self.Rolled or 0, #self.Players))

			self:AddStat("rolls", 1)

			table.sort(self.Players, function(a, b)
				return a.Roll > b.Roll
			end)

			self:SortPlayerList()

			break
		end
	end
end

GambleBuddy.Events.GameEnded = function(self, args)
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

	-- If we're in silent, add the message
	--self:SendMessage(string.format("|cffFFC44DGamble|rBuddy: %s (%s) owes %s (%s) %s gold!", self.Result[2][1].DisplayName, self.Result[4], self.Result[1][1].DisplayName, self.Result[3], self:Comma(Earnings)))
end

GambleBuddy.Events.GameDraw = function(self)
	if self.Settings.PlaySounds then
		PlaySound(SOUNDKIT.LFG_DENIED)
	end

	self:AddStat("draw", 1)
end

GambleBuddy.Events.GameTie = function(self)

end

GambleBuddy.Events.Toggle = function(self) -- Just a testing event, remove for release
	if (not self.Window) then
		self:CreateWindow()
	end

	if (not self.Window:IsShown()) then
		self:ShowWindow()
	end
end

GambleBuddy.Events.Version = function(self, message)
	local Version = tonumber(message)

	if (Version > (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)("GambleBuddy", "Version")) then
		print(string.format("GambleBuddy: A new version is available (%s)", Version))
	end
end

function GambleBuddy:CHAT_MSG_ADDON(prefix, message, chattype, sender)
	sender = string.match(sender, "(%S+)-.-")

	if (prefix ~= "GambleBuddy" or sender == UnitName("player")) then
		return
	end

	local Event, Args = string.match(message, "^(%a+)\\(.+)$")

	if self.Events[Event] then
		self.Events[Event](self, Args)
	end
end

function GambleBuddy:SendEvent(event, args)
	if (self.Settings.Channel == 4) then
		return
	end

	print(self.Settings.Channel, self.ChannelSelections[self.Settings.Channel])

	local Message = string.format("%s\\%s", event, args or " ")

	CT:SendAddonMessage("NORMAL", "GambleBuddy", Message, self.ChannelSelections[self.Settings.Channel])
end

GambleBuddy:RegisterEvent("CHAT_MSG_ADDON")

C_ChatInfo.RegisterAddonMessagePrefix("GambleBuddy")