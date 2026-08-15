local Name, AddOn = ...
local GambleBuddy = AddOn.GambleBuddy

local table = table
local string = string

-- Add a page that just includes scrollable match history lines

--[[
	It could be possible to save players as well as more match info if I saved a parsed string of the match instead of saving it as a table of data
--]]

--[[

	Winner        Loser          Wager   Earnings
	Rhonin (100)  Khadgar (900)  1000    800

--]]

-- GambleBuddyHistory

GambleBuddy.MatchHistory = {}

function GambleBuddy:AddMatchHistory(wager, roll, outcome, value)
	if (#self.MatchHistory > 50) then -- Don't store more than 50 matches
		table.remove(self.MatchHistory, 1)
	end

	table.insert(self.MatchHistory, {wager, roll, outcome, value})
end