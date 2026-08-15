local Name, AddOn = ...
local vGambler = AddOn.vGambler
local L = AddOn.L

vGambler.BannedPlayers = {}
vGambler.FreeBannedPlayers = {}

local VisibleBanRows = 11

function vGambler:BanCloseButtonOnEnter()
	self.Texture:SetVertexColor(0.9, 0.1, 0.1)

	local Parent = self:GetParent()

	Parent:SetBackdropColor(0.25, 0.266, 0.294)
	Parent:SetBackdropBorderColor(0.25, 0.266, 0.294)
end

function vGambler:BanCloseButtonOnLeave()
	self.Texture:SetVertexColor(1, 1, 1)

	local Parent = self:GetParent()

	Parent:SetBackdropColor(0.184, 0.192, 0.211)
	Parent:SetBackdropBorderColor(0.184, 0.192, 0.211)
end

function vGambler:UnbanPlayerFromUI()
	for i = 1, #vGamblerBans do -- Remove the saved data
		if (vGamblerBans[i][1] == self.Name) then
			table.remove(vGamblerBans, i)

			break
		end
	end

	vGambler:SortBannedPlayers()
end

function vGambler:AddBannedPlayerUI(name, reason)
	local Page = self:GetPage("Bans")
	local Bar

	if (#self.BannedPlayers >= math.min(#vGamblerBans, VisibleBanRows)) then
		self:SortBannedPlayers()
		return
	elseif self.FreeBannedPlayers[1] then
		Bar = table.remove(self.FreeBannedPlayers, 1)
	else
		Bar = CreateFrame("Frame", nil, Page.BanArea, "BackdropTemplate")
		Bar:SetSize(Page:GetWidth() - 24, 24)
		Bar:SetBackdrop(self.SmallBackdrop)
		Bar:SetBackdropColor(0.184, 0.192, 0.211)
		Bar:SetBackdropBorderColor(0.184, 0.192, 0.211)
		Bar:SetScript("OnEnter", self.WindowButtonOnEnter)
		Bar:SetScript("OnLeave", self.WindowButtonOnLeave)
		Bar.Label = Bar:CreateFontString(nil, "OVERLAY")
		Bar.Label:SetPoint("LEFT", Bar, 5, -1)
		Bar.Label:SetFont(self.Font, self.Settings.FontSize)
		Bar.Label:SetShadowColor(0.029, 0.029, 0.051)
		Bar.Label:SetShadowOffset(0, -1)
		Bar.Label:SetJustifyH("LEFT")
		Bar.Label:SetSize(94, 12)

		Bar.Reason = Bar:CreateFontString(nil, "OVERLAY")
		Bar.Reason:SetPoint("LEFT", Bar, "CENTER", -60, -1)
		Bar.Reason:SetFont(self.Font, self.Settings.FontSize)
		Bar.Reason:SetShadowColor(0.029, 0.029, 0.051)
		Bar.Reason:SetShadowOffset(0, -1)
		Bar.Reason:SetJustifyH("LEFT")
		Bar.Reason:SetSize(206, 12)

		Bar.Remove = CreateFrame("Frame", nil, Bar)
		Bar.Remove:SetPoint("RIGHT", Bar, 0, 0)
		Bar.Remove:SetSize(24, 24)
		Bar.Remove:SetScript("OnEnter", self.BanCloseButtonOnEnter)
		Bar.Remove:SetScript("OnLeave", self.BanCloseButtonOnLeave)
		Bar.Remove:SetScript("OnMouseUp", self.UnbanPlayerFromUI)

		Bar.Remove.Texture = Bar.Remove:CreateTexture(nil, "OVERLAY")
		Bar.Remove.Texture:SetPoint("CENTER", Bar.Remove, 0, 0)
		Bar.Remove.Texture:SetSize(16, 16)
		Bar.Remove.Texture:SetTexture("Interface\\AddOns\\vGambler\\Assets\\HydraUIClose.tga")
	end

	Bar:EnableMouseWheel(true)
	Bar:SetScript("OnMouseWheel", self.BanScrollOnMouseWheel)

	table.insert(self.BannedPlayers, Bar)

	self:SortBannedPlayers()
end

function vGambler:SortBannedPlayers()
	local Page = self:GetPage("Bans")
	local Maximum = math.max(1, #vGamblerBans - VisibleBanRows + 1)
	local Offset = math.max(1, math.min(math.floor((Page.BanScroll.Offset or 1) + 0.5), Maximum))

	Page.BanScroll.Offset = Offset
	Page.BanScroll:SetMinMaxValues(1, Maximum)
	Page.BanScroll:SetValue(Offset)

	for i = 1, #self.BannedPlayers do
		local Bar = self.BannedPlayers[i]
		local Ban = vGamblerBans[Offset + i - 1]

		Bar:ClearAllPoints()

		if Ban and i <= VisibleBanRows then
			if (i == 1) then
				Bar:SetPoint("TOPLEFT", Page.BanArea, 4, -30)
			else
				Bar:SetPoint("TOPLEFT", self.BannedPlayers[i-1], "BOTTOMLEFT", 0, -2)
			end

			Bar.Name = Ban[1]
			Bar.Remove.Name = Ban[1]
			Bar.Label:SetText(Ban[1])
			Bar.Reason:SetText(Ban[2])
			Bar:Show()
		else
			Bar:Hide()
		end
	end
end

function vGambler:BanScrollOnValueChanged(offset)
	vGambler:GetPage("Bans").BanScroll.Offset = offset
	vGambler:SortBannedPlayers()
end

function vGambler:BanScrollOnMouseWheel(delta)
	local ScrollBar = vGambler:GetPage("Bans").BanScroll
	ScrollBar:SetValue(ScrollBar.Offset - delta)
end

function vGambler:BanPlayer(player, reason)
	if (not vGamblerBans) then
		vGamblerBans = {}
	end

	for i = 1, #vGamblerBans do
		if (vGamblerBans[i][1] == player) then -- Check if this player is already banned
			return
		end
	end

	table.insert(vGamblerBans, {player, reason}) -- Can add date here if I feel like it

	self:AddBannedPlayerUI(player, reason)

	if self.Settings.PlaySounds then
		PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
	end
end

function vGambler:UnbanPlayer(player)
	if (not vGamblerBans) then
		return
	end

	for i = 1, #vGamblerBans do
		if (vGamblerBans[i][1] == player) then
			table.remove(vGamblerBans, i)

			break
		end
	end

	vGambler:SendMessage(string.format("|cffFFC44DvGambler|r: %s has been removed from the ban list.", player))
end

function vGambler:ResetBans()
	if (type(vGamblerBans) ~= "table") then
		vGamblerBans = {}
	else
		for key in pairs(vGamblerBans) do
			vGamblerBans[key] = nil
		end
	end

	for i = #self.BannedPlayers, 1, -1 do
		local Bar = table.remove(self.BannedPlayers, i)

		Bar:Hide()
		table.insert(self.FreeBannedPlayers, Bar)
	end

	if (self.Window and self:GetPage("Bans")) then
		self:SortBannedPlayers()
	end

	print("vGambler: Ban list has been reset.")
end

function vGambler:IsBanned(player)
	if (not vGamblerBans) then
		return false
	end

	for i = 1, #vGamblerBans do
		if (vGamblerBans[i][1] == player) then
			return true, vGamblerBans[i][2]
		end
	end
end

function vGambler:BanPlayerFromUI()
	local Page = vGambler:GetPage("Bans")
	local Name = Page.NameInput:GetText()
	local Reason = Page.ReasonInput:GetText()

	-- Validate that we have an actual name
	if (string.find(Name, "%S") and Name == Page.NameInput.DefaultText) then
		return
	end

	if (string.find(Reason, "%S") and Reason ~= Page.ReasonInput.DefaultText) then
		vGambler:BanPlayer(Name, Reason)
	else
		vGambler:BanPlayer(Name)
	end

	Page.NameInput:SetAutoFocus(false)
	Page.NameInput:ClearFocus()
	Page.NameInput:SetText(Page.NameInput.DefaultText)

	Page.ReasonInput:SetAutoFocus(false)
	Page.ReasonInput:ClearFocus()
	Page.ReasonInput:SetText(Page.ReasonInput.DefaultText)

	vGambler:SendMessage(string.format("|cffFFC44DvGambler|r: Banning %s for the reason: %s", Name, Reason))
end

function vGambler:BanInputOnMouseDown()
	self:SetText("")
	self:SetAutoFocus(true)
end

function vGambler:BanInputOnEnterPressed()
	local Text = self:GetText()
	local Page = vGambler:GetPage("Bans")

	if string.find(Text, "%S") then
		Page.BanButton:SetBackdropColor(0.839, 0.270, 0.270)
		Page.BanButton:SetBackdropBorderColor(0.839, 0.270, 0.270)
	else
		self:SetText(self.DefaultText)

		Page.BanButton:SetBackdropColor(0.25, 0.266, 0.294)
		Page.BanButton:SetBackdropBorderColor(0.25, 0.266, 0.294)
	end

	self:SetAutoFocus(false)
	self:ClearFocus()
end

function vGambler:BanButtonMouseDown()
	self.Label:ClearAllPoints()
	self.Label:SetPoint("CENTER", self, 1, -2)
end

function vGambler:BanButtonMouseUp()
	self.Label:ClearAllPoints()
	self.Label:SetPoint("CENTER", self, 0, -1)

	local Page = vGambler:GetPage("Bans")

	Page.BanButton:SetBackdropColor(0.25, 0.266, 0.294)
	Page.BanButton:SetBackdropBorderColor(0.25, 0.266, 0.294)
end

function vGambler:SetupBansPage(page)
	local Inputs = CreateFrame("Frame", nil, page, "BackdropTemplate")
	Inputs:SetSize(353, 32)
	Inputs:SetPoint("TOPLEFT", page, 0, 0)
	Inputs:SetBackdrop(self.MediumBackdrop)
	Inputs:SetBackdropColor(0.184, 0.192, 0.211)
	Inputs:SetBackdropBorderColor(0.184, 0.192, 0.211)

	local NameInput = CreateFrame("EditBox", nil, Inputs, "BackdropTemplate")
	NameInput:SetSize(90, 24)
	NameInput:SetPoint("BOTTOMLEFT", Inputs, 4, 4)
	NameInput:SetBackdrop(self.SmallBackdrop)
	NameInput:SetBackdropColor(0.125, 0.133, 0.145)
	NameInput:SetBackdropBorderColor(0.125, 0.133, 0.145)
	NameInput:SetFont(self.Font, self.Settings.FontSize, "")
	NameInput:SetShadowColor(0.029, 0.029, 0.051)
	NameInput:SetShadowOffset(0, -1)
	NameInput:SetText(format("|cffd2d2d2%s|r", NAME))
	NameInput:SetAutoFocus(false)
	NameInput:SetTextInsets(6.5, -6, 2, 1)
	NameInput:SetScript("OnMouseDown", self.BanInputOnMouseDown)
	NameInput:SetScript("OnEnterPressed", self.BanInputOnEnterPressed)
	NameInput:SetScript("OnEscapePressed", self.BanInputOnEnterPressed)
	NameInput:SetScript("OnEditFocusLost", self.OnEditFocusLost)
	NameInput.DefaultText = format("|cffd2d2d2%s|r", NAME)

	local ReasonInput = CreateFrame("EditBox", nil, Inputs, "BackdropTemplate")
	ReasonInput:SetSize(187, 24)
	ReasonInput:SetPoint("LEFT", NameInput, "RIGHT", 4, 0)
	ReasonInput:SetBackdrop(self.SmallBackdrop)
	ReasonInput:SetBackdropColor(0.125, 0.133, 0.145)
	ReasonInput:SetBackdropBorderColor(0.125, 0.133, 0.145)
	ReasonInput:SetFont(self.Font, self.Settings.FontSize, "")
	ReasonInput:SetShadowColor(0.029, 0.029, 0.051)
	ReasonInput:SetShadowOffset(0, -1)
	ReasonInput:SetText("|cffd2d2d2Reason (optional)|r")
	ReasonInput:SetAutoFocus(false)
	ReasonInput:SetTextInsets(6.5, -6, 2, 1)
	ReasonInput:SetScript("OnMouseDown", self.BanInputOnMouseDown)
	ReasonInput:SetScript("OnEnterPressed", self.BanInputOnEnterPressed)
	ReasonInput:SetScript("OnEscapePressed", self.BanInputOnEnterPressed)
	ReasonInput.DefaultText = "|cffd2d2d2Reason (optional)|r"

	local BanButton = CreateFrame("Frame", nil, Inputs, "BackdropTemplate")
	BanButton:SetSize(60, 24)
	BanButton:SetPoint("LEFT", ReasonInput, "RIGHT", 4, 0)
	BanButton:SetBackdrop(self.SmallBackdrop)
	BanButton:SetBackdropColor(0.25, 0.266, 0.294)
	BanButton:SetBackdropBorderColor(0.25, 0.266, 0.294)
	BanButton:SetScript("OnMouseUp", vGambler.BanPlayerFromUI)
	BanButton:HookScript("OnMouseUp", self.BanButtonMouseUp)
	BanButton:HookScript("OnMouseDown", self.BanButtonMouseDown)

	BanButton.Label = BanButton:CreateFontString(nil, "OVERLAY")
	BanButton.Label:SetPoint("CENTER", BanButton, 0, -1)
	BanButton.Label:SetFont(self.Font, self.Settings.FontSize)
	BanButton.Label:SetJustifyH("CENTER")
	BanButton.Label:SetText(CHAT_BAN)
	BanButton.Label:SetShadowColor(0.029, 0.029, 0.051)
	BanButton.Label:SetShadowOffset(0, -1)

	local BanArea = CreateFrame("Frame", nil, page, "BackdropTemplate")
	BanArea:SetPoint("TOPLEFT", Inputs, "BOTTOMLEFT", 0, -6)
	BanArea:SetPoint("BOTTOMRIGHT", page, 0, 0)
	BanArea:SetBackdrop(self.MediumBackdrop)
	BanArea:SetBackdropColor(0.184, 0.192, 0.211)
	BanArea:SetBackdropBorderColor(0.184, 0.192, 0.211)
	BanArea:EnableMouseWheel(true)
	BanArea:SetScript("OnMouseWheel", self.BanScrollOnMouseWheel)

	BanArea.Header = CreateFrame("Frame", nil, BanArea, "BackdropTemplate")
	BanArea.Header:SetSize(page:GetWidth() - 8, 24)
	BanArea.Header:SetPoint("TOPLEFT", BanArea, 4, -4)
	BanArea.Header:SetBackdrop(self.SmallBackdrop)
	BanArea.Header:SetBackdropColor(0.25, 0.266, 0.294)
	BanArea.Header:SetBackdropBorderColor(0.25, 0.266, 0.294)

	BanArea.HeaderLabel = BanArea.Header:CreateFontString(nil, "OVERLAY")
	BanArea.HeaderLabel:SetPoint("LEFT", BanArea.Header, 5, -1)
	BanArea.HeaderLabel:SetFont(self.Font, self.Settings.FontSize)
	BanArea.HeaderLabel:SetShadowColor(0.029, 0.029, 0.051)
	BanArea.HeaderLabel:SetShadowOffset(0, -1)
	BanArea.HeaderLabel:SetText("|cffFFC44DPlayer|r")

	BanArea.HeaderReason = BanArea.Header:CreateFontString(nil, "OVERLAY")
	BanArea.HeaderReason:SetPoint("LEFT", BanArea.Header, "CENTER", -60, -1)
	BanArea.HeaderReason:SetFont(self.Font, self.Settings.FontSize)
	BanArea.HeaderReason:SetShadowColor(0.029, 0.029, 0.051)
	BanArea.HeaderReason:SetShadowOffset(0, -1)
	BanArea.HeaderReason:SetText("|cffFFC44DBan reason|r")

	local BanScroll = CreateFrame("Slider", nil, BanArea)
	BanScroll:SetWidth(12)
	BanScroll:SetPoint("TOPRIGHT", BanArea.Header, "BOTTOMRIGHT", 1, 0)
	BanScroll:SetPoint("BOTTOMRIGHT", BanArea, -3, 4)
	BanScroll:SetThumbTexture(self.Settings.UIStyle == 1 and "Interface\\AddOns\\vGambler\\Assets\\HydraRoundThumb.tga" or "Interface\\AddOns\\vGambler\\Assets\\HydraThumb.tga")
	BanScroll:GetThumbTexture():SetSize(32, 32)
	BanScroll:GetThumbTexture():SetVertexColor(0.25, 0.266, 0.294)
	BanScroll:SetOrientation("VERTICAL")
	BanScroll:SetValueStep(1)
	BanScroll:SetObeyStepOnDrag(true)
	BanScroll:SetMinMaxValues(1, 1)
	BanScroll:SetValue(1)
	BanScroll.Offset = 1
	BanScroll:EnableMouseWheel(true)
	BanScroll:SetScript("OnMouseWheel", self.BanScrollOnMouseWheel)
	BanScroll:SetScript("OnValueChanged", self.BanScrollOnValueChanged)
	BanScroll:SetScript("OnEnter", self.ScrollBarOnEnter)
	BanScroll:SetScript("OnLeave", self.ScrollBarOnLeave)
	BanScroll:SetScript("OnMouseDown", self.ScrollBarOnMouseDown)
	BanScroll:SetScript("OnMouseUp", self.ScrollBarOnMouseUp)

	page.BanArea = BanArea
	page.BanScroll = BanScroll
	page.BanButton = BanButton
	page.NameInput = NameInput
	page.ReasonInput = ReasonInput

	-- Add current bans to the UI
	if (vGamblerBans and #vGamblerBans > 0) then
		for i = 1, #vGamblerBans do
			self:AddBannedPlayerUI(vGamblerBans[i][1], vGamblerBans[i][2])
		end
	end
end
