-- Locals
local PlayerName = UnitName("player")
local PlayerClass = select(2, UnitClass("player"))
local CurrentRollValue = 1000
local Rolls = {}
local Players = {}
local Stats = {}

-- Libraries
local random = random
local gsub = gsub
local type = type
local floor = floor
local format = format
local strmatch = string.match
local tonumber = tonumber
local tostring = tostring
local reverse = string.reverse
local tinsert = tinsert
local tremove = tremove
local tsort = table.sort
local split = strsplit

-- Functions
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local SendAddonMessage = C_ChatInfo.SendAddonMessage

local Comma = function(number)
	if (not number) then
		return
	end
	
	if (type(number) ~= "number") then
		number = tonumber(number)
	end
	
	local Number = format("%.0f", floor(number + 0.5))
   	local Left, Number, Right = strmatch(Number, "^([^%d]*%d)(%d+)(.-)$")
	
	return Left and Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) or number
end

local GetRoll = function()
	local Roll = random(1, CurrentRollValue)
	
	return Roll
end

local SortRolls = function()
	tsort(Rolls, function(a, b)
		return a[2] > b[2]
	end)
	
	local Winner = Rolls[1]
	local Loser = Rolls[#Rolls]
	local Diff = Winner[2] - Loser[2]
	
	if (not Stats[Winner[1]]) then
		Stats[Winner[1]] = 0
	end
	
	if (not Stats[Loser[1]]) then
		Stats[Loser[1]] = 0
	end
	
	Stats[Winner[1]] = Stats[Winner[1]] + Diff
	Stats[Loser[1]] = Stats[Loser[1]] - Diff
	
	SilentGambler.BottomLabel:SetText(format("%s owes %s %s", Loser[1], Winner[1], Comma(Diff)))
	
	for i = #Rolls, 1, -1 do
		tremove(Rolls, 1)
	end
end

local CheckRolls = function()
	local NumPlayers = #Players
	local Count = 0
	
	for i = 1, #Players do
		if Players[i].HasRolled then
			Count = Count + 1
		end
	end
	
	if (Count == NumPlayers) then
		SortRolls()
	end
end

local PostStats = function()
	local Temp = {}
	local i = 1
	
	for k, v in pairs(Stats) do
		Temp[i] = {k, v}
		i = i + 1
	end
	
	if (i == 1) then
		print("No stats yet!")
		
		return
	end
	
	tsort(Temp, function(a, b)
		return a[2] > b[2]
	end)
	
	for i = 1, #Temp do
		print(format("%d. %s: %s", i, Temp[i][1], Comma(Temp[i][2])))
	end
	
	Temp = nil
end

-- GUI
local Blank = "Interface\\AddOns\\SilentGambler\\Blank.tga"
local Font = "Interface\\AddOns\\SilentGambler\\PTSans.ttf"
local FontColor = {220/255, 220/255, 220/255}

local Backdrop = {
	bgFile = Blank,
	edgeFile = Blank,
	tile = false, tileSize = 0, edgeSize = 1,
	insets = {left = 1, right = 1, top = 1, bottom = 1},
}

local BackdropBorder = {	
	edgeFile = Blank,
	edgeSize = 1,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local SetTemplate = function(self)
	self:SetBackdrop(Backdrop)
	self:SetBackdropBorderColor(0, 0, 0)
	self:SetBackdropColor(0.21, 0.21, 0.21)
end

local SetTemplateDark = function(self)
	self:SetBackdrop(Backdrop)
	self:SetBackdropBorderColor(0, 0, 0)
	self:SetBackdropColor(0.12, 0.12, 0.12)
end

local ButtonOnEnter = function(self)
	self:SetBackdropColor(0.17, 0.17, 0.17)
end

local ButtonOnLeave = function(self)
	self:SetBackdropColor(0.12, 0.12, 0.12)
end

local SendEvent = function(event, arg1)
	local Channel = ""
	
	if IsInRaid() then
		Channel = (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "RAID"
	elseif IsInGroup() then
		Channel = (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "PARTY"
	elseif IsInGuild() then
		Channel = "GUILD"
	end
	
	if Channel then
		local Event = event .. ":" .. tostring(arg1)
		
		SendAddonMessage("SilentGambler", Event, Channel)
	end
end

local GUI = CreateFrame("Frame", "SilentGambler", UIParent, "BackdropTemplate")
GUI:SetSize(228, 160)
GUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
SetTemplate(GUI)
GUI:SetMovable(true)
GUI:EnableMouse(true)
GUI:SetUserPlaced(true)
GUI:RegisterForDrag("LeftButton")
GUI:SetScript("OnDragStart", GUI.StartMoving)
GUI:SetScript("OnDragStop", GUI.StopMovingOrSizing)
GUI:Hide()

local Top = CreateFrame("Frame", nil, GUI, "BackdropTemplate")
Top:SetSize(228, 21)
Top:SetPoint("BOTTOM", GUI, "TOP", 0, -1)
SetTemplateDark(Top)

GUI.TopLabel = Top:CreateFontString(nil, "OVERLAY")
GUI.TopLabel:SetPoint("TOPLEFT", Top, "TOPLEFT", 4, -4)
GUI.TopLabel:SetFont(Font, 16)
GUI.TopLabel:SetTextColor(unpack(FontColor))
GUI.TopLabel:SetShadowOffset(1.25, -1.25)
GUI.TopLabel:SetShadowColor(0, 0, 0)

local Close = CreateFrame("Button", nil, Top, "BackdropTemplate")
Close:SetSize(21, 21)
Close:SetPoint("TOPRIGHT", Top, "TOPRIGHT", 0, 0)
Close:SetFrameStrata("MEDIUM")
SetTemplateDark(Close)
Close:SetScript("OnMouseUp", function(self)
	GUI:Hide()
end)
Close:SetScript("OnEnter", function(self) self.X:SetTextColor(1, 0.1, 0.1) end)
Close:SetScript("OnLeave", function(self) self.X:SetTextColor(unpack(FontColor)) end)

Close.X = Close:CreateFontString(nil, "OVERLAY")
Close.X:SetPoint("CENTER", Close, "CENTER", 1, -1)
Close.X:SetFont(Font, 16)
Close.X:SetTextColor(unpack(FontColor))
Close.X:SetText("×")
Close.X:SetShadowOffset(1.25, -1.25)
Close.X:SetShadowColor(0, 0, 0)

-- Enter Button
EnterButton = CreateFrame("Frame", "SilentGamblerJoinButton", GUI, "BackdropTemplate")
EnterButton:SetSize(70, 21)
EnterButton:SetPoint("LEFT", Top, 0, 0)
SetTemplateDark(EnterButton)
EnterButton:SetScript("OnEnter", ButtonOnEnter)
EnterButton:SetScript("OnLeave", ButtonOnLeave)
EnterButton:SetScript("OnMouseUp", function(self)
	SendEvent("ADD_PLAYER", PlayerName)
end)

EnterButton.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

EnterButton.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

EnterButton.Label = EnterButton:CreateFontString(nil, "OVERLAY")
EnterButton.Label:SetPoint("CENTER", EnterButton, 0, 0)
EnterButton.Label:SetFont(Font, 14)
EnterButton.Label:SetJustifyH("CENTER")
EnterButton.Label:SetTextColor(unpack(FontColor))
EnterButton.Label:SetText("Join")
EnterButton.Label:SetShadowOffset(1.25, -1.25)
EnterButton.Label:SetShadowColor(0, 0, 0)

-- Pass Button
PassButton = CreateFrame("Frame", "SilentGamblerPassButton", GUI, "BackdropTemplate")
PassButton:SetSize(70, 21)
PassButton:SetPoint("LEFT", EnterButton, "RIGHT", -1, 0)
SetTemplateDark(PassButton)
PassButton:SetScript("OnEnter", ButtonOnEnter)
PassButton:SetScript("OnLeave", ButtonOnLeave)
PassButton:SetScript("OnMouseUp", function(self)
	self:Disable()
	SilentGamblerJoinButton:Disable()
end)

PassButton.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

PassButton.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

PassButton.Label = PassButton:CreateFontString(nil, "OVERLAY")
PassButton.Label:SetPoint("CENTER", PassButton, 0, 0)
PassButton.Label:SetFont(Font, 14)
PassButton.Label:SetJustifyH("CENTER")
PassButton.Label:SetTextColor(unpack(FontColor))
PassButton.Label:SetText("Pass")
PassButton.Label:SetShadowOffset(1.25, -1.25)
PassButton.Label:SetShadowColor(0, 0, 0)

-- Roll button
RollButton = CreateFrame("Frame", "SilentGamblerRollButton", GUI, "BackdropTemplate")
RollButton:SetSize(70, 21)
RollButton:SetPoint("LEFT", PassButton, "RIGHT", -1, 0)
SetTemplateDark(RollButton)
RollButton:SetScript("OnEnter", ButtonOnEnter)
RollButton:SetScript("OnLeave", ButtonOnLeave)
RollButton:SetScript("OnMouseUp", function(self)
	local Roll = GetRoll()
	
	SendEvent("PLAYER_ROLL", PlayerName..":"..tostring(Roll))
	
	--[[for i = 1, #Players do
		if (Players[i].Name == PlayerName and not Players[i].HasRolled) then
			Players[i].HasRolled = true
			Players[i].Total:SetText(Comma(Roll))
			
			SendEvent("PLAYER_ROLL", PlayerName..":"..tostring(Roll))
		end
	end]]
end)

RollButton.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

RollButton.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

RollButton.Label = RollButton:CreateFontString(nil, "OVERLAY")
RollButton.Label:SetPoint("CENTER", RollButton, 0, 0)
RollButton.Label:SetFont(Font, 14)
RollButton.Label:SetJustifyH("CENTER")
RollButton.Label:SetTextColor(unpack(FontColor))
RollButton.Label:SetText("Roll!")
RollButton.Label:SetShadowOffset(1.25, -1.25)
RollButton.Label:SetShadowColor(0, 0, 0)

local Bottom = CreateFrame("Frame", nil, GUI, "BackdropTemplate")
Bottom:SetSize(228, 21)
Bottom:SetPoint("TOP", GUI, "BOTTOM", 0, 1)
SetTemplateDark(Bottom)

GUI.BottomLabel = Bottom:CreateFontString(nil, "OVERLAY")
GUI.BottomLabel:SetPoint("LEFT", Bottom, 4, 0)
GUI.BottomLabel:SetFont(Font, 14)
GUI.BottomLabel:SetTextColor(unpack(FontColor))
GUI.BottomLabel:SetJustifyH("LEFT")
GUI.BottomLabel:SetShadowOffset(1.25, -1.25)
GUI.BottomLabel:SetShadowColor(0, 0, 0)

local PlayerRoll = function(player)
	for i = 1, #Players do
		if (Players[i].Name == player and not Players[i].HasRolled) then
			Players[i].HasRolled = true
			local Roll = GetRoll()
			
			tinsert(Rolls, {Players[i].Name, Roll})
			
			Players[i].Total:SetText(Comma(Roll))
			-- Send the roll value to other clients.
			
			CheckRolls()
		end
	end
end

local SortPlayers = function()
	for i = 1, #Players do
		if (i == 1) then
			Players[i]:SetPoint("TOPLEFT", GUI, "TOPLEFT", 3, -3)
		else
			Players[i]:SetPoint("TOP", Players[i-1], "BOTTOM", 0, -2)
		end
	end
end

local AddPlayer = function(name)
	for i = 1, #Players do
		if (Players[i].Name == name) then
			return
		end
	end
	
	local PlayerSlot = CreateFrame("Frame", nil, GUI, "BackdropTemplate")
	PlayerSlot:SetSize(222, 21)
	SetTemplateDark(PlayerSlot)
	
	PlayerSlot.Name = name
	
	PlayerSlot.Label = PlayerSlot:CreateFontString(nil, "OVERLAY")
	PlayerSlot.Label:SetPoint("LEFT", PlayerSlot, 4, 0)
	PlayerSlot.Label:SetFont(Font, 14)
	PlayerSlot.Label:SetJustifyH("LEFT")
	PlayerSlot.Label:SetTextColor(unpack(FontColor))
	PlayerSlot.Label:SetText(name)
	PlayerSlot.Label:SetShadowOffset(1.25, -1.25)
	PlayerSlot.Label:SetShadowColor(0, 0, 0)
	
	PlayerSlot.TotalFrame = CreateFrame("Frame", nil, PlayerSlot, "BackdropTemplate")
	PlayerSlot.TotalFrame:SetSize(80, 21)
	PlayerSlot.TotalFrame:SetPoint("RIGHT", PlayerSlot, 0, 0)
	SetTemplateDark(PlayerSlot.TotalFrame)
	
	PlayerSlot.Total = PlayerSlot.TotalFrame:CreateFontString(nil, "OVERLAY")
	PlayerSlot.Total:SetPoint("LEFT", PlayerSlot.TotalFrame, 4, 0)
	PlayerSlot.Total:SetFont(Font, 14)
	PlayerSlot.Total:SetJustifyH("LEFT")
	PlayerSlot.Total:SetTextColor(unpack(FontColor))
	PlayerSlot.Total:SetShadowOffset(1.25, -1.25)
	PlayerSlot.Total:SetShadowColor(0, 0, 0)
	
	tinsert(Players, PlayerSlot)
	
	SortPlayers()
end

local RemovePlayer = function(name)
	local Player
	
	for i = 1, #Players do
		if (Players[i].Name == name) then
			Player = Players[i]
			tremove(Players, i)
			break
		end
	end
	
	if Player then
		Player:Hide()
		SortPlayers()
	end
end

-- Admin panel
local Admin = CreateFrame("Frame", "SilentGamblerAdmin", GUI, "BackdropTemplate")
Admin:SetSize(120, 96)
Admin:SetPoint("BOTTOM", GUI, "TOP", 0, 23)
SetTemplate(Admin)
Admin:Hide()

local AdminTop = CreateFrame("Frame", nil, Admin, "BackdropTemplate")
AdminTop:SetSize(120, 21)
AdminTop:SetPoint("BOTTOM", Admin, "TOP", 0, -1)
SetTemplateDark(AdminTop)

AdminTop.TopLabel = AdminTop:CreateFontString(nil, "OVERLAY")
AdminTop.TopLabel:SetPoint("TOPLEFT", AdminTop, "TOPLEFT", 4, -4)
AdminTop.TopLabel:SetFont(Font, 16)
AdminTop.TopLabel:SetTextColor(unpack(FontColor))
AdminTop.TopLabel:SetText("Set a roll value")
AdminTop.TopLabel:SetShadowOffset(1.25, -1.25)
AdminTop.TopLabel:SetShadowColor(0, 0, 0)

-- Editbox
local EditBoxOnMouseDown = function(self)
	self:SetAutoFocus(true)
end

local EditBoxOnEditFocusLost = function(self)
	self:SetAutoFocus(false)
end

local EditBoxOnEscapePressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
end

local EditBoxOnEnterPressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
	
	local Value = self:GetText()
	
	if (Value == "" or Value == " ") then
		self:SetText(CurrentRollValue)
		
		return
	end
end

local EditBox = CreateFrame("Frame", nil, Admin, "BackdropTemplate")
EditBox:SetPoint("TOPLEFT", Admin, 3, -3)
EditBox:SetSize(114, 21)
SetTemplateDark(EditBox)
EditBox:EnableMouse(true)

EditBox.Box = CreateFrame("EditBox", nil, EditBox)
EditBox.Box:SetPoint("TOPLEFT", EditBox, 4, -4)
EditBox.Box:SetPoint("BOTTOMRIGHT", EditBox, -4, 2)
EditBox.Box:SetFont(Font, 16)
EditBox.Box:SetText(CurrentRollValue)
EditBox.Box:SetShadowColor(0, 0, 0)
EditBox.Box:SetShadowOffset(1.25, -1.25)
EditBox.Box:SetMaxLetters(6)
EditBox.Box:SetAutoFocus(false)
EditBox.Box:SetNumeric(true)
EditBox.Box:EnableKeyboard(true)
EditBox.Box:EnableMouse(true)
EditBox.Box:SetScript("OnMouseDown", EditBoxOnMouseDown)
EditBox.Box:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
EditBox.Box:SetScript("OnEnterPressed", EditBoxOnEnterPressed)
EditBox.Box:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)

AcceptRolls = CreateFrame("Frame", nil, Admin, "BackdropTemplate")
AcceptRolls:SetSize(114, 21)
AcceptRolls:SetPoint("TOPLEFT", EditBox, "BOTTOMLEFT", 0, -2)
SetTemplateDark(AcceptRolls)
AcceptRolls:SetScript("OnEnter", ButtonOnEnter)
AcceptRolls:SetScript("OnLeave", ButtonOnLeave)
AcceptRolls:SetScript("OnMouseUp", function(self)
	SendEvent("SET_ROLL", EditBox.Box:GetText())
	SendEvent("START_GAME")
end)

AcceptRolls.Label = AcceptRolls:CreateFontString(nil, "OVERLAY")
AcceptRolls.Label:SetPoint("CENTER", AcceptRolls, 0, 0)
AcceptRolls.Label:SetFont(Font, 14)
AcceptRolls.Label:SetJustifyH("CENTER")
AcceptRolls.Label:SetTextColor(unpack(FontColor))
AcceptRolls.Label:SetText("Accept Rolls")
AcceptRolls.Label:SetShadowOffset(1.25, -1.25)
AcceptRolls.Label:SetShadowColor(0, 0, 0)

-- Close
CloseGame = CreateFrame("Frame", nil, Admin, "BackdropTemplate")
CloseGame:SetSize(114, 21)
CloseGame:SetPoint("TOPLEFT", AcceptRolls, "BOTTOMLEFT", 0, -2)
SetTemplateDark(CloseGame)
CloseGame:SetScript("OnEnter", ButtonOnEnter)
CloseGame:SetScript("OnLeave", ButtonOnLeave)
CloseGame:SetScript("OnMouseUp", function(self)
	SendEvent("CLOSE_GAME")
end)

CloseGame.Label = CloseGame:CreateFontString(nil, "OVERLAY")
CloseGame.Label:SetPoint("CENTER", CloseGame, 0, 0)
CloseGame.Label:SetFont(Font, 14)
CloseGame.Label:SetJustifyH("CENTER")
CloseGame.Label:SetTextColor(unpack(FontColor))
CloseGame.Label:SetText("Close Game")
CloseGame.Label:SetShadowOffset(1.25, -1.25)
CloseGame.Label:SetShadowColor(0, 0, 0)

-- Reset
Reset = CreateFrame("Frame", nil, Admin, "BackdropTemplate")
Reset:SetSize(114, 21)
Reset:SetPoint("TOPLEFT", CloseGame, "BOTTOMLEFT", 0, -2)
SetTemplateDark(Reset)
Reset:SetScript("OnEnter", ButtonOnEnter)
Reset:SetScript("OnLeave", ButtonOnLeave)
Reset:SetScript("OnMouseUp", function(self)
	SendEvent("RESET_ALL")
end)

Reset.Label = Reset:CreateFontString(nil, "OVERLAY")
Reset.Label:SetPoint("CENTER", Reset, 0, 0)
Reset.Label:SetFont(Font, 14)
Reset.Label:SetJustifyH("CENTER")
Reset.Label:SetTextColor(unpack(FontColor))
Reset.Label:SetText("Reset Game")
Reset.Label:SetShadowOffset(1.25, -1.25)
Reset.Label:SetShadowColor(0, 0, 0)

EnterButton:Disable()
PassButton:Disable()
RollButton:Disable()

-- Chat window
local ChatFrame = CreateFrame("Frame", nil, GUI, "BackdropTemplate")
ChatFrame:SetPoint("TOPLEFT", Top, "TOPRIGHT", 2, 0)
ChatFrame:SetSize(260, 180)
SetTemplate(ChatFrame)
ChatFrame:Hide()

ChatFrame.Chat = CreateFrame("ScrollingMessageFrame", nil, ChatFrame)
ChatFrame.Chat:SetPoint("CENTER", ChatFrame, 2, 3)
ChatFrame.Chat:SetSize(ChatFrame:GetWidth() - 8, ChatFrame:GetHeight() - 6)
ChatFrame.Chat:SetFont(Font, 14)
ChatFrame.Chat:SetShadowColor(0, 0, 0)
ChatFrame.Chat:SetShadowOffset(1.25, -1.25)
ChatFrame.Chat:SetFading(false)
ChatFrame.Chat:SetJustifyH("LEFT")
ChatFrame.Chat:SetMaxLines(50)
ChatFrame.Chat:SetScript("OnMouseWheel", function(self, delta)
	if (delta == 1) then
		self:ScrollUp()
	else
		self:ScrollDown()
	end
end)

-- Editbox
local EditBoxOnMouseDown = function(self)
	self:SetText("")
	self:SetAutoFocus(true)
end

local EditBoxOnEditFocusLost = function(self)
	self:SetAutoFocus(false)
end

local EditBoxOnEscapePressed = function(self)
	self:SetText("")

	self:SetAutoFocus(false)
	self:ClearFocus()
	
	self:SetText("|cffB0B0B0Chat...|r")
end

local EditBoxOnEnterPressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
	
	local Value = self:GetText()
	
	if (Value == "" or Value == " ") then
		self:SetText("|cffB0B0B0Chat...|r")
		
		return
	end
	
	SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, Value))
	
		local Hex = RAID_CLASS_COLORS[PlayerClass].colorStr
		
		ChatFrame.Chat:AddMessage(format("[|c%s%s|r]: %s", Hex, PlayerName, Value))
	
	self:SetText("|cffB0B0B0Chat...|r")
end

local EditBox = CreateFrame("Frame", nil, ChatFrame, "BackdropTemplate")
EditBox:SetPoint("TOPLEFT", ChatFrame, "BOTTOMLEFT", 0, 1)
EditBox:SetSize(260, 21)
SetTemplateDark(EditBox)
EditBox:EnableMouse(true)

EditBox.Box = CreateFrame("EditBox", nil, EditBox)
EditBox.Box:SetPoint("TOPLEFT", EditBox, 5, -1)
EditBox.Box:SetPoint("BOTTOMRIGHT", EditBox, -5, 1)
EditBox.Box:SetFont(Font, 14)
EditBox.Box:SetText("|cffB0B0B0Chat...|r")
EditBox.Box:SetShadowColor(0, 0, 0)
EditBox.Box:SetShadowOffset(1.25, -1.25)
EditBox.Box:SetMaxLetters(255)
EditBox.Box:SetAutoFocus(false)
EditBox.Box:EnableKeyboard(true)
EditBox.Box:EnableMouse(true)
EditBox.Box:SetScript("OnMouseDown", EditBoxOnMouseDown)
EditBox.Box:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
EditBox.Box:SetScript("OnEnterPressed", EditBoxOnEnterPressed)
EditBox.Box:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)

