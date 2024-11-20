local include 	   = include
local AddCSLuaFile = AddCSLuaFile

if SERVER then
	AddCSLuaFile ("gateaway/system/systemdispatcher.lua")
end

print ("Loading garbage.." .. "\n")

include ("gateaway/system/systemdispatcher.lua")
