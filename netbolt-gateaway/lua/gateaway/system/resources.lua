local self   = {}
local ipairs = ipairs

function self:InternalId ()
	return "NetBoltGateAway:Resources"
end

function self:PreConstructor ()
	self.BestUsable = ""
	
	self.Channels   = NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:WeakKeys ()
end

function self:CalculateTimeRemaining (duration)
    if duration > 60 then
        local minutes = duration / 60

        return string.format ("%.3g minute%s", minutes, minutes == 1 and "" or "s")
    else
        local seconds = duration

        return string.format ("%.3g second%s", seconds, seconds == 1 and "" or "s")
    end
end

function self:Constructor ()
	if self.BestUsable ~= "" then -- Lua refresh compatibility.
		NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Already found Best Administration Mode (" .. self.BestUsable .. ").")
		
		return 
	end

	if ULib then
		self.Channels [#self.Channels + 1] = "ULX"
	elseif serverguard then
		self.Channels [#self.Channels + 1] = "ServerGuard"
	elseif maestro then
		self.Channels [#self.Channels + 1] = "Maestro"
	elseif sam then
		self.Channels [#self.Channels + 1] = "SAM"
	elseif D3A then
		self.Channels [#self.Channels + 1] = "D3A"
	else
		self.Channels [#self.Channels + 1] = "None"
	end
	
	if #self.Channels > 1 then
		NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Warning: Multiple Administration Mode has been detected, only one can run at a time.")
		
		for _, bestChannels in ipairs (self.Channels) do
			NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger  ("Found : " .. bestChannels)
		end
		
		NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger  ("The current configuration may lead to conflict issues.")
	end
	
	if #self.Channels == 1 then
		self.BestUsable = self.Channels [1]
		
		NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger  ("Found " .. self.BestUsable .. " as Best Administration Mode.")
	end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())