-- Chat toggle
local ChatToggle = CreateFrame("Button", nil, GUI, "BackdropTemplate")
ChatToggle:SetSize(21, 21)
ChatToggle:SetPoint("BOTTOMRIGHT", Bottom, "BOTTOMRIGHT", 0, 0)
ChatToggle:SetFrameStrata("MEDIUM")
SetTemplateDark(ChatToggle)
ChatToggle:SetScript("OnMouseUp", function(self)
	if self.NeedsReset then
		self.Arrow:SetTextColor(1, 1, 1)
		self.NeedsReset = false
	end
	
	if ChatFrame:IsShown() then
		ChatFrame:Hide()
		self.Arrow:SetText("►")
	else
		ChatFrame:Show()
		self.Arrow:SetText("◄")
	end
end)

ChatToggle.Arrow = ChatToggle:CreateFontString(nil, "OVERLAY")
ChatToggle.Arrow:SetPoint("CENTER", ChatToggle, "CENTER", 0, 0)
ChatToggle.Arrow:SetFont("Interface\\AddOns\\SilentGambler\\Arial.ttf", 12)
ChatToggle.Arrow:SetTextColor(unpack(FontColor))
ChatToggle.Arrow:SetText("►")
ChatToggle.Arrow:SetShadowOffset(1.25, -1.25)
ChatToggle.Arrow:SetShadowColor(0, 0, 0)

