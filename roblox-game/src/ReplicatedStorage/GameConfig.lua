-- GameConfig.lua (ModuleScript)
-- Single source of truth for all game balance values.
-- Both server and client scripts require this module.

local GameConfig = {}

-- ── Clicking ──────────────────────────────────────────────────────────────────
GameConfig.BASE_COINS_PER_CLICK = 1    -- Before upgrades/rebirths
GameConfig.CLICK_COOLDOWN       = 0.08 -- Minimum seconds between server-accepted clicks

-- ── Passive income ────────────────────────────────────────────────────────────
GameConfig.PASSIVE_TICK = 1            -- Seconds between passive income ticks

-- ── Eggs ─────────────────────────────────────────────────────────────────────
-- weight = relative hatch probability (higher = more common)
-- multi  = coins-per-second added by one of this pet when equipped
GameConfig.EGGS = {
    {
        id    = "basic",
        name  = "Basic Egg",
        cost  = 50,
        color = BrickColor.new("Bright yellow"),
        pets  = {
            { name = "Cat",    multi = 1,    weight = 55, color = BrickColor.new("Light orange") },
            { name = "Dog",    multi = 2,    weight = 28, color = BrickColor.new("Reddish brown") },
            { name = "Fox",    multi = 6,    weight = 13, color = BrickColor.new("Neon orange") },
            { name = "Dragon", multi = 20,   weight = 4,  color = BrickColor.new("Bright red") },
        },
    },
    {
        id    = "super",
        name  = "Super Egg",
        cost  = 500,
        color = BrickColor.new("Hot pink"),
        pets  = {
            { name = "Lion",    multi = 15,  weight = 50, color = BrickColor.new("Bright yellow") },
            { name = "Tiger",   multi = 35,  weight = 30, color = BrickColor.new("Neon orange") },
            { name = "Griffin", multi = 90,  weight = 15, color = BrickColor.new("Gold") },
            { name = "Phoenix", multi = 220, weight = 5,  color = BrickColor.new("Bright red") },
        },
    },
    {
        id    = "legendary",
        name  = "Legendary Egg",
        cost  = 5000,
        color = BrickColor.new("Cyan"),
        pets  = {
            { name = "Unicorn",   multi = 200,  weight = 40, color = BrickColor.new("White") },
            { name = "Kraken",    multi = 500,  weight = 30, color = BrickColor.new("Bright blue") },
            { name = "Leviathan", multi = 1200, weight = 20, color = BrickColor.new("Deep blue") },
            { name = "Celestial", multi = 3000, weight = 10, color = BrickColor.new("Cyan") },
        },
    },
}

-- ── Upgrades (each can be bought multiple times; cost = baseCost * costMult^level) ──
GameConfig.UPGRADES = {
    {
        id       = "click_power",
        name     = "Click Power",
        desc     = "+1 coin per click",
        baseCost = 25,
        costMult = 1.5,
    },
    {
        id       = "auto_click",
        name     = "Auto Clicker",
        desc     = "1 free click per second",
        baseCost = 100,
        costMult = 2.0,
    },
    {
        id       = "passive_boost",
        name     = "Coin Magnet",
        desc     = "2× passive income",
        baseCost = 200,
        costMult = 1.8,
    },
}

-- ── Pets ──────────────────────────────────────────────────────────────────────
GameConfig.MAX_PETS = 5   -- Maximum pets that give passive income at once

return GameConfig
