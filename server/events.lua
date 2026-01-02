AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        for id, cabinet in pairs(Config.CabinetLocations) do
            RegisterInventory(id, cabinet.name)
        end
    end
end)
RegisterServerEvent("vorp_inventory:useItem")
AddEventHandler("vorp_inventory:useItem", function(eventData)
    local _source = source
    local itemName = eventData.item
    local mainId = eventData.id -- ID konkrétního itemu

    if itemName == Config.FileItem then
        -- Získáme kompletní data o itemu (včetně metadat)
        exports.vorp_inventory:getItemByMainId(_source, mainId, function(itemData)
            if itemData then
                print("Otevírám soubor z kartotéky pro hráče " .. _source)
                print(json.encode(itemData, {indent=true}))
                TriggerClientEvent("aprts_filecabinet:Client:OpenSingleFile", _source, itemData)
            end
        end)
    end
end)


-- AddEventHandler("vorp_inventory:useItem")
-- RegisterServerEvent("vorp_inventory:useItem", function(data)
--     local _source = source
--     local itemName = data.item
--     exports.vorp_inventory:getItemByMainId(_source, data.id, function(data)
--         if data == nil then
--             return
--         end
--         local metadata = data.metadata
--         if metadata then
           
--         end
--     end)
-- end)




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
    
    local emptyPapersCount = exports.vorp_inventory:getItemCount(_source, nil, Config.EmptyPaperItem)
    
    local files = getFilesFromInventory(inventoryID)
    
    -- PŘIDÁNO: Posíláme i Config.DocumentTypes
    TriggerClientEvent("aprts_filecabinet:Client:OpenCabinetMenu", _source, id, files, emptyPapersCount, Config.DocumentTypes)
end)




RegisterServerEvent("aprts_filecabinet:Server:addFileToCabinet")
AddEventHandler("aprts_filecabinet:Server:addFileToCabinet", function(cabinetId, fileData)
    local _source = source
    local prefix = Config.InventoryPrefix
    local inventoryID = prefix .. tostring(cabinetId)

    local hasPaper = exports.vorp_inventory:getItemCount(_source, nil, Config.EmptyPaperItem)
    if hasPaper <= 0 then
        TriggerClientEvent('notifications:notify', _source, "CHYBA", "Nemáš u sebe čistý papír!", 3000)
        print("Nemáš u sebe čistý papír!")
        return
    end

    local items = {{
        name = Config.FileItem,
        amount = 1,
        metadata = {
            label = fileData.title,
            description = "Dokument: " .. fileData.title,
            content = fileData.content,
            title = fileData.title,
            docType = fileData.docType or 'standard' -- Ukládáme typ dokumentu
        }
    }}
   
    exports.vorp_inventory:subItem(_source, Config.EmptyPaperItem, 1)
    if  exports.vorp_inventory:addItemsToCustomInventory(inventoryID, items,1) then
        TriggerClientEvent('notifications:notify', _source, "ÚSPĚCH", "Soubor byl uložen do kartotéky.", 3000)
    else
        TriggerClientEvent('notifications:notify', _source, "CHYBA", "Nepodařilo se uložit soubor do kartotéky.", 3000)
    end
end)

RegisterServerEvent("aprts_filecabinet:Server:removeFileFromCabinet")
AddEventHandler("aprts_filecabinet:Server:removeFileFromCabinet", function(cabinetId, itemID)
    local _source = source
    local prefix = Config.InventoryPrefix
    local inventoryID = prefix .. tostring(cabinetId)

    -- Odebrat soubor ze skříňky
    exports.vorp_inventory:removeItemFromCustomInventory(inventoryID,Config.FileItem,1, itemID, 1)


end)



RegisterServerEvent("aprts_filecabinet:Server:editFileInCabinet")
AddEventHandler("aprts_filecabinet:Server:editFileInCabinet", function(cabinetId, fileData)
    local _source = source
    local prefix = Config.InventoryPrefix
    local inventoryID = prefix .. tostring(cabinetId)
    local originalItemID = fileData.originalItemID -- Toto je Crafted ID itemu, který chceme smazat

    -- 1. Zkontroluj práva (implementuj zde, pokud chceš)
    -- například: if not hasJob(_source, Config.CabinetLocations[cabinetId].jobs) then return end

    -- 2. Odeber starý item
    local successRemove = exports.vorp_inventory:removeItemFromCustomInventory(inventoryID, Config.FileItem, 1, originalItemID)
    
    if not successRemove then
        TriggerClientEvent('notifications:notify', _source, "CHYBA", "Nepodařilo se najít původní dokument k editaci!", 4000)
        LOG(_source, "FILECABINET_ERROR", "Nepodařilo se odebrat původní dokument " .. originalItemID .. " z kartotéky " .. cabinetId .. " pro editaci.")
        return
    end

    -- 3. Vytvoř nový item s aktualizovanými daty
    local items = {{
        name = Config.FileItem,
        amount = 1,
        metadata = {
            label = fileData.title,
            description = "Dokument: " .. fileData.title .. " (Typ: " .. (Config.DocumentTypes[fileData.docType].label or "Neznámý") .. ")",
            content = fileData.content,
            title = fileData.title,
            docType = fileData.docType or 'standard',
            -- Volitelné: Aktualizovat kdo upravil
            -- lastEditorCharId = Player(_source).state.Character.CharId,
            -- lastEditorName = GetPlayerName(_source),
            -- lastEditedAt = os.time()
        }
    }}

    exports.vorp_inventory:addItemsToCustomInventory(inventoryID, items,1)

    LOG(_source, "FILECABINET", "Editoval dokument " .. originalItemID .. " v kartotéce " .. cabinetId .. ": Nový název: " .. fileData.title .. " (Typ: " .. fileData.docType .. ")")
    TriggerClientEvent('notifications:notify', _source, "ÚSPĚCH", "Dokument úspěšně upraven!", 3000)
end)

RegisterServerEvent("aprts_filecabinet:Server:copyFile")
AddEventHandler("aprts_filecabinet:Server:copyFile", function(cabinetId, fileData)
    local _source = source
    local prefix = Config.InventoryPrefix
    local inventoryID = prefix .. tostring(cabinetId)

    -- 1. Kontrola papíru
    local hasPaper = exports.vorp_inventory:getItemCount(_source, nil, Config.EmptyPaperItem)
    if hasPaper <= 0 then
        TriggerClientEvent('notifications:notify', _source, "CHYBA", "Nemáš u sebe čistý papír na kopii!", 3000)
        return
    end

    -- 2. Vytvoření nového názvu
    local newTitle = "Kopie - " .. fileData.title
    -- Zkrácení, aby to nebylo moc dlouhé, pokud se kopíruje kopie
    if string.len(newTitle) > 40 then
        newTitle = string.sub(newTitle, 1, 40)
    end

    -- 3. Příprava itemu

        local metadata = {
            label = newTitle,
            description = "Kopie dokumentu: " .. fileData.title,
            content = fileData.content,
            title = newTitle,
            docType = fileData.docType or 'standard'
        }

   
    -- 4. Odebrání papíru a přidání itemu
    exports.vorp_inventory:subItem(_source, Config.EmptyPaperItem, 1)
    exports.vorp_inventory:addItem(_source, Config.FileItem, 1, metadata)

    LOG(_source, "FILECABINET", "Vytvořil kopii dokumentu '" .. fileData.title .. "' v kartotéce " .. cabinetId)
    TriggerClientEvent('notifications:notify', _source, "KARTOTÉKA", "Kopie vytvořena.", 2000)
end)