# BiGuess: Current Architecture Audit & Product Blueprint Alignment

This document answers the twelve core architectural questions regarding the current state of BiGuess compared directly against the requirements of the BiGuess Product Blueprint.

---

### 1. How a game currently starts

* **Current Implementation:**
  * The application launches with an animated splash screen featuring a 3D logo flip, particle effects, and staggered title animations.
  * During the splash sequence, the app runs a network check against a remote version file and checks Shorebird for over-the-air code patches.
  * If the check completes or is skipped, the user is navigated to the Categories screen.
  * The Categories screen presents a two-column grid showing eighteen anime categories.
  * The user taps a category card, which opens the Game screen for that specific franchise.
  * The Game screen loads in an idle state displaying a closed Mystery Box in the center. The identity is not yet visible.
  * The user taps the Mystery Box to initiate the round.
  * An animated countdown timer runs for a preset duration (defaulting to two seconds, but configurable to two, three, five, or ten seconds).
  * When the countdown reaches zero, the mystery box disappears and reveals the character image and name hint.

* **Blueprint Target:**
  * The blueprint removes startup network checks, the mystery box tap, and the countdown timer delay.
  * The target flow is immediate and streamlined: Open BiGuess → Choose Topic → Choose Pack(s) → Configure Match Settings (Difficulty and Number of Rounds) → Start Game immediately with Round 1.

---

### 2. How players are represented

* **Current Implementation:**
  * Players have zero digital representation in the application.
  * There are no user entities, player profiles, player identification numbers, login sessions, or database tables for players.
  * The concept of two players ("The Answerer" and "The Guesser") exists purely as instructional text in the How to Play guide.
  * The application runs as a standalone utility on a single device without device pairing, local networking, or session synchronization.
  * Developer profiles exist in the code for creator credits in dialogs, but these represent software authors rather than game participants.

* **Blueprint Target:**
  * This principle is preserved for the Mobile MVP.
  * The mobile game remains completely offline, accountless, and played face-to-face where each human uses their own physical phone.
  * User profiles and permissions (Owner, Admin, Collector) are restricted exclusively to the web-based BiGuess Studio CMS and do not exist in the mobile gameplay app.

---

### 3. How identities are selected

* **Current Implementation:**
  * Identity selection is handled by a character selection use case triggered when the round starts.
  * It operates on the image list of the currently selected category using one of two selectable modes:
    * **Random Mode:** Chooses an image purely at random from the entire list with replacement. Characters can repeat on back-to-back turns.
    * **Non-Repeating Mode:** Treats the images as a deck of cards, removing selected characters from a temporary remaining pool until all have appeared, then automatically reshuffling the full list.

* **Blueprint Target:**
  * The blueprint makes the non-repeating deck shuffle the permanent default behavior for all games, removing the need for an algorithm toggle in settings.
  * Before cards enter the selection pool, they are filtered by the configured difficulty level.
  * Selection operates locally on each device without coordinating pools between phones.

---

### 4. How cards/identities are represented

* **Current Implementation:**
  * There is no formal Card entity, class, or data model.
  * An identity is represented solely as a raw asset file path string pointing to an image file.
  * The character's name is not stored in data; it is extracted on the fly by splitting the path string by slashes and stripping the file extension.
  * The game state holds only the active image path string and the extracted name string.
  * There are no difficulty attributes, card IDs, category IDs, tags, or metadata attached to identities.

* **Blueprint Target:**
  * Introduces an explicit, lightweight Card model containing only:
    * Unique Identifier
    * Display Name
    * Image File Reference
    * Difficulty Level (Easy, Medium, Hard)
    * Parent Pack Reference
  * Cards are kept topic-agnostic and avoid complex semantic tags (such as powers, gender, or species) so the same structure works for sports, history, food, and animals.

---

### 5. How content is currently stored

* **Current Implementation:**
  * All content is bundled directly inside the application installation package as static image files.
  * Images are stored in local folders separated by category.
  * A generated manifest file in the code maps each category title to its list of file paths.
  * Category names, folder paths, and logo references are hardcoded directly into application constants in Dart code.
  * There is no local database (such as SQLite), and there is no mechanism to download or update packs dynamically.

* **Blueprint Target:**
  * Content is decoupled from the application binary.
  * Metadata is stored locally in an embedded relational SQL database (SQLite) containing topics, packs, and cards.
  * Playable packs are distributed as downloadable packages from cloud storage and unpacked into private application storage.
  * Downloaded images are stored in protected internal app storage to discourage trivial scraping and prevent cluttering the user's gallery.

---

### 6. How images are loaded

* **Current Implementation:**
  * Images are loaded directly from the compiled app bundle using standard Flutter asset image widgets.
  * When opening the game screen, the first five images of the selected category are pre-cached in memory to improve responsiveness.
  * Images are displayed inside a dedicated container with rounded corners and subtle drop shadows.

* **Blueprint Target:**
  * Images will be loaded locally from device file storage or decrypted byte buffers rather than compiled app assets.
  * Caching and memory-bounded decoding will ensure smooth rendering during long sessions without excessive memory consumption.

---

### 7. How difficulty currently works, if applicable

* **Current Implementation:**
  * Difficulty does not exist in the current application.
  * There are no difficulty levels, tags, filters, or settings.
  * Every character in a category has the exact same probability of being selected, whether they are main protagonists or obscure background characters.

