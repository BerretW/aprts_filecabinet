AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        -- MySQL:execute("SELECT * FROM aprts_clues", {}, function(result)
        --     for k, v in pairs(result) do
        --         v.coords = json.decode(v.coords)
        --         clues[v.id] = v

        --     end
        -- end)

        for id, cabinet in pairs(Config.CabinetLoactions) do
            RegisterInventory(id, cabinet.name)
        end
    end
end)

-- RegisterServerEvent("aprts_vzor:Server:RegisterInventory")
-- AddEventHandler("aprts_vzor:Server:RegisterInventory", function(inventoryName, prefix,shared,weapons,itemLimit, weightLimit)
--     local _source = source
--     local stor_id = Player(_source).state.Character.CharId

--     local isRegistered = exports.vorp_inventory:isCustomInventoryRegistered(prefix .. tostring(stor_id))

--     if isRegistered then
--         debgPrint("Inventář " .. prefix .. tostring(stor_id) .. " je již zaregistrovaný")
--         exports.vorp_inventory:removeInventory(prefix .. tostring(stor_id))
--     end

--     local data = {
--         id = prefix .. tostring(stor_id),
--         name = inventoryName,
--         limit = itemLimit,
--         acceptWeapons = weapons,
--         shared = shared,
--         ignoreItemStackLimit = true,
--         whitelistItems = false,
--         UsePermissions = false,
--         UseBlackList = false,
--         whitelistWeapons = false,
--         useWeight = true,
--         weight = weightLimit
--     }
--     exports.vorp_inventory:registerInventory(data)
-- end)

AddEventHandler("vorp_inventory:useItem")
RegisterServerEvent("vorp_inventory:useItem", function(data)
    local _source = source
    local itemName = data.item
    exports.vorp_inventory:getItemByMainId(_source, data.id, function(data)
        if data == nil then
            return
        end
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
    local stor_id = Player(_source).state.Character.CharId

    local inventoryID = prefix .. tostring(id)
    local cabinetItems = {}
    exports.vorp_inventory:openInventory(_source, inventoryID)
end)

RegisterServerEvent("aprts_filecabinet:Server:OpenCabinetMenu")
AddEventHandler("aprts_filecabinet:Server:OpenCabinetMenu", function(id)
    local _source = source
    local prefix = Config.InventoryPrefix
    local stor_id = Player(_source).state.Character.CharId

    local inventoryID = prefix .. tostring(id)
    local cabinetItems = {}
    exports.vorp_inventory:getCustomInventoryItems(inventoryID, function(items)
        if items == nil then
            notify("Tato kartotéka je prázdná.")
            return
        else
            print("Načítání položek kartotéky...")
            print(json.encode(items, {
                indent = true
            }))
            for _, item in pairs(items) do
                if item.name == "filecabinet_key" then
                    table.insert(cabinetItems, item.crafted_id)
                end
            end
        end
    end)
    TriggerClientEvent("aprts_filecabinet:Client:OpenCabinetMenu", _source, cabinetItems)
end)

RegisterServerEvent("aprts_filecabinet:Server:GetItemMeta")
AddEventHandler("aprts_filecabinet:Server:GetItemMeta", function(itemID, cb)
    local _source = source
    local prefix = Config.InventoryPrefix

    local item = exports.vorp_inventory:getItemById(_source, itemID)
    if item then
        cb(item.metadata)
    else
        cb(nil)
    end
end)

RegisterServerEvent("aprts_filecabinet:Server:SaveItemMeta")
AddEventHandler("aprts_filecabinet:Server:SaveItemMeta", function(itemID, content, title)
    local _source = source
    local prefix = Config.InventoryPrefix

    local item = exports.vorp_inventory:getItemById(_source, itemID)
    if item then
        item.metadata.content = content
        item.metadata.title = title
        exports.vorp_inventory:setItemMetadata(_source, itemID, item.metadata, 1)
    end
end)
