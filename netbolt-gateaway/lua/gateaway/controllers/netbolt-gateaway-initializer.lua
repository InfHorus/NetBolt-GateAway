-- Forensics.Theme = Green
-- Cardinal.Theme  = Blue
-- Bastion.Theme   = Red
-- Minuit.Theme    = Black
-- WireMultiAgent.Theme = Dark Purple

local self 			= {}
local MsgC 			= MsgC
local type			= type
local previousSave 	= previousSave or {}
local sanitizedDate = string.gsub (os.date ("%d/%m/%Y"), "/", "_")

function self:InternalId ()
	return "NetBoltGateAway:Initializer"
end

function self:MiniLogger_ (appender, _)
	if not appender and type (self) ~= "table" then
		appender = self
	end

	Msg ("\n")
	MsgC (Color (255,255,255), "(", Color (255,0,0), "[!] NetBoltGateAway | " .. tostring (NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].TimeTracker ()) .. " [!]", Color (255,255,255),"): ", appender)
	Msg ("\n")
end

function self:MiniLogger (appender, shouldIgnore)
	if type (self) == "table" and not previousSave then
		--previousSave = previousSave or {}
	end
	
	if not appender and type (self) ~= "table" then
		appender = self
	end
	
	if not shouldIgnore then
		Msg ("\n")
		MsgC (Color (255,255,255), "(", Color (255,0,0), "[!] NetBoltGateAway | " .. tostring (NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].TimeTracker ()) .. " [!]", Color (255,255,255),"): ", appender)
		Msg ("\n")
	end

	if previousSave then
		previousSave [#previousSave + 1] = "[" .. tostring (NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].TimeTracker ()) .. "] : " .. appender .. "\n"
	end
	
	if file.Exists ("netbolt-gateaway/console/console" .. "_" .. sanitizedDate .. ".txt", "DATA") then
		if previousSave then
			file.Append ("netbolt-gateaway/console/console" .. "_" .. sanitizedDate .. ".txt", table.concat (previousSave))
			previousSave = nil
		end
		file.Append ("netbolt-gateaway/console/console" .. "_" .. sanitizedDate .. ".txt", "[" .. tostring (NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].TimeTracker ()) .. "] : " .. appender .. "\n")
	end
end

function self:LoadSubPath ()
	if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].LoadFile and type (NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].LoadFile) == "table" then
	
		for incremental = 1, #NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].LoadFile do
			if not NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].LoadFile [incremental] or incremental == 1 then
				goto skipIteration
			end

			local isServer 	  = NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].ParseCorrectFiles (NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].LoadFile [incremental])
			local correctPath = string.gsub (NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].LoadFile [incremental], "SERVER|", "")
			correctPath		  = string.gsub (correctPath, "CLIENT|", "")
			
			if isServer and SERVER then
				local output = NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].DispatchFiles (correctPath)
				self:MiniLogger (output)
			elseif not isServer then
				local output = NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].DispatchFiles (correctPath)
				self:MiniLogger (output)
			end

			::skipIteration::
		end
	else
		self:MiniLogger ('!!Could not retrieve element {NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"].LoadFile}.')
	end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())
self:LoadSubPath ()