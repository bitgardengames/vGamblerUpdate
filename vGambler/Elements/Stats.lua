local Name, AddOn = ...
local vGambler = AddOn.vGambler
local L = AddOn.L

local table = table
local string = string
local next = next
local tonumber = tonumber

-- AFTER TESTING IS DONE, DON'T TRACK STATS FOR TEST PLAYERS.

-- Using a lot of tables in this file, so recycle as much as I can to keep a low overhead
local Session = {}
local PlayerSession = {}
local StatLines = {}
local FreeStatLines = {}
local StatsSorter = {}
local FreeStatTables = {}
local LastSorter
local SortDir = 1
local SortSetting = "Earnings"
local DashboardToggles = {}

function vGambler:GetAggregateStatData()
	return self.Settings.StatDisplay == true and Session or vGamblerData
end

function vGambler:GetPlayerStatData()
	return self.Settings.StatDisplay == true and PlayerSession or vGamblerPlayers
end

function vGambler:AddStat(stat, value)
	if (not vGamblerData) then
		vGamblerData = {}
	end

	if (not vGamblerData[stat]) then
		vGamblerData[stat] = 0
	end

	if (not Session[stat]) then
		Session[stat] = 0
	end

	Session[stat] = Session[stat] + value
	vGamblerData[stat] = vGamblerData[stat] + value

	self:UpdateStat(stat)
end

function vGambler:AddMaxStat(stat, value)
	if (not vGamblerData) then
		vGamblerData = {}
	end

	if (not vGamblerData[stat]) then
		vGamblerData[stat] = 0
	end

	if (not Session[stat]) then
		Session[stat] = 0
	end

	Session[stat] = math.max(Session[stat], value)
	vGamblerData[stat] = math.max(vGamblerData[stat], value)

	self:UpdateStat(stat)
end

function vGambler:AddPlayerStat(name, stat, value)
	if (not vGamblerPlayers) then
		vGamblerPlayers = {}
	end

	if (not vGamblerPlayers[name]) then
		vGamblerPlayers[name] = {}
	end

	if (not vGamblerPlayers[name][stat]) then
		vGamblerPlayers[name][stat] = 0
	end

	if (not PlayerSession[name]) then
		PlayerSession[name] = {}
	end

	if (not PlayerSession[name][stat]) then
		PlayerSession[name][stat] = 0
	end

	vGamblerPlayers[name][stat] = vGamblerPlayers[name][stat] + value
	PlayerSession[name][stat] = PlayerSession[name][stat] + value
end

function vGambler:AddPlayerMaxStat(name, stat, value)
	if (not vGamblerPlayers) then
		vGamblerPlayers = {}
	end

	if (not vGamblerPlayers[name]) then
		vGamblerPlayers[name] = {}
	end

	if (not vGamblerPlayers[name][stat]) then
		vGamblerPlayers[name][stat] = 0
	end

	if (not PlayerSession[name]) then
		PlayerSession[name] = {}
	end

	if (not PlayerSession[name][stat]) then
		PlayerSession[name][stat] = 0
	end

	vGamblerPlayers[name][stat] = math.max(vGamblerPlayers[name][stat], value)
	PlayerSession[name][stat] = math.max(PlayerSession[name][stat], value)
end

function vGambler:RecordWinningStreak(winner, loser, players)
	local Participants = {}

	for _, Player in ipairs(players or {}) do
		if Player.name then
			Participants[Player.name] = true
		end
	end

	if winner and winner ~= "Draw" then
		Participants[winner] = true
	end

	if loser and loser ~= "Draw" then
		Participants[loser] = true
	end

	for PlayerName in next, Participants do
		vGamblerPlayers = vGamblerPlayers or {}
		vGamblerPlayers[PlayerName] = vGamblerPlayers[PlayerName] or {}
		PlayerSession[PlayerName] = PlayerSession[PlayerName] or {}

		if PlayerName == winner then
			local PlayerData = vGamblerPlayers[PlayerName]
			local SessionData = PlayerSession[PlayerName]

			PlayerData.currentstreak = (PlayerData.currentstreak or 0) + 1
			PlayerData.winningstreak = math.max(PlayerData.winningstreak or 0, PlayerData.currentstreak)
			SessionData.currentstreak = (SessionData.currentstreak or 0) + 1
			SessionData.winningstreak = math.max(SessionData.winningstreak or 0, SessionData.currentstreak)
		else
			vGamblerPlayers[PlayerName].currentstreak = 0
			PlayerSession[PlayerName].currentstreak = 0
		end
	end