-- Debug Stuff. Will be cleaned up.

-- /run __SGAdd("Vexisle")
-- /run __SGAdd("Vexisle"); __SGAdd("Cobelarusu"); __SGAdd("Banktre"); __SGAdd("Obsidiana")
__SGAdd = AddPlayer
__SGRem = RemovePlayer --/run __SGRem("Banktre")
__SGRoll = PlayerRoll -- /run __SGRoll("Vexisle"); __SGRoll("Cobelarusu"); __SGRoll("Banktre"); __SGRoll("Obsidiana")

--- /run SilentGamblerAdmin:Show()

-- /run __SGAdd("Vexxisle"); __SGAdd("Cobelarusu"); __SGAdd("Banktre"); __SGAdd("Obsidiana"); __SGRoll("Vexxisle"); __SGRoll("Cobelarusu"); __SGRoll("Banktre"); __SGRoll("Obsidiana")

-- /run __SGAdd("Vexisle"); __SGAdd("Cobelarusu"); __SGAdd("Banktre"); __SGAdd("Obsidiana"); __SGAdd("Bigroostie"); __SGAdd("Schwanks"); __SGRoll("Vexisle"); __SGRoll("Cobelarusu"); __SGRoll("Banktre"); __SGRoll("Obsidiana")

-- /run __DUMPSGSTATS()

