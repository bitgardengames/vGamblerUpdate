local Name, AddOn = ...
local L = AddOn.L
local vGambler = AddOn.vGambler
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

LSM:Register("font", "PT Sans", "Interface\\Addons\\vGambler\\Assets\\PTSans.ttf")

vGambler.LSMFonts = LSM:HashTable("font")
vGambler.Blank = "Interface\\AddOns\\vGambler\\Assets\\HydraUIBlank.tga"

--[[
	To do

	- Play specific defeat/victory sounds if the player won/lost the roll
	- Language support
	- Maybe a window to merge character information
	- Implement sound dropdowns for LSM
	- Ban page scrolling
--]]

local table = table
local string = string
local math = math

vGambler.Tie = {}
vGambler.Players = {}
vGambler.UIPlayers = {}
vGambler.FreePlayers = {}

vGambler.ChannelColors = {
	{vGambler:HexToRGB("aaaaff")},
	{vGambler:HexToRGB("ff7f00")},
	{vGambler:HexToRGB("40ff40")},
	{vGambler:HexToRGB("e6cc80")},
	{vGambler:HexToRGB("aa00ff")},
}

vGambler.ChannelSelections = {
	PARTY,
	RAID,
	GUILD,
	"Test",
}

function vGambler:CreateBackdrops()
	if (self.Settings.UIStyle == 1) then
		self.LargeBackdrop = {
			bgFile = self.Blank,
			edgeFile = "Interface\\AddOns\\vGambler\\Assets\\HydraRound3.tga",
			edgeSize = 14,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
		}

		self.MediumBackdrop = {
			bgFile = self.Blank,
			edgeFile = "Interface\\AddOns\\vGambler\\Assets\\HydraRound2.tga",
			edgeSize = 14,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
		}

		self.SmallBackdrop = {
			bgFile = self.Blank,
			edgeFile = "Interface\\AddOns\\vGambler\\Assets\\HydraRound1.tga",
			edgeSize = 14,
			insets = {left = 2, right = 2, top = 2, bottom = 2},
		}
	else
		self.LargeBackdrop = {
			bgFile = self.Blank,
			edgeFile = self.Blank,
			edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		}

		self.MediumBackdrop = {
			bgFile = self.Blank,
			edgeFile = self.Blank,
			edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		}

		self.SmallBackdrop = {
			bgFile = self.Blank,
			edgeFile = self.Blank,
			edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		}
	end
end

function vGambler:CreateTooltip()
	local Tooltip = CreateFrame("GameTooltip", "vGamblerTooltip", UIParent, "GameTooltipTemplate")
	Tooltip:SetFrameLevel(3)
	Tooltip.NineSlice:SetAlpha(0)

	Tooltip.Outside = CreateFrame("Frame", nil, Tooltip, "BackdropTemplate")
	Tooltip.Outside:SetPoint("TOPLEFT", Tooltip, -4, 4)
	Tooltip.Outside:SetPoint("BOTTOMRIGHT", Tooltip, 4, -4)
	Tooltip.Outside:SetBackdrop(self.MediumBackdrop)
	Tooltip.Outside:SetBackdropColor(0.125, 0.133, 0.145)
	Tooltip.Outside:SetBackdropBorderColor(0.125, 0.133, 0.145)
	Tooltip.Outside:SetFrameLevel(1)

	Tooltip.Inside = CreateFrame("Frame", nil, Tooltip, "BackdropTemplate")
	Tooltip.Inside:SetPoint("TOPLEFT", Tooltip, 0, -0)
	Tooltip.Inside:SetPoint("BOTTOMRIGHT", Tooltip, 0, 0)
	Tooltip.Inside:SetBackdrop(vGambler.SmallBackdrop)
	Tooltip.Inside:SetBackdropColor(0.184, 0.192, 0.211)
	Tooltip.Inside:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Tooltip.Inside:SetFrameLevel(2)

	self.Tooltip = Tooltip
end

function vGambler:SendMessage(message)
	local Channel = self.GameChannel or self.Settings.Channel

	if (Channel == 4)then
		self.ChatWindow:AddMessage(message)

		self:UpdateChatScrollBar()
	else
		-- Just strip hex stuff here so that I can color all of the messages throughout the addon
		message = string.gsub(message, "|r", "")
		message = string.gsub(message, "|c%x%x%x%x%x%x%x%x", "")

		SendChatMessage(message, self.ChannelSelections[Channel])
	end
end

function vGambler:Comma(number)
	if (not number) then
		return
	end

   	local Left, Number = string.match(math.floor(number + 0.5), "^([^%d]*%d)(%d+)(.-)$")

	return Left and Left .. string.reverse(string.gsub(string.reverse(Number), "(%d%d%d)", "%1,")) or tostring(number)
end

function vGambler:ListPlayers(data) -- Can't just table.concat the player table
	local List = ""

	for i = 1, #data do
		if (i == 1) then
			List = List .. data[i].DisplayName
		else
			List = List .. ", " .. data[i].DisplayName
		end
	end

	return List
end

function vGambler:WindowButtonMouseUp()
	self.Label:SetPoint("LEFT", self, 5, -0.5)

	if vGambler.Settings.PlaySounds then
		PlaySound(SOUNDKIT.UI_IG_STORE_PAGE_NAV_BUTTON)
	end
end

function vGambler:WindowButtonMouseDown()
	self.Label:SetPoint("LEFT", self, 6, -1.5)
end

function vGambler:WindowButtonOnEnter()
	self:SetBackdropColor(0.25, 0.266, 0.294)
	self:SetBackdropBorderColor(0.25, 0.266, 0.294)
end

function vGambler:WindowButtonOnLeave()
	self:SetBackdropColor(0.184, 0.192, 0.211)
	self:SetBackdropBorderColor(0.184, 0.192, 0.211)
end

