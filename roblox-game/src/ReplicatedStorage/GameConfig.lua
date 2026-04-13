-- GameConfig.lua (ModuleScript)
-- Shared configuration used by both server and client scripts

local GameConfig = {}

GameConfig.GAME_NAME    = "Obby Adventure"
GameConfig.MAX_STAGES   = 10
GameConfig.VOID_HEIGHT  = -100   -- Y position below which a player is considered "in the void"
GameConfig.STAGE_SPACING = 60    -- Studs between stage checkpoints along the X axis

-- BrickColor theme per stage (index matches stage number)
GameConfig.STAGE_COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright orange"),
    BrickColor.new("Bright yellow"),
    BrickColor.new("Lime green"),
    BrickColor.new("Cyan"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Hot pink"),
    BrickColor.new("Magenta"),
    BrickColor.new("White"),
    BrickColor.new("Gold"),
}

return GameConfig
