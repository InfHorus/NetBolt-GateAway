local self 		= {}
local pairs		= pairs
local ipairs 	= ipairs
local tostring 	= tostring

function self:InternalId ()
    return "NetBoltGateAway:AdvDupe2DetourGhosts"
end

function self:Constructor ()
    -- TODO: Restore original functions with a disable button.
    self.OriginalSendGhost  = AdvDupe2.SendGhost
    self.OriginalSendGhosts = AdvDupe2.SendGhosts
    
    if SERVER then
        AdvDupe2.SendGhost = function(ply, AddOne)
            NetBoltGateAway["NetBoltGateAway:Setup"]:Send("advdupe2_add_ghost", {
                model = AddOne.Model,
                physicsObjects = AddOne.PhysicsObjects
            }, {ply})
        end
        
        AdvDupe2.SendGhosts = function(ply)
            if not ply.AdvDupe2.Entities then return end
            
            local cache = {}
            local temp 	= {}
            local mdls 	= {}
            local cnt 	= 1
            local add 	= true
            local head
            
            for k, v in pairs (ply.AdvDupe2.Entities) do
                temp[cnt] = v
                for i = 1, #cache do
                    if cache[i] == v.Model then
                        mdls[cnt] = i
                        add = false
                        break
                    end
                end
                if add then
                    mdls[cnt] = table.insert(cache, v.Model)
                else
                    add = true
                end
                if k == ply.AdvDupe2.HeadEnt.Index then
                    head = cnt
                end
                cnt = cnt + 1
            end
            
            if not head then
                AdvDupe2.Notify(ply, "Invalid head entity for ghosts.", NOTIFY_ERROR)
                return
            end
            
            -- Send via NetBolt
            NetBoltGateAway["NetBoltGateAway:Setup"]:Send("advdupe2_send_ghosts", {
                head 			= head,
                headZ 			= ply.AdvDupe2.HeadEnt.Z,
                headPos 		= ply.AdvDupe2.HeadEnt.Pos,
                modelCache 		= cache,
                entities 		= temp,
                modelIndices 	= mdls,
                count 			= cnt - 1
            }, {ply})
        end
    end
    
    if CLIENT then
        -- Handle ghost data from server
		local function MakeGhostsFromTable(EntTable)
			if(not EntTable) then return end
			if(not EntTable.Model or EntTable.Model:sub(-4,-1) ~= ".mdl") then
				EntTable.Model = "models/error.mdl"
			end

			local GhostEntity = ClientsideModel(EntTable.Model, RENDERGROUP_TRANSLUCENT)

			if not IsValid(GhostEntity) then
				AdvDupe2.RemoveGhosts()
				AdvDupe2.Notify("Too many entities to spawn ghosts!", NOTIFY_ERROR)
				return
			end

			GhostEntity:SetRenderMode(RENDERMODE_TRANSALPHA)
			GhostEntity:SetColor(Color(255, 255, 255, 150))
			GhostEntity.Phys = EntTable.PhysicsObjects[0]

			if util.IsValidRagdoll(EntTable.Model) then
				local ref, parents, angs = {}, {}, {}

				GhostEntity:SetupBones()
				for k, v in pairs(EntTable.PhysicsObjects) do
					local bone = GhostEntity:TranslatePhysBoneToBone(k)
					local bonp = GhostEntity:GetBoneParent(bone)
					if bonp == -1 then
						ref[bone] = GhostEntity:GetBoneMatrix(bone):GetInverseTR()
					else
						bonp = GhostEntity:TranslatePhysBoneToBone(GhostEntity:TranslateBoneToPhysBone(bonp))
						parents[bone] = bonp
						ref[bone] = GhostEntity:GetBoneMatrix(bone):GetInverseTR() * GhostEntity:GetBoneMatrix(bonp)
					end

					local m = Matrix() m:SetAngles(v.Angle)
					angs[bone] = m
				end

				for bone, ang in pairs(angs) do
					if parents[bone] and angs[parents[bone]] then
						local localrotation = angs[parents[bone]]:GetInverseTR() * ang
						local m = ref[bone] * localrotation
						GhostEntity:ManipulateBoneAngles(bone, m:GetAngles())
					else
						local pos = GhostEntity:GetBonePosition(bone)
						GhostEntity:ManipulateBonePosition(bone, -pos)
						GhostEntity:ManipulateBoneAngles(bone, ref[bone]:GetAngles())
					end
				end
			end

			return GhostEntity
		end
	
        NetBoltGateAway["NetBoltGateAway:Setup"]:Receive ("advdupe2_add_ghost", function (data)
            local ghost = {
                Model = data.model,
                PhysicsObjects = data.physicsObjects
            }
            
            AdvDupe2.GhostEntities[AdvDupe2.CurrentGhost] = MakeGhostsFromTable(ghost)
            AdvDupe2.CurrentGhost = AdvDupe2.CurrentGhost + 1
        end)
        
        local function SpawnGhosts()
			if AdvDupe2.CurrentGhost == AdvDupe2.HeadEnt then 
				AdvDupe2.CurrentGhost = AdvDupe2.CurrentGhost + 1 
			end

			local g = AdvDupe2.GhostToSpawn[AdvDupe2.CurrentGhost]
			if g and AdvDupe2.CurrentGhost / AdvDupe2.TotalGhosts * 100 <= GetConVar("advdupe2_limit_ghost"):GetFloat() then
				AdvDupe2.GhostEntities[AdvDupe2.CurrentGhost] = MakeGhostsFromTable(g)
				if not AdvDupe2.BusyBar then
					AdvDupe2.ProgressBar.Percent = AdvDupe2.CurrentGhost / AdvDupe2.TotalGhosts * 100
				end

				AdvDupe2.CurrentGhost = AdvDupe2.CurrentGhost + 1
				AdvDupe2.UpdateGhosts(true)
			else
				AdvDupe2.Ghosting = false
				hook.Remove("Tick", "AdvDupe2_SpawnGhosts")

				if not AdvDupe2.BusyBar then
					AdvDupe2.RemoveProgressBar()
				end
			end
		end

		NetBoltGateAway["NetBoltGateAway:Setup"]:Receive ("advdupe2_send_ghosts", function (data)
			AdvDupe2.RemoveGhosts()
			AdvDupe2.GhostToSpawn = {}
			AdvDupe2.HeadEnt = data.head
			AdvDupe2.HeadZPos = data.headZ
			AdvDupe2.HeadPos = data.headPos

			for i = 1, data.count do
				AdvDupe2.GhostToSpawn[i] = {
					Model = data.modelCache[data.modelIndices[i]],
					PhysicsObjects = data.entities[i].PhysicsObjects
				}
			end
			
			AdvDupe2.CurrentGhost = 1
			AdvDupe2.GhostEntities = {}
			AdvDupe2.HeadGhost = MakeGhostsFromTable(AdvDupe2.GhostToSpawn[AdvDupe2.HeadEnt])
			AdvDupe2.HeadOffset = AdvDupe2.GhostToSpawn[AdvDupe2.HeadEnt].PhysicsObjects[0].Pos
			AdvDupe2.HeadAngle = AdvDupe2.GhostToSpawn[AdvDupe2.HeadEnt].PhysicsObjects[0].Angle
			AdvDupe2.GhostEntities[AdvDupe2.HeadEnt] = AdvDupe2.HeadGhost
			AdvDupe2.TotalGhosts = #AdvDupe2.GhostToSpawn
			
			if AdvDupe2.TotalGhosts > 1 then
				AdvDupe2.Ghosting = true
				
				if not AdvDupe2.BusyBar then
					AdvDupe2.InitProgressBar("Ghosting: ")
					AdvDupe2.BusyBar = false
				end
				
				hook.Add("Tick", "AdvDupe2_SpawnGhosts", SpawnGhosts)
			else
				AdvDupe2.Ghosting = false
			end
		end)
    end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())