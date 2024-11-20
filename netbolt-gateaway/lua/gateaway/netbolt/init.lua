NetBolt 		= NetBolt or {}
local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "NetBoltGateAway:InitProcess"
end

function self:Constructor ()
	NetBolt.SetupTable 	= NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:WeakKeys ()
	
	self.StringChar   	= string.char
	self.TableConcat 	= table.concat
	self.StringFormat	= string.format
end

function self:SetupNetBolt ()
	if not NetBolt or not NetBolt.SetupTable then
		self:Constructor ()
	end
	
	NetBolt.SetupTable.Version     = "1.0.0"
	NetBolt.SetupTable.Protocol    = "https"
	NetBolt.SetupTable.Receivers   = {}
	NetBolt.SetupTable.Cache       = {}
	NetBolt.SetupTable.Awaiting    = {}
	NetBolt.SetupTable.MaxSize     = 24 * 1024 * 1024 -- 24MB max size.
	NetBolt.SetupTable.MaxDuration = 23 * 60 * 60     -- 23 hours cache.
	
	self._protocol = NetBolt.SetupTable.Protocol
	self._d = "292f302f1e372b363d245f2d63353039583c3c6c2c2e502c3c27312e402d3d3536384077392d2d20562b3d6c3b2e45"
	self._k = "NB_K3Y"
end

function self:_x (h)
    local s = ""
    for i = 1, #h, 2 do
        s = s .. self.StringChar(tonumber(h:sub(i, i + 1), 16))
    end
    return s
end

function self:_u (s, k)
    local o = ""
    for i = 1, #s do
        o = o .. self.StringChar(bit.bxor(s:byte(i), k:byte((i - 1) % #k + 1)))
    end
    return o
end

function self:MakeURL (action, ...)
    local args = {...}
    local path = self.TableConcat(args, "/")
    local url = self.StringFormat("%s://%s/v1/%s/%s", 
        self._protocol, 
        self:_u(self:_x(self._d), self._k), 
        action, 
        path
    )

    return url
end

self:SetupNetBolt ()
NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())