end

vGambler.SortStats = {
	Name = function(dir)
		if (dir and dir == 0) then
			table.sort(StatsSorter, function(a, b)
				local A = string.match(a[1], "|c%x%x%x%x%x%x%x%x(.-)|r") or a[1]
				local B = string.match(b[1], "|c%x%x%x%x%x%x%x%x(.-)|r") or b[1]

				return A > B
			end)
		else
			table.sort(StatsSorter, function(a, b)
				local A = string.match(a[1], "|c%x%x%x%x%x%x%x%x(.-)|r") or a[1]
				local B = string.match(b[1], "|c%x%x%x%x%x%x%x%x(.-)|r") or b[1]

				return A < B
			end)
		end
	end,

	Wins = function(dir)
		if (dir and dir == 0) then
			table.sort(StatsSorter, function(a, b)
				return a[2] < b[2]
			end)
		else
			table.sort(StatsSorter, function(a, b)
				return a[2] > b[2]
			end)
		end
	end,

	WinPercent = function(dir)
		if (dir and dir == 0) then
			table.sort(StatsSorter, function(a, b)
				return a[3] < b[3]
			end)
		else
			table.sort(StatsSorter, function(a, b)
				return a[3] > b[3]
			end)
		end
	end,

	Earnings = function(dir)
		if (dir and dir == 0) then
			table.sort(StatsSorter, function(a, b)
				return a[4] < b[4]
			end)
		else
			table.sort(StatsSorter, function(a, b)
				return a[4] > b[4]
			end)
		end
	end,
}

function vGambler:ResetStats()
	vGamblerPlayers = nil
	table.wipe(PlayerSession)

	self:UpdateBasicStats()
	print(L.STATS_RESET)
end

function vGambler:UpdateStatDisplay(value)
	vGamblerSettings.StatDisplay = value
	vGambler.Settings.StatDisplay = value

	for i = 1, #DashboardToggles do
		local Toggle = DashboardToggles[i]
		Toggle.Toggled = value

		if value then
			Toggle.Box:SetBackdropColor(vGambler:HexToRGB("FFC44D"))
			Toggle.Box:SetBackdropBorderColor(vGambler:HexToRGB("FFC44D"))
		else
			Toggle.Box:SetBackdropColor(0.125, 0.133, 0.145)
			Toggle.Box:SetBackdropBorderColor(0.125, 0.133, 0.145)
		end
	end

	vGambler:UpdateBasicStats()
	vGambler:UpdateStatGrid()
end

function vGambler:SetupDashboardHeader(page)
	local HeaderBar = CreateFrame("Frame", nil, page, "BackdropTemplate")
	HeaderBar:SetSize(page:GetWidth(), 32)
	HeaderBar:SetPoint("TOPLEFT", page, 0, 0)
	HeaderBar:SetBackdrop(self.MediumBackdrop)
	HeaderBar:SetBackdropColor(0.184, 0.192, 0.211)
	HeaderBar:SetBackdropBorderColor(0.184, 0.192, 0.211)

	HeaderBar.Label = HeaderBar:CreateFontString(nil, "OVERLAY")
	HeaderBar.Label:SetPoint("LEFT", HeaderBar, 7, -0.5)
	HeaderBar.Label:SetFont(self.Font, self.Settings.FontSize)
	HeaderBar.Label:SetText(string.format("|cffFFC44D%s|r", L.STAT_VIEW))
	HeaderBar.Label:SetShadowColor(0.029, 0.029, 0.051)
	HeaderBar.Label:SetShadowOffset(0, -1)

	local SessionToggle = CreateFrame("Frame", nil, HeaderBar)
	SessionToggle:SetSize(173, 32)
	SessionToggle:SetPoint("RIGHT", HeaderBar, "RIGHT", 0, 0)
	local Toggle = self:AddGameCheckbox({}, SessionToggle, L.SESSION_STATS, self.Settings.StatDisplay, self.UpdateStatDisplay)
	Toggle:SetPoint("TOPLEFT", SessionToggle, 4, -4)
	table.insert(DashboardToggles, Toggle)

	return HeaderBar
end

