# BiGuess Product Blueprint

## 1. Big Idea

BiGuess is an offline-first, face-to-face party game where two or more players sit together, choose a topic, and each receive a hidden identity on their own phone.

Each player turns their screen outward so everyone except themselves can see their identity. Players then take turns asking the group quick **Yes or No** questions about their own hidden identity, using the answers to deduce who or what they are.

The first player to correctly identify their identity wins the round.

The phones are not the game itself. They are a tool that removes the preparation and randomization required by traditional physical guessing games.

Instead of printing images, preparing cards, assigning identities manually, or carrying physical materials, BiGuess handles those parts digitally while leaving the actual game to the people sitting together.

### Core Concept

> **BiGuess uses technology to remove the friction around a social game while deliberately leaving the social game itself to the people.**

The application prepares the game.

The players play the game.

---

## 2. Product Vision

BiGuess exists to make spontaneous face-to-face guessing games effortless.

A group should be able to sit together, choose something they all enjoy, and begin playing within seconds without needing to prepare physical cards or depend on an internet connection during gameplay once the required content has been downloaded.

Technology should be used only where it provides clear value:

- selecting content;
- randomizing identities;
- managing game settings;
- organizing a large content library;
- downloading and updating content;
- making new topics and packs easily accessible.

The conversation itself remains human.

Players look at each other, ask questions, listen to answers, make guesses, argue about interpretations, laugh, and enjoy the reactions happening around them.

### Product Identity

BiGuess is:

> **An offline-first social game with an online, expandable content ecosystem.**

Gameplay is offline.

Content can evolve online.

The application itself should remain a facilitator rather than becoming the center of the social experience.

---

# 3. Product Principles

## 3.1 Real Life Comes First

BiGuess exists to improve face-to-face interaction, not replace it.

The players, their questions, reactions, arguments, jokes, guesses, and laughter are the actual game.

The phone is only the facilitator.

Every feature should be evaluated against:

> **Does this make the real-world experience better, or does it unnecessarily make players interact with their phones?**

If a feature makes the phone more important than the people, it requires strong justification.

---

## 3.2 The Phone Should Get Out of the Way

After identities are assigned and displayed, BiGuess should require very little interaction.

Players should be able to:

1. Receive an identity.
2. Turn their phone outward.
3. Ask questions.
4. Listen to the group.
5. Think.
6. Guess.

The application should not require players to record every question, record every answer, or continuously operate the application during the round.

The conversation itself is the game.

---

## 3.3 Offline-First Gameplay

The core gameplay should work without an internet connection **once the required content has been downloaded**.

Internet access is required when the player needs content that is not already available locally.

The intended flow is:

> **Connect → Discover/Download content → Disconnect → Play offline**

If a player wants to play another topic or pack that has not been downloaded, they reconnect, download the required content, and can then play that content offline.

Downloaded content should remain playable offline until the player removes it.

The core gameplay should not require:

- accounts;
- login;
- real-time synchronization;
- cloud database access;
- server availability;
- continuous internet connectivity.

---

## 3.4 Humans Control the Game

BiGuess should facilitate the rules rather than attempt to police real-world gameplay.

The application cannot and should not attempt to determine:

- whether somebody accidentally saw their identity;
- whether somebody intentionally cheated;
- whether the group can recognize an identity;
- how a player holds their phone;
- whether a phone is held in the hand or placed on a table;
- whether somebody gives a truthful answer;
- whether somebody gives a misleading answer;
- whether a guess is accepted by the group;
- whether two players claim a win simultaneously;
- whether the group agrees with an interpretation.

These are social and physical aspects of the game.

> **The group is responsible for how the game is played in the real world.**

BiGuess provides the game material and tools; the players control the physical rules.

---

## 3.5 Zero Unnecessary Friction

Starting a game should be fast and understandable.

The ideal experience should approach:

> **Open → Choose → Prepare → Play**

Players should not need:

- account creation;
- room codes;
- invitations;
- matchmaking;
- complicated setup;
- unnecessary confirmations;
- network waiting when the required content is already downloaded.

Optional settings may exist, but the default experience should remain simple.

---

## 3.6 Randomness Should Feel Fair

Randomization is one of BiGuess's core responsibilities.

The application should provide reliable random selection while avoiding unnecessary repetition within the same game/session.

The goal is for BiGuess to behave more like a shuffled physical deck than an unrestricted random-number generator.

Players should not need to understand the randomization algorithm.

---

## 3.7 Content Is Part of the Game

The application is only one part of BiGuess.

The other major part is its content library.

A beautiful application with very little content will not create a strong party game.

BiGuess should therefore be designed from the beginning for a continuously expanding collection of topics, packs, and identities.

The initial content may focus on Anime, but the architecture must support many other subjects, including:

- Anime;
- Movies;
- Football;
- Countries;
- Food;
- Animals;
- Historical figures;
- Scholars;
- Science;
- Games;
- and future topics not yet defined.

---

## 3.8 Topic-Agnostic by Design

The game engine should not depend on a specific type of identity.

A card may represent:

- a fictional character;
- a football player;
- a country;
- a food;
- a movie;
- an animal;
- a historical figure;
- a scholar;
- or another type of identity.

The fundamental content structure should therefore be based on reusable concepts such as:

> **Topic → Pack → Card**

rather than being designed around Anime-specific assumptions.

---

## 3.9 Content Must Scale Independently From Code

Developers should not be required every time new content is added.

The long-term goal is for content contributors to be able to create and manage:

> Topic → Pack → Card → Image → Metadata

without modifying the game engine.

The game engine should remain relatively stable while the content library continuously grows.

---

## 3.10 Quality Over Quantity

A large content library is valuable only when its content is useful.

BiGuess should prioritize:

- recognizable identities;
- high-quality images;
- accurate metadata;
- useful difficulty classification;
- consistent presentation;
- well-organized packs;
- appropriate content.

A carefully curated pack can be better than a much larger collection of poor-quality or irrelevant cards.

---

## 3.11 Difficulty Affects Selection, Not Conversation

Difficulty should primarily determine which identities can be selected.

For example:

- **Easy:** highly recognizable identities;
- **Medium:** broader or less obvious identities;
- **Hard:** obscure or specialized identities.

Difficulty should not restrict how players communicate.

