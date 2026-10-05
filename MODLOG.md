# FPV Kamikaze Drone - Flight Mode Mod (Acro <-> Non-Acro / Stabilized) - MODLOG

## Project Overview
- **Game:** FPV Kamikaze Drone (Steam AppID: 2707940, Build ID: 23452483)
- **Engine:** Unreal Engine 5.6 (Source build with IoStore / Zen format)
- **Install Path:** `~/snap/steam/common/.local/share/Steam/steamapps/common/FPVKamikazeDrone`
- **Mod Directory:** `/home/root2506/FPVKamikazeDrone-CameraMod`
- **Save / Config Path:** `~/snap/steam/common/.local/share/Steam/steamapps/compatdata/2707940/pfx/drive_c/users/steamuser/AppData/Local/FPVKamikazeDrone/Saved/Config/Windows`
- **Backup File:** `/home/root2506/.universal-modder/backups/fpvkamikazedrone-saves/20261005-230303.zip` (15 files, 0.5 MB)
- **Goal:** Mod allowing the player to toggle/switch flight mode between **Acro** (full manual rate mode, standard combat FPV without self-leveling) and **Non-Acro** (Angle / Stabilized mode with automatic horizon self-leveling to keep the drone level and prevent flipping).


## Recon & Architecture
- **Engine Details:** Unreal Engine 5.6 (Windows x64 via Proton / Steam).
- **Anti-Cheat:** None found.
- **Paks / Assets:** Assets packed into IoStore (`FPVKamikazeDrone-Windows.ucas`, `FPVKamikazeDrone-Windows.utoc`) with Oodle compression.
- **Drone Classes:**
  - `BP_Kamikaze_C` (Drone pawn for kamikaze strikes)
  - `BP_Drone_FPV_C`
  - Input Actions: `IA_FOV_Narrow`, `IA_FOV_Wider`, `IA_ToggleView`, `IA_Cam_Tilt`
- **Mod Route Candidates:**
  1. **UE4SS Lua Mod (Recommended):**
     - Inject via `dwmapi.dll` / `xinput1_3.dll` into the game directory.
     - Intercept or bind a hotkey (e.g., 'V', 'C', 'Middle Mouse' or custom).
     - Hook active camera component / controller on `BP_Kamikaze_C`.
     - Smoothly or instantly toggle Field of View (FOV) and post-process / camera boom between Wide (e.g. 110-120°) and Macro (e.g. 35-50° zoom), and optionally custom focal distance.
  2. **Input Mapping / Config Mod (if natively supported by unbound game actions):**
     - Map `IA_FOV_Narrow` / `IA_FOV_Wider` in User Input Config if exposed in GameUserSettings/EnhancedInput configs.

## Implementation & Installation
- **Loader:** RE-UE4SS v3.0.1 (Experimental 1152-ge3ba1016 with UE 5.6 compatibility).
- **Injection:** `dwmapi.dll` proxy placed in `FPVKamikazeDrone/Binaries/Win64/`.
- **Proton Wine Configuration:** Added `[Software\Wine\DllOverrides]` with `"dwmapi"="native,builtin"` to `user.reg`.
- **Mod Folder:** `FPVKamikazeDrone/Binaries/Win64/ue4ss/Mods/FPVCameraMod/`
  - `Scripts/config.lua`: Configurable keybindings and FOV presets.
  - `Scripts/main.lua`: Camera switcher logic, smooth interpolation, active controller/camera hook, and on-screen HUD message feedback.
  - `enabled.txt` & registered in `mods.txt`.

## Controls & Keybindings
- **Toggle Flight Mode (`V` or `C`):** Switch between:
  - **Acro Mode:** Full manual rate control (standard combat FPV flight, no auto-leveling).
  - **Non-Acro Mode:** Angle / Horizon stabilized mode (automatic self-leveling to 0° Roll & Pitch when controls are neutral).
- **Customization:** Settings can be customized in `ue4ss/Mods/FPVCameraMod/Scripts/config.lua` (`StabilizerStrength`, `Damping`, `MaxTiltAngle`).


## Safety & Process Hygiene
- Save and config backup created: `~/.universal-modder/backups/fpvkamikazedrone-saves/20261005-230303.zip`.
- Singleplayer / Offline mode prioritized.
- Exact PID hygiene enforced.

## Crash Analysis & Fixes (2026-10-05)
1. **Engine Crash (`EXCEPTION_ACCESS_VIOLATION reading address 0x0000000a4cd035d1`):**
   - **Root Cause:** `main.lua` had an infinite `LoopAsync(16)` constantly calling `ExecuteInGameThread` with `UEHelpers.GetPlayerController() -> FindAllOf("PlayerController")` starting immediately at game launch. During engine boot and GC (`FCallbackGarbageCollector`), scanning `GUObjectArray` 60 times/sec dereferenced freed memory. In addition, iterating `TArray` using `ipairs` caused out-of-bounds pointer crashes in UE4SS.
   - **Fix:** Converted `main.lua` to an event-driven architecture. Hooked `/Script/Engine.PlayerController:ClientRestart` via `RegisterHook` to cleanly capture the controller and possessed drone pawn on the game thread. Replaced `ipairs` on `TArray` with safe `:ForEach()`. Replaced infinite 60fps loop with a self-terminating, finite transition timer that only runs for ~10 frames when FOV transitions.
   - **Keybind fix:** Fixed `Key.RIGHT_BRACKET` and `Key.LEFT_BRACKET` (which do not exist in UE4SS `Key` table) to use `Key.OEM_SIX` (`]`), `Key.OEM_FOUR` (`[`), `Key.ADD`, and `Key.SUBTRACT`.

2. **GPU Crash (`GPU Crash dump Triggered`):**
   - **Root Cause:** GTX 1050 Ti (4GB Pascal GPU) running Unreal Engine 5.6 on Linux/Proton with default DX12/VKD3D. UE5 PCD3D_SM6 shaders and high memory usage trigger driver timeouts/VRAM exhaustion under VKD3D.
   - **Recommendation:** Add `-dx11` to Steam Launch Options (`WINEDLLOVERRIDES="dwmapi=n,b" %command% -dx11`). The game contains precompiled `PCD3D_SM5` shaders, which allows DXVK to run stably and at higher FPS on 4GB GPUs.


