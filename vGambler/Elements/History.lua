local Name, AddOn = ...
local vGambler = AddOn.vGambler
local L = AddOn.L

local math = math
local table = table
local string = string
local date = date
local time = time

local HistoryLines = {}
local MaxMatchHistory = 50
local HistoryRefreshInterval = 30

-- Keep match history in a SavedVariables table so it survives reloads and new
-- sessions. The history is trimmed when new matches are added.
if (type(vGamblerHistory) ~= "table") then
	vGamblerHistory = {}
end

vGambler.MatchHistory = vGamblerHistory

function vGambler:FormatHistoryTimestamp(timestamp, currentTime)
	if (not timestamp) then
		return ""
	end

	currentTime = currentTime or time()
	local elapsed = currentTime - timestamp
	if (elapsed >= 0 and date("%Y%m%d", timestamp) == date("%Y%m%d", currentTime)) then
		if (elapsed < 60) then
			return L.MATCH_JUST_NOW
		elseif (elapsed < 3600) then
			return string.format(L.MATCH_MINUTES_AGO, math.floor(elapsed / 60))
		end

		return string.format(L.MATCH_HOURS_AGO, math.floor(elapsed / 3600))
	end

	return date(L.MATCH_HISTORY_DATE_FORMAT, timestamp)
end

