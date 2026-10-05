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
    IsTransitioning = false,
    CachedPlayerController = nil,
    CachedPawn = nil,
    LastNotificationTime = 0
}

local function Log(msg)
    print(string.format("[FPVCameraMod] %s\n", msg))
end

-- Safely retrieve active PlayerController without spamming FindAllOf
local function GetActivePlayerController()
    if State.CachedPlayerController and State.CachedPlayerController:IsValid() then
        return State.CachedPlayerController
    end
    local ok, pc = pcall(function() return UEHelpers.GetPlayerController() end)
    if ok and pc and pc:IsValid() then
        State.CachedPlayerController = pc
        return pc
    end
    return nil
end

-- Safely retrieve active Pawn
local function GetActivePawn()
    if State.CachedPawn and State.CachedPawn:IsValid() then
        return State.CachedPawn
    end
    local pc = GetActivePlayerController()
    if pc and pc:IsValid() then
        if pc.Pawn and pc.Pawn:IsValid() then
            State.CachedPawn = pc.Pawn
            return pc.Pawn
        elseif pc.AcknowledgedPawn and pc.AcknowledgedPawn:IsValid() then
            State.CachedPawn = pc.AcknowledgedPawn
            return pc.AcknowledgedPawn
        end
    end
    return nil
end

-- Cached CameraComponent class reference
local CameraClassRef = nil
local function GetCameraClass()
    if not CameraClassRef or not CameraClassRef:IsValid() then
        pcall(function()
            CameraClassRef = StaticFindObject("/Script/Engine.CameraComponent")
        end)
    end
    return CameraClassRef
end

--- Apply FOV to all relevant camera components and managers
local function ApplyCameraFOV(NewFOV)
    local PlayerController = GetActivePlayerController()
    if not PlayerController or not PlayerController:IsValid() then
        return false
    end

    local applied = false

    -- 1. Update PlayerCameraManager
    pcall(function()
        local CameraManager = PlayerController.PlayerCameraManager
        if CameraManager and CameraManager:IsValid() then
            CameraManager.DefaultFOV = NewFOV
            CameraManager.LockedFOV = NewFOV
            if CameraManager.SetFOV then
                CameraManager:SetFOV(NewFOV)
            end
            applied = true
        end
    end)

    -- 2. Call PlayerController FOV command if available
    pcall(function()
        if PlayerController.FOV then
            PlayerController:FOV(NewFOV)
            applied = true
        end
    end)

    -- 3. Update CameraComponents on the drone pawn
    local TargetActor = GetActivePawn()
    if TargetActor and TargetActor:IsValid() then
        -- Direct CameraComponent property
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

        -- Iterate components via UE4SS TArray :ForEach (never ipairs!)
        pcall(function()
            local CamClass = GetCameraClass()
            if CamClass and CamClass:IsValid() and TargetActor.K2_GetComponentsByClass then
                local comps = TargetActor:K2_GetComponentsByClass(CamClass)
                if comps and comps:IsValid() and comps.ForEach then
                    comps:ForEach(function(index, comp)
                        if comp and comp:IsValid() then
                            if State.InitialDroneFOV == nil and comp.FieldOfView then
                                State.InitialDroneFOV = comp.FieldOfView
                            end
                            comp.FieldOfView = NewFOV
                            if comp.SetFieldOfView then
                                comp:SetFieldOfView(NewFOV)
                            end
                            applied = true
                        end
                    end)
                end
            end
        end)
    end

    return applied
end

--- Send on-screen HUD notification to the player
local function NotifyPlayer(msg)
    Log(msg)
    if not Config.ShowOnScreenMessage then return end

    ExecuteInGameThread(function()
        local PC = GetActivePlayerController()
        if PC and PC:IsValid() then
            pcall(function()
                if PC.ClientMessage then
                    PC:ClientMessage(msg)
                end
            end)
        end
    end)
end

--- Start transition if smooth transition is enabled, or apply immediately
local function StartTransition()
    if not Config.SmoothTransition then
        State.CurrentFOV = State.TargetFOV
        ExecuteInGameThread(function()
            ApplyCameraFOV(State.TargetFOV)
        end)
        return
    end

    if State.IsTransitioning then
        -- Already running transition loop, it will pick up the new TargetFOV
        return
    end

    State.IsTransitioning = true

    -- Finite LoopAsync: only runs during active camera movement and shuts down when done!
    LoopAsync(20, function()
        if not State.IsTransitioning then
            return true -- Stop loop
        end

        local shouldStop = false
        ExecuteInGameThread(function()
            local diff = State.TargetFOV - State.CurrentFOV
            if math.abs(diff) > 0.5 then
                local step = diff * math.min(1.0, Config.TransitionSpeed * 0.020)
                if math.abs(step) < 0.25 then
                    step = (diff > 0) and 0.25 or -0.25
                end
                State.CurrentFOV = State.CurrentFOV + step
                ApplyCameraFOV(State.CurrentFOV)
            else
                State.CurrentFOV = State.TargetFOV
                ApplyCameraFOV(State.TargetFOV)
                State.IsTransitioning = false
                shouldStop = true
            end
        end)

        return shouldStop
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
        State.TargetFOV = State.InitialDroneFOV or Config.MacroFOV
        NotifyPlayer(string.format("[FPV Camera] Mode: MACRO (Zoom / Strike: %.0f deg)", State.TargetFOV))
    end

    StartTransition()
end

--- Adjust FOV up or down dynamically
local function AdjustFOV(delta)
    State.TargetFOV = math.max(Config.MinFOV, math.min(Config.MaxFOV, State.TargetFOV + delta))
    NotifyPlayer(string.format("[FPV Camera] FOV: %.0f deg (%s)", State.TargetFOV, State.CurrentMode))
    StartTransition()
end

-- Keybind registrations
local function BindKey(key, callback)
    if not key then return end
    pcall(function()
        RegisterKeyBind(key, {}, callback)
    end)
end

BindKey(Config.ToggleKey, ToggleCameraMode)
BindKey(Config.AltToggleKey, ToggleCameraMode)
BindKey(Config.FovIncreaseKey, function() AdjustFOV(Config.FovStep) end)
BindKey(Config.FovDecreaseKey, function() AdjustFOV(-Config.FovStep) end)
BindKey(Config.AltFovIncreaseKey, function() AdjustFOV(Config.FovStep) end)
BindKey(Config.AltFovDecreaseKey, function() AdjustFOV(-Config.FovStep) end)

-- Hook PlayerController:ClientRestart to track when player takes control of a drone
pcall(function()
    RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)
        local pc = self:get()
        if pc and pc:IsValid() then
            State.CachedPlayerController = pc
            if NewPawn and NewPawn:IsValid() then
                State.CachedPawn = NewPawn:get()
            elseif pc.Pawn and pc.Pawn:IsValid() then
                State.CachedPawn = pc.Pawn
            end
            Log(string.format("PlayerController restarted with Pawn: %s",
                State.CachedPawn and State.CachedPawn:GetFullName() or "none"))
        end
    end)
end)

print("[FPVCameraMod] FPV Camera Switcher Mod loaded successfully! Press 'V' or 'C' in flight to toggle Macro / Non-Macro.\n")
