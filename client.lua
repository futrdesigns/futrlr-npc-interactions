local Framework = nil
local ESX, QBCore = nil, nil
local npcEntities = {}
local interacting = false

CreateThread(function()
    if GetResourceState("es_extended") == "started" then
        Framework = "ESX"
        ESX = exports["es_extended"]:getSharedObject()
    elseif GetResourceState("qb-core") == "started" then
        Framework = "QBCORE"
        QBCore = exports['qb-core']:GetCoreObject()
    else
        Framework = "STANDALONE"
    end
end)

function Notify(msg, msgType)
    msgType = msgType or "info"

    if Config.NotificationSystem == "ox" then
        if lib and lib.notify then
            lib.notify({
                title = "Lunar NPC",
                description = msg,
                type = msgType
            })
        end

    elseif Config.NotificationSystem == "okok" then
        TriggerEvent('okokNotify:Alert', "Lunar NPC", msg, 6000, msgType)

    elseif Config.NotificationSystem == "mythic" then
        TriggerEvent('mythic_notify:client:SendAlert', { type = msgType, text = msg })

    elseif Config.NotificationSystem == "qb" then
        TriggerEvent('QBCore:Notify', msg, msgType)

    elseif Config.NotificationSystem == "esx" then
        ESX.ShowNotification(msg)

    elseif Config.NotificationSystem == "custom" then
        print("[CUSTOM NOTIFY] " .. msg)

    else
        print("[DEFAULT NOTIFY] " .. msg)
    end
end

CreateThread(function()
    Wait(300)
    for _, def in ipairs(Config.NPCs) do
        local model = joaat(def.model)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end

        local ped = CreatePed(4, model, def.coords.x, def.coords.y, def.coords.z - 1.0, def.heading, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        if def.scenario then
            TaskStartScenarioInPlace(ped, def.scenario, 0, true)
        end
        npcEntities[def.id] = { ped = ped, def = def }
    end
end)

CreateThread(function()
    while true do
        local ply = PlayerPedId()
        local pcoords = GetEntityCoords(ply)
        local sleep = 1200

        for npcId, info in pairs(npcEntities) do
            local dist = #(pcoords - info.def.coords)

            if dist < 15.0 then
                sleep = 0
                if dist < 2.0 then
                    DrawText3D(info.def.coords.x, info.def.coords.y, info.def.coords.z + 1.0, "~y~[E]~s~ Talk")
                    if IsControlJustReleased(0, 38) and not interacting then
                        interacting = true
                        StartNPCInteraction(npcId, info)
                        Wait(400)
                        interacting = false
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function StartNPCInteraction(npcId, info)
    local state = nil

    TriggerServerEvent("lunar_npc:getPlayerStateForNPC", npcId)

    RegisterNetEvent("lunar_npc:returnPlayerStateForNPC", function(returnId, data)
        if returnId == npcId then state = data end
    end)

    local waited = 0
    while not state and waited < 2000 do
        Wait(50)
        waited = waited + 50
    end

    local opts = {}
    local def = info.def
    local reputation = state.reputation or 0
    local seen = state.seen
    local grudge = state.grudge or 0

    local greeting = "Happy Lunar New Year!"

    if grudge > 0 then greeting = "You again... I have not forgotten."
    elseif reputation < -5 then greeting = "I do not trust you."
    elseif reputation > 5 then greeting = "Ahh, friend! Good fortune!"
    elseif seen then greeting = "Welcome back!"
    end

    table.insert(opts, { label = greeting, action = "greet" })
    table.insert(opts, { label = "Receive a Red Envelope 🧧", action = "redenvelope" })

    if def.type == "shopkeeper" then
        table.insert(opts, { label = "Browse Shop", action = "browse" })
        table.insert(opts, { label = "Rob (Test)", action = "rob" })
    end

    if grudge == 0 then
        table.insert(opts, { label = "Ask for Blessing", action = "blessing" })
    else
        table.insert(opts, { label = "Apologize", action = "apologize" })
    end

    local pick = ShowSimpleMenu("Lunar NPC", opts)

    if pick == "greet" then
        Notify(greeting)
        TriggerServerEvent("lunar_npc:playerInteracted", npcId, { repGain = 1 })

    elseif pick == "redenvelope" then
        TriggerServerEvent("lunar_npc:requestRedEnvelope", npcId)

    elseif pick == "browse" then
        Notify("Shop system not yet integrated.")

    elseif pick == "rob" then
        TriggerServerEvent("lunar_npc:playerNegativeInteraction", npcId, "robbery")
        TriggerServerEvent("lunar_npc:reportRobbery", npcId, info.def.coords)
        Notify("You attempt to rob the shopkeeper...")

    elseif pick == "blessing" then
        Notify(Config.LuckMessages[math.random(#Config.LuckMessages)])
        TriggerServerEvent("lunar_npc:playerInteracted", npcId, { repGain = 2 })

    elseif pick == "apologize" then
        Notify("You apologize sincerely...")
        TriggerServerEvent("lunar_npc:playerInteracted", npcId, { repGain = 3 })
    end
end

function ShowSimpleMenu(title, items)
    Notify(title)
    for i, v in ipairs(items) do
        Notify(("(%d) %s"):format(i, v.label))
    end
    Wait(1000)
    return items[1].action
end

function DrawText3D(x, y, z, txt)
    SetTextScale(0.38, 0.38)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(txt)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

RegisterNetEvent("lunar_npc:envelopeGiven", function(reward)
    Notify(("You received %s x%s"):format(reward.item, reward.amount))
end)

RegisterNetEvent("lunar_npc:notifyNearby", function(coords, txt)
    local pcoords = GetEntityCoords(PlayerPedId())
    if #(pcoords - vector3(coords.x, coords.y, coords.z)) < 80.0 then
        Notify(txt)
    end
end)
