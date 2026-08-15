local Name, AddOn = ...
local GambleBuddy = AddOn.GambleBuddy

local table = table
local string = string

GambleBuddy.StatMethods = {	-- Basic stats, just add optional formatting to some of them.
	games = function(stat, data)
		stat.Left:SetText("Games:")
		stat.Right:SetText(data and GambleBuddy:Comma(data.games) or 0)
	end,

	rolls = function(stat, data)
		stat.Left:SetText("Rolls:")
		stat.Right:SetText(data and GambleBuddy:Comma(data.rolls) or 0)
	end,

	ties = function(stat, data)
		stat.Left:SetText("Tied Games:")
		stat.Right:SetText(data and GambleBuddy:Comma(data.ties) or 0)
	end,

	draws = function(stat, data)
		stat.Left:SetText("Draw Games:")
		stat.Right:SetText(data and GambleBuddy:Comma(data.draw) or 0)
	end,

	totalgold = function(stat, data)
		stat.Left:SetText("Gold Won:")
		stat.Right:SetText(string.format("%s|cffffe02eg|r", data and GambleBuddy:Comma(data.totalgold) or 0))
	end,

	topwager = function(stat, data)
		stat.Left:SetText("Highest Wager:")
		stat.Right:SetText(data and GambleBuddy:Comma(data.topwager) or 0)
	end,

	topwin = function(stat, data)
		stat.Left:SetText("Highest Roll:")
		stat.Right:SetText(data and GambleBuddy:Comma(data.topwin) or 0)
	end,

	toppayout = function(stat, data)
		stat.Left:SetText("Highest Payout:")
		stat.Right:SetText(string.format("%s|cffffe02eg|r", data and GambleBuddy:Comma(data.toppayout) or 0))
	end,

	uniqueplayers = function(stat, data)
		local Count = 0
		local PlayerData = GambleBuddy.Settings.StatDisplay == true and PlayerSession or GambleBuddyPlayers

		if PlayerData then
			if (#PlayerData == 0) then
				Count = 0
			else
				for user in next, PlayerData do
					Count = Count + 1
				end
			end
		end

		stat.Left:SetText("Unique Players")
		stat.Right:SetText(Count)
	end,

	sessiongames = function(stat, data)
		stat.Left:SetText("Highest game streak:")
		stat.Right:SetText(data and data.sessiongames or 0)
	end,
}

function GambleBuddy:AddStatLine(t, parent, id)
	local Line = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Line:SetSize(parent:GetWidth() - 8, 24)
	Line:SetBackdrop(self.SmallBackdrop)
	Line:SetBackdropColor(0.184, 0.192, 0.211)
	Line:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Line:SetScript("OnEnter", self.WindowButtonOnEnter)
	Line:SetScript("OnLeave", self.WindowButtonOnLeave)
	Line.ID = id

	Line.Left = Line:CreateFontString(nil, "OVERLAY")
	Line.Left:SetPoint("LEFT", Line, 5, -0.5)
	Line.Left:SetFont(self.Font, self.Settings.FontSize)
	Line.Left:SetShadowColor(0.029, 0.029, 0.051)
	Line.Left:SetShadowOffset(0, -1)

	Line.Right = Line:CreateFontString(nil, "OVERLAY")
	Line.Right:SetPoint("RIGHT", Line, -5, -0.5)
	Line.Right:SetJustifyH("RIGHT")
	Line.Right:SetFont(self.Font, self.Settings.FontSize)
	Line.Right:SetShadowColor(0.029, 0.029, 0.051)
	Line.Right:SetShadowOffset(0, -1)

	table.insert(t, Line)

	return Line
end

function GambleBuddy:SetupAboutPage(page)
	page.Game = {}
	page.Stats = {}

	-- Game stats
	local GameInfo = CreateFrame("Frame", nil, page, "BackdropTemplate")
	GameInfo:SetSize(173, 318)
	GameInfo:SetPoint("TOPLEFT", page, 0, 0)
	GameInfo:SetBackdrop(self.MediumBackdrop)
	GameInfo:SetBackdropBorderColor(0, 0, 0)
	GameInfo:SetBackdropColor(0.184, 0.192, 0.211)
	GameInfo:SetBackdropBorderColor(0.184, 0.192, 0.211)

	self:AddGameHeader(page.Game, GameInfo, "General Stats")
	page.Stats["games"] = self:AddStatLine(page.Game, GameInfo, "games")
	page.Stats["rolls"] = self:AddStatLine(page.Game, GameInfo, "rolls")
	page.Stats["ties"] = self:AddStatLine(page.Game, GameInfo, "ties")
	page.Stats["draws"] = self:AddStatLine(page.Game, GameInfo, "draws")
	page.Stats["totalgold"] = self:AddStatLine(page.Game, GameInfo, "totalgold")
	page.Stats["uniqueplayers"] = self:AddStatLine(page.Game, GameInfo, "uniqueplayers")

	self:AddGameHeader(page.Game, GameInfo, "Top Stats")
	page.Stats["topwager"] = self:AddStatLine(page.Game, GameInfo, "topwager")
	page.Stats["topwin"] = self:AddStatLine(page.Game, GameInfo, "topwin")
	page.Stats["toppayout"] = self:AddStatLine(page.Game, GameInfo, "toppayout")
	page.Stats["sessiongames"] = self:AddStatLine(page.Game, GameInfo, "sessiongames")

	self:SortButtonList(page.Game, GameInfo)

	self:UpdateBasicStats()
end

function GambleBuddy:UpdateStat(stat)
	local StatsPage = self:GetPage("About")
	local Data = self.Settings.StatDisplay == true and Session or GambleBuddyData

	if (StatsPage.Stats[stat] and self.StatMethods[stat]) then
		self.StatMethods[stat](StatsPage.Stats[stat], Data)
	end
end

function GambleBuddy:UpdateBasicStats()
	local Page = self:GetPage("About")
	local Data = self.Settings.StatDisplay == true and Session or GambleBuddyData

	for stat in next, Page.Stats do
		if self.StatMethods[stat] then
			self.StatMethods[stat](Page.Stats[stat], Data)
		end
	end
end