local self 		= {}
local string	= string
local pairs		= pairs
local ipairs 	= ipairs
local tostring 	= tostring

function self:InternalId ()
    return "NetBoltGateAway:AdvDupe2DetourFiles"
end

function self:Constructor ()
	-- TODO: Restore original functions with a disable button.
    self.OriginalSanitizeFilename 	= AdvDupe2.SanitizeFilename
    self.OriginalSendToClient 		= AdvDupe2.SendToClient
    self.OriginalUploadFile 		= AdvDupe2.UploadFile
    self.OriginalLoadDupe 			= AdvDupe2.LoadDupe
    
    if SERVER then
        AdvDupe2.SendToClient = function(ply, data, autosave)
            if not IsValid(ply) then return end
            if #data > AdvDupe2.MaxDupeSize then
                AdvDupe2.Notify(ply, "Copied duplicator filesize is too big!", NOTIFY_ERROR)
                return
            end

            ply.AdvDupe2.Downloading = true
            AdvDupe2.InitProgressBar(ply, "Saving:")

            NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("advdupe2_file", {
                data 		= data,
                autosave 	= autosave == 1,
            }, {ply}, 
			function ()
                ply.AdvDupe2.Downloading = false
            end)
        end
        
        NetBoltGateAway["NetBoltGateAway:Setup"]:Receive("advdupe2_upload", function(ply, fileData)
            if not IsValid(ply) then return end
            if not ply.AdvDupe2 then ply.AdvDupe2 = {} end

            ply.AdvDupe2.Name = string.match(fileData.name, "([%w_ ]+)") or "Advanced Duplication"

            if ply.AdvDupe2.Uploading then
                AdvDupe2.Notify(ply, "Duplicator is Busy!", NOTIFY_ERROR, 5)
                return
            end

            ply.AdvDupe2.Uploading = true
            AdvDupe2.InitProgressBar(ply, "Opening: ")

            local success, dupe, info, moreinfo = AdvDupe2.Decode(fileData.data)
            if success then
                self.OriginalLoadDupe(ply, success, dupe, info, moreinfo)
            else
                AdvDupe2.Notify(ply, "Duplicator Upload Failed!", NOTIFY_ERROR, 5)
            end
            
            ply.AdvDupe2.Uploading = false
        end)
    end
    
    if CLIENT then
        -- Detour client-side functions
        AdvDupe2.UploadFile = function(ReadPath, ReadArea)
            if uploading then 
                AdvDupe2.Notify("Already opening file, please wait.", NOTIFY_ERROR)
                return 
            end

            if ReadArea == 0 then
                ReadPath = AdvDupe2.DataFolder .. "/" .. ReadPath .. ".txt"
            elseif ReadArea == 1 then
                ReadPath = AdvDupe2.DataFolder .. "/-Public-/" .. ReadPath .. ".txt"
            else
                ReadPath = "adv_duplicator/" .. ReadPath .. ".txt"
            end

            if not file.Exists(ReadPath, "DATA") then 
                AdvDupe2.Notify("File does not exist", NOTIFY_ERROR)
                return 
            end

            local read = file.Read(ReadPath)
            if not read then 
                AdvDupe2.Notify("File could not be read", NOTIFY_ERROR)
                return 
            end

            local name = string.Explode("/", ReadPath)
            name = name[#name]
            name = string.sub(name, 1, #name-4)

            local success, dupe, info, moreinfo = AdvDupe2.Decode(read)
            if success then
                uploading = true
                
                NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("advdupe2_upload", {
                    name = name,
                    data = read
                }, nil, function()
                    uploading = nil
                    AdvDupe2.File = nil
                    AdvDupe2.RemoveProgressBar()
                end)

                AdvDupe2.LoadGhosts(dupe, info, moreinfo, name)
            else
                AdvDupe2.Notify("File could not be decoded. ("..dupe..") Upload Canceled.", NOTIFY_ERROR)
            end
        end

        -- Handle received files
        NetBoltGateAway ["NetBoltGateAway:Setup"]:Receive ("advdupe2_file", function (fileData)
            AdvDupe2.RemoveProgressBar()

            if not fileData or not fileData.data then
                AdvDupe2.Notify("File was not saved!", NOTIFY_ERROR, 5)
                return
            end

            local path
            if fileData.autosave then
                if LocalPlayer():GetInfo("advdupe2_auto_save_overwrite") ~= "0" then
                    path = AdvDupe2.GetFilename(AdvDupe2.AutoSavePath, true)
                else
                    path = AdvDupe2.GetFilename(AdvDupe2.AutoSavePath)
                end
            else
                path = AdvDupe2.GetFilename(AdvDupe2.SavePath)
            end

            path = AdvDupe2.SanitizeFilename(path)

            local dupefile = file.Open(path, "wb", "DATA")
            if not dupefile then
                AdvDupe2.Notify("File was not saved!", NOTIFY_ERROR, 5)
                return
            end

            dupefile:Write(fileData.data)
            dupefile:Close()

            local filename = string.StripExtension(string.GetFileFromFilename(path))
            if fileData.autosave then
                if IsValid(AdvDupe2.FileBrowser.AutoSaveNode) then
                    local add = true
                    for i = 1, #AdvDupe2.FileBrowser.AutoSaveNode.Files do
                        if filename == AdvDupe2.FileBrowser.AutoSaveNode.Files[i].Label:GetText() then
                            add = false
                            break
                        end
                    end
                    if add then
                        AdvDupe2.FileBrowser.AutoSaveNode:AddFile(filename)
                        AdvDupe2.FileBrowser.Browser.pnlCanvas:Sort(AdvDupe2.FileBrowser.AutoSaveNode)
                    end
                end
            else
                AdvDupe2.FileBrowser.Browser.pnlCanvas.ActionNode:AddFile(filename)
                AdvDupe2.FileBrowser.Browser.pnlCanvas:Sort(AdvDupe2.FileBrowser.Browser.pnlCanvas.ActionNode)
            end

            AdvDupe2.Notify("File successfully saved!", NOTIFY_GENERIC, 5)
        end)
    end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())