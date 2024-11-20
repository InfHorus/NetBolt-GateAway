NetBoltGateAway 	= NetBoltGateAway or {}
local self 		   	= {}
local include 	   	= include
local AddCSLuaFile 	= AddCSLuaFile
local tostring		= tostring
local type		   	= type
local setmetatable 	= setmetatable
local initTime  	= SysTime ()

function NetBoltGateAway.MakeGateAway (SignalAccelerator, SignalFilter, ISaveMap)
    SignalFilter [ISaveMap] = SignalAccelerator
end

function self:WeakKeys ()
    local weakTable = {}
	
    setmetatable (weakTable, 
		{
			__mode = "k" 
		}
	)
	
    return weakTable
end

function self:TimeTracker ()
	local startupTime = SysTime () 
	startupTime 	  = startupTime - initTime
	
	return string.format ("%02d:%02d", math.floor (startupTime / 60), math.floor (startupTime % 60), math.floor (startupTime * 1000 % 1000))
end

function self:InternalId ()
	return "NetBoltGateAway:SystemDispatcher"
end

function self:Constructor ()
	self.LoadFile = self:WeakKeys ()
	
	self.LoadFile [#self.LoadFile + 1] = "gateaway/controllers/netbolt-gateaway-initializer.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|gateaway/system/resources.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|gateaway/administration/programlogs.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|gateaway/playersessions/handleplayers.lua"
	
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/netbolt/init.lua"
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/netbolt/setup.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|gateaway/netbolt/endflow.lua"
	
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/matching/signalprocessor.lua"
	
	
	--- workers ---
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/plugins/expression2/netbolt-expression2.lua"
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/plugins/expression2/netbolt-expression2-download.lua"
	
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/plugins/advdupe2/netbolt-advdupe2-files.lua"
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/plugins/advdupe2/netbolt-advdupe2-ghosts.lua"
	
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/plugins/pac3/netbolt-pac3-submit.lua"

	
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|gateaway/controllers/classesmegastructure.lua"
end

function self:ParseCorrectFiles (_)
	if string.sub (self, 1, 6) == "SERVER" then
		return true
	else
		return false
	end
end

function self:DispatchFiles (file, server)
	if type (self) ~= "table" and not file then
		file = tostring (self)
	end
	if file ~= nil then
		AddCSLuaFile (file)
		include (file)

		return "> Dispatched > " .. file .. "."
	else
		if type (self) == "table" then
			return self:InternalId () .. ".DispatchFiles : Empty allocation provided."
		else
			return self:InternalId () .. ".DispatchFiles : Empty allocation provided."
		end
	end
end

function self:GetStateStatus (status)
	if status then
		return true
	end
end

self:Constructor ()
NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())
self:DispatchFiles (self.LoadFile [1])
