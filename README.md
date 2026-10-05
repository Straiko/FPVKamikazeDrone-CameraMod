# FPV Kamikaze Drone - Visual Noise & Camera Mod (Clean View / Без Помех)

[![GitHub Release](https://img.shields.io/github/v/release/Straiko/FPVKamikazeDrone-CameraMod?style=flat-square)](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20(Proton)-blue?style=flat-square)](#)
[![Game](https://img.shields.io/badge/game-FPV%20Kamikaze%20Drone-orange?style=flat-square)](https://store.steampowered.com/app/2707940/FPV_Kamikaze_Drone/)

[ 🇷🇺 Русский ](#-русский) | [ 🇬🇧 English ](#-english)

---

# 🇷🇺 Русский

Модификация для игры **FPV Kamikaze Drone**, позволяющая на лету переключать вид камеры между стандартным аналоговым сигналом с помехами и абсолютно чистым цифровым изображением:

1. **АКРО (Стандартный вид):** Аналоговый FPV видеосигнал с помехами, рябью, полосами VTX и ретро-эффектами CRT/VCR.
2. **НЕ-АКРО (Чистый вид):** Кристально чистая цифровая картинка без помех, шумов, полос и ряби.

---

### 🎮 Управление в игре

| Действие | Клавиша | Описание |
|---|:---:|---|
| **Переключить режим вида** | **`V`** или **`C`** | Переключение между **Акро** (с помехами) и **Не-акро** (чистая картинка) |

При переключении на экране отображается статус:
- `[РЕЖИМ] >> НЕ-АКРО << (Чистая картинка без помех и ряби)`
- `[РЕЖИМ] >> АКРО << (Аналоговый FPV / Рябь и помехи ВКЛ)`

---

### 🪟 Инструкция по установке для Windows

1. **Скачайте архив:**
   - Перейдите в раздел **[Releases](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest)** и скачайте файл:  
     📦 **`FPVKamikazeDrone-CleanView-v1.0.0-FullPack.zip`**
2. **Откройте папку игры в Steam:**
   - В вашей библиотеке Steam нажмите правой кнопкой мыши по **FPV Kamikaze Drone** -> **«Управление»** -> **«Просмотреть локальные файлы»**.
3. **Перейдите в директорию исполняемых файлов:**
   - Откройте подпапку:  
     `FPVKamikazeDrone\Binaries\Win64\`  
     *(В этой папке находится файл `FPVKamikazeDrone-Win64-Shipping.exe`).*
4. **Распакуйте файлы мода:**
   - Скопируйте файл `dwmapi.dll` и папку `ue4ss` из архива прямо в эту папку:  
     `.../FPVKamikazeDrone/Binaries/Win64/`
5. **Готово!**
   - Запустите игру через Steam. Во время полета или наблюдения нажимайте клавишу **`V`** или **`C`**.

---

### 🐧 Инструкция по установке для Linux и Steam Deck (Proton)

1. **Скачайте архив:**
   - В разделе **[Releases](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest)** скачайте:  
     📦 **`FPVKamikazeDrone-CleanView-v1.0.0-FullPack.zip`**
2. **Откройте папку игры:**
   - В Steam: правой кнопкой мыши по **FPV Kamikaze Drone** -> **«Управление»** -> **«Просмотреть локальные файлы»**.
   - Перейдите по пути:  
     `FPVKamikazeDrone/Binaries/Win64/`  
     *(Полный путь по умолчанию: `~/.local/share/Steam/steamapps/common/FPVKamikazeDrone/FPVKamikazeDrone/Binaries/Win64/`)*.
3. **Скопируйте файлы мода:**
   - Распакуйте `dwmapi.dll` и папку `ue4ss` в каталог `FPVKamikazeDrone/Binaries/Win64/`.
4. **Настройте параметры запуска в Steam:**
   - В библиотеке Steam нажмите правой кнопкой мыши по **FPV Kamikaze Drone** -> **«Свойства...»** (Properties) -> вкладка **«Общие»** (General).
   - В поле **«Параметры запуска»** (Launch Options) вставьте:
     ```bash
     WINEDLLOVERRIDES="dwmapi=n,b" %command% -dx11
     ```
     > **Зачем нужны эти параметры?**  
     > - `WINEDLLOVERRIDES="dwmapi=n,b"` — указывает Wine/Proton загружать DLL мода (`dwmapi.dll`) вместо встроенной системной заглушки.  
     > - `-dx11` — переключает рендеринг Unreal Engine на DirectX 11 (через DXVK), предотвращая вылеты и GPU-краши на видеокартах NVIDIA и AMD.
5. **Готово!**
   - Запустите игру. В полете нажимайте **`V`** или **`C`** для переключения картинки.

---

### ⚙️ Настройка параметров

Файл конфигурации расположен по пути:  
`.../FPVKamikazeDrone/Binaries/Win64/ue4ss/Mods/FPVCameraMod/Scripts/config.lua`

- `Config.ToggleKey = Key.V` — основная клавиша переключения.
- `Config.AltToggleKey = Key.C` — дополнительная клавиша переключения.
- `Config.DefaultMode = "ACRO"` — начальный режим при старте (`"ACRO"` — аналоговый с рябью, `"NON_ACRO"` — чистая картинка сразу).
- `Config.ShowOnScreenMessage = true` — показывать ли текстовое оповещение на экране при переключении.
- `Config.AlsoStabilizeFlight = false` — помощь стабилизации горизонта в режиме Не-акро.

---

### ❓ Решение проблем

- **Мод не реагирует на клавиши:**
  - Убедитесь, что файлы `dwmapi.dll` и папка `ue4ss` распакованы именно в `FPVKamikazeDrone/Binaries/Win64/`, а не в корень `steamapps/common/FPVKamikazeDrone/`.
  - На Linux убедитесь, что в параметрах запуска Steam прописано `WINEDLLOVERRIDES="dwmapi=n,b" %command%`.
- **Лог работы мода:**
  - Записывается в файл `FPVKamikazeDrone/Binaries/Win64/ue4ss/UE4SS.log`.

---

# 🇬🇧 English

A modification for **FPV Kamikaze Drone** that allows switching on the fly between the standard analog video feed with static/noise and a completely clean digital view:

1. **ACRO (Default Mode):** Standard analog FPV video feed with static noise, VTX interference lines, CRT ripples, and VHS distortion.
2. **NON-ACRO (Clean View):** Crystal-clear digital picture with zero noise, zero ripples, and zero interference.

---

### 🎮 In-Game Controls

| Action | Key | Description |
|---|:---:|---|
| **Toggle View Mode** | **`V`** or **`C`** | Toggle between **Acro** (analog noise) and **Non-Acro** (clean picture) |

On-screen status notification upon toggling:
- `[РЕЖИМ] >> НЕ-АКРО << (Чистая картинка без помех и ряби)` (Non-Acro: Clean image)
- `[РЕЖИМ] >> АКРО << (Аналоговый FPV / Рябь и помехи ВКЛ)` (Acro: Analog noise ON)

---

### 🪟 Windows Installation Guide

1. **Download the archive:**
   - Go to the **[Releases](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest)** section and download:  
     📦 **`FPVKamikazeDrone-CleanView-v1.0.0-FullPack.zip`**
2. **Open the game directory in Steam:**
   - In your Steam Library, right-click **FPV Kamikaze Drone** -> **Manage** -> **Browse local files**.
3. **Navigate to the binaries directory:**
   - Open the subfolder:  
     `FPVKamikazeDrone\Binaries\Win64\`  
     *(You will see `FPVKamikazeDrone-Win64-Shipping.exe` in this folder).*
4. **Extract mod files:**
   - Extract `dwmapi.dll` and the `ue4ss` folder from the archive directly into:  
     `.../FPVKamikazeDrone/Binaries/Win64/`
5. **Done!**
   - Launch the game through Steam. While in flight or spectating, press **`V`** or **`C`** to toggle video noise on and off!

---

### 🐧 Linux & Steam Deck Installation Guide (Proton)

1. **Download the archive:**
   - Go to **[Releases](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest)** and download:  
     📦 **`FPVKamikazeDrone-CleanView-v1.0.0-FullPack.zip`**
2. **Open the game folder:**
   - In Steam: right-click **FPV Kamikaze Drone** -> **Manage** -> **Browse local files**.
   - Navigate to:  
     `FPVKamikazeDrone/Binaries/Win64/`  
     *(Default path: `~/.local/share/Steam/steamapps/common/FPVKamikazeDrone/FPVKamikazeDrone/Binaries/Win64/`)*.
3. **Copy mod files:**
   - Extract `dwmapi.dll` and the `ue4ss` folder into `FPVKamikazeDrone/Binaries/Win64/`.
4. **Set Steam Launch Options:**
   - In your Steam Library, right-click **FPV Kamikaze Drone** -> **Properties...** -> **General** tab.
   - In the **Launch Options** field, paste:
     ```bash
     WINEDLLOVERRIDES="dwmapi=n,b" %command% -dx11
     ```
     > **Why are these parameters required?**  
     > - `WINEDLLOVERRIDES="dwmapi=n,b"` — Forces Wine/Proton to load the mod's proxy DLL (`dwmapi.dll`) instead of the built-in system stub.  
     > - `-dx11` — Switches Unreal Engine rendering to DirectX 11 (via DXVK), preventing GPU timeouts and crashes on NVIDIA and AMD graphics cards.
5. **Done!**
   - Launch the game and press **`V`** or **`C`** to toggle clean picture mode!

---

### ⚙️ Configuration

Configuration file is located at:  
`.../FPVKamikazeDrone/Binaries/Win64/ue4ss/Mods/FPVCameraMod/Scripts/config.lua`

Open with any text editor to customize:
- `Config.ToggleKey = Key.V` — Primary toggle key.
- `Config.AltToggleKey = Key.C` — Secondary toggle key.
- `Config.DefaultMode = "ACRO"` — Default mode on spawn (`"ACRO"` = analog noise, `"NON_ACRO"` = clean picture immediately).
- `Config.ShowOnScreenMessage = true` — Show on-screen HUD text notifications.
- `Config.AlsoStabilizeFlight = false` — Optional flight auto-leveling helper in Non-Acro mode.

---

### ❓ Troubleshooting

- **Mod does not respond to keys:**
  - Verify that `dwmapi.dll` and the `ue4ss` folder are placed inside `FPVKamikazeDrone/Binaries/Win64/` and NOT in the root game folder.
  - On Linux, verify that `WINEDLLOVERRIDES="dwmapi=n,b" %command%` is set in Steam Launch Options.
- **Log file:**
  - Check `FPVKamikazeDrone/Binaries/Win64/ue4ss/UE4SS.log` for mod loading and diagnostics.
