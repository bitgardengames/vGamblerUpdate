local Name, AddOn = ...
local vGambler = AddOn.vGambler
local L = AddOn.L

local table = table
local string = string

vGambler.Settings = {
	-- UI settings
	MinimapIcon = true,
	PlaySounds = true,
	StatDisplay = true, -- true = session, false = total
	UIFont = "PT Sans",
	FontSize = 14,

	-- Game settings
	RollValue = 10,
	Channel = 1,
	PlayerNumbers = false,
	PlayerTooltips = true,
	ColoredBars = true,
	EnterCommand = "1", -- Fun idea, but has problems when players with different commands play together
	LeaveCommand = "-1",
}

function vGambler:CheckBoxOnMouseUp()
	if self.Toggled then
		self.Toggled = false
		self.Box:SetBackdropColor(0.125, 0.133, 0.145)
		self.Box:SetBackdropBorderColor(0.125, 0.133, 0.145)

		if vGambler.Settings.PlaySounds then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		end
	else
		self.Toggled = true
		self.Box:SetBackdropColor(vGambler:HexToRGB("FFC44D"))
		self.Box:SetBackdropBorderColor(vGambler:HexToRGB("FFC44D"))

		if vGambler.Settings.PlaySounds then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end
	end

	if self.Hook then
		self.Hook(self, self.Toggled)
	end
end

function vGambler:AddGameCheckbox(t, parent, text, value, func)
	local Line = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Line:SetSize(parent:GetWidth() - 8, 24)
	Line:SetBackdrop(self.SmallBackdrop)
	Line:SetBackdropColor(0.184, 0.192, 0.211)
	Line:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Line:SetScript("OnEnter", self.WindowButtonOnEnter)
	Line:SetScript("OnLeave", self.WindowButtonOnLeave)
	Line:SetScript("OnMouseUp", self.CheckBoxOnMouseUp)
	Line.Toggled = value
	Line.Hook = func

	Line.Label = Line:CreateFontString(nil, "OVERLAY")
	Line.Label:SetPoint("LEFT", Line, 5, -0.5)
	Line.Label:SetFontObject(self:GetFontObject(self.Font, self.Settings.FontSize))
	Line.Label:SetText(text)

	Line.Box = CreateFrame("Frame", nil, Line, "BackdropTemplate")
	Line.Box:SetSize(18, 18)
	Line.Box:SetPoint("RIGHT", Line, -3, 0)
	Line.Box:SetBackdrop(self.SmallBackdrop)

	if value then
		Line.Box:SetBackdropColor(self:HexToRGB("FFC44D"))
		Line.Box:SetBackdropBorderColor(self:HexToRGB("FFC44D"))
	else
		Line.Box:SetBackdropColor(0.125, 0.133, 0.145)
		Line.Box:SetBackdropBorderColor(0.125, 0.133, 0.145)
	end

	table.insert(t, Line)

	return Line
end

function vGambler:UpdateShowListNumbers(value)
	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	vGamblerSettings.PlayerNumbers = value
	vGambler.Settings.PlayerNumbers = value

	for i = 1, #vGambler.Players do
		if vGambler.Settings.PlayerNumbers then
			if vGambler.Settings.ColoredBars then
				vGambler.Players[i].Label:SetText(string.format(L.NUMBERED_PLAYER, i, vGambler.Players[i].Name))
			else
				vGambler.Players[i].Label:SetText(string.format(L.NUMBERED_PLAYER, i, vGambler.Players[i].DisplayName))
			end
		else
			if vGambler.Settings.ColoredBars then
				vGambler.Players[i].Label:SetText(vGambler.Players[i].Name)
			else
				vGambler.Players[i].Label:SetText(vGambler.Players[i].DisplayName)
			end
		end
	end
end

function vGambler:UpdateShowMinimapButton(value)
	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	vGamblerSettings.MinimapIcon = value
	vGambler.Settings.MinimapIcon = value

	if value then
		vGambler.LibDBIcon:Show("vGambler")
	else
		vGambler.LibDBIcon:Hide("vGambler")
	end
end

function vGambler:UpdateShowPlayerTooltips(value)
	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	-- These should be in the hook or something instead of in each callback
	vGamblerSettings.PlayerTooltips = value
	vGambler.Settings.PlayerTooltips = value
end