* **Blueprint Target:**
  * Implements a cumulative three-tier difficulty system:
    * **Easy:** Highly recognizable, iconic identities.
    * **Medium:** Well-known supporting characters familiar to regular fans.
    * **Hard:** Obscure, minor, or specialized characters for hardcore fans.
  * Difficulty is cumulative:
    * Selecting Easy includes Easy cards only.
    * Selecting Medium includes Easy and Medium cards.
    * Selecting Hard includes Easy, Medium, and Hard cards.
  * Difficulty is selected during match configuration and remains fixed for the duration of that game.

---

### 8. How rounds currently work

* **Current Implementation:**
  * There is no round structure, round limit, or match completion state.
  * The game operates as an endless carousel:
    * The user reveals an identity.
    * The players play verbally face-to-face.
    * The player taps the refresh button at the bottom of the screen.
    * The countdown timer runs again, and a new character is revealed.
    * This repeats infinitely until the user manually exits back to the categories screen.

* **Blueprint Target:**
  * A game session has a defined number of rounds configured before starting (such as 1, 3, or 5 rounds).
  * The active screen clearly tracks progress (for example, "Round 2 of 5").
  * Players tap Next Round when their verbal duel is complete, which triggers a clean transition animation and loads the next identity.
  * When all configured rounds are finished, the app presents a Game Over screen offering a quick rematch or an exit to topics.

---

### 9. Which screens are required for gameplay

* **Current Implementation:**
  * **Splash Screen:** Displays branding animations and runs network update checks.
  * **Categories Screen:** Displays the grid of available anime franchises.
  * **Game Screen:** Shows the mystery box, countdown ticker, revealed character display, and roll button.
  * **Game Info Dialog:** A multi-tab modal for settings, game rules, app information, and developer credits.

* **Blueprint MVP Target:**
  * **Topic Selection Screen:** Allows choosing a high-level category (such as Anime, Movies, Football).
  * **Pack Selection Screen:** Allows picking single, multiple, or random packs within that topic and displays offline availability.
  * **Game Configuration Screen/Modal:** Allows setting Difficulty and Number of Rounds before starting.
  * **Active Game / Identity Screen:** An outward-facing display showing the assigned card artwork, character name, round counter, and next round control.
  * **Game Over / Completion Screen:** Summarizes the completed match and provides instant replay or exit options.
  * **Pack Catalog / Download Screen (Supporting):** For browsing remote packs, downloading them for offline use, and managing storage.
  * **Minimal Settings / About Dialog (Supporting):** For theme selection and basic application credits.

---

### 10. Which parts of the application currently depend on the network

* **Current Implementation:**
  * The application depends on the network during app launch on the splash screen:
    * Fetching the remote version manifest from GitHub to check for newer app releases.
    * Downloading full APK files through an in-app updater when updates are available.
    * Contacting Shorebird cloud servers to check for and stage over-the-air code patches.
    * Opening external developer profile links (GitHub, LinkedIn, website).
  * The actual gameplay (selecting categories, revealing characters, rolling next cards) is 100% offline because all assets are bundled locally.

* **Blueprint Target:**
  * Network operations are eliminated completely from the app launch and gameplay paths.
  * Network access is used solely for content management: browsing the remote catalog of packs, downloading new packs, and checking for pack updates.
  * Once required packs are downloaded, the entire game functions offline with zero network connectivity.

---

### 11. Which existing content must be preserved

* **Existing Assets to Preserve:**
  * **Curated Character Artwork (922 characters):** All high-quality character images across the six completed anime packs:
    * One Piece (315 characters)
    * Attack on Titan (94 characters)
    * Hunter X Hunter (89 characters)
    * Naruto (63 characters)
    * Black Clover (55 characters)
    * Demon Slayer (35 characters)
  * **Franchise Logos (22 logos):** All high-resolution logos for the active packs, planned expansion packs, and BiGuess branding.
  * **Custom Typography:** The Google Sans font family files used across the app.
  * **Design System & Visual Language:** Deep purple/violet palette, dark and light theme contrast rules, ambient radial gradients, glassmorphism app bars, and playful micro-animations.
  * **Creator Attribution:** Developer and content collector credits.
  * **Blueprint Directive:** Section 7443 explicitly requires preserving existing content during development while progressively improving attribution and metadata.

---

### 12. Which existing features are intentionally being removed from the MVP

* **Legacy App Features Being Removed:**
  * **Startup Network Update Gates:** Removing the blocking GitHub manifest check, in-app APK installer, and Shorebird patch check on launch to guarantee instant, friction-free startup.
  * **Artificial Timers & Delays:** Removing the mystery box tapping requirement and the 0s–10s countdown delay so that cards appear immediately and the phone gets out of the way.
  * **Character Name Hint Toggle:** Removing the option to hide character names; the outward screen will always show the name so opponents can identify the card without guessing confusion.
  * **Algorithm Mode Selection:** Removing the toggle between random and non-repeating modes; fair deck shuffle will be the built-in standard.
  * **Hardcoded Categories:** Replacing hardcoded category definitions with a dynamic, data-driven topic and pack structure.

* **Features Explicitly Excluded from MVP per Blueprint:**
  * **Digital Scoring & Win Detection:** No in-game score counters or winner buttons; players determine winners socially in real life.
  * **Question & Turn Tracking:** No digital logging of questions asked, answers given, or turns taken.
  * **Multiplayer Networking:** No device pairing, room codes, lobbies, matchmaking, or Bluetooth/Wi-Fi communication.
  * **Player User Accounts:** No user registration, login screens, or cloud profiles in the mobile game.
  * **Community Platform Complexity:** Community submissions, contributor rankings, XP, badges, achievements, comments, and AI-assisted card creation tools are strictly deferred to post-MVP releases.
