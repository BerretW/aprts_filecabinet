AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        for id, cabinet in pairs(Config.CabinetLoactions) do
            RegisterInventory(id, cabinet.name)
        end
    end
end)

AddEventHandler("vorp_inventory:useItem")
RegisterServerEvent("vorp_inventory:useItem", function(data)
    local _source = source
    local itemName = data.item
    exports.vorp_inventory:getItemByMainId(_source, data.id, function(data)
        if data == nil then return end
        if itemName == Config.FileItem then
            TriggerClientEvent("aprts_filecabinet:Client:UseFileItem", _source, data)
        elseif itemName == Config.FolderItem then
            TriggerClientEvent("aprts_filecabinet:Client:UseFolderItem", _source, data)
        end
    end)
end)

RegisterServerEvent("aprts_filecabinet:Server:OpenCabinet")
AddEventHandler("aprts_filecabinet:Server:OpenCabinet", function(id)
    local _source = source
    local prefix = Config.InventoryPrefix
    local inventoryID = prefix .. tostring(id)
    exports.vorp_inventory:openInventory(_source, inventoryID)
end)

-- OPRAVENÝ EVENT PRO NAČTENÍ (ROZBALUJE STACKY)
RegisterServerEvent("aprts_filecabinet:Server:OpenCabinetMenu")
AddEventHandler("aprts_filecabinet:Server:OpenCabinetMenu", function(id)
    local _source = source
    local prefix = Config.InventoryPrefix
    local inventoryID = prefix .. tostring(id)
    local epmtyPapersCount = exports.vorp_inventory:getCustomInventoryItemCount(inventoryID, Config.EmptyPaperItem)
    local files = getFilesFromInventory(inventoryID)
    TriggerClientEvent("aprts_filecabinet:Client:OpenCabinetMenu", _source,id, files, epmtyPapersCount)
end)




RegisterServerEvent("aprts_filecabinet:Server:addFileToCabinet")
AddEventHandler("aprts_filecabinet:Server:addFileToCabinet", function(cabinetId, fileData)
    local _source = source
    local prefix = Config.InventoryPrefix
    local inventoryID = prefix .. tostring(cabinetId)
    local items = {{
                    name = Config.FileItem,
                    amount = 1,
                    metadata = {
                        label = "Spis " .. fileData.title,
                        content = fileData.content,
                        title = fileData.title
                    }
                }}
   
    -- Přidat soubor do inventáře skříňky
    exports.vorp_inventory:addItemsToCustomInventory(inventoryID, items,1)

    -- Odebrat prázdný papír z hráčova inventáře
    exports.vorp_inventory:subItem(_source, Config.EmptyPaperItem, 1)
end)

RegisterServerEvent("aprts_filecabinet:Server:removeFileFromCabinet")
AddEventHandler("aprts_filecabinet:Server:removeFileFromCabinet", function(cabinetId, itemID)
    local _source = source
    local prefix = Config.InventoryPrefix
    local inventoryID = prefix .. tostring(cabinetId)

    -- Odebrat soubor ze skříňky
    exports.vorp_inventory:removeItemFromCustomInventory(inventoryID,Config.FileItem,1, itemID, 1)


end)