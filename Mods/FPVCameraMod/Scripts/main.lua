-- FPV Kamikaze Drone - Visual & Camera Mode Switcher
-- Переключение между:
-- 1. "АКРО" (Картинка рябит): аналоговый FPV с помехами, рябью и CRT/VCR эффектами.
-- 2. "НЕ-АКРО" (Обычная чистая картинка без помех): кристально чистый цифровой вид.

local UEHelpers = require("UEHelpers")
local Config = require("config")

print("[FPVCameraMod] Initializing Acro (Noise/Ripples) <-> Non-Acro (Clean) Switcher...\n")

local State = {
    CurrentMode = Config.DefaultMode or "ACRO", -- "ACRO" or "NON_ACRO"
    CachedPlayerController = nil,
    CachedPawn = nil,
    CachedCameraComponent = nil,
    SavedRetainerMaterials = {},
    LastAppliedMode = nil
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

-- Safely get active Drone/Spectator Pawn
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

-- Safely execute a console command through all available engines/controllers
local function ExecuteConsole(cmd)
    local executed = false

    -- Method 1: PlayerController:ConsoleCommand
    pcall(function()
        local pc = GetPlayerController()
        if pc and pc:IsValid() and pc.ConsoleCommand then
            pc:ConsoleCommand(cmd, true)
            executed = true
        end
    end)

    -- Method 2: KismetSystemLibrary:ExecuteConsoleCommand
    pcall(function()
        local KSL = UEHelpers.GetKismetSystemLibrary()
        local world = UEHelpers.GetWorld()
        if KSL and KSL:IsValid() and world and world:IsValid() then
            KSL:ExecuteConsoleCommand(world, cmd, nil)
            executed = true
        end
    end)

    -- Method 3: Global ExecuteConsoleCommand if provided by UE4SS
    pcall(function()
        if ExecuteConsoleCommand then
            ExecuteConsoleCommand(cmd)
            executed = true
        end
    end)

    return executed
end

-- Refresh camera component reference
local function RefreshCameraComponent()
    local pawn = GetPawn()
    State.CachedCameraComponent = nil
    if not pawn or not pawn:IsValid() then return nil end

    pcall(function()
        if pawn.CameraComponent and pawn.CameraComponent:IsValid() then
            State.CachedCameraComponent = pawn.CameraComponent
        elseif pawn.Camera and pawn.Camera:IsValid() then
            State.CachedCameraComponent = pawn.Camera
        end
    end)

    if not State.CachedCameraComponent then
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
    end

    return State.CachedCameraComponent
end

-- Parameter names commonly used in Cem Tezcan's CRT/VCR postprocess materials
local CRT_PARAM_NAMES = {
    "Master", "MasterToggle", "Enable", "Intensity", "Weight", "Noise", "NoiseIntensity",
    "Static", "Interference", "Scanline", "ScanlineIntensity", "Distortion", "Curvature",
    "Glitch", "GlitchIntensity", "VHS", "TapeNoise", "Artifacts", "Flicker", "Jitter",
    "HorizontalHold", "VerticalHold", "Grain", "Tracking", "Phosphor", "Bleed", "ChromaticAberration"
}

-- Apply or remove noise, scanlines, and CRT distortion across all rendering channels
local function ApplyNoiseState(enableNoise, isManualToggle)
    local targetWeight = enableNoise and 1.0 or 0.0
    local cam = RefreshCameraComponent()

    local stats = {
        console = false,
        camera = false,
        volumes = 0,
        ppComps = 0,
        retainerBoxes = 0,
        midCount = 0,
        widgets = 0
    }

    -- 1. Unreal Engine Rendering Console Variables (Complete material-level bypass)
    if not enableNoise then
        stats.console = ExecuteConsole("r.PostProcessing.DisableMaterials 1")
        ExecuteConsole("show PostProcessMaterials 0")
        ExecuteConsole("r.FilmGrain 0")
        ExecuteConsole("r.SceneColorFringeQuality 0")
    else
        stats.console = ExecuteConsole("r.PostProcessing.DisableMaterials 0")
        ExecuteConsole("show PostProcessMaterials 1")
        ExecuteConsole("r.FilmGrain 1")
        ExecuteConsole("r.SceneColorFringeQuality 1")
    end

    -- 2. Pawn Camera Component PostProcess Settings
    if cam and cam:IsValid() then
        pcall(function()
            cam.PostProcessBlendWeight = targetWeight
            if cam.PostProcessSettings then
                cam.PostProcessSettings.bOverride_WeightedBlendables = enableNoise
                if not enableNoise then
                    cam.PostProcessSettings.bOverride_FilmGrainIntensity = true
                    cam.PostProcessSettings.FilmGrainIntensity = 0.0
                    cam.PostProcessSettings.bOverride_SceneFringeIntensity = true
                    cam.PostProcessSettings.SceneFringeIntensity = 0.0
                    cam.PostProcessSettings.bOverride_VignetteIntensity = true
                    cam.PostProcessSettings.VignetteIntensity = 0.0
                else
                    cam.PostProcessSettings.bOverride_FilmGrainIntensity = false
                    cam.PostProcessSettings.bOverride_SceneFringeIntensity = false
                    cam.PostProcessSettings.bOverride_VignetteIntensity = false
                end
            end
            stats.camera = true
        end)
    end

    -- 3. PlayerCameraManager PostProcess Settings
    local pc = GetPlayerController()
    if pc and pc:IsValid() then
        pcall(function()
            local mgr = pc.PlayerCameraManager
            if mgr and mgr:IsValid() and mgr.PostProcessSettings then
                mgr.PostProcessSettings.bOverride_WeightedBlendables = enableNoise
            end
        end)
    end

    -- 4. PostProcessVolumes across the map
    pcall(function()
        local volumes = FindAllOf("PostProcessVolume")
        if volumes then
            for _, vol in ipairs(volumes) do
                if vol and vol:IsValid() then
                    vol.bEnabled = enableNoise
                    vol.BlendWeight = targetWeight
                    if vol.Settings then
                        vol.Settings.bOverride_WeightedBlendables = enableNoise
                    end
                    stats.volumes = stats.volumes + 1
                end
            end
        end
    end)

    -- 5. PostProcessComponents (e.g. on pawn or world actors)
    pcall(function()
        local comps = FindAllOf("PostProcessComponent")
        if comps then
            for _, comp in ipairs(comps) do
                if comp and comp:IsValid() then
                    comp.bEnabled = enableNoise
                    comp.BlendWeight = targetWeight
                    if comp.Settings then
                        comp.Settings.bOverride_WeightedBlendables = enableNoise
                    end
                    stats.ppComps = stats.ppComps + 1
                end
            end
        end
    end)

    -- 6. UMG RetainerBoxes (HUD / UI shader filters)
    pcall(function()
        local boxes = FindAllOf("RetainerBox")
        if boxes then
            for _, box in ipairs(boxes) do
                if box and box:IsValid() then
                    if not enableNoise then
                        local mat = box.EffectMaterial
                        if mat and mat:IsValid() then
                            local name = mat:GetFullName()
                            if string.find(name, "CRT") or string.find(name, "pp") or string.find(name, "Preset") or string.find(name, "Noise") or string.find(name, "VCR") then
                                State.SavedRetainerMaterials[box] = mat
                                box:SetEffectMaterial(nil)
                                stats.retainerBoxes = stats.retainerBoxes + 1
                            end
                        end
                    else
                        local saved = State.SavedRetainerMaterials[box]
                        if saved and saved:IsValid() then
                            box:SetEffectMaterial(saved)
                            stats.retainerBoxes = stats.retainerBoxes + 1
                        end
                    end
                end
            end
        end
    end)

    -- 7. MaterialInstanceDynamics matching CRT/VCR/Noise presets
    pcall(function()
        local mids = FindAllOf("MaterialInstanceDynamic")
        if mids then
            for _, mid in ipairs(mids) do
                if mid and mid:IsValid() then
                    local name = mid:GetFullName()
                    if string.find(name, "CRT") or string.find(name, "VCR") or string.find(name, "PP_Preset") or string.find(name, "00_animated") then
                        for _, param in ipairs(CRT_PARAM_NAMES) do
                            pcall(function()
                                mid:SetScalarParameterValue(FName(param), targetWeight)
                            end)
                        end
                        stats.midCount = stats.midCount + 1
                    end
                end
            end
        end
    end)

    -- 8. UI Widgets with static/noise image layers
    pcall(function()
        local widgets = FindAllOf("UserWidget")
        if widgets then
            local noiseProps = {"Noise", "Static", "Interference", "CRT", "VCR", "NoiseImage", "StaticImage", "Img_Noise", "OverlayNoise"}
            for _, w in ipairs(widgets) do
                if w and w:IsValid() then
                    for _, prop in ipairs(noiseProps) do
                        pcall(function()
                            local elem = w[prop]
                            if elem and elem:IsValid() and elem.SetRenderOpacity then
                                elem:SetRenderOpacity(targetWeight)
                                stats.widgets = stats.widgets + 1
                            end
                        end)
                    end
                end
            end
        end
    end)

    State.LastAppliedMode = enableNoise and "ACRO" or "NON_ACRO"

    if isManualToggle then
        Log(string.format("Applied [%s] (Noise=%s, Weight=%.1f) -> CVar: %s, Cam: %s, Volumes: %d, PPComps: %d, Retainers: %d, MIDs: %d, Widgets: %d",
            State.LastAppliedMode, tostring(enableNoise), targetWeight,
            tostring(stats.console), tostring(stats.camera), stats.volumes, stats.ppComps, stats.retainerBoxes, stats.midCount, stats.widgets))
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
            ApplyNoiseState(false, true)
        end)
        NotifyPlayer("[РЕЖИМ] >> НЕ-АКРО << (Чистая картинка без помех и ряби)")
    else
        State.CurrentMode = "ACRO"
        ExecuteInGameThread(function()
            ApplyNoiseState(true, true)
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

-- Hook PlayerController:ClientRestart to track when player possesses any pawn (drone or spectator)
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
                RefreshCameraComponent()

                -- Apply current mode after a tiny delay so pawn finish initializing
                LoopAsync(200, function()
                    ExecuteInGameThread(function()
                        ApplyNoiseState(State.CurrentMode == "ACRO", false)
                    end)
                    return true -- Run once
                end)
            end
        end
    end)
end)

-- Gentle maintenance check every 2.0s (silent, no spam): ensures clean picture stays clean
LoopAsync(2000, function()
    if State.CurrentMode == "NON_ACRO" then
        ExecuteInGameThread(function()
            ApplyNoiseState(false, false)
        end)
    end
    return false -- Keep periodic check
end)

print("[FPVCameraMod] Mod loaded! Press 'V' or 'C' in flight to toggle between Acro (рябь) and Non-Acro (чистая картинка).\n")
