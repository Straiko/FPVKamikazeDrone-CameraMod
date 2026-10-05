-- FPV Camera & Video Feed Configuration
-- FPV Kamikaze Drone: Acro (рябь / помехи) <-> Non-Acro (чистая картинка без помех)

local Config = {}

-- Key bindings:
-- Toggle between Acro (картинка рябит / помехи) and Non-Acro (чистая картинка без помех):
Config.ToggleKey = Key.V
Config.AltToggleKey = Key.C

-- Default mode on spawn:
-- "ACRO" = стандартный режим (картинка с помехами/рябью FPV)
-- "NON_ACRO" = чистая картинка без помех сразу со старта
Config.DefaultMode = "ACRO"

-- Visual interference / noise filter:
-- Toggles the CRT/VCR postprocess noise and scanlines off in Non-Acro mode
Config.ToggleNoise = true

-- Optional flight horizon self-leveling assistance in Non-Acro mode:
-- true = также помогает удерживать горизонт, false = меняет только картинку (только рябь)
Config.AlsoStabilizeFlight = false
Config.StabilizerStrength = 4.0
Config.Damping = 0.35

-- On-screen HUD notification when switching modes:
Config.ShowOnScreenMessage = true

return Config