An Easy identity may still require many questions.

A Hard identity may be guessed immediately.

That variation is part of the real-life game.

---

## 3.12 Configurable Game Settings, Minimal Enforcement

BiGuess should provide settings that the application can meaningfully control.

Initial configurable settings include:

- Difficulty;
- Number of rounds;
- Single topic/pack selection;
- Multiple selected topics/packs;
- Random selection across available topics/packs.

The settings experience must remain simple and easy to understand.

BiGuess should not attempt to digitally enforce aspects of gameplay that depend on human behavior.

### Timer

A timer is **not part of the MVP**.

It should not be implemented simply because it could be useful.

The possibility of adding a timer can be reconsidered later if real players and the community demonstrate a clear demand for it.

---

## 3.13 Attractive UI and Purposeful Animation

BiGuess should have a visually attractive and playful interface.

Animations are an important part of the product experience and should not be removed merely in the name of simplicity.

Animations can make the experience more exciting during:

- topic selection;
- pack selection;
- randomization;
- identity generation;
- round transitions;
- new-round preparation;
- other important moments.

However:

> **Animations should enhance the experience without becoming the experience.**

Animations should be:

- attractive;
- smooth;
- purposeful;
- reasonably fast;
- consistent with the game's personality.

They should never create unnecessary waiting or interfere with the actual gameplay.

---

## 3.14 Cost-Conscious Infrastructure

BiGuess should minimize unnecessary recurring infrastructure costs during its early stages.

The principle is not:

> "Never pay for infrastructure."

The principle is:

> **Do not spend significant money on infrastructure before the product has demonstrated that the cost is justified.**

The architecture should prefer:

> Local computation → Local storage → Static/distributed content → Low-cost/free infrastructure → Paid infrastructure when justified

Cloud services should be introduced when they solve real problems or when usage justifies their cost.

Infrastructure costs should scale with the success and needs of the product rather than becoming a significant burden before the product has users or revenue.

---

## 3.15 Don't Build Technology for Imaginary Problems

Technical complexity must have a reason.

BiGuess should not introduce technology merely because it is technically interesting or because other applications commonly use it.

Examples:

- Firebase should not be introduced simply because BiGuess is a multiplayer game.
- Accounts should not exist unless they provide meaningful value.
- Real-time synchronization should not exist unless the product actually needs it.
- AI should not exist unless it solves a real problem.
- A backend should not exist for functionality that can be handled locally.

> **If the simplest solution works, the simplest solution wins.**

---

## 3.16 Online Content, Offline Gameplay

BiGuess should use an online content ecosystem while keeping gameplay local.

The intended architecture is:

```text
                BI GUESS
                    |
          +---------+---------+
          |                   |
      Game Engine       Content Platform
                              |
                    +---------+---------+
                    |                   |
                Metadata             Images
                    |                   |
                Database        Object Storage/CDN
                             
                              |
                        Download Pack
                              |
                              v
                     Local Device Storage
                              |
                              v
                       Offline Gameplay
```

The cloud should primarily be responsible for:

- discovering content;
- distributing content;
- updating content;
- managing community content;
- moderating submissions;
- publishing approved content.

The cloud should not be required during normal gameplay when the necessary content is already downloaded.

---

## 3.17 Content Downloads Should Be Pack-Based

BiGuess should not normally fetch one image from the server every time an identity is selected.

Instead, players should download the required content before playing.

For example:

> **One Piece**
>
> 466 cards
> 18 MB
>
> **Download**

After downloading:

> ✓ Available Offline

This reduces network dependency and unnecessary requests while making gameplay faster and more reliable.

The player can then play many rounds without network activity.

---

## 3.18 Local Content Protection

Downloaded content should not simply be stored as ordinary, easily accessible image files.

Content should be stored inside the application's private/protected storage using an appropriate packaged and/or encrypted format.

The purpose is to prevent casual extraction and make basic content scraping substantially harder.

This is not intended to make content impossible to extract.

If the application can display an image, a sufficiently determined attacker can potentially extract it through reverse engineering, memory inspection, screenshots, or other techniques.

The goal is therefore:

> **Prevent trivial content scraping rather than promise impossible protection.**

---

## 3.19 Efficient Content Updates

Users should not need to understand content versions.

When the application reconnects to the content ecosystem, it should determine whether local content differs from the currently available content and download only what is missing or changed.

The system may internally use:

- hashes;
- fingerprints;
- revisions;
- manifests;
- timestamps;
- or other mechanisms

to efficiently determine what needs to be downloaded.

These implementation details should remain invisible to normal players.

The user experience should simply be:

> **Content is up to date**

or:

> **New content available**

followed by only the necessary download.

---

## 3.20 Community-Driven Content

BiGuess should eventually support community-created content.

A separate **BiGuess Content Studio** should allow authorized contributors to create and manage:

- topics;
- packs;
- cards;
- images;
- metadata;
- difficulty;
- submissions;
- publishing status.

A future community workflow may look like:

```text
Community Creator
       |
       v
Create Pack
       |
       v
Submit
       |
       v
Moderation
       |
   +---+---+
   |       |
Accept   Reject
   |
   v
Publish
   |
   v
Available to Players
```

Community content should not automatically become public.

Content quality, inappropriate material, spam, duplication, copyright, trademarks, and other legal or moderation concerns must be considered before building a public community ecosystem.

---

## 3.21 Monetization Must Not Damage the Core Experience

BiGuess does not need to commit to a monetization model before the product has demonstrated real user demand.

Potential future models may include:

- premium content packs;
- free core content with premium packs;
- a one-time Pro purchase;
- carefully placed advertising outside active gameplay;
- premium/community-created packs;
- other models discovered through actual user behavior.

The core social experience should remain protected.

In particular, monetization should not introduce intrusive interruptions during a round or force unnecessary online requirements into the core offline gameplay.

The product should first prove that people enjoy BiGuess.

Monetization can then be designed around what players actually value.

---

# 4. User Experience

## 4.1 Core Experience

The ideal BiGuess experience is:

> **Open → Choose → Prepare → Reveal → Turn phones outward → Play**

The application handles preparation and randomization and then becomes almost invisible.

Players spend most of the session:

- looking at each other;
- asking questions;
- listening to answers;
- thinking;
- guessing;
- laughing;
- interacting.

