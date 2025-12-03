local Framework = nil
local ESX, QBCore = nil, nil

local playerMemory = {}
local npcData = {}

CreateThread(function()
    Wait(200)
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

local function getIdentifier(src)
    if Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer.identifier
    elseif Framework == "QBCORE" then
        local p = QBCore.Functions.GetPlayer(src)
        return p.PlayerData.citizenid
    else
        return "player-" .. src
    end
end

local function getMemory(id)
    if not playerMemory[id] then
        playerMemory[id] = {
            seenBy = {},
            reputation = 0,
            grudges = {},
            lastRobberies = {},
            lastCall = {}
        }
    end
    return playerMemory[id]
end

local function getWeightedReward()
    local total = 0
    for _, r in ipairs(Config.Rewards) do total = total + r.chance end
    local roll = math.random(total)
    local c = 0
    for _, r in ipairs(Config.Rewards) do
        c = c + r.chance
        if roll <= c then return r end
    end
end

local function giveReward(src, reward)
    if Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if reward.item == "money" then xPlayer.addMoney(reward.amount)
        else xPlayer.addInventoryItem(reward.item, reward.amount) end

    elseif Framework == "QBCORE" then
        local Player = QBCore.Functions.GetPlayer(src)
        if reward.item == "money" then Player.Functions.AddMoney("cash", reward.amount)
        else Player.Functions.AddItem(reward.item, reward.amount) end

    else
        print("[STANDALONE REWARD]", reward.item, reward.amount)
    end
end

function SendDispatch(coords, message)
    message = message or "Suspicious activity reported."

    if Config.DispatchSystem == "codesign3d" then
        TriggerEvent('cd_dispatch:CreateNotification', {
            job = { "police" },
            coords = coords,
            title = "NPC Disturbance",
            message = message,
            flash = true,
            blip = true,
            sprite = 431,
            color = 1,
            scale = 1.2,
            sound = 1
        })
        return
    end

    if Config.DispatchSystem == "codesign" or Config.DispatchSystem == "cd_dispatch" then
        TriggerEvent('cd_dispatch:AddNotification', {
            job_table = { "police" },
            coords = coords,
            title = "NPC Alert",
            message = message,
            flash = true,
            unique_id = tostring(math.random(1111,9999)),
            sound = 1
        })
        return
    end

    if Config.DispatchSystem == "ccd_dispatch" then
        TriggerEvent('ccd_dispatch:AddNotification', {
            job = "police",
            coords = coords,
            msg = message
        })
        return
    end

    if Config.DispatchSystem == "qb" then
        TriggerEvent("qb-dispatch:server:CreateCall", "10-90", {
            message = message,
            coords = coords
        })
        return
    end

    if Config.DispatchSystem == "custom" then
        print("[CUSTOM DISPATCH]", message, coords)
        return
    end

    print("[DEFAULT DISPATCH] Police alert:", message)
end

RegisterServerEvent("lunar_npc:getPlayerStateForNPC")
AddEventHandler("lunar_npc:getPlayerStateForNPC", function(npcId)
    local src = source
    local id = getIdentifier(src)
    local mem = getMemory(id)
    local g = mem.grudges[npcId]

    TriggerClientEvent("lunar_npc:returnPlayerStateForNPC", src, npcId, {
        seen = mem.seenBy[npcId] or false,
        reputation = mem.reputation or 0,
        grudge = g and g.level or 0,
        grudgeExpires = g and g.expires or 0
    })
end)

RegisterServerEvent("lunar_npc:playerInteracted")
AddEventHandler("lunar_npc:playerInteracted", function(npcId, data)
    local src = source
    local id = getIdentifier(src)
    local mem = getMemory(id)

    mem.seenBy[npcId] = true
    mem.reputation = mem.reputation + (data.repGain or 1)

    if mem.grudges[npcId] then mem.grudges[npcId] = nil end
end)

RegisterServerEvent("lunar_npc:playerNegativeInteraction")
AddEventHandler("lunar_npc:playerNegativeInteraction", function(npcId, reason)
    local src = source
    local id = getIdentifier(src)
    local mem = getMemory(id)

    mem.reputation = mem.reputation - 2
    local g = mem.grudges[npcId] or { level = 0, expires = 0 }

    g.level = math.min(Config.Grudge.maxGrudgeLevel, g.level + 1)
    local extra = Config.Grudge.baseDuration * (Config.Grudge.holdMultiplier ^ (g.level-1))
    g.expires = os.time() + math.floor(extra)

    mem.grudges[npcId] = g
end)

RegisterServerEvent("lunar_npc:requestRedEnvelope")
AddEventHandler("lunar_npc:requestRedEnvelope", function(npcId)
    local src = source
    local reward = getWeightedReward()
    giveReward(src, reward)

    local id = getIdentifier(src)
    local mem = getMemory(id)
    mem.reputation = mem.reputation + 1

    TriggerClientEvent("lunar_npc:envelopeGiven", src, reward)
end)

RegisterServerEvent("lunar_npc:reportRobbery")
AddEventHandler("lunar_npc:reportRobbery", function(npcId, coords)
    local src = source
    local id = getIdentifier(src)
    local mem = getMemory(id)

    mem.lastRobberies[npcId] = mem.lastRobberies[npcId] or { count = 0, times = {} }
    local entry = mem.lastRobberies[npcId]

    table.insert(entry.times, os.time())

    local pruned = {}
    for _, t in ipairs(entry.times) do
        if os.time() - t <= Config.Robbery.robberyResetTime then
            table.insert(pruned, t)
        end
    end

    entry.times = pruned
    entry.count = #pruned

    npcData[npcId] = npcData[npcId] or { globalRobberies = {}, lastCalled = 0 }
    table.insert(npcData[npcId].globalRobberies, os.time())

    local newglobal = {}
    for _, t in ipairs(npcData[npcId].globalRobberies) do
        if os.time() - t <= Config.Robbery.robberyResetTime then
            table.insert(newglobal, t)
        end
    end
    npcData[npcId].globalRobberies = newglobal

    if #npcData[npcId].globalRobberies >= Config.Robbery.thresholdToCallPolice then
        local cd = npcData[npcId].lastCalled
        if os.time() - cd > Config.Robbery.cooldownAfterCall then
            npcData[npcId].lastCalled = os.time()
            SendDispatch(coords, "Multiple robbery attempts reported at a Lunar New Year stall.")
            TriggerClientEvent("lunar_npc:notifyNearby", -1, coords, "Shopkeeper called police due to repeated robberies.")
        end
    end
end)

CreateThread(function()
    while true do
        for pid, mem in pairs(playerMemory) do
            for npcId, g in pairs(mem.grudges) do
                if os.time() > g.expires then
                    mem.grudges[npcId] = nil
                end
            end
        end
        Wait(60000)
    end
end)