function vGambler:HexToRGB(hex)
	if (not hex) then
		return
	end

	return tonumber("0x" .. string.sub(hex, 1, 2)) / 255, tonumber("0x" .. string.sub(hex, 3, 4)) / 255, tonumber("0x" .. string.sub(hex, 5, 6)) / 255
end

function vGambler:UpdateClassColoredBars(value)
	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	-- These should be in the hook or something instead of in each callback
	vGamblerSettings.ColoredBars = value
	vGambler.Settings.ColoredBars = value

	for i = 1, #vGambler.Players do
		if vGambler.Settings.ColoredBars then
			local R, G, B = vGambler:HexToRGB(vGambler.Players[i].Hex)

			vGambler.UIPlayers[i].Bar:SetStatusBarColor(R * 0.70, G * 0.70, B * 0.70)
			vGambler.UIPlayers[i].Label:SetTextColor(1, 1, 1)

			if vGambler.Settings.PlayerNumbers then
				vGambler.UIPlayers[i].Label:SetText(string.format(L.NUMBERED_PLAYER, i, vGambler.Players[i].Name))
			else
				vGambler.UIPlayers[i].Label:SetText(vGambler.Players[i].Name)
			end
		else
			vGambler.UIPlayers[i].Bar:SetStatusBarColor(0.25, 0.266, 0.294)

			if vGambler.Settings.PlayerNumbers then
				vGambler.UIPlayers[i].Label:SetText(string.format(L.NUMBERED_PLAYER, i, vGambler.Players[i].DisplayName))
			else
				vGambler.UIPlayers[i].Label:SetText(vGambler.Players[i].DisplayName)
			end
		end
	end
end

function vGambler:UpdatePlaySounds(value)
	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	vGamblerSettings.PlaySounds = value
	vGambler.Settings.PlaySounds = value
end

function vGambler:UpdateUIFont(value)
	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	vGamblerSettings.UIFont = value
	vGambler.Settings.UIFont = value
end

function vGambler:FontSizeInputOnEnter(value)
	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	value = tonumber(value)
	if (not value) then
		return vGambler.Settings.FontSize
	end

	if (value > 18) then
		value = 18
	elseif (value < 10) then
		value = 10
	end

	vGamblerSettings.FontSize = value
	vGambler.Settings.FontSize = value

	return value
end

function vGambler:ShowResetStatsConfirmation(resetFunc)
	local Dialog = self.ResetStatsDialog

	Dialog.ResetFunc = resetFunc
	Dialog:Show()
end

function vGambler:AcceptResetStats()
	local Dialog = vGambler.ResetStatsDialog
	local ResetFunc = Dialog.ResetFunc

	Dialog:Hide()
	Dialog.ResetFunc = nil

	if ResetFunc then
		ResetFunc()
	end
end

function vGambler:CancelResetStats()
	local Dialog = vGambler.ResetStatsDialog

	Dialog:Hide()
	Dialog.ResetFunc = nil
end

function vGambler:ShowResetGeneralStatsConfirmation()
	vGambler:ShowResetStatsConfirmation(vGambler.ResetGeneralStats)
end

function vGambler:ShowResetPlayerStatsConfirmation()
	vGambler:ShowResetStatsConfirmation(vGambler.ResetPlayerStats)
end

