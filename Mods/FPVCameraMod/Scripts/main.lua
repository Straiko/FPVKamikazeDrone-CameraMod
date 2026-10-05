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

-- Safely get active PlayerController
local function GetPlayerController()
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

-- Safely get active Drone Pawn
local function GetPawn()
    if State.CachedPawn and State.CachedPawn:IsValid() then
        return State.CachedPawn
    end
    local pc = GetPlayerController()
    if pc and pc:IsValid() then
        local p = pc.Pawn or pc.AcknowledgedPawn
        if p and p:IsValid() then
            State.CachedPawn = p
            return p
        end
    end
    return nil
end

-- Refresh camera and post-process component references
local function RefreshPawnComponents()
    local pawn = GetPawn()
    if not pawn or not pawn:IsValid() then return end

    State.CachedCameraComponent = nil
    State.CachedPostProcessComponents = {}

    -- Direct CameraComponent
    pcall(function()
        if pawn.CameraComponent and pawn.CameraComponent:IsValid() then
            State.CachedCameraComponent = pawn.CameraComponent
        elseif pawn.Camera and pawn.Camera:IsValid() then
            State.CachedCameraComponent = pawn.Camera
        end
    end)

    -- Scan for CameraComponent by class
    pcall(function()
        local CamClass = StaticFindObject("/Script/Engine.CameraComponent")
        if CamClass and CamClass:IsValid() and pawn.K2_GetComponentsByClass then
            local comps = pawn:K2_GetComponentsByClass(CamClass)
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
        if PPClass and PPClass:IsValid() and pawn.K2_GetComponentsByClass then
            local comps = pawn:K2_GetComponentsByClass(PPClass)
            if comps and comps:IsValid() and comps.ForEach then
                comps:ForEach(function(idx, comp)
                    if comp and comp:IsValid() then
                        table.insert(State.CachedPostProcessComponents, comp)
                    end
                end)
            end
        end
    end)

    Log(string.format("Pawn components cached: Pawn=%s, Cam=%s, PPComps=%d",
        pawn:GetFullName(),
        State.CachedCameraComponent and State.CachedCameraComponent:GetFullName() or "none",
        #State.CachedPostProcessComponents))
end

-- Apply or remove noise, scanlines, and CRT distortion
local function ApplyNoiseState(enableNoise)
    local targetWeight = enableNoise and 1.0 or 0.0

    RefreshPawnComponents()

    local camModified = false
    local ppModifiedCount = 0
    local volumeCount = 0

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
            camModified = true
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
                ppModifiedCount = ppModifiedCount + 1
            end)
        end
    end

    -- 3. PlayerCameraManager
    local pc = GetPlayerController()
    if pc and pc:IsValid() then
        pcall(function()
            local mgr = pc.PlayerCameraManager
            if mgr and mgr:IsValid() then
                if mgr.PostProcessBlendWeight then
                    mgr.PostProcessBlendWeight = targetWeight
                end
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

    -- 4. Level PostProcessVolumes (if preset is assigned to map volume)
    pcall(function()
        local volumes = FindAllOf("PostProcessVolume")
        if volumes then
            for _, vol in ipairs(volumes) do
                if vol:IsValid() and vol.Settings and vol.Settings.WeightedBlendables then
                    local arr = vol.Settings.WeightedBlendables.Array
                    if arr and arr.ForEach then
                        arr:ForEach(function(idx, elem)
                            pcall(function()
                                if elem and elem.Weight then
                                    elem.Weight = targetWeight
                                    volumeCount = volumeCount + 1
                                end
                            end)
                        end)
                    end
                end
            end
        end
    end)

    -- 5. UI Widgets (e.g. WBP_FPV_Drone static / noise overlay)
    pcall(function()
        local widgets = FindAllOf("WBP_FPV_Drone_C")
        if widgets then
            for _, w in ipairs(widgets) do
                if w:IsValid() then
                    for _, prop in ipairs({"Noise", "Static", "Interference", "CRT", "NoiseImage", "StaticImage", "Img_Noise"}) do
                        pcall(function()
                            if w[prop] and w[prop]:IsValid() and w[prop].SetRenderOpacity then
                                w[prop]:SetRenderOpacity(targetWeight)
                            end
                        end)
                    end
                end
            end
        end
    end)

    Log(string.format("Applied noise = %s (Weight: %.1f) [Cam: %s, PPComps: %d, Volumes: %d]",
        tostring(enableNoise), targetWeight, tostring(camModified), ppModifiedCount, volumeCount))
end

-- Lightweight enforcement loop: keeps clean picture active while in Non-Acro
local function EnsureNonAcroEnforcementLoop()
    if State.CurrentMode == "NON_ACRO" and not State.IsLoopRunning then
        State.IsLoopRunning = true
        LoopAsync(50, function() -- ~20 updates/sec while clean picture is active
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
        local pc = GetPlayerController()
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

            local pawn = nil
            pcall(function()
                if NewPawn then
                    pawn = NewPawn:get()
                end
            end)
            if not pawn or not pawn:IsValid() then
                pawn = pc.Pawn or pc.AcknowledgedPawn
            end

            if pawn and pawn:IsValid() then
                State.CachedPawn = pawn
                RefreshPawnComponents(pawn)

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