The phone is a facilitator, not the center of attention.

---

## 4.2 Starting the Game

BiGuess requires internet access when the player needs content that has not yet been downloaded.

Once the necessary packs are downloaded, the player can start and continue playing those packs offline.

The overall lifecycle is:

```text
Open BiGuess
    |
    v
Do I have the required content?
    |
   / \
  No  Yes
  |    |
  v    v
Internet   Start
  |
  v
Download
  |
  v
Start
  |
  v
Play Offline
```

If the player later wants to play another topic or pack that is not available locally, the same process is repeated.

---

## 4.3 Choosing What to Play

The group should be able to choose content in a simple and understandable way.

BiGuess should support:

### Single Topic / Pack

Play from one selected content pool.

### Multiple Selected Topics / Packs

Combine several selected content pools.

For example:

> Naruto + One Piece + Dragon Ball

### Random Topics

Allow BiGuess to randomly select from the available compatible topics/packs.

The exact UI for these choices should prioritize speed and clarity and should be designed together with the other gameplay settings.

---

## 4.4 Difficulty

Difficulty determines which identities may be selected.

The player should be able to understand the available difficulty levels without needing documentation.

Difficulty should affect content selection rather than restrict the players' real-world conversation.

---

## 4.5 Game Rounds

The number of rounds should be configurable.

Possible choices can include a small set of easy-to-understand options such as:

- 1 round;
- 3 rounds;
- 5 rounds;
- other appropriate options to be determined during UX design.

The exact interface should be designed to make configuration fast for a group that is already sitting together and ready to play.

---

## 4.6 Receiving an Identity

When a player starts a round, BiGuess randomly assigns an identity from the selected content pool.

The player must not need to know their own identity in order to play.

The phone is then turned outward so the rest of the group can see the identity.

The physical handling of the phone is part of the real-world game and is controlled by the players.

BiGuess does not attempt to police whether a player accidentally sees or intentionally looks at their identity.

---

## 4.7 Playing the Round

Once the identities are displayed, the application should require little or no interaction.

Players take turns asking the group **Yes-or-No** questions.

Examples:

> "Am I a human?"

> "Am I from Japan?"

> "Am I a football player?"

> "Am I a villain?"

The group answers verbally.

The player uses the answers to deduce their identity.

Questions and answers do not need to be entered into the application.

---

## 4.8 Guessing

When a player believes they know their identity, they announce their guess verbally.

The group determines whether the guess is correct.

BiGuess does not need to verify the answer electronically.

The physical group remains responsible for accepting or rejecting guesses.

---

## 4.9 Winning

The default game objective is:

> **Be the first player to correctly identify your own hidden identity.**

The application does not need to digitally determine the winner.

The group determines the winner according to the real-world game.

---

## 4.10 Timer

A timer is not part of the MVP.

Normal BiGuess gameplay should not impose a time limit.

An identity may take three questions or thirty questions to discover, and both situations are valid.

A timer may be reconsidered in the future if the community demonstrates that it adds meaningful value.

---

## 4.11 Replaying

After a round finishes, players should be able to quickly start another round without navigating through unnecessary screens.

The application should make repeated play convenient.

The goal is:

> **Finish → New identities → Continue playing**

rather than:

> Finish → Results → Confirmation → Configuration → Loading → New round

unless the selected game configuration genuinely requires those steps.

---

## 4.12 Offline Content

Downloaded packs should remain available offline.

Players should clearly understand which content is available locally.

Example states:

**Not Downloaded**

> Download

**Downloaded**

> ✓ Available Offline

**Update Available**

> Update

The player should not need an internet connection to play a pack that is already downloaded.

---

## 4.13 Animations

BiGuess should use attractive animations throughout the interface where they enhance the experience.

Important moments may include:

- selecting content;
- randomizing;
- generating identities;
- transitioning into a round;
- starting a new round;
- other meaningful game transitions.

Animations must remain purposeful and reasonably fast.

The application should feel polished and playful without allowing effects to delay or interrupt gameplay.

---

## 4.14 The Identity Screen

The identity screen is a special part of the BiGuess experience.

It acts as a **digital physical card**.

Its purpose is not to provide a conventional mobile-app interface but to present the identity clearly to the other players while the owner does not see it.

The physical handling of the device remains the responsibility of the players.

The application should provide the content; the group controls how it is physically used.

---

## 4.15 UX Golden Rule

> **BiGuess should do everything necessary to prepare the game and almost nothing unnecessary once the game begins.**

The application should be fast, understandable, visually attractive, and unobtrusive.

The best outcome is not that players spend more time using BiGuess.

The best outcome is that they **start playing BiGuess quickly and then spend their time playing with each other.**

---

## Game Model

### 1. Game Structure

A BiGuess game is a temporary face-to-face game session played by two or more people, where each player uses their own phone.

A game consists of:

* One selected **Topic**
* One or more selected **Packs** belonging to that Topic
* Game settings
* One or more **Rounds**

The application manages content selection, configuration, random card assignment, and round progression.

The actual guessing, questioning, answering, winning, and other social interactions happen between the players in real life and are not controlled by the application.

---

### 2. Topic

A **Topic** is an organizational category containing multiple Packs.

Examples:

* Anime
* Football
* Movies
* Countries
* Food
* Animals
* History
* Science

Topics are **not playable and not downloadable**.

A game can use **exactly one Topic**.

A Topic contains multiple Packs, and players choose their playable content from those Packs.

Multi-topic games are intentionally not supported. Keeping a game inside one Topic limits the amount of content that needs to be available locally and keeps card selection and randomization efficient.

Structure:

```text
Topic
├── Pack
├── Pack
└── Pack
```

---

### 3. Pack

A **Pack** is the actual playable and downloadable content unit.

Every Pack belongs to **exactly one Topic**.

Example:

```text
Anime
├── Naruto
├── One Piece
├── Dragon Ball
└── Demon Slayer
```

A Pack contains two or more Cards to be considered playable.

Players must have the required Packs downloaded before they can start a game using them.

Downloaded Packs remain available for offline gameplay.

---

### 4. Card

A **Card** represents one playable identity that a player must discover.

For the MVP, a Card contains only:

* **Name**
* **Image**
* **Difficulty**
* **Pack**

No additional semantic attributes are required.