function vGambler:DisableGameButton(id)
	for i = 1, #self.Window.GameButtons do
		if (self.Window.GameButtons[i].ID and self.Window.GameButtons[i].ID == id) then
			self.Window.GameButtons[i]:EnableMouse(false)
			self.Window.GameButtons[i].Animation:SetChange(0.6, 0.6, 0.6)
			self.Window.GameButtons[i].Animation:Play()

			break
		end
	end
end

function vGambler:EnableGameButton(id)
	for i = 1, #self.Window.GameButtons do
		if (self.Window.GameButtons[i].ID and self.Window.GameButtons[i].ID == id) then
			self.Window.GameButtons[i]:EnableMouse(true)

			if (self.Window.GameButtons[i].ID == "Channel") then
				self.Window.GameButtons[i].Animation:SetChange(unpack(vGambler.ChannelColors[self.Settings.Channel]))
			else
				self.Window.GameButtons[i].Animation:SetChange(1, 1, 1)
			end

			self.Window.GameButtons[i].Animation:Play()

			break
		end
	end
end

function vGambler:DisablePlayButton(id)
	for i = 1, #self.Window.PlayButtons do
		if (self.Window.PlayButtons[i].ID and self.Window.PlayButtons[i].ID == id) then
			self.Window.PlayButtons[i]:EnableMouse(false)
			self.Window.PlayButtons[i].Animation:SetChange(0.6, 0.6, 0.6)
			self.Window.PlayButtons[i].Animation:Play()

			break
		end
	end
end

function vGambler:EnablePlayButton(id)
	for i = 1, #self.Window.PlayButtons do
		if (self.Window.PlayButtons[i].ID and self.Window.PlayButtons[i].ID == id) then
			self.Window.PlayButtons[i]:EnableMouse(true)
			self.Window.PlayButtons[i].Animation:SetChange(1, 1, 1)
			self.Window.PlayButtons[i].Animation:Play()

			break
		end
	end
end

function vGambler:AddGameHeader(t, parent, name)
	local Header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Header:SetSize(parent:GetWidth() - 8, 24)
	Header:SetBackdrop(self.SmallBackdrop)
	Header:SetBackdropColor(0.25, 0.266, 0.294)
	Header:SetBackdropBorderColor(0.25, 0.266, 0.294)

	Header.Label = Header:CreateFontString(nil, "OVERLAY")
	Header.Label:SetPoint("LEFT", Header, 6, -0.5)
	Header.Label:SetFont(self.Font, self.Settings.FontSize)
	Header.Label:SetText(string.format("|cffFFC44D%s|r", name))
	Header.Label:SetShadowColor(0.029, 0.029, 0.051)
	Header.Label:SetShadowOffset(0, -1)

	table.insert(t, Header)

	return Header
end

function vGambler:AddGameButton(t, parent, id, name, func)
	local Button = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Button:SetSize(parent:GetWidth() - 8, 24)
	Button:SetBackdrop(self.SmallBackdrop)
	Button:SetBackdropColor(0.184, 0.192, 0.211)
	Button:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Button:SetScript("OnMouseUp", func)
	Button:SetScript("OnEnter", self.WindowButtonOnEnter)
	Button:SetScript("OnLeave", self.WindowButtonOnLeave)
	Button:HookScript("OnMouseUp", self.WindowButtonMouseUp)
	Button:HookScript("OnMouseDown", self.WindowButtonMouseDown)
	Button.ID = id

	Button.Label = Button:CreateFontString(nil, "OVERLAY")
	Button.Label:SetPoint("LEFT", Button, 5, -0.5)
	Button.Label:SetFont(self.Font, self.Settings.FontSize)
	Button.Label:SetText(name)
	Button.Label:SetShadowColor(0.029, 0.029, 0.051)
	Button.Label:SetShadowOffset(0, -1)

	Button.Animation = LibMotion:CreateAnimation(Button.Label, "color")
	Button.Animation:SetColorType("text")
	Button.Animation:SetDuration(0.15)

	table.insert(t, Button)

	return Button
end

function vGambler:WindowInputEnterPressed()
	self:SetAutoFocus(false)
	self:ClearFocus()

	if self.Hook then
		self.Hook(self, self:GetText())
	end
end

function vGambler:WindowInputMouseDown()
	if (self.ID == "RollValue") then
		self:SetText(tonumber(vGambler.Settings.RollValue)) -- Get rid of the comma when we click
	end

	self:HighlightText()
	self:SetAutoFocus(true)
end

function vGambler:OnEditFocusLost()
	self:SetAutoFocus(false)
end

function vGambler:AddGameInput(t, parent, id, value, func)
	local Input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
	Input:SetSize(parent:GetWidth() - 8, 24)
	Input:SetBackdrop(self.SmallBackdrop)
	Input:SetBackdropColor(0.184, 0.192, 0.211)
	Input:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Input:SetFont(self.Font, self.Settings.FontSize, "")
	Input:SetShadowColor(0.029, 0.029, 0.051)
	Input:SetShadowOffset(0, -1)
	Input:SetText(value)
	Input:SetAutoFocus(false)
	Input:SetTextInsets(5, -5, 2, 0)
	Input:SetScript("OnMouseDown", self.WindowInputMouseDown)
	Input:SetScript("OnEnterPressed", self.WindowInputEnterPressed)
	Input:SetScript("OnEscapePressed", self.WindowInputEnterPressed)
	Input:SetScript("OnEditFocusLost", self.OnEditFocusLost)
	Input:SetScript("OnEnter", self.WindowButtonOnEnter)
	Input:SetScript("OnLeave", self.WindowButtonOnLeave)
	Input.Hook = func
	Input.ID = id

	Input.Animation = LibMotion:CreateAnimation(Input, "color")
	Input.Animation:SetColorType("editbox")
	Input.Animation:SetDuration(0.15)

	table.insert(t, Input)

	return Input
end

