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


RegisterNetEvent("aprts_filecabinet:Server:OpenCabinetMenu")
AddEventHandler("aprts_filecabinet:Server:OpenCabinetMenu", function(cabinetId,items)
    -- posílá seznam dostupných spisů ve skříňce
        SendNUIMessage({
            action = "open",
            recipes = items
        })
end)