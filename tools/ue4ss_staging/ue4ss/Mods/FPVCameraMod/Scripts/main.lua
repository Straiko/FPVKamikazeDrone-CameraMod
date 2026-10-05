-- FPV Kamikaze Drone - Camera Switcher Mod (Macro <-> Non-Macro)
-- Allows players to switch between the default zoomed "Macro" view
-- and a wide-angle "Non-Macro" FPV camera in flight.

local UEHelpers = require("UEHelpers")
local Config = require("config")

print("[FPVCameraMod] Initializing FPV Camera Switcher Mod...\n")

local State = {
    CurrentMode = "MACRO", -- "MACRO" or "NON_MACRO"
    TargetFOV = Config.MacroFOV,
    CurrentFOV = Config.MacroFOV,
    InitialDroneFOV = nil,
    IsActive = false,
    LastNotificationTime = 0
}

local function Log(msg)
    print(string.format("[FPVCameraMod] %s\n", msg))
end

--- Apply FOV to all relevant camera components and managers
local function ApplyCameraFOV(NewFOV)
    local PlayerController = UEHelpers.GetPlayerController()
    if not PlayerController or not PlayerController:IsValid() then
        return false
    end

    local applied = false

    -- 1. Update PlayerCameraManager
    local CameraManager = PlayerController.PlayerCameraManager
    if CameraManager and CameraManager:IsValid() then
        -- Set default and locked FOV
        pcall(function()
            CameraManager.DefaultFOV = NewFOV
            CameraManager.LockedFOV = NewFOV
            if CameraManager.SetFOV then
                CameraManager:SetFOV(NewFOV)
            end
            applied = true
        end)
    end

    -- 2. Find controlled drone pawn or view target
    local TargetActor = nil
    if PlayerController.Pawn and PlayerController.Pawn:IsValid() then
        TargetActor = PlayerController.Pawn
    elseif PlayerController.AcknowledgedPawn and PlayerController.AcknowledgedPawn:IsValid() then
        TargetActor = PlayerController.AcknowledgedPawn
    else
        pcall(function()
            if PlayerController.GetViewTarget then
                TargetActor = PlayerController:GetViewTarget()
            end
        end)
    end

    -- 3. Update CameraComponents on the drone pawn
    if TargetActor and TargetActor:IsValid() then
        -- Check direct CameraComponent property if present
        pcall(function()
            if TargetActor.CameraComponent and TargetActor.CameraComponent:IsValid() then
                if State.InitialDroneFOV == nil and TargetActor.CameraComponent.FieldOfView then
                    State.InitialDroneFOV = TargetActor.CameraComponent.FieldOfView
                end
                TargetActor.CameraComponent.FieldOfView = NewFOV
                if TargetActor.CameraComponent.SetFieldOfView then
                    TargetActor.CameraComponent:SetFieldOfView(NewFOV)
                end
                applied = true
            end
        end)

        -- Iterate components on TargetActor
        pcall(function()
            if TargetActor.K2_GetComponentsByClass then
                local CameraClass = StaticFindObject("/Script/Engine.CameraComponent")
                if CameraClass and CameraClass:IsValid() then
                    local CameraComponents = TargetActor:K2_GetComponentsByClass(CameraClass)
                    if CameraComponents then
                        for _, CamComp in ipairs(CameraComponents) do
                            if CamComp:IsValid() then
                                if State.InitialDroneFOV == nil and CamComp.FieldOfView then
                                    State.InitialDroneFOV = CamComp.FieldOfView
                                end
                                CamComp.FieldOfView = NewFOV
                                if CamComp.SetFieldOfView then
                                    CamComp:SetFieldOfView(NewFOV)
                                end
                                applied = true
                            end
                        end
                    end
                end
            end
        end)
    end

    return applied
end

--- Send on-screen HUD notification to the player
local function NotifyPlayer(msg)
    Log(msg)
    ExecuteInGameThread(function()
        local PlayerController = UEHelpers.GetPlayerController()
        if PlayerController and PlayerController:IsValid() then
            pcall(function()
                if PlayerController.ClientMessage then
                    PlayerController:ClientMessage(msg, "None", 3.0)
                end
            end)
        end
    end)
end

--- Toggle between Macro (Zoomed) and Non-Macro (Wide FPV)
local function ToggleCameraMode()
    if State.CurrentMode == "MACRO" then
        State.CurrentMode = "NON_MACRO"
        State.TargetFOV = Config.NonMacroFOV
        NotifyPlayer(string.format("[FPV Camera] Mode: NON-MACRO (Wide FPV: %.0f deg)", State.TargetFOV))
    else
        State.CurrentMode = "MACRO"
        -- Use captured initial FOV if available, or configured Macro FOV
        State.TargetFOV = State.InitialDroneFOV or Config.MacroFOV
        NotifyPlayer(string.format("[FPV Camera] Mode: MACRO (Zoom / Strike: %.0f deg)", State.TargetFOV))
    end

    if not Config.SmoothTransition then
        State.CurrentFOV = State.TargetFOV
        ExecuteInGameThread(function()
            ApplyCameraFOV(State.TargetFOV)
        end)
    end
end

--- Adjust FOV up or down dynamically
local function AdjustFOV(delta)
    State.TargetFOV = math.max(Config.MinFOV, math.min(Config.MaxFOV, State.TargetFOV + delta))
    NotifyPlayer(string.format("[FPV Camera] FOV: %.0f deg (%s)", State.TargetFOV, State.CurrentMode))
    if not Config.SmoothTransition then
        State.CurrentFOV = State.TargetFOV
        ExecuteInGameThread(function()
            ApplyCameraFOV(State.TargetFOV)
        end)
    end
end

-- Keybind registrations
if Config.ToggleKey then
    RegisterKeyBind(Config.ToggleKey, {}, function()
        ToggleCameraMode()
    end)
end

if Config.AltToggleKey and Config.AltToggleKey ~= Config.ToggleKey then
    RegisterKeyBind(Config.AltToggleKey, {}, function()
        ToggleCameraMode()
    end)
end

if Config.FovIncreaseKey then
    RegisterKeyBind(Config.FovIncreaseKey, {}, function()
        AdjustFOV(Config.FovStep)
    end)
end

if Config.FovDecreaseKey then
    RegisterKeyBind(Config.FovDecreaseKey, {}, function()
        AdjustFOV(-Config.FovStep)
    end)
end

-- Persistent update loop (runs ~60 times per second)
-- Handles smooth transition and maintains the requested FOV even if the game tries to reset it
LoopAsync(16, function()
    ExecuteInGameThread(function()
        local PlayerController = UEHelpers.GetPlayerController()
        if not PlayerController or not PlayerController:IsValid() then
            return
        end

        -- Smooth interpolation
        if Config.SmoothTransition then
            local diff = State.TargetFOV - State.CurrentFOV
            if math.abs(diff) > 0.05 then
                State.CurrentFOV = State.CurrentFOV + diff * math.min(1.0, Config.TransitionSpeed * 0.016)
                ApplyCameraFOV(State.CurrentFOV)
            else
                State.CurrentFOV = State.TargetFOV
                ApplyCameraFOV(State.TargetFOV)
            end
        else
            ApplyCameraFOV(State.TargetFOV)
        end
    end)
    return false -- keep looping
end)

print("[FPVCameraMod] FPV Camera Switcher Mod loaded successfully! Press 'V' or 'C' in flight to toggle Macro / Non-Macro.\n")
