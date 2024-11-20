if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (CLIENT) then
	return
end

local self   	 = {}
local ipairs 	 = ipairs
local tostring 	 = tostring
local tonumber 	 = tonumber
local print		 = print


function self:InternalId ()
	return "NetBoltGateAway:EndFlow"
end

function self:Constructor ()
	self.sentTokens = {}
	
	-- Auto-reconnect on server token expiry (24h)
    timer.Create ("NetBoltGateAway:EndFlow.Register", 23 * 60 * 60, 0, function ()
        NetBoltGateAway ["NetBoltGateAway:Setup"]:Register ()

        self.sentTokens = {}
    end)
end

function self:PlayerHandling (ply, cmd)
	if not IsValid (ply) or self.sentTokens [ply] then return end
	
	if not cmd:IsForced () and ply:IsConnected () and NetBoltGateAway ["NetBoltGateAway:PlayerSession"].PlayerSession [ply:SteamID64 ()] then
		if NetBoltGateAway ["NetBoltGateAway:Setup"].clientToken then
			net.Start (NetBoltGateAway ["NetBoltGateAway:SignalProcessor"].Identifiers.Register)
			net.WriteString (NetBoltGateAway ["NetBoltGateAway:Setup"].clientToken)
			net.Send (ply)
			
			self.sentTokens [ply] = true
		end
	end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())