
RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    menuOpen = false 
    cb("ok")
end)

RegisterNUICallback("addFile", function(data, cb)
    local itemID = data.itemID
    local content = data.content
    local title = data.title
    local cabinetID = data.cabinetID
    
    TriggerServerEvent("aprts_filecabinet:Server:addFileToCabinet", cabinetID, {title = title, content = content})
    cb("ok")
end)