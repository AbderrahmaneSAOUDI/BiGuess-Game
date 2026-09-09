# Content Architecture & Download Pipeline

> Separation of game engine & content, BiGuess Studio, pack management

---

## **User:**

Move to Content Architecture

---

## **ChatGPT:**

Absolutely. Now we move to **Content Architecture**, which is one of the most important parts of the new BiGuess design.

The key is to keep it **simple enough for the MVP**, while making sure the architecture can later support BiGuess Studio and community content without forcing us to redesign everything.

# Content Architecture

## Content Architecture

### 1. Purpose

BiGuess separates **game logic** from **game content**.

The game engine should not contain individual identities, topics, packs, or hardcoded content.

Instead, content is managed independently and delivered to the application as downloadable Packs.

This allows BiGuess to grow from a small initial collection into a large content library without increasing the size of the base application significantly.

The core relationship is:

```text
Topic
  └── Pack
       └── Cards
```

---

### 2. Content Hierarchy

BiGuess uses three content levels:

#### Topic

A Topic is a non-playable organizational category.

Examples:

```text
Anime
Football
Movies
Countries
Food
History
Science
```

A Topic:

- cannot be played directly;
- cannot be downloaded as a whole;
- contains multiple Packs;
- is used to organize the content library.

A Game uses exactly one Topic.

---

#### Pack

A Pack is the main playable and downloadable content unit.

Every Pack belongs to exactly one Topic.

Examples:

```text
Anime
├── Naruto
├── One Piece
├── Dragon Ball
└── Demon Slayer
```

A Pack:

- belongs to one Topic;
- contains Cards;
- can be downloaded;
- can be played offline after downloading;
- must contain at least two Cards to be playable.

The Pack is the primary unit used for content distribution.

---

#### Card

A Card is one playable identity.

For the MVP, the Card contains only:

- Name
- Image
- Difficulty
- Pack relationship

No topic-specific attributes are required.

The same Card structure must work for every type of content supported by BiGuess.

Examples:

```text
Naruto Uzumaki
Lionel Messi
Japan
Pizza
Albert Einstein
```

All are simply Cards from the perspective of the game engine.

---

### 3. Content Model

The conceptual content model is:

```text
Topic
├── id
├── name
└── packs[]

Pack
├── id
├── name
├── topicId
└── cards[]

Card
├── id
├── name
├── image
├── difficulty
└── packId
```

The exact database/document representation will be defined later in the Technical Architecture section.

---

### 4. Card Difficulty

Card difficulty uses three internal numeric levels:

```text
1 = Easy
2 = Medium
3 = Hard
```

The difficulty is cumulative when selecting content:

```text
Selected = Easy
→ Difficulty 1

Selected = Medium
→ Difficulty 1 + 2

Selected = Hard
→ Difficulty 1 + 2 + 3
```

Therefore the effective rule is:

```text
card.difficulty <= selectedDifficulty
```

Difficulty is content metadata and is assigned to Cards during content creation/management.

The game engine does not need to understand why a Card is considered difficult.

---

### 5. Images

Images are part of the Card content.

Images should be optimized for mobile gameplay before distribution.

The content system should avoid shipping unnecessarily large original assets when a smaller optimized image provides the same gameplay experience.

The application should be able to display downloaded images quickly and reliably while offline.

The exact image formats, resolutions, compression settings, and processing pipeline will be defined in the Technical Architecture and Content Studio sections.

---

### 6. Content Distribution

Content is distributed independently from the BiGuess application itself.

The application contains the:

- game engine;
- UI;
- gameplay logic;
- content discovery interface;
- download system;
- local content system.

The remote content system contains:

- Topics;
- Packs;
- Cards;
- images;
- content metadata.

Conceptually:

```text
                    BiGuess
                       │
                 Content Catalog
                       │
              ┌────────┴────────┐
              │                 │
            Topic              Topic
              │                 │
            Packs             Packs
              │
            Cards
              │
            Images
```

The base application therefore does not need to contain the entire content library.

---

### 7. Download Model

Users download Packs rather than individual Cards.

Example:

```text
User
 ↓
Anime
 ↓
One Piece
 ↓
Download Pack
 ↓
All required Pack content is cached locally
 ↓
Available Offline
```

The application should not normally fetch one image at a time during gameplay.

This is intentionally avoided because it would:

- make gameplay dependent on network availability;
- introduce latency;
- increase remote requests;
- increase infrastructure usage;
- make the offline experience unreliable.

Once a Pack is downloaded, gameplay should use the local copy.

---

### 8. Local Content

Downloaded content is stored inside BiGuess's private application storage/cache.

It should not be exposed to the user as a normal collection of image files.

Conceptually:

```text
BiGuess Private Storage
│
├── Local Content Database
│
├── Pack Data
│
└── Protected Image Assets
```

Downloaded content should use an encrypted/protected representation to discourage casual extraction and data scraping.

The protection system is intended to make raw content difficult to access directly, not to provide absolute DRM.

---

### 9. Content Availability

A Pack has a local availability state.

Conceptually:

```text
Not Downloaded
      ↓
Downloading
      ↓
Downloaded
      ↓
Available Offline
```

If the remote content changes, the local Pack can become eligible for an update.

The application should compare local and remote content information and download only the content that is missing or has changed.

Users should not need to manage content versions manually.

---

### 10. Content Updates