function vGambler:WindowDropdownMouseDown()
	if self.List:IsShown() then
		self.List:Hide()
	else
		self.List:Show()
	end
end

function vGambler:DropdownItemOnMouseUp()
	self.Button.List:Hide()

	if self.Button.List.Hook then
		self.Button.List:Hook(self.Button, self.Index)
	end

	if vGambler.Settings.PlaySounds then
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK)
	end
end

function vGambler:FontDropdownItemOnMouseUp()
	self.Button.List:Hide()

	if self.Button.List.Hook then
		self.Button.List:Hook(self.Index)
	end

	self.Button.Label:SetFont(vGambler.LSMFonts[self.Index], 12)
	self.Button.Label:SetText(self.Index)

	if vGambler.Settings.PlaySounds then
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK)
	end
end

function vGambler:AddGameDropdown(t, parent, id, text, selections, func)
	local Button = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Button:SetSize(parent:GetWidth() - 8, 24)
	Button:SetBackdrop(self.SmallBackdrop)
	Button:SetBackdropColor(0.184, 0.192, 0.211)
	Button:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Button:SetScript("OnMouseUp", self.WindowDropdownMouseDown)
	Button:SetScript("OnEnter", self.WindowButtonOnEnter)
	Button:SetScript("OnLeave", self.WindowButtonOnLeave)
	Button:HookScript("OnMouseUp", self.WindowButtonMouseUp)
	Button:HookScript("OnMouseDown", self.WindowButtonMouseDown)
	Button.ID = id

	Button.Label = Button:CreateFontString(nil, "OVERLAY")
	Button.Label:SetPoint("LEFT", Button, 5, -0.5)
	Button.Label:SetFont(self.Font, self.Settings.FontSize)
	Button.Label:SetText(text)
	Button.Label:SetShadowColor(0.029, 0.029, 0.051)
	Button.Label:SetShadowOffset(0, -1)

	if (id == "Channel") then
		Button.Label:SetTextColor(unpack(self.ChannelColors[self.Settings.Channel]))
	end

	Button.Animation = LibMotion:CreateAnimation(Button.Label, "color")
	Button.Animation:SetColorType("text")
	Button.Animation:SetDuration(0.15)

	Button.List = CreateFrame("Frame", nil, Button, "BackdropTemplate")
	Button.List:SetSize(138, (#selections * 24) + ((#selections - 1) * 2) + 8) -- 2 is button spacing, 8 is padding (4 * 2)
	Button.List:SetPoint("TOP", Button, "BOTTOM", 0, -2)
	Button.List:SetBackdrop(self.LargeBackdrop)
	Button.List:SetBackdropColor(0.125, 0.133, 0.145)
	Button.List:SetBackdropBorderColor(0.125, 0.133, 0.145)
	Button.List:EnableMouse(true)
	Button.List.Hook = func
	Button.List:Hide()

	Button.ListInset = CreateFrame("Frame", nil, Button.List, "BackdropTemplate")
	Button.ListInset:SetPoint("TOPLEFT", Button.List, 4, -4)
	Button.ListInset:SetPoint("BOTTOMRIGHT", Button.List, -4, 4)
	Button.ListInset:SetBackdrop(self.MediumBackdrop)
	Button.ListInset:SetBackdropColor(0.184, 0.192, 0.211)
	Button.ListInset:SetBackdropBorderColor(0.184, 0.192, 0.211)

	for i = 1, #selections do
		Button.List[i] = CreateFrame("Frame", nil, Button.ListInset, "BackdropTemplate")
		Button.List[i]:SetSize(130, 24)
		Button.List[i]:SetBackdrop(self.MediumBackdrop)
		Button.List[i]:SetBackdropColor(0.184, 0.192, 0.211)
		Button.List[i]:SetBackdropBorderColor(0.184, 0.192, 0.211)
		Button.List[i]:SetScript("OnMouseUp", self.DropdownItemOnMouseUp)
		Button.List[i]:SetScript("OnEnter", self.WindowButtonOnEnter)
		Button.List[i]:SetScript("OnLeave", self.WindowButtonOnLeave)
		Button.List[i].Button = Button
		Button.List[i].Index = i

		Button.List[i].Label = Button.List[i]:CreateFontString(nil, "OVERLAY")
		Button.List[i].Label:SetPoint("LEFT", Button.List[i], 5, -0.5)
		Button.List[i].Label:SetFont(self.Font, self.Settings.FontSize)
		Button.List[i].Label:SetText(selections[i])
		Button.List[i].Label:SetShadowColor(0.029, 0.029, 0.051)
		Button.List[i].Label:SetShadowOffset(0, -1)

		if (id == "Channel") then
			Button.List[i].Label:SetTextColor(unpack(self.ChannelColors[i]))
		end

		if (i == 1) then
			Button.List[i]:SetPoint("TOPLEFT", Button.List, 4, -4)
		else
			Button.List[i]:SetPoint("TOPLEFT", Button.List[i-1], "BOTTOMLEFT", 0, -2)
		end
	end

	table.insert(t, Button)

	return Button
end

function vGambler:SetFontScrollOffset(offset)
	self.Offset = offset

	if (self.Offset <= 1) then
		self.Offset = 1
	elseif (self.Offset > (#self.List - 8)) then
		self.Offset = self.Offset - 1
	end

	local First

	for i = 1, #self.List do
		self.List[i]:ClearAllPoints()

		if (i >= self.Offset) and (i <= self.Offset + 8) then
			if (not First) then
				self.List[i]:SetPoint("TOPLEFT", self.List, 4, -4)
				First = i
			else
				self.List[i]:SetPoint("TOPLEFT", self.List[i-1], "BOTTOMLEFT", 0, -2)
			end

			self.List[i]:Show()
		else
			self.List[i]:Hide()
		end
	end
end

function vGambler:FontScrollOnValueChanged(offset)
	self.Offset = offset

	vGambler.SetFontScrollOffset(self, offset)
end

function vGambler:FontScrollOnMouseWheel(delta)
	if (delta > 0) then -- Up
		self.Offset = self.Offset - 1

		if (self.Offset <= 1) then
			self.Offset = 1
		end
	else -- Down
		self.Offset = self.Offset + 1

		if (self.Offset > (#self.List - 8)) then
			self.Offset = self.Offset - 1
		end
	end

	vGambler.SetFontScrollOffset(self, self.Offset)
	self:SetValue(self.Offset)
end

function vGambler:AddFontDropdown(t, parent, id, value, func)
	local Button = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Button:SetSize(parent:GetWidth() - 8, 24)
	Button:SetBackdrop(self.SmallBackdrop)
	Button:SetBackdropColor(0.184, 0.192, 0.211)
	Button:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Button:SetScript("OnMouseUp", self.WindowDropdownMouseDown)
	Button:SetScript("OnEnter", self.WindowButtonOnEnter)
	Button:SetScript("OnLeave", self.WindowButtonOnLeave)
	Button:HookScript("OnMouseUp", self.WindowButtonMouseUp)
	Button:HookScript("OnMouseDown", self.WindowButtonMouseDown)
	Button.ID = id

	Button.Label = Button:CreateFontString(nil, "OVERLAY")
	Button.Label:SetPoint("LEFT", Button, 5, -0.5)
	Button.Label:SetSize(Button:GetWidth() - 10, 12)
	Button.Label:SetFont(self.LSMFonts[value] or self.LSMFonts["PT Sans"], self.Settings.FontSize)
	Button.Label:SetText(value)
	Button.Label:SetJustifyH("LEFT")
	Button.Label:SetShadowColor(0.029, 0.029, 0.051)
	Button.Label:SetShadowOffset(0, -1)

	Button.Animation = LibMotion:CreateAnimation(Button.Label, "color")
	Button.Animation:SetColorType("text")
	Button.Animation:SetDuration(0.15)

	Button.List = CreateFrame("Frame", nil, Button, "BackdropTemplate")
	Button.List:SetPoint("TOP", Button, "BOTTOM", 0, -2)
	Button.List:SetBackdrop(self.LargeBackdrop)
	Button.List:SetBackdropColor(0.125, 0.133, 0.145)
	Button.List:SetBackdropBorderColor(0.125, 0.133, 0.145)
	Button.List:EnableMouse(true)
	Button.List.Hook = func
	Button.List:Hide()

	Button.ListInset = CreateFrame("Frame", nil, Button.List, "BackdropTemplate")
	Button.ListInset:SetPoint("TOPLEFT", Button.List, 4, -4)
	Button.ListInset:SetPoint("BOTTOMRIGHT", Button.List, -4, 4)
	Button.ListInset:SetBackdrop(self.MediumBackdrop)
	Button.ListInset:SetBackdropColor(0.184, 0.192, 0.211)
	Button.ListInset:SetBackdropBorderColor(0.184, 0.192, 0.211)

	for font, path in next, self.LSMFonts do
		local MenuItem = CreateFrame("Frame", nil, Button.ListInset, "BackdropTemplate")
		MenuItem:SetSize(156, 24)
		MenuItem:SetBackdrop(self.MediumBackdrop)
		MenuItem:SetBackdropColor(0.184, 0.192, 0.211)
		MenuItem:SetBackdropBorderColor(0.184, 0.192, 0.211)
		MenuItem:SetScript("OnMouseUp", self.FontDropdownItemOnMouseUp)
		MenuItem:SetScript("OnEnter", self.WindowButtonOnEnter)
		MenuItem:SetScript("OnLeave", self.WindowButtonOnLeave)
		MenuItem.Button = Button
		MenuItem.Index = font

		MenuItem.Label = MenuItem:CreateFontString(nil, "OVERLAY")
		MenuItem.Label:SetPoint("LEFT", MenuItem, 5, 0)
		MenuItem.Label:SetSize(150, 12)
		MenuItem.Label:SetFont(path, 12)
		MenuItem.Label:SetText(font)
		MenuItem.Label:SetJustifyH("LEFT")
		MenuItem.Label:SetShadowColor(0.029, 0.029, 0.051)
		MenuItem.Label:SetShadowOffset(0, -1)

		table.insert(Button.List, MenuItem)
	end

	Button.List:SetSize(180, (9 * 24) + (8 * 2) + 8) -- 2 is button spacing, 8 is padding (4 * 2)

	local ListScroll = CreateFrame("Slider", nil, Button.List)
	ListScroll:SetWidth(12)
	ListScroll:SetPoint("TOPRIGHT", Button.List, -5, -2)
	ListScroll:SetPoint("BOTTOMRIGHT", Button.List, -5, 2)
	ListScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
	ListScroll:SetOrientation("VERTICAL")
	ListScroll:SetValueStep(1)
	ListScroll:SetObeyStepOnDrag(true)
	ListScroll:SetMinMaxValues(1, 1)
	ListScroll:SetMinMaxValues(1, math.max(1, #Button.List - 8))
	ListScroll:SetValue(1)
	ListScroll.Offset = 1
	ListScroll.List = Button.List
	ListScroll:SetScript("OnMouseWheel", self.FontScrollOnMouseWheel)
	ListScroll:SetScript("OnValueChanged", self.FontScrollOnValueChanged)
	ListScroll:SetScript("OnEnter", self.ScrollBarOnEnter)
	ListScroll:SetScript("OnLeave", self.ScrollBarOnLeave)
	ListScroll:SetScript("OnMouseDown", self.ScrollBarOnMouseDown)
	ListScroll:SetScript("OnMouseUp", self.ScrollBarOnMouseUp)

	local ListScrollThumb = ListScroll:GetThumbTexture()
	ListScrollThumb:SetSize(32, 32)
	ListScrollThumb:SetVertexColor(0.25, 0.266, 0.294)

	if (self.Settings.UIStyle == 1) then
		ListScroll:SetThumbTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
		ListScrollThumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga")
	else
		ListScrollThumb:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
	end

	self.SetFontScrollOffset(ListScroll, 1)

	table.insert(t, Button)

	return Button
end

function vGambler:CloseButtonOnEnter()
	self.Texture:SetVertexColor(0.9, 0.1, 0.1)
end

function vGambler:CloseButtonOnLeave()
	self.Texture:SetVertexColor(1, 1, 1)
end

function vGambler:CloseButtonMouseUp()
	vGambler:ToggleWindow()

	--[[if vGambler.Settings.PlaySounds then
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
	end]]
end

function vGambler:RollInputOnEnter(value)
	if (not value) then
		value = 10
	end

	value = math.max(2, tonumber(value))-- 2 is the minimum we can allow

	if (not vGamblerSettings) then
		vGamblerSettings = {}
	end

	vGamblerSettings.RollValue = value
	vGambler.Settings.RollValue = value

	self:SetText(vGambler:Comma(value))
end

function vGambler:ShowPage(name)
	for i = 1, #vGambler.Window.Pages do
		if (vGambler.Window.Pages[i].Name == name) then
			vGambler.Window.Pages[i]:Show()
		else
			vGambler.Window.Pages[i]:Hide()
		end
	end
end

function vGambler:TabOnMouseUp()
	vGambler:ShowPage(self.Name)
end

-- vGambler:CreatePageHook(name, func) -- So when the page is created, it can call hooks and feed Page through the function. To do later, easy enough to add in.
function vGambler:CreatePage(name, label)
	local Tab = CreateFrame("Frame", nil, self.Window.TabParent, "BackdropTemplate")
	Tab:SetSize(81, 24)
	Tab:SetBackdrop(self.SmallBackdrop)
	Tab:SetBackdropColor(0.184, 0.192, 0.211)
	Tab:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Tab:SetScript("OnMouseUp", self.TabOnMouseUp)
	Tab:SetScript("OnEnter", self.WindowButtonOnEnter)
	Tab:SetScript("OnLeave", self.WindowButtonOnLeave)
	Tab:HookScript("OnMouseUp", self.WindowButtonMouseUp)
	Tab:HookScript("OnMouseDown", self.WindowButtonMouseDown)
	Tab.Name = name

	Tab.Label = Tab:CreateFontString(nil, "OVERLAY")
	Tab.Label:SetPoint("LEFT", Tab, 5, -0.5)
	Tab.Label:SetFont(self.Font, self.Settings.FontSize, "")
	Tab.Label:SetText(label or name)
	Tab.Label:SetShadowColor(0.029, 0.029, 0.051)
	Tab.Label:SetShadowOffset(0, -1)

	local Page = CreateFrame("Frame", nil, self.Window)
	Page:SetSize(353, 366)
	Page:SetPoint("BOTTOMRIGHT", self.Window, -6, 6)
	Page.Name = name

	table.insert(self.Window.Tabs, Tab)
	table.insert(self.Window.Pages, Page)

	return Page
end

function vGambler:GetPage(name)
	for i = 1, #self.Window.Pages do
		if (self.Window.Pages[i].Name == name) then
			return self.Window.Pages[i]
		end
	end
end

function vGambler:CreateWindow()
	local Window = CreateFrame("Frame", "vGamblerWindow", UIParent, "BackdropTemplate")
	Window:SetSize(460, 408)
	Window:SetPoint("CENTER", UIParent, 0, 0)
	Window:SetBackdrop(self.LargeBackdrop)
	Window:SetBackdropColor(0.125, 0.133, 0.145)
	Window:SetBackdropBorderColor(0.125, 0.133, 0.145)
	Window:SetFrameStrata("DIALOG")
	Window:EnableMouse(true)
	Window:SetMovable(true)
	Window:SetClampedToScreen(true)
	Window:SetScript("OnMouseWheel", function() end) -- Just to stop zooming
	Window:SetScale(0.2)
	Window:Hide()

	Window.ScaleIn = LibMotion:CreateAnimation(Window, "Scale")
	Window.ScaleIn:SetEasing("in")
	Window.ScaleIn:SetDuration(0.15)
	Window.ScaleIn:SetChange(1)

	Window.FadeIn = LibMotion:CreateAnimation(Window, "Fade")
	Window.FadeIn:SetEasing("in")
	Window.FadeIn:SetDuration(0.15)
	Window.FadeIn:SetChange(1)

	Window.ScaleOut = LibMotion:CreateAnimation(Window, "Scale")
	Window.ScaleOut:SetEasing("out")
	Window.ScaleOut:SetDuration(0.15)
	Window.ScaleOut:SetChange(0.2)

	Window.FadeOut = LibMotion:CreateAnimation(Window, "Fade")
	Window.FadeOut:SetEasing("out")
	Window.FadeOut:SetDuration(0.15)
	Window.FadeOut:SetChange(0)
	Window.FadeOut:SetScript("OnFinished", function(self) self.Parent:Hide() end)

	local Header = CreateFrame("Frame", nil, Window, "BackdropTemplate")
	Header:SetHeight(24)
	Header:SetPoint("TOPLEFT", Window, 6, -6)
	Header:SetPoint("TOPRIGHT", Window, -6, -6)
	Header:SetBackdrop(self.MediumBackdrop)
	Header:SetBackdropColor(0.184, 0.192, 0.211)
	Header:SetBackdropBorderColor(0.184, 0.192, 0.211)
	Header:EnableMouse(true)
	Header:RegisterForDrag("LeftButton")
	Header:SetScript("OnDragStart", function() Window:StartMoving() end)
	Header:SetScript("OnDragStop", function() Window:StopMovingOrSizing() end)

	Window.Label = Header:CreateFontString(nil, "OVERLAY")
	Window.Label:SetPoint("TOPLEFT", Header, 7, -6)
	Window.Label:SetFont(self.Font, 14)
	Window.Label:SetText(L.WINDOW_TITLE)
	Window.Label:SetShadowColor(0.029, 0.029, 0.051)
	Window.Label:SetShadowOffset(0, -1)

	local Close = CreateFrame("Frame", nil, Header)
	Close:SetPoint("RIGHT", Header, 0, 0)
	Close:SetSize(24, 24)
	Close:SetScript("OnEnter", self.CloseButtonOnEnter)
	Close:SetScript("OnLeave", self.CloseButtonOnLeave)
	Close:SetScript("OnMouseUp", self.CloseButtonMouseUp)

	Close.Texture = Close:CreateTexture(nil, "OVERLAY")
	Close.Texture:SetPoint("CENTER", Close, 0, 0)
	Close.Texture:SetSize(16, 16)
	Close.Texture:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraUIClose.tga")

	Window.Tabs = {}
	Window.Pages = {}

	self.Window = Window

	local TabParent = CreateFrame("Frame", nil, Window, "BackdropTemplate")
	TabParent:SetSize(89, 366)
	TabParent:SetPoint("BOTTOMLEFT", Window, 6, 6)
	TabParent:SetBackdrop(self.MediumBackdrop)
	TabParent:SetBackdropColor(0.184, 0.192, 0.211)
	TabParent:SetBackdropBorderColor(0.184, 0.192, 0.211)

	Window.TabParent = TabParent

	local GamePage = self:CreatePage("Game", L.PAGE_GAME)
	local StatsPage = self:CreatePage("Leaderboard", L.PAGE_STATS)
	local AboutPage = self:CreatePage("Overview", L.PAGE_ABOUT)
	local HistoryPage = self:CreatePage("History", L.PAGE_HISTORY)
	local BansPage = self:CreatePage("Bans", L.PAGE_BANS)
	local SettingsPage = self:CreatePage("Settings", L.PAGE_SETTINGS)

	-- Page stuff, this will be moved later
	self:SetupControlsPage(GamePage)
	self:SetupStatsPage(StatsPage)
	self:SetupHistoryPage(HistoryPage)
	self:SetupBansPage(BansPage)
	self:SetupSettingsPage(SettingsPage)
	self:SetupAboutPage(AboutPage)

	self:SortButtonList(self.Window.Tabs, TabParent)

	self:ShowPage("Game")
end

function vGambler:SortButtonList(list, parent)
	for i = 1, #list do
		list[i]:ClearAllPoints()

		if (i == 1) then
			list[i]:SetPoint("TOPLEFT", parent, 4, -4)
		else
			list[i]:SetPoint("TOP", list[i-1], "BOTTOM", 0, -2)
		end
	end
end

function vGambler:PlayerOnEnter()
	if (not vGambler.Settings.PlayerTooltips or not vGamblerPlayers) then
		return
	end

	if vGambler.Players[self.Index] then
		local Stats = vGamblerPlayers[vGambler.Players[self.Index].DisplayName]

		if (not Stats) then
			-- Debug
			print("No stats debug", vGambler.Players[self.Index].DisplayName)

			return
		end

		vGambler.Tooltip:SetOwner(self, "ANCHOR_NONE")
		vGambler.Tooltip:SetPoint("BOTTOM", self, "TOP", 0, 5)
		vGambler.Tooltip:ClearLines()

		vGambler.Tooltip:AddDoubleLine(vGambler.Players[self.Index].DisplayName, string.format(L.TOTAL_GAMES, Stats.games), 1, 1, 1, 1, 1, 1)

		if Stats.wins then
			vGambler.Tooltip:AddLine(" ")
			vGambler.Tooltip:AddDoubleLine(L.WINS, Stats.wins, 1, 1, 1, 1, 1, 1)
			vGambler.Tooltip:AddDoubleLine(L.WIN_RATE, string.format(L.PERCENT, math.floor((Stats.wins / Stats.games) * 100 + 0.5)), 1, 1, 1, 1, 1, 1)
			vGambler.Tooltip:AddDoubleLine(L.GOLD_EARNED, vGambler:Comma(Stats.earnings), 1, 1, 1, 1, 1, 1)
		end

		if Stats.losses then
			vGambler.Tooltip:AddLine(" ")
			vGambler.Tooltip:AddDoubleLine(L.LOSSES, Stats.losses, 1, 1, 1, 1, 1, 1)
			vGambler.Tooltip:AddDoubleLine(L.LOSS_RATE, string.format(L.PERCENT, math.floor((Stats.losses / Stats.games) * 100 + 0.5)), 1, 1, 1, 1, 1, 1)
			vGambler.Tooltip:AddDoubleLine(L.GOLD_LOST, vGambler:Comma(Stats.loss), 1, 1, 1, 1, 1, 1)
		end

		if Stats.ties then
			vGambler.Tooltip:AddLine(" ")
			vGambler.Tooltip:AddDoubleLine(L.TIES, Stats.ties, 1, 1, 1, 1, 1, 1) -- Condense information. Ties: %s (%s won, %s lost); next line; Tie win rate: %s%%
			vGambler.Tooltip:AddDoubleLine(L.TIES_WON, Stats.tieswon or 0, 1, 1, 1, 1, 1, 1)
			vGambler.Tooltip:AddDoubleLine(L.TIES_LOST, Stats.tieslost or 0, 1, 1, 1, 1, 1, 1)
		end

		vGambler.Tooltip:Show()
	end

	--self:SetStatusBarColor(0.29, 0.298, 0.373)
end

function vGambler:PlayerOnLeave()
	vGambler.Tooltip:Hide()

	--[[self:SetStatusBarColor(0.25, 0.258, 0.333)
	if self.Settings.ColoredBars then
			local R, G, B = self:HexToRGB(self.Players[i].Hex)
			self:SetStatusBarColor(R * 0.9, G * 0.9, B * 0.9)
		else
		self:SetStatusBarColor(0.25, 0.258, 0.333)
	end]]
end

function vGambler:AddPlayer(name, guid)
	local Name = string.match(name, "|c%x%x%x%x%x%x%x%x(%S+)|r") or name
	local Hex

	for i = 1, #self.Players do
		if (self.Players[i].Name == Name) then
			return
		end
	end

	if guid then
		local Class, ClassName = GetPlayerInfoByGUID(guid)

		if ClassName then
			Hex = RAID_CLASS_COLORS[ClassName].colorStr
			Hex = string.sub(Hex, 3, 8)
			name = string.format("|cff%s%s|r", Hex, Name)
		end
	else -- This is a test player
		Hex = string.match(name, "|c%x%x(%x+)") or "FFFFFF"
	end

	table.insert(self.Players, {Name = Name, DisplayName = name, Roll = 0, Hex = Hex})

	self:AddPlayerUI()

	if (self.IsTestGame and self.TestCount == #self.Players) then
		self:CloseGame()
	end
end

function vGambler:RemovePlayer(name)
	for i = 1, #self.Players do
		if (self.Players[i].Name == name) then
			table.remove(self.Players, i)
			self:RemoveAllPlayersUI()

			for j = 1, #self.Players do
				self:AddPlayerUI()
			end

			self:SortPlayerList()
			return true
		end
	end
end

function vGambler:RemoveAllPlayers()
	for i = #self.UIPlayers, 1, -1 do
		self.UIPlayers[i]:Hide()
		self.UIPlayers[i].Bar:SetAlpha(0)
		self.UIPlayers[i].Bar:SetValue(0)

		table.insert(self.FreePlayers, table.remove(self.UIPlayers, i))
	end

	self.Window.Label:SetText(L.WINDOW_TITLE)

	self.Window.GameArea.ScrollBar:SetMinMaxValues(1, 1)
	self.Window.GameArea.ScrollBar:SetValue(1)
end

function vGambler:AddPlayerUI()
	local Player

	if self.FreePlayers[1] then
		Player = table.remove(self.FreePlayers, 1)
	else
		Player = CreateFrame("Frame", nil, self.Window.GameArea)
		Player:SetSize(175, 24)
		Player:SetFrameLevel(20)
		Player:SetScript("OnEnter", self.PlayerOnEnter)
		Player:SetScript("OnLeave", self.PlayerOnLeave)
		Player:SetScript("OnMouseWheel", self.PlayerOnMouseWheel)
		Player:SetAlpha(0)

		Player.Bar = CreateFrame("StatusBar", nil, Player)
		Player.Bar:SetAllPoints()
		Player.Bar:SetMinMaxValues(0, 1)
		Player.Bar:SetValue(0)
		Player.Bar:SetFrameLevel(10)
		Player.Bar:SetAlpha(0)

		if (self.Settings.UIStyle == 1) then
			Player.Bar:SetStatusBarTexture("Interface\\AddOns\\vGambler\\Assets\\HydraRoundBar.tga")
		else
			Player.Bar:SetStatusBarTexture(self.Blank)
		end

		Player.Fade = LibMotion:CreateAnimation(Player, "fade")
		Player.Fade:SetDuration(0.25)
		Player.Fade:SetChange(1)

		Player.Bar.Fade = LibMotion:CreateAnimation(Player.Bar, "fade")
		Player.Bar.Fade:SetDuration(0.3)
		Player.Bar.Fade:SetChange(1)

		Player.Label = Player:CreateFontString(nil, "OVERLAY")
		Player.Label:SetPoint("LEFT", Player, 5, -0.5)
		Player.Label:SetFont(self.GameFont, 12)
		Player.Label:SetShadowColor(0, 0, 0)
		Player.Label:SetShadowOffset(1, -1)

		Player.RollValue = Player:CreateFontString(nil, "OVERLAY")
		Player.RollValue:SetPoint("RIGHT", Player, -5, -0.5)
		Player.RollValue:SetFont(self.GameFont, 12)
		Player.RollValue:SetText("-")
		Player.RollValue:SetShadowColor(0, 0, 0)
		Player.RollValue:SetShadowOffset(1, -1)
	end

	Player.Index = #self.UIPlayers + 1
	Player:SetAlpha(0)
	--Player:Show()
	Player.Fade:Play()

	table.insert(self.UIPlayers, Player)

	self:SetGameScrollOffset(1)

	self:SortPlayerList()
end

function vGambler:RemovePlayerUI()
	self.UIPlayers[1]:Hide()
	self.UIPlayers[1].Bar:SetAlpha(0)
	self.UIPlayers[1].Bar:SetValue(0)

	table.insert(self.FreePlayers, table.remove(self.UIPlayers, 1))

	self:SortPlayerList()
end

function vGambler:RemoveAllPlayersUI()
	for i = #self.UIPlayers, 1, -1 do
		self.UIPlayers[1]:Hide()
		self.UIPlayers[1].Bar:SetAlpha(0)
		self.UIPlayers[1].Bar:SetValue(0)

		table.insert(self.FreePlayers, table.remove(self.UIPlayers, 1))
	end

	self.Window.Label:SetText(L.WINDOW_TITLE)

	self.Window.GameArea.ScrollBar:SetMinMaxValues(1, 1)
	self.Window.GameArea.ScrollBar:SetValue(1)
end

function vGambler:SortPlayerList(sort)
	local Lowest -- This is just flavor to color the bottom roll

	if sort then
		table.sort(self.Players, function(a, b)
			return a.Roll > b.Roll
		end)

		-- After we just sorted, can't I just grab the last index now?? self.Players[#self.Players].Roll should be lowest..
		for i = 1, #self.Players do
			if (self.Players[i].Roll and self.Players[i].Roll > 0) then
				if (not Lowest) then
					Lowest = self.Players[i].Roll
				else
					Lowest = math.min(Lowest, self.Players[i].Roll)
				end
			end
		end
	end

	for i = 1, #self.Players do
		if (not self.UIPlayers[i]) then
			return
		end

		if (self.Players[i].Roll == 0) then
			self.UIPlayers[i].RollValue:SetText("-")
			self.UIPlayers[i].RollValue:SetTextColor(1, 1, 1)
		else
			self.UIPlayers[i].RollValue:SetText(self:Comma(self.Players[i].Roll))

			self.UIPlayers[i].Bar:SetMinMaxValues(0, self.GameWager or self.Settings.RollValue)
			self.UIPlayers[i].Bar:SetValue(self.Players[i].Roll)
			self.UIPlayers[i].Fade:Play()
			self.UIPlayers[i].Bar.Fade:Play()

			self.UIPlayers[i].RollValue:SetTextColor(1, 1, 1)

			if (self.Players[i].Roll == self.Players[1].Roll) then
				self.UIPlayers[i].RollValue:SetTextColor(0.05, 0.95, 0.05)
			elseif (self.Players[i].Roll == Lowest) then
				self.UIPlayers[i].RollValue:SetTextColor(0.95, 0.05, 0.05)
			else
				self.UIPlayers[i].RollValue:SetTextColor(1, 1, 1)
			end
		end

		if self.Settings.ColoredBars then
			local R, G, B = self:HexToRGB(self.Players[i].Hex)

			self.UIPlayers[i].Bar:SetStatusBarColor(R * 0.70, G * 0.70, B * 0.70)

			if self.Settings.PlayerNumbers then
				self.UIPlayers[i].Label:SetText(string.format(L.NUMBERED_PLAYER, i, self.Players[i].Name))
			else
				self.UIPlayers[i].Label:SetText(self.Players[i].Name)
			end
		else
			self.UIPlayers[i].Bar:SetStatusBarColor(0.25, 0.266, 0.294)

			if self.Settings.PlayerNumbers then
				self.UIPlayers[i].Label:SetText(string.format(L.NUMBERED_PLAYER, i, self.Players[i].DisplayName))
			else
				self.UIPlayers[i].Label:SetText(self.Players[i].DisplayName)
			end
		end
	end

	if (#self.Players > 0) then
		self.Window.Label:SetText(string.format(L.WINDOW_PROGRESS, self.Rolled or 0, #self.Players))
	else
		self.Window.Label:SetText(L.WINDOW_TITLE)
	end
end

function vGambler:ToggleWindow()
	if (not self.Window) then
		self:CreateWindow()
	end

	if self.Window:IsShown() then
		self:HideWindow()
	else
		self:ShowWindow()
	end

end

function vGambler:ShowWindow()
	if (not self.Window) then
		self:CreateWindow()

		return
	end

	if (not self.Window:IsShown()) then
		self.Window:SetAlpha(0)
		self.Window:Show()
		self.Window.ScaleIn:Play()
		self.Window.FadeIn:Play()

		if self.Settings.PlaySounds then
			PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
		end
	end
end

function vGambler:HideWindow()
	if (not self.Window) then
		return
	end

	if self.Window:IsShown() then
		self.Window.ScaleOut:Play()
		self.Window.FadeOut:Play()

		if self.Settings.PlaySounds then
			PlaySound(SOUNDKIT.MONEY_FRAME_CLOSE)
		end
	end
end

function vGambler:PLAYER_ENTERING_WORLD()
	if vGamblerSettings then
		for name, value in next, vGamblerSettings do
			self.Settings[name] = value
		end
	end

	self.Font = self.LSMFonts[self.Settings.UIFont]
	self.GameFont = self.LSMFonts[self.Settings.GameFont]

	-- If the font isn't available anymore, use PTSans
	if (not self.Font) then
		self.Font = "Interface\\AddOns\\vGambler\\Assets\\PTSans.ttf"

		-- Update the font dropdown menu to PTSans as well
	end

	if (not self.GameFont) then
		self.GameFont = "Interface\\AddOns\\vGambler\\Assets\\PTSans.ttf"
	end

	self:CreateBackdrops()
	self:CreateTooltip()

	-- Minimap Icon
	self.LibDBIcon = LibStub("LibDBIcon-1.0")
	local MinimapButton = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("vGambler", {label = "vGambler", type = "data source", icon = "Interface\\ICONS\\inv_misc_dice_02", text = "vGambler"})

	if (self.LibDBIcon and not self.LibDBIcon:IsRegistered("vGambler")) then
		self.LibDBIcon:Register("vGambler", MinimapButton)
	end

	MinimapButton.OnClick = function()
		vGambler:ToggleWindow()
	end

	MinimapButton.OnEnter = function(self)
		vGambler.Tooltip:SetOwner(self, "ANCHOR_NONE")
		vGambler.Tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
		vGambler.Tooltip:ClearLines()
		vGambler.Tooltip:AddLine(L.WINDOW_TITLE)
		vGambler.Tooltip:AddLine(" ")
		vGambler.Tooltip:AddLine(L.MINIMAP_TOOLTIP)
		vGambler.Tooltip:Show()
	end

	MinimapButton.OnLeave = function()
		vGambler.Tooltip:Hide()
	end

	if self.Settings.MinimapIcon then
		self.LibDBIcon:Show("vGambler")
	else
		self.LibDBIcon:Hide("vGambler")
	end

	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function vGambler:OnEvent(event, ...)
	local Channel = self.GameChannel or self.Settings.Channel
	local EventGroup = self.EventGroups[Channel]

	if self[event] then
		self[event](self, ...)
	elseif EventGroup and EventGroup[event] then
		self:ChatMessageEvent(...)
	end
end

vGambler:RegisterEvent("PLAYER_ENTERING_WORLD")
vGambler:SetScript("OnEvent", vGambler.OnEvent)