BiGuess does not attempt to store every possible property of an identity, such as:

* Is the person human?
* Is the person alive?
* Is the character a villain?
* Is the character male?
* Is the identity from a specific country?
* etc.

Such information can be discovered through the players' own knowledge, conversation, or external sources when they choose to use them.

This keeps the Card model generic and prevents the system from accumulating large numbers of attributes that are irrelevant to most content types.

The same Card model must work for all Topics, regardless of whether the identity is a person, fictional character, country, food, animal, object, or another type of content.

---

### 5. Difficulty

Card difficulty is represented internally by a numeric value:

```text
1 = Easy
2 = Medium
3 = Hard
```

Difficulty represents the maximum difficulty level available to the player.

The difficulty selection is cumulative:

| Selected Difficulty | Eligible Cards       |
| ------------------- | -------------------- |
| Easy                | Easy                 |
| Medium              | Easy + Medium        |
| Hard                | Easy + Medium + Hard |

Therefore:

```text
card.difficulty <= selectedDifficulty
```

is sufficient to determine whether a Card can be selected.

**Easy is the default difficulty.**

Difficulty is selected during Game Configuration and cannot be changed while a game is in progress.

To change it, the player must leave the current game and configure a new game.

---

### 6. Pack Selection

A player first selects exactly one Topic.

They then choose the Packs to use from that Topic.

BiGuess supports three content-selection approaches:

#### Single Pack

Play using one specific Pack.

Example:

```text
Anime → Naruto
```

#### Selected Packs

Play using multiple Packs from the same Topic.

Example:

```text
Anime
→ Naruto
→ One Piece
→ Dragon Ball
```

The Cards from all selected Packs form the game's Card pool.

All selected Packs must already be downloaded.

#### Random Packs

Allow BiGuess to randomly select Pack(s) from the chosen Topic according to the available game configuration.

Only downloaded Packs can participate.

Multi-topic selection is not supported.

---

### 7. Game Configuration

After the player chooses the Topic and Pack selection, BiGuess presents the **Game Configuration** step.

The player can either keep the default settings or modify them before starting the game.

MVP settings include:

* Difficulty
* Number of Rounds

The configuration is fixed when the game starts.

Settings cannot be changed during an active game.

The intended flow is:

```text
Choose Topic
      ↓
Choose Pack(s)
      ↓
Game Configuration
      ↓
Start Game
```

The default configuration should allow the player to start quickly without manually changing every setting.

---

### 8. Game and Rounds

A **Game** is a complete session containing the selected content, configuration, and a defined number of Rounds.

A **Round** is one cycle in which players receive their Cards and play the real-world guessing game.

Example:

```text
Game
├── Topic: Anime
├── Packs: Naruto + One Piece
├── Difficulty: Medium
├── Rounds: 3
│
├── Round 1
├── Round 2
└── Round 3
```

BiGuess controls only the progression and tracking of the configured number of Rounds.

It does **not** determine or record:

* who won;
* who lost;
* who guessed first;
* whether a guess was correct;
* how many questions were asked;
* whether players followed the rules.

These are intentionally left to the players and the real-world group.

---

### 9. Card Pool and Randomization

When a Game starts, BiGuess builds a Card pool from the selected and downloaded Packs.

The selected Difficulty is applied to determine the eligible Cards.

Example:

```text
Selected Packs
      ↓
All Cards
      ↓
Difficulty Filter
      ↓
Eligible Cards
      ↓
Random Card Selection
```

BiGuess uses a temporary Card list for random selection.

When a Card is selected, it is removed from that temporary list.

The process continues until the temporary list is empty.

When the list is exhausted, it is rebuilt from the cached/downloaded Pack content and random selection continues.

This prevents unnecessary repetition while allowing the game to continue indefinitely.

The randomization is **local to each device**.

BiGuess does not synchronize Card pools between players' phones.

---

### 10. Identity Assignment

Each player's phone independently selects a Card from its local Card pool.

BiGuess does not guarantee that different players receive different Cards.

The application cannot reliably determine which phones are participating in the same physical game, and introducing network synchronization solely to prevent duplicate identities would contradict the offline-first nature of the game.

Therefore, the same identity may appear on multiple players' phones during the same physical round.

The players are responsible for the real-world rules of the game.

---

### 11. Real-World Gameplay

After Cards have been assigned, the application becomes a facilitator for the physical game.

Each player turns their phone outward so the other players can see their hidden identity.

Players take turns asking **Yes or No** questions about their own identity.

The application does not require players to:

* enter questions;
* record answers;
* validate answers;
* press a button after every question;
* report guesses;
* confirm winners.

The group handles these interactions verbally.

The application only provides the identity and supports the configured game/round flow.

---

### 12. Scoring and Winning

Scoring is not part of the MVP.

BiGuess does not attempt to automatically determine winners because the application cannot reliably observe or verify real-world events.

For example, two players may believe they won or press a winner button simultaneously. Real-time synchronization would only synchronize the actions; it would not establish which player actually won.

The group determines the winner according to the real-world rules they choose to follow.

---

### 13. Timer

A timer is **not part of the MVP**.

BiGuess does not track the number of questions or limit the amount of time a player can take.

The length of a guessing process is intentionally unrestricted because different Cards naturally require different numbers of questions.

A timer may be considered in the future only if real players/community members demonstrate a meaningful demand for it.

---

### 14. Network Dependency

The core gameplay does not require a network connection once the required Packs have been downloaded.

The initial content flow is:

```text
Internet
   ↓
Discover Topic / Pack
   ↓
Download Pack
   ↓
Store Locally
   ↓
Play Offline
```

If a player wants to play a Topic or Pack that is not available locally, an internet connection is required to download the necessary content.

The same process repeats whenever the player wants to use new content that has not yet been downloaded.

During offline gameplay, BiGuess should not need to communicate with a remote server.

---

### 15. Local Content

Downloaded Packs are stored inside BiGuess's private application storage/cache and should not appear as ordinary image files in the user's accessible phone storage.

Downloaded content should be stored in a protected/encrypted form to discourage casual extraction and data scraping.

Encryption is a protection mechanism, not absolute DRM. Any content that can ultimately be displayed on a device can potentially be extracted by a sufficiently determined attacker.

The goal is to prevent simple access to the raw content while keeping gameplay fast and fully offline.

