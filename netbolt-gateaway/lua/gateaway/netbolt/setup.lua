local self   	 = {}
local ipairs 	 = ipairs
local tostring 	 = tostring
local tonumber 	 = tonumber
local print		 = print


function self:InternalId ()
	return "NetBoltGateAway:Setup"
end

function self:Constructor ()
	self.TableToJSON = util.TableToJSON
	self.JSONToTable = util.JSONToTable
	self.DoCompress  = util.Compress
	self.Decompress  = util.Decompress
	
	if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (CLIENT) then
		net.Receive (NetBoltGateAway ["NetBoltGateAway:SignalProcessor"].Identifiers.Register, function ()
			self.clientToken = net.ReadString ()
		end)
	end
end

function self:HandleCompression (payload)
    payload = self.TableToJSON (payload)
	
    return self.DoCompress (payload)
end

function self:HandleDecompression (payload)
    local decompressed = self.Decompress (payload)
	
    if not decompressed then return nil end
	
    return self.JSONToTable (decompressed)
end

function self:Register (callback)
    HTTP({
        method 	= "GET",
        url 	= NetBoltGateAway ["NetBoltGateAway:InitProcess"]:MakeURL ("register"),
        success = function (code, body)
            if code ~= 200 then
                NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Registration failed with code " .. code, false)
				
                return
            end

            local data = self.JSONToTable (body)
            if not data or not data.server or not data.client then
                NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Invalid registration response", false)
				
                return
            end

            self.serverToken = data.server
            self.clientToken = data.client

            if callback then callback () end

            if player.GetCount () > 0 then
                net.Start (NetBoltGateAway ["NetBoltGateAway:SignalProcessor"].Identifiers.Register)
                net.WriteString (self.clientToken)
                net.Broadcast ()
            end
        end,
		
        failed = function (err)
            NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Registration failed - " .. err, false)
        end
    })
end

function self:Send(message, data, recipients, onProof)
    NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Starting Send for message: " .. message, true)
    
    if not isstring(message) then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Message must be a string", false)
		
        return
    end

    if not data then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Data cannot be nil", false)
		
        return
    end

    local compressed = self:HandleCompression (data)
    if not compressed then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Failed to compress data", false)
		
        return
    end

    NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Compressed data size: " .. #compressed .. " bytes", true)

    if #compressed > NetBolt.SetupTable.MaxSize then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Data too large (" .. #compressed .. " bytes)", false)
		
        return
    end

    if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (SERVER) and not self.serverToken then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("No server token available. Is the registration complete?", false)
		
        return
    end
    
    if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (CLIENT) and not self.clientToken then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("No client token available. Is the server connection complete?")
		
        return
    end

    print("[NetBolt] Using token:", SERVER and self.serverToken or self.clientToken)

    local hash = util.SHA1 (compressed)
    NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Data hash: " .. hash, false)

    if isfunction (onProof) then
        if SERVER then
            self:SetAwaitingProof (hash, onProof, recipients)
        else
            self:SetAwaitingProof (hash, onProof)
        end
    end
    
    if NetBolt.SetupTable.Cache [hash] and (os.time() - NetBolt.SetupTable.Cache [hash].time) < NetBolt.SetupTable.MaxDuration then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Using cached data with ID: " .. NetBolt.SetupTable.Cache [hash].id, false)
        self:SendToRecipients (message, NetBolt.SetupTable.Cache [hash].id, recipients, isfunction (onProof))
        return
    end

    NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Uploading to worker...", true)

    HTTP({
        method = "POST",
        url = NetBoltGateAway ["NetBoltGateAway:InitProcess"]:MakeURL ("write"),
        headers = {
            ["X-Auth-Token"] = SERVER and self.serverToken or self.clientToken,
        },
        body = compressed,
        
        success = function(code, body)
            NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Upload response code: " .. code, true)
            NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Upload response body: " .. body, true)

            if code ~= 200 then
                NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("NetBolt: Upload failed with code " .. code, false)
                return
            end

            local response = self.JSONToTable (body)
            if not response or not response.id then
                NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("NetBolt: Invalid upload response", false)
				
                return
            end

            NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Got ID from worker: " .. response.id, false)

            NetBolt.SetupTable.Cache [hash] = {
                id = response.id,
                time = os.time()
            }

            self:SendToRecipients (message, response.id, recipients, isfunction(onProof))
        end,
        failed = function (err)
            NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Upload failed - " .. err, false)
        end
    })
end

function self:SendToRecipients (message, id, recipients, requireProof)
    --NetBoltGateAway["NetBoltGateAway:Initializer"]:MiniLogger ("SendToRecipients: " .. message .. id, recipients and #recipients or "broadcast", false)
    
    timer.Simple (0.1, function ()
        net.Start (NetBoltGateAway ["NetBoltGateAway:SignalProcessor"].Identifiers.Carriage)
        net.WriteString (message)
        net.WriteString (id)
        net.WriteBool (requireProof or false)

        if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (SERVER) then
            if recipients then
                NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Sending to specific recipients: " .. #recipients, false)
                net.Send (recipients)
            else
                NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Broadcasting to all", true)
                net.Broadcast ()
            end
        else
            net.SendToServer ()
        end
    end)
end

function self:Receive (message, callback)
    if not isstring (message) then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Message must be a string", false)
		
        return
    end

    if not isfunction (callback) then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("Callback must be a function", false)
		
        return
    end

    message = string.lower (message)
    NetBolt.SetupTable.Receivers [message] = callback

    if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (CLIENT) then
        timer.Simple (0, function ()
            net.Start (NetBoltGateAway ["NetBoltGateAway:SignalProcessor"].Identifiers.Receivers)
            net.WriteString  (message)
            net.SendToServer ()
        end)
    end
end

function self:SetAwaitingProof (hash, callback, recipients)
    if SERVER then
        for _, ply in ipairs (recipients) do
            local key = ply:SteamID64 () .. "-" .. hash
			
            NetBolt.SetupTable.Awaiting [key] = callback
        end
    else
        NetBolt.SetupTable.Awaiting [hash] = callback
    end
end

function self:ReceiveData (len, ply)
    local message 	 = net.ReadString ()
    local id         = net.ReadString ()
    local needsProof = net.ReadBool   ()

    local callback = NetBolt.SetupTable.Receivers [string.lower (message)]
	
    if not callback then
        NetBoltGateAway ["NetBoltGateAway:Initializer"]:MiniLogger ("NetBolt: No receiver for message: " .. message, false)
		
        return
    end

    HTTP({
        method  = "GET",
        url     = NetBoltGateAway ["NetBoltGateAway:InitProcess"]:MakeURL ("read", id),
		
        success = function (code, body)
            if code ~= 200 then return end

            local data = self:HandleDecompression (body)
            if not data then return end

            if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (SERVER) then
                callback(ply, data)
            else
                callback(data)
            end

            if needsProof then
                local hash = util.SHA1 (body)
				
                net.Start (NetBoltGateAway ["NetBoltGateAway:SignalProcessor"].Identifiers.Fingerprint)
                net.WriteString (hash)
                if NetBoltGateAway ["NetBoltGateAway:SystemDispatcher"]:GetStateStatus (SERVER) then
                    net.Send (ply)
                else
                    net.SendToServer ()
                end
            end
        end,
		
        failed = function (err)
            NetBoltGateAway["NetBoltGateAway:Initializer"]:MiniLogger ("Download failed - " .. err, true)
			error ("NetBolt: Download failed - " .. err)
        end
    })
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())