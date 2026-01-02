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
AddEventHandler("aprts_filecabinet:Client:OpenCabinetMenu", function(id,files, emptyPapersCount)
    -- posílá seznam dostupných spisů ve skříňce
    print(json.encode(files, {indent = true}))
    local cabinet = Config.CabinetLoactions[id]
    SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open",
            cabinetID = id,
            cabinetName = cabinet.name,
            files = files,
            emptyPapersCount = emptyPapersCount
        })
end)