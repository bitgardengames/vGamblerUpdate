local Name, AddOn = ...
local vGambler = AddOn.vGambler

-- Chat windows may still queue local messages before the controls are created.
vGambler.PendingMessages = {}

-- Addon-message synchronization is intentionally disabled. Keep this method so
-- the host's normal game flow can continue to call it without special cases.
function vGambler:SendEvent(event, args)
end

-- These actions use ordinary chat and rolls, so they remain available to the
-- local play buttons even when addon communications are disabled.
function vGambler:JoinGame()
	SendChatMessage(self.Settings.EnterCommand, self.ChannelSelections[self.GameChannel or self.Settings.Channel])
	self:DisablePlayButton("Join")
	self:EnablePlayButton("Withdraw")
end

function vGambler:WithdrawGame()
	SendChatMessage(self.Settings.LeaveCommand, self.ChannelSelections[self.GameChannel or self.Settings.Channel])
	self:EnablePlayButton("Join")
	self:DisablePlayButton("Withdraw")
end

function vGambler:RollGame()
	RandomRoll(1, self.GameWager or self.Settings.RollValue)
	self:DisablePlayButton("Roll")
end
