if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (CLIENT) then
	return
end

local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "NetBoltGateAway:PlayerSession"
end

function self:Constructor ()
	self.PlayerSession = self.PlayerSession or {}
end

function self:CreatePlayerSession (ply)
	if not ply or not NetBoltGateAway ["NetBoltGateAway:ProgramLogs"]:IsPlayerValid_ (ply) then
		NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Denied session creation due to invalid player.")
		
		return 
	end
	
	local playerName 		= ply:Nick () or ply:Name ()
	local playerId	 		= ply:SteamID 	()
	local uniquePlayerId 	= ply:SteamID64 ()
	
	if not self.PlayerSession [uniquePlayerId] then
		self.PlayerSession [uniquePlayerId] = 
		{
			["TotalCount"] 	= 0,
			["TotalSize"]	= 0,
			["Seed"]		= CurTime (),
			["Constructor"]	= "",
		}
	end
	
	NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Created player " .. playerName .. " (" .. playerId .. ")'s session.")
end

function self:DestroyPlayerSession (ply)
	if not ply or not NetBoltGateAway ["NetBoltGateAway:ProgramLogs"]:IsPlayerValid_ (ply) then
		NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Denied session destruction due to invalid player.")
		
		return 
	end
	
	local playerName 		= ply:Nick () or ply:Name ()
	local playerId	 		= ply:SteamID 	()
	local uniquePlayerId 	= ply:SteamID64 ()
	
	if not self.PlayerSession [uniquePlayerId] then
		return
	end
	
	NetBoltGateAway ["NetBoltGateAway:EndFlow"].sentTokens [ply] = nil
	
	
	NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Destroyed player " .. playerName .. " (" .. playerId .. ")'s session.")
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())
