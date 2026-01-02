-- ================================================
-- FILE: client/nui.lua
-- ================================================

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    if Config.Debug then print("^3[NUI] Menu zavřeno.^0") end
    cb("ok")
end)

RegisterNUICallback("addFile", function(data, cb)
    local cabinetID = data.cabinetID
    local title = data.title
    local content = data.content
    local docType = data.docType or "standard"

    if Config.Debug then
        print("^2[NUI] Požadavek na uložení NOVÉHO souboru:^0")
        print(" - Cabinet ID: " .. tostring(cabinetID))
        print(" - Title: " .. tostring(title))
        print(" - Type: " .. tostring(docType))
        print(" - Content Length: " .. string.len(tostring(content)))
    end

    if not cabinetID or not title or title == "" then
        print("^1[NUI ERROR] Chybí ID kartotéky nebo název spisu!^0")
        cb("error")
        return
    end
    
    local fileData = {
        title = title,
        content = content,
        docType = docType
    }
    TriggerServerEvent("aprts_filecabinet:Server:addFileToCabinet", cabinetID, fileData)
    cb("ok")
end)

-- NOVÝ CALLBACK PRO EDITACI SOUBORU
RegisterNUICallback("editFile", function(data, cb)
    local cabinetID = data.cabinetID
    local originalItemID = data.originalItemID -- Toto je crafted_id původního itemu
    local title = data.title
    local content = data.content
    local docType = data.docType or "standard"

    if Config.Debug then
        print("^2[NUI] Požadavek na EDITACI souboru:^0")
        print(" - Cabinet ID: " .. tostring(cabinetID))
        print(" - Original Item ID: " .. tostring(originalItemID))
        print(" - Title: " .. tostring(title))
        print(" - Type: " .. tostring(docType))
        print(" - Content Length: " .. string.len(tostring(content)))
    end

    if not cabinetID or not originalItemID or not title or title == "" then
        print("^1[NUI ERROR] Chybí ID kartotéky, Item ID nebo název spisu pro editaci!^0")
        cb("error")
        return
    end
    
    local fileData = {
        originalItemID = originalItemID,
        title = title,
        content = content,
        docType = docType
    }
    TriggerServerEvent("aprts_filecabinet:Server:editFileInCabinet", cabinetID, fileData)
    cb("ok")
end)

RegisterNUICallback("copyFile", function(data, cb)
    local cabinetID = data.cabinetID
    local title = data.title
    local content = data.content
    local docType = data.docType or "standard"

    if Config.Debug then
        print("^2[NUI] Požadavek na KOPÍROVÁNÍ souboru:^0")
        print(" - Title: " .. tostring(title))
    end

    if not cabinetID or not title then
        cb("error")
        return
    end
    
    local fileData = {
        title = title,
        content = content,
        docType = docType
    }
    
    TriggerServerEvent("aprts_filecabinet:Server:copyFile", cabinetID, fileData)
    cb("ok")
end)