---

### 16. MVP Game Loop

The complete MVP game flow is:

```text
Open BiGuess
      ↓
Choose Topic
      ↓
Choose:
  • Single Pack
  • Selected Packs
  • Random Packs
      ↓
Ensure Required Packs Are Downloaded
      ↓
Game Configuration
  • Difficulty
  • Number of Rounds
      ↓
Start Game
      ↓
Round 1
      ↓
Players Receive Random Cards
      ↓
Real-World Yes/No Gameplay
      ↓
Round Ends According to Players
      ↓
Next Round
      ↓
...
      ↓
Configured Number of Rounds Completed
      ↓
Game Finished
```

The application manages the digital preparation and progression.

The players manage the actual game.

---

## Content System

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

* cannot be played directly;
* cannot be downloaded as a whole;
* contains multiple Packs;
* is used to organize the content library.

A Game uses exactly one Topic.

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

* belongs to one Topic;
* contains Cards;
* can be downloaded;
* can be played offline after downloading;
* must contain at least two Cards to be playable.

The Pack is the primary unit used for content distribution.

#### Card

A Card is one playable identity.

For the MVP, the Card contains only:

* **Name**
* **Image**
* **Difficulty**
* **Pack relationship**

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

The exact database/document representation is defined in the Technical Architecture section.

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

The exact image formats, resolutions, compression settings, and processing pipeline are defined in the Technical Architecture and Content Studio sections.

---

### 6. Content Distribution

Content is distributed independently from the BiGuess application itself.

The application contains the:

* game engine;
* UI;
* gameplay logic;
* content discovery interface;
* download system;
* local content system.

The remote content system contains:

* Topics;
* Packs;
* Cards;
* images;
* content metadata.

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

* make gameplay dependent on network availability;
* introduce latency;
* increase remote requests;
* increase infrastructure usage;
* make the offline experience unreliable.

Once a Pack is downloaded, gameplay should use the local copy.

---

### 8. Local Content Storage & Protection

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

* available Topics;
* available Packs;
* Pack names;
* Pack relationships;
* Card counts;
* download status;
* content update information;
* required metadata.

The catalog should be lightweight and should not require downloading complete Card data just to browse available Packs.

The application should download full Pack content only when the user chooses to use that Pack.

---

### 12. Offline-First Content Architecture

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

* discovering content;
* downloading Packs;
* checking for content changes;
* updating local content.

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

* administrators;
* data collectors;
* content management;
* creating Topics;
* creating Packs;
* adding Cards;
* uploading images;
* assigning difficulty;
* reviewing and managing content.

The initial Studio does not need to expose community publishing.

---

### 15. BiGuess Studio Pipeline

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

### 16. Community Content (Future Vision)

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

### 17. Content Ownership and Attribution

For the MVP, content managed through BiGuess Studio is considered controlled BiGuess content.

Content should have enough internal metadata to identify where it came from and allow Studio administrators to manage it.

Future community content may require additional information such as:

* creator;
* submission status;
* approval status;
* ownership/licensing information.

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

---

# Technical Architecture

## 1. Architecture Goals

BiGuess consists of three cooperating systems:

```text
BiGuess Mobile
      │
      │ Downloads content
      ▼
Content Backend
      ▲
      │ Manages content
      │
BiGuess Studio
```

The architecture must satisfy the following requirements:

1. Gameplay must work completely offline after Packs are downloaded.
2. Remote access must be minimized to stay within free-tier limits.
3. Content must be independent from the mobile application's code.
4. The content system should be portable enough to migrate between database providers in the future.
5. The architecture must remain simple enough for a small project and team.
6. The system must not require paid infrastructure while BiGuess is not generating enough income to justify it.

> **Golden Rule:** BiGuess infrastructure must stay within free-tier limits. Optimize usage before considering any paid upgrade.

---

# 2. Main Systems

BiGuess consists of three major systems.

## 2.1 BiGuess Mobile

The player-facing Flutter application.

Responsibilities:

* Browse Topics and Packs.
* Download Packs.
* Store downloaded content locally.
* Configure games.
* Run games completely offline.
* Randomize Cards.
* Manage Round progression.
* Display Cards and their images.

The mobile application must not depend on the backend during gameplay.

---

## 2.2 BiGuess Studio

BiGuess Studio is a separate Flutter application used to manage BiGuess content.

MVP responsibilities:

* Google authentication.
* Studio user authorization.
* User profiles.
* User statistics.
* Topic management.
* Pack management.
* Card management.
* Image management.
* Difficulty assignment.
* Content synchronization.
* Content publishing.

Studio is also intended to be used by friends/data collectors to populate BiGuess with content while the mobile application is being developed.

Future responsibilities may include:

* Community submissions.
* Moderation.
* Contributor ranking.
* Community statistics.

---

## 2.3 Content Backend

The Content Backend stores and distributes BiGuess content.

Responsibilities:

* Store Topics.
* Store Packs.
* Store Cards.
* Store content metadata.
* Store/serve Card images.
* Provide content catalog information.
* Provide content synchronization information.

The backend does **not** manage active games.

It does not need:

* Game rooms.
* Player connections.
* Real-time game state.
* Card assignment synchronization.
* Scores.
* Questions.
* Winners.

---

# 3. Offline-First Architecture

The most important technical principle of BiGuess is:

> **The network is used to obtain content, not to play the game.**

The intended flow is:

```text
Internet
   │
   ▼
Discover Content
   │
   ▼
Download Pack
   │
   ▼
Store Locally
   │
   ▼
Play Offline
```

Once the required Packs are downloaded, gameplay should not require:

* Internet;
* Firebase;
* API requests;
* database reads;
* remote image loading;
* real-time connections.

This guarantees that the real-life game is not interrupted by network problems.

---

# 4. Mobile Application Architecture

The BiGuess mobile application should separate presentation, game logic, content management, and storage.

A high-level structure is:

```text
BiGuess Mobile
│
├── Presentation
│   ├── Screens
│   ├── Widgets
│   └── Animations
│
├── Game
│   ├── Game Configuration
│   ├── Round Management
│   ├── Card Selection
│   └── Randomization
│
├── Content
│   ├── Catalog
│   ├── Pack Management
│   ├── Downloading
│   └── Synchronization
│
├── Local Storage
│   ├── Content Metadata
│   ├── Pack Data
│   ├── Card Data
│   └── Protected Images
│
└── Core
    ├── Models
    ├── Repositories
    └── Shared Services
```

