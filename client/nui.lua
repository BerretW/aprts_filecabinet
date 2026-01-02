RegisterNUICallback("openFile", function(data, cb)
    local itemID = data.itemID
    local status = "failed"
    TriggerServerEvent("aprts_filecabinet:Server:GetItemMeta", itemID, function(meta)
        if meta then
            SendNUIMessage({
                action = "loadFile",
                content = meta.content or "",
                title = meta.title or ""
            })
            status = "ok"
        end
    end)
    cb(status)
end)

RegisterNUICallback("saveFile", function(data, cb)
    local itemID = data.itemID
    local content = data.content
    local title = data.title
    TriggerServerEvent("aprts_filecabinet:Server:SaveItemMeta", itemID, content, title)
    cb("ok")
end)