BiGuess should avoid forcing users to repeatedly download complete Packs when only a small amount of content has changed.

For example:

```text
Local Pack
100 Cards

Remote Pack
105 Cards
```

The application should be able to determine that only the additional/changed content needs to be downloaded.

Similarly, if an existing Card's image changes, the application should update that asset rather than unnecessarily downloading the entire Pack again.

The implementation may use internal fingerprints, hashes, timestamps, or other mechanisms to efficiently determine what has changed.

These mechanisms are implementation details and should not become a user-facing version-management system.

---

### 11. Content Catalog

The application needs a lightweight remote catalog that allows it to know what content exists before downloading it.

The catalog should provide enough information to display:

- available Topics;
- available Packs;
- Pack names;
- Pack relationships;
- Card counts;
- download status;
- content update information;
- required metadata.

The catalog should be lightweight and should not require downloading complete Card data just to browse available Packs.

The application should download full Pack content only when the user chooses to use that Pack.

---

### 12. Offline-First Gameplay

Once the necessary Packs are downloaded:

```text
Internet
   ✕
   │
   ▼
BiGuess
   │
   ├── Local Topic information
   ├── Local Pack information
   ├── Local Cards
   └── Local Images
           │
           ▼
       Play Offline
```

The gameplay layer should not depend on remote reads.

Network access is primarily required for:

- discovering content;
- downloading Packs;
- checking for content changes;
- updating local content.

The actual game should operate from local data.

---

### 13. Pack Size and Application Size

The BiGuess application itself should remain relatively small.

Content is intentionally separated from the application binary.

This allows:

```text
Small App
+
Downloaded Content
=
Large Content Library
```

The application does not need to grow significantly when new Packs are published.

A player can choose which Packs to keep locally based on their interests and available device storage.

This also supports the long-term goal of allowing BiGuess to contain a very large content library without forcing every player to download everything.

---

### 14. Content Management

Content is not hardcoded into the Flutter application.

Instead, content is managed externally through **BiGuess Studio**.

For the MVP, BiGuess Studio is intended for:

- administrators;
- data collectors;
- content management;
- creating Topics;
- creating Packs;
- adding Cards;
- uploading images;
- assigning difficulty;
- reviewing and managing content.

The initial Studio does not need to expose community publishing.

---

### 15. BiGuess Studio

The intended content pipeline is:

```text
Content Creator / Data Collector
             ↓
       BiGuess Studio
             ↓
      Create / Edit Content
             ↓
         Review
             ↓
          Publish
             ↓
      Remote Content System
             ↓
        BiGuess App
             ↓
       User Downloads Pack
             ↓
          Play Offline
```

This allows the mobile application and content creation process to evolve independently.

---

### 16. Community Content

Community-created content is **not part of the MVP**.

However, the content architecture should leave room for it.

The future pipeline may become:

```text
Community Creator
       ↓
Content Submission
       ↓
BiGuess Studio
       ↓
Review
   ┌───┴───┐
 Accept   Reject
   │
   ↓
Publish
   ↓
BiGuess Content Catalog
   ↓
Users
```

The MVP should not implement the complexity of community accounts, moderation, reputation, reporting, public submissions, or creator management unless required.

The architecture should simply avoid making these future capabilities impossible.

---

### 17. Content Ownership

For the MVP, content managed through BiGuess Studio is considered controlled BiGuess content.

Content should have enough internal metadata to identify where it came from and allow Studio administrators to manage it.

Future community content may require additional information such as:

- creator;
- submission status;
- approval status;
- ownership/licensing information.

These fields should not be required for the MVP unless they become necessary for the actual content workflow.

---

### 18. Content and Game Separation

The game engine must remain independent from the meaning of individual Cards.

For example, the game engine should not contain logic such as:

```text
if card is football player...
if card is anime character...
if card is country...
```

Instead:

```text
Game Engine
     ↓
Card
     ├── Name
     ├── Image
     └── Difficulty
```

The content defines what the Card represents.

The game engine only needs to know how to select and display it.

This allows new Topics to be added without modifying the gameplay system.

---

### 19. MVP Content Principles

The MVP content architecture follows these principles:

1. **Topic organizes Packs.**
2. **Pack is the downloadable/playable unit.**
3. **Card is the playable identity.**
4. **A Pack belongs to exactly one Topic.**
5. **A Game uses exactly one Topic.**
6. **Cards contain only the metadata necessary for MVP gameplay.**
7. **Difficulty is represented as 1, 2, or 3.**
8. **Content is separate from the application binary.**
9. **Downloaded Packs are playable offline.**
10. **Gameplay should not fetch individual images from the network.**
11. **Downloaded content is stored privately and protected against casual extraction.**
12. **Updates should download only missing or changed content.**
13. **BiGuess Studio manages the initial content ecosystem.**
14. **Community content is a future capability, not an MVP requirement.**

### One important architectural decision I'd make now

I would **not yet choose Firestore vs Cloudflare R2 vs another storage/database** in this section.

We know what the system needs:

**Catalog → Pack metadata → Card metadata → image assets → local cache → synchronization.**

The next step should be to examine the actual workloads and then choose the cheapest/simple architecture that satisfies them.

And there is one particularly important thing we should solve before choosing the backend: **what exactly gets downloaded when a player downloads a Pack**. If we get that right, we can drastically reduce reads and bandwidth—and that's directly connected to your free-tier goal.

---

