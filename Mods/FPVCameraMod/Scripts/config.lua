-- FPV Flight Mode Configuration
-- FPV Kamikaze Drone: Acro <-> Non-Acro (Angle / Stabilized) Switcher

local Config = {}

-- Key bindings:
-- Toggle between Acro (manual rate) and Non-Acro (stabilized / angle mode):
Config.ToggleKey = Key.V
Config.AltToggleKey = Key.C

-- Default flight mode on start:
-- Options: "ACRO" (pure manual / rate mode) or "NON_ACRO" (self-leveling / angle mode)
Config.DefaultMode = "ACRO"

-- Non-Acro (Angle Mode) Stabilizer Tuning:
-- Responsiveness of returning to level (higher = snaps to horizon faster):
Config.StabilizerStrength = 4.5

-- Damping factor (smoothness of leveling, 0.1 to 0.5):
Config.Damping = 0.35

-- Maximum tilt angle allowed in Non-Acro mode (degrees):
Config.MaxTiltAngle = 50.0

-- On-screen HUD notification when switching modes:
Config.ShowOnScreenMessage = true

return Config
