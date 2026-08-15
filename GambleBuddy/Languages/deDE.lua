local Name, AddOn = ...
local L = {}
local GambleBuddy = CreateFrame("Frame")

AddOn.L = L
AddOn.Locale = GetLocale()
AddOn.GambleBuddy = GambleBuddy

if (Locale ~= "deDE") then
	return
end

