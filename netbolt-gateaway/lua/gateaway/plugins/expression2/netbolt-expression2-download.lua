local self 		= {}
local pairs		= pairs
local ipairs 	= ipairs
local tostring 	= tostring
local CurTime 	= CurTime
local IsValid 	= IsValid
local next	 	= next

function self:InternalId ()
    return "NetBoltGateAway:E2Download"
end

function self:Constructor ()
    if SERVER then
        WireLib.Expression2Download = function(ply, targetEnt, wantedfiles, uploadandexit)
            if not IsValid(targetEnt) or targetEnt:GetClass() ~= "gmod_wire_expression2" then
                WireLib.AddNotify(ply, "Invalid Expression chip specified.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
                return
            end

            local main, includes = targetEnt:GetCode()
            
            if not includes or not next(includes) then
                -- No includes, send main code only
                NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("wire_expression2_download", {
                    files = {{targetEnt.name, main}},
                    uploadandexit = uploadandexit
                }, {ply})
            elseif not wantedfiles then
                -- Send file list for selection
                local fileList = {}
                for k, v in pairs(includes) do
                    table.insert(fileList, k)
                end

                NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("wire_expression2_filelist", {
                    files = fileList,
                    uploadandexit = uploadandexit
                }, {ply})

                targetEnt.DownloadAllowedPlayers = targetEnt.DownloadAllowedPlayers or {}
                targetEnt.DownloadAllowedPlayers[ply] = true
                timer.Simple(60, function()
                    if not IsValid(targetEnt) then return end
                    if not targetEnt.DownloadAllowedPlayers then return end
                    targetEnt.DownloadAllowedPlayers[ply] = nil
                    if table.IsEmpty(targetEnt.DownloadAllowedPlayers) then
                        targetEnt.DownloadAllowedPlayers = nil
                    end
                end)
            else
                -- Send requested files
                local data = {{}, {}}
                if wantedfiles.main then
                    data[1] = {targetEnt.name, main}
                    wantedfiles.main = nil
                end

                for i = 1, #wantedfiles do
                    local path = wantedfiles[i]
                    if includes[path] then
                        data[2][path] = includes[path]
                    else
                        WireLib.AddNotify(ply, "Nonexistant file requested ('" .. tostring(path) .. "'). File skipped.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
                    end
                end

                NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("wire_expression2_download", {
                    files = data,
                    uploadandexit = uploadandexit
                }, {ply})
            end
        end

        -- Handle wanted files selection
        NetBoltGateAway ["NetBoltGateAway:Setup"]:Receive ("wire_expression2_wantedfiles", function (ply, data)
            local toent = data.entity
            if not toent.DownloadAllowedPlayers or not toent.DownloadAllowedPlayers[ply] then return end

            WireLib.Expression2Download(ply, toent, data.files, data.uploadandexit)
        end)
    end

    if CLIENT then
        -- Handle downloads
        NetBoltGateAway ["NetBoltGateAway:Setup"]:Receive ("wire_expression2_download", function(data)
            if not wire_expression2_editor then initE2Editor() end

            local files = data.files
            local uploadandexit = data.uploadandexit

            local name, main
            if files[1] then
                name = files[1][1]
                main = files[1][2]
            end

            if uploadandexit then
                wire_expression2_editor.chip = LocalPlayer():GetEyeTrace().Entity
            end

            if files[2] and next(files[2]) then
                for k, v in pairs(files[2]) do
                    wire_expression2_editor:Open(k, v)
                end
            end

            wire_expression2_editor:Open(name, main)
        end)

        -- Handle file list
        NetBoltGateAway ["NetBoltGateAway:Setup"]:Receive ("wire_expression2_filelist", function(data)
            local files = data.files
            local uploadandexit = data.uploadandexit
            
            -- Create file selection UI
            local pnl = vgui.Create("DFrame")
            pnl:SetSize(200, 100)
            pnl:Center()
            pnl:SetTitle("Select files to download")

            local lst = vgui.Create("DPanelList", pnl)
            lst.Paint = function() end
            lst:SetSpacing(2)

            local selectedfiles = {main = true}
            local checkboxes = {}

            local check = vgui.Create("DCheckBoxLabel")
            check:SetText("Main")
            check:Toggle()
            lst:AddItem(check)
            function check:OnChange(val)
                selectedfiles.main = val or nil
            end
            checkboxes[#checkboxes + 1] = check

            for i = 1, #files do
                local path = files[i]
                local check = vgui.Create("DCheckBoxLabel")
                check:SetText(path)
                lst:AddItem(check)
                function check:OnChange(val)
                    if val then
                        selectedfiles[i] = path
                    else
                        selectedfiles[i] = nil
                    end
                end
                checkboxes[#checkboxes + 1] = check
            end

            -- Add control buttons
            local ok = vgui.Create("DButton")
            ok:SetText("Ok")
            lst:AddItem(ok)
            function ok:DoClick()
                local entity = LocalPlayer():GetEyeTrace().Entity
                NetBoltGateAway ["NetBoltGateAway:Setup"]:Send ("wire_expression2_wantedfiles", {
                    entity = entity,
                    files = selectedfiles,
                    uploadandexit = uploadandexit
                })
                pnl:Close()
            end

            local selectall = vgui.Create("DButton")
            selectall:SetText("Select all")
            lst:AddItem(selectall)
            function selectall:DoClick()
                selectedfiles = {main = true}
                for k, v in pairs(files) do
                    selectedfiles[k] = v
                end
                for _, check in ipairs(checkboxes) do
                    if not check:GetChecked() then check:Toggle() end
                end
            end

            local selectnone = vgui.Create("DButton")
            selectnone:SetText("Select none")
            lst:AddItem(selectnone)
            function selectnone:DoClick()
                selectedfiles = {}
                for _, check in ipairs(checkboxes) do
                    if check:GetChecked() then check:Toggle() end
                end
            end

            -- Setup panel
            local height = 23 + (#checkboxes * 20) + 60
            pnl:SetTall(math.min(height + 2, ScrH() / 2))
            lst:EnableVerticalScrollbar(true)
            lst:StretchToParent(2, 23, 2, 2)
            pnl:MakePopup()
        end)
    end
end

NetBoltGateAway.MakeGateAway (self, NetBoltGateAway, self:InternalId ())