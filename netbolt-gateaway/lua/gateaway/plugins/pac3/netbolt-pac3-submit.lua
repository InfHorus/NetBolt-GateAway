local self 	= {}
local table = table

function self:InternalId ()
    return "NetBoltGateAway:PAC3Submit"
end

function self:Constructor ()
    if SERVER then
        local pac_submit_spam = CreateConVar  ('pac_submit_spam', '1',   {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 'Prevent users from spamming pac_submit')
        local pac_submit_limit = CreateConVar ('pac_submit_limit', '30', {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 'pac_submit spam limit')

        function pace.HandleReceivedData(ply, data)
            data.owner = ply
            data.uid = pac.Hash(ply)

            if data.wear_filter and #data.wear_filter > game.MaxPlayers() then
                pac.Message("Player ", ply, " tried to submit extraordinary wear filter size of ", #data.wear_filter, ", dropping.")
                data.wear_filter = nil
            end

            if istable(data.part) and data.part.self then
                if istable(data.part.self) and not data.part.self.UniqueID then return end
                pac.Message("Received pac outfit from ", ply)
                pace.SubmitPartNotify(data)
            elseif isstring(data.part) then
                local clearing = data.part == "__ALL__"
                pac.Message("Clearing ", clearing and "Outfit" or "Part", " from ", ply)
                pace.RemovePart(data)
            end
        end

        NetBoltGateAway ["NetBoltGateAway:Setup"]:Receive ("pac_submit", function (ply, data)
            if pac_submit_spam:GetBool () and not game.SinglePlayer () then
                local allowed = pac.RatelimitPlayer(ply, "pac_submit", pac_submit_limit:GetInt(), 5, {"Player ", ply, " is spamming pac_submit!"})
                if not allowed then return end
            end

            if pac.CallHook("CanWearParts", ply) == false then return end
            pace.HandleReceivedData(ply, data)
        end)
    end

    if CLIENT then
        local function regenerateUniqueIDs(part, baseID)
            if not part or not part.self then return end
            
            local identifier = part.self.Name or part.self.ClassName or "part"
            part.self.UniqueID = pac.Hash(baseID .. identifier .. tostring(SysTime()))
            
            if part.children then
                for _, child in ipairs(part.children) do
                    regenerateUniqueIDs(child, part.self.UniqueID)
                end
            end
        end

        function pace.WearOnServer(filter)
            local outfitParts = {}
            
            for key, part in pairs(pac.GetLocalParts()) do
                if pace.IsPartSendable(part) then
                    local partData = part:ToTable()
                    -- Generate new unique IDs with a unique base because that shit won't work otherwise
                    regenerateUniqueIDs(partData, tostring(SysTime()) .. "_" .. key)
                    table.insert(outfitParts, partData)
                end
            end

            if #outfitParts == 0 then return end

            local data = {
                part = outfitParts[1], -- Send first part as main
                owner = LocalPlayer(),
                wear_filter = pace.CreateWearFilter()
            }

            -- Add remaining parts as children so we don't have to split garbage
            for i = 2, #outfitParts do
                if not data.part.children then
                    data.part.children = {}
                end
                table.insert(data.part.children, outfitParts[i])
            end

            NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("pac_submit", data, nil, function ()
                pac.Message ('Transmitted complete outfit to server')
            end)
        end

        -- Individual part sending
        function pace.SendPartToServer(part, extra)
            local allowed, reason = pac.CallHook("CanWearParts", pac.LocalPlayer)
            if allowed == false then
                pac.Message(reason or "the server doesn't want you to wear parts for some reason")
                return false
            end

            if not pace.IsPartSendable(part) then return false end

            local data = {part = part:ToTable()}
            regenerateUniqueIDs(data.part, tostring(SysTime()))
            
            if extra then
                table.Merge(data, extra)
            end

            data.owner = part:GetPlayerOwner()
            data.wear_filter = pace.CreateWearFilter()

            NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("pac_submit", data, nil, function()
                local partName = part.Name or part.ClassName or "unnamed part"
                pac.Message(('Transmitted part %q to server'):format(partName))
            end)

            return true
        end
    end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())