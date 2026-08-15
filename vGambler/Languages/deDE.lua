local Name, AddOn = ...
local L = {}
local vGambler = CreateFrame("Frame")

AddOn.L = L
AddOn.Locale = GetLocale()
AddOn.vGambler = vGambler

if (Locale ~= "deDE") then
	return
end

