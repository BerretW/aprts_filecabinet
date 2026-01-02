local function LoadModel(model)
    local model = GetHashKey(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(10)
    end
end

local function spawnProp(prop, coords, h)
    local hash = GetHashKey(prop)
    LoadModel(prop)
    local object = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(object, h)
    SetModelAsNoLongerNeeded(hash)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
    return object
end

local function spawnPed(model, coords)
    debugPrint('Spawning ped: ' .. model)
    model = LoadModel(model)
    local ped = CreatePed(model, coords.x, coords.y, coords.z, 0.0, true, false)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)

    PlaceEntityOnGroundProperly(ped)
    SetModelAsNoLongerNeeded(model)
    return ped
end


local function spawnNPC(model, x, y, z)
    local modelHash = LoadModel(model)
    local npc_ped = CreatePed(model, x, y, z, false, false, false, false)
    PlaceEntityOnGroundProperly(npc_ped)
    Citizen.InvokeNative(0x283978A15512B2FE, npc_ped, true)
    print('npc_ped: ' .. npc_ped)
    SetEntityHeading(npc_ped, 0.0)
    SetEntityCanBeDamaged(npc_ped, false)
    SetEntityInvincible(npc_ped, true)
    FreezeEntityPosition(npc_ped, true)
    SetBlockingOfNonTemporaryEvents(npc_ped, true)
    SetEntityCompletelyDisableCollision(npc_ped, false, false)

    Citizen.InvokeNative(0xC163DAC52AC975D3, npc_ped, 6)
    Citizen.InvokeNative(0xC163DAC52AC975D3, npc_ped, 0)
    Citizen.InvokeNative(0xC163DAC52AC975D3, npc_ped, 1)
    Citizen.InvokeNative(0xC163DAC52AC975D3, npc_ped, 2)

    SetModelAsNoLongerNeeded(modelHash)
    return npc_ped
end


Citizen.CreateThread(function()
    while true do
        local pause = 1000

        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)

        Citizen.Wait(pause)
    end
end)
