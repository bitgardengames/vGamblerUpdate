local Name, AddOn = ...
local vGambler = AddOn.vGambler
local L = AddOn.L

local table = table
local string = string
local tonumber = tonumber

local function GetPlayerRecord(field)
	local RecordName
	local RecordValue = 0

	for PlayerName, PlayerData in next, vGambler:GetPlayerStatData() or {} do
		local Value = tonumber(PlayerData[field]) or 0

		if Value > RecordValue or (Value == RecordValue and Value > 0 and (not RecordName or PlayerName < RecordName)) then
			RecordName = PlayerName
			RecordValue = Value
		end
	end

	return RecordName, RecordValue
end

vGambler.StatMethods = {	-- Basic stats, just add optional formatting to some of them.
	games = function(stat, data)
		stat.Left:SetText(L.GAMES)
		stat.Right:SetText(data and vGambler:Comma(data.games) or 0)
	end,

	rolls = function(stat, data)
		stat.Left:SetText(L.ROLLS)
		stat.Right:SetText(data and vGambler:Comma(data.rolls) or 0)
	end,

	ties = function(stat, data)
		stat.Left:SetText(L.TIED_GAMES)
		stat.Right:SetText(data and vGambler:Comma(data.ties) or 0)
	end,

	draws = function(stat, data)
		stat.Left:SetText(L.DRAW_GAMES)
		stat.Right:SetText(data and vGambler:Comma(data.draw) or 0)
	end,

	totalgold = function(stat, data)
		stat.Left:SetText(L.GOLD_WON)
		stat.Right:SetText(string.format(L.GOLD_AMOUNT, data and vGambler:Comma(data.totalgold) or 0))
	end,

	topwager = function(stat, data)
		stat.Left:SetText(L.HIGHEST_WAGER)
		stat.Right:SetText(data and vGambler:Comma(data.topwager) or 0)
	end,

	topwin = function(stat, data)
		stat.Left:SetText(L.HIGHEST_ROLL)
		stat.Right:SetText(data and vGambler:Comma(data.topwin) or 0)
	end,

	toppayout = function(stat, data)
		stat.Left:SetText(L.HIGHEST_PAYOUT)
		stat.Right:SetText(string.format(L.GOLD_AMOUNT, data and vGambler:Comma(data.toppayout) or 0))
	end,

	uniqueplayers = function(stat, data)
		local Count = 0
		local PlayerData = vGambler:GetPlayerStatData()

		if PlayerData then
			if (#PlayerData == 0) then
				Count = 0
			else
				for user in next, PlayerData do
					Count = Count + 1
				end
			end
		end

		stat.Left:SetText(L.UNIQUE_PLAYERS)
		stat.Right:SetText(Count)
	end,

	sessiongames = function(stat, data)
		stat.Left:SetText(L.HIGHEST_GAME_STREAK)
		stat.Right:SetText(data and data.sessiongames or 0)
	end,

	biggestwinner = function(stat)
		local PlayerName, Value = GetPlayerRecord("earnings")
		stat.Left:SetText(PlayerName or L.NO_RECORD)
		stat.Right:SetText(PlayerName and string.format(L.GOLD_AMOUNT, vGambler:Comma(Value)) or "")
	end,

	biggestloser = function(stat)
		local PlayerName, Value = GetPlayerRecord("loss")
		stat.Left:SetText(PlayerName or L.NO_RECORD)
		stat.Right:SetText(PlayerName and string.format(L.GOLD_AMOUNT, vGambler:Comma(Value)) or "")
	end,
}

function vGambler:AddStatLine(t, parent, id)
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

function vGambler:SetupAboutPage(page)
	page.General = {}
	page.Performance = {}
	page.Stats = {}

	local HeaderBar = self:SetupDashboardHeader(page)
	local PanelWidth = (page:GetWidth() - 6) / 2
	local General = CreateFrame("Frame", nil, page, "BackdropTemplate")
	General:SetPoint("TOPLEFT", HeaderBar, "BOTTOMLEFT", 0, -6)
	General:SetPoint("BOTTOMLEFT", page, 0, 0)
	General:SetWidth(PanelWidth)
	General:SetBackdrop(self.MediumBackdrop)
	General:SetBackdropColor(0.184, 0.192, 0.211)
	General:SetBackdropBorderColor(0.184, 0.192, 0.211)

	local Performance = CreateFrame("Frame", nil, page, "BackdropTemplate")
	Performance:SetPoint("TOPRIGHT", HeaderBar, "BOTTOMRIGHT", 0, -6)
	Performance:SetPoint("BOTTOMRIGHT", page, 0, 0)
	Performance:SetWidth(PanelWidth)
	Performance:SetBackdrop(self.MediumBackdrop)
	Performance:SetBackdropColor(0.184, 0.192, 0.211)
	Performance:SetBackdropBorderColor(0.184, 0.192, 0.211)

	self:AddGameHeader(page.General, General, L.GENERAL_STATS)
	for _, stat in ipairs({"games", "rolls", "ties", "draws", "totalgold", "uniqueplayers"}) do
		page.Stats[stat] = self:AddStatLine(page.General, General, stat)
	end
	self:SortButtonList(page.General, General)

	self:AddGameHeader(page.Performance, Performance, L.TOP_STATS)
	for _, stat in ipairs({"topwager", "topwin", "toppayout", "sessiongames"}) do
		page.Stats[stat] = self:AddStatLine(page.Performance, Performance, stat)
	end
	self:AddGameHeader(page.Performance, Performance, L.BIGGEST_WINNER)
	page.Stats["biggestwinner"] = self:AddStatLine(page.Performance, Performance, "biggestwinner")
	self:AddGameHeader(page.Performance, Performance, L.BIGGEST_LOSER)
	page.Stats["biggestloser"] = self:AddStatLine(page.Performance, Performance, "biggestloser")
	self:SortButtonList(page.Performance, Performance)

	self:UpdateBasicStats()
end

function vGambler:UpdateStat(stat)
	local StatsPage = self:GetPage("Overview")
	local Data = self:GetAggregateStatData()

	if (StatsPage.Stats[stat] and self.StatMethods[stat]) then
		self.StatMethods[stat](StatsPage.Stats[stat], Data)
	end

	-- Player changes can affect any of the dashboard records.
	for _, recordStat in ipairs({"biggestwinner", "biggestloser"}) do
		if StatsPage.Stats[recordStat] then
			self.StatMethods[recordStat](StatsPage.Stats[recordStat], Data)
		end
	end
end

function vGambler:UpdateBasicStats()
	local Page = self:GetPage("Overview")
	local Data = self:GetAggregateStatData()

	for stat in next, Page.Stats do
		if self.StatMethods[stat] then
			self.StatMethods[stat](Page.Stats[stat], Data)
		end
	end
end
