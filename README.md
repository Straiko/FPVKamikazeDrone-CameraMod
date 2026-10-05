# FPV Kamikaze Drone - Visual Noise & Camera Mod (Clean View / Без Помех)

[![GitHub Release](https://img.shields.io/github/v/release/Straiko/FPVKamikazeDrone-CameraMod?style=flat-square)](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20(Proton)-blue?style=flat-square)](#)
[![Game](https://img.shields.io/badge/game-FPV%20Kamikaze%20Drone-orange?style=flat-square)](https://store.steampowered.com/app/2707940/FPV_Kamikaze_Drone/)

Модификация для игры **FPV Kamikaze Drone**, позволяющая на лету переключать вид камеры между аналоговым сигналом с помехами и абсолютно чистым цифровым изображением:

1. **АКРО (Стандартный вид):** Аналоговый FPV видеосигнал с помехами, рябью, полосами VTX и ретро-эффектами CRT/VCR.
2. **НЕ-АКРО (Чистый вид):** Кристально чистая картинка без помех, шумов, полос и ряби.

---

## 🎮 Управление в игре

| Действие | Клавиша | Описание |
|---|:---:|---|
| **Переключить режим вида** | **`V`** или **`C`** | Переключение между **Акро** (с помехами) и **Не-акро** (без помех) |

При переключении на экране отображается уведомление:
- `[РЕЖИМ] >> НЕ-АКРО << (Чистая картинка без помех и ряби)`
- `[РЕЖИМ] >> АКРО << (Аналоговый FPV / Рябь и помехи ВКЛ)`

---

## 🪟 Инструкция по установке для Windows

1. **Скачайте архив:**
   - Перейдите в раздел **[Releases](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest)** и скачайте файл:  
     📦 **`FPVKamikazeDrone-CleanView-v1.0.0-FullPack.zip`**
2. **Откройте папку игры в Steam:**
   - В вашей библиотеке Steam нажмите правой кнопкой мыши по **FPV Kamikaze Drone** -> **«Управление»** -> **«Просмотреть локальные файлы»**.
3. **Перейдите в директорию исполняемых файлов:**
   - Откройте подпапку:  
     `FPVKamikazeDrone\Binaries\Win64\`  
     *(В этой папке находится файл `FPVKamikazeDrone-Win64-Shipping.exe`).*
4. **Распакуйте мод:**
   - Из скачанного архива скопируйте файл `dwmapi.dll` и папку `ue4ss` прямо в эту папку:  
     `.../FPVKamikazeDrone/Binaries/Win64/`
5. **Готово!**
   - Запустите игру через Steam. Во время полета или наблюдения нажимайте клавишу **`V`** или **`C`**.

---

## 🐧 Инструкция по установке для Linux и Steam Deck (Proton)

1. **Скачайте архив:**
   - В разделе **[Releases](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest)** скачайте:  
     📦 **`FPVKamikazeDrone-CleanView-v1.0.0-FullPack.zip`**
2. **Откройте папку игры в файловом менеджере:**
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
     > - `WINEDLLOVERRIDES="dwmapi=n,b"` — указывает Wine/Proton загружать DLL мода (`dwmapi.dll`) вместо встроенной заглушки.  
     > - `-dx11` — переключает рендеринг Unreal Engine на DirectX 11 (через DXVK), предотвращая вылеты и GPU-краши на видеокартах NVIDIA и AMD.
5. **Готово!**
   - Запустите игру. В полете нажимайте **`V`** или **`C`** для переключения картинки.

---

## ⚙️ Настройка параметров мода

Файл конфигурации расположен по пути:  
`.../FPVKamikazeDrone/Binaries/Win64/ue4ss/Mods/FPVCameraMod/Scripts/config.lua`

Вы можете открыть его в любом текстовом редакторе и настроить под себя:
- `Config.ToggleKey = Key.V` — основная клавиша переключения.
- `Config.AltToggleKey = Key.C` — дополнительная клавиша переключения.
- `Config.DefaultMode = "ACRO"` — начальный режим при старте (`"ACRO"` — аналоговый с рябью, `"NON_ACRO"` — чистая картинка сразу).
- `Config.ShowOnScreenMessage = true` — показывать ли текстовое оповещение на экране при переключении (`true` / `false`).
- `Config.AlsoStabilizeFlight = false` — помощь стабилизации горизонта в режиме Не-акро.

---

## ❓ Решение возможных проблем

- **Мод не реагирует на клавиши:**
  - Убедитесь, что файлы `dwmapi.dll` и папка `ue4ss` распакованы именно в `FPVKamikazeDrone/Binaries/Win64/`, а не в корень `steamapps/common/FPVKamikazeDrone/`.
  - На Linux убедитесь, что в параметрах запуска Steam прописано `WINEDLLOVERRIDES="dwmapi=n,b" %command%`.
- **Лог работы мода:**
  - Логи загрузки и работы записываются в файл:  
    `FPVKamikazeDrone/Binaries/Win64/ue4ss/UE4SS.log`.

---

## 🌐 English Quick Guide

### 🎮 Controls
Press **`V`** or **`C`** in flight to toggle between:
- **ACRO:** Standard analog FPV feed with VTX static, scanlines, and ripples.
- **NON-ACRO:** Crystal clear digital camera view without any video interference.

### 🪟 Windows Install:
1. Download **`FPVKamikazeDrone-CleanView-v1.0.0-FullPack.zip`** from [Releases](https://github.com/Straiko/FPVKamikazeDrone-CameraMod/releases/latest).
2. Extract `dwmapi.dll` and the `ue4ss` folder into:  
   `.../FPVKamikazeDrone/Binaries/Win64/`
3. Launch the game via Steam.

### 🐧 Linux / Steam Deck Install:
1. Extract `dwmapi.dll` and `ue4ss` folder into `.../FPVKamikazeDrone/Binaries/Win64/`.
2. In Steam Game Properties -> **Launch Options**, set:
   ```bash
   WINEDLLOVERRIDES="dwmapi=n,b" %command% -dx11
   ```
3. Launch game.
