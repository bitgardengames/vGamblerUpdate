local Name, AddOn = ...
local vGambler = AddOn.vGambler
local L = AddOn.L

vGambler.Ela = 0
vGambler.Testers = {}
vGambler.InUseNames = {}

vGambler.TestNames = {
	"|cff0070DDThrall|r", "|cff3FC7EBJaina|r", "|cffC69B6DMagni|r", "|cffAAD372Sylvanas|r", "|cffC41E3AArthas|r", "|cffFF7C0AMalfurion|r", "|cffA330C9Illidan|r", "|cffF48CBAAnduin|r", "|cff8788EEMedivh|r", "|cff3FC7EBKhadgar|r", "|cff8788EEGul'dan|r",
	"|cff8788EEArchimonde|r", "|cff8788EEKil'jaeden|r", "Velen", "|cffAAD372Brann|r", "|cffC69B6DMuradin|r", "|cff3FC7EBKael'thas|r", "|cffAAD372Alleria|r", "Tyrande", "Maiev", "|cffFF7C0ACenarius|r", "Elune", "|cffF48CBABolvar|r", "|cff3FC7EBAegwynn|r",
	"|cff0070DDNer'zhul|r", "|cff0070DDDrek'Thar|r", "|cffFFF468Genn|r", "|cff3FC7EBRhonin|r", "|cffF48CBATirion|r", "|cffF48CBATuralyon|r", "|cffF48CBAUther|r", "|cffC69B6DVarian|r", "|cffC69B6DGrommash|r", "|cffC69B6DOrgrim|r", "|cffF48CBAYrel|r",
	"|cffC69B6DGarrosh|r", "|cffFFF468Garona|r", "|cffC69B6DBaine|r", "|cff3FC7EBKel'Thuzad|r", "|cffAAD372Rexxar|r", "Benedictus", "|cff8788EECho'gall|r", "|cffFFF468Valeera|r", "|cff00FF98Chen|r", "|cffAAD372Rehgar|r", "|cffFFF468Mathias|r",
	"|cffC41E3ADarion|r", "|cffC41E3AKoltira|r", "|cffA330C9Illysanna|r", "|cffA330C9Varedis|r", "|cffAAD372Vereesa|r", "|cffAAD372Hemet|r", "|cff00FF98Aysa|r", "|cff00FF98Ji|r", "|cff00FF98Taran|r", "|cffFF7C0AFandral|r", "|cffFF7C0ARemulos|r",
	"|cff0070DDNobundo|r", "|cff3FC7EBThalyssra|r", "|cffAAD372Vol'jin|r", "|cffAAD372Shandris|r", "|cff0070DDDraka|r",
}

function vGambler:AddPlayersOnUpdate(elapsed)
	self.Ela = self.Ela + elapsed

	if (self.Ela > 0.2) then
		if (not self.InUseNames[1]) then
			self:SetScript("OnUpdate", nil)

			return
		end

		local Player = table.remove(self.InUseNames, 1)

		self:AddPlayer(Player)

		table.insert(self.TestNames, Player)

		self.Ela = 0
	end
end

function vGambler:RollPlayersOnUpdate(elapsed)
	self.Ela = self.Ela + elapsed

	if (self.Ela > 0.6) then
		if (not self.Testers[1]) then
			self:SetScript("OnUpdate", nil)

			return
		end

		local Player = table.remove(self.Testers, 1)
		local Roll = random(1, self.GameWager or self.Settings.RollValue)

		self:CHAT_MSG_SYSTEM(string.format(RANDOM_ROLL_RESULT, Player.Name, Roll, 1, self.GameWager or self.Settings.RollValue)) -- This event is already set up to process this information

		self.Ela = 0
	end
end

function vGambler:PauseOnUpdate(elapsed)
	self.Ela = self.Ela + elapsed

	if (self.Ela > 2) then
		self:SetScript("OnUpdate", nil)
		self.Ela = 0

		self:RemoveAllPlayersUI()

		for i = #self.Players, 1, -1 do
			table.remove(self.Players, 1)
		end

		for i = 1, #self.Tie do
			table.insert(self.Players, self.Tie[i])
		end

		for i = 1, #self.Players do
			self.Players[i].Roll = 0
			self:AddPlayerUI()
		end

		local Players = {}

		for i = 1, #self.Players do
			table.insert(Players, self.Players[i].DisplayName)
		end

		self:AccountTieRound(Players)
		self.Tie = table.wipe(self.Tie)

		self:CloseTiedGame()

		if self.IsTestGame then
			self:RollTestPlayers()
		end

		return
	end
end

function vGambler:ResetOnUpdate(elapsed)
	self.Ela = self.Ela + elapsed

	if (self.Ela > 3) then
		self:SetScript("OnUpdate", nil)
		self.Ela = 0

		self:ResetGame()
		self:TestGame()
	end
end

function vGambler:RollTestPlayers()
	if self.Testers[1] then
		for i = 1, #self.Testers do
			table.remove(self.Testers, 1)
		end
	end

	for i = 1, #self.Players do
		table.insert(self.Testers, self.Players[i])
	end

	self.Ela = -1
	self:SetScript("OnUpdate", self.RollPlayersOnUpdate)
end

function vGambler:TestGame()
	self.IsTestGame = true
	self.TestCount = random(2, 4)
	self:StartGame()

	for i = 1, self.TestCount do -- Get some fake player names. Pulling them so we don't have to check for repeats
		table.insert(self.InUseNames, table.remove(self.TestNames, random(1, #self.TestNames)))
	end

	self:SetScript("OnUpdate", self.AddPlayersOnUpdate)
end