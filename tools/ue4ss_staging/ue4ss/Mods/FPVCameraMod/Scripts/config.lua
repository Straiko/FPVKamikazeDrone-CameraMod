-- FPV Camera Mod Configuration
-- FPV Kamikaze Drone: Macro / Non-Macro Camera Switcher

local Config = {}

-- Key bindings:
-- Toggle between Macro and Non-Macro:
Config.ToggleKey = Key.V
Config.AltToggleKey = Key.C

-- Fine adjustment keys:
Config.FovIncreaseKey = Key.RIGHT_BRACKET -- ']' key (or NUM_PLUS)
Config.FovDecreaseKey = Key.LEFT_BRACKET  -- '[' key (or NUM_MINUS)

-- Camera FOV presets (degrees):
-- Macro mode (default narrow/zoomed view for precision targeting):
Config.MacroFOV = 65.0

-- Non-Macro mode (wide-angle FPV view for navigation and high situational awareness):
Config.NonMacroFOV = 115.0

-- Step size when adjusting FOV manually:
Config.FovStep = 5.0

-- Minimum and maximum allowable FOV:
Config.MinFOV = 40.0
Config.MaxFOV = 140.0

-- Smooth FOV transitions (true = smoothly interpolate, false = instant snap):
Config.SmoothTransition = true
Config.TransitionSpeed = 12.0 -- higher = faster transition

-- On-screen notification:
Config.ShowOnScreenMessage = true

return Config
