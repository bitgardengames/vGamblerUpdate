local Name, AddOn = ...
local L = AddOn.L
local GambleBuddy = AddOn.GambleBuddy

function GambleBuddy:OnChannelSelection(dropdown, value)
	if (not GambleBuddySettings) then
		GambleBuddySettings = {}
	end

	GambleBuddySettings.Channel = value
	GambleBuddy.Settings.Channel = value

	dropdown.Label:SetText(GambleBuddy.ChannelSelections[value])

	if (dropdown.ID == "Channel") then
		dropdown.Label:SetTextColor(unpack(GambleBuddy.ChannelColors[value]))
	end
end

function GambleBuddy:SetGameScrollOffset(offset)
	self.Offset = offset

	if (self.Offset <= 1) then
		self.Offset = 1
	elseif (self.Offset > (#GambleBuddy.Players - 8)) then
		self.Offset = self.Offset - 1
	end

	local First

	for i = 1, #GambleBuddy.UIPlayers do
		if GambleBuddy.UIPlayers[i] then
			GambleBuddy.UIPlayers[i]:ClearAllPoints()

			if (i >= self.Offset) and (i <= self.Offset + 8) then
				if (not First) then
					GambleBuddy.UIPlayers[i]:SetPoint("TOPLEFT", GambleBuddy.Window.GameArea, 4, -4)
					First = i
				else
					GambleBuddy.UIPlayers[i]:SetPoint("TOP", GambleBuddy.UIPlayers[i-1], "BOTTOM", 0, -2)
				end

				GambleBuddy.UIPlayers[i]:Show()
			else
				GambleBuddy.UIPlayers[i]:Hide()
			end
		end
	end
end

function GambleBuddy:GameScrollOnValueChanged(offset)
	GambleBuddy.Window.GameArea.ScrollBar.Offset = offset

	GambleBuddy:SetGameScrollOffset(offset)
end

function GambleBuddy:GameScrollOnMouseWheel(delta)
	if (delta > 0) then -- Up
		self.Offset = self.Offset - 1

		if (self.Offset <= 1) then
			self.Offset = 1
		end
	else -- Down
		self.Offset = self.Offset + 1

		if (self.Offset > (#GambleBuddy.Players - 8)) then
			self.Offset = self.Offset - 1
		end
	end

	GambleBuddy:SetGameScrollOffset(self.Offset)
	self:SetValue(self.Offset)
end

function GambleBuddy:PlayerOnMouseWheel(delta)
	local ScrollBar = GambleBuddy.Window.GameArea.ScrollBar

	if (delta > 0) then -- Up
		ScrollBar.Offset = ScrollBar.Offset - 1

		if (ScrollBar.Offset <= 1) then
			ScrollBar.Offset = 1
		end
	else -- Down
		ScrollBar.Offset = ScrollBar.Offset + 1

		if (ScrollBar.Offset > (#GambleBuddy.Players - 8)) then
			ScrollBar.Offset = ScrollBar.Offset - 1
		end
	end

	--GambleBuddy:SetGameScrollOffset(ScrollBar.Offset)
	ScrollBar:SetValue(ScrollBar.Offset)
end

function GambleBuddy:ScrollBarOnEnter()
	self:GetThumbTexture():SetVertexColor(0.235, 0.247, 0.27)
end

function GambleBuddy:ScrollBarOnLeave()
	if (not self.OverrideThumb) then
		self:GetThumbTexture():SetVertexColor(0.25, 0.266, 0.294)
	end
end

function GambleBuddy:ScrollBarOnMouseDown()
	self.OverrideThumb = true
	self:GetThumbTexture():SetVertexColor(0.235, 0.247, 0.27)
end

function GambleBuddy:ScrollBarOnMouseUp()
	self.OverrideThumb = false
	self:GetThumbTexture():SetVertexColor(0.25, 0.266, 0.294)
end

function GambleBuddy:ChatScrollBarOnValueChanged(offset)
	GambleBuddy.ChatWindow:SetScrollOffset(select(2, GambleBuddy.ChatWindow.ScrollBar:GetMinMaxValues()) - offset)
end

function GambleBuddy:ChatOnMouseWheel(delta)
	local Value = self.ScrollBar:GetValue()

	if (delta > 0) then
		if IsModifierKeyDown() then
			self.ScrollBar:SetValue(Value - 3)
		else
			self.ScrollBar:SetValue(Value - 1)
		end
	elseif (delta < 0) then
		if IsModifierKeyDown() then
			self.ScrollBar:SetValue(Value + 3)
		else
			self.ScrollBar:SetValue(Value + 1)
		end
	end
end

function GambleBuddy:UpdateChatScrollBar()
	local NumMessages = GambleBuddy.ChatWindow:GetNumMessages()

	GambleBuddy.ChatWindow.ScrollBar:SetMinMaxValues(1, math.max(1, NumMessages))

	if GambleBuddy.ChatWindow:AtBottom() then -- Only scroll the window if we're currently on the bottom. Otherwise stay at current offset
		GambleBuddy.ChatWindow.ScrollBar:SetValue(math.max(0, NumMessages))
	end
end

function GambleBuddy:SetupControlsPage(page)
	--page.Buttons = {} -- self.Window.Buttons should be self.GameButtons.Buttons or something instead

	-- Game tab
	local GameButtons = CreateFrame("Frame", nil, page, "BackdropTemplate")
	GameButtons:SetSize(146, 240)
	GameButtons:SetPoint("TOPLEFT", page, 0, 0)
	GameButtons:SetBackdrop(self.MediumBackdrop)
	GameButtons:SetBackdropColor(0.184, 0.192, 0.211)
	GameButtons:SetBackdropBorderColor(0.184, 0.192, 0.211)

	local GameSettings = CreateFrame("Frame", nil, page)
	GameSettings:SetSize(146, 100)
	GameSettings:SetPoint("BOTTOMLEFT", GameButtons, 0, 10)
	--GameSettings:SetBackdrop(self.MediumBackdrop)
	--GameSettings:SetBackdropColor(0.184, 0.192, 0.211)
	--GameSettings:SetBackdropBorderColor(0.184, 0.192, 0.211)
	--GameSettings:Hide()

	local PlayButtons = CreateFrame("Frame", nil, page)
	PlayButtons:SetSize(146, 100)
	PlayButtons:SetPoint("BOTTOMLEFT", GameButtons, 0, 10)
	--PlayButtons:SetBackdrop(self.MediumBackdrop)
	--PlayButtons:SetBackdropColor(0.184, 0.192, 0.211)
	--PlayButtons:SetBackdropBorderColor(0.184, 0.192, 0.211)
	PlayButtons:Hide()

	local GameArea = CreateFrame("Frame", nil, page, "BackdropTemplate")
	GameArea:SetSize(201, 240)
	GameArea:SetPoint("TOPLEFT", GameButtons, "TOPRIGHT", 6, 0)
	GameArea:SetBackdrop(self.MediumBackdrop)
	GameArea:SetBackdropColor(0.184, 0.192, 0.211)
	GameArea:SetBackdropBorderColor(0.184, 0.192, 0.211)

	local GameAreaScroll = CreateFrame("Slider", nil, GameArea)
	GameAreaScroll:SetWidth(12)
	GameAreaScroll:SetPoint("TOPRIGHT", GameArea, -3, -0)
	GameAreaScroll:SetPoint("BOTTOMRIGHT", GameArea, -3, 0)
	GameAreaScroll:SetThumbTexture("Interface\\AddOns\\GambleBuddy\\Assets\\HydraThumb.tga")
	GameAreaScroll:SetOrientation("VERTICAL")
	GameAreaScroll:SetValueStep(1)
	GameAreaScroll:SetObeyStepOnDrag(true)
	GameAreaScroll:SetMinMaxValues(1, 1)
	GameAreaScroll:SetValue(1)
	GameAreaScroll.Offset = 1
	GameAreaScroll:SetScript("OnMouseWheel", self.GameScrollOnMouseWheel)
	GameAreaScroll:SetScript("OnValueChanged", self.GameScrollOnValueChanged)
	GameAreaScroll:SetScript("OnEnter", self.ScrollBarOnEnter)
	GameAreaScroll:SetScript("OnLeave", self.ScrollBarOnLeave)
	GameAreaScroll:SetScript("OnMouseDown", self.ScrollBarOnMouseDown)
	GameAreaScroll:SetScript("OnMouseUp", self.ScrollBarOnMouseUp)

	local GameAreaScrollThumb = GameAreaScroll:GetThumbTexture()
	GameAreaScrollThumb:SetSize(32, 32)
	GameAreaScrollThumb:SetVertexColor(0.25, 0.266, 0.294)

	if (self.Settings.UIStyle == 1) then
		GameAreaScroll:SetThumbTexture("Interface\\AddOns\\GambleBuddy\\Assets\\HydraRoundThumb.tga")
		GameAreaScrollThumb:SetTexture("Interface\\AddOns\\GambleBuddy\\Assets\\HydraRoundThumb.tga")
	else
		GameAreaScrollThumb:SetTexture("Interface\\AddOns\\GambleBuddy\\Assets\\HydraThumb.tga")
	end

	self.Window.GameArea = GameArea
	self.Window.GameArea.ScrollBar = GameAreaScroll
	self.Window.GameButtons = GameButtons
	self.Window.PlayButtons = PlayButtons
	self.Window.GameSettings = GameSettings

	self:SetGameScrollOffset(1)

	self:AddGameHeader(GameButtons, GameButtons, "Host Game")
	self:AddGameButton(GameButtons, GameButtons, "Start", "Start Game", function() if GambleBuddy.Settings.Channel == 4 then GambleBuddy:TestGame() else GambleBuddy:StartGame() end end)
	self:AddGameButton(GameButtons, GameButtons, "LastCall", "Last Call", function() GambleBuddy:LastCall() end)
	self:AddGameButton(GameButtons, GameButtons, "Close", "Close Game", function() GambleBuddy:CloseGame() end)
	self:AddGameButton(GameButtons, GameButtons, "Reset", "Reset Game", function() GambleBuddy:ResetGame() end)

	self:AddGameHeader(GameSettings, GameSettings, "Roll Value")
	self:AddGameInput(GameSettings, GameSettings, "RollValue", self:Comma(self.Settings.RollValue), self.RollInputOnEnter)

	self:AddGameHeader(GameSettings, GameSettings, "Game Channel")
	self:AddGameDropdown(GameSettings, GameSettings, "Channel", self.ChannelSelections[self.Settings.Channel], self.ChannelSelections, self.OnChannelSelection)

	self:AddGameHeader(PlayButtons, PlayButtons, "Join Game")
	self:AddGameButton(PlayButtons, PlayButtons, "Join", "Join", function() end)
	self:AddGameButton(PlayButtons, PlayButtons, "Withdraw", "Withdraw", function() end)
	self:AddGameButton(PlayButtons, PlayButtons, "Roll", "Roll", function() end)

	self:DisableGameButton("LastCall")
	self:DisableGameButton("Reset")
	self:DisableGameButton("Close")

	local GameChat = CreateFrame("Frame", nil, page, "BackdropTemplate")
	GameChat:SetPoint("TOPLEFT", GameButtons, "BOTTOMLEFT", 0, -6)
	GameChat:SetPoint("BOTTOMRIGHT", page, 0, 0)
	GameChat:SetBackdrop(self.MediumBackdrop)
	GameChat:SetBackdropColor(0.184, 0.192, 0.211)
	GameChat:SetBackdropBorderColor(0.184, 0.192, 0.211)

	local ChatWindow = CreateFrame("ScrollingMessageFrame", nil, GameChat)
	ChatWindow:SetPoint("TOPLEFT", GameChat, 3, -3)
	ChatWindow:SetPoint("BOTTOMRIGHT", GameChat, -3, 3)
	ChatWindow:SetFont(self.Font, self.Settings.FontSize, "")
	ChatWindow:SetJustifyH("LEFT")
	ChatWindow:SetShadowColor(0.029, 0.029, 0.051)
	ChatWindow:SetShadowOffset(0, -1)
	ChatWindow:SetFading(self.Settings.FadeChat)
	ChatWindow:EnableMouseWheel(true)
	ChatWindow:SetScript("OnMouseWheel", self.ChatOnMouseWheel)

	local ScrollBar = CreateFrame("Slider", nil, GameChat)
	ScrollBar:SetWidth(12)
	ScrollBar:SetPoint("TOPRIGHT", GameChat, -3, 0)
	ScrollBar:SetPoint("BOTTOMRIGHT", GameChat, -3, 0)
	ScrollBar:SetThumbTexture("Interface\\AddOns\\GambleBuddy\\Assets\\HydraThumb.tga")
	ScrollBar:SetOrientation("VERTICAL")
	ScrollBar:SetValueStep(1)
	ScrollBar:SetObeyStepOnDrag(true)
	ScrollBar:SetMinMaxValues(0, 1)
	ScrollBar:SetValue(1)
	ScrollBar:EnableMouseWheel(true)
	ScrollBar:SetScript("OnMouseWheel", WindowScrollBarOnMouseWheel)
	ScrollBar:SetScript("OnValueChanged", self.ChatScrollBarOnValueChanged)
	ScrollBar:SetScript("OnEnter", self.ScrollBarOnEnter)
	ScrollBar:SetScript("OnLeave", self.ScrollBarOnLeave)
	ScrollBar:SetScript("OnMouseDown", self.ScrollBarOnMouseDown)
	ScrollBar:SetScript("OnMouseUp", self.ScrollBarOnMouseUp)

	self.ChatWindow = ChatWindow
	self.ChatWindow.ScrollBar = ScrollBar

	local Thumb = ScrollBar:GetThumbTexture()
	Thumb:SetSize(32, 32)
	Thumb:SetVertexColor(0.25, 0.266, 0.294)

	if (self.Settings.UIStyle == 1) then
		ScrollBar:SetThumbTexture("Interface\\AddOns\\GambleBuddy\\Assets\\HydraRoundThumb.tga")
		Thumb:SetTexture("Interface\\AddOns\\GambleBuddy\\Assets\\HydraRoundThumb.tga")
	else
		Thumb:SetTexture("Interface\\AddOns\\GambleBuddy\\Assets\\HydraThumb.tga")
	end

	self.ChatWindow:AddMessage("Welcome to |cffFFC44DGamble|rBuddy")

	self:SortButtonList(GameButtons, GameButtons)
	self:SortButtonList(GameSettings, GameSettings)
	self:SortButtonList(PlayButtons, PlayButtons)
end