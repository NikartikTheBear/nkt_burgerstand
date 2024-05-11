RegisterNetEvent("bgstand:server:registerInv", function()
    local source = source
    local id = GetPlayerIdentifierByType(source, "license"):gsub("license:", "")
    Player(source).state.license = id
    exports.ox_inventory:RegisterStash(id.."_cart", GetPlayerName(source).."'s burger cart", 20 , 30 * 1000)
end)

RegisterNetEvent("bgstand:server:giveCart", function(coords)
    local source = source
    local license
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
     if #(coords - playerCoords) > 5 then return end
    local data = exports.ox_inventory:Search(source, 1, "bglicense")
    for k, v in pairs(data) do
         license = v.metadata.number
    end
    exports.ox_inventory:AddItem(source, "burgerstand", 1, {
        owner = GetPlayerName(source),
        number = license
    })

end)

RegisterNetEvent("bgstand:server:newLicense", function(dist)
    local source = source
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
     if #(dist - playerCoords) > 5 then return end
    local s = exports.ox_inventory:RemoveItem(source, "money", Config.license.price)
    if s then
        exports.ox_inventory:AddItem(source, "bglicense", 1, {
            owner = GetPlayerName(source),
            l_t = "Burger - Meat",
            number = math.random(11111, 99999),
            date = os.date("%d/%m/%Y")
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {description = "You don't have enough money!"}) 
    end
end)


lib.callback.register('bgstand:getItemCount', function(source, item)
    local items = exports.ox_inventory:GetItem(source, item, nil, false)
    return items or 0
end)


local function equals(o1, o2)
    if o1 == o2 then return true end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or equals(value1, value2) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

RegisterNetEvent("bgstand:server:cookMeth", function(cook, items)
    local source = source
    local items = items
    local item = cook
    local cTb = Config.Recipes

    if equals(items, cTb[item].required) then
        for k, v in pairs(items) do
            exports.ox_inventory:RemoveItem(source, k, v)
        end
        exports.ox_inventory:AddItem(source, item, cTb[item].resultAmt)
    else
        TriggerClientEvent('ox_lib:notify', source, {description = "You don't have enough ingredients!"})
    end
        
end)

AddEventHandler("onServerResourceStart", function()
    CreateThread(function()
        BuyHook = exports.ox_inventory:registerHook('openInventory', function(payload)
            local license = GetPlayerIdentifierByType(payload.source, "license"):gsub("license:", "")
            if string.match(payload.inventoryId, "cart_") then
                local id = (payload.inventoryId):gsub("_cart", "")
                if id ~= license then
                    return false
                end
            end
        end)
        
        OpenHook = exports.ox_inventory:registerHook('createItem', function(payload)
            local metadata = payload.metadata
            metadata.owner = GetPlayerName(payload.inventoryId) or "N/A"
            return metadata
        end,{
            itemFilter = {
                burgerstand = true
            }
        })

        SwapHook = exports.ox_inventory:registerHook('swapItems', function(payload)
            if payload.toType == "stash" and string.match(payload.toInventory, "_cart") then
                return false
            end
        end,{
            itemFilter = {
                burgerstand = true
            }
        })
    end)
end)
AddEventHandler("onServerResourceStop", function()
    exports.ox_inventory:removeHooks(BuyHook)
    exports.ox_inventory:removeHooks(OpenHook)
    exports.ox_inventory:removeHooks(SwapHook)
end)