The exact Flutter package and folder structure should be decided during implementation.

---

# 5. Separation Between Game and Content

The Game Engine must not contain hardcoded Cards or Topic-specific logic.

The Game Engine should work with generic Card data.

For example, it should not contain logic such as:

```text
if card is anime character
if card is football player
if card is country
if card is food
```

Instead:

```text
Game Engine
     │
     ▼
   Card
   ├── Name
   ├── Image
   └── Difficulty
```

This allows new Topics to be added without modifying the gameplay system.

---

# 6. Content Architecture

The technical system follows:

```text
Topic
  │
  └── Pack
       │
       └── Cards
```

A Topic is an organizational category.

A Pack is the downloadable/playable unit.

A Card is the playable identity.

### Topic

```text
Topic
├── id
└── name
```

### Pack

```text
Pack
├── id
├── topicId
└── name
```

### Card

```text
Card
├── id
├── packId
├── name
├── image
└── difficulty
```

The database may contain additional technical fields, but these should not unnecessarily become part of the Game Engine's domain model.

---

# 7. Pack Download

The Pack is the main download unit.

When the user downloads a Pack, BiGuess downloads the content required to play it.

Each Card provides:

* Name.
* Image.
* Difficulty.

Conceptually:

```text
Download Pack
      │
      ▼
Pack Data
      │
      ├── Card
      │    ├── Name
      │    ├── Image
      │    └── Difficulty
      │
      ├── Card
      │    ├── Name
      │    ├── Image
      │    └── Difficulty
      │
      └── ...
```

The application should perform bulk downloads rather than requesting each Card individually.

---

# 8. Remote Content Catalog

The application needs a lightweight way to discover what content exists before downloading it.

The catalog should provide enough information to display:

* Topics.
* Packs.
* Pack names.
* Topic relationships.
* Card counts.
* Download availability.
* Content update information.

The catalog should remain lightweight.

Browsing available Packs should not require downloading the entire Card dataset.

---

# 9. Database Architecture

The content database should be independent from the authentication system.

A possible architecture is:

```text
Google Account
      │
      ▼
Firebase Authentication
      │
      ▼
Studio User
      │
      ▼
Authorization
      │
      ▼
Content Database
      │
      ├── Topics
      ├── Packs
      └── Cards
```

Firebase Authentication is responsible for identity.

The Content Database is responsible for content and application-specific data.

This separation allows the content database to be replaced without replacing the authentication system.

---

# 10. SQL as the Content Database

A SQL database is currently the preferred direction for the canonical BiGuess content database because the content relationships are naturally structured:

```text
Topic
  │
  └── Pack
       │
       └── Card
```

However, the application must not become tightly coupled to SQL-specific implementation details.

The final SQL provider must be selected according to:

* Free-tier limits.
* Storage limits.
* Bandwidth limits.
* Connection limits.
* API availability.
* Flutter compatibility.
* Reliability.
* Ease of migration.
* Long-term suitability.

No provider should be selected merely because it is popular.

---

# 11. Database Portability

The project should be designed so the Content Database can be replaced in the future.

The application should communicate with the backend through repositories or data-access interfaces.

Conceptually:

```text
UI
 ↓
Application Services
 ↓
Repositories
 ↓
Backend Implementation
 ↓
Database Provider
```

For example:

```text
CardRepository
      ↓
SQLCardRepository
```

could later become:

```text
CardRepository
      ↓
AnotherCardRepository
```

without changing the Card model or Game Engine.

Provider-specific database structures should therefore be isolated inside the backend/data layer.

---

# 12. Authentication Architecture

Firebase Authentication may be used for BiGuess Studio authentication.

Google Sign-In is the initial authentication method.

The authentication flow is:

```text
User
  ↓
Google Sign-In
  ↓
Firebase Authentication
  ↓
Authenticated Email
  ↓
Check Studio Authorization
```

Authentication answers:

> Who is this user?

Authorization answers:

> Is this user allowed to use BiGuess Studio?

These responsibilities must remain separate.

---

# 13. Studio Authorization

Only emails authorized by the Owner Admin can access BiGuess Studio.

The flow is:

```text
Google Login
     ↓
Firebase Authentication
     ↓
Get User Email
     ↓
Check Authorized Users
     │
     ├── Authorized
     │      ↓
     │   Open Studio
     │
     └── Unauthorized
            ↓
        Stay on Login
```

An authenticated Google account is not automatically a Studio user.

---

# 14. Studio Roles

The MVP should support role-based access.

## Owner Admin

The highest-level Studio role.

Responsibilities include:

* Manage authorized users.
* Assign/remove moderators.
* Manage Topics.
* Manage Packs.
* Manage Cards.
* Manage content.
* Manage Studio users.
* Manage system settings.

## Data Collector

A trusted contributor responsible for building content.

Responsibilities may include:

* Add Cards.
* Edit Cards.
* Assign difficulty.
* Create Packs according to permissions.
* Contribute content.

## Moderator

A trusted user selected by the Owner Admin.

The future role is primarily intended for reviewing community submissions.

The exact permission matrix should be defined before implementation.

---

# 15. Studio First Login

BiGuess Studio should be optimized for minimal remote database usage.

During the first successful login:

```text
Google Login
     ↓
Authorization
     ↓
Download Required Studio Dataset
     ↓
Store Locally
     ↓
Work Locally
```

The Studio should not repeatedly request the same data from the backend.

The goal is to allow users to work primarily from a locally synchronized dataset.

---

# 16. Studio Synchronization

Studio synchronization is manual.

There should be:

* No realtime database listeners.
* No automatic polling.
* No continuous synchronization.

The user explicitly chooses **Refresh**.

```text
Studio
  ↓
Refresh
  ↓
Check Remote Changes
  ↓
Download Required Changes
  ↓
Update Local Dataset
```

This reduces unnecessary database reads and keeps the system within free-tier limits.

---

# 17. Optimized Refresh

Pressing Refresh should not download the entire database every time.

The first operation should be a lightweight change check.

Possible mechanisms include:

