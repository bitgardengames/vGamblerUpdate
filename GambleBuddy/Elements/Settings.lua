local Name, AddOn = ...
local GambleBuddy = AddOn.GambleBuddy

local table = table
local string = string

GambleBuddy.Settings = {
	-- UI settings
	MinimapIcon = true,
	PlaySounds = true,
	StatDisplay = true, -- true = session, false = total
	UIStyle = 1, -- 1 = round, 2 = square
	FadeChat = true,
	UIFont = "PT Sans",
	GameFont = "PT Sans",
	FontSize = 14,

	-- Game settings
	RollValue = 10,
	Channel = 4,
	PlayerNumbers = false,
	PlayerTooltips = true,
	ColoredBars = true,
	EnterCommand = "1", -- Fun idea, but has problems when players with different commands play together
	LeaveCommand = "0",
}

GambleBuddy.UIStyleSelections = {"Round", "Square"} -- Localize these

function GambleBuddy:CheckBoxOnMouseUp()
	if self.Toggled then
		self.Toggled = false
		self.Box:SetBackdropColor(0.125, 0.133, 0.145)
		self.Box:SetBackdropBorderColor(0.125, 0.133, 0.145)

		if GambleBuddy.Settings.PlaySounds then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		end
	else
		self.Toggled = true
		self.Box:SetBackdropColor(GambleBuddy:HexToRGB("FFC44D"))
		self.Box:SetBackdropBorderColor(GambleBuddy:HexToRGB("FFC44D"))

		if GambleBuddy.Settings.PlaySounds then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end
	end

	if self.Hook then
		self.Hook(self, self.Toggled)
	end
end

function GambleBuddy:AddGameCheckbox(t, parent, text, value, func)
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
	Line.Label:SetFont(self.Font, self.Settings.FontSize)
	Line.Label:SetText(text)
	Line.Label:SetShadowColor(0.029, 0.029, 0.051)
	Line.Label:SetShadowOffset(0, -1)

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

