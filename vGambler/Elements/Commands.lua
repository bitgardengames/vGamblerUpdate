local Name, AddOn = ...
local L = AddOn.L
local vGambler = AddOn.vGambler

vGambler.Commands = {
	ban = function(message) -- /vg ban {player} {reason}
		local Name, Reason = string.match(message, "^(%a+)%s(.+)$")

		if (not Name) then
			return
		end

		if (Reason and string.find(Reason, "%S")) then
			vGambler:BanPlayer(Name, Reason)
		else
			vGambler:BanPlayer(Name, true)
		end
	end,

	getban = function(name) -- /vg getban {player}
		if (not vGamblerBans) then
			return print(L.NO_BANNED_PLAYERS)
		end

		local Banned, Reason = vGambler:IsBanned(name)

		if Banned then
			print(string.format(L.PLAYER_IS_BANNED, name, Reason))
		else
			print(string.format(L.PLAYER_NOT_BANNED, name))
		end
	end,

	unban = function(name) -- /vg unban {player}
		vGambler:UnbanPlayer(name)
	end,

	resetbans = function() -- /vg resetbans
		vGambler:ResetBans()
	end,

	show = function() -- /vg show
		vGambler:ShowWindow()
	end,

	hide = function() -- /vg hide
		vGambler:HideWindow()
	end,

	toggle = function() -- /vg toggle
		vGambler:ToggleWindow()
	end,

	set = function(value) -- /vg set {value}
		value = tonumber(value)

		if (value and value > 0) then
			vGambler.RollValue = math.max(2, value)

			-- Update interface
			if (not vGambler.Window) then
				return
			end

			for i = 1, #vGambler.Window.Buttons do
				if (vGambler.Window.Buttons[i].ID == "RollValue") then -- Can adjust this if I need something prettier.
					if (not vGamblerSettings) then
						vGamblerSettings = {}
					end

					vGamblerSettings.RollValue = value
					vGambler.Settings.RollValue = value
					vGambler.Window.Buttons[i]:SetText(vGambler:Comma(value))

					return
				end
			end
		end
	end,
}

SLASH_VGAMBLER1 = "/vg"
SLASH_VGAMBLER2 = "/gamble"
SLASH_VGAMBLER3 = "/vgambler"
SlashCmdList.VGAMBLER = function(command)
	local arg1, arg2 = string.match(command, "^(%S+)%s*(.*)$")

	if (not arg1) then
		vGambler:ToggleWindow()
	else
		arg1 = string.lower(arg1)

		if vGambler.Commands[arg1] then
			vGambler.Commands[arg1](arg2)
		end
	end
end