* Manifest.
* `updatedAt` timestamps.
* Hashes.
* Checksums.
* Change identifiers.

Conceptually:

```text
Refresh
   ↓
Small Change Check
   ↓
Changes?
 ┌─┴──────────┐
No           Yes
 │             │
Done     Download Changes
              │
              ▼
       Update Local Data
```

The implementation should be chosen based on the final backend.

The goal is:

> **Refreshing unchanged content should be extremely cheap.**

---

# 18. Studio Local Data

Studio should work primarily with its local synchronized dataset.

For example:

```text
Data Collector
      ↓
Create 50 Cards
      ↓
Local Studio Data
      ↓
Publish / Synchronize
      ↓
Remote Backend
```

The Studio should avoid sending a database request for every small UI operation whenever batching is possible.

Examples of operations that should preferably be batched:

* Adding many Cards.
* Uploading multiple images.
* Updating multiple Cards.
* Publishing a Pack.

---

# 19. Mobile Content Synchronization

Mobile synchronization follows the same low-request philosophy.

The user downloads a Pack once.

Afterward:

```text
Remote Pack
     ↓
Download
     ↓
Local Pack
     ↓
Offline Gameplay
```

The application should not request individual Cards from the database during gameplay.

---

# 20. Content Updates

BiGuess does not require user-facing Pack version numbers.

The system should compare local and remote content internally.

Example:

```text
Local Pack
100 Cards

Remote Pack
103 Cards
```

The synchronization system should determine what is missing or changed.

Only the required content should be downloaded.

The exact implementation may use:

* hashes;
* timestamps;
* manifests;
* checksums;
* content identifiers.

The mechanism is an internal technical detail.

---

# 21. Image Storage

Card images should be stored separately from database metadata whenever possible.

The preferred conceptual architecture is:

```text
Database
   │
   ├── Topics
   ├── Packs
   └── Cards
          │
          └── Image Reference

Object/File Storage
   │
   └── Card Images
```

Images should not be stored directly inside database records as large binary data.

Images should also be optimized before publication to reduce:

* storage;
* bandwidth;
* download size;
* local device storage.

---

# 22. Local Mobile Storage

Downloaded Packs are stored inside BiGuess's private application storage.

They should not appear as normal image files in the user's public phone storage.

Conceptually:

```text
BiGuess Private Storage
│
├── Local Content Data
├── Pack Data
├── Card Data
└── Protected Image Assets
```

The exact local database/storage technology will be selected during implementation.

---

# 23. Content Protection

Downloaded images should be stored in an encrypted/protected form.

The purpose is to discourage:

* casual extraction;
* simple file browsing;
* straightforward scraping.

The protection system should balance:

* security;
* performance;
* storage efficiency;
* implementation complexity.

It must not introduce noticeable delays when displaying Cards.

This is not intended to provide perfect DRM.

Any content that can ultimately be displayed on a device can potentially be extracted by a sufficiently determined attacker.

---

# 24. Game Engine

The Game Engine is completely local.

Its responsibilities include:

* Receive Game Configuration.
* Load selected local Packs.
* Build the Card pool.
* Apply Difficulty.
* Randomize Cards.
* Assign Cards locally.
* Remove selected Cards from the temporary pool.
* Rebuild the pool when exhausted.
* Track the current Round.
* Finish the configured number of Rounds.

The Game Engine does not manage:

* Questions.
* Answers.
* Winners.
* Losers.
* Scores.
* Timers.
* Player communication.
* Real-world behavior.

---

# 25. Card Pool

When a game starts:

```text
Selected Topic
      ↓
Selected Pack(s)
      ↓
Load Local Cards
      ↓
Apply Difficulty
      ↓
Create Temporary Pool
      ↓
Random Selection
```

When a Card is selected, it is removed from the temporary pool.

When the pool becomes empty, it is rebuilt from the locally cached Pack content.

The pool is temporary and does not need to be persisted.

---

# 26. Independent Player Devices

Every player's phone operates independently.

Phones do not need to:

* Connect to each other.
* Use Bluetooth.
* Share Wi-Fi.
* Join an online room.
* Connect to Firebase during gameplay.
* Synchronize Card assignments.

Conceptually:

```text
Phone A                  Phone B
   │                        │
Local Packs              Local Packs
   │                        │
Local Pool               Local Pool
   │                        │
Random Card              Random Card
   │                        │
   └────── Real World ─────┘
```

The physical players create the connection through conversation and gameplay.

---

# 27. Duplicate Cards Between Players

BiGuess does not guarantee unique Cards across different phones.

Because each phone operates independently, the application does not know which devices belong to the same physical game.

Therefore this is valid:

```text
Phone A → Naruto
Phone B → Luffy
Phone C → Naruto
```

BiGuess should not introduce networking solely to prevent this.

---

# 28. Persistent Game State

BiGuess does not save Game State.

The application does not remember:

* Previous Topics.
* Previous Packs.
* Previous Difficulty.
* Previous Rounds.
* Previous games.
* Unfinished games.
* Scores.
* Winners.

If the application is killed, closed, or crashes during a game, the game is lost.

The user starts a new game.

The only important persistent user-side data is downloaded content.

---

# 29. Network Usage

Network access should be concentrated around content operations.

### Network may be used for:

* Discovering Topics.
* Discovering Packs.
* Checking content information.
* Downloading Packs.
* Checking for content updates.
* Downloading missing/changed content.

### Network should not be required for:

* Starting a game with downloaded Packs.
* Card randomization.
* Card selection.
* Displaying downloaded Cards.
* Round progression.
* Real-world gameplay.

---

# 30. Free-Tier Optimization

The architecture must actively minimize backend usage.

Important strategies include:

### Avoid Per-Card Reads

Do not request each Card separately when downloading a Pack.

Use bulk Pack downloads.

### Avoid Realtime

Do not use realtime listeners for Mobile or Studio content synchronization.

### Avoid Automatic Refresh

Studio checks for updates only when the user presses Refresh.

### Cache Locally

Downloaded data should be reused instead of repeatedly downloaded.

### Batch Writes

Studio should batch content operations whenever practical.

### Separate Metadata and Images

Use a database for structured metadata and object storage for images.

### Incremental Updates

Download only missing or changed content.

### Delete Unnecessary Data

Future rejected community submissions should be deleted after one week.

