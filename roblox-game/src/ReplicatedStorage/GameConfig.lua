-- GameConfig.lua (ModuleScript)
-- Single source of truth for all game balance values.

local GameConfig = {}

-- ── Clicking ──────────────────────────────────────────────────────────────────
GameConfig.BASE_COINS_PER_CLICK = 1
GameConfig.CLICK_COOLDOWN       = 0.08

-- ── Lucky clicks ─────────────────────────────────────────────────────────────
GameConfig.LUCKY_CHANCE = 0.05
GameConfig.LUCKY_MULT   = 10

-- ── Passive income ────────────────────────────────────────────────────────────
GameConfig.PASSIVE_TICK = 1

-- ── Rebirth ───────────────────────────────────────────────────────────────────
GameConfig.REBIRTH_BASE_COST = 500    -- lowered: reachable in ~2 min with a pet
GameConfig.REBIRTH_COST_MULT = 3
GameConfig.REBIRTH_BONUS     = 2

-- ── Eggs ─────────────────────────────────────────────────────────────────────
-- Basic Egg is 20 coins — reachable in ~20 clicks so the loop starts immediately
GameConfig.EGGS = {
    {
        id    = "basic",
        name  = "Basic Egg",
        cost  = 20,
        color = BrickColor.new("Bright yellow"),
        pets  = {
            { name = "Cat",    multi = 2,   weight = 55, color = BrickColor.new("Light orange") },
            { name = "Dog",    multi = 4,   weight = 28, color = BrickColor.new("Reddish brown") },
            { name = "Fox",    multi = 10,  weight = 13, color = BrickColor.new("Neon orange") },
            { name = "Dragon", multi = 30,  weight = 4,  color = BrickColor.new("Bright red") },
        },
    },
    {
        id    = "super",
        name  = "Super Egg",
        cost  = 400,
        color = BrickColor.new("Hot pink"),
        pets  = {
            { name = "Lion",    multi = 20,  weight = 50, color = BrickColor.new("Bright yellow") },
            { name = "Tiger",   multi = 50,  weight = 30, color = BrickColor.new("Neon orange") },
            { name = "Griffin", multi = 120, weight = 15, color = BrickColor.new("Gold") },
            { name = "Phoenix", multi = 300, weight = 5,  color = BrickColor.new("Bright red") },
        },
    },
    {
        id    = "legendary",
        name  = "Legendary Egg",
        cost  = 4000,
        color = BrickColor.new("Cyan"),
        pets  = {
            { name = "Unicorn",   multi = 250,  weight = 40, color = BrickColor.new("White") },
            { name = "Kraken",    multi = 600,  weight = 30, color = BrickColor.new("Bright blue") },
            { name = "Leviathan", multi = 1500, weight = 20, color = BrickColor.new("Deep blue") },
            { name = "Celestial", multi = 4000, weight = 10, color = BrickColor.new("Cyan") },
        },
    },
}

-- ── Upgrades ─────────────────────────────────────────────────────────────────
-- Click Power starts at 10 coins — buyable after ~10 clicks, before first egg
GameConfig.UPGRADES = {
    { id = "click_power",   name = "Click Power",  desc = "+1 coin per click",      baseCost = 10,  costMult = 1.6 },
    { id = "auto_click",    name = "Auto Clicker", desc = "1 free click per second", baseCost = 75,  costMult = 2.0 },
    { id = "passive_boost", name = "Coin Magnet",  desc = "2× passive income",       baseCost = 150, costMult = 1.8 },
}

GameConfig.MAX_PETS = 5

-- ── Sounds (rbxasset:// always loads in Studio, no 403) ──────────────────────
GameConfig.SOUNDS = {
    click   = "rbxasset://sounds/electronicpingshort.wav",
    coin    = "rbxasset://sounds/electronicpingshort.wav",
    hatch   = "rbxasset://sounds/pop_mid.wav",
    upgrade = "rbxasset://sounds/electronicpingshort.wav",
    rebirth = "rbxasset://sounds/pop_mid.wav",
    lucky   = "rbxasset://sounds/pop_mid.wav",
}

return GameConfig
