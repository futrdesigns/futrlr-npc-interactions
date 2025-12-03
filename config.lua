Config = {}

-- NPCs
Config.NPCs = {
    {
        id = "lunar_oldman_1",
        model = "cs_old_man2",
        coords = vector3(-632.85, -235.75, 38.05),
        heading = 130.0,
        scenario = "WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT",
        type = "celebrant"
    },
    {
        id = "lunar_shop_1",
        model = "ig_mrs_thornhill",
        coords = vector3(-622.0, -237.0, 38.05),
        heading = 90.0,
        scenario = "WORLD_HUMAN_AA_SMOKE",
        type = "shopkeeper"
    }
}

-- NOTIFICATION SYSTEM
-- options: "ox", "okok", "mythic", "qb", "esx", "custom"
Config.NotificationSystem = "ox"

-- DISPATCH SYSTEM
-- options:
-- "codesign" (cd_dispatch / ccd_dispatch auto-detect)
-- "codesign3d" (CodeSign 3D dispatch version)
-- "qb", "cd_dispatch", "ccd_dispatch", "custom"
Config.DispatchSystem = "codesign3d"

-- Weighted rewards
Config.Rewards = {
    { item = "money", amount = 500, chance = 55 },
    { item = "money", amount = 1500, chance = 25 },
    { item = "goldbar", amount = 1, chance = 5 },
    { item = "firework", amount = 3, chance = 15 }
}

-- GRUDGE SYSTEM
Config.Grudge = {
    baseDuration = 60 * 30,
    holdMultiplier = 1.5,
    maxGrudgeLevel = 5
}

-- ROBBERY DETECTION
Config.Robbery = {
    detectRadius = 4.0,
    robberyResetTime = 60 * 5,
    thresholdToCallPolice = 2,
    cooldownAfterCall = 60 * 10
}

Config.Reactions = {
    jobs = {
        friendly = { "police", "doctor", "ambulance" },
        hostile = { "thief", "criminal" }
    },
    outfit_blacklist = {
        hostile = { 15, 24 }
    }
}

Config.LuckMessages = {
    "The Year of the Dragon brings you strength!",
    "Prosperity awaits those who greet the new year with joy.",
    "Harmony and fortune shine upon your path.",
    "Luck doubles when shared with kindness."
}
