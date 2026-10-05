-- FPV Kamikaze Drone - Flight Mode Switcher (Acro <-> Non-Acro / Stabilized)
-- Allows players to switch between:
-- 1. ACRO MODE: Full manual rate mode (default FPV, no self-leveling).
-- 2. NON-ACRO MODE: Angle / Stabilized mode (automatic horizon self-leveling).

local UEHelpers = require("UEHelpers")
local Config = require("config")

print("[FPVFlightMode] Initializing Acro / Non-Acro Flight Mode Switcher...\n")

local State = {
    CurrentMode = Config.DefaultMode or "ACRO", -- "ACRO" or "NON_ACRO"
    CachedPlayerController = nil,
    CachedPawn = nil,
    CachedPhysComp = nil,
    NativeCandidates = {},
    IsLoopRunning = false,
    LastNotificationTime = 0
}

local function Log(msg)
    print(string.format("[FPVFlightMode] %s\n", msg))
end

-- Safely find the simulated physics component on the drone
local function FindDronePhysicsComponent(Pawn)
    if not Pawn or not Pawn:IsValid() then return nil end

    -- 1. Check RootComponent
    pcall(function()
        if Pawn.RootComponent and Pawn.RootComponent:IsValid() then
            local root = Pawn.RootComponent
            if root.IsSimulatingPhysics and root:IsSimulatingPhysics() then
                return root
            end
        end
    end)

    -- 2. Check Mesh
    pcall(function()
        if Pawn.Mesh and Pawn.Mesh:IsValid() then
            local mesh = Pawn.Mesh
            if mesh.IsSimulatingPhysics and mesh:IsSimulatingPhysics() then
                return mesh
            end
        end
    end)

    -- 3. Fallback: check any PrimitiveComponent on Pawn
    local PrimitiveClass = StaticFindObject("/Script/Engine.PrimitiveComponent")
    if PrimitiveClass and PrimitiveClass:IsValid() and Pawn.K2_GetComponentsByClass then
        local comps = Pawn:K2_GetComponentsByClass(PrimitiveClass)
        if comps and comps:IsValid() and comps.ForEach then
            local found = nil
            comps:ForEach(function(index, comp)
                if not found and comp and comp:IsValid() and comp.IsSimulatingPhysics and comp:IsSimulatingPhysics() then
                    found = comp
                end
            end)
            if found then return found end
        end
    end

    return Pawn.RootComponent
end

-- Scan Pawn and Components for native stabilization / flight mode variables
local function ScanForNativeFlightMode(Pawn)
    if not Pawn or not Pawn:IsValid() then return {} end

    local candidates = {}

    -- Scan Pawn properties
    pcall(function()
        local class = Pawn:GetClass()
        while class and class:IsValid() do
            class:ForEachProperty(function(prop)
                local name = prop:GetFName():ToString():lower()
                if name:find("stabiliz") or name:find("acro") or name:find("angle") or name:find("flightmode") then
                    Log(string.format("Discovered native Pawn property: %s", prop:GetFName():ToString()))
                    table.insert(candidates, { Object = Pawn, PropertyName = prop:GetFName():ToString() })
                end
            end)
            class = class:GetSuperClass()
        end
    end)

    -- Scan components (e.g. BP_IMUComponent)
    pcall(function()
        local ActorComponentClass = StaticFindObject("/Script/Engine.ActorComponent")
        if ActorComponentClass and ActorComponentClass:IsValid() and Pawn.K2_GetComponentsByClass then
            local comps = Pawn:K2_GetComponentsByClass(ActorComponentClass)
            if comps and comps:IsValid() and comps.ForEach then
                comps:ForEach(function(idx, comp)
                    if comp and comp:IsValid() then
                        local cClass = comp:GetClass()
                        local cName = cClass:GetFName():ToString()
                        while cClass and cClass:IsValid() do
                            cClass:ForEachProperty(function(prop)
                                local name = prop:GetFName():ToString():lower()
                                if name:find("stabiliz") or name:find("acro") or name:find("angle") or name:find("flightmode") then
                                    Log(string.format("Discovered component property: %s.%s", cName, prop:GetFName():ToString()))
                                    table.insert(candidates, { Object = comp, ComponentName = cName, PropertyName = prop:GetFName():ToString() })
                                end
                            end)
                            cClass = cClass:GetSuperClass()
                        end
                    end
                end)
            end
        end
    end)

    return candidates
end

-- Apply flight mode to native properties if available
local function ApplyNativeMode(IsNonAcro)
    for _, candidate in ipairs(State.NativeCandidates) do
        pcall(function()
            if candidate.Object and candidate.Object:IsValid() then
                local propName = candidate.PropertyName
                local lowerName = propName:lower()
                if lowerName:find("acro") then
                    candidate.Object[propName] = not IsNonAcro
                else
                    candidate.Object[propName] = IsNonAcro
                end
                Log(string.format("Applied native property %s = %s", propName, tostring(candidate.Object[propName])))
            end
        end)
    end
