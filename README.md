<div align="center">

  <img src="assets/logos/biguess-icon.webp" alt="BiGuess Logo" width="120" height="120" style="border-radius: 24px; margin-bottom: 12px;" />

  # 🎮 BiGuess

  **The Ultimate Face-to-Face 2-Player Anime & Character Guessing Game**

  [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-00B4D8?style=for-the-badge)](https://riverpod.dev)
  [![Material 3](https://img.shields.io/badge/UI-Material%203-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
  [![Platforms](https://img.shields.io/badge/Platforms-Android%20|%20Web-4CAF50?style=for-the-badge)](https://flutter.dev/multi-platform)
  [![Version](https://img.shields.io/badge/Version-v0.25.0-orange?style=for-the-badge)](pubspec.yaml)

  <p align="center">
    <a href="#-about-biguess">About</a> •
    <a href="#-how-to-play">How to Play</a> •
    <a href="#-key-features">Key Features</a> •
    <a href="#-categories">Categories</a> •
    <a href="#%EF%B8%8F-game-algorithms--settings">Settings</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#-team--credits">Team & Credits</a>
  </p>

</div>

---

## 📖 About BiGuess

**BiGuess** is an interactive, fast-paced two-player social party game that merges the classic deduction mechanics of *"20 Questions"* with rich anime and pop-culture character universes. 

Designed specifically for face-to-face play, gatherings, anime conventions, and tech community events, BiGuess turns quick wits, strategic questioning, and deep franchise trivia into moments of laughter, suspense, and friendly competition.

> **💡 The Story Behind BiGuess:**  
> BiGuess was crafted to break the ice and bring people together offline through seamless mobile gaming and fast-paced 2-player character duels.

---

## 🕹️ How to Play

Playing BiGuess requires **two players** and **one or two phones** sitting opposite each other.

```
       [ PLAYER 1: The Answerer ]
       (Knows character & answers)
                  ▲
                  │  "Is your character a villain?"
                  │  "No!"
                  ▼
       [ PLAYER 2: The Guesser ]
     (Asks Yes/No questions to deduce)
```

### 🎯 Step-by-Step Round

1. **Pick a Category:** Choose a shared favorite franchise from the 18 available universes.
2. **Hit "Random":** The answerer taps the primary action button to trigger an animated countdown timer (0s - 5s).
3. **Secret Reveal:** A character card is revealed onto the answerer's screen.
4. **The Interrogation:** The guesser asks **Yes/No questions** (*e.g., "Do they possess Titan powers?", "Are they a Devil Fruit user?"*).
5. **Deduce & Victory:** The guesser narrows down the possibilities until they make their final guess!
6. **Switch Roles:** Rotate turns and keep score!

### 📜 Game Rules
- ⚖️ **Yes/No Only:** All questions asked by the guesser must be strictly answerable with "Yes", "No", or "Unknown/Irrelevant".
- 🤝 **Honesty First:** The answerer must answer truthfully according to canon lore.
- 🙈 **No Peeking:** The guesser must never peek at the answerer's screen during the roll or countdown.

---

## ✨ Key Features

- 🎭 **18 Curated Anime Franchises:** Massive roster of characters featuring custom logos, optimized WebP artwork, and clean metadata.
- 🎲 **Smart Randomization Engines:**
  - **Non-Repeating (Fair Shuffle):** Cycles through the entire roster without repeats until all characters have been played.
  - **Pure Random:** Classic pseudo-random generator for unpredictable rolls.
- ⏱️ **Customizable Suspense Countdown:** Fine-tune suspense timing from **0s (instant), 1s, 2s, 3s, up to 5 seconds**.
- 🌓 **Dynamic Theme Engine:** Seamless switching between Dark Mode and Light Mode with Material 3 tokens.
- ✨ **Fluid Micro-Animations:** Staggered list animations, 3D interactive scale cards, mystery box reveals, and tap-punch feedback powered by `flutter_staggered_animations`.
- 🎛️ **Comprehensive In-App Game Center:** Built-in modal dialog featuring live settings, rules explanation, about page, and team credits.
- 📱 **Cross-Platform Support:** Ready to run natively on Android and the Web.

---

## 🎭 Categories

BiGuess includes **18 rich anime universes** with hundreds of characters:

| Franchise | Category | Artwork Status |
| :--- | :---: | :---: |
| ⚔️ **Attack on Titan** | `attack_on_titan` | ✅ High-Res Asset Pack |
| 🍀 **Black Clover** | `black_clover` | ✅ High-Res Asset Pack |
| 🗡️ **Demon Slayer** | `demon_slayer` | ✅ High-Res Asset Pack |
| 🎣 **Hunter X Hunter** | `hunter_x_hunter` | ✅ High-Res Asset Pack |
| 🍥 **Naruto** | `naruto` | ✅ High-Res Asset Pack |
| 🏴‍☠️ **One Piece** | `one_piece` | ✅ High-Res Asset Pack |
| 🌸 **Bleach** | `bleach` | 🚀 Active Expansion |
| 👁️ **Code Geass** | `code_geass` | 🚀 Active Expansion |
| 📓 **Death Note** | `death_note` | 🚀 Active Expansion |
| 🔍 **Detective Conan** | `detective_conan` | 🚀 Active Expansion |
| 🧪 **Dr. Stone** | `dr_stone` | 🚀 Active Expansion |
| 🐉 **Dragon Ball Z** | `dragon_ball_z` | 🚀 Active Expansion |
| ⚗️ **FMAB** | `fmab` | 🚀 Active Expansion |
| 🧿 **Jujutsu Kaisen** | `jujutsu_kaisen` | 🚀 Active Expansion |
| 💥 **My Hero Academia** | `my_hero_academia` | 🚀 Active Expansion |
| 🗡️ **Solo Leveling** | `solo_leveling` | 🚀 Active Expansion |
| ⏳ **Tokyo Revengers** | `tokyo_revengers` | 🚀 Active Expansion |
| ⛵ **Vinland Saga** | `vinland_saga` | 🚀 Active Expansion |

---

## ⚙️ Game Algorithms & Settings

BiGuess offers in-depth gameplay customization accessible via the **Settings (⚙️)** menu:

| Setting | Options | Description |
| :--- | :--- | :--- |
| **Character Algorithm** | `Non-Repeating` / `Random` | Choose between deck-shuffled non-repeating character selection or pure independent random selection. |
| **Countdown Timer** | `0s`, `1s`, `2s`, `3s`, `5s` | Controls anticipation duration before revealing the character. |
| **Character Hint** | `Enabled` / `Disabled` | Toggle displaying character name labels for players who may not immediately recognize an image. |
| **Theme Mode** | `System` / `Light` / `Dark` | Adaptive Material 3 theme mode with custom elevation styling. |

---

## 🛠️ Tech Stack & Architecture

BiGuess is built with modern, declarative Flutter best practices:

- **Framework:** [Flutter](https://flutter.dev) (SDK `^3.0.0`)
- **Language:** [Dart](https://dart.dev)
- **State Management:** [Riverpod 2.x](https://riverpod.dev) (`flutter_riverpod`)
- **Animation System:** `flutter_staggered_animations`, Custom Ticker controllers & Matrix4 transforms
- **System & Device:** `path_provider`, `url_launcher`, `package_info_plus`, `device_info_plus`

### 📁 Project Structure

```text
BiGuess-Game/
├── assets/
│   ├── fonts/               # GoogleSans typography suite
│   ├── images/              # Anime character asset catalogs (WebP)
│   ├── logos/               # Category logos & app icons
│   └── profile/             # Developer profile media
├── lib/
│   ├── main.dart            # App entrypoint & ProviderScope
│   ├── assets_manifest.dart # High-performance static asset registry
│   ├── providers/           # Riverpod state notifiers (Theme, Game, Algo)
│   ├── screens/
│   │   ├── categories_screen.dart # Franchise selection grid
│   │   └── game_screen.dart       # Main gameplay & countdown arena
│   ├── utils/               # Asset loader & runtime helpers
│   └── widgets/
│       ├── animations/      # Character card, countdown & mystery box FX
│       └── info_dialog.dart # Multi-tab settings, rules & team dialog
└── pubspec.yaml             # Dependencies, assets & launcher configuration
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code with Flutter extension
- An Android device, emulator, or modern web browser

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AbderrahmaneSAOUDI/BiGuess-Game.git
   cd BiGuess-Game
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### 📦 Building Release Packages

- **Android APK:**
  ```bash
  flutter build apk --release --split-per-abi
  ```
- **Android App Bundle (Google Play):**
  ```bash
  flutter build appbundle --release
  ```
- **Web:**
  ```bash
  flutter build web --release
  ```

---

## 👥 Team & Credits

<table>
  <tr>
    <td align="center" width="50%">
      <a href="https://saoudi.online">
        <img src="assets/profile/abderrahmane_saoudi.webp" width="100px;" alt="Abderrahmane SAOUDI" style="border-radius: 50%;" onerror="this.src='https://github.com/AbderrahmaneSAOUDI.png'"/>
        <br />
        <sub><b>Abderrahmane SAOUDI</b></sub>
      </a>
      <br />
      <sub>Lead Developer & UI/UX Designer</sub>
      <br />
      <a href="https://saoudi.online">🌐 Website</a> •
      <a href="https://github.com/AbderrahmaneSAOUDI">🐙 GitHub</a> •
      <a href="mailto:saoudi.dev@gmail.com">✉️ Email</a>
    </td>
    <td align="center" width="50%">
      <a href="mailto:anas.djribie@gmail.com">
        <img src="assets/profile/anas_oussama_djebie.webp" width="100px;" alt="Anas Oussama DJRIBIE" style="border-radius: 50%;" onerror="this.src='https://ui-avatars.com/api/?name=Anas+Djribie&background=6750A4&color=fff'"/>
        <br />
        <sub><b>Anas Oussama DJRIBIE</b></sub>
      </a>
      <br />
      <sub>Data Collector & QA Tester</sub>
      <br />
      <sub>Curated datasets, naming conventions & playtesting</sub>
      <br />
      <a href="mailto:anas.djribie@gmail.com">✉️ Email</a>
    </td>
  </tr>
</table>

### 🌟 Special Thanks
- **Open-source community & anime fans** — For the continuous inspiration, feedback, and playtesting support.

---

## 🤝 Contributing

Contributions, new anime categories, character submissions, and bug fixes are very welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the repository for details.

<div align="center">
  <sub>Crafted with ❤️ by <a href="https://saoudi.online">Abderrahmane SAOUDI</a> and the BiGuess Community.</sub>
</div>