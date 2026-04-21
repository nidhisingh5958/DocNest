# DocNest 

A minimal, fully offline Android document scanner built with Flutter.  
No cloud. No login. No tracking. Just clean, fast scanning.

---

## ✨ Features

| Feature | Details |
|---|---|
| 📷 Scan | Camera-based scanning with automatic edge detection |
| 🖼️ Filters | Original · Grayscale · Black & White · Enhanced |
| 📑 Multi-page | Scan multiple pages into a single PDF |
| 🗂️ Organization | Year/Category folder structure + tags |
| 🔍 OCR Search | Offline text extraction (Google ML Kit) |
| 📤 Local Share | Bluetooth · Wi-Fi Direct · Nearby Share |
| 🔒 App Lock | Biometrics or PIN (optional) |
| 🌙 Minimal UI | Clean light theme, 3-tab nav |

---

## 🚀 Quick Setup

### Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter | 3.19+ |
| Dart | 3.0+ |
| Android Studio | Hedgehog (2023.1.1+) |
| Android SDK | API 24+ (Android 7.0) |
| Target SDK | API 34 (Android 14) |
| Java | 17 |

### 1. Clone / copy the project

```bash
# If you have the files, navigate to the project root
cd docnest
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Create required asset directories

```bash
mkdir -p assets/images assets/animations
touch assets/images/.gitkeep
touch assets/animations/.gitkeep
```

### 4. Run on device

```bash
# List connected devices
flutter devices

# Run (replace <device-id> with your device)
flutter run -d <device-id>

# Or just run on the first connected device
flutter run
```

### 5. Build release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 Dependencies

### Core Flutter packages

```yaml
# Camera & Image capture
camera: ^0.10.5+9              # Direct camera access
image_picker: ^1.0.7           # Gallery import
cunning_document_scanner: ^1.0.3  # Edge detection + document crop

# Image processing
image: ^4.1.7                  # Grayscale, B&W, contrast filters

# PDF
pdf: ^3.10.8                   # Pure-Dart PDF generation
printing: ^5.12.0              # PDF preview/printing

# Local Database
sqflite: ^2.3.2                # SQLite for document metadata
path_provider: ^2.1.2          # Device directory paths
path: ^1.9.0                   # Path joining utilities

# File operations
share_plus: ^9.0.0             # System share sheet (Bluetooth, Wi-Fi Direct)
open_filex: ^4.3.4             # Open PDF in external viewer
file_picker: ^8.0.3            # Import existing files

# OCR (fully offline, on-device ML)
google_mlkit_text_recognition: ^0.13.0  # No internet required

# Authentication
local_auth: ^2.1.8             # Biometrics / fingerprint / face ID

