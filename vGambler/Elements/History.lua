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

-- Keep match history in a SavedVariables table so it survives reloads and new
-- sessions. The history is trimmed when new matches are added.
if (type(vGamblerHistory) ~= "table") then
	vGamblerHistory = {}
end

vGambler.MatchHistory = vGamblerHistory

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
	vGambler.Tooltip:AddLine(string.format(L.MATCH_NUMBER, self.MatchNumber), 1, 1, 1)

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

	offset = math.max(1, math.min(math.floor(offset + 0.5), Maximum))
	Page.HistoryScroll.Offset = offset
	Page.HistoryScroll:SetMinMaxValues(1, Maximum)
	Page.HistoryScroll:SetValue(offset)

	for i = 1, #HistoryLines do
		local MatchNumber = #self.MatchHistory - offset - i + 2
		local Match = self.MatchHistory[MatchNumber]
		local Line = HistoryLines[i]

		if Match then
			Line.MatchIndex = MatchNumber
			Line.MatchNumber = MatchNumber
			Line.Label:SetText(string.format(L.MATCH_SUMMARY, MatchNumber, Match.winner, Match.loser, self:Comma(Match.value)))
			Line:Show()
		else
			Line:Hide()
		end
	end
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

		Line.Label = Line:CreateFontString(nil, "OVERLAY")
		Line.Label:SetPoint("LEFT", Line, 5, -0.5)
		self:SetFont(Line.Label, self.Font, self.Settings.FontSize)
		table.insert(HistoryLines, Line)
	end

	local HistoryScroll = CreateFrame("Slider", nil, HistoryArea)
	HistoryScroll:SetWidth(12)
	HistoryScroll:SetPoint("TOPRIGHT", Header, "BOTTOMRIGHT", 1, 0)
	HistoryScroll:SetPoint("BOTTOMRIGHT", HistoryArea, -3, 4)
	HistoryScroll:SetThumbTexture(self.Settings.UIStyle == 1 and "Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga" or "Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
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
	self:UpdateHistory()
end
