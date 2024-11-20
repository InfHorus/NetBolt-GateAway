local self 		= {}
local pairs		= pairs
local ipairs 	= ipairs
local tostring 	= tostring
local CurTime 	= CurTime
local IsValid 	= IsValid

function self:InternalId ()
    return "NetBoltGateAway:E2Detour"
end

function self:Constructor ()
    self.OriginalE2Upload = WireLib.Expression2Upload
    
    if CLIENT then
		WireLib.Expression2Upload = function(targetEnt, code, filepath)
			if not targetEnt then targetEnt = LocalPlayer():GetEyeTrace().Entity or NULL end
			if isentity(targetEnt) then
				if not IsValid(targetEnt) then return end
				targetEnt = targetEnt:EntIndex()
			end
			
			if not code and not wire_expression2_editor then return end
			code = code or wire_expression2_editor:GetCode()
			filepath = filepath or wire_expression2_editor:GetChosenFile()
			
			local err, includes, warnings
			if e2_function_data_received then
				err, includes, warnings = E2Lib.Validate(code)
				if err and err[1] then
					WireLib.AddNotify(err[1].message, NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
					return
				end
			else
				WireLib.AddNotify("The Expression 2 function data has not been transferred to the client yet.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				return
			end
			
			-- Prepare data
			local datastr
			if includes then
				local newincludes = {}
				for k, v in pairs(includes) do
					newincludes[k] = v
				end
				datastr = WireLib.von.serialize({ code, newincludes, filepath })
			else
				datastr = WireLib.von.serialize({ code, {}, filepath })
			end
			
			-- Show initial upload progress
			Expression2SetProgress(10, nil)
			
			NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("wire_expression2_upload", {
				entindex 	= targetEnt,
				code 		= datastr
			}, nil, function ()
				Expression2SetProgress(100, nil)
				
				Expression2SetProgress()
			end)
		end
	end
    
    if SERVER then
        -- Set up receiver
        NetBoltGateAway ["NetBoltGateAway:Setup"]:Receive ("wire_expression2_upload", function (ply, data)
            local toent = Entity(data.entindex)
            
            if (not IsValid(toent) or toent:GetClass() ~= "gmod_wire_expression2") then
                WireLib.AddNotify(ply, "Invalid Expression chip specified. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
                return
            end
            
            if not WireLib.CanTool(ply, toent, "wire_expression2") then
                WireLib.AddNotify(ply, "You are not allowed to upload to the target Expression chip. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
                return
            end
            
            local ok, ret = pcall(WireLib.von.deserialize, data.code)
            if not ok then
                WireLib.AddNotify(ply, "Expression 2 upload failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				
                print("Expression 2 upload failed! Error message:\n" .. ret)
				
                return
            end
            
            local code = ret[1]
            local includes = {}
            for k, v in pairs(ret[2]) do
                includes[k] = v
            end
            local filepath = ret[3]
            
            if ply ~= toent.player then
                toent.player = ply
                toent:SetPlayer(ply)
                toent:SetNWEntity("player", ply)
            end
            
            toent.code_author = {
                name = ply:GetName(),
                steamID = ply:SteamID()
            }
            
            toent:Setup(code, includes, nil, nil, filepath)
        end)
    end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())