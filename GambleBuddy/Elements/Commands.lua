local Name, AddOn = ...
local L = AddOn.L
local GambleBuddy = AddOn.GambleBuddy

GambleBuddy.Commands = {
	ban = function(message) -- /gb ban {player} {reason}
		local Name, Reason = string.match(message, "^(%a+)%s(.+)$")

		if (not Name) then
			return
		end

		if (Reason and string.find(Reason, "%S")) then
			GambleBuddy:BanPlayer(Name, Reason)
		else
			GambleBuddy:BanPlayer(Name, true)
		end
	end,

	getban = function(name) -- /gb getban {player}
		if (not GambleBuddyBans) then
			return print("No players are banned")
		end

		local Banned, Reason = GambleBuddy:IsBanned(name)

		if Banned then
			print(string.format("%s is banned (%s)", name, Reason))
		else
			print(string.format("%s is not banned", name))
		end
	end,

	unban = function(name) -- /gb unban {player}
		GambleBuddy:UnbanPlayer(name)
	end,

	resetbans = function() -- /gb resetbans
		GambleBuddy:ResetBans()
	end,

	show = function() -- /gb show
		GambleBuddy:ShowWindow()
	end,

	hide = function() -- /gb hide
		GambleBuddy:HideWindow()
	end,

	toggle = function() -- /gb toggle
		GambleBuddy:ToggleWindow()
	end,

	set = function(value) -- /gb set {value}
		value = tonumber(value)

		if (value and value > 0) then
			GambleBuddy.RollValue = math.max(2, value)

			-- Update interface
			if (not GambleBuddy.Window) then
				return
			end

			for i = 1, #GambleBuddy.Window.Buttons do
				if (GambleBuddy.Window.Buttons[i].ID == "RollValue") then -- Can adjust this if I need something prettier.
					if (not GambleBuddySettings) then
						GambleBuddySettings = {}
					end

					GambleBuddySettings.RollValue = value
					GambleBuddy.Settings.RollValue = value
					GambleBuddy.Window.Buttons[i]:SetText(GambleBuddy:Comma(value))

					return
				end
			end
		end
	end,
}

SLASH_GAMBLEBUDDY1 = "/gb"
SLASH_GAMBLEBUDDY2 = "/gamble"
SLASH_GAMBLEBUDDY3 = "/gbuddy"
SlashCmdList.GAMBLEBUDDY = function(command)
	local arg1, arg2 = string.match(command, "^(%S+)%s(.+)$")

	if (not arg1) then
		GambleBuddy:ToggleWindow()
	elseif GambleBuddy.Commands[arg1] then
		GambleBuddy.Commands[arg1](arg2)
	end
end