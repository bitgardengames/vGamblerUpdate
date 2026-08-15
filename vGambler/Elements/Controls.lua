local Name, AddOn = ...
local L = AddOn.L
local vGambler = AddOn.vGambler

function vGambler:OnChannelSelection(dropdown, value)
	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	vGamblerSettings.Channel = value
	vGambler.Settings.Channel = value

	dropdown.Label:SetText(vGambler.ChannelSelections[value])

	if (dropdown.ID == "Channel") then
		dropdown.Label:SetTextColor(unpack(vGambler.ChannelColors[value]))
	end
end

function vGambler:SetGameScrollOffset(offset)
	self.Offset = offset

	if (self.Offset <= 1) then
		self.Offset = 1
	elseif (self.Offset > (#vGambler.Players - 8)) then
		self.Offset = self.Offset - 1
	end

	local First

	for i = 1, #vGambler.UIPlayers do
		if vGambler.UIPlayers[i] then
			vGambler.UIPlayers[i]:ClearAllPoints()

			if (i >= self.Offset) and (i <= self.Offset + 8) then
				if (not First) then
					vGambler.UIPlayers[i]:SetPoint("TOPLEFT", vGambler.Window.GameArea, 4, -4)
					First = i
				else
					vGambler.UIPlayers[i]:SetPoint("TOP", vGambler.UIPlayers[i-1], "BOTTOM", 0, -2)
				end

				vGambler.UIPlayers[i]:Show()
			else
				vGambler.UIPlayers[i]:Hide()
			end
		end
	end

	vGambler:SortPlayerList()
end

function vGambler:GameScrollOnValueChanged(offset)
	vGambler.Window.GameArea.ScrollBar.Offset = offset

	vGambler:SetGameScrollOffset(offset)
end

function vGambler:GameScrollOnMouseWheel(delta)
	if (delta > 0) then -- Up
		self.Offset = self.Offset - 1

		if (self.Offset <= 1) then
			self.Offset = 1
		end
	else -- Down
		self.Offset = self.Offset + 1

		if (self.Offset > (#vGambler.Players - 8)) then
			self.Offset = self.Offset - 1
		end
	end

	vGambler:SetGameScrollOffset(self.Offset)
	self:SetValue(self.Offset)
end

function vGambler:PlayerOnMouseWheel(delta)
	local ScrollBar = vGambler.Window.GameArea.ScrollBar

	if (delta > 0) then -- Up
		ScrollBar.Offset = ScrollBar.Offset - 1

		if (ScrollBar.Offset <= 1) then
			ScrollBar.Offset = 1
		end
	else -- Down
		ScrollBar.Offset = ScrollBar.Offset + 1

		if (ScrollBar.Offset > (#vGambler.Players - 8)) then
			ScrollBar.Offset = ScrollBar.Offset - 1
		end
	end

	ScrollBar:SetValue(ScrollBar.Offset)
end

function vGambler:ScrollBarOnEnter()
	self:GetThumbTexture():SetVertexColor(0.235, 0.247, 0.27)
end

function vGambler:ScrollBarOnLeave()
	if (not self.OverrideThumb) then
		self:GetThumbTexture():SetVertexColor(0.25, 0.266, 0.294)
	end
end

function vGambler:ScrollBarOnMouseDown()
	self.OverrideThumb = true
	self:GetThumbTexture():SetVertexColor(0.235, 0.247, 0.27)
end

function vGambler:ScrollBarOnMouseUp()
	self.OverrideThumb = false
	self:GetThumbTexture():SetVertexColor(0.25, 0.266, 0.294)
end

function vGambler:ChatScrollBarOnValueChanged(offset)
	vGambler.ChatWindow:SetScrollOffset(select(2, vGambler.ChatWindow.ScrollBar:GetMinMaxValues()) - offset)
end

function vGambler:ChatOnMouseWheel(delta)
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

function vGambler:UpdateChatScrollBar()
	local NumMessages = vGambler.ChatWindow:GetNumMessages()

	vGambler.ChatWindow.ScrollBar:SetMinMaxValues(1, math.max(1, NumMessages))

	if vGambler.ChatWindow:AtBottom() then -- Only scroll the window if we're currently on the bottom. Otherwise stay at current offset
		vGambler.ChatWindow.ScrollBar:SetValue(math.max(0, NumMessages))
	end
end

function vGambler:SetupControlsPage(page)
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
	GameAreaScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
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
		GameAreaScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
		GameAreaScrollThumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
	else
		GameAreaScrollThumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
	end

	self.Window.GameArea = GameArea
	self.Window.GameArea.ScrollBar = GameAreaScroll
	self.Window.GameButtons = GameButtons
	self.Window.PlayButtons = PlayButtons
	self.Window.GameSettings = GameSettings

	self:SetGameScrollOffset(1)

	self:AddGameHeader(GameButtons, GameButtons, L.HOST_GAME)
	self:AddGameButton(GameButtons, GameButtons, "Start", L.START_GAME, function() if vGambler.Settings.Channel == 4 then vGambler:TestGame() else vGambler:StartGame() end end)
	self:AddGameButton(GameButtons, GameButtons, "LastCall", L.LAST_CALL_BUTTON, function() vGambler:LastCall() end)
	self:AddGameButton(GameButtons, GameButtons, "Close", L.CLOSE_GAME, function() vGambler:CloseGame() end)
	self:AddGameButton(GameButtons, GameButtons, "Reset", L.RESET_GAME, function() vGambler:ResetGame() end)

	self:AddGameHeader(GameSettings, GameSettings, L.ROLL_VALUE)
	self:AddGameInput(GameSettings, GameSettings, "RollValue", self:Comma(self.Settings.RollValue), self.RollInputOnEnter)

	self:AddGameHeader(GameSettings, GameSettings, L.GAME_CHANNEL)
	self:AddGameDropdown(GameSettings, GameSettings, "Channel", self.ChannelSelections[self.Settings.Channel], self.ChannelSelections, self.OnChannelSelection)

	self:AddGameHeader(PlayButtons, PlayButtons, L.JOIN_GAME)
	self:AddGameButton(PlayButtons, PlayButtons, "Join", L.JOIN, function() vGambler:JoinGame() end)
	self:AddGameButton(PlayButtons, PlayButtons, "Withdraw", L.WITHDRAW, function() vGambler:WithdrawGame() end)
	self:AddGameButton(PlayButtons, PlayButtons, "Roll", L.ROLL, function() vGambler:RollGame() end)

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
	ScrollBar:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
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
		ScrollBar:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
		Thumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
	else
		Thumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
	end

	self.ChatWindow:AddMessage(L.WELCOME)

	for i = 1, #self.PendingMessages do
		self.ChatWindow:AddMessage(self.PendingMessages[i])
	end

	self.PendingMessages = table.wipe(self.PendingMessages)
	self:UpdateChatScrollBar()

	self:SortButtonList(GameButtons, GameButtons)
	self:SortButtonList(GameSettings, GameSettings)
	self:SortButtonList(PlayButtons, PlayButtons)
end