function vGambler:CreateResetStatsDialog()
	local Dialog = CreateFrame("Frame", nil, self.Window, "BackdropTemplate")
	Dialog:SetSize(300, 136)
	Dialog:SetPoint("CENTER", self.Window, 0, 0)
	Dialog:SetBackdrop(self.LargeBackdrop)
	Dialog:SetBackdropColor(0.125, 0.133, 0.145)
	Dialog:SetBackdropBorderColor(0.125, 0.133, 0.145)
	Dialog:SetFrameLevel(self.Window:GetFrameLevel() + 10)
	Dialog:EnableMouse(true)
	Dialog:Hide()

	local Header = CreateFrame("Frame", nil, Dialog, "BackdropTemplate")
	Header:SetPoint("TOPLEFT", Dialog, 6, -6)
	Header:SetPoint("TOPRIGHT", Dialog, -6, -6)
	Header:SetHeight(24)
	Header:SetBackdrop(self.MediumBackdrop)
	Header:SetBackdropColor(0.184, 0.192, 0.211)
	Header:SetBackdropBorderColor(0.184, 0.192, 0.211)

	local Title = Header:CreateFontString(nil, "OVERLAY")
	Title:SetPoint("CENTER", Header, 0, 0)
	Title:SetFontObject(self:GetFontObject(self.Font, self.Settings.FontSize))
	Title:SetText(string.format("|cffFFC44D%s|r", L.STATS_SETTINGS))

	local Warning = Dialog:CreateFontString(nil, "OVERLAY")
	Warning:SetPoint("TOPLEFT", Header, "BOTTOMLEFT", 8, -8)
	Warning:SetPoint("TOPRIGHT", Header, "BOTTOMRIGHT", -8, -8)
	Warning:SetHeight(38)
	Warning:SetFontObject(self:GetFontObject(self.Font, self.Settings.FontSize))
	Warning:SetJustifyH("CENTER")
	Warning:SetJustifyV("MIDDLE")
	Warning:SetText(L.RESET_STATS_WARNING)

	local Buttons = {}
	local Accept = self:AddGameButton(Buttons, Dialog, "acceptreset", L.ACCEPT, self.AcceptResetStats)
	Accept:SetSize(137, 24)
	Accept:SetPoint("BOTTOMLEFT", Dialog, 8, 8)

	local Cancel = self:AddGameButton(Buttons, Dialog, "cancelreset", L.CANCEL, self.CancelResetStats)
	Cancel:SetSize(137, 24)
	Cancel:SetPoint("BOTTOMRIGHT", Dialog, -8, 8)

	self.ResetStatsDialog = Dialog
end

function vGambler:SetupSettingsPage(page)
	page.LeftSettings = {}
	page.RightSettings = {}

	local Left = CreateFrame("Frame", nil, page, "BackdropTemplate")
	Left:SetSize(175, 214)
	Left:SetPoint("TOPLEFT", page, 0, 0)
	Left:SetBackdrop(self.MediumBackdrop)
	Left:SetBackdropColor(0.184, 0.192, 0.211)
	Left:SetBackdropBorderColor(0.184, 0.192, 0.211)

	self:AddGameHeader(page.LeftSettings, Left, L.GAME_SETTINGS)
	self:AddGameCheckbox(page.LeftSettings, Left, L.SHOW_PLAYER_NUMBERS, self.Settings.PlayerNumbers, self.UpdateShowListNumbers)
	self:AddGameCheckbox(page.LeftSettings, Left, L.CLASS_COLORED_BARS, self.Settings.ColoredBars, self.UpdateClassColoredBars)
	self:AddGameCheckbox(page.LeftSettings, Left, L.SHOW_TOOLTIP_STATS, self.Settings.PlayerTooltips, self.UpdateShowPlayerTooltips)

	self:AddGameHeader(page.LeftSettings, Left, L.UI_FONT)
	self:AddFontDropdown(page.LeftSettings, Left, "Font", self.Settings.UIFont, self.UpdateUIFont)

	self:AddGameHeader(page.LeftSettings, Left, L.SET_FONT_SIZE)
	self:AddGameInput(page.LeftSettings, Left, "FontSize", self.Settings.FontSize, self.FontSizeInputOnEnter)

	self:SortButtonList(page.LeftSettings, Left)

	local Right = CreateFrame("Frame", nil, page, "BackdropTemplate")
	Right:SetSize(174, 162)
	Right:SetPoint("TOPRIGHT", page, 0, 0)
	Right:SetBackdrop(self.MediumBackdrop)
	Right:SetBackdropColor(0.184, 0.192, 0.211)
	Right:SetBackdropBorderColor(0.184, 0.192, 0.211)

	self:AddGameHeader(page.RightSettings, Right, L.GENERAL_SETTINGS)
	self:AddGameCheckbox(page.RightSettings, Right, L.SHOW_MINIMAP_BUTTON, self.Settings.MinimapIcon, self.UpdateShowMinimapButton)
	self:AddGameCheckbox(page.RightSettings, Right, L.PLAY_SOUNDS, self.Settings.PlaySounds, self.UpdatePlaySounds)

	self:AddGameHeader(page.RightSettings, Right, L.STATS_SETTINGS)
	self:AddGameButton(page.RightSettings, Right, "resetgeneral", L.RESET_GENERAL_STATS, self.ShowResetGeneralStatsConfirmation)
	self:AddGameButton(page.RightSettings, Right, "resetplayers", L.RESET_PLAYER_STATS, self.ShowResetPlayerStatsConfirmation)

	self:SortButtonList(page.RightSettings, Right)
	self:CreateResetStatsDialog()
end
