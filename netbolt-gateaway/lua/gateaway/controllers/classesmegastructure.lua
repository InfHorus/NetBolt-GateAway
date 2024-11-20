do
	NetBoltGateAway ["NetBoltGateAway:SignalProcessor"]:Constructor ()
	
	if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (SERVER) then
		
		NetBoltGateAway ["NetBoltGateAway:ProgramLogs"]:Constructor 		()
		NetBoltGateAway ["NetBoltGateAway:PlayerSession"]:Constructor 		()
		NetBoltGateAway ["NetBoltGateAway:EndFlow"]:Constructor     		()
		NetBoltGateAway ["NetBoltGateAway:InitProcess"]:Constructor  		()
		NetBoltGateAway ["NetBoltGateAway:InitProcess"]:SetupNetBolt       	()
		
		hook.Add ("StartCommand", "NetBoltGateAway:StartCommand", function (ply, cmd)
			NetBoltGateAway ["NetBoltGateAway:EndFlow"]:PlayerHandling (ply, cmd)
		end)
		
		NetBoltGateAway["NetBoltGateAway:Setup"]:Constructor ()
		
		hook.Add ("Initialize", "NetBoltGateAway:Initialize", function ()
			NetBoltGateAway ["NetBoltGateAway:Setup"]:Register ()
			
			NetBoltGateAway ["NetBoltGateAway:Setup"]:Register (function ()
				hook.Run ("NetBoltLoaded")
			end)
		end)
		
		hook.Add ("InitPostEntity", "NetBoltGateAway:InitEvent", function ()
			NetBoltGateAway ["NetBoltGateAway:Resources"]:PreConstructor ()
			NetBoltGateAway ["NetBoltGateAway:Resources"]:Constructor 	 ()	
		end)

		hook.Add ("PlayerInitialSpawn", NetBoltGateAway ["NetBoltGateAway:PlayerSession"]:InternalId (), function (ply, _)
			NetBoltGateAway ["NetBoltGateAway:PlayerSession"]:CreatePlayerSession (ply)
		end)
		
		hook.Add ("PlayerDisconnected", NetBoltGateAway ["NetBoltGateAway:PlayerSession"]:InternalId (), function (ply)
			NetBoltGateAway ["NetBoltGateAway:PlayerSession"]:DestroyPlayerSession (ply)
		end)
	else
		hook.Add ("Initialize", "NetBoltGateAway:FireHook", function ()
			hook.Run ("NetBoltLoaded")
		end)
		
		NetBoltGateAway ["NetBoltGateAway:InitProcess"]:Constructor  ()
		NetBoltGateAway ["NetBoltGateAway:InitProcess"]:SetupNetBolt ()
		NetBoltGateAway ["NetBoltGateAway:Setup"]:Constructor 		 ()
	end
	
	------------------------------------------------------------------
	
	net.Receive (NetBoltGateAway ["NetBoltGateAway:SignalProcessor"].Identifiers.Carriage, function (len, ply)
		NetBoltGateAway ["NetBoltGateAway:Setup"]:ReceiveData (len, ply)
	end)
	
	hook.Add ("Initialize", "NetBoltGateAway:PluginsLoader", function ()
		if (WireLib) then
			NetBoltGateAway ["NetBoltGateAway:E2Detour"]:Constructor 				()
			NetBoltGateAway ["NetBoltGateAway:E2Download"]:Constructor 				()
		end
		
		if (AdvDupe2) then
			NetBoltGateAway ["NetBoltGateAway:AdvDupe2DetourFiles"]:Constructor 	()
			NetBoltGateAway ["NetBoltGateAway:AdvDupe2DetourGhosts"]:Constructor 	()
		end
		
		if (pac and pace) then
			NetBoltGateAway ["NetBoltGateAway:PAC3Submit"]:Constructor 				()
		end
	end)
	
	net.Receive (NetBoltGateAway ["NetBoltGateAway:SignalProcessor"].Identifiers.Fingerprint, function (len, ply)
		local hash = net.ReadString ()
		
		if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (SERVER) then
			hash = ply:SteamID64 () .. "-" .. hash
		end

		local callback = NetBolt.SetupTable.Awaiting [hash]
		
		if callback then
			callback (ply)
			NetBolt.SetupTable.Awaiting [hash] = nil
		end
	end)
end