# UI
flutter_staggered_grid_view: ^0.7.0  # Masonry grid layout
flutter_slidable: ^3.1.0             # Swipe-to-delete
intl: ^0.19.0                        # Date formatting
material_symbols_icons: ^4.2755.0   # Extended icon set
```

### Why these packages?

- **`cunning_document_scanner`** — wraps native Android document detection (no custom OpenCV needed)
- **`google_mlkit_text_recognition`** — runs fully on-device using the ML Kit models bundled in the app; zero internet calls
- **`sqflite`** with FTS4 virtual tables enables fast full-text search across OCR results
- **`share_plus`** delegates to the Android system share sheet, which natively handles Bluetooth, Nearby Share, and Wi-Fi Direct without any extra code
- **`pdf`** is a pure-Dart library — no native dependencies, no crashes

---

## 🗂️ Project Structure

```
docnest/
├── lib/
│   ├── main.dart                    # App entry, bottom nav, lock gate
│   │
│   ├── models/
│   │   └── document.dart            # Document data model + DocCategory
│   │
│   ├── services/
│   │   ├── database_service.dart    # SQLite CRUD + FTS search
│   │   ├── storage_service.dart     # File system: folders, images, PDFs
│   │   ├── ocr_service.dart         # ML Kit text extraction
│   │   ├── document_service.dart    # Business logic coordinator
│   │   ├── share_service.dart       # Local file sharing
│   │   └── auth_service.dart        # App lock (biometric/PIN)
│   │
│   ├── screens/
│   │   ├── scan_screen.dart         # Camera → filter → save flow
│   │   ├── documents_screen.dart    # List/grid browser + search
│   │   ├── document_detail_screen.dart  # PDF view + OCR text + tags
│   │   ├── share_screen.dart        # Multi-select + share
│   │   ├── settings_screen.dart     # App lock, storage info
│   │   └── lock_screen.dart         # PIN pad / biometric prompt
│   │
│   ├── widgets/
│   │   ├── document_card.dart       # List and grid card variants
│   │   ├── filter_selector.dart     # Filter strip with live previews
│   │   ├── page_thumbnail_strip.dart  # Reorderable multi-page strip
│   │   ├── search_bar_widget.dart   # Debounced search input
│   │   └── tag_chip.dart            # Colored tag badge
│   │
│   └── utils/
│       └── theme.dart               # Colors, typography, ThemeData
│
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml      # Permissions (camera, BT, storage)
│       └── res/xml/file_paths.xml   # FileProvider config for sharing
│
├── assets/
│   ├── images/                      # Static image assets
│   └── animations/                  # Lottie JSON files (optional)
│
└── pubspec.yaml                     # Dependencies + asset declarations
```

---

## 🏗️ Architecture: 3-Layer Design

```
┌─────────────────────────────────────────┐
│          UI Layer (screens/)            │
│  Stateful widgets, no business logic    │
├─────────────────────────────────────────┤
│        Logic Layer (services/)          │
│  DocumentService coordinates all ops   │
├────────────────┬────────────────────────┤
│ StorageService │ DatabaseService (SQLite)│
│ (File system)  │ + OcrService (ML Kit)  │
└────────────────┴────────────────────────┘
```

**Key design decisions:**
- **`DocumentService`** is the single entry point for all document operations — screens never call storage or DB directly
- **Singleton services** — each service is a singleton to avoid duplicate connections
- **`IndexedStack`** for tabs — all 3 screens stay alive in memory for instant tab switching
- **FTS4 virtual table** — SQLite full-text search over OCR results, much faster than `LIKE '%query%'`

---

## 📂 Local File Structure (on device)

```
/data/user/0/<package>/files/DocNest/
├── 2025/
│   ├── Bills/
│   │   ├── Electricity_Bill_1712345678.pdf
│   │   └── ...
│   ├── Work/
│   │   └── Contract_1712345679.pdf
│   └── Personal/
│       └── ...
└── .cache/              ← Temporary page images before PDF creation
    └── page_1_*.jpg
```

---

## 🔐 Permissions Explained

| Permission | Why |
|---|---|
| `CAMERA` | Required for document scanning |
| `READ/WRITE_EXTERNAL_STORAGE` | Saving PDFs (Android ≤ 12) |
| `READ_MEDIA_IMAGES` | Gallery import (Android 13+) |
| `USE_BIOMETRIC` | Optional app lock |
| `BLUETOOTH_*` | Local file sharing via system share sheet |
| `ACCESS_WIFI_STATE` | Wi-Fi Direct sharing |
| `ACCESS_FINE_LOCATION` | Required by Android for Wi-Fi Direct |

> **Note:** No `INTERNET` permission is requested or needed. DocNest is fully offline.

---

## 🎨 Design System

| Token | Value |
|---|---|
| Primary | `#1A1A2E` (deep navy) |
| Accent | `#4F8EF7` (calm blue) |
| Background | `#F6F7FB` (off-white) |
| Surface | `#FFFFFF` |
| Border | `#E8EAF0` |
| Danger | `#EF4444` |

**Category colors:**
- Bills → `#FF6B6B` (red)
- Notes → `#4ECDC4` (teal)
- Personal → `#9B59B6` (purple)
- Work → `#3498DB` (blue)
- Other → `#95A5A6` (gray)

---

## 🐛 Troubleshooting

### Camera not opening
- Check that `CAMERA` permission is granted in device settings
- Test on a physical device — emulators may not support camera features

### OCR not working / slow
- ML Kit downloads its model on first use — needs a brief moment to initialize
- Ensure the image is well-lit and not blurry

### PDF won't open
- Install a PDF viewer app (Adobe Acrobat, Google PDF Viewer, etc.)
- The app uses `open_filex` which delegates to the system's default PDF handler

### Sharing not showing Bluetooth/Nearby
- These options appear in the Android system share sheet based on your device's capabilities
- Ensure Bluetooth and Location are enabled on both devices

### Build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Gradle issues
```bash
cd android
./gradlew clean
cd ..
flutter run
```

---

## 📋 Minimum Requirements

- **Android 7.0** (API 24) or higher
- **~80 MB** storage for the app + ML Kit model
- **Camera** with autofocus (for edge detection quality)

---

## 🔮 Possible Enhancements

- [ ] Password-protected PDFs
- [ ] Document merging (combine multiple PDFs)
- [ ] QR code scanning mode
- [ ] Dark theme
- [ ] Widget for quick-scan from home screen
- [ ] Auto-backup to local NAS via FTP/SMB

---

Built with Flutter · No backend · No cloud · No tracking