local Events = {}

Events["RESET_ALL"] = function()
	for i = 1, #Players do
		Players[1].HasRolled = false
		Players[1].Total:SetText("")
		RemovePlayer(Players[1].Name)
	end
	
	SilentGambler.BottomLabel:SetText("")
	
	EnterButton:Disable()
	PassButton:Disable()
	RollButton:Disable()
end

Events["ADD_PLAYER"] = function(name)
	AddPlayer(name)
end

Events["REMOVE_PLAYER"] = function(name)
	RemovePlayer(name)
end

Events["PLAYER_ROLL"] = function(name, value)
	for i = 1, #Players do
		if (Players[i].Name == name and not Players[i].HasRolled) then
			Players[i].HasRolled = true
			Players[i].Total:SetText(Comma(value))
			
			tinsert(Rolls, {Players[i].Name, tonumber(value)})
			
			CheckRolls()
		end
	end
end

Events["SET_ROLL"] = function(value)
	CurrentRollValue = tonumber(value)
	
	GUI.BottomLabel:SetText("Current roll is for " .. Comma(CurrentRollValue) .. ".")
end

Events["START_GAME"] = function()
	if (not SilentGambler:IsShown()) then
		-- Alert the player that a roll is happening.
		print("A roll is happening! Type /sg or /sgam to watch or join.")
	end
	
	EnterButton:Enable()
	PassButton:Enable()
