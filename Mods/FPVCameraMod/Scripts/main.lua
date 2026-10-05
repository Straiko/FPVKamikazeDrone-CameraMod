-- FPV Kamikaze Drone - Visual & Camera Mode Switcher
-- Переключение между:
-- 1. "АКРО" (Картинка рябит): аналоговый FPV с помехами, рябью и CRT/VCR эффектами.
-- 2. "НЕ-АКРО" (Обычная чистая картинка без помех): кристально чистый цифровой вид.

local UEHelpers = require("UEHelpers")
local Config = require("config")

print("[FPVCameraMod] Initializing Acro (Noise) <-> Non-Acro (Clean) Switcher...\n")

local State = {
    CurrentMode = Config.DefaultMode or "ACRO", -- "ACRO" or "NON_ACRO"
    CachedPlayerController = nil,
    CachedPawn = nil,
    CachedCameraComponent = nil,
    CachedPostProcessComponents = {},
    IsLoopRunning = false,
    LastNotificationTime = 0
}

local function Log(msg)
    print(string.format("[FPVCameraMod] %s\n", msg))
end

-- Find camera components on the drone pawn
local function CachePawnComponents(Pawn)
    if not Pawn or not Pawn:IsValid() then return end

    State.CachedCameraComponent = nil
    State.CachedPostProcessComponents = {}

    -- Direct CameraComponent
    pcall(function()
        if Pawn.CameraComponent and Pawn.CameraComponent:IsValid() then
            State.CachedCameraComponent = Pawn.CameraComponent
        elseif Pawn.Camera and Pawn.Camera:IsValid() then
            State.CachedCameraComponent = Pawn.Camera
        end
    end)

    -- Scan for CameraComponent by class
    pcall(function()
        local CamClass = StaticFindObject("/Script/Engine.CameraComponent")
        if CamClass and CamClass:IsValid() and Pawn.K2_GetComponentsByClass then
            local comps = Pawn:K2_GetComponentsByClass(CamClass)
            if comps and comps:IsValid() and comps.ForEach then
                comps:ForEach(function(idx, comp)
                    if comp and comp:IsValid() and not State.CachedCameraComponent then
                        State.CachedCameraComponent = comp
                    end
                end)
            end
        end
    end)

    -- Scan for PostProcessComponent by class
    pcall(function()
        local PPClass = StaticFindObject("/Script/Engine.PostProcessComponent")
        if PPClass and PPClass:IsValid() and Pawn.K2_GetComponentsByClass then
            local comps = Pawn:K2_GetComponentsByClass(PPClass)
            if comps and comps:IsValid() and comps.ForEach then
                comps:ForEach(function(idx, comp)
                    if comp and comp:IsValid() then
                        table.insert(State.CachedPostProcessComponents, comp)
                    end
                end)
            end
        end
    end)

    Log(string.format("Cached components for %s (Camera: %s, PP Comps: %d)",
        Pawn:GetFullName(),
        State.CachedCameraComponent and State.CachedCameraComponent:GetFullName() or "none",
        #State.CachedPostProcessComponents))
end

-- Apply or remove noise, scanlines, and CRT distortion
local function ApplyNoiseState(enableNoise)
    local targetWeight = enableNoise and 1.0 or 0.0

    -- 1. CameraComponent PostProcess Settings & Blendables
    local cam = State.CachedCameraComponent
    if cam and cam:IsValid() then
        pcall(function()
            cam.PostProcessBlendWeight = targetWeight

            if cam.PostProcessSettings and cam.PostProcessSettings.WeightedBlendables then
                local arr = cam.PostProcessSettings.WeightedBlendables.Array
                if arr and arr.ForEach then
                    arr:ForEach(function(idx, elem)
                        pcall(function()
                            if elem and elem.Weight then
                                elem.Weight = targetWeight
                            end
                        end)
                    end)
                end
            end
        end)
    end

    -- 2. PostProcess Components on Pawn
    for _, ppComp in ipairs(State.CachedPostProcessComponents) do
        if ppComp and ppComp:IsValid() then
            pcall(function()
                ppComp.bEnabled = enableNoise
                ppComp.BlendWeight = targetWeight
                if ppComp.Settings and ppComp.Settings.WeightedBlendables then
                    local arr = ppComp.Settings.WeightedBlendables.Array
                    if arr and arr.ForEach then
                        arr:ForEach(function(idx, elem)
                            pcall(function()
                                if elem and elem.Weight then
                                    elem.Weight = targetWeight
                                end
                            end)
                        end)
                    end
                end
            end)
        end
    end

    -- 3. PlayerCameraManager
    local pc = State.CachedPlayerController
    if pc and pc:IsValid() then
        pcall(function()
            local mgr = pc.PlayerCameraManager
            if mgr and mgr:IsValid() then
                if mgr.PostProcessSettings and mgr.PostProcessSettings.WeightedBlendables then
                    local arr = mgr.PostProcessSettings.WeightedBlendables.Array
                    if arr and arr.ForEach then
                        arr:ForEach(function(idx, elem)
                            pcall(function()
                                if elem and elem.Weight then
                                    elem.Weight = targetWeight
                                end
                            end)
                        end)
                    end
                end
            end
        end)
    end

    -- 4. Optional flight stabilizer (if enabled in config)
    if Config.AlsoStabilizeFlight and not enableNoise then
        pcall(function()
            local pawn = State.CachedPawn
            if pawn and pawn:IsValid() and pawn.RootComponent and pawn.RootComponent:IsValid() then
                local rot = pawn:K2_GetActorRotation()
                if rot then
                    local roll = rot.Roll > 180 and (rot.Roll - 360) or rot.Roll
                    local pitch = rot.Pitch > 180 and (rot.Pitch - 360) or rot.Pitch
                    local targetRollRate = math.max(-180, math.min(180, -roll * (Config.StabilizerStrength or 4.0)))
                    local targetPitchRate = math.max(-180, math.min(180, -pitch * (Config.StabilizerStrength or 4.0)))
                    local angVel = pawn.RootComponent:GetPhysicsAngularVelocityInDegrees()
                    if angVel then
                        local alpha = Config.Damping or 0.35
                        pawn.RootComponent:SetPhysicsAngularVelocityInDegrees(
                            {
                                X = angVel.X + (targetRollRate - angVel.X) * alpha,
                                Y = angVel.Y + (targetPitchRate - angVel.Y) * alpha,
                                Z = angVel.Z
                            },
                            false,
                            "None"
                        )
                    end
                end
            end
        end)
    end
end

-- Lightweight enforcement loop: ensures the clean picture stays clean
-- even if the game tries to re-apply signal noise based on distance/battery
local function EnsureNonAcroEnforcementLoop()
    if State.CurrentMode == "NON_ACRO" and not State.IsLoopRunning then
        State.IsLoopRunning = true
        LoopAsync(33, function() -- ~30 updates per sec while in Non-Acro
            if State.CurrentMode ~= "NON_ACRO" then
                State.IsLoopRunning = false
                return true -- Stop loop
            end

            ExecuteInGameThread(function()
                ApplyNoiseState(false)
            end)

            return false
        end)
    end
end

-- Send HUD feedback to player
local function NotifyPlayer(msg)
    Log(msg)
    if not Config.ShowOnScreenMessage then return end

    ExecuteInGameThread(function()
        local pc = State.CachedPlayerController
        if not pc or not pc:IsValid() then
            local ok, newPc = pcall(function() return UEHelpers.GetPlayerController() end)
            if ok and newPc and newPc:IsValid() then
                pc = newPc
                State.CachedPlayerController = newPc
            end
        end

        if pc and pc:IsValid() then
            pcall(function()
                if pc.ClientMessage then
                    pc:ClientMessage(msg)
                end
            end)
        end
    end)
end

--- Toggle between Acro (рябь) and Non-Acro (чистая картинка)
local function ToggleMode()
    if State.CurrentMode == "ACRO" then
        State.CurrentMode = "NON_ACRO"
        ExecuteInGameThread(function()
            ApplyNoiseState(false)
        end)
        EnsureNonAcroEnforcementLoop()
        NotifyPlayer("[РЕЖИМ] >> НЕ-АКРО << (Чистая картинка без помех и ряби)")
    else
        State.CurrentMode = "ACRO"
        ExecuteInGameThread(function()
            ApplyNoiseState(true)
        end)
        NotifyPlayer("[РЕЖИМ] >> АКРО << (Аналоговый FPV / Рябь и помехи ВКЛ)")
    end
end

-- Keybind registrations
local function BindKey(key, callback)
    if not key then return end
    pcall(function()
        RegisterKeyBind(key, {}, callback)
    end)
end

BindKey(Config.ToggleKey, ToggleMode)
BindKey(Config.AltToggleKey, ToggleMode)

-- Hook PlayerController:ClientRestart to track when player possesses the drone
pcall(function()
    RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)
        local pc = self:get()
        if pc and pc:IsValid() then
            State.CachedPlayerController = pc
            local pawn = NewPawn and NewPawn:IsValid() and NewPawn:get() or pc.Pawn
            if pawn and pawn:IsValid() then
                State.CachedPawn = pawn
                CachePawnComponents(pawn)

                -- Apply current mode to new pawn
                if State.CurrentMode == "NON_ACRO" then
                    ApplyNoiseState(false)
                    EnsureNonAcroEnforcementLoop()
                else
                    ApplyNoiseState(true)
                end
            end
        end
    end)
end)

print("[FPVCameraMod] Mod loaded! Press 'V' or 'C' in flight to toggle between Acro (рябь) and Non-Acro (чистая картинка).\n")