end

-- Horizon stabilization step (Non-Acro / Angle Mode)
local function StepStabilizer()
    if State.CurrentMode ~= "NON_ACRO" then
        return
    end

    local Pawn = State.CachedPawn
    if not Pawn or not Pawn:IsValid() then
        return
    end

    local PhysComp = State.CachedPhysComp
    if not PhysComp or not PhysComp:IsValid() then
        State.CachedPhysComp = FindDronePhysicsComponent(Pawn)
        PhysComp = State.CachedPhysComp
        if not PhysComp or not PhysComp:IsValid() then
            return
        end
    end

    pcall(function()
        local Rot = Pawn:K2_GetActorRotation()
        if not Rot then return end

        local roll = Rot.Roll
        local pitch = Rot.Pitch

        -- Wrap angles to -180 .. +180
        if roll > 180.0 then roll = roll - 360.0 end
        if roll < -180.0 then roll = roll + 360.0 end
        if pitch > 180.0 then pitch = pitch - 360.0 end
        if pitch < -180.0 then pitch = pitch + 360.0 end

        -- Target angular velocities to return to level (0 Roll, 0 Pitch)
        local targetRollRate = -roll * Config.StabilizerStrength
        local targetPitchRate = -pitch * Config.StabilizerStrength

        -- Clamp max corrective angular rate (degrees/sec)
        local maxRate = 220.0
        targetRollRate = math.max(-maxRate, math.min(maxRate, targetRollRate))
        targetPitchRate = math.max(-maxRate, math.min(maxRate, targetPitchRate))

        if PhysComp.GetPhysicsAngularVelocityInDegrees and PhysComp.SetPhysicsAngularVelocityInDegrees then
            local currAngVel = PhysComp:GetPhysicsAngularVelocityInDegrees()
            if currAngVel then
                local alpha = Config.Damping or 0.35
                local newRollVel = currAngVel.X + (targetRollRate - currAngVel.X) * alpha
                local newPitchVel = currAngVel.Y + (targetPitchRate - currAngVel.Y) * alpha

                PhysComp:SetPhysicsAngularVelocityInDegrees(
                    { X = newRollVel, Y = newPitchVel, Z = currAngVel.Z },
                    false,
                    "None"
                )
            end
        end
    end)
end

-- Start or stop the active stabilizer loop
local function EnsureStabilizerLoop()
    if State.CurrentMode == "NON_ACRO" and not State.IsLoopRunning then
        State.IsLoopRunning = true
        LoopAsync(20, function()
            if State.CurrentMode ~= "NON_ACRO" then
                State.IsLoopRunning = false
                return true -- Stop loop
            end

            ExecuteInGameThread(function()
                StepStabilizer()
            end)

            return false -- Keep looping while in NON_ACRO
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

--- Toggle between Acro and Non-Acro modes
local function ToggleFlightMode()
    if State.CurrentMode == "ACRO" then
        State.CurrentMode = "NON_ACRO"
        ApplyNativeMode(true)
        EnsureStabilizerLoop()
        NotifyPlayer("[FLIGHT MODE] >> NON-ACRO << (Angle / Stabilized Horizon)")
    else
        State.CurrentMode = "ACRO"
        ApplyNativeMode(false)
        -- Loop will self-terminate on next tick
        NotifyPlayer("[FLIGHT MODE] >> ACRO << (Full Manual / Rate Mode)")
    end
end

-- Keybind registrations
local function BindKey(key, callback)
    if not key then return end
    pcall(function()
        RegisterKeyBind(key, {}, callback)
    end)
end

BindKey(Config.ToggleKey, ToggleFlightMode)
BindKey(Config.AltToggleKey, ToggleFlightMode)

-- Hook PlayerController:ClientRestart to track when player possesses the drone
pcall(function()
    RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)
        local pc = self:get()
        if pc and pc:IsValid() then
            State.CachedPlayerController = pc
            local pawn = NewPawn and NewPawn:IsValid() and NewPawn:get() or pc.Pawn
            if pawn and pawn:IsValid() then
                State.CachedPawn = pawn
                State.CachedPhysComp = FindDronePhysicsComponent(pawn)
                State.NativeCandidates = ScanForNativeFlightMode(pawn)
                Log(string.format("Drone pawn initialized: %s (PhysComp: %s)",
                    pawn:GetFullName(),
                    State.CachedPhysComp and State.CachedPhysComp:GetFullName() or "none"))

                -- Apply current mode to new pawn
                if State.CurrentMode == "NON_ACRO" then
                    ApplyNativeMode(true)
                    EnsureStabilizerLoop()
                else
                    ApplyNativeMode(false)
                end
            end
        end
    end)
end)

print("[FPVFlightMode] Mod loaded! Press 'V' or 'C' in flight to switch between ACRO and NON-ACRO.\n")
