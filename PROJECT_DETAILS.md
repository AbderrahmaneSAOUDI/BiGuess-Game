# 🎮 BiGuess Game — Complete Project Documentation & Technical Dossier

<div align="center">

  <img src="assets/logos/biguess-icon.webp" alt="BiGuess Logo" width="130" height="130" style="border-radius: 28px; margin-bottom: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.25);" />

  # BiGuess Game (gdg_guess_game)
  ### *The Ultimate Face-to-Face 2-Player Anime & Pop-Culture Character Guessing Game*

  [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-00B4D8?style=for-the-badge)](https://riverpod.dev)
  [![Material 3](https://img.shields.io/badge/UI-Material%203-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
  [![Shorebird Code Push](https://img.shields.io/badge/OTA-Shorebird%202.0-blueviolet?style=for-the-badge)](https://shorebird.dev)
  [![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20%26%20Layered-2E7D32?style=for-the-badge)](https://blog.cleancoder.com)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
  [![Current Version](https://img.shields.io/badge/Version-v0.31.0%2B7-orange?style=for-the-badge)](pubspec.yaml)

  <p align="center">
    <b>An offline social duel that fuses classic "20 Questions" deduction with 18 legendary anime franchises and 920+ character cards.</b>
  </p>

</div>

---

## 📑 Table of Contents

1. [Executive Summary & Project Overview](#1-executive-summary--project-overview)
2. [Game Mechanics, Gameplay Flow & Rules](#2-game-mechanics-gameplay-flow--rules)
3. [Full Feature Matrix & System Capabilities](#3-full-feature-matrix--system-capabilities)
4. [Anime Franchises & Character Catalog Analytics](#4-anime-franchises--character-catalog-analytics)
5. [Software Architecture & Design Patterns](#5-software-architecture--design-patterns)
6. [Hybrid OTA Update Engine & Shorebird Code-Push](#6-hybrid-ota-update-engine--shorebird-code-push)
7. [Developer Automation Toolbox (`scripts/`)](#7-developer-automation-toolbox-scripts)
8. [Complete Git Commit History & Release Evolution](#8-complete-git-commit-history--release-evolution)
9. [Technical Stack, Dependencies & Configurations](#9-technical-stack-dependencies--configurations)
10. [Repository File & Directory Structure](#10-repository-file--directory-structure)
11. [Testing, Quality Assurance & Verification](#11-testing-quality-assurance--verification)
12. [Build, Deployment & Packaging Guide](#12-build-deployment--packaging-guide)
13. [Team, Roles & Credits](#13-team-roles--credits)

---

## 1. Executive Summary & Project Overview

### 💡 What is BiGuess?
**BiGuess** is an interactive, mobile-first 2-player social party game developed in Flutter and Dart. Designed for face-to-face gatherings, anime conventions, student meetups, and friendly hangouts, BiGuess challenges two players sitting opposite each other to deduce mystery anime characters using structured, rapid-fire **Yes/No interrogation**.

### 🎯 Core Philosophy
Unlike standard trivia apps where players simply tap multiple-choice answers, BiGuess brings people together **offline and in-person**:
- **Zero Online Requirement for Gameplay:** Instant offline responsiveness.
- **Pure Face-to-Face Engagement:** Social conversation, psychological bluffing, and trivia memory.
- **Curated Asset High-Performance Engine:** Ultra-compressed WebP cards with zero runtime asset lag.
- **Continuous Seamless Delivery:** In-app hybrid OTA auto-updates (Shorebird instant hot patching + In-App ABI-split APK installer).

---

## 2. Game Mechanics, Gameplay Flow & Rules

BiGuess is played between **two players** using **one or two smartphones** sitting across from each other.

```
       ┌───────────────────────────────────────────────┐
       │          PLAYER 1 : The Answerer              │
       │    (Holds phone / Knows mystery character)     │
       └───────────────────────┬───────────────────────┘
                               │
               "Is your character a Devil Fruit user?"
                               │  "Yes!"
                               ▼
       ┌───────────────────────────────────────────────┐
       │          PLAYER 2 : The Guesser               │
       │     (Asks tactical Yes/No questions to win)   │
       └───────────────────────────────────────────────┘
```

### 🔁 Step-by-Step Round Flow
1. **Franchise Selection:** Players pick their shared favorite anime universe (e.g. *One Piece*, *Attack on Titan*, *Naruto*, *Hunter X Hunter*, *Black Clover*, *Demon Slayer*).
2. **Hit "Random" / "Roll":** The Answerer taps the interactive action button to start the round.
3. **Suspense Countdown (0s - 10s):** An animated countdown timer ticks down while the Answerer holds the phone facing them (or towards their opponent in dual-phone mode).
4. **Secret Character Reveal:** The character artwork and mystery card are revealed.
5. **The Tactical Interrogation:**
   - The Guesser asks questions that can **only** be answered with **"Yes"**, **"No"**, or **"Irrelevant / Unknown"** (*e.g., "Do they wield a sword?", "Are they an Uchiha?", "Are they part of the Survey Corps?"*).
6. **Final Deduction & Scoring:**
   - The Guesser narrows down the roster and declares their guess.
   - If correct, the Guesser earns a point!
7. **Role Reversal:** Players switch roles for the next round.

### 📜 Official Game Rules
- ⚖️ **Yes/No Only:** Questions must never be open-ended (e.g., *"What hair color do they have?"* is invalid).
- 🤝 **Honesty Policy:** Answers must adhere strictly to official anime/manga canon.
- 🙈 **Anti-Peeking Protocol:** The Guesser must never look at the Answerer's screen.
- ⏱️ **Turn Limitation:** 1 question asked per turn.

### 🎉 Fun Tournament Variations
- **Lightning Round:** 15-second timer per question.
- **Scoreboard Gauntlet:** First to 5 points wins.
- **Franchise Roulette:** Switch categories every single round.

---

## 3. Full Feature Matrix & System Capabilities

| Feature Category | Description & Technical Capability |
| :--- | :--- |
| 🎭 **18 Anime Universes** | 6 fully packaged high-res categories (922 characters) + 12 active expansion franchises. |
| 🎲 **Dual Shuffling Algorithms** | **Fair Non-Repeating (Deck Shuffler):** Cycles through entire roster before repeats.<br>**Pure Random:** Traditional pseudo-random generator with seed entropy. |
| ⏱️ **Configurable Suspense Timer** | Configurable anticipation duration: `0s (Instant)`, `1s`, `2s`, `3s`, `5s`, and `10s`. |
| 🌓 **Adaptive Theming Engine** | Full Material 3 support for **Dark Mode**, **Light Mode**, and **System Adaptive** with custom surfaces and high contrast. |
| 🎛️ **Character Hint Overlay** | Dynamic toggle to show or hide character name badges during gameplay for beginner or hardcore modes. |
| ✨ **Rich Micro-Animations** | 3D interactive scale cards (`InteractiveScaleCard`), Mystery Box pulse reveals (`AnimatedMysteryBox`), countdown ticker (`AnimatedCountdown`), and staggered grid cards (`flutter_staggered_animations`). |
| 🏆 **Built-in Game Center Modal** | Tabbed dialog (`GameInfoDialog`) covering live settings, visual how-to-play guides, app details, and developer profiles. |
| 🔄 **Hybrid In-App OTA System** | Dual-tier updater combining Shorebird Code Push live patching with an in-app multi-ABI APK download & install manager. |
| 📱 **Cross-Platform Target** | Native Android architecture builds (`arm64-v8a`, `armeabi-v7a`, `x86_64`) and Web release bundle. |

---

## 4. Anime Franchises & Character Catalog Analytics

BiGuess features **922 individual character image assets** thoroughly optimized in modern WebP format:

### 📊 Packaged Active Universes

| Category Name | Directory Identifier | Character Count | Avg File Size | Shortest Name | Longest Name |
| :--- | :--- | :---: | :---: | :--- | :--- |
| ⚔️ **Attack on Titan** | `attack_on_titan` | **131** | 7.8 KB | `Daz` | `Darius Zackly` |
| 🍀 **Black Clover** | `black_clover` | **67** | 8.5 KB | `Asta` | `Lemiel Silvamillion Clover` |
| 🗡️ **Demon Slayer** | `demon_slayer` | **43** | 9.3 KB | `Rui` | `Kiyo Terauchi / Sumi / Naho` |
| 🎣 **Hunter X Hunter** | `hunter_x_hunter` | **135** | 6.6 KB | `Gel` | `Leorio Paradinight` |
| 🍥 **Naruto** | `naruto` | **80** | 13.6 KB | `Ao` | `Hashirama Senju` |
| 🏴‍☠️ **One Piece** | `one_piece` | **466** | 10.7 KB | `Gin` | `Trafalgar D. Water Law` |
| **TOTAL PACKAGED** | **6 Franchises** | **922 Cards** | **9.7 KB** | **Total Disk Footprint: 8.72 MB** |

### 🚀 Franchises in Active Expansion (Registered in Manifest & UI)
- 🌸 **Bleach** (`assets/images/bleach`)
- 👁️ **Code Geass** (`assets/images/code_geass`)
- 📓 **Death Note** (`assets/images/death_note`)
- 🔍 **Detective Conan** (`assets/images/detective_conan`)
- 🧪 **Dr. Stone** (`assets/images/dr_stone`)
- 🐉 **Dragon Ball Z** (`assets/images/dragon_ball_z`)
- ⚗️ **Fullmetal Alchemist: Brotherhood** (`assets/images/fmab`)
- 🧿 **Jujutsu Kaisen** (`assets/images/jujutsu_kaisen`)
- 💥 **My Hero Academia** (`assets/images/my_hero_academia`)
- 🗡️ **Solo Leveling** (`assets/images/solo_leveling`)
- ⏳ **Tokyo Revengers** (`assets/images/tokyo_revengers`)
- ⛵ **Vinland Saga** (`assets/images/vinland_saga`)

---

## 5. Software Architecture & Design Patterns

The BiGuess codebase is built on **Clean Architecture** with strict layer separation, dependency inversion, and declarative state management via **Riverpod 2.x**.

```
                           ┌───────────────────────────────┐
                           │      PRESENTATION LAYER       │
                           │  Screens, Widgets, Dialogs,   │
                           │    Controllers & ViewModels   │
                           └───────────────┬───────────────┘
                                           │ Calls Use Cases
                                           ▼
                           ┌───────────────────────────────┐
                           │         DOMAIN LAYER          │
                           │  Entities, Use Cases, Models, │
                           │     Repository Interfaces     │
                           └───────────────▲───────────────┘
                                           │ Implements
                                           │
                           ┌───────────────┴───────────────┐
                           │          DATA LAYER           │
                           │  Repository Implementations,  │
                           │   Data Sources & Manifests    │
                           └───────────────────────────────┘
                                           │
                           ┌───────────────┴───────────────┐
                           │    CORE & SERVICES LAYER      │
                           │   Theme, Constants, Utils,    │
                           │  OTA & Shorebird Patch Engine │
                           └───────────────────────────────┘
```

### 🧩 Architectural Layers Breakdown

#### 1. Domain Layer (`lib/domain/`)
- **Models & Entities:**
  - `GameCategory`: Pure immutable category representation.
  - `CharacterAlgorithm`: Enum defining `fairNonRepeating` vs `pureRandom`.
  - `GameState`: Complete immutable round state (`isLoading`, `isCountingDown`, `countdown`, `currentImageAsset`, `correctAnswer`, `playedCharacters`).
  - `SemVer`: Custom Semantic Versioning comparator supporting `major.minor.patch+buildNumber`.
  - `RemoteVersion`: Data model for `version.json` remote payload and ABI URL resolution.
  - `UpdateDecision`: Sealed update resolution hierarchy (`UpdateNone`, `UpdateShorebirdPatch`, `UpdateFullApk`).
  - `DeveloperInfo`: Contributor and team profiles.
- **Repository Contracts:**
  - `ICategoryRepository`: Contract for loading categories, resolving counts, and character sets.
  - `IAppInfoRepository`: Contract for system version and platform querying.
- **Use Cases:**
  - `SelectCharacterUseCase`: Encapsulates character selection business logic (Fair non-repeating shuffle vs pure random).

#### 2. Data Layer (`lib/data/`)
- **Data Sources:**
  - `AssetManifestDataSource`: Reads pre-indexed static metadata directly from `assets_manifest.dart` with zero runtime I/O overhead.
  - `PackageInfoDataSource`: Interacts with native platform bundle info.
- **Repository Implementations:**
  - `CategoryRepositoryImpl`: Concrete implementation of `ICategoryRepository`.
  - `AppInfoRepositoryImpl`: Concrete implementation of `IAppInfoRepository`.

#### 3. Presentation Layer (`lib/presentation/`)
- **Controllers (Riverpod StateNotifiers):**
  - `GameController`: Coordinates character selection, countdown triggers, audio/visual states, and reset hooks.
  - `GameSettingsController`: Persists user algorithm choice, countdown length, and hint toggles.
  - `CategoryController`: Manages category listing and search filtering.
  - `ThemeController`: Manages Dark/Light/System theme transitions.
  - `UpdateController`: Orchestrates background version checks, Shorebird patch installation, and in-app APK download workflows.
- **Screens & Dialogs:**
  - `CategoriesScreen`: Responsive franchise selection grid with staggered hero animations.
  - `GameScreen`: Main suspense countdown arena, character card viewport, and interaction deck.
  - `GameInfoDialog`: Multi-tabbed overlay (Settings, How to Play, About, Developers).
- **Custom Visual Components:**
  - `InteractiveScaleCard`: Touch-responsive 3D tilt and scale character display.
  - `AnimatedCountdown`: Circular pulse countdown with radial progress tick.
  - `AnimatedMysteryBox`: Suspense box with glowing particles.
  - `AnimatedGlassAppBarBackground`: Translucent frosted glass effect.

#### 4. Core & Services Layer (`lib/core/`, `lib/services/`)
- `AppConstants`: Centralized game configurations and franchise declarations.
- `AppColors` & `AppTheme`: Material 3 color system with custom dark and light palettes.
- `AssetLoader`: Static file resolution utility with Unicode NFC normalization.
- `VersionService`: Remote manifest parser, ABI architecture detector, and update decision engine.
- `OtaInstallerService`: Resilient chunked APK downloader using `Dio`, rolling speed/ETA estimator, and `OpenFilex` native package installer trigger.
- `ShorebirdPatchService`: Gracefully isolated wrapper for Shorebird runtime code-push patches.

---

## 6. Hybrid OTA Update Engine & Shorebird Code-Push

BiGuess features an enterprise-grade, zero-downtime update engine that balances instant code push with full native binary installation.

```
                            [ Launch App / Check Updates ]
                                          │
                                          ▼
                             [ Fetch version.json from GitHub ]
                                          │
                   ┌──────────────────────┴──────────────────────┐
                   ▼                                             ▼
       [ Major / Minor Bump OR ]                     [ Patch Bump ONLY & ]
       [ Native Code Changed   ]                     [ No Native Changes ]
                   │                                             │
                   ▼                                             ▼
       [ In-App Full APK Installer ]                 [ Shorebird Code Push ]
       - Detect Device ABI                           - Background patch download
         (arm64, v7a, x86_64)                        - Instant staged installation
       - Dio streaming download with speed/ETA       - Applies on next restart
       - Validate atomic .tmp -> .apk                
       - Launch Android Package Installer
```

### ⚙️ Update Decision Rules
1. **Up-to-Date (`UpdateNone`):** If `localVersion >= remoteVersion`, no update action is required.
2. **Shorebird Patch (`UpdateShorebirdPatch`):** If the remote version is a minor patch without native platform changes, Shorebird downloads and stages the patch in the background.
3. **Full Native APK (`UpdateFullApk`):** If a major/minor version bump occurs or native Android code (`android/`) has changed, the app initiates an in-app APK download targeting the device's exact CPU architecture (`arm64-v8a`, `armeabi-v7a`, or `x86_64`).
4. **Mandatory Enforcement:** If `localVersion < minRequiredVersion`, the update dialog blocks gameplay until updated.

---

## 7. Developer Automation Toolbox (`scripts/`)

BiGuess includes an extensive suite of Python 3 and Bash automation tools in the `scripts/` directory to streamline asset processing, manifest generation, quality assurance, and automated multi-ABI releases.

```text
scripts/
├── menu.py                 # Interactive terminal CLI dashboard
├── run.sh                  # Shell entrypoint launcher
├── convert_and_optimize.py # Batch image converter & WebP compressor
├── generate_manifest.py    # Static asset manifest generator & pubspec sync
├── audit_assets.py         # Broken links, missing files & integrity auditor
├── normalize_filenames.py  # Character name sanitizer & Unicode NFC fixer
├── character_stats.py      # Character analytics & Levenshtein typo detector
├── build_app.py            # Pre-flight tester & Flutter build runner
├── release.py              # End-to-end versioning, build & GitHub release pipeline
└── update_version.sh       # Fast version bump utility
```

### 🛠️ CLI Tools Summary

#### 1. `menu.py` / `run.sh` — Interactive Dashboard
Interactive terminal interface providing 1-click access to all development and release utilities:
```bash
./scripts/run.sh
# or
python3 scripts/menu.py
```

#### 2. `convert_and_optimize.py` — Image Compressor
Converts images (PNG, JPG, BMP, GIF) to WebP, recompresses oversized assets, strips EXIF metadata, and downscales images for mobile RAM efficiency:
```bash
python3 scripts/convert_and_optimize.py assets/images/ -q 82 -m 500 -d
```

#### 3. `generate_manifest.py` — Asset Manifest & Config Sync
Scans `assets/images/` subdirectories and compiles `lib/assets_manifest.dart` with deterministic sorting and Unicode NFC normalization, ensuring characters with accents (`Bell-mère`, `Charlotte Brûlée`) and Arabic scripts load cleanly without runtime parsing lag:
```bash
python3 scripts/generate_manifest.py --sync-pubspec
```

#### 4. `audit_assets.py` — Asset Integrity Auditor
Scans the codebase and disk storage to flag missing assets, casing mismatches, corrupted headers, orphan images, oversized files, and irregular naming:
```bash
python3 scripts/audit_assets.py -r audit_report.md
```

#### 5. `normalize_filenames.py` — Character Filename Cleaner
Removes web scraper artifacts (`_1`, `(1)`, `[HQ]`, `%20`, double spaces) and standardizes character file naming:
```bash
python3 scripts/normalize_filenames.py --apply --sync-manifest
```

#### 6. `character_stats.py` — Analytics & Typo Detector
Calculates franchise distribution metrics, detects potential duplicate character entries via **Levenshtein distance**, and exports catalogs to JSON/CSV:
```bash
python3 scripts/character_stats.py --check-duplicates --export-json characters.json
```

#### 7. `release.py` & `build_app.py` — Automated Release Pipeline
Performs pre-flight checks (`flutter pub get`, `flutter analyze`, `flutter test`), bumps `pubspec.yaml` and `version.json`, builds multi-ABI APKs, calculates SHA-256 checksums, creates GitHub Releases via GitHub CLI/API, uploads release assets, publishes Shorebird patches, and commits/tags Git:
```bash
python3 scripts/release.py --bump minor --split-apk --push
```

---

## 8. Complete Git Commit History & Release Evolution

BiGuess was created on **May 27, 2025**, and has evolved across **48 distinct commits and version milestones** leading up to **v0.31.0** in August 2026.

### 🌟 Project Evolutionary Phases

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Phase 1: Genesis & Rapid Prototyping (v0.01 – v0.10) [May – June 2025]     │
│  - Core concept implementation: 2-player character guessing arena.          │
│  - Basic image loading, initial categories, early countdown timer.          │
├─────────────────────────────────────────────────────────────────────────────┤
│  Phase 2: Roster Ingestion & Localization (v0.11 – v0.18) [June 2025]        │
│  - Massive expansion of One Piece, Hunter x Hunter, and Naruto rosters.     │
│  - Ingestion of Arabic character naming sets and multi-character cards.     │
│  - Introduction of the multi-tabbed Rules and Contact dialog.               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Phase 3: Modernization & UI Polish (v0.19 – v0.25) [August 2026]           │
│  - Upgrade to Flutter 3.x, Dart 3, and Material 3 design system.            │
│  - WebP conversion of all 920+ character images (saving over 75% disk space)│
│  - Micro-animations: 3D interactive card tilt, mystery box particles.       │
├─────────────────────────────────────────────────────────────────────────────┤
│  Phase 4: Clean Architecture & Riverpod Refactor (v0.26 – v0.30)            │
│  - Full decoupling into Domain, Data, Presentation, and Core layers.        │
│  - State management migration to Riverpod 2.x StateNotifiers.               │
│  - Static asset code-generation via lib/assets_manifest.dart.               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Phase 5: Shorebird OTA & Release Automation (v0.30.2 – v0.31.0)            │
│  - Integration of Shorebird Code Push 2.x for over-the-air hot patching.    │
│  - In-app multi-ABI APK downloader and installer service with Dio.          │
│  - Complete Python automation toolbox and GitHub release pipeline.          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📜 Exhaustive Chronological Commit Log

| Commit Hash | Commit Date | Commit Description & Release Milestone | Author |
| :---: | :---: | :--- | :--- |
| `20d4b77` | 2025-05-27 | **Initial commit** — Repository creation and initial Flutter scaffold | Abderrahmane SAOUDI |
| `ec05452` | 2025-05-27 | **v0.01** — Initial proof-of-concept game screen and single-category deck | Abderrahmane SAOUDI |
| `814814a` | 2025-05-29 | **v0.02** — Category selection screen and multi-franchise navigation | Abderrahmane SAOUDI |
| `d33f580` | 2025-05-29 | **v0.03** — Added countdown timer logic before character reveal | Abderrahmane SAOUDI |
| `6abba8a` | 2025-05-30 | **v0.04** — Asset folder re-organization and category metadata | Abderrahmane SAOUDI |
| `ce66d93` | 2025-05-31 | **v0.05** — Basic randomizer algorithm and UI refinements | Abderrahmane SAOUDI |
| `44f53ec` | 2025-06-01 | **v0.06** — Card layout styling, custom GoogleSans typography integration | Abderrahmane SAOUDI |
| `4fc4ab2` | 2025-06-03 | **v0.07** — Rules modal dialog and how-to-play instructions | Abderrahmane SAOUDI |
| `7969e88` | 2025-06-05 | **v0.08** — Hunter X Hunter and Naruto character asset ingestion | Abderrahmane SAOUDI |
| `5d68664` | 2025-06-07 | **v0.09** — Sound and vibration feedback experiments, layout fixes | Abderrahmane SAOUDI |
| `a9fbcf9` | 2025-06-08 | **v0.10** — Attack on Titan and Black Clover roster addition | Abderrahmane SAOUDI |
| `04500ab` | 2025-06-09 | **v0.11** — One Piece massive character expansion pack | Abderrahmane SAOUDI |
| `c1f80f2` | 2025-06-09 | **v0.12** — Demon Slayer asset pack and logo integration | Abderrahmane SAOUDI |
| `bb1fefd` | 2025-06-25 | **v0.13** — Added Arabic character names support for Hunter X Hunter | Abderrahmane SAOUDI |
| `3aa9042` | 2025-06-26 | **v0.14** — Character card scaling and high-DPI rendering improvements | Abderrahmane SAOUDI |
| `d666016` | 2025-06-26 | **v0.15** — UI cleanup, transition speed tuning, and memory optimization | Abderrahmane SAOUDI |
| `44b00b6` | 2025-06-27 | **v0.16** — Non-repeating character deck algorithm implementation | Abderrahmane SAOUDI |
| `c43c2ef` | 2025-06-27 | **v0.17 (v0.18.0-beta)** — Refactor CategoriesScreen UI, tabbed dialogs, developer profiles | Abderrahmane SAOUDI |
| `c946fd4` | 2025-06-28 | **v0.18** — Final beta stabilization and asset manifest indexing | Abderrahmane SAOUDI |
| `8474453` | 2026-08-22 | **v0.19** — Codebase reactivation: Flutter 3.x upgrade and dependency updates | Abderrahmane SAOUDI |
| `8a3801f` | 2026-08-22 | **v0.20** — Material 3 theming implementation and Dark Mode color tokens | Abderrahmane SAOUDI |
| `dd9bcb7` | 2026-08-22 | **v0.21** — Batch image conversion to WebP format across all categories | Abderrahmane SAOUDI |
| `bdc4409` | 2026-08-22 | **v0.22** — 3D interactive card tilt animations and gesture physics | Abderrahmane SAOUDI |
| `f412fca` | 2026-08-22 | **v0.23** — Mystery box suspense animations and glowing particle effects | Abderrahmane SAOUDI |
| `7fe2919` | 2026-08-22 | **v0.24** — Character hint visibility toggle and in-game settings modal | Abderrahmane SAOUDI |
| `066ca7d` | 2026-08-22 | **v0.25** — Release polish for v0.25.0: App icons, web build support, README overhaul | Abderrahmane SAOUDI |
| `f66bd74` | 2026-08-23 | **v0.26** — Clean Architecture migration: Created Domain, Data, Core, and Presentation layers | Abderrahmane SAOUDI |
| `69b9f15` | 2026-08-23 | **v0.27** — State management overhaul: Migrated all screens and controllers to Riverpod 2.x | Abderrahmane SAOUDI |
| `7ce7ebe` | 2026-08-24 | **v0.28** — Automated static asset code-gen: Created `lib/assets_manifest.dart` and Python scripts | Abderrahmane SAOUDI |
| `18a6793` | 2026-08-25 | **v0.29** — Unit test suite addition: Added domain, repository, and controller test coverage | Abderrahmane SAOUDI |
| `a4470b1` | 2026-08-25 | **release: v0.30.2** — Release automation: Built `scripts/release.py` and GitHub workflow | Abderrahmane SAOUDI |
| `640d023` | 2026-08-25 | **release: v0.30.3** — In-app OTA engine: Added `VersionService` and remote `version.json` check | Abderrahmane SAOUDI |
| `e3d9188` | 2026-08-25 | **release: v0.30.3** — OTA download manager: Added Dio chunked streaming and speed calculator | Abderrahmane SAOUDI |
| `b6d56eb` | 2026-08-25 | **v0.30** — Integration of Shorebird code push SDK and `shorebird.yaml` | Abderrahmane SAOUDI |
| `f7b76c3` | 2026-08-25 | **v0.30.4** — Shorebird patch verification and background update handlers | Abderrahmane SAOUDI |
| `6345a8e` | 2026-08-25 | **release: v0.30.4** — Android native installer intent integration via `open_filex` | Abderrahmane SAOUDI |
| `3facb71` | 2026-08-25 | **release: v0.30.4** — Architecture-specific APK URL resolution (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | Abderrahmane SAOUDI |
| `47e75de` | 2026-08-25 | **release: v0.30.5** — Cleaned up stale APK cache handling and download temp files | Abderrahmane SAOUDI |
| `393c16b` | 2026-08-25 | **release: v0.30.6** — Version synchronization script and manifest validator checks | Abderrahmane SAOUDI |
| `efcbd11` | 2026-08-25 | **release: v0.30.4** — Release hotfix stabilization | Abderrahmane SAOUDI |
| `67a2699` | 2026-08-25 | **v0.30.4.2** — UI alignment fixes for large-screen tablets and foldable displays | Abderrahmane SAOUDI |
| `6559933` | 2026-08-26 | **release: v0.30.5** — Updated asset manifest and cleaned up build targets | Abderrahmane SAOUDI |
| `996f853` | 2026-08-26 | **release: v0.30.5** — Tagged release v0.30.5 | Abderrahmane SAOUDI |
| `dfd3d38` | 2026-08-26 | **patch: shorebird OTA update for v0.30.5+6** — Pushed first live Shorebird patch | Abderrahmane SAOUDI |
| `b143521` | 2026-08-26 | **patch: shorebird OTA update for v0.30.5+6** — Shorebird patch verification | Abderrahmane SAOUDI |
| `62f1441` | 2026-08-26 | **patch: shorebird OTA update for v0.30.5+6** — Patch live rollout | Abderrahmane SAOUDI |
| `747b462` | 2026-08-26 | **v0.31** — Prepared version v0.31.0+7 milestone with multi-ABI split release pipeline | Abderrahmane SAOUDI |
| `39388b2` | 2026-08-26 | **release: v0.30.5** — Release sync and documentation updates | Abderrahmane SAOUDI |

---

## 9. Technical Stack, Dependencies & Configurations

### 💻 Environment
- **SDK:** Flutter `>=3.0.0 <4.0.0`
- **Dart:** `>=3.0.0`
- **Build Tooling:** Android Gradle Plugin, Java 17+, Python 3.8+

### 📦 Runtime Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.6.1       # Declarative, reactive state management

  # Over-The-Air & In-App Updates
  shorebird_code_push: ^2.0.7    # Instant Flutter over-the-air code push
  dio: ^5.7.0                    # High-performance HTTP client for APK downloads
  open_filex: ^4.5.0             # Android native package installer trigger
  restart_app: ^1.3.2            # Hot-restart app after OTA code-push patches
  package_info_plus: ^10.2.1     # Reads installed app version & build number
  device_info_plus: ^13.2.0      # Detects hardware CPU ABIs (arm64, v7a, x86_64)

  # UI & Animations
  flutter_staggered_animations: ^1.1.1 # Fluid staggered list & grid entry animations
  cupertino_icons: ^1.0.2        # Cupertino icon set

  # Storage & Networking
  path_provider: ^2.1.1          # Cache and temp storage path resolution
  path: ^1.8.3                   # File path manipulation
  url_launcher: ^6.3.1           # External browser launching (GitHub, profiles)
```

### 🛠️ Development Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0          # Strict Flutter linting & analyzer rules
  flutter_launcher_icons: ^0.14.3 # Adaptive launcher icon generator
```

### 🎨 Fonts & Assets
- **Typography:** GoogleSans Suite (`GoogleSans-Regular.ttf`, `GoogleSans-Medium.ttf`, `GoogleSans-Bold.ttf`).
- **Icons & Logos:** Adaptive WebP logos and app icons in `assets/logos/`.
- **Shorebird Configuration:** Configured in `shorebird.yaml` (`app_id: a0871911-c109-46f9-ac9c-2104ab938018`).

---

## 10. Repository File & Directory Structure

```text
BiGuess-Game/
├── .github/                         # GitHub repository configuration
├── android/                         # Native Android project configuration
│   ├── app/                         # App module, AndroidManifest.xml, build.gradle
│   └── gradle/                      # Gradle wrapper configuration
├── assets/                          # Static media and design assets
│   ├── fonts/                       # GoogleSans typography family
│   │   ├── GoogleSans-Bold.ttf
│   │   ├── GoogleSans-Medium.ttf
│   │   └── GoogleSans-Regular.ttf
│   ├── images/                      # Character card asset directories (922+ WebP files)
│   │   ├── attack_on_titan/         # 131 characters
│   │   ├── black_clover/            # 67 characters
│   │   ├── demon_slayer/            # 43 characters
│   │   ├── hunter_x_hunter/         # 135 characters
│   │   ├── naruto/                  # 80 characters
│   │   └── one_piece/               # 466 characters
│   ├── logos/                       # Franchise category logos and app badges
│   └── profile/                     # Developer and team avatars
├── lib/                             # Core Flutter Application Code
│   ├── core/                        # Cross-cutting concerns & foundational utilities
│   │   ├── constants/
│   │   │   └── app_constants.dart   # App names, versions, defaults & categories
│   │   ├── theme/
│   │   │   ├── app_colors.dart      # Material 3 dark/light color palette tokens
│   │   │   └── app_theme.dart       # ThemeData configurations & surfaces
│   │   └── utils/
│   │       ├── asset_loader.dart    # Unicode NFC asset resolution
│   │       └── url_helper.dart      # Browser launcher helper
│   ├── data/                        # Data sources & concrete repositories
│   │   ├── datasources/
│   │   │   ├── asset_manifest_data_source.dart # Static manifest reader
│   │   │   └── package_info_data_source.dart   # Local bundle info reader
│   │   └── repositories/
│   │       ├── app_info_repository_impl.dart   # Implementation of app metadata
│   │       └── category_repository_impl.dart   # Implementation of category loader
│   ├── domain/                      # Pure business logic & entities
│   │   ├── models/
│   │   │   ├── category.dart        # GameCategory model
│   │   │   ├── character_algorithm.dart # Algorithm enum (Fair vs Random)
│   │   │   ├── developer_info.dart  # Team contributor entity
│   │   │   ├── game_info_tab.dart   # Tabbed dialog enum
│   │   │   ├── game_state.dart      # Immutable GameRoundState
│   │   │   ├── remote_version.dart  # version.json parser & ABI resolver
│   │   │   ├── sem_ver.dart         # Semantic version comparator
│   │   │   ├── update_decision.dart # Sealed update decision types
│   │   │   └── update_state.dart    # Live download & patch state
│   │   ├── repositories/
│   │   │   ├── i_app_info_repository.dart
│   │   │   └── i_category_repository.dart
│   │   └── use_cases/
│   │       └── select_character_use_case.dart # Shuffling and random selection logic
│   ├── presentation/                # UI Layer
│   │   ├── controllers/             # Riverpod StateNotifiers
│   │   │   ├── app_version_controller.dart
│   │   │   ├── category_controller.dart
│   │   │   ├── game_controller.dart
│   │   │   ├── game_settings_controller.dart
│   │   │   ├── theme_controller.dart
│   │   │   └── update_controller.dart
│   │   ├── dialogs/
│   │   │   └── info/                # Multi-tab Game Center dialog
│   │   │       ├── game_info_dialog.dart
│   │   │       ├── tabs/            # Settings, How to Play, About, Developers
│   │   │       └── widgets/         # Section cards, badges, chat bubbles
│   │   ├── screens/
│   │   │   ├── categories/          # Franchise grid screen
│   │   │   ├── game/                # Main suspense & duel screen
│   │   │   └── splash/              # Fast initialization screen
│   │   └── widgets/
│   │       ├── animations/          # 3D scale card, countdown, mystery box
│   │       └── common/              # Glass icon buttons, logo buttons
│   ├── services/                    # Background infrastructure services
│   │   ├── ota_installer_service.dart   # Dio APK downloader & installer
│   │   ├── shorebird_patch_service.dart # Shorebird code push manager
│   │   └── version_service.dart         # Version comparison & ABI engine
│   ├── assets_manifest.dart         # High-speed static asset catalog
│   └── main.dart                    # App entrypoint with ProviderScope
├── scripts/                         # Python & Bash Automation Suite
│   ├── audit_assets.py              # Health, casing & broken asset scanner
│   ├── build_app.py                 # Multi-target build runner & checksums
│   ├── character_stats.py           # Levenshtein typo finder & data exporter
│   ├── convert_and_optimize.py      # Batch WebP compressor & EXIF stripper
│   ├── generate_manifest.py         # Static manifest generator & pubspec sync
│   ├── menu.py                      # Interactive CLI terminal menu
│   ├── normalize_filenames.py       # Filename cleaner & Unicode NFC normalizer
│   ├── release.py                   # Automated release & GitHub publisher
│   ├── run.sh                       # Quick bash launcher
│   └── update_version.sh            # Synchronized version bumper
├── test/                            # Comprehensive Automated Test Suite
│   ├── clean_architecture_test.dart # Unit & widget tests for Clean Architecture
│   └── widget_test.dart             # UI rendering & interaction tests
├── web/                             # Web platform assets and index.html
├── pubspec.yaml                     # Dependencies, assets & fonts config
├── shorebird.yaml                   # Shorebird OTA Code Push configuration
├── version.json                     # Live remote update manifest
├── PROJECT_DETAILS.md               # Master technical dossier (this file)
└── README.md                        # Public GitHub repository overview
```

---

## 11. Testing, Quality Assurance & Verification

BiGuess maintains strict quality standards through automated unit testing, widget testing, and asset verification scripts:

### 🧪 Automated Test Suite (`test/clean_architecture_test.dart`)
- **Domain & Model Tests:**
  - `GameCategory` serialization, deserialization, and value equality.
  - `GameRoundState` immutability and `copyWith` state transitions.
  - `SemVer` comparison logic (major, minor, patch, build number, `isNewerMajorOrMinorThan`).
  - `RemoteVersion` parsing and ABI-specific APK URL resolution (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
- **Use Case & Repository Tests:**
  - `SelectCharacterUseCase` verification for `pureRandom` and `fairNonRepeating` deck exhaustion.
  - `CategoryRepositoryImpl` category count calculation and asset path querying.
- **Controller & StateNotifier Tests:**
  - `GameSettingsController` toggle mutations and defaults.
  - `ThemeController` mode changes (Light, Dark, System).
  - `GameController` full round lifecycle (countdown ticks, reveal, reset).
- **Widget Integration Tests:**
  - `GameInfoDialog` tab switching (`SettingsTab`, `HowToPlayTab`, `AboutGameTab`, `DevelopersTab`).
  - `GameEmptyState` and `GameAppBar` rendering under ProviderScope.

### 🛡️ Running Tests & Static Analysis
```bash
# Run static analysis
flutter analyze

# Execute all unit and widget tests
flutter test

# Run asset integrity audit
python3 scripts/audit_assets.py

# Check manifest synchronization
python3 scripts/generate_manifest.py --check
```

---

## 12. Build, Deployment & Packaging Guide

### 📱 Android Native Builds

#### Split APKs by CPU Architecture (Default & Exclusive APK Format)
Produces optimized, smaller APKs (~15 MB each) matching specific device chips:
```bash
flutter build apk --release --split-per-abi
```
Generated artifacts in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (Modern 64-bit Android devices)
- `app-armeabi-v7a-release.apk` (Legacy 32-bit Android devices)
- `app-x86_64-release.apk` (Android emulators / Intel devices)

#### Android App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```

---

### 🌐 Web Release Build
```bash
flutter build web --release
```

---

### 🕊️ Shorebird OTA Code Push Deployment

#### 1. Initialize Binary Release on Shorebird
```bash
shorebird release android
```

#### 2. Push Instant Hot-Patch (No APK Reinstall Required)
```bash
shorebird patch android
```

---

### 🚀 Automated 1-Command Release Pipeline
Using the built-in release tool:
```bash
# Release a patch update (e.g. 0.31.0 -> 0.31.1)
python3 scripts/release.py --bump patch --split-apk --push

# Release a minor update (e.g. 0.31.0 -> 0.32.0)
python3 scripts/release.py --bump minor --split-apk --push
```

---

## 13. Team, Roles & Credits

<table align="center">
  <tr>
    <td align="center" width="50%">
      <a href="https://saoudi.online">
        <img src="assets/profile/abderrahmane_saoudi.webp" width="110px;" alt="Abderrahmane SAOUDI" style="border-radius: 50%; box-shadow: 0 4px 12px rgba(0,0,0,0.15);" onerror="this.src='https://github.com/AbderrahmaneSAOUDI.png'"/>
        <br /><br />
        <b>Abderrahmane SAOUDI</b>
      </a>
      <br />
      <sub>Lead Developer & UI/UX Designer</sub>
      <br /><br />
      <i>Flutter architecture, Riverpod state engine, Clean Architecture refactoring, hybrid OTA update pipeline, custom animations, and Python automation suite.</i>
      <br /><br />
      <a href="https://saoudi.online">🌐 saoudi.online</a> •
      <a href="https://github.com/AbderrahmaneSAOUDI">🐙 GitHub</a> •
      <a href="mailto:saoudi.dev@gmail.com">✉️ Email</a>
    </td>
    <td align="center" width="50%">
      <a href="mailto:anas.djribie@gmail.com">
        <img src="assets/profile/anas_oussama_djebie.webp" width="110px;" alt="Anas Oussama DJRIBIE" style="border-radius: 50%; box-shadow: 0 4px 12px rgba(0,0,0,0.15);" onerror="this.src='https://ui-avatars.com/api/?name=Anas+Djribie&background=6750A4&color=fff'"/>
        <br /><br />
        <b>Anas Oussama DJRIBIE</b>
      </a>
      <br />
      <sub>Data Collector & QA Tester</sub>
      <br /><br />
      <i>Anime character dataset curation, high-resolution WebP asset acquisition, naming standardizations, bilingual cataloging, and gameplay quality assurance.</i>
      <br /><br />
      <a href="mailto:anas.djribie@gmail.com">✉️ anas.djribie@gmail.com</a>
    </td>
  </tr>
</table>

### 🌟 Special Acknowledgments
- **Anime Fans & Playtesters:** For countless rounds of testing, trivia feedback, and character balance suggestions.
- **Flutter & Riverpod Teams:** For delivering a world-class cross-platform declarative framework.
- **Shorebird Team:** For enabling instant over-the-air code push capabilities on Flutter.

---

<div align="center">
  <sub>Document generated for <b>BiGuess Game</b> • Maintained by <a href="https://saoudi.online">Abderrahmane SAOUDI</a> • Licensed under MIT</sub>
</div>
