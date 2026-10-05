-- FPV Camera Mod Configuration
-- FPV Kamikaze Drone: Macro / Non-Macro Camera Switcher

local Config = {}

-- Key bindings:
-- Toggle between Macro (narrow/zoom) and Non-Macro (wide FPV):
Config.ToggleKey = Key.V
Config.AltToggleKey = Key.C

-- Fine adjustment keys:
-- In UE4SS Key enum: OEM_SIX is ']', OEM_FOUR is '[', ADD/SUBTRACT are numpad +/-
Config.FovIncreaseKey = Key.OEM_SIX or Key.ADD
Config.FovDecreaseKey = Key.OEM_FOUR or Key.SUBTRACT
Config.AltFovIncreaseKey = Key.ADD
Config.AltFovDecreaseKey = Key.SUBTRACT

-- Camera FOV presets (degrees):
-- Macro mode (default narrow/zoomed view for precision targeting):
Config.MacroFOV = 65.0

-- Non-Macro mode (wide-angle FPV view for navigation and flight awareness):
Config.NonMacroFOV = 115.0

-- Step size when adjusting FOV manually:
Config.FovStep = 5.0

-- Minimum and maximum allowable FOV:
Config.MinFOV = 40.0
Config.MaxFOV = 140.0

-- Smooth FOV transitions (true = smoothly interpolate, false = instant snap):
Config.SmoothTransition = true
Config.TransitionSpeed = 10.0 -- Higher = faster transition

-- On-screen notification:
Config.ShowOnScreenMessage = true

return Config
