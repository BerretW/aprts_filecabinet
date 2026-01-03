AddEventHandler("onClientResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    -- TriggerServerEvent("aprts_clue:Server:LoadClues")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    FreezeEntityPosition(PlayerPedId(), false)
end)


RegisterNetEvent("aprts_filecabinet:Client:OpenCabinetMenu")
AddEventHandler("aprts_filecabinet:Client:OpenCabinetMenu", function(id, files, emptyPapersCount, docTypes)
    local cabinet = Config.CabinetLocations[id]
    
    if cabinet then
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open",
            cabinetID = id,
            cabinetName = cabinet.name,
            files = files,
            emptyPapersCount = emptyPapersCount,
            docTypes = docTypes, -- Předáváme config do JS
                 cabinetStyle = cabinet.style or {} 
        })
    end
end)


RegisterNetEvent("aprts_filecabinet:Client:OpenSingleFile")
AddEventHandler("aprts_filecabinet:Client:OpenSingleFile", function(itemData)
    -- itemData obsahuje metadata z inventáře
    if not itemData or not itemData.metadata then 
        notify("Tento spis je poškozený.")
        return 
    end

    SetNuiFocus(true, true)
    
    -- Posíláme zprávu do JS s novou akcí 'openSingleFile'
    SendNUIMessage({
        action = "openSingleFile",
        file = itemData, 
        docTypes = Config.DocumentTypes -- Musíme poslat i definice typů
    })
end)