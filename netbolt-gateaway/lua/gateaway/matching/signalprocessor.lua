local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "NetBoltGateAway:SignalProcessor"
end

function self:Constructor ()
	self.Identifiers = {}

	self.Identifiers.Carriage 	 = "netbolt-gateaway-data"
	self.Identifiers.Fingerprint = "netbolt-gateaway-fingerprint"
	self.Identifiers.Register 	 = "netbolt-gateaway-register"
	self.Identifiers.Receivers 	 = "netbolt-gateaway-receivers"
	
	if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (SERVER) then
		for _, identifiers in pairs (self.Identifiers) do
			util.AddNetworkString (identifiers)
		end
		
		self.HandlePayLoad = function (ply, codeUniqueHashing, uncompressedCarriage, dataTypes, blankVars)
			NetBoltGateAway ["NetBoltGateAway:iSerializer"]:SerializePayLoadCarriage (uncompressedCarriage, codeUniqueHashing, dataTypes, blankVars, 0, ply)
		end
	end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())

if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (CLIENT) then
	return
end
--[[
-- Str::ctor per LivePlayerSession()
function self:ReceiveCarriage ()
	net.Receive (self.Identifiers.Carriage, function (_, ply)
		local playerId64 = ply:SteamID64 ()
		local playerName = ply:Nick 	 () or ply:Name ()
		local playerId	 = ply:SteamID 	 ()
		
		if not NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] then
			NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Warning: Received a network from a player without LivePlayerSession! " .. playerName .. "(" .. playerId .. ")")
			
			return
		end
		
		if not NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] then 
			NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
		end
		
		if NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Seed"] > CurTime () then
			NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Warning: Received too many requests from player : " .. playerName .. " (" .. playerId .. ").")
			
			NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
			
			NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Cooldown expires in: " .. NetBoltGateAway ["NetBoltGateAway:Resources"]:CalculateTimeRemaining (NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Seed"] - CurTime ()))
			
			return
		end
		
		local carriageEnded = net.ReadBool ()
			
		local signature 	= net.ReadBool ()
		
		if not signature then
			NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Warning: Received a malformed carriage from player : " .. playerName .. " (" .. playerId .. ").")
			
			return
		end
		
		local packetsRemaining 		= net.ReadString  ()
		local sizeRemaining			= net.ReadString  ()
		
		local e2Sharing				= net.ReadString  ()
		local e2Description			= net.ReadString  ()
		
		local importedFloat  		= net.ReadUInt (16)
		local compressedCarriage   	= net.ReadData (importedFloat)
		
		NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] .. compressedCarriage
		
		if not carriageEnded then
			return
		end
		
		if not NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] then
			NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Warning: Failed to reconstruct carriage packets from player : " .. playerName .. " (" .. playerId .. ").")
			
			NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
			
			return
		end
	
		local uncompressedCarriage 	= util.Decompress (NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"]) or ""
		
		if not uncompressedCarriage or uncompressedCarriage == "" then
			NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Warning: Deserialization failure for player " .. playerName .. " (" .. playerId .. ").")
			
			NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
		end
		
		local codeUniqueHashing = string.format ("%07X", util.CRC (uncompressedCarriage))
		
		
		NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Seed"] 		    = CurTime () + 3
		NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["TotalCount"] 	= NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["TotalCount"] + 1
		NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["TotalSize"]  	= NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["TotalSize"]  + string.len (uncompressedCarriage)
		
		NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Received a carriage from player : " .. playerName .. " (" .. playerId .. ").")
		NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger (playerName .. " (" .. playerId .. ") bandwidth used : " .. string.NiceSize (NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["TotalSize"]))
		
		
		NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
		
		self.TransferExpression2Code (ply, codeUniqueHashing, uncompressedCarriage, e2Description, e2Sharing)
	end)
end
--]]
NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())
