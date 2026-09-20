# 📱 My Jailbreak Repo

Репозиторий твиков для Sileo / Cydia.

## 📦 Твики

### 1. **Pulse** — Неоновые часы на Lock Screen
- 💫 Пульсирующая glow-анимация вокруг времени
- 👋 Приветствие по времени суток (Good morning / Good night)

### 2. **SnapTap** — Жесты на статус-бар
- 🔒 Двойной тап по статус-бару → блокировка экрана
- 📅 Одинарный тап по времени → показать текущую дату (анимированный тост)

## 🚀 Установка репозитория в Sileo

### Вариант 1: GitHub Pages
```bash
cd ~/my-project/repo
git init
git add .
git commit -m "Initial repo"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
# Включите GitHub Pages в Settings → Pages → Branch: main, Folder: /
```
Затем в Sileo: **Источники → Добавить** → `https://YOUR_USERNAME.github.io/YOUR_REPO/`

### Вариант 2: Локально (через SSH)
```bash
# На устройстве (через SSH):
# Создайте папку репозитория
mkdir -p /var/repo

# Скопируйте файлы
scp -r ~/my-project/repo/* root@DEVICE_IP:/var/repo/

# Добавьте в Sileo источник:
file:///var/repo/
```

## 📱 Установка твиков вручную (без репозитория)
```bash
# Скопируйте .deb на устройство
scp com.yourcompany.pulse_1.0.0-1_iphoneos-arm.deb root@DEVICE_IP:/tmp/

# На устройстве:
dpkg -i /tmp/com.yourcompany.pulse_1.0.0-1_iphoneos-arm.deb
killall SpringBoard
```

## 🔧 Разработка

### Структура проекта
```
~/my-project/
├── pulse/                    # Твик Pulse (неоновые часы)
│   ├── Tweak.xm             # Исходный код (Logos)
│   ├── Makefile             # Сборка Theos
│   ├── control              # DEB метаданные
│   ├── Pulse.plist          # Фильтр MobileSubstrate
│   └── packages/            # Собранные .deb
│
├── snaptap/                 # Твик SnapTap (жесты)
│   ├── Tweak.xm             # Исходный код (Logos)
│   ├── Makefile             # Сборка Theos
│   ├── control              # DEB метаданные
│   ├── SnapTap.plist        # Фильтр MobileSubstrate
│   └── packages/            # Собранные .deb
│
└── repo/                    # Репозиторий для Sileo
    ├── debs/                # Все .deb пакеты
    ├── Packages             # Индекс (генерируется автоматически)
    ├── Release              # Мета-информация
    ├── CydiaIcon.png        # Иконка репозитория
    └── generate.sh          # Скрипт генерации репозитория
```

### Пересборка
```bash
# Пересобрать Pulse
cd ~/my-project/pulse
make clean && make package DEBUG=0

# Пересобрать SnapTap
cd ~/my-project/snaptap
make clean && make package DEBUG=0

# Обновить репозиторий
cd ~/my-project/repo && bash generate.sh
```

### Зависимости для разработки
- **Theos** (`~/theos/`) — кросс-компилятор для iOS
- **iOS SDK** (`~/theos/sdks/iPhoneOS14.5.sdk`)
- **toolchain** (`~/theos/toolchain/linux/iphone/`)
- **dpkg-deb**, **ar**, **xz** — для упаковки DEB

## ⚙️ Технические детали

| Твик | Мин. iOS | Фреймворки | Целевой класс |
|------|----------|------------|---------------|
| Pulse | 14.0 | UIKit, QuartzCore, SpringBoardFoundation | `SBLockScreenDateViewController` |
| SnapTap | 13.0 | UIKit, QuartzCore | `SpringBoard` |

## 🎨 Скриншоты (концепт)

### Pulse
```
┌──────────────────────┐
│  🔵╔═══════════════╗  │
│    ║  14:32       ║  │ ← Неоновый glow
│  🔵╚═══════════════╝  │
│     🌅 Good morning  │ ← Приветствие
└──────────────────────┘
```

### SnapTap
```
Двойной тап → Экран блокируется
Тап по времени → 📅  Monday, September 20
```
