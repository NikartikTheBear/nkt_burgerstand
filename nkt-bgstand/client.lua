local propModels = {'prop_burgerstand_01'}
local anims = {"pickup_object", "mini@repair"}
for i=1, #anims do
    lib.requestAnimDict(anims[i])
end
for i=1, #propModels do    
    lib.requestModel(propModels[i])
end

exports.ox_inventory:displayMetadata({
    owner = "Owner",
    l_t = "License for",
    number = "License n.",
    date = "Date"
})


exports.ox_target:addSphereZone({
    coords = Config.license.location,
    radius = 3,
    options = {
        {
            label = "New Burger license",
            name = "burger_license",
            distance = 3,
            onSelect = function(data)
                TriggerServerEvent("bgstand:server:newLicense", data.coords)
            end
        }
    }
})

exports("useCart", function(data, slot)
    local coords = GetEntityCoords(cache.ped)
    local forwardVector = GetEntityForwardVector(cache.ped)


    exports.ox_inventory:useItem(data, function(data)
        if data then
            TaskPlayAnim(cache.ped, "pickup_object", "pickup_low", 8.0, 8.0, 1000, 50, 0, false, false, false)
            Wait(900)
            local offset = 2.0
            local cartPosition = vector3(coords.x + forwardVector.x * offset, coords.y + forwardVector.y * offset, coords.z - 0.4)
            local cart = CreateObjectNoOffset(propModels[1], cartPosition.x, cartPosition.y, cartPosition.z, true, false)
            PlaceObjectOnGroundProperly(cart)
            TriggerServerEvent("bgstand:server:registerInv")
            exports.ox_target:addLocalEntity(cart, {
                {
                    name = 'open' .. cart,
                    label = 'Open drawer',
                    icon = 'fa-solid fa-tent',
                    onSelect = function(data)
                        exports.ox_inventory:openInventory('stash', {id=LocalPlayer.state.license.."_cart", owner=LocalPlayer.state.license})
                    end
                },
                {
                    name = 'cook' .. cart,
                    label = 'Cook',
                    icon = 'fa-solid fa-burger',
                    onSelect = function(data)
                        lib.showContext("cart_cook")
                        TaskPlayAnim(cache.ped, "mini@repair", "fixing_a_player", 8.0, 8.0, -1, 50, 0, false, false, false)
                    end
                },
                {
                    name = 'take' .. cart,
                    label = 'Pickup cart',
                    icon = 'fa-solid fa-hand-back-fist',
                    onSelect = function(data)
                        TaskPlayAnim(cache.ped, "pickup_object", "pickup_low", 8.0, 8.0, 1000, 50, 0, false, false, false)
                        Wait(900)
                        DeleteEntity(data.entity)
                        ClearPedTasks(cache.ped)
                        TriggerServerEvent("bgstand:server:giveCart", data.coords)
                        SetModelAsNoLongerNeeded(data.entity)
                    end
                },
            })
        end
    end)
end)

local options = {}
for k, v in pairs (Config.Recipes) do
        options[#options+1] = {
            title = k,
            description = "Cook a delicious "..k,
            onSelect = function()
                local items = {}
                for _, m in pairs(v.required) do
                    local count = lib.callback.await('bgstand:getItemCount', false, _)
                    if count.count >= v.required[count.name] then items[_] = v.required[count.name] end
                end
                local success = lib.skillCheck({v.difficulty}, {'w', 'a', 's', 'd'})
                if success then
                    TriggerServerEvent("bgstand:server:cookMeth", k,  items)
                end
                 ClearPedTasks(cache.ped)
            end,
        }
end


lib.registerContext({
    id = "cart_cook",
    title = "Burger Stand Kitchen",
    onExit = function()
        ClearPedTasks(cache.ped)
    end,
    options = options
})