function vGambler:AddLongStatLine(parent)
	if FreeStatLines[1] then -- Get an old line, only make new ones as needed
		local Line = table.remove(FreeStatLines, 1)

		Line:Show()
		table.insert(StatLines, Line)

		return
	end

	local Line = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Line:SetSize(parent:GetWidth() - 24, 24)
	Line:SetBackdrop(self.SmallBackdrop)
	Line:SetBackdropColor(0.184, 0.192, 0.211)
	Line:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Line:SetScript("OnMouseWheel", self.StatLineOnMouseWheel)
	Line:SetScript("OnEnter", self.WindowButtonOnEnter)
	Line:SetScript("OnLeave", self.WindowButtonOnLeave)

	Line.Name = Line:CreateFontString(nil, "OVERLAY")
	Line.Name:SetPoint("LEFT", Line, 5, -0.5)
	Line.Name:SetFont(self.Font, self.Settings.FontSize)
	Line.Name:SetJustifyH("LEFT")
	Line.Name:SetShadowColor(0.029, 0.029, 0.051)
	Line.Name:SetShadowOffset(0, -1)

	Line.Wins = Line:CreateFontString(nil, "OVERLAY")
	Line.Wins:SetPoint("LEFT", Line, 120, -0.5)
	Line.Wins:SetFont(self.Font, self.Settings.FontSize)
	Line.Wins:SetJustifyH("LEFT")
	Line.Wins:SetShadowColor(0.029, 0.029, 0.051)
	Line.Wins:SetShadowOffset(0, -1)

	Line.WinPercent = Line:CreateFontString(nil, "OVERLAY")
	Line.WinPercent:SetPoint("RIGHT", Line, -106, -0.5)
	Line.WinPercent:SetJustifyH("RIGHT")
	Line.WinPercent:SetFont(self.Font, self.Settings.FontSize)
	Line.WinPercent:SetShadowColor(0.029, 0.029, 0.051)
	Line.WinPercent:SetShadowOffset(0, -1)

	Line.Earnings = Line:CreateFontString(nil, "OVERLAY")
	Line.Earnings:SetPoint("RIGHT", Line, -5, -0.5)
	Line.Earnings:SetJustifyH("RIGHT")
	Line.Earnings:SetFont(self.Font, self.Settings.FontSize)
	Line.Earnings:SetShadowColor(0.029, 0.029, 0.051)
	Line.Earnings:SetShadowOffset(0, -1)

	table.insert(StatLines, Line)
end

function vGambler:ResetStatLines()
	local Line

	for i = #StatsSorter, 1, -1 do
		table.insert(FreeStatTables, table.remove(StatsSorter, i))
	end

	for i = #StatLines, 1, -1 do
		Line = table.remove(StatLines, i)
		Line:Hide()

		table.insert(FreeStatLines, Line)
	end
end

function vGambler:GetStatTable()
	if FreeStatTables[1] then
		return table.remove(FreeStatTables, 1)
	else
		return {}
	end
end

function vGambler:UpdateStatGrid()
	vGambler:ResetStatLines()
	vGambler:PopulateStatLines(SortDir)
end

function vGambler:PopulateStatLines(direction)
	local PlayerData = self.Settings.StatDisplay == true and PlayerSession or vGamblerPlayers
	local Page = vGambler:GetPage("Leaderboard")

	for user, data in next, PlayerData do
		if (data.wins or data.losses) then -- Filter players who haven't won or lost
			local StatData = vGambler:GetStatTable()
			local Percent

			if (data.wins and data.games) then
				Percent = tonumber(string.format("%.2f", (data.wins / data.games) * 100))
			end

			StatData[1] = user
			StatData[2] = data.wins or 0
			StatData[3] = Percent or 0
			StatData[4] = (data.earnings or 0) - (data.loss or 0)

			table.insert(StatsSorter, StatData)
		end
	end

	if vGambler.SortStats[SortSetting] then
		vGambler.SortStats[SortSetting](direction)
	else
		vGambler.SortStats.Earnings(1)
	end

	for i = 1, #StatsSorter do
		vGambler:AddLongStatLine(Page.StatArea)
		StatLines[i].Name:SetText(string.format(L.NUMBERED_PLAYER, i, StatsSorter[i][1]))
		StatLines[i].Wins:SetText(StatsSorter[i][2])
		StatLines[i].WinPercent:SetText(string.format(L.PERCENT, StatsSorter[i][3]))
		StatLines[i].Earnings:SetText(string.format(L.GOLD_AMOUNT, vGambler:Comma(StatsSorter[i][4])))
	end

	vGambler:SetStatScrollOffset(1)
end

function vGambler:SetStatScrollOffset(offset)
	self.Offset = offset

	if (self.Offset <= 1) then
		self.Offset = 1
	elseif (self.Offset > (#StatsSorter - 9)) then
		self.Offset = self.Offset - 1
	end

	local First
	local Page = vGambler:GetPage("Leaderboard")

	Page.StatAreaScroll:SetMinMaxValues(1, math.max(1, #StatsSorter - 9))
	Page.StatAreaScroll:SetValue(self.Offset)

	for i = 1, #StatsSorter do
		if StatLines[i] then
			StatLines[i]:ClearAllPoints()

			if (i >= self.Offset) and (i <= self.Offset + 9) then
				if (not First) then
					StatLines[i]:SetPoint("TOPLEFT", Page.StatArea, 4, -32)
					First = i
				else
					StatLines[i]:SetPoint("TOPLEFT", StatLines[i-1], "BOTTOMLEFT", 0, -4)
				end

				StatLines[i]:Show()
			else
				StatLines[i]:Hide()
			end
		end
	end
end

function vGambler:StatScrollOnValueChanged(offset)
	vGambler:SetStatScrollOffset(floor(offset + 0.5))
end

function vGambler:StatScrollOnMouseWheel(delta)
	if (delta > 0) then -- Up
		self.Offset = self.Offset - 1

		if (self.Offset <= 1) then
			self.Offset = 1
		end
	else -- Down
		self.Offset = self.Offset + 1

		if (self.Offset > (#StatsSorter - 9)) then
			self.Offset = self.Offset - 1
		end
	end

	vGambler:SetStatScrollOffset(self.Offset)
	self:SetValue(self.Offset)
end

function vGambler:StatLineOnMouseWheel(delta)
	local Page = vGambler:GetPage("Leaderboard")
	local ScrollBar = Page.StatAreaScroll

	if (delta > 0) then -- Up
		ScrollBar.Offset = ScrollBar.Offset - 1

		if (ScrollBar.Offset <= 1) then
			ScrollBar.Offset = 1
		end
	else -- Down
		ScrollBar.Offset = ScrollBar.Offset + 1

		if (ScrollBar.Offset > (#StatsSorter - 9)) then
			ScrollBar.Offset = ScrollBar.Offset - 1
		end
	end

	vGambler:SetStatScrollOffset(ScrollBar.Offset)
	ScrollBar:SetValue(ScrollBar.Offset)
end

function vGambler:OnStatCategoryMouseUp()
	if (LastSorter and LastSorter == self) then -- If we're re-clicking on a category, toggle the direction. Otherwise if clicking a new category sort down by default
		if (SortDir == 1) then
			SortDir = 0
		else
			SortDir = 1
		end
	else
		SortDir = 1
	end

	SortSetting = self.SortMode

	vGambler:ResetStatLines()
	vGambler:PopulateStatLines(SortDir)

	LastSorter = self
end

function vGambler:StatCategoryOnEnter()
	self.Label:SetText((string.gsub(self.LabelText, "|cff%x%x%x%x%x%x", "|cffffffff")))
end

function vGambler:StatCategoryOnLeave()
	self.Label:SetText(self.LabelText)
end

function vGambler:SetupStatsPage(page)
	local HeaderBar = self:SetupDashboardHeader(page)

	local StatArea = CreateFrame("Frame", nil, page, "BackdropTemplate")
	StatArea:SetPoint("TOPLEFT", HeaderBar, "BOTTOMLEFT", 0, -6)
	StatArea:SetPoint("BOTTOMRIGHT", page, 0, 0)
	StatArea:SetBackdrop(self.MediumBackdrop)
	StatArea:SetBackdropBorderColor(0.184, 0.192, 0.211)
	StatArea:SetBackdropColor(0.184, 0.192, 0.211)

	StatArea.Header = CreateFrame("Frame", nil, StatArea, "BackdropTemplate")
	StatArea.Header:SetSize(page:GetWidth() - 8, 24)
	StatArea.Header:SetPoint("TOPLEFT", StatArea, 4, -4)
	StatArea.Header:SetBackdrop(self.SmallBackdrop)
	StatArea.Header:SetBackdropColor(0.25, 0.266, 0.294)
	StatArea.Header:SetBackdropBorderColor(0.25, 0.266, 0.294)

	local Player = CreateFrame("Frame", nil, StatArea.Header)
	Player:SetSize(111, 24)
	Player:SetPoint("LEFT", StatArea.Header, 0, 0)
	Player.SortMode = "Name"
	Player:SetScript("OnMouseUp", self.OnStatCategoryMouseUp)
	Player:SetScript("OnEnter", self.StatCategoryOnEnter)
	Player:SetScript("OnLeave", self.StatCategoryOnLeave)
	Player:HookScript("OnMouseUp", self.WindowButtonMouseUp)
	Player:HookScript("OnMouseDown", self.WindowButtonMouseDown)

	Player.Label = Player:CreateFontString(nil, "OVERLAY")
	Player.Label:SetPoint("LEFT", Player, 5, -1)
	Player.Label:SetFont(self.Font, self.Settings.FontSize)
	Player.Label:SetShadowColor(0.029, 0.029, 0.051)
	Player.Label:SetShadowOffset(0, -1)
	Player.LabelText = L.PLAYER_HEADER
	Player.Label:SetText(Player.LabelText)

	local Wins = CreateFrame("Frame", nil, StatArea.Header)
	Wins:SetSize(67, 24)
	Wins:SetPoint("LEFT", Player, "RIGHT", 4, 0)
	Wins.SortMode = "Wins"
	Wins:SetScript("OnMouseUp", self.OnStatCategoryMouseUp)
	Wins:SetScript("OnEnter", self.StatCategoryOnEnter)
	Wins:SetScript("OnLeave", self.StatCategoryOnLeave)
	Wins:HookScript("OnMouseUp", self.WindowButtonMouseUp)
	Wins:HookScript("OnMouseDown", self.WindowButtonMouseDown)

	Wins.Label = Wins:CreateFontString(nil, "OVERLAY")
	Wins.Label:SetPoint("LEFT", Wins, 5, -1)
	Wins.Label:SetFont(self.Font, self.Settings.FontSize)
	Wins.Label:SetShadowColor(0.029, 0.029, 0.051)
	Wins.Label:SetShadowOffset(0, -1)
	Wins.LabelText = L.WINS_HEADER
	Wins.Label:SetText(Wins.LabelText)

	local WinPercent = CreateFrame("Frame", nil, StatArea.Header)
	WinPercent:SetSize(87, 24)
	WinPercent:SetPoint("LEFT", Wins, "RIGHT", 4, 0)
	WinPercent.SortMode = "WinPercent"
	WinPercent:SetScript("OnMouseUp", self.OnStatCategoryMouseUp)
	WinPercent:SetScript("OnEnter", self.StatCategoryOnEnter)
	WinPercent:SetScript("OnLeave", self.StatCategoryOnLeave)
	WinPercent:HookScript("OnMouseUp", self.WindowButtonMouseUp)
	WinPercent:HookScript("OnMouseDown", self.WindowButtonMouseDown)

	WinPercent.Label = WinPercent:CreateFontString(nil, "OVERLAY")
	WinPercent.Label:SetPoint("LEFT", WinPercent, 5, -1)
	WinPercent.Label:SetFont(self.Font, self.Settings.FontSize)
	WinPercent.Label:SetShadowColor(0.029, 0.029, 0.051)
	WinPercent.Label:SetShadowOffset(0, -1)
	WinPercent.LabelText = L.WIN_PERCENT_HEADER
	WinPercent.Label:SetText(WinPercent.LabelText)

	local Earnings = CreateFrame("Frame", nil, StatArea.Header)
	Earnings:SetSize(68, 24)
	Earnings:SetPoint("LEFT", WinPercent, "RIGHT", 4, 0)
	Earnings.SortMode = "Earnings"
	Earnings:SetScript("OnMouseUp", self.OnStatCategoryMouseUp)
	Earnings:SetScript("OnEnter", self.StatCategoryOnEnter)
	Earnings:SetScript("OnLeave", self.StatCategoryOnLeave)
	Earnings:HookScript("OnMouseUp", self.WindowButtonMouseUp)
	Earnings:HookScript("OnMouseDown", self.WindowButtonMouseDown)

	Earnings.Label = Earnings:CreateFontString(nil, "OVERLAY")
	Earnings.Label:SetPoint("LEFT", Earnings, 5, -1)
	Earnings.Label:SetFont(self.Font, self.Settings.FontSize)
	Earnings.Label:SetShadowColor(0.029, 0.029, 0.051)
	Earnings.Label:SetShadowOffset(0, -1)
	Earnings.LabelText = L.EARNINGS_HEADER
	Earnings.Label:SetText(Earnings.LabelText)

	page.StatArea = StatArea

	local StatAreaScroll = CreateFrame("Slider", nil, StatArea)
	StatAreaScroll:SetWidth(12)
	StatAreaScroll:SetPoint("TOPRIGHT", StatArea.Header, "BOTTOMRIGHT", 1, 0)
	StatAreaScroll:SetPoint("BOTTOMRIGHT", StatArea, -3, 16)
	StatAreaScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
	StatAreaScroll:SetOrientation("VERTICAL")
	StatAreaScroll:SetValueStep(1)
	StatAreaScroll:SetObeyStepOnDrag(true)
	StatAreaScroll:SetMinMaxValues(1, 1)
	StatAreaScroll:SetValue(1)
	StatAreaScroll.Offset = 1
	StatAreaScroll:SetScript("OnMouseWheel", self.StatScrollOnMouseWheel)
	StatAreaScroll:SetScript("OnValueChanged", self.StatScrollOnValueChanged)
	StatAreaScroll:SetScript("OnEnter", self.ScrollBarOnEnter)
	StatAreaScroll:SetScript("OnLeave", self.ScrollBarOnLeave)
	StatAreaScroll:SetScript("OnMouseDown", self.ScrollBarOnMouseDown)
	StatAreaScroll:SetScript("OnMouseUp", self.ScrollBarOnMouseUp)

	page.StatAreaScroll = StatAreaScroll

	local StatAreaScrollThumb = StatAreaScroll:GetThumbTexture()
	StatAreaScrollThumb:SetSize(32, 32)
	StatAreaScrollThumb:SetVertexColor(0.25, 0.266, 0.294)

	if (self.Settings.UIStyle == 1) then
		StatAreaScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
		StatAreaScrollThumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
	else
		StatAreaScrollThumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
	end

	local StatWidthScroll = CreateFrame("Slider", nil, StatArea)
	StatWidthScroll:SetHeight(12)
	StatWidthScroll:SetPoint("BOTTOMLEFT", StatArea, 1, 4)
	StatWidthScroll:SetPoint("BOTTOMRIGHT", StatArea, -17, 4)
	StatWidthScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumbHoriz.tga")
	StatWidthScroll:SetOrientation("HORIZONTAL")
	StatWidthScroll:SetValueStep(1)
	StatWidthScroll:SetObeyStepOnDrag(true)
	StatWidthScroll:SetMinMaxValues(1, 1)
	StatWidthScroll:SetValue(1)
	StatWidthScroll.Offset = 1
	--StatWidthScroll:SetScript("OnMouseWheel", self.StatScrollOnMouseWheel)
	--StatWidthScroll:SetScript("OnValueChanged", self.StatScrollOnValueChanged)
	StatWidthScroll:SetScript("OnEnter", self.ScrollBarOnEnter)
	StatWidthScroll:SetScript("OnLeave", self.ScrollBarOnLeave)
	StatWidthScroll:SetScript("OnMouseDown", self.ScrollBarOnMouseDown)
	StatWidthScroll:SetScript("OnMouseUp", self.ScrollBarOnMouseUp)

	page.StatWidthScroll = StatWidthScroll

	local StatWidthScrollThumb = StatWidthScroll:GetThumbTexture()
	StatWidthScrollThumb:SetSize(32, 32)
	StatWidthScrollThumb:SetVertexColor(0.25, 0.266, 0.294)

	if (self.Settings.UIStyle == 1) then
		StatWidthScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumbHoriz.tga")
		StatWidthScrollThumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumbHoriz.tga")
	else
		StatWidthScrollThumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumbHoriz.tga")
	end

	self:PopulateStatLines(1)
end

function vGambler:UpdateStat(stat)
	local StatsPage = self:GetPage("Overview")
	local Data = self.Settings.StatDisplay == true and Session or vGamblerData

	if (StatsPage.Stats[stat] and self.StatMethods[stat]) then
		self.StatMethods[stat](Data, StatsPage.Stats[stat])
	end
end

function vGambler:ResetGeneralStats()
	if vGamblerData then
		local Page = vGambler:GetPage("Overview")

		for stat in next, Page.Stats do
			Page.Stats[stat].Right:SetText(0)
		end

		vGamblerData = {}
	end
end

function vGambler:ResetPlayerStats()
	if vGamblerPlayers then
		vGamblerPlayers = {}
		table.wipe(PlayerSession)
		
		vGambler:UpdateBasicStats()
		vGambler:UpdateStatGrid()
	end
end