function GambleBuddy:UpdateShowListNumbers(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	GambleBuddySettings.PlayerNumbers = value
	GambleBuddy.Settings.PlayerNumbers = value

	for i = 1, #GambleBuddy.Players do
		if GambleBuddy.Settings.PlayerNumbers then
			if GambleBuddy.Settings.ColoredBars then
				GambleBuddy.Players[i].Label:SetText(string.format("%d.  %s", i, GambleBuddy.Players[i].Name))
			else
				GambleBuddy.Players[i].Label:SetText(string.format("%d.  %s", i, GambleBuddy.Players[i].DisplayName))
			end
		else
			if GambleBuddy.Settings.ColoredBars then
				GambleBuddy.Players[i].Label:SetText(GambleBuddy.Players[i].Name)
			else
				GambleBuddy.Players[i].Label:SetText(GambleBuddy.Players[i].DisplayName)
			end
		end
	end
end

function GambleBuddy:UpdateShowMinimapButton(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	GambleBuddySettings.MinimapIcon = value
	GambleBuddy.Settings.MinimapIcon = value

	if value then
		GambleBuddy.LibDBIcon:Show("GambleBuddy")
	else
		GambleBuddy.LibDBIcon:Hide("GambleBuddy")
	end
end

function GambleBuddy:UpdateShowPlayerTooltips(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	-- These should be in the hook or something instead of in each callback
	GambleBuddySettings.PlayerTooltips = value
	GambleBuddy.Settings.PlayerTooltips = value
end

function GambleBuddy:HexToRGB(hex)
	if (not hex) then
		return
	end

	return tonumber("0x" .. string.sub(hex, 1, 2)) / 255, tonumber("0x" .. string.sub(hex, 3, 4)) / 255, tonumber("0x" .. string.sub(hex, 5, 6)) / 255
end

function GambleBuddy:UpdateClassColoredBars(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	-- These should be in the hook or something instead of in each callback
	GambleBuddySettings.ColoredBars = value
	GambleBuddy.Settings.ColoredBars = value

	for i = 1, #GambleBuddy.Players do
		if GambleBuddy.Settings.ColoredBars then
			local R, G, B = GambleBuddy:HexToRGB(GambleBuddy.Players[i].Hex)

			GambleBuddy.UIPlayers[i].Bar:SetStatusBarColor(R * 0.70, G * 0.70, B * 0.70)
			GambleBuddy.UIPlayers[i].Label:SetTextColor(1, 1, 1)

			if GambleBuddy.Settings.PlayerNumbers then
				GambleBuddy.UIPlayers[i].Label:SetText(string.format("%d.  %s", i, GambleBuddy.Players[i].Name))
			else
				GambleBuddy.UIPlayers[i].Label:SetText(GambleBuddy.Players[i].Name)
			end
		else
			GambleBuddy.UIPlayers[i].Bar:SetStatusBarColor(0.25, 0.266, 0.294)

			if GambleBuddy.Settings.PlayerNumbers then
				GambleBuddy.UIPlayers[i].Label:SetText(string.format("%d.  %s", i, GambleBuddy.Players[i].DisplayName))
			else
				GambleBuddy.UIPlayers[i].Label:SetText(GambleBuddy.Players[i].DisplayName)
			end
		end
	end
end

function GambleBuddy:UpdatePlaySounds(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	GambleBuddySettings.PlaySounds = value
	GambleBuddy.Settings.PlaySounds = value
end

function GambleBuddy:UpdateUIStyle(dropdown, value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	GambleBuddySettings.UIStyle = value
	GambleBuddy.Settings.UIStyle = value

	dropdown.Label:SetText(GambleBuddy.UIStyleSelections[value])

	-- Create a prompt, REQUIRES_RELOAD
end

function GambleBuddy:UpdateFadeChat(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	GambleBuddy.ChatWindow:SetFading(GambleBuddy.Settings.FadeChat)

	GambleBuddySettings.FadeChat = value
	GambleBuddy.Settings.FadeChat = value
end

function GambleBuddy:UpdateUIFont(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	GambleBuddySettings.UIFont = value
	GambleBuddy.Settings.UIFont = value
end

function GambleBuddy:UpdateGameFont(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	GambleBuddySettings.GameFont = value
	GambleBuddy.Settings.GameFont = value
end

function GambleBuddy:FontSizeInputOnEnter(value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	value = tonumber(value)

	if (value > 18) then
		value = 18
	elseif (value < 10) then
		value = 10
	end

	GambleBuddySettings.FontSize = value
	GambleBuddy.Settings.FontSize = value
end

function GambleBuddy:SetupSettingsPage(page)
	page.LeftSettings = {}
	page.RightSettings = {}

	local Left = CreateFrame("Frame", nil, page, "BackdropTemplate")
	Left:SetSize(175, 266)
	Left:SetPoint("TOPLEFT", page, 0, 0)
	Left:SetBackdrop(self.MediumBackdrop)
	Left:SetBackdropColor(0.184, 0.192, 0.211)
	Left:SetBackdropBorderColor(0.184, 0.192, 0.211)

	self:AddGameHeader(page.LeftSettings, Left, "Game Settings")
	self:AddGameCheckbox(page.LeftSettings, Left, "Show player numbers", self.Settings.PlayerNumbers, self.UpdateShowListNumbers)
	self:AddGameCheckbox(page.LeftSettings, Left, "Class colored bars", self.Settings.ColoredBars, self.UpdateClassColoredBars)
	self:AddGameCheckbox(page.LeftSettings, Left, "Show tooltip stats", self.Settings.PlayerTooltips, self.UpdateShowPlayerTooltips)

	self:AddGameHeader(page.LeftSettings, Left, "UI font")
	self:AddFontDropdown(page.LeftSettings, Left, "Font", self.Settings.UIFont, self.UpdateUIFont)

	self:AddGameHeader(page.LeftSettings, Left, "Game font")
	self:AddFontDropdown(page.LeftSettings, Left, "Font", self.Settings.GameFont, self.UpdateGameFont)

	self:AddGameHeader(page.LeftSettings, Left, "Set font size")
	self:AddGameInput(page.LeftSettings, Left, "FontSize", self.Settings.FontSize, self.FontSizeInputOnEnter)

	self:SortButtonList(page.LeftSettings, Left)

	local Right = CreateFrame("Frame", nil, page, "BackdropTemplate")
	Right:SetSize(174, 240)
	Right:SetPoint("TOPRIGHT", page, 0, 0)
	Right:SetBackdrop(self.MediumBackdrop)
	Right:SetBackdropColor(0.184, 0.192, 0.211)
	Right:SetBackdropBorderColor(0.184, 0.192, 0.211)

	self:AddGameHeader(page.RightSettings, Right, "General Settings")
	self:AddGameCheckbox(page.RightSettings, Right, "Show minimap button", self.Settings.MinimapIcon, self.UpdateShowMinimapButton)
	self:AddGameCheckbox(page.RightSettings, Right, "Play sounds", self.Settings.PlaySounds, self.UpdatePlaySounds)
	self:AddGameCheckbox(page.RightSettings, Right, "Fade chat", self.Settings.FadeChat, self.UpdateFadeChat)

	self:AddGameHeader(page.RightSettings, Right, "UI Style")
	self:AddGameDropdown(page.RightSettings, Right, "UI style", self.UIStyleSelections[self.Settings.UIStyle], self.UIStyleSelections, self.UpdateUIStyle)

	self:AddGameHeader(page.RightSettings, Right, "Stats Settings")
	self:AddGameButton(page.RightSettings, Right, "resetgeneral", "Reset General Stats", self.ResetGeneralStats)
	self:AddGameButton(page.RightSettings, Right, "resetplayers", "Reset Player Stats", self.ResetPlayerStats)

	self:SortButtonList(page.RightSettings, Right)
end