---

# 31. BiGuess Studio User Profiles

A Studio user has a profile.

The profile should contain information such as:

```text
UserProfile
├── id
├── displayName
├── email
├── photo
├── role
├── cardsAdded
├── cardsRemoved
├── packsCreated
├── packsRemoved
├── topicsCreated
└── topicsRemoved
```

The profile is part of the MVP.

These statistics provide useful information about each contributor and prepare the project for future gamification.

---

# 32. Contribution Statistics

Studio should track contributor activity.

Examples:

* Cards added.
* Cards removed.
* Packs created.
* Packs removed.
* Topics created.
* Topics removed.

Statistics should not require a database write for every individual UI action whenever batching is possible.

The system should prioritize minimizing writes while maintaining accurate statistics.

---

# 33. Studio Gamification

A contributor ranking system is planned for the future.

Possible ranking factors include:

* Cards contributed.
* Packs created.
* Topics created.
* Accepted community submissions.
* Other meaningful contribution metrics.

The ranking system itself is **not part of the MVP**.

The MVP includes the profile and basic contribution statistics needed to support it later.

---

# 34. Community Content

Community content is not part of the initial Mobile MVP.

The architecture should nevertheless allow the future addition of community submissions.

Future flow:

```text
Community User
      ↓
Submit Content
      ↓
Pending Review
      ↓
Moderator
      ↓
Accept / Refuse
      │
      ├── Accept
      │      ↓
      │   Publish
      │
      └── Refuse
             ↓
        Keep for 1 Week
             ↓
       Permanent Deletion
```

Community submissions must not automatically become public content.

---

# 35. Moderation

Moderators are selected by the Owner Admin using authorized email addresses.

Future community submissions will require moderation before publication.

Moderators can:

* Review submissions.
* Accept submissions.
* Refuse submissions.

Only accepted submissions become official published content.

---

# 36. Rejected Submissions

Rejected community submissions should not remain permanently stored.

The intended lifecycle is:

```text
Rejected
   ↓
Temporary Storage
   ↓
1 Week
   ↓
Permanent Deletion
```

The purpose is to retain rejected data temporarily for review/history while avoiding unnecessary storage consumption.

This also supports the strict free-tier requirement.

---

# 37. Community Contribution Statistics

For future community content, only accepted submissions count toward contributor statistics and ranking.

Example:

```text
Submitted: 10 Cards
Accepted:   7 Cards
Refused:    3 Cards
```

Contribution count:

```text
7 Cards
```

not:

```text
10 Cards
```

Rejected content must not artificially increase contributor rankings.

---

# 38. Backend Portability Strategy

The architecture should be designed around a provider-independent domain.

The following should remain stable:

```text
Topic
Pack
Card
UserProfile
```

The following may change:

```text
Database Provider
Storage Provider
Authentication Provider
API Layer
Synchronization Implementation
```

The application should isolate provider-specific implementations behind interfaces/repositories.

This reduces the cost of future migration.

---

# 39. Initial Backend Direction

The current preferred direction is:

```text
Firebase Authentication
        │
        │
        ▼
Studio Authentication
        │
        ▼
Provider-Independent App Logic
        │
        ▼
SQL Content Database
        │
        ├── Topics
        ├── Packs
        └── Cards
        │
        ▼
Object/File Storage
        │
        └── Card Images
```

The exact providers are intentionally not locked yet.

The final selection must be based primarily on:

1. Free-tier limits.
2. Storage capacity.
3. Bandwidth.
4. Database/API request limits.
5. Reliability.
6. Flutter compatibility.
7. Ease of migration.
8. Simplicity.
9. Long-term viability for BiGuess.

---

# 40. Development Strategy

BiGuess Mobile and BiGuess Studio should be developed in parallel.

```text
                BiGuess Project
                      │
             ┌────────┴────────┐
             │                 │
       BiGuess Mobile     BiGuess Studio
             │                 │
        Game Engine       Content Pipeline
             │                 │
             └────────┬────────┘
                      │
                Shared Models
                & Architecture
```

BiGuess Studio should be started early enough for data collectors to begin populating real content.

This allows the mobile application to be tested with realistic Packs containing hundreds or thousands of Cards instead of relying on a small hardcoded dataset.

---

# 41. MVP Technical Principles

The technical architecture follows these rules:

1. **Flutter is used for the player-facing BiGuess application.**
2. **Flutter is also used for BiGuess Studio unless another decision is made later.**
3. **Gameplay is local-first.**
4. **Downloaded Packs are playable offline.**
5. **No network connection is required during gameplay.**
6. **No real-time multiplayer system is required.**
7. **Phones do not synchronize with each other.**
8. **Game State is not persisted.**
9. **Downloaded content is persistent.**
10. **Topics organize Packs.**
11. **Packs are the primary download unit.**
12. **Pack downloads contain Card names, images, and difficulties.**
13. **Content is separated from application code.**
14. **The content database should preferably be SQL-based.**
15. **Authentication is separated from content storage.**
16. **Firebase Authentication may be used for Studio Google login.**
17. **Only authorized emails can access Studio.**
18. **Studio works primarily from locally synchronized data.**
19. **Studio synchronization is manual.**
20. **Studio does not use realtime listeners.**
21. **Refresh should use lightweight change detection.**
22. **Remote requests should be minimized aggressively.**
23. **Images should use object/file storage rather than database records.**
24. **Downloaded images should be protected/encrypted locally.**
25. **Content synchronization should download only missing or changed content.**
26. **Repositories/data-access layers must isolate the database provider.**
27. **The content backend must remain replaceable.**
28. **Studio user profiles are part of the MVP.**
29. **Studio contribution statistics are part of the MVP.**
30. **Studio ranking/gamification is not part of the MVP.**
31. **Community submissions are not part of the MVP.**
32. **Future community submissions require moderation.**
33. **Only accepted community submissions count toward ranking/statistics.**
34. **Rejected submissions are deleted after one week.**
35. **Infrastructure must remain within free-tier limits.**
36. **Optimization must be preferred over paid infrastructure.**

---

## Content Studio
### How non-developers contribute

---

## Distribution & Updates

---

## Costs

---

## Legal/IP

---

## Business Possibilities

---

## MVP

---

## Future Vision

---

## Migration Plan From Current BiGuess