end

Events["CLOSE_GAME"] = function()
	EnterButton:Disable()
	PassButton:Disable()
	RollButton:Disable()
	
	for i = 1, #Players do
		if (Players[i].Name == PlayerName) then
			RollButton:Enable()
			
			break
		end
	end
end

Events["CALL_PAYOUT"] = function(message)
	SilentGambler.BottomLabel:SetText(message)
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("CHAT_MSG_ADDON")
EventFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
	if (prefix ~= "SilentGambler") then -- We don't need our own events either... do we?
		return
	end
	
	local Event, Arg1, Arg2 = split(":", message)
	
	if Events[Event] then
		Events[Event](Arg1, Arg2)
	elseif (Event == "CHAT_MSG") then
		if (not ChatFrame:IsShown()) then
			-- Alert that there's chatting happening.
			ChatToggle.Arrow:SetTextColor(1, 1, 0)
			ChatToggle.NeedsReset = true
		end
		
		local Player, Class, Message = strmatch(message, "CHAT_MSG:(%a+):(%a+):(.*):nil")
		local Hex = "|c" .. RAID_CLASS_COLORS[Class].colorStr
		
		ChatFrame.Chat:AddMessage(format("[%s%s|r]: %s", Hex, Player, Message))
	end
end)

SLASH_SILENTGAMBLER1 = "/sg"
SLASH_SILENTGAMBLER2 = "/sgam"
SlashCmdList["SILENTGAMBLER"] = function(cmd)
	if (cmd == "admin") then
		if (not GUI:IsShown()) then
			GUI:Show()
		end
		
		if Admin:IsShown() then
			Admin:Hide()
		else
			Admin:Show()
		end
	elseif (cmd == "stats") then
		PostStats()
	elseif (cmd == "fake") then
		__SGAdd("Vexxisle")
		__SGAdd("Cobelarusu")
		__SGAdd("Banktre")
		__SGAdd("Obsidiana")
		__SGRoll("Vexxisle")
		__SGRoll("Cobelarusu")
		__SGRoll("Banktre")
		__SGRoll("Obsidiana")
	else
		if GUI:IsShown() then
			GUI:Hide()
		else
			GUI:Show()
		end
	end
end

C_ChatInfo.RegisterAddonMessagePrefix("SilentGambler")

--[[
	Events needed. This time make the "leader" client respond to these events as well, instead of needing different sets of events.
	
	RESET_ALL -- Reset all players info.
	ADD_PLAYER -- Add a new player.
	REMOVE_PLAYER -- Remove a player.
	PLAYER_ROLL -- Recieve a player's roll information.
	SET_ROLL -- Tell all clients what the roll will be for.
	START_GAME -- Rolls are now open!
	CLOSE_GAME -- Stop taking new players. Let everyone roll.
	CALL_PAYOUT -- Tell everyone what the payout was.
	CHAT_MSG -- Send a chat message.
]]