function vGambler:AddMatchHistory(winner, loser, value, wager, players)
	while (#self.MatchHistory >= MaxMatchHistory) do
		table.remove(self.MatchHistory, 1)
	end

	table.insert(self.MatchHistory, {
		winner = winner,
		loser = loser,
		value = value,
		wager = wager,
		players = players,
		timestamp = time(),
	})

	self:UpdateHistory()
end

function vGambler:HistoryLineOnEnter()
	local Match = vGambler.MatchHistory[self.MatchIndex]

	if (not Match) then
		return
	end

	vGambler.WindowButtonOnEnter(self)
	vGambler.Tooltip:SetOwner(self, "ANCHOR_NONE")
	vGambler.Tooltip:SetPoint("LEFT", self, "RIGHT", 8, 0)
	vGambler.Tooltip:ClearLines()
	if Match.timestamp then
		vGambler.Tooltip:AddDoubleLine(L.MATCH_PLAYED, date(L.MATCH_DATE_FORMAT, Match.timestamp), 1, 1, 1, 1, 1, 1)
	end

	vGambler.Tooltip:AddLine(" ")

	for i = 1, #(Match.players or {}) do
		local Player = Match.players[i]
		vGambler.Tooltip:AddDoubleLine(string.format(L.PLAYER_ROLL, i, Player.name), vGambler:Comma(Player.roll), 1, 1, 1, 1, 1, 1)
	end

	vGambler.Tooltip:Show()
end

function vGambler:HistoryLineOnLeave()
	vGambler.WindowButtonOnLeave(self)
	vGambler.Tooltip:Hide()
end

function vGambler:SetHistoryScrollOffset(offset)
	local Page = self:GetPage("History")
	local Maximum = math.max(1, #self.MatchHistory - #HistoryLines + 1)
	local CurrentTime = time()

	offset = math.max(1, math.min(math.floor(offset + 0.5), Maximum))
	Page.HistoryScroll.Offset = offset
	Page.HistoryScroll:SetMinMaxValues(1, Maximum)
	Page.HistoryScroll:SetValue(offset)

	for i = 1, #HistoryLines do
		local MatchIndex = #self.MatchHistory - offset - i + 2
		local Match = self.MatchHistory[MatchIndex]
		local Line = HistoryLines[i]

		if Match then
			Line.MatchIndex = MatchIndex
			Line.Winner:SetText(Match.winner)
			Line.Loser:SetText(Match.loser)
			Line.Value:SetText(string.format(L.GOLD_AMOUNT, self:Comma(Match.value)))
			Line.Date:SetText(self:FormatHistoryTimestamp(Match.timestamp, CurrentTime))
			Line:Show()
		else
			Line:Hide()
		end
	end
end

function vGambler:HistoryPageOnUpdate(elapsed)
	self.HistoryRefreshElapsed = (self.HistoryRefreshElapsed or 0) + elapsed
	if (self.HistoryRefreshElapsed >= HistoryRefreshInterval) then
		self.HistoryRefreshElapsed = 0
		vGambler:SetHistoryScrollOffset(self.HistoryScroll.Offset)
	end
end

function vGambler:HistoryPageOnShow()
	self.HistoryRefreshElapsed = 0
	vGambler:SetHistoryScrollOffset(self.HistoryScroll.Offset)
end

function vGambler:HistoryScrollOnValueChanged(offset)
	vGambler:SetHistoryScrollOffset(offset)
end

function vGambler:HistoryScrollOnMouseWheel(delta)
	local ScrollBar = vGambler:GetPage("History").HistoryScroll
	ScrollBar:SetValue(ScrollBar.Offset - delta)
end

function vGambler:UpdateHistory()
	if self.Window then
		self:SetHistoryScrollOffset(1)
	end
end

function vGambler:SetupHistoryPage(page)
	local HistoryArea = CreateFrame("Frame", nil, page, "BackdropTemplate")
	HistoryArea:SetAllPoints(page)
	HistoryArea:SetBackdrop(self.MediumBackdrop)
	HistoryArea:SetBackdropColor(0.184, 0.192, 0.211)
	HistoryArea:SetBackdropBorderColor(0.184, 0.192, 0.211)
	HistoryArea:EnableMouseWheel(true)
	HistoryArea:SetScript("OnMouseWheel", self.HistoryScrollOnMouseWheel)

	local Header = self:AddGameHeader({}, HistoryArea, L.MATCH_HISTORY)
	Header:SetPoint("TOPLEFT", HistoryArea, 4, -4)
	Header.Label:ClearAllPoints()
	Header.Label:SetPoint("LEFT", Header, 6, -0.5)
	Header.Label:SetWidth(82)
	Header.Label:SetJustifyH("LEFT")
	Header.Label:SetText(L.MATCH_WINNER_HEADER)

	Header.Loser = Header:CreateFontString(nil, "OVERLAY")
	Header.Loser:SetPoint("LEFT", Header, 93, -0.5)
	Header.Loser:SetWidth(82)
	Header.Loser:SetJustifyH("LEFT")
	Header.Loser:SetFont(self.Font, self.Settings.FontSize)
	Header.Loser:SetText(L.MATCH_LOSER_HEADER)
	Header.Loser:SetShadowColor(0.029, 0.029, 0.051)
	Header.Loser:SetShadowOffset(0, -1)

	Header.Value = Header:CreateFontString(nil, "OVERLAY")
	Header.Value:SetPoint("LEFT", Header, 180, -0.5)
	Header.Value:SetWidth(45)
	Header.Value:SetJustifyH("RIGHT")
	Header.Value:SetFont(self.Font, self.Settings.FontSize)
	Header.Value:SetText(L.MATCH_VALUE_HEADER)
	Header.Value:SetShadowColor(0.029, 0.029, 0.051)
	Header.Value:SetShadowOffset(0, -1)

	Header.Date = Header:CreateFontString(nil, "OVERLAY")
	Header.Date:SetPoint("LEFT", Header, 230, -0.5)
	Header.Date:SetWidth(95)
	Header.Date:SetJustifyH("RIGHT")
	Header.Date:SetFont(self.Font, self.Settings.FontSize)
	Header.Date:SetText(L.MATCH_DATE_HEADER)
	Header.Date:SetShadowColor(0.029, 0.029, 0.051)
	Header.Date:SetShadowOffset(0, -1)

	for i = 1, 11 do
		local Line = CreateFrame("Frame", nil, HistoryArea, "BackdropTemplate")
		Line:SetSize(HistoryArea:GetWidth() - 24, 24)
		Line:SetPoint("TOPLEFT", HistoryArea, 4, -32 - ((i - 1) * 28))
		Line:SetBackdrop(self.SmallBackdrop)
		Line:SetBackdropColor(0.184, 0.192, 0.211)
		Line:SetBackdropBorderColor(0.184, 0.192, 0.211)
		Line:EnableMouse(true)
		Line:EnableMouseWheel(true)
		Line:SetScript("OnEnter", self.HistoryLineOnEnter)
		Line:SetScript("OnLeave", self.HistoryLineOnLeave)
		Line:SetScript("OnMouseWheel", self.HistoryScrollOnMouseWheel)

		Line.Winner = Line:CreateFontString(nil, "OVERLAY")
		Line.Winner:SetPoint("LEFT", Line, 5, -0.5)
		Line.Winner:SetWidth(82)
		Line.Winner:SetJustifyH("LEFT")
		Line.Winner:SetFont(self.Font, self.Settings.FontSize)
		Line.Winner:SetShadowColor(0.029, 0.029, 0.051)
		Line.Winner:SetShadowOffset(0, -1)

		Line.Loser = Line:CreateFontString(nil, "OVERLAY")
		Line.Loser:SetPoint("LEFT", Line, 92, -0.5)
		Line.Loser:SetWidth(82)
		Line.Loser:SetJustifyH("LEFT")
		Line.Loser:SetFont(self.Font, self.Settings.FontSize)
		Line.Loser:SetShadowColor(0.029, 0.029, 0.051)
		Line.Loser:SetShadowOffset(0, -1)

		Line.Value = Line:CreateFontString(nil, "OVERLAY")
		Line.Value:SetPoint("LEFT", Line, 179, -0.5)
		Line.Value:SetWidth(45)
		Line.Value:SetJustifyH("RIGHT")
		Line.Value:SetFont(self.Font, self.Settings.FontSize)
		Line.Value:SetShadowColor(0.029, 0.029, 0.051)
		Line.Value:SetShadowOffset(0, -1)

		Line.Date = Line:CreateFontString(nil, "OVERLAY")
		Line.Date:SetPoint("LEFT", Line, 229, -0.5)
		Line.Date:SetWidth(95)
		Line.Date:SetJustifyH("RIGHT")
		Line.Date:SetFont(self.Font, self.Settings.FontSize)
		Line.Date:SetShadowColor(0.029, 0.029, 0.051)
		Line.Date:SetShadowOffset(0, -1)

		table.insert(HistoryLines, Line)
	end

	local HistoryScroll = CreateFrame("Slider", nil, HistoryArea)
	HistoryScroll:SetWidth(12)
	HistoryScroll:SetPoint("TOPRIGHT", Header, "BOTTOMRIGHT", 1, 0)
	HistoryScroll:SetPoint("BOTTOMRIGHT", HistoryArea, -3, 4)
	HistoryScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
	HistoryScroll:GetThumbTexture():SetSize(32, 32)
	HistoryScroll:GetThumbTexture():SetVertexColor(0.25, 0.266, 0.294)
	HistoryScroll:SetOrientation("VERTICAL")
	HistoryScroll:SetValueStep(1)
	HistoryScroll:SetObeyStepOnDrag(true)
	HistoryScroll:SetMinMaxValues(1, 1)
	HistoryScroll:SetValue(1)
	HistoryScroll.Offset = 1
	HistoryScroll:SetScript("OnMouseWheel", self.HistoryScrollOnMouseWheel)
	HistoryScroll:SetScript("OnValueChanged", self.HistoryScrollOnValueChanged)
	HistoryScroll:SetScript("OnEnter", self.ScrollBarOnEnter)
	HistoryScroll:SetScript("OnLeave", self.ScrollBarOnLeave)
	HistoryScroll:SetScript("OnMouseDown", self.ScrollBarOnMouseDown)
	HistoryScroll:SetScript("OnMouseUp", self.ScrollBarOnMouseUp)

	page.HistoryScroll = HistoryScroll
	page:SetScript("OnShow", self.HistoryPageOnShow)
	page:SetScript("OnUpdate", self.HistoryPageOnUpdate)

	self:UpdateHistory()
end
