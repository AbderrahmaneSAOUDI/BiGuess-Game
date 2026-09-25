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

A downloaded Pack remains playable offline unless the player removes it locally or the device later synchronizes a valid cloud deletion.

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

The application should provide reliable random selection while avoiding unnecessary repetition within the same device's game/session. Because devices operate independently without network synchronization, Card repetition between different physical devices is permitted and expected.

The goal is for BiGuess to behave more like a shuffled physical deck on each device than an unrestricted random-number generator.

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
- Single Pack selection (within chosen Topic);
- Multiple selected Packs (within chosen Topic);
- Random Pack selection (within chosen Topic).

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

> **Canonical Rule:** One Game → exactly one Topic → one or more Packs from that Topic. Multi-topic games are intentionally not supported.

BiGuess should support:

### Single Pack

Play from one selected Pack within the chosen Topic.

### Multiple Selected Packs (Within the Same Topic)

Combine several selected Packs belonging to the same chosen Topic.

For example, within the **Anime** Topic:

> Naruto + One Piece + Dragon Ball

### Random Packs

Allow BiGuess to randomly select Pack(s) from the downloaded Packs within the chosen Topic.

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

# BiGuess Content Studio

## 1. Overview

**BiGuess Studio** is the content-management application for the BiGuess ecosystem.

Its purpose is to allow the BiGuess team to create, organize, review, maintain, and publish the content used by the BiGuess mobile application without requiring changes to the mobile application's code.

BiGuess Studio is a **separate Flutter application** from the BiGuess mobile game.

The relationship between the systems is:

```text
┌──────────────────────┐
│   BiGuess Studio     │
│                      │
│ Create / Edit        │
│ Review / Organize    │
│ Publish              │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Content Backend    │
│                      │
│ Topics               │
│ Packs                │
│ Cards                │
│ Images               │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│    BiGuess Mobile    │
│                      │
│ Download             │
│ Cache                │
│ Play Offline         │
└──────────────────────┘
```

Studio is **not** responsible for gameplay.

It does not manage:

* active games
* players in a game
* questions
* answers
* winners
* losers
* scores
* game rooms
* realtime gameplay
* Bluetooth/Wi-Fi game synchronization

Its responsibility is content.

---

# 2. Main Philosophy

BiGuess Studio should be designed around one fundamental goal:

> **Make it extremely easy and fast for a small team to create thousands of high-quality BiGuess cards.**

Studio should not become a generic enterprise CMS.

The initial users are expected to be:

* Owner Admin
* Data Collectors

with Moderators and community contributors being future extensions.

The application should prioritize:

1. Speed of content creation
2. Simple workflows
3. Local-first operation
4. Efficient synchronization
5. Strong content validation
6. Low infrastructure usage
7. Free-tier sustainability
8. Easy management of large amounts of content

---

# 3. Content Hierarchy

BiGuess content follows a strict hierarchy:

```text
Topic
  └── Pack
        └── Card
```

For example:

```text
Anime
 ├── Naruto
 │    ├── Naruto Uzumaki
 │    ├── Sasuke Uchiha
 │    ├── Sakura Haruno
 │    └── Kakashi Hatake
 │
 ├── One Piece
 │    ├── Monkey D. Luffy
 │    ├── Roronoa Zoro
 │    └── Nami
 │
 └── Dragon Ball
      ├── Goku
      ├── Vegeta
      └── Piccolo
```

## Topic

A Topic represents a broad category of BiGuess content.

Examples:

* Anime
* Films
* Football
* Countries
* Food
* Scholars
* etc.

A Topic contains Packs.

Topics are not directly playable cards and do not contain cards themselves.

---

## Pack

A Pack is the primary content and download unit.

A Pack belongs to exactly one Topic and contains Cards.

Examples:

```text
Topic: Anime

Packs:
- Naruto
- One Piece
- Dragon Ball
- Attack on Titan
```

Packs are also the primary publishing unit.

---

## Card

A Card represents one possible identity/image shown during gameplay.

A Card contains only the metadata required by the game:

```text
Card
├── ID
├── Name
├── Image
├── Difficulty
└── Pack ID
```

No unnecessary semantic metadata is required.

BiGuess does not need to know whether a character is:

* a hero
* a villain
* male/female
* human
* alive
* fictional
* powerful
* etc.

Players determine those facts through their real-life questions.

---

# 4. Studio Users and Roles

## 4.1 Owner Admin

The Owner Admin has complete control over Studio and its content.

The Owner Admin can:

* manage authorized Studio users
* manage roles
* create/edit/delete Topics
* create/edit/delete Packs
* create/edit/delete Cards
* restore deleted content
* permanently delete content
* upload and manage images
* review content
* publish Topics
* publish Packs
* unpublish Topics
* unpublish Packs
* view all content, including deleted content
* view contributor statistics
* manage Studio settings

The Owner Admin is the final authority over published content.

---

## 4.2 Data Collector

Data Collectors are trusted contributors who populate the BiGuess content database.

Their primary purpose is to create and maintain content.

A Collector can:

* create Packs
* edit Packs
* delete Packs
* create Cards
* edit Cards
* delete Cards
* upload images
* assign Card difficulty
* review their content
* search content
* filter content
* perform bulk actions where permitted

Collectors **cannot permanently delete content**.

Collectors can mark content as deleted, but the deletion is reversible by the Owner Admin.

Collectors also cannot manage Topics.

This keeps the top-level content taxonomy under administrative control while allowing Collectors to efficiently build Packs and Cards.

---

## 4.3 Moderator

Moderators are a future role.

They will primarily exist when BiGuess supports community-generated content.

Moderators will eventually be able to:

* review community submissions
* accept submissions
* reject submissions
* inspect reported content

Moderator functionality is **not part of the initial Studio MVP**.

---

# 5. Authentication and Authorization

## 5.1 Google Login

BiGuess Studio uses Google authentication.

Firebase Authentication can be used for Studio authentication.

The authentication system answers:

> Who is this user?

The BiGuess backend answers:

> Is this user authorized to use Studio and what role do they have?

---

## 5.2 Authorized Users

Studio access is restricted.

The Owner Admin maintains an authorized-user list based on email addresses.

Example:

```text
Authorized Users

abderrahmane@example.com    OWNER
collector1@example.com      COLLECTOR
collector2@example.com      COLLECTOR
```

A Google account that successfully authenticates but is not authorized must not enter Studio.

Instead, the user sees an access-denied state and can sign out.

---

## 5.3 Roles Must Be Data-Driven

The application should not hard-code permissions throughout the UI.

Instead:

```text
User
├── ID
├── Email
├── Name
├── Avatar
├── Role
└── Statistics
```

Roles determine permissions.

This makes it possible to introduce additional roles later without redesigning the entire application.

---

# 6. Studio Navigation

The Studio interface should remain simple.

A possible structure:

```text
BiGuess Studio

Dashboard

Content
├── Topics
├── Packs
└── Cards

Review

Profile

Settings
```

The exact visual layout can be decided during UI/UX design, but navigation should prioritize content management over administrative features.

---

# 7. Dashboard

The Dashboard provides a quick overview of the content system and the user's activity.

Example:

```text
Welcome back, Abderrahmane

Content
────────────────────────

Topics       12
Packs        84
Cards        4,231

Your Contributions
────────────────────────

Cards Added       438
Cards Removed      12
Packs Created       8
Packs Removed       1
Topics Created      2
Topics Removed      0

Recent Activity
────────────────────────

+20 cards
Naruto Pack
Today

+15 cards
One Piece Pack
Yesterday
```

The Dashboard should remain simple.

It should not become an analytics platform.

The purpose is to answer:

* What content exists?
* What did I contribute?
* Is something waiting for my attention?
* When was the last synchronization?

Advanced analytics are not part of the MVP.

---

# 8. Topic Management

Topics represent the highest level of the content hierarchy.

Example:

```text
Anime
Films
Football
Countries
Food
```

## Topic Permissions

The Owner Admin has full Topic CRUD permissions.

Collectors do not create or delete Topics.

This prevents the content taxonomy from becoming inconsistent.

For example, without administrative control, the database could eventually contain:

```text
Anime
Anime Characters
Anime Character
Japanese Anime
Anime - Characters
Anime Characters 2026
```

Keeping Topic management restricted avoids this problem.

---

# 9. Pack Management

Packs are the primary organizational and download unit.

A Pack belongs to one Topic.

Example:

```text
Anime
│
├── Naruto
│   └── 142 Cards
│
├── One Piece
│   └── 327 Cards
│
└── Dragon Ball
    └── 214 Cards
```

## Pack Screen

A Pack should show information such as:

```text
Naruto

Topic: Anime
Cards: 142

Draft Cards: 32
Published Cards: 110

Status: Published

[Add Cards]
[Review]
[Publish]
```

The exact information displayed can evolve with the UI design.

---

## Pack CRUD

Collectors can:

* create Packs
* edit Packs
* mark Packs as deleted

Owner Admin can:

* create Packs
* edit Packs
* mark Packs as deleted
* restore Packs
* permanently delete Packs
* publish Packs
* unpublish Packs

---

# 10. Soft Deletion

Deletion of content by Collectors must be **soft deletion**.

A Collector does not permanently remove content from the database.

Instead:

```text
Active
  ↓
Deleted
```

Deleted content:

* disappears from normal content views
* is hidden from the BiGuess mobile game
* is excluded from normal searches and lists
* remains available to the Owner Admin

The Owner Admin can then decide what happens next:

```text
Deleted
   │
   ├── Restore / Keep
   │
   └── Permanently Delete
```

This protects against accidental deletion and allows the Owner Admin to review content before permanently removing it.

---

# 11. Deleted Content and the Mobile Game

Deleted content must never be included in newly distributed playable content.

If a Card is deleted:

```text
Card
Status: Deleted
```

the mobile game must not select it during gameplay.

If a Pack is deleted, it must not be offered as an available playable Pack.

If a Topic is deleted, it must not be offered as an available Topic.

Local cached content also needs to respect deletion updates.

Therefore synchronization must be able to communicate not only:

```text
New content
```

but also:

```text
Deleted content
```

---

# 12. Card Management

Cards are the most frequently created entities in Studio.

The Card editor should remain simple.

A Card contains:

```text
Name
Image
Difficulty
```

The Pack relationship is determined by the context in which the Card is created.

Example:

```text
Pack: Naruto

Card

Name:
Kakashi Hatake

Image:
[Image]

Difficulty:
○ Easy
○ Medium
● Hard

[Save]
```

---

# 13. Card Naming

The Card Name remains a dedicated field.

This is intentional.

Users should not be forced to rename image files before importing them.

Renaming files manually on a phone can be unnecessarily frustrating:

```text
Browser
 ↓
Download image
 ↓
Open File Manager
 ↓
Find image
 ↓
Long press
 ↓
Rename
 ↓
Type name
 ↓
Confirm
 ↓
Return
 ↓
Repeat
```

BiGuess Studio should remove this unnecessary work.

---

## Filename as an Optional Name Source

When importing an image, Studio can offer the filename as a convenient name suggestion.

Example:

```text
Image:
kakashi_hatake.jpg

Suggested Name:
Kakashi Hatake
```

The Collector can simply accept the suggested name and continue.

Alternatively:

```text
[Use filename]
```

can populate the Card Name field.

The filename is therefore a **convenience option**, not the canonical source of Card names.

The Collector always has the ability to edit the name.

---

# 14. Image Upload and Automatic Compression

Image handling should be designed to minimize storage and bandwidth usage.

When a user selects an image, Studio should automatically process it on the frontend before uploading.

The process can include:

```text
Original Image
      ↓
Resize if necessary
      ↓
Compress
      ↓
Optimized Image
      ↓
Upload
```

The user should not have to manually compress images.

The application should perform this transparently.

There is no need to display unnecessary messages such as:

> "Image compressed successfully."

The user simply selects an image and continues working.

The objective is:

> **Optimize the image without making the contributor think about optimization.**

---

# 15. Image Processing Principles

Image processing should balance:

* visual quality
* file size
* storage
* bandwidth
* processing time

Images should be compressed enough to significantly reduce storage and download costs while maintaining sufficient quality for BiGuess gameplay.

The exact:

* dimensions
* format
* compression level

should be determined during implementation and testing.

The system should avoid processing that noticeably slows down the content-creation workflow.

---

# 16. Bulk Card Import

Bulk importing is an important Studio feature.

It exists because adding hundreds of cards individually would be unnecessarily slow.

A Collector should be able to select multiple images at once.

Example:

```text
Select Images

✓ Naruto.jpg
✓ Sasuke.jpg
✓ Sakura.jpg
✓ Kakashi.jpg
✓ Itachi.jpg
✓ Hinata.jpg
```

Studio then creates a list of Cards for review.

---

# 17. Bulk Import Review

Bulk importing should **not immediately publish or blindly save all cards**.

Instead, Studio creates a reviewable list.

Example:

```text
Naruto Pack

Imported Cards

┌──────────────────────────────────────┐
│ [Image] Naruto Uzumaki               │
│ Name: [Naruto Uzumaki            ]   │
│ Difficulty: [Easy ▼]                 │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ [Image] Sasuke Uchiha                │
│ Name: [Sasuke Uchiha             ]   │
│ Difficulty: [Medium ▼]               │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ [Image] Kakashi Hatake               │
│ Name: [Kakashi Hatake            ]   │
│ Difficulty: [Hard ▼]                 │
└──────────────────────────────────────┘
```

The Collector can inspect every Card and modify:

* Name
* Difficulty
* image if necessary

before confirming the import.

This is especially useful when the filename has been used as the initial suggested name.

---

# 18. Bulk Import Goals

The bulk-import workflow should optimize for:

```text
Many images
    ↓
Quick import
    ↓
Review list
    ↓
Assign / correct names
    ↓
Assign difficulty
    ↓
Confirm
```

It should not attempt to automate decisions that require human judgment.

In particular, difficulty assignment should remain under human control.

---

# 19. Bulk Actions

Once content exists, Studio should support useful bulk actions.

For example:

```text
Select 20 Cards

[Change Difficulty]
[Delete]
```

Potential future actions can include:

* changing difficulty
* moving Cards
* deleting Cards
* restoring Cards

Bulk actions should always respect the user's role.

Dangerous operations such as deletion should require confirmation.

---

# 20. Search

Search is an essential Studio feature.

Because Studio is local-first and the relevant content is downloaded to the device, normal search should happen locally.

Example:

```text
Search:
kakashi
```

Results can immediately show:

```text
Kakashi Hatake
Pack: Naruto
Difficulty: Hard
Status: Published
```

There should be no need to contact the backend for every search query.

This provides:

* faster search
* better offline behavior
* fewer database reads
* lower infrastructure usage

---

# 21. Filtering

Studio should support practical local filtering.

Useful filters include:

* Topic
* Pack
* Difficulty
* Status
* Contributor

For example:

```text
Topic: Anime
Pack: Naruto
Difficulty: Easy
Status: Draft
```

Filtering should happen locally whenever possible.

The goal is to make large datasets manageable without generating unnecessary backend requests.

---

# 22. Content Status

Content should have a lifecycle.

At minimum, Studio needs to distinguish between content that is:

```text
Draft
Published
Deleted
```

Deleted is a separate state because deletion is soft and reversible by the Owner Admin.

The exact internal state model can be expanded if future community moderation requires states such as:

```text
Pending Review
Rejected
```

but those states should not unnecessarily complicate the MVP.

---

# 23. Publishing Model

Publishing happens at the **Topic and Pack level**.

Cards are not individually published to the mobile application.

The Pack is the primary content distribution unit.

A Topic can also have a published state because Topics themselves determine what content is available to mobile users.

Publishing governance follows three distinct tiers:

1. **Initial Publication (Packs and Topics):** Requires Owner Admin validation and explicit approval before becoming available to mobile users.
2. **Routine Maintenance of Published Packs:** Authorized Data Collectors can directly edit, add, or retire Cards in an already-published Pack. The Pack receives a new revision automatically, without creating an Owner approval bottleneck for routine content updates.
3. **Community Submissions (Future):** Submissions from external community contributors will enter a dedicated moderation queue before review and publication.

Example:

```text
Topic: Anime
Status: Published

Pack: Naruto
Status: Published

Pack: One Piece
Status: Draft
```

The mobile application should only receive content that is eligible for publication.

---

# 24. Pack Publishing

A Pack should have a clear review state before publishing.

Example:

```text
Naruto

142 Cards

✓ Names present
✓ Images present
✓ Difficulties assigned
✓ No blocking validation errors

[Publish Pack]
```

Publishing makes the Pack available for distribution to BiGuess mobile users.

If the Pack is later modified, the changes must be reflected in the synchronization system.

---

# 25. Topic Publishing

Topics can also be published or unpublished.

An unpublished Topic should not appear as a playable Topic in the mobile application.

This allows the team to prepare an entire Topic before making it available.

Example:

```text
Football
 ├── Clubs
 ├── Players
 └── National Teams

Status: Draft
```

The team can continue building content until the Topic is ready.

Then:

```text
[Publish Topic]
```

makes it available to players.

---

# 26. Unpublishing

Publishing should be reversible.

The Owner Admin should be able to:

```text
Published
    ↓
Unpublish
    ↓
Not available for new gameplay
```

This is important for correcting mistakes, temporarily removing problematic content, or preparing major content changes.

---

# 27. Validation Before Publishing

Studio should validate content before allowing publication.

Examples of validation rules:

```text
Card:
✓ Name exists
✓ Image exists
✓ Difficulty exists
✓ Pack exists
✓ Card is not deleted
```

Pack:

```text
✓ Pack has valid Topic
✓ Pack has valid Cards
✓ Cards contain required data
✓ No blocking validation errors
```

Topic:

```text
✓ Topic has valid metadata
✓ Published Packs are valid
```

Validation should prevent broken content from being distributed to the mobile application.

---

# 28. Duplicate Detection

Studio should help identify potential duplicate Cards.

For example:

```text
Naruto Uzumaki
```

already exists in the same Pack.

When another Card with the same or very similar name is created, Studio can display:

```text
Possible duplicate

Naruto Uzumaki already exists in this Pack.
```

This should be a **warning**, not necessarily an absolute restriction.

Different entities can legitimately have the same name.

The final decision remains with the content manager.

---

# 29. Local-First Architecture

Studio should operate primarily from local data after synchronization.

The basic model is:

```text
Backend
   │
   │ Initial Sync
   ▼
Local Database
   │
   ├── Topics
   ├── Packs
   ├── Cards
   ├── Users
   └── Local changes
          │
          ▼
       Studio UI
```

Normal browsing, searching, filtering, and editing should use local data whenever possible.

---

# 30. First Login

After the first successful login and authorization:

```text
Google Login
     ↓
Authorization Check
     ↓
Initial Synchronization
     ↓
Download Required Content
     ↓
Store Locally
     ↓
Studio Ready
```

The first synchronization may take longer because the application needs to establish its local dataset.

After that, Studio should avoid repeatedly downloading everything.

---

# 31. Manual Synchronization

Studio should use **manual refresh**, not realtime synchronization.

Example:

```text
Last synchronized:
18:32

[↻ Refresh]
```

When Refresh is pressed:

```text
Studio
   ↓
Check lightweight change information
   ↓
Anything changed?
   │
   ├── No
   │     ↓
   │   Up to date
   │
   └── Yes
         ↓
     Download changes
         ↓
     Update local database
```

The system should avoid downloading unchanged content.

---

# 32. Incremental Synchronization

Synchronization should support:

* newly created content
* modified content
* deleted content
* published/unpublished changes
* changed images

The system should identify what changed and transfer only what is necessary.

For example:

```text
Local:
Naruto Pack — current

Remote:
Naruto Pack — changed

Result:
Download only required changes
```

This minimizes:

* bandwidth
* storage operations
* database reads
* synchronization time

---

# 33. Free-Tier-First Engineering

A fundamental BiGuess architecture principle is:

> **BiGuess infrastructure should remain within free tiers for as long as realistically possible.**

This is not merely a temporary optimization.

The system should be designed to minimize unnecessary infrastructure consumption from the beginning.

The goal is not to artificially optimize every single operation before measuring real usage.

Instead, the architecture should naturally favor efficient patterns.

### Prefer:

```text
Local caching
Batch operations
Incremental synchronization
Manifest/change detection
Local search
Local filtering
Compressed images
Bulk uploads
Bulk writes
Manual refresh
Pack-based downloads
```

### Avoid:

```text
Per-card network requests
Per-keystroke writes
Realtime listeners
Constant polling
Repeated full downloads
Repeated image downloads
Unnecessary background synchronization
```

The implementation should always look for solutions that preserve the free tier for as long as possible.

If a more efficient architecture provides the same functionality while using fewer resources, prefer it.

---

# 34. Backend Independence

Studio should not directly couple the UI to a specific backend provider.

The architecture should follow:

```text
Studio UI
    ↓
Application Services
    ↓
Repositories
    ↓
Backend Implementation
    ↓
Provider
```

The domain models should remain provider-independent.

This makes it possible to change infrastructure later without rewriting Studio's UI and business logic.

---

# 35. Image Storage

Card metadata belongs in the database.

Images should be stored separately in object/file storage.

Conceptually:

```text
Database
────────────────────
Card ID
Name
Difficulty
Pack ID
Image Reference
```

while:

```text
Object Storage
────────────────────
image files
```

This keeps the database suitable for structured data while allowing image storage to scale independently.

---

# 36. Mobile Image Protection

Images distributed to the mobile application should be stored in the application's private storage.

The system should provide strong practical protection against casual extraction.

The goal is:

> **Make extraction as difficult as reasonably possible without making gameplay slow or unnecessarily complicated.**

BiGuess does not attempt to make extraction mathematically impossible.

Any content displayed on a user's device can ultimately be captured by a sufficiently determined person.

However, the application should avoid simply placing:

```text
/storage/DCIM/BiGuess/naruto.jpg
```

as easily accessible public files.

Instead, downloaded images should be stored in private application storage and protected appropriately.

Protection should not noticeably affect normal gameplay.

---

# 37. Contribution Statistics

User profiles are part of the Studio MVP.

A profile can display:

```text
Name
Avatar
Role
```

and contribution statistics.

Statistics include activity such as:

```text
Cards Added
Cards Removed

Packs Created
Packs Removed

Topics Created
Topics Removed
```

The statistics represent actual activity.

---

# 38. Contribution Counting

Deleted content does **not** erase the contributor's historical contribution count.

For example:

```text
Cards Added:   500
Cards Removed: 100
```

The contributor has:

```text
600 contributions
```

not 400.

Removal represents another action performed by the contributor.

Therefore statistics track contribution activity rather than only currently existing content.

This also creates useful data for possible future contributor rankings.

---

# 39. Ranking

Contributor ranking is **not part of the MVP**.

However, the MVP should collect the statistics needed to support ranking later.

Future ranking could potentially use:

```text
Accepted Cards
Created Packs
Created Topics
Other validated contributions
```

The exact ranking algorithm should be designed only when the community contribution system exists.

The MVP should not introduce:

* XP
* levels
* badges
* leaderboards
* achievements

just for the sake of gamification.

---

# 40. Community Content — Future

Community contributions are a future extension.

The planned flow is:

```text
Community User
      ↓
Submit Content
      ↓
Pending
      ↓
Moderator Review
      ↓
Accept / Reject
      ↓
Published
```

Only accepted content becomes part of the official BiGuess content library.

Only accepted contributions should count toward future contributor rankings.

---

# 41. Rejected Community Content

Rejected community content should not be stored indefinitely.

The planned policy is:

```text
Rejected
    ↓
Keep temporarily
    ↓
After 7 days
    ↓
Permanent deletion
```

This reduces unnecessary storage usage.

The exact implementation of the cleanup mechanism will depend on the selected backend infrastructure and must remain compatible with the free-tier-first principle.

---

# 42. Data Editing and Conflicts

Studio is not intended to provide realtime collaborative editing.

For example, the system does not need to behave like Google Docs.

If two contributors modify the same Card simultaneously, the MVP should use a simple conflict strategy rather than building a sophisticated collaboration engine.

Possible approaches include:

* last successful update wins
* server-side update timestamps
* lightweight conflict warnings

The exact implementation can be chosen during backend design.

The priority is avoiding unnecessary synchronization complexity.

---

# 43. Offline Capability

Studio should remain useful when the network is temporarily unavailable.

If content has already been synchronized locally, the user should still be able to:

* browse Topics
* browse Packs
* browse Cards
* search
* filter
* inspect content
* work with locally available data

Operations that require server communication may remain pending until synchronization is available.

The exact offline editing queue will be determined during the synchronization architecture design.

---

# 44. Studio MVP

The first production-ready Studio should contain:

## Authentication

* Google Login
* Firebase Authentication
* authorized-user verification
* role management

## Topics

* Owner CRUD
* local browsing
* search/filter

## Packs

* Collector CRUD
* Owner CRUD
* soft deletion
* restoration by Owner
* permanent deletion by Owner
* publishing
* unpublishing

## Cards

* Collector CRUD
* Owner CRUD
* soft deletion
* restoration by Owner
* permanent deletion by Owner
* image upload
* automatic image compression
* difficulty assignment
* name field
* filename-to-name convenience
* search
* filtering

## Bulk Content

* multiple-image import
* generated Card list
* per-Card review
* per-Card name editing
* per-Card difficulty assignment
* bulk actions

## Publishing

* Pack publishing
* Topic publishing
* Pack unpublishing
* Topic unpublishing
* validation before publishing

## Synchronization

* local database
* first-login synchronization
* manual refresh
* lightweight change detection
* incremental synchronization
* deleted-content synchronization

## Profile

* user information
* role
* contribution statistics

---

# 45. Explicitly Out of MVP

The following should **not** delay the first Studio release:

* community submissions
* moderator workflow
* contributor ranking
* XP
* badges
* achievements
* realtime collaboration
* chat
* comments
* advanced analytics
* AI-generated Cards
* AI difficulty assignment
* AI image discovery
* sophisticated conflict resolution
* realtime listeners
* complicated notification systems
* enterprise-style permission management

These can be reconsidered after BiGuess has real users and real content-creation requirements.

---

# 46. Ideal Collector Workflow

The complete intended workflow should feel like this:

```text
Open Studio
    ↓
Google Login
    ↓
Authorization
    ↓
Initial Sync / Local Data
    ↓
Dashboard
    ↓
Select Topic
    ↓
Select Pack
    ↓
Add Cards
    ↓
Select multiple images
    ↓
Studio automatically optimizes images
    ↓
Generate Card list
    ↓
Review every Card
    ↓
Confirm / edit names
    ↓
Assign difficulty
    ↓
Save Cards
    ↓
Review Pack
    ↓
Fix validation issues
    ↓
Pack ready
    ↓
Owner publishes Pack
```

The experience should feel fast enough that a Collector can comfortably create large amounts of content.

---

# 47. Design Principles

BiGuess Studio should follow these principles throughout development.

### 1. Content creation first

Every feature should be evaluated by asking:

> Does this make creating and maintaining BiGuess content easier?

### 2. Local-first

Use local data for normal browsing, searching, filtering, and other operations whenever possible.

### 3. Network only when necessary

Do not make the backend part of every interaction.

### 4. Free-tier first

Prefer architectures and implementations that minimize infrastructure usage and keep the project within free-tier limits for as long as possible.

### 5. Human judgment where appropriate

Studio should automate repetitive technical tasks such as image compression, but content decisions such as difficulty should remain under contributor control.

### 6. Recoverable deletion

Contributors should not be able to accidentally destroy content permanently.

### 7. Publishing is deliberate

Content should be reviewed before being distributed to players.

### 8. Keep the data model simple

A Card should not become an encyclopedia entry.

### 9. Optimize for thousands of Cards

The application should remain practical when the database grows from:

```text
100 Cards
```

to:

```text
1,000 Cards
```

to:

```text
10,000+ Cards
```

### 10. Don't build the future too early

Community systems, ranking, moderation, AI, and advanced analytics should only be implemented when BiGuess actually needs them.

---

# 48. Final Studio Vision

BiGuess Studio should ultimately become the **content engine behind BiGuess**.

Its job is simple:

```text
Create
   ↓
Organize
   ↓
Review
   ↓
Publish
   ↓
Distribute
```

while making the repetitive work as easy as possible.

A Collector should not have to think about:

* database queries
* image compression
* storage formats
* synchronization protocols
* CDN configuration
* cache invalidation
* backend requests

They should think about:

> **"What Card should I add next?"**

Everything else should happen behind the scenes.

The long-term vision is:

```text
                    BiGuess Studio
                          │
             ┌────────────┼────────────┐
             │            │            │
          Topics        Packs        Cards
             │            │            │
             └────────────┼────────────┘
                          │
                    Content Backend
                          │
             ┌────────────┴────────────┐
             │                         │
        BiGuess Mobile           Future Community
             │                         │
        Download Packs            Submit Content
             │                         │
        Play Offline              Moderation
             │                         │
             └──────────┬──────────────┘
                        │
                   BiGuess Ecosystem
```

The MVP should remain focused on the first half of that vision:

> **Give the BiGuess team a fast, reliable, low-cost way to build a large, high-quality content library and distribute it to the mobile game.**

Everything beyond that can grow when the project earns the right to become more complex.

---

## Distribution & Updates
# Distribution & Updates

## 1. Purpose

BiGuess separates the **application itself** from its **playable content**.

The mobile application contains the game logic, interface, animations, local storage system, download system, and other technical components. Topics, Packs, Cards, and their images are distributed separately as content.

This allows BiGuess to remain a relatively small application while allowing the content library to grow independently.

The core principle is:

> **The internet delivers BiGuess content. It should not participate in BiGuess gameplay.**

Once the required Packs are downloaded and verified, the user should be able to play completely offline.

---

# 2. Distribution Model

BiGuess uses a **Pack-based distribution model**.

The Pack is the primary unit of:

* User-facing catalog browsing
* Initial downloading
* Local storage management
* Offline availability
* Deletion

> **Architectural Distinction:**
> * **Initial distribution unit = Pack.** The user browses, acquires, and manages content at the Pack level.
> * **Update transport = changed Pack contents.** For updates, the system does not redownload the entire Pack; it transfers only the delta of changed Cards, images, and metadata.

A Topic is primarily an organizational structure containing Packs.

Cards are managed inside Packs and are not independently downloaded by the user.

For example:

```text
Topic
 ├── Pack A
 │    ├── Card 1
 │    ├── Card 2
 │    └── Card 3
 │
 ├── Pack B
 │    ├── Card 4
 │    ├── Card 5
 │    └── Card 6
 │
 └── Pack C
      ├── Card 7
      └── Card 8
```

The user downloads **Pack A**, not individual Cards.

---

# 3. Catalog vs Content

BiGuess should distinguish between lightweight catalog information and heavy playable content.

## Catalog

The catalog contains lightweight information such as:

* Topic ID
* Topic name
* Pack ID
* Pack name
* Pack availability
* Pack download size
* Pack revision/change information
* Other lightweight metadata required to determine whether content needs updating

Catalog information should be inexpensive to retrieve and may also be cached locally.

## Content

Playable Pack content contains:

* Cards
* Card names
* Card difficulties
* Card relationships
* Card images
* Required technical metadata

Heavy content should not be downloaded simply because the user is browsing the catalog.

The user should explicitly choose which Packs they want available offline.

---

# 4. Downloading Packs

Downloading a Pack is the main way new playable content enters the device.

The general flow is:

```text
User chooses Pack
        ↓
Check connectivity
        ↓
Retrieve Pack information / manifest
        ↓
Determine required content
        ↓
Download required files
        ↓
Verify downloaded content
        ↓
Store content locally
        ↓
Mark Pack as AVAILABLE
```

A Pack must **not** be considered available until all required content has successfully downloaded and passed integrity checks.

If the download fails halfway through, the Pack must not be treated as a complete playable Pack.

---

# 5. Pack Download Size

Before downloading a Pack, BiGuess should show the user an approximate download size.

For example:

```text
Anime Legends

Cards: 250
Download size: ~38 MB

[ Download ]
```

This allows the user to understand the storage and network cost before starting the download.

The displayed size does not need to be perfectly exact, but it should be reasonably representative of the actual download.

---

# 6. Download Activity and Logs

Downloading a Pack should not feel like a black box.

BiGuess should provide the user with a **visible activity/log view** showing what is happening behind the scenes.

The purpose is not to expose technical implementation details, but to provide transparency and confidence that the download is actually progressing.

For example:

```text
Downloading Anime Legends...

✓ Checking Pack information
✓ Preparing download
✓ Downloading card data
✓ Downloading images
✓ Verifying downloaded files
→ Saving Pack locally
→ Finalizing Pack

Progress: 184 / 250 cards

████████████████░░░░ 74%
```

The log should communicate meaningful operations such as:

* Checking Pack information
* Preparing download
* Downloading card data
* Downloading images
* Verifying files
* Saving content
* Finalizing Pack
* Download completed

It should not overwhelm the user with low-level information such as:

```text
GET /api/card/9384
SHA256(...)
HTTP 206
INSERT INTO...
```

The goal is **transparency, not technical debugging**.

The activity view may also be useful for diagnosing failed downloads without requiring the user to understand the underlying architecture.

---

# 7. Download Integrity

BiGuess should verify downloaded content before considering a Pack ready.

Depending on the final backend implementation, verification may use:

* File size
* Hash/checksum
* Manifest information
* Content identifiers
* Other integrity metadata

The important rule is:

> **Downloaded content must be verified before becoming active playable content.**

A corrupted or incomplete download must never silently replace valid local content.

---

# 8. Local Pack States

A downloaded Pack can have states similar to:

```text
NOT_DOWNLOADED
DOWNLOADING
AVAILABLE
UPDATE_AVAILABLE
UPDATING
FAILED
```

These states describe the relationship between the local device and the cloud content.

### NOT_DOWNLOADED

The Pack exists in the catalog but its playable content is not stored locally.

### DOWNLOADING

The Pack is currently being downloaded.

### AVAILABLE

The complete Pack is stored locally and verified.

The user can play it without an internet connection.

### UPDATE_AVAILABLE

The cloud contains a newer revision of the Pack than the local device.

The existing local version remains playable until the update succeeds.

### UPDATING

BiGuess is downloading and preparing the newer Pack content.

### FAILED

The latest download/update operation failed.

A previously valid local version should remain usable whenever possible.

---

# 9. Offline Availability

Once a Pack is successfully downloaded:

> **A downloaded Pack does not expire and requires no periodic online validation.**

It remains playable offline indefinitely unless removed locally by the user or removed after synchronizing a valid cloud deletion. BiGuess must not require the user to reconnect to the internet before playing a downloaded Pack.

The user should be able to:

* Open the application offline
* Select downloaded content
* Start a game
* Play rounds
* Randomize Cards
* Continue playing

without network access.

The internet is required for obtaining or synchronizing content, not for the actual game.

---

# 10. No Network During Gameplay

The Game Engine should operate entirely from local content.

During gameplay, BiGuess should not:

* Fetch Cards from the server
* Download images
* Query the database
* Require realtime connections
* Poll for updates
* Depend on internet availability

The game should already have everything it needs before gameplay begins.

This is especially important because BiGuess is designed for real-world social situations where internet connectivity may be poor or completely unavailable.

---

# 11. Pack Selection and Downloads

A user may select one or multiple Packs from the same Topic.

Only Packs that are locally available can be guaranteed to work offline.

If a required Pack has not been downloaded, BiGuess should make that clear and allow the user to download it before starting the game.

A multi-Pack download may be presented as one user action, but internally BiGuess should still treat each Pack independently.

For example:

```text
Download selected Packs

✓ Anime Heroes
→ Anime Villains
○ Anime Movies

Overall: 1 / 3 Packs
```

This preserves the Pack as the fundamental unit of distribution and makes failure/retry easier to manage.

---

# 12. Download Concurrency

BiGuess should avoid downloading an unlimited number of files simultaneously.

Downloads should use controlled concurrency so that:

* Memory usage remains reasonable
* Devices are not overloaded
* Network connections are not unnecessarily saturated
* Free-tier bandwidth is used efficiently
* Downloads remain reliable

The exact concurrency limit can be determined during implementation and testing.

---

# 13. Interrupted Downloads

Downloads can fail because of:

* Lost internet connection
* Application being closed
* Device going offline
* Server errors
* Insufficient storage
* Other unexpected failures

An interrupted Pack must not be marked as available.

Where technically practical, BiGuess should support retrying or resuming downloads instead of unnecessarily starting the entire operation from zero.

---

# 14. Atomic Pack Updates

Updating a Pack should not destroy the currently playable Pack before the new version is ready.

The preferred process is:

```text
Existing Pack
      ↓
Download new content separately
      ↓
Verify new content
      ↓
Prepare new local revision
      ↓
Switch active revision
      ↓
Delete obsolete local content
```

This means that if an update fails halfway through, the user can continue playing the previous valid Pack.

Only after the new Pack has been successfully downloaded and verified should it replace the old active content.

---

# 15. Incremental Pack Updates

BiGuess should avoid redownloading an entire Pack whenever a small change occurs.

For example, if a Pack contains:

```text
1,000 Cards
```

and only:

```text
10 Cards added
5 Cards modified
3 Cards deleted
```

the device should ideally download only the necessary changes.

The update system should therefore support change information such as:

```text
ADDED
MODIFIED
DELETED
```

This dramatically reduces:

* Download size
* Bandwidth consumption
* Update time
* Server requests
* User waiting time

It also helps BiGuess remain within free-tier infrastructure limits.

---

# 16. Pack Revisions

Users do not need to see technical version numbers.

BiGuess can internally use:

* Revision numbers
* Change IDs
* Timestamps
* Hashes
* Manifests
* Other synchronization metadata

to determine whether the local Pack matches the cloud.

For example:

```text
Local revision: 184
Cloud revision: 187
```

The user does not need to see this.

The application only needs to communicate something meaningful:

```text
Update available
```

---

# 17. Checking for Updates

Update checking should be lightweight.

BiGuess should first determine whether anything changed before downloading heavy content.

The preferred flow is:

```text
Check lightweight metadata
        ↓
No changes?
        ↓
Nothing to download

OR

Changes detected
        ↓
Determine required files
        ↓
Download only changes
```

Checking for updates must not automatically mean downloading updates.

This distinction is important for users with limited mobile data.

---

# 18. Manual Updates

Large content downloads should not happen silently in the background.

The user should have control over when substantial Pack updates are downloaded.

BiGuess may inform the user:

```text
3 Packs have updates available.

[ Update Now ]
```

The user can then decide when to perform the download.

Lightweight update checks are acceptable, but the actual transfer of large content should remain controlled.

---

# 19. No Realtime Content Synchronization

BiGuess does not require realtime synchronization.

There is no need for:

* Realtime database listeners
* Continuous polling
* Live Pack synchronization
* Gameplay synchronization
* Persistent connections between devices

This reduces:

* Infrastructure usage
* Battery consumption
* Network traffic
* Complexity
* Free-tier costs

Content changes can be detected during appropriate synchronization moments instead.

---

# 20. Studio Synchronization

BiGuess Studio follows the same local-first philosophy.

After logging in and obtaining the required working data, Studio should cache relevant information locally.

Studio should not repeatedly request the same data from the backend for every screen interaction.

Instead:

```text
Studio
  ↓
Local data
  ↓
User works locally
  ↓
Changes are batched
  ↓
Cloud synchronization
```

The exact implementation may differ between Studio and the mobile game, but unnecessary repeated backend operations should be avoided.

---

# 21. Content Created by Trusted Collectors

BiGuess Studio collectors are trusted members of the project team.

They are not treated like future public community contributors.

Therefore, trusted collectors should be able to manage content efficiently without requiring the Owner Admin to manually approve every single modification.

This is especially important because the project owner needs to remain focused on application development rather than becoming a bottleneck for content management.

---

# 22. Updating a Published Pack

A published Pack may be updated directly by an authorized Studio collector.

The workflow is:

```text
Published Pack
      ↓
Collector edits Pack
      ↓
Adds / modifies / removes Cards
      ↓
Collector saves changes
      ↓
Pack receives a new internal revision
      ↓
Published Pack is updated
      ↓
Devices detect the change
      ↓
Devices download required changes
```

There is no requirement for Owner Admin approval for every update to a published Pack.

This is based on the assumption that Studio collectors are trusted members of the BiGuess team.

The purpose is to keep content production efficient and prevent the Owner Admin from becoming a permanent approval bottleneck.

---

# 23. Publishing Rules

Publishing applies to:

* Topics
* Packs

Publishing does **not** apply to individual Cards.

Cards are managed as part of their Pack.

A Pack being published means that its content is eligible for distribution to the mobile application.

A Topic being published controls whether that Topic and its Packs are visible/available to users.

The hierarchy is therefore:

```text
Topic
   ↓
Pack
   ↓
Cards
```

Publishing happens at the Topic and Pack levels.

---

# 24. Pack Deletion

There is only **one deletion behavior** for Packs.

BiGuess does not distinguish between different deletion types.

When a Pack is removed from the cloud:

1. The Pack is no longer available for new downloads.
2. Connected devices learn that the Pack has been deleted.
3. The local Pack is deleted from those devices.
4. The Pack becomes unavailable for gameplay.

The goal is to keep the local device synchronized with the actual cloud catalog.

---

# 25. Device Behavior After Cloud Deletion

A device cannot know about a deletion while it is completely offline.

Therefore:

```text
Cloud Pack deleted
        ↓
Device offline
        ↓
Existing local Pack may temporarily remain
        ↓
Device reconnects
        ↓
Synchronization detects deletion
        ↓
Local Pack is immediately deleted
```

As soon as the device has connectivity and receives the information that the Pack has been deleted, it should remove the local Pack.

There are no separate deletion categories or complicated deletion modes.

This keeps both the Studio workflow and the mobile synchronization implementation simpler.

---

# 26. Deletion vs Local Storage Management

Deleting a Pack from the cloud is different from the user removing a downloaded Pack from their own device.

### User removes local download

The cloud Pack still exists.

```text
Cloud: AVAILABLE
Device: NOT_DOWNLOADED
```

The user can download it again later.

### Pack is deleted from the cloud

The Pack no longer exists as an available cloud Pack.

```text
Cloud: DELETED
Device: DELETED
```

Once the device learns about the deletion, the local copy must be removed.

---

# 27. Deleted Content and Synchronization

Synchronization metadata should allow the client to know that a Pack was deleted.

Simply making the Pack disappear from a database query is not always sufficient because a device may already possess an old local copy.

Therefore, the distribution system needs a way for clients to detect:

```text
Pack X → deleted
```

This can be implemented using appropriate deletion/change metadata.

The implementation details depend on the final backend, but the product rule is simple:

> **If the cloud says the Pack is deleted, a connected device must remove its local copy.**

---

# 28. Local Storage

Downloaded content should be stored in the application's private storage area.

Images should not simply be placed in ordinary public folders as easily accessible:

```text
/storage/DCIM/biguess/card123.jpg
```

The goal is to make casual extraction and scraping more difficult.

The preferred approach is to:

* Store files inside private application storage
* Protect/encrypt sensitive content where practical
* Keep the content inaccessible through ordinary user-facing file browsing
* Avoid unnecessary permanent plaintext copies

This is not intended to provide impossible DRM.

A determined attacker with sufficient technical access may still extract content.

The goal is:

> **Make practical casual extraction difficult without harming gameplay performance.**

---

# 29. Performance of Protected Content

Content protection must not make the game feel slow.

The Game Engine should not perform expensive cryptographic operations every time a Card appears if this can be avoided.

Downloaded content should be prepared in a way that allows gameplay to remain fast.

The user experience should feel like:

```text
Show Card
↓
Instant
```

not:

```text
Show Card
↓
Decrypt
↓
Process
↓
Decode
↓
Wait
↓
Display
```

Protection should therefore be balanced against:

* Startup time
* Memory usage
* Storage usage
* Battery usage
* Gameplay responsiveness

---

# 30. Local Content Snapshot During Gameplay

Once a game starts, the Game Engine should work from a consistent local content snapshot.

An update or synchronization operation should not modify the active game pool in the middle of a round.

For example:

```text
Pack is updated
        ↓
Game already running
        ↓
Current game continues using its snapshot
```

The updated Pack can become active for the next game.

This prevents unpredictable behavior such as Cards disappearing or changing while players are already playing.

---

# 31. Offline Catalog Information

BiGuess may cache lightweight catalog information locally.

This allows the application to show previously known Topics and Packs even when the user is offline.

For example:

```text
Offline

Downloaded:
✓ Anime Heroes
✓ Anime Villains

Not downloaded:
○ Anime Movies
```

The user should be able to identify which content is available locally without requiring an internet connection.

However, offline catalog information is only a local snapshot.

The cloud remains authoritative once synchronization occurs.

---

# 32. Storage Management

Downloaded Packs are persistent content, not temporary cache data.

BiGuess should eventually provide a way for the user to manage downloaded content.

For example:

```text
Downloaded Packs

Anime Heroes       32 MB
Anime Villains     41 MB
Football Legends   58 MB

[ Remove Download ]
```

Removing a local download should free device storage without deleting the cloud Pack.

This distinction should remain clear throughout the architecture:

```text
Cloud content
      ≠
Local downloaded content
```

---

# 33. App Updates vs Content Updates

BiGuess has two independent update systems.

## Application Update

The application itself is updated through the platform's normal distribution mechanism.

Application updates contain:

* Flutter code
* UI
* Game Engine changes
* Bug fixes
* New features
* Technical improvements

## Content Update

Content updates happen through the BiGuess content distribution system.

Content updates contain:

* Topics
* Packs
* Cards
* Images
* Content changes

This separation allows content to evolve without requiring a new application release every time a Card is added.

---

# 34. Example: Adding Cards to a Published Pack

Suppose:

```text
Anime Heroes
```

contains:

```text
500 Cards
```

A trusted collector adds:

```text
25 new Cards
```

The Pack remains published.

Its internal revision changes.

A device that already has the Pack eventually detects:

```text
Update available
```

The device downloads only the new content required.

After verification:

```text
500 Cards
+
25 new Cards
=
525 Cards
```

The user does not need to reinstall the application.

---

# 35. Example: Modifying a Card

Suppose a collector changes the image of:

```text
Card 127
```

The synchronization system should identify that the Card or its image changed.

The device does not need to download the entire Pack again.

Instead:

```text
Card 127 image
      ↓
Changed
      ↓
Download new image
      ↓
Verify
      ↓
Replace local content
```

---

# 36. Example: Removing a Card

If a Card is removed from a Pack:

```text
Cloud:
Card 127 → deleted
```

the next synchronization should tell the device that the Card no longer belongs to the current Pack revision.

The device removes that local Card content as part of the Pack update.

Again, there is no need to redownload the entire Pack.

---

# 37. Example: Deleting an Entire Pack

If:

```text
Anime Heroes
```

is deleted from the cloud:

```text
Cloud
  ↓
Pack deleted
```

a device that is currently offline may temporarily retain its local copy.

When it reconnects:

```text
Synchronization
      ↓
Pack deletion detected
      ↓
Local Pack deleted
```

The Pack is then no longer available for gameplay.

There are no alternative deletion modes.

---

# 38. Free-Tier Optimization

BiGuess is designed to remain within the available free infrastructure tiers for as long as possible.

This is an explicit architectural requirement.

The system should optimize usage rather than assuming that infrastructure can simply be upgraded when limits are reached.

Important principles include:

* Avoid per-Card backend reads during gameplay
* Avoid realtime listeners
* Avoid polling
* Avoid repeated downloads
* Download Packs in bulk
* Cache content locally
* Use lightweight manifests/change information
* Use incremental updates
* Batch Studio operations
* Avoid unnecessary image transfers
* Store images outside the database when appropriate
* Avoid downloading content that the user did not request
* Avoid syncing unchanged content
* Remove deleted content from devices when synchronization detects deletion

The architecture should favor **fewer, larger, meaningful operations** over thousands of small operations.

---

# 39. Bandwidth Optimization

Bandwidth is especially important because Cards contain images.

The system should therefore avoid:

```text
1 Card
→ 1 request
→ 1 image
→ 1 database operation
```

whenever a more efficient Pack-level operation is possible.

Instead:

```text
Pack
→ manifest
→ required changes
→ batched content transfer
```

The exact transport mechanism depends on the selected backend and storage provider.

---

# 40. Synchronization Philosophy

The overall synchronization philosophy is:

```text
LOCAL FIRST
    ↓
Use local content whenever possible
    ↓
Check lightweight cloud metadata when appropriate
    ↓
Detect changes
    ↓
Download only required changes
    ↓
Verify changes
    ↓
Atomically activate them
```

The cloud should not be queried simply because the user opened a game.

The local device should be trusted to provide the content that has already been downloaded.

---

# 41. What Distribution & Updates Must NOT Become

The distribution system should not evolve into a complicated realtime content platform.

BiGuess does not need:

* Player-to-player synchronization
* Game rooms
* Bluetooth communication
* Wi-Fi game sessions
* Realtime gameplay servers
* Cloud game state
* Server-side Card selection
* Continuous device synchronization
* Mandatory internet gameplay
* Complex deletion categories
* Manual Admin approval for every trusted collector edit

These features would add complexity without improving the core BiGuess experience.

---

# 42. Final Architecture Principle

The Distribution & Updates system should remain simple:

```text
                 CLOUD
                   │
          Topics / Packs / Cards
                   │
             Lightweight
              synchronization
                   │
                   ▼
                DEVICE
                   │
          Downloaded Packs
                   │
                   ▼
             LOCAL STORAGE
                   │
                   ▼
              GAME ENGINE
                   │
                   ▼
          COMPLETELY OFFLINE
               GAMEPLAY
```

The system should make content easy to create, distribute, update, and remove while keeping gameplay independent from the network.

The most important rule is:

> **Download once. Verify it. Store it locally. Play offline. Update only when something actually changed. Delete it when the cloud says it is deleted.**

---

## Costs

## 1. Cost Philosophy

BiGuess is a community-oriented project and is not expected to generate revenue during the initial stages.

The project therefore follows a strict cost principle:

> **BiGuess should operate within free-tier infrastructure for as long as reasonably possible.**

The architecture must be designed around efficient resource usage rather than assuming that infrastructure can be upgraded whenever limits are reached.

This means:

* Prefer free infrastructure.
* Minimize database reads and writes.
* Avoid unnecessary network requests.
* Avoid realtime services unless they become genuinely necessary.
* Cache content locally.
* Download content in Packs rather than individual Cards during gameplay.
* Download only changed content during updates.
* Compress Card images aggressively while maintaining acceptable visual quality.
* Avoid storing large binary files inside the database.
* Batch operations whenever possible.
* Avoid infrastructure that creates unnecessary recurring costs.
* Monitor usage before considering paid upgrades.
* Optimize the architecture before increasing infrastructure capacity.

The goal is not to guarantee that BiGuess will always cost exactly `$0`. Infrastructure providers can change their pricing, quotas, and terms.

The goal is to make the architecture **naturally inexpensive enough to remain inside available free tiers for as long as possible**.

---

# 2. Cost Model

BiGuess has an unusually favorable cost model because the actual game is offline.

The application does not require:

* Realtime multiplayer servers.
* Persistent game sessions.
* Matchmaking servers.
* Voice servers.
* Video servers.
* Game-state synchronization.
* Server-side Card selection.
* Per-turn API requests.
* Continuous telemetry.
* Realtime database listeners.
* WebSocket connections during gameplay.

The network is primarily used for:

1. Browsing Topics and Packs.
2. Checking Pack information.
3. Downloading Packs.
4. Checking whether downloaded content has changed.
5. Downloading changed content.
6. Studio synchronization.
7. Studio content management.

Once a Pack is downloaded, the actual game can run completely offline.

This makes **content distribution**, rather than gameplay infrastructure, the primary cost consideration.

---

# 3. Recommended Infrastructure

The current preferred infrastructure architecture is:

```text
Cloudflare
│
├── Workers
│   └── BiGuess API
│
├── D1
│   └── Structured metadata
│
└── R2
    └── Card images / content files
```

Studio authentication can use:

```text
Google
   │
   ▼
Firebase Authentication
   │
   ▼
BiGuess Studio
   │
   ▼
Cloudflare Workers API
```

The exact provider selection remains subject to reevaluation if free-tier limits, pricing, or project requirements change.

---

# 4. Cloudflare D1

Cloudflare D1 is the preferred database for BiGuess's structured content.

D1 is a serverless SQL database based on SQLite semantics and is available on Cloudflare's Free and Paid Workers plans.

D1 is suitable because BiGuess's content model is naturally relational:

```text
Topic
 └── Pack
      └── Card
```

The database can contain information such as:

* Topics
* Packs
* Cards
* Difficulty
* Pack relationships
* Publication state
* Revision information
* Content hashes
* Deletion markers
* Contributor information
* Studio-related metadata

The database should **not** store Card images as large BLOBs.

Images belong in object storage.

---

# 5. D1 Free-Tier Capacity

The current Cloudflare Workers Free plan provides D1 with:

| Resource         |      Free allowance |
| ---------------- | ------------------: |
| Rows read        |       5 million/day |
| Rows written     |         100,000/day |
| Total D1 storage |                5 GB |
| Data egress      | No D1 egress charge |

D1 does not charge for data transfer/egress from the database.

The Free plan also currently supports up to:

* 10 D1 databases per account.
* 500 MB maximum size per individual database.
* 5 GB total D1 storage per account.
* 50 D1 queries/subrequests per Worker invocation.

For BiGuess, these limits are sufficient for the expected MVP architecture.

---

# 6. Important D1 Free-Tier Consideration

Beginning September 1, 2026, Cloudflare began enforcing D1 Free-plan daily row-read and row-write limits.

If an account exceeds its daily free allowance, D1 queries fail until the daily limit resets.

The stored data itself is not deleted or affected.

Therefore, BiGuess must treat database efficiency as an architectural requirement.

The application must not depend on unlimited database queries.

Instead:

```text
GOOD

App
 │
 ├── lightweight catalog request
 │
 ├── Pack manifest request
 │
 └── Pack download
       │
       ▼
    LOCAL DATA
       │
       ▼
    OFFLINE GAME
```

Not:

```text
BAD

App
 │
 ├── Card request
 ├── Card request
 ├── Card request
 ├── Card request
 ├── Card request
 └── ...
```

---

# 7. D1 Query Optimization Rules

BiGuess should follow these rules:

### 7.1 No database requests during gameplay

Once required Packs are available locally, the Game Engine should use local data.

```text
Gameplay
   │
   └── Local storage / memory
```

No database request should be required to:

* Select a Card.
* Display a Card.
* Read Card difficulty.
* Read Card name.
* Build the temporary randomization pool.
* Advance to the next Card.

---

### 7.2 Avoid full-table scans

Queries should use appropriate indexes.

For example:

```sql
SELECT *
FROM cards
WHERE pack_id = ?;
```

should be supported by an index on `pack_id`.

This reduces unnecessary row reads and is particularly important because D1's free tier measures rows read.

---

### 7.3 Prefer batch queries

When several related records are needed, they should be retrieved efficiently rather than through many independent requests.

---

### 7.4 Cache catalog information

The mobile application can keep lightweight information about:

* Topics.
* Packs.
* Publication state.
* Pack revisions.
* Approximate download size.

This allows the application to avoid repeatedly requesting unchanged information.

---

### 7.5 No realtime listeners

Realtime synchronization is not required for the MVP.

The application should use explicit refresh/update checks.

---

# 8. Cloudflare R2

Cloudflare R2 should be used for Card images and other large content files.

R2 is preferable to storing images directly inside D1 because object storage is designed for binary files.

The architecture becomes:

```text
D1
 │
 └── Card metadata
       │
       └── image reference/hash
                  │
                  ▼
                 R2
                  │
                  └── actual image
```

Cloudflare R2 currently provides:

| Resource           |   Free allowance |
| ------------------ | ---------------: |
| Standard storage   |      10 GB-month |
| Class A operations |  1 million/month |
| Class B operations | 10 million/month |
| Internet egress    |             Free |

The absence of Internet egress charges is particularly useful for BiGuess because Pack downloads can involve significant outbound data.

---

# 9. Card Image Size Requirement

BiGuess has a strict content optimization target:

> **Each Card image should be compressed to less than 50 KB whenever acceptable visual quality can be maintained.**

This requirement exists for both:

* User download size.
* Infrastructure cost control.

Images should be compressed automatically by BiGuess Studio.

The Collector should not need to manually optimize images.

---

# 10. Pack Size Requirement

The target Pack size is:

> **Generally under 10 MB per Pack.**

The 10 MB target is not necessarily an absolute technical maximum because a Pack contains metadata, manifests, and potentially other supporting files.

The preferred rule is:

> Packs should normally remain below 10 MB, and individual Card images should normally remain below 50 KB.

For example:

```text
200 Cards
×
~50 KB/image
≈
10 MB
```

This makes Pack downloads reasonably lightweight while allowing substantial content.

---

# 11. Why Pack-Based Distribution Controls Costs

The Pack is the primary content distribution unit.

BiGuess should not download individual Cards during normal gameplay.

Instead:

```text
User chooses Pack
        │
        ▼
Download Pack
        │
        ▼
Store locally
        │
        ▼
Play offline
```

This means that the number of gameplay sessions does not directly translate into database requests or image downloads.

A user can play the same Pack:

```text
1 time
10 times
100 times
1000 times
```

without repeatedly downloading its Cards.

This is one of the most important cost-control decisions in the architecture.

---

# 12. Download Once, Play Offline Without Periodic Validation

Downloaded content does not expire and requires no periodic online checks.

> **Download once, then play offline without periodic license checks or mandatory online validation (until removed locally by the user or removed via synchronized cloud deletion).**

After a Pack has been successfully downloaded and verified:

```text
Pack = AVAILABLE
```

The user can play it without an Internet connection.

BiGuess should not require:

* Online license checks.
* Periodic content validation before gameplay.
* Server confirmation before starting a game.
* Repeated image downloads.
* Repeated Pack downloads.

This reduces both infrastructure usage and dependence on network availability while remaining fully consistent with the cloud deletion synchronization policy.

---

# 13. Incremental Updates

BiGuess should never redownload an entire Pack when only a small part of the Pack has changed.

The update system should identify:

* Added Cards.
* Modified Cards.
* Deleted Cards.
* Changed images.
* Changed metadata.

For example:

```text
Current Pack
100 Cards

Remote Pack
100 Cards

Changes:
+ 3 Cards
~ 2 Cards modified
- 1 Card deleted

Required download:
5 Card changes
```

rather than:

```text
Download entire 100-Card Pack again
```

This significantly reduces bandwidth usage.

---

# 14. Image Deduplication and Reuse

The system should avoid downloading an image again when its content has not changed.

An image hash or equivalent content identifier can be used.

Conceptually:

```text
Local image hash
        │
        ▼
Compare with remote reference
        │
   ┌────┴────┐
   │         │
 Same      Changed
   │         │
 Keep      Download
```

This reduces unnecessary R2 operations and mobile data usage.

---

# 15. Local Storage

Downloaded Pack content should be stored inside the application's private storage area.

The application should distinguish between:

```text
Downloaded Content
```

and:

```text
Temporary Cache
```

Downloaded content represents Packs that the user intentionally made available offline.

Temporary cache represents disposable technical data.

The user should eventually be able to manage downloaded Packs and delete local copies without affecting the cloud copy.

---

# 16. Local Content Protection

Card images should not simply be placed in publicly accessible phone storage as ordinary JPG/PNG files.

The application should use private application storage and, where practical, additional protection/encryption.

This is not intended to provide perfect DRM.

A sufficiently determined person can always extract content from a device that is allowed to display it.

The goal is to prevent casual extraction while keeping gameplay fast.

Protection mechanisms must therefore not introduce noticeable delays when displaying Cards.

---

# 17. Cloudflare Workers

Cloudflare Workers should act as the API layer between BiGuess clients and the backend.

The preferred architecture is:

```text
Flutter
   │
   ▼
Cloudflare Worker
   │
   ├── Authentication / authorization
   ├── Request validation
   ├── API logic
   ├── D1 queries
   └── R2 operations
```

The Flutter applications should not directly expose database credentials or unrestricted database access.

Workers Free currently provides 100,000 requests/day, with 10 ms CPU time per invocation on the Free plan. Cloudflare does not charge additional egress/throughput fees for Workers.

For the expected BiGuess MVP traffic pattern, this should provide substantial room.

---

# 18. API Efficiency

The API should be designed around coarse-grained operations rather than tiny requests.

Good:

```text
GET /topics
GET /packs/{id}/manifest
GET /packs/{id}/changes
```

Bad:

```text
GET /card/1
GET /card/2
GET /card/3
GET /card/4
...
```

The API should return everything needed for a logical operation in as few requests as practical.

---

# 19. Studio Cost Optimization

BiGuess Studio is expected to generate more backend activity than the mobile game because it creates and modifies content.

However, Studio should also be local-first.

The intended model is:

```text
First Login
    │
    ▼
Download required Studio data
    │
    ▼
Local working data
    │
    ▼
User works locally
    │
    ▼
Batch synchronization
```

Studio should not write to the database on every keystroke.

For example, typing:

```text
N
Na
Nar
Naru
Narut
Naruto
```

must not generate six database writes.

Instead, the final Card name should be synchronized when the operation is committed.

---

# 20. Image Compression in Studio

Image optimization should happen automatically in Studio.

The Collector uploads an image:

```text
Original image
      │
      ▼
Studio compression
      │
      ▼
Optimized image
      │
      ▼
R2
```

The Collector should not have to manually resize or compress the image.

This simultaneously:

* Reduces storage usage.
* Reduces download size.
* Reduces bandwidth usage.
* Improves mobile download times.
* Reduces long-term infrastructure requirements.

---

# 21. Firebase Authentication

Firebase Authentication can be used for Google authentication in BiGuess Studio.

Firebase currently provides a no-cost Spark plan, and Firebase lists several authentication services as no-cost within applicable limits. Google authentication should therefore be kept separate from the main content infrastructure rather than using Firebase as the entire BiGuess backend.

The intended architecture is:

```text
Google Account
      │
      ▼
Firebase Authentication
      │
      ▼
BiGuess Studio
      │
      ▼
Cloudflare Worker
      │
      ▼
D1 / R2
```

Authentication and content storage therefore remain separate concerns.

---

# 22. Why Not Use Firebase Firestore for Everything?

Firebase is not inherently unsuitable for BiGuess.

However, the project does not need many of the features that make Firebase particularly attractive.

BiGuess does not require:

* Realtime game synchronization.
* Realtime listeners.
* Server-side game sessions.
* Persistent multiplayer state.
* Per-turn database requests.

The content model is also naturally relational:

```text
Topic
  ↓
Pack
  ↓
Card
```

Therefore, SQL is a better conceptual fit for the main content database.

Firebase Authentication can still be used independently where it provides a convenient solution.

---

# 23. Why Not Use a Traditional VPS?

A traditional VPS is unnecessary for the MVP.

BiGuess does not require a permanently running server.

Using a VPS would introduce:

* Server maintenance.
* Operating system updates.
* Monitoring.
* Security maintenance.
* Fixed infrastructure costs.
* More operational complexity.

Serverless infrastructure better matches BiGuess's usage pattern.

---

# 24. Why Not Store Everything in One Service?

Using one provider for everything can look simpler, but it is not necessarily the best architecture.

BiGuess has different types of requirements:

```text
Authentication
    → Firebase Auth

Structured data
    → D1

Binary files
    → R2

API
    → Workers

Mobile local gameplay
    → Device storage
```

Each component is selected according to its job.

This also prevents the entire application from becoming tightly coupled to one backend product.

---

# 25. Cost-Control Rules

The following rules are considered architectural requirements.

### Rule 1 — No network during normal gameplay

Downloaded Packs must be sufficient to play offline.

### Rule 2 — No per-Card API requests during gameplay

Cards come from local storage.

### Rule 3 — No realtime database listeners

Realtime functionality is unnecessary for MVP.

### Rule 4 — No polling

The application should not repeatedly ask the server whether content changed.

### Rule 5 — Separate checking from downloading

A lightweight update check must not automatically trigger a large download.

### Rule 6 — Pack-level distribution

Content should be downloaded as Packs rather than one Card at a time during gameplay.

### Rule 7 — Incremental updates

Only changed content should be downloaded.

### Rule 8 — Compress images

Card images should normally be below 50 KB.

### Rule 9 — Keep Packs small

Packs should generally remain below 10 MB.

### Rule 10 — Batch Studio operations

Avoid unnecessary individual writes.

### Rule 11 — Cache aggressively

Previously downloaded information should not be repeatedly requested.

### Rule 12 — Avoid duplicate downloads

Use hashes/revisions to determine whether content has actually changed.

### Rule 13 — Do not store images in the SQL database

Binary content belongs in object storage.

### Rule 14 — Monitor usage

Backend usage should be periodically reviewed to identify inefficient queries or unexpectedly expensive operations.

### Rule 15 — Optimize before upgrading

If usage approaches a free-tier limit, the first response should be optimization rather than immediately moving to a paid plan.

---

# 26. Expected Traffic Pattern

BiGuess's expected traffic pattern is intentionally asymmetric.

```text
                    NETWORK USAGE

Browsing             ███
Pack download        ████████████████████
Pack update          ████
Studio               ██████
Gameplay             ▏
```

Gameplay should represent almost no network activity.

The expensive operation is the initial Pack download.

This is acceptable because downloading a Pack is an explicit user action and occurs much less frequently than playing the game.

---

# 27. Example: 1,000 Users

Assume:

```text
1,000 users
×
1 Pack
×
10 MB
```

The initial distribution represents approximately:

```text
10 GB
```

of downloaded content.

If the users subsequently play the Pack many times without updating it, those gameplay sessions should not create another 10 GB of downloads.

This is the key difference between BiGuess and an online game.

---

# 28. Example: 10,000 Users

Assume:

```text
10,000 users
×
5 Packs
×
10 MB
```

The potential initial content distribution is approximately:

```text
500 GB
```

This is where content distribution and R2 storage/operations become much more important than D1.

However, R2 currently has no Internet egress charge, which is highly favorable for this type of workload.

The project should nevertheless monitor:

* Total stored content.
* Number of Pack downloads.
* R2 operations.
* Worker requests.
* D1 row reads.
* D1 row writes.

---

# 29. The Main Long-Term Cost Risk

The main cost risk is **not the SQL database**.

The primary risks are:

1. Number of users.
2. Number of Pack downloads.
3. Total amount of content stored.
4. Number of images.
5. Frequency of content updates.
6. Inefficient API/database queries.
7. Unnecessary repeated downloads.

Therefore, content size and distribution efficiency must remain important design constraints.

---

# 30. Free-Tier Growth Strategy

BiGuess should grow through optimization stages.

### Stage 1 — MVP

Target:

```text
$0/month
```

Use:

* Cloudflare Workers Free.
* Cloudflare D1 Free.
* Cloudflare R2 Free allowance.
* Firebase Authentication no-cost tier.
* Local mobile storage.

---

### Stage 2 — Growing Community

If usage increases:

1. Measure actual consumption.
2. Identify the bottleneck.
3. Optimize the relevant component.
4. Reduce unnecessary requests/downloads.
5. Only then evaluate whether the free tier is still sufficient.

The project should not upgrade every component simply because the user base grows.

---

### Stage 3 — Large Community

If BiGuess eventually becomes large enough that free infrastructure is insufficient, the architecture should allow individual components to scale independently.

For example:

```text
D1
 │
 ├── remains sufficient
 │
 └── Workers reaches limit
          │
          ▼
      Evaluate scaling

R2
 │
 └── content storage grows
          │
          ▼
      Evaluate storage cost
```

There is no requirement that every component move to a paid plan simultaneously.

---

# 31. No Artificial Infrastructure Complexity

BiGuess should not introduce infrastructure simply because it may become useful someday.

For MVP, avoid:

* Redis.
* Kubernetes.
* Dedicated servers.
* Message queues unless required.
* Realtime infrastructure.
* Dedicated CDN configuration unless necessary.
* Microservices.
* Multiple databases.
* Complex event buses.

The preferred architecture is:

```text
Flutter
   │
   ▼
Workers
   │
   ├── D1
   └── R2
```

with Firebase Authentication for Studio login.

Simple infrastructure is cheaper, easier to maintain, and easier to replace.

---

# 32. Monitoring

BiGuess should monitor infrastructure usage from the beginning.

Important metrics include:

### D1

* Rows read/day.
* Rows written/day.
* Storage usage.
* Most expensive queries.
* Full-table scans.

### Workers

* Requests/day.
* CPU usage.
* Failed requests.
* API endpoint usage.

### R2

* Storage size.
* Class A operations.
* Class B operations.
* Pack download volume.
* Image update volume.

### Application

* Number of downloaded Packs.
* Pack download failures.
* Update failures.
* Average Pack size.
* Number of Cards per Pack.

Monitoring should be used primarily to identify optimization opportunities.

---

# 33. Usage Alerts

The project should define internal warning thresholds before reaching provider limits.

For example:

```text
< 50%       Normal
50–70%      Monitor
70–85%      Investigate
85–95%      Optimize
> 95%       Immediate action
```

The exact thresholds can be adjusted after real usage data is available.

The important principle is to discover inefficient behavior **before** the infrastructure reaches a hard limit.

---

# 34. Database Failure and Free-Tier Exhaustion

The application must not assume that the backend is always available.

If the user already has downloaded Packs:

```text
Backend unavailable
       │
       ▼
Downloaded Packs
       │
       ▼
Game continues offline
```

This is another major benefit of the offline-first architecture.

Backend failure should primarily affect:

* Browsing new content.
* Downloading new Packs.
* Checking updates.
* Studio synchronization.

It should not prevent an already downloaded Pack from being played.

---

# 35. Cloud Deletion and Cost Control

When a Pack is deleted from the cloud, connected devices must remove their local copy once they reconnect and learn that the Pack has been deleted.

The system should therefore maintain deletion information/tombstones long enough for clients to discover the deletion.

This prevents deleted content from remaining indefinitely on connected devices while also avoiding the need for realtime deletion notifications.

Deletion records should eventually be cleaned according to a defined retention policy to avoid unnecessary database growth.

---

# 36. Content Retention

Content that is permanently deleted from the cloud should eventually be removed from:

* D1.
* R2.
* Relevant manifests.
* Temporary processing storage.

The exception is information required for:

* Contribution history.
* Statistics.
* Auditing.
* Deletion synchronization.

The retention period should be kept as short as practical while preserving the required history.

---

# 37. Cost of Community Content

Future community-generated content may significantly increase storage and download requirements.

However, the same architecture remains applicable:

```text
Community submission
        │
        ▼
Studio review
        │
        ▼
Accepted content
        │
        ▼
Published Pack
        │
        ▼
R2
```

Rejected content should not remain indefinitely.

The existing rule that refused submissions are permanently deleted after one week also helps control unnecessary storage usage.

---

# 38. Cost and Content Quality

Cost optimization must not destroy the actual game experience.

For example, the project should not aggressively compress images to the point where:

* Characters become difficult to recognize.
* Images contain severe artifacts.
* Text inside an image becomes unreadable.
* The visual quality becomes noticeably poor.

The target is:

> **Small enough to distribute efficiently while still looking good during real gameplay.**

The `<50 KB` target is therefore a strong optimization target, not a reason to destroy image quality.

---

# 39. Infrastructure Decision

The current preferred MVP infrastructure is:

| Component      | Technology             | Purpose                        |
| -------------- | ---------------------- | ------------------------------ |
| Mobile app     | Flutter                | Gameplay                       |
| Studio         | Flutter                | Content management             |
| Authentication | Firebase Auth          | Studio Google login            |
| API            | Cloudflare Workers     | Secure backend API             |
| Database       | Cloudflare D1          | Topics, Packs, Cards, metadata |
| Object storage | Cloudflare R2          | Images and content files       |
| Local storage  | Private device storage | Offline Packs                  |
| Game state     | Local/in-memory only   | Active game                    |

This architecture is optimized around BiGuess's central principle:

> **Download content once, then play offline.**

---

# 40. Cost Target

The intended MVP infrastructure target is:

> **$0/month.**

This is not a guarantee that the project will remain free forever.

Instead, the architecture is explicitly designed to make `$0/month` achievable during the early life of the project and to delay paid infrastructure until real usage demonstrates that it is necessary.

---

# 41. When Paid Infrastructure Becomes Acceptable

Paid infrastructure should only be considered when:

1. Free-tier limits are genuinely being reached.
2. The relevant workload has already been optimized.
3. The project has meaningful active usage.
4. The cost is justified by the project's scale or sustainability.
5. The alternative of changing providers has been evaluated.

The project should not pay simply to avoid optimizing inefficient architecture.

---

# 42. Cost Philosophy Summary

BiGuess is designed to be:

```text
Offline-first
      +
Pack-based
      +
Cache-heavy
      +
Incrementally updated
      +
Image-optimized
      +
Batch-synchronized
      +
Serverless
      +
Free-tier oriented
```

The central cost principle is:

> **Do the expensive work rarely, cache it locally, and avoid repeating it.**

A user should be able to download a Pack once and play it hundreds of times without generating hundreds of corresponding database or image requests.

This is the fundamental reason BiGuess can remain inexpensive even as usage grows.

---

# 43. Provider Re-Evaluation

Cloudflare D1 + R2 + Workers is the current preferred architecture, but provider selection must not become an irreversible product decision.

Infrastructure should be periodically reevaluated based on:

* Current free-tier limits.
* Pricing changes.
* Reliability.
* Performance.
* Storage requirements.
* Bandwidth requirements.
* Developer experience.
* Security.
* Migration difficulty.

The project should avoid provider-specific assumptions in the application layer where practical.

The goal is not to use Cloudflare for its own sake.

The goal is to use the **most cost-efficient infrastructure that satisfies BiGuess's requirements**.

---

# 44. Final Principle

BiGuess should never be architected around the assumption:

> "If we grow, we will simply pay more."

It should instead be architected around:

> **"If we grow, we first make the system more efficient."**

Only when optimization is no longer sufficient should infrastructure costs increase.

This principle is especially important because BiGuess is an offline social game whose infrastructure requirements should remain fundamentally small compared with a conventional online multiplayer game.

---

## Legal/IP

BiGuess may contain references to third-party characters, people, brands, fictional works, games, movies, sports figures, historical figures, and other subjects that may be protected by copyright, trademarks, publicity rights, or other intellectual-property rights.

BiGuess is an independent game and is not affiliated with, sponsored by, or endorsed by the owners of third-party franchises, characters, brands, teams, organizations, or other referenced properties unless explicitly stated.

### Third-Party Images

Images used in BiGuess may include third-party artwork, photographs, promotional material, or other visual assets.

BiGuess does not claim ownership of third-party images unless the relevant asset was created by BiGuess or its contributors.

Where practical, BiGuess should identify the source, creator, license, or rights information associated with an image. However, the absence of identified ownership information does not mean that an image is owned by BiGuess or automatically free to use.

For the current development/content phase, existing content may be retained while the product is being built. Future releases should progressively improve source, attribution, licensing, and rights metadata where practical.

### In-App Notice

BiGuess may display a short notice alongside third-party images to make the relationship with third-party intellectual property clear.

Example:

> **Third-party content:** This image or subject is used for identification and gameplay purposes. BiGuess is not affiliated with or endorsed by the respective rights holder.

This notice is intended for transparency and identification purposes. It does not grant BiGuess permission to use copyrighted material and should not be considered a substitute for a license or other legal authorization.

### Ownership

BiGuess claims ownership only over original material created for the project, including applicable:

* source code;
* original UI/UX designs;
* original graphics and interface assets;
* original game systems and implementation;
* original documentation;
* original branding created by the project.

Third-party names, characters, logos, photographs, artwork, trademarks, and other protected material remain the property of their respective owners.

The MIT license or other open-source license applied to BiGuess source code applies only to the project material covered by that license. It does not grant rights to third-party images, characters, trademarks, or other external content.

### Content and Community Submissions

BiGuess may eventually support community-created Topics, Packs, Cards, images, and other content.

Community content must not automatically become public.

Before publication, community submissions may be subject to moderation and review for:

* copyright concerns;
* trademark concerns;
* unauthorized use of third-party material;
* inappropriate content;
* spam;
* duplication;
* privacy concerns;
* other legal or platform-policy issues.

The planned community workflow is:

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
     /     \
 Accept    Reject
    |
    v
 Publish
    |
    v
Available to Players
```

This follows the existing BiGuess content architecture, where community content is intended to pass through moderation before becoming publicly available.

### Copyright and IP Reports

BiGuess should provide a way for rights holders or other users to report potentially problematic content.

A report may include:

* the affected Topic, Pack, Card, or image;
* the relevant content identifier;
* the reason for the report;
* supporting information or links;
* contact information where appropriate.

Reported content may be temporarily hidden, replaced, or removed while the issue is reviewed.

BiGuess should maintain a record of moderation and content actions where appropriate.

### Content Rights Metadata

The content system should be capable of storing rights-related metadata independently from the gameplay data.

Conceptually:

```text
Card
 ├── Subject / Identity
 ├── Image
 └── Metadata
       ├── Source
       ├── Creator
       ├── License
       ├── Attribution
       └── Rights Status
```

This allows an image to be replaced or updated without changing the identity of the Card.

The content architecture already separates Topics, Packs, Cards, Images, and metadata, allowing rights information to evolve independently from the core game engine.

### Content Removal

If BiGuess receives a credible copyright, trademark, privacy, or other intellectual-property complaint, the affected content may be removed or replaced.

Removal of an image does not necessarily require removal of the underlying Card or subject.

For example:

```text
Card: Naruto Uzumaki
        |
        v
   Image Asset A
        |
   Reported / Removed
        |
        v
   Image Asset B
```

The Card identity can remain while its visual asset is changed.

### Disclaimer

BiGuess may include a general intellectual-property notice in the application:

> BiGuess is an independent guessing game and is not affiliated with, sponsored by, or endorsed by the owners of third-party characters, people, brands, teams, franchises, or other referenced properties. Third-party names, characters, images, logos, and trademarks remain the property of their respective owners. If you believe content displayed by BiGuess infringes your rights, please contact us so the relevant content can be reviewed.

The disclaimer is intended to provide transparency. It does not itself create a license, permission, or legal right to use third-party material.

### Legal Status

This section describes the project's intended content and IP practices. It is not legal advice and does not constitute a legal opinion.

As BiGuess moves toward public distribution, monetization, large-scale community content, or commercial partnerships, the project's intellectual-property and content policies should be reviewed and updated based on the applicable laws, platform requirements, licenses, and business model.

---

## Business Possibilities

BiGuess should initially follow a **freemium access model**, rather than building its business around selling individual franchise or topic Packs.

The main objective of the free version is to let users genuinely experience BiGuess and build a habit of playing it. The Pro version should primarily remove meaningful usage limitations rather than simply give users access to “better” content.

### Free Version

The Free version should provide a complete and enjoyable core experience, while placing reasonable limits on content usage.

* Core BiGuess gameplay remains free.
* Users should not need an account just to play.
* Gameplay remains offline after content has been downloaded.
* Free users can download/store a limited number of Packs at the same time, currently considered **5 Packs**.
* The limit should preferably represent the number of Packs currently stored rather than a lifetime number of downloads. Users should be able to remove Packs and replace them with others.
* Free users have a limited selection of Cards available from downloaded Packs.
* The Free limitation is an **in-app Card access/selection policy**, not an alternate Pack download format. The device downloads the complete, standard Pack (preserving Pack integrity and validation), but the local Game Engine restricts the active playable pool to approximately **50 randomly selected Cards per Pack/session**.
* The limitation should feel like a restriction on access to the full Pack, not an artificial counter that permanently punishes users for playing.
* Note: BiGuess Cards store identities (Name, Subtitle, Description, Image), not trivia questions; questions are formulated verbally by players in real life. Therefore, limits apply strictly to available Card identities.

The download limitation also has a secondary technical benefit: it prevents the free version from accumulating a very large offline content library. However, this should not be the primary reason presented to users. The main business purpose is to create a meaningful distinction between Free and Pro.

### Pro Version

BiGuess Pro should remove the meaningful limits imposed on the Free version.

* Unlimited Pack storage/downloads.
* Full access to all Cards contained in downloaded Packs.
* No artificial gameplay limits on the number of available playable Cards.
* The core offline-first gameplay experience remains unchanged.

The Pro model should avoid adding unnecessary features purely to justify payment. Pro should primarily mean **full access to the BiGuess content experience**.

### Content and IP Strategy

BiGuess should **not initially use a model where some famous franchises are free while others are paid**.

For example, arbitrarily making one franchise Pack free and another franchise Pack paid would create difficult questions about why certain content is monetized and could create additional legal/IP complications.

BiGuess may reference third-party characters, people, brands, fictional works, games, movies, sports figures and other protected material. Commercializing such content introduces additional copyright, trademark, publicity-rights and licensing considerations. A disclaimer alone does not provide permission to commercially use protected content.

Therefore, the initial business model should **not depend on selling individual third-party franchise Packs**.

The long-term commercial content strategy can instead focus on content that BiGuess owns, has permission to use, or has properly licensed. Licensed partnerships, branded content and other commercial content opportunities can be considered later when the legal and business foundations are stronger.

### Why This Model Fits BiGuess

BiGuess's content architecture already treats the **Pack as the primary downloadable unit**, allowing the application itself to remain relatively small while the content library grows independently.

This makes a Pack-based access limit technically compatible with the product architecture.

The offline-first architecture also means that downloaded Packs can be played without continuous network access. Network usage is primarily needed for browsing, downloading and updating content rather than for every turn of gameplay.

The business model therefore becomes:

**Free → experience BiGuess with reasonable limits → Pro → remove those limits and access the full downloaded content.**

This is preferable to interrupting gameplay with aggressive advertising, forcing subscriptions from the beginning, or making users pay for individual pieces of potentially complicated third-party IP.

### Monetization Timing

BiGuess should not assume that monetization is valuable simply because it is technically possible.

The first priority is to establish that people actually enjoy BiGuess, play it repeatedly, and continue using it with other people. The existing product direction already emphasizes proving user demand before committing heavily to monetization.

Therefore, the Free version should be strong enough to validate the product rather than functioning as a deliberately crippled demo.

Once there is evidence of repeated usage and demand, Pro can become the primary monetization mechanism.

### Future Possibilities

These are **future possibilities, not current commitments**:

* Properly licensed content and franchise partnerships.
* BiGuess-owned official content.
* Brand-sponsored Packs or experiences.
* Community-created Packs with moderation.
* A creator/content marketplace.
* Custom Packs for events, organizations or other partnerships.

These should only be developed when BiGuess has enough users and a sufficiently mature legal, moderation and content-management system to support them.

The existing blueprint already treats community content as something that requires moderation before publication rather than allowing submissions to become automatically public.

### Business Principles

The business strategy should follow several principles:

1. **Pro should sell access, not arbitrary content scarcity.**
2. **Do not build the initial business model around unlicensed third-party IP.**
3. **Free users must still have a genuinely enjoyable game.**
4. **The Pack is the natural unit for content storage and access.**
5. **The download limit should preferably be a current-storage limit, not a lifetime download counter.**
6. **The question/Card limit should feel natural rather than like an annoying artificial quota.**
7. **Do not interrupt active gameplay with intrusive monetization.**
8. **Do not add a subscription simply because subscriptions generate recurring revenue.**
9. **Validate repeated user behavior before optimizing monetization.**
10. **Treat licensing, moderation and community content as later-stage business infrastructure, not MVP requirements.**
11. **Keep infrastructure costs proportional to real usage; low technical infrastructure cost is an advantage, but it does not eliminate content, legal, marketing or operational costs.**

The current business direction can therefore be summarized simply:

> **BiGuess is free to play, with meaningful limits on the amount of content a free user can keep and use. Pro removes those limits. The business should initially monetize the BiGuess experience itself rather than individual third-party franchises.**

---

## MVP

The BiGuess MVP exists to prove one thing:

> **Can a group of people quickly start a BiGuess game, enjoy playing it together, and come back to play again?**

The MVP therefore focuses on the smallest complete ecosystem required to deliver the real BiGuess experience:

```text
BiGuess Mobile
      │
      ▼
Content Backend
      ▲
      │
BiGuess Studio
```

The three systems must work together, but none should contain unnecessary complexity.

---

### 1. MVP Definition

The MVP is complete when a player can:

```text
Open BiGuess
    ↓
Choose a Topic
    ↓
Choose a Pack or Packs from that Topic
    ↓
Download required content
    ↓
Configure Difficulty + Rounds
    ↓
Start Game
    ↓
Receive random identities
    ↓
Play the real-world Yes/No game
    ↓
Continue through configured rounds
    ↓
Finish
```

After a Pack has been downloaded, the complete gameplay loop must work without an internet connection.

The application prepares and manages the digital parts of the game. Players control the actual social game.

---

### 2. Mobile MVP

BiGuess Mobile must provide:

#### Content

* Browse published Topics.
* Browse Packs belonging to a Topic.
* See Pack information and download state.
* Download Packs.
* Keep downloaded Packs available offline.
* Detect available updates.
* Incrementally update changed content.

The Pack is the primary download unit. Gameplay must use locally stored content rather than making per-Card network requests.

#### Game Setup

The player selects exactly one Topic and then chooses:

* One Pack.
* Multiple Packs from that Topic.
* Random Pack selection from that Topic.

The selected Packs form the game's Card pool.

MVP configuration:

* Difficulty.
* Number of rounds.

The configuration becomes fixed when the game starts.

#### Gameplay

Each device independently selects identities from its local Card pool.

The application:

* selects Cards randomly;
* displays the identity;
* manages round progression;
* supports starting another round quickly.

The application does **not**:

* record questions;
* record answers;
* verify guesses;
* determine winners;
* track scores;
* synchronize players;
* require network access during gameplay.

The real-world group handles those parts.

#### UX

The core experience should feel like:

> **Choose → Prepare → Reveal → Turn phones outward → Play**

The identity screen should behave like a digital physical card: clear, attractive, and unobtrusive.

Animations are allowed and encouraged where they improve the experience, but they must remain fast and purposeful.

---

### 3. Studio MVP

BiGuess Studio is required for the MVP because content must exist independently from the mobile application.

The first production-ready Studio includes:

#### Authentication

* Google Login.
* Firebase Authentication.
* Authorized-user verification.
* Role management.

Only authorized users can access Studio.

#### Topics

* Owner CRUD.
* Local browsing.
* Search/filter.

#### Packs

* Collector CRUD.
* Owner CRUD.
* Soft deletion.
* Owner restoration.
* Owner permanent deletion.
* Publishing.
* Unpublishing.

#### Cards

* Collector CRUD.
* Owner CRUD.
* Soft deletion.
* Owner restoration.
* Owner permanent deletion.
* Image upload.
* Automatic image compression.
* Difficulty assignment.
* Name editing.
* Filename-to-name convenience.
* Search/filter.

#### Bulk Content

Bulk creation is an important part of the MVP because manually creating hundreds of Cards would make content production unnecessarily slow.

Studio should support:

* Multiple-image import.
* Generated Card list.
* Per-Card review.
* Per-Card name editing.
* Per-Card difficulty assignment.
* Bulk actions.

#### Publishing

Before content becomes available to players:

```text
Create
  ↓
Edit
  ↓
Review
  ↓
Validate
  ↓
Publish
  ↓
Mobile Catalog
```

Publishing must validate the required content before making it available.

---

### 4. Studio Synchronization

Studio is local-first.

The intended workflow is:

```text
First Login
    ↓
Download Studio Dataset
    ↓
Work Locally
    ↓
Commit Changes
    ↓
Batch Synchronization
```

Studio must not write to the backend on every keystroke.

Refresh is manual and should use lightweight change detection followed by incremental synchronization. Realtime listeners, polling, and continuous synchronization are not part of the MVP.

Studio should also remain useful when temporarily offline for locally available content.

---

### 5. Content Backend MVP

The backend provides only what the product actually needs:

```text
Authentication
    → Firebase Auth

API
    → Serverless API

Structured Content
    → SQL Database

Images
    → Object Storage

Mobile
    → Local Device Storage
```

The current preferred direction is:

* Firebase Authentication for Studio authentication.
* Cloudflare Workers for the API.
* Cloudflare D1 for structured content.
* Cloudflare R2 for images.

The exact providers remain replaceable and must be isolated behind repositories/data-access layers.

The backend does **not** manage:

* game rooms;
* active game sessions;
* player connections;
* real-time state;
* scores;
* questions;
* winners.

---

### 6. MVP Data Model

The core content model remains deliberately small:

```text
Topic
├── id
└── name

Pack
├── id
├── topicId
└── name

Card
├── id
├── packId
├── name
├── imageReference
└── difficulty
```

Difficulty:

```text
1 = Easy
2 = Medium
3 = Hard
```

Selection is cumulative:

```text
Easy   → 1
Medium → 1 + 2
Hard   → 1 + 2 + 3
```

The Card model must remain generic and topic-agnostic.

---

### 7. Offline Requirement

Offline gameplay is a hard MVP requirement, not an optional enhancement.

Once the required Pack is downloaded:

```text
Network
   X
   │
   ▼
Local Topics
Local Packs
Local Cards
Local Images
   │
   ▼
Offline Gameplay
```

No remote database read, image request, API request, or real-time connection should be required during normal gameplay.

Downloaded content should be stored in private application storage and protected against casual extraction. Absolute DRM is neither expected nor promised.

---

### 8. MVP Performance and Cost Rules

The architecture must remain free-tier-first.

Prefer:

* local caching;
* local search/filtering;
* Pack-based downloads;
* compressed images;
* bulk operations;
* incremental synchronization;
* lightweight manifests/change detection;
* manual refresh.

Avoid:

* per-Card API requests;
* per-keystroke writes;
* realtime listeners;
* polling;
* repeated full downloads;
* repeated image downloads;
* unnecessary background synchronization.

Target constraints from the blueprint:

* Card images should normally remain below 50 KB.
* Packs should generally remain below 10 MB.

These are engineering targets intended to control bandwidth and storage, not absolute product rules.

---

### 9. Studio Profile and Statistics

Studio profiles are part of the MVP.

A profile may contain:

```text
Name
Avatar
Role
Contribution Statistics
```

Statistics track actual activity such as:

* Cards Added.
* Cards Removed.
* Packs Created.
* Packs Removed.
* Topics Created.
* Topics Removed.

Removing content does not erase historical contribution activity.

Ranking is not part of the MVP.

---

### 10. Explicitly Out of MVP

The following must not delay the first production release:

* Community submissions.
* Public creator accounts.
* Moderator workflow.
* Contributor ranking.
* XP.
* Levels.
* Badges.
* Achievements.
* Leaderboards.
* Realtime collaboration.
* Chat.
* Comments.
* Advanced analytics.
* AI-generated Cards.
* AI difficulty assignment.
* AI image discovery.
* Sophisticated conflict resolution.
* Realtime listeners.
* Complicated notifications.
* Enterprise-style permission management.
* Timer.
* Scoring system.
* Digital winner verification.
* Multiplayer synchronization.

These may become future features only when real product usage demonstrates a need for them.

---

### 11. MVP Development Order

Development should happen in parallel rather than finishing one application completely before starting the other.

Recommended order:

```text
1. Shared Models + Architecture
            ↓
2. Content Backend Foundation
            ↓
3. Studio Authentication + Roles
            ↓
4. Studio Topic / Pack / Card Creation
            ↓
5. Bulk Image/Card Workflow
            ↓
6. Publishing Pipeline
            ↓
7. Mobile Catalog
            ↓
8. Mobile Pack Download
            ↓
9. Local Content Storage
            ↓
10. Game Engine
            ↓
11. Identity Screen + Randomization
            ↓
12. Offline Gameplay
            ↓
13. Incremental Updates
            ↓
14. End-to-End Testing With Real Content
```

Studio should be started early enough for real data collectors to populate realistic Packs while Mobile is being developed. This is important because the mobile app must be tested against hundreds or thousands of real Cards rather than a tiny hardcoded dataset.

---

### 12. MVP Definition of Done

BiGuess MVP is considered complete when all of the following are true:

* A Studio user can authenticate and access the authorized Studio.
* A Topic can be created.
* A Pack can be created inside a Topic.
* Cards can be added with images, names, and difficulty.
* Multiple Cards/images can be imported efficiently.
* Content can be reviewed and published.
* Mobile can discover published Topics and Packs.
* Mobile can download a Pack.
* Downloaded content persists locally.
* A downloaded Pack can be played completely offline.
* A game can be configured with difficulty and rounds.
* Cards are selected locally and randomly.
* Identities can be displayed clearly.
* Rounds can progress without requiring network access.
* A new round can be started quickly.
* Content updates can be detected and synchronized incrementally.
* Studio and Mobile do not require realtime synchronization.
* The system operates within the free-tier-first architectural constraints.
* The complete flow has been tested with realistic content.

The final success criterion is not technical completeness.

It is:

> **A real group can install BiGuess, obtain content, sit together, start playing quickly, play without internet, finish the game, and want to play another round.**

That is the MVP.

---

## Future Vision

BiGuess should grow from a simple offline party game into a long-term social gaming platform built around **content, people, and face-to-face play**.

The core philosophy should remain unchanged:

> **Technology prepares the game. People play the game.**

BiGuess should never become a conventional online multiplayer game where the application replaces the social interaction. The phones should remain facilitators, gameplay should remain primarily offline, and the real-world group should remain at the center of the experience.

### 1. A Growing Content Ecosystem

The long-term value of BiGuess should come from a continuously expanding content library.

The architecture already separates the game engine from its content, allowing new Topics, Packs, and Cards to be added without modifying the mobile application.

Over time, BiGuess can expand beyond its initial content into:

* Anime
* Movies
* Football
* Games
* Countries
* Food
* Animals
* History
* Science
* and other categories created by BiGuess or its community.

The goal is not simply to have more content.

> **The goal is to make BiGuess relevant to more groups of people.**

### 2. Community-Created Content

Once the core product and moderation infrastructure are mature, BiGuess can open its content ecosystem to the community.

The long-term model may become:

```text
Creator
   ↓
Create Pack
   ↓
Submit
   ↓
Moderation
   ↓
Accept / Reject
   ↓
Publish
   ↓
Available to Players
```

Community content should never become public automatically.

Moderation, copyright, trademarks, inappropriate content, spam, duplication, quality, and other legal or operational concerns must be handled before a community Pack becomes part of the official library.

Only accepted contributions should contribute to future creator statistics or rankings.

### 3. A Creator Ecosystem

If community content becomes successful, BiGuess Studio can evolve from an internal content-management tool into a broader creator platform.

Creators could eventually:

* Build and maintain Packs.
* Submit content for review.
* Track their contributions.
* See validated contribution statistics.
* Potentially participate in a creator marketplace.

Any ranking or reputation system should be introduced only when there is a real community contribution system to justify it, rather than adding generic XP, badges, or leaderboards simply for gamification.

### 4. BiGuess Pro and Sustainable Monetization

Monetization should come after BiGuess demonstrates genuine repeated usage.

The intended direction is for Free to remain a real, enjoyable version of the game while Pro primarily removes meaningful content limitations rather than adding artificial gameplay restrictions.

The long-term business should protect the social experience:

* No intrusive interruptions during gameplay.
* No unnecessary online requirements.
* No dependence on aggressive advertising.
* No artificial features added purely to justify payment.

The objective is to monetize the **BiGuess experience and content ecosystem**, not to make the core game frustrating for free users.

### 5. Official, Licensed, and Partner Content

As BiGuess grows, the content ecosystem may eventually include:

* BiGuess-owned official Packs.
* Properly licensed franchises.
* Franchise partnerships.
* Brand-sponsored Packs or experiences.
* Custom Packs for events and organizations.
* Other commercial partnerships.

These are future possibilities, not MVP commitments. They should only be pursued once BiGuess has sufficient users and the legal, moderation, and content infrastructure required to support them.

BiGuess should not build its early business model around selling unlicensed third-party franchises.

### 6. Infrastructure Should Scale Quietly

BiGuess should preserve its fundamental technical advantage as it grows:

> **Download content once, then play offline.**

More users should not automatically mean proportionally more gameplay infrastructure.

The architecture should continue to favor:

```text
Local computation
      +
Local storage
      +
Cached content
      +
Incremental updates
      +
Efficient distribution
```

Infrastructure should become more efficient before it becomes more expensive. Paid infrastructure should be introduced only when real usage and optimized architecture justify it.

### 7. What BiGuess Should Never Become

Growth should not compromise the product's identity.

BiGuess should not become:

* A conventional online multiplayer game.
* A social network.
* A chat platform.
* A phone-first experience.
* A game that requires constant internet access.
* A product overloaded with unnecessary gamification.
* A platform where monetization interrupts the actual game.

The strongest version of BiGuess is still the simplest one:

> **A group sits together, chooses something they enjoy, turns their phones outward, and starts guessing.**

Everything added in the future should strengthen that experience rather than compete with it.

### 8. Long-Term Vision

The long-term BiGuess ecosystem can therefore be understood as:

```text
                         BI GUESS
                            │
              ┌─────────────┴─────────────┐
              │                           │
        Social Game                Content Ecosystem
              │                           │
        Offline Play              ┌───────┴───────┐
        Face-to-Face               │               │
        Simple Setup           Official        Community
        Local Gameplay         Content         Content
                                    │               │
                              Licensed/Owned     Creators
                              Partnerships       Moderation
                                                    │
                                                    ▼
                                             Future Marketplace
```

The game itself should remain simple.

The ecosystem around it can become large.

> **BiGuess should become a platform where anyone can quickly find something their group enjoys guessing, download it once, put their phones down, and play together.**

That is the long-term direction: **a growing content ecosystem built around an intentionally simple, offline-first social game.**

---

## Migration Plan From Current BiGuess

The migration from the current BiGuess implementation to the target architecture should be performed incrementally.

The objective is **not to rewrite BiGuess from scratch**. The objective is to preserve the working game experience while progressively replacing the current implementation with the architecture defined in this blueprint.

The migration should ultimately produce three clearly separated systems:

```text
                    BiGuess
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
     Mobile App     Backend      Studio
          │            │            │
          │            │            │
     Game Engine   Content API   Content Pipeline
          │            │            │
          ▼            ▼            ▼
   Local Packs       D1 / R2     Local Studio Data
          │
          ▼
    Offline Gameplay
```

The central migration principle is:

> **Move complexity out of gameplay and into content distribution.**

BiGuess gameplay should become a local operation over downloaded content. The network should primarily exist to discover, download, update, and manage content. This is consistent with the target architecture, where the application downloads Packs and then plays them offline.

---

## 1. Migration Objectives

The migration is considered successful when the current BiGuess application has been transformed into the following model:

```text
Flutter Mobile
    │
    ├── Local Content
    │      ├── Topics
    │      ├── Packs
    │      ├── Cards
    │      └── Protected Images
    │
    └── Local Game Engine
             │
             └── Offline Gameplay


BiGuess Studio
    │
    └── Content Management
             │
             ▼
       Workers API
          │    │
          ▼    ▼
         D1    R2
```

The migration must establish the following properties:

1. Gameplay is completely local.
2. Content is separated from application code.
3. Topic → Pack → Card is the canonical content hierarchy.
4. Packs are the primary download unit.
5. Downloaded Packs remain playable offline.
6. The Game Engine does not depend on the backend.
7. The Game Engine does not depend on the meaning of individual Cards.
8. Individual Cards and images are not fetched during gameplay.
9. Content can be created and maintained without modifying the Mobile application.
10. BiGuess Studio becomes the primary content-management system.
11. Content updates are incremental.
12. Backend providers remain replaceable behind repository/data-access layers.
13. Infrastructure remains simple and free-tier-oriented.
14. Existing production content can be migrated without rebuilding it manually.

These objectives follow the MVP technical principles defined by the blueprint, including local-first gameplay, persistent downloaded content, Pack-based distribution, separated content, provider-independent repositories, and aggressive reduction of remote requests.

---

## 2. Migration Philosophy

The migration should use a **strangler-style architecture** rather than a big-bang rewrite.

The existing implementation remains functional while new components are introduced around it.

Conceptually:

```text
Current BiGuess
      │
      ▼
Introduce new model
      │
      ▼
Introduce adapters
      │
      ▼
Extract Game Engine
      │
      ▼
Introduce local content
      │
      ▼
Introduce Packs
      │
      ▼
Introduce backend
      │
      ▼
Introduce Studio
      │
      ▼
Migrate production content
      │
      ▼
Remove legacy systems
```

Each phase should produce a working intermediate state.

At no point should the project depend on completing Mobile, Backend, and Studio simultaneously before anything can be tested.

The migration should also avoid carrying old architectural assumptions into the new system simply because they already exist.

---

## 3. Phase 0 — Freeze and Document the Current Implementation

Before modifying the existing application, the current behavior should be documented.

The purpose of this phase is to establish a **behavioral baseline**.

Document:

* Current application screens.
* Current navigation flow.
* Current game-start flow.
* Current player configuration.
* Current identity-selection behavior.
* Current round behavior.
* Current randomization behavior.
* Current difficulty behavior, if present.
* Current Card representation.
* Current image-loading behavior.
* Current content storage.
* Current network dependencies.
* Existing content datasets.
* Existing image assets.
* Existing configuration files.
* Existing assumptions embedded in the code.
* Existing features that are intentionally retained.
* Existing features that are intentionally removed from the MVP.

The baseline should answer one important question:

> **What does BiGuess currently do that must continue working after the migration?**

This phase should not be used to redesign the product.

The current game behavior should be treated as the reference behavior unless it conflicts with an explicit requirement in the new blueprint.

---

## 4. Phase 1 — Establish the Canonical Content Model

The first architectural change should be the introduction of the canonical content model:

```text
Topic
 └── Pack
      └── Card
```

The MVP models are deliberately small.

```text
Topic
├── id
└── name

Pack
├── id
├── topicId
└── name

Card
├── id
├── packId
├── name
├── imageReference
└── difficulty
```

Difficulty is:

```text
1 = Easy
2 = Medium
3 = Hard
```

and selection is cumulative:

```text
Easy
└── difficulty 1

Medium
├── difficulty 1
└── difficulty 2

Hard
├── difficulty 1
├── difficulty 2
└── difficulty 3
```

The Card model must remain generic and topic-agnostic. The Game Engine must not contain assumptions such as:

```text
if card is football player...
if card is anime character...
if card is country...
```

Instead, the engine should only understand the generic Card contract:

```text
Card
├── Name
├── Image
└── Difficulty
```

This separation allows new Topics to be introduced without modifying gameplay code.

### Migration approach

If the current implementation already has a Card-like model, it should be mapped into the new model.

If it has a different structure, create a temporary adapter:

```text
Legacy Card
     │
     ▼
Migration Adapter
     │
     ▼
Canonical Card
```

The adapter should be temporary and should have a defined removal point.

The canonical model should become the only model consumed by the new Game Engine.

---

## 5. Phase 2 — Separate Content From Gameplay

The next step is to remove content assumptions from the Game Engine.

The desired dependency direction is:

```text
UI
 │
 ▼
Game Engine
 │
 ▼
Local Content Repository
 │
 ▼
Topic / Pack / Card
```

The Game Engine should not know whether a Card represents:

* an anime character;
* a football player;
* a historical person;
* a country;
* a fictional character;
* or any future category.

Its responsibility is simply to operate on Cards.

The Game Engine should be responsible for:

* Receiving Game Configuration.
* Loading selected local Packs.
* Building the Card pool.
* Applying Difficulty.
* Randomizing Cards.
* Assigning Cards locally.
* Removing selected Cards from the temporary pool.
* Rebuilding the pool when exhausted.
* Tracking the current Round.
* Finishing the configured number of Rounds.

The engine should not manage backend requests, content publishing, image downloads, questions, answers, scoring, winners, or player synchronization.

The result should be a reusable local Game Engine that can be tested independently from Flutter UI and backend infrastructure.

---

## 6. Phase 3 — Introduce the Local Content Repository

Once the Game Engine is separated, introduce a local repository for content.

The initial target is:

```text
Game Engine
      │
      ▼
Local Content Repository
      │
      ├── Local Topics
      ├── Local Packs
      ├── Local Cards
      └── Local Images
```

The Game Engine should no longer load production Cards directly from hardcoded constants, static UI data, or remote APIs.

Instead:

```text
Game Engine
      │
      ▼
Repository
      │
      ▼
Local Data
```

This creates the architectural boundary required for the final offline-first system.

The exact local database/storage technology can be selected during implementation. The important requirement is that downloaded content lives in private application storage and remains available without the network.

---

## 7. Phase 4 — Migrate Existing Content Into Packs

Existing BiGuess content should then be reorganized into the canonical hierarchy.

The migration should transform the existing dataset into:

```text
Topic
 ├── Pack
 │    ├── Card
 │    ├── Card
 │    └── Card
 │
 └── Pack
      ├── Card
      ├── Card
      └── Card
```

Each Card must receive:

* a stable identifier;
* its Pack identifier;
* its name;
* its image reference;
* its difficulty.

Each Pack must receive:

* a stable identifier;
* its Topic identifier;
* its name;
* its content state;
* the metadata required for distribution and synchronization.

A Pack should become the fundamental unit for:

* downloading;
* local storage;
* updating;
* deleting;
* publishing;
* synchronization.

The blueprint explicitly defines a Pack as the downloadable/playable unit and a Card as the playable identity.

### Existing content must not be manually recreated

Where possible, migration tooling should import the existing content automatically.

A migration script or importer should:

```text
Existing Dataset
      │
      ▼
Validate
      │
      ▼
Map Fields
      │
      ▼
Generate IDs
      │
      ▼
Create Topics
      │
      ▼
Create Packs
      │
      ▼
Create Cards
      │
      ▼
Validate Images
      │
      ▼
Generate Import Dataset
```

The original dataset should remain available until the migrated content has been validated.

---

## 8. Phase 5 — Move Images Out of Application Bundles

Card images should be separated from application code.

The target model is:

```text
D1
│
├── Topics
├── Packs
└── Cards
       │
       └── imageReference
             
R2
│
└── Card Images
```

Images should not be stored as large binary database records.

They should be optimized before publication to reduce:

* storage;
* bandwidth;
* Pack size;
* download time;
* local device storage.

The blueprint uses a normal target of approximately **<50 KB per Card image** and **<10 MB per Pack**, while explicitly treating these as engineering targets rather than absolute product rules. Image quality must remain sufficient for real gameplay.

During migration, existing images should therefore be processed through an image pipeline:

```text
Existing Image
      │
      ▼
Validate
      │
      ▼
Resize
      │
      ▼
Compress
      │
      ▼
Store
      │
      ▼
Generate Image Reference
```

Downloaded images should be kept in private application storage and protected against casual extraction. This is intended as practical content protection rather than perfect DRM.

---

## 9. Phase 6 — Make Offline Gameplay the Primary Path

After local content is available, the Game Engine must operate entirely from it.

The target runtime becomes:

```text
Downloaded Pack
      │
      ▼
Local Storage
      │
      ▼
Local Repository
      │
      ▼
Game Engine
      │
      ▼
Gameplay
```

There must be no:

```text
Card API request
Image API request
Database request
Realtime connection
```

during normal gameplay.

The offline requirement is a hard MVP requirement:

```text
Network
   X
   │
   ▼
Local Topics
Local Packs
Local Cards
Local Images
   │
   ▼
Offline Gameplay
```

Once the required Pack is downloaded, the game must remain fully playable without internet access.

### Migration gate

Before proceeding to the backend migration, the team should be able to:

1. Install the migrated Mobile application.
2. Populate it with a local Pack.
3. Disable network access.
4. Start a game.
5. Select Cards.
6. Display images.
7. Complete configured rounds.
8. Restart the application.
9. Start another offline game.

If this does not work reliably, the migration should not proceed to treating the backend as the source of downloaded content.

---

## 10. Phase 7 — Introduce the Remote Content Catalog

Once local Packs work, introduce the lightweight remote catalog.

The catalog exists to answer:

> **What content is available?**

It should provide enough information for Mobile to display:

* Topics;
* Packs;
* Pack names;
* Pack relationships;
* Card counts;
* download status;
* update information;
* required metadata.

It should **not** require downloading complete Card datasets simply to browse the catalog. Full Pack content should only be downloaded when the user chooses to use that Pack.

The flow becomes:

```text
Mobile
  │
  ▼
Lightweight Catalog
  │
  ├── Topics
  └── Packs
       │
       ▼
User selects Pack
       │
       ▼
Download Pack
       │
       ▼
Local Storage
       │
       ▼
Offline Gameplay
```

This is important for both performance and infrastructure cost.

---

## 11. Phase 8 — Introduce the Content Backend

After the local model and catalog contract are stable, introduce the backend.

The current preferred MVP architecture is:

```text
Flutter Mobile
       │
       ▼
Cloudflare Workers
       │
       ├── D1
       │    └── Structured metadata
       │
       └── R2
            └── Images / content files
```

Studio authentication is separated from content storage:

```text
Google
   │
   ▼
Firebase Authentication
   │
   ▼
BiGuess Studio
   │
   ▼
Workers API
```

The backend manages content distribution and management.

It does **not** manage:

* game rooms;
* active game sessions;
* player connections;
* realtime state;
* scores;
* questions;
* winners.

This distinction is essential.

BiGuess is not being migrated into an online multiplayer architecture.

---

## 12. Phase 9 — Introduce Repository/Data-Access Boundaries

The Mobile application must not directly depend on Cloudflare-specific APIs.

Use interfaces such as:

```text
ContentRepository
        │
        ├── LocalContentRepository
        │
        └── RemoteContentRepository
```

The Game Engine depends on:

```text
ContentRepository
```

rather than:

```text
CloudflareD1Repository
```

Similarly, backend-specific implementations should remain behind clear interfaces.

The architecture should therefore allow:

```text
Current Provider
      │
      ▼
Repository Interface
      │
      ▼
Application
```

rather than:

```text
Application
      │
      ▼
Cloudflare-specific code everywhere
```

The blueprint explicitly requires provider-specific infrastructure to remain isolated behind repositories/data-access layers so that the backend remains replaceable.

---

## 13. Phase 10 — Implement Pack Downloads

The Mobile application should now support the complete Pack download lifecycle.

```text
Browse Topic
      ↓
Browse Packs
      ↓
Select Pack
      ↓
Check Local State
      ↓
Download Missing Content
      ↓
Verify Download
      ↓
Store Locally
      ↓
Mark Pack Available
      ↓
Play Offline
```

The Pack download must include everything required for gameplay:

```text
Pack
├── Pack metadata
├── Cards
│    ├── names
│    ├── difficulties
│    └── image references
└── image assets
```

The actual implementation may package these resources differently, but the user-facing result must be the same:

> Download a Pack once, then play it without internet.

The application binary itself should remain relatively small because new content is distributed independently from the application.

---

## 14. Phase 11 — Implement Incremental Content Synchronization

The migration must not create a system where every update requires downloading an entire Pack again.

For example:

```text
Local Pack
100 Cards

Remote Pack
105 Cards
```

The synchronization layer should determine what is missing or changed.

```text
Local Pack
    │
    ▼
Change Detection
    │
    ▼
Remote Pack
    │
    ├── unchanged
    ├── new Card
    ├── changed Card
    └── changed Image
             │
             ▼
      Download Required Data
             │
             ▼
        Update Local Pack
```

The implementation may use:

* hashes;
* timestamps;
* manifests;
* checksums;
* fingerprints;
* content identifiers.

The mechanism is an internal technical detail and should not become a user-facing version-management system.

The important requirement is:

> **Only missing or changed content should normally be transferred.**

---

## 15. Phase 12 — Implement Lightweight Refresh

Mobile should not continuously synchronize.

There should be no requirement for:

* realtime listeners;
* continuous polling;
* persistent connections;
* live Pack synchronization.

Instead:

```text
Refresh
   │
   ▼
Small Change Check
   │
   ├── No changes
   │      ↓
   │     Done
   │
   └── Changes
          ↓
    Download Changes
          ↓
    Update Local Data
```

Refreshing unchanged content should be extremely cheap.

This is particularly important because the blueprint treats database efficiency and request minimization as architectural requirements rather than later optimizations.

---

## 16. Phase 13 — Build BiGuess Studio in Parallel

BiGuess Studio should not wait until the Mobile application is completely finished. Rather than being a sequential step that waits for the mobile download pipeline, Studio operates as a parallel workstream that starts as soon as the canonical content models (Phase 1) and local content boundaries (Phase 3) are defined.

Mobile and Studio should be developed in parallel:

```text
                  BiGuess
                     │
          ┌──────────┴──────────┐
          │                     │
     BiGuess Mobile        BiGuess Studio
          │                     │
     Game Engine          Content Pipeline
          │                     │
          └──────────┬──────────┘
                     │
              Shared Models
              & Architecture
```

The blueprint explicitly recommends parallel development so that real content can begin entering the system early.

Studio should provide the MVP content-management workflow:

```text
Create Topic
     ↓
Create Pack
     ↓
Add Cards
     ↓
Upload Images
     ↓
Assign Difficulty
     ↓
Review
     ↓
Publish
```

Studio should be designed around trusted administrators and data collectors rather than public community creators during the MVP.

---

## 17. Phase 14 — Make Studio Local-First

Studio should follow the same general efficiency philosophy as Mobile.

Instead of:

```text
User action
    ↓
Database request
    ↓
UI update
```

prefer:

```text
Studio
   ↓
Local Dataset
   ↓
User works locally
   ↓
Batch changes
   ↓
Synchronize
   ↓
Remote Backend
```

Examples that should preferably be batched include:

* adding many Cards;
* uploading multiple images;
* updating multiple Cards;
* publishing a Pack.

The goal is to make content creation efficient while minimizing unnecessary backend operations.

---

## 18. Phase 15 — Import Existing Production Content Into Studio

Once Studio is operational, the existing BiGuess content should be imported into it.

The process should be:

```text
Existing Content
      │
      ▼
Migration Importer
      │
      ▼
Topic / Pack / Card
      │
      ▼
Image Processing
      │
      ▼
Studio Dataset
      │
      ▼
Validation
      │
      ▼
Publish
```

Studio should then become the authoritative source for future content management.

The Mobile application should no longer require developers to edit application code whenever a Card is added, removed, renamed, or reorganized.

This is one of the principal purposes of Studio: content should evolve independently from the Mobile application.

---

## 19. Phase 16 — Introduce Publishing at the Correct Levels

Publishing should remain simple.

The hierarchy is:

```text
Topic
   ↓
Pack
   ↓
Cards
```

Publishing applies to:

* Topics;
* Packs.

Publishing does not apply independently to individual Cards.

Cards are managed as part of their Pack.

A published Pack becomes eligible for distribution to Mobile, while a published Topic controls whether the Topic and its Packs are visible/available to users.

The migration should therefore avoid inventing unnecessary per-Card publishing workflows.

---

## 20. Phase 17 — Implement Pack Revisions

When an authorized Studio collector modifies a published Pack:

```text
Published Pack
      ↓
Collector edits
      ↓
Add / Modify / Remove Cards
      ↓
Save
      ↓
New internal revision
      ↓
Published Pack updated
      ↓
Devices detect change
      ↓
Required changes downloaded
```

There is no requirement for Owner Admin approval for every modification made by a trusted Studio collector.

The purpose is to prevent the project owner from becoming a bottleneck for routine content production.

---

## 21. Phase 18 — Implement Pack Deletion and Tombstones

Pack deletion must be synchronized without requiring realtime infrastructure.

When a Pack is deleted from the cloud:

```text
Cloud Pack deleted
       ↓
Device offline
       ↓
Local Pack may temporarily remain
       ↓
Device reconnects
       ↓
Deletion detected
       ↓
Local Pack removed
       ↓
Pack unavailable for gameplay
```

A deleted Pack should no longer be available for new downloads.

Connected devices should remove their local copy after synchronization detects the deletion.

Deletion markers/tombstones should remain available long enough for clients to discover the deletion.

They can later be cleaned according to a retention policy.

---

## 22. Phase 19 — Replace the Legacy Content System

Only after the new pipeline has been validated should the old content system be removed.

The target dependency graph should be:

```text
Mobile
  │
  ▼
Local Content
  │
  ▼
Game Engine
```

and:

```text
Studio
  │
  ▼
Content Backend
  │
  ├── D1
  └── R2
```

The following legacy components should be removed when their replacements are proven:

* hardcoded production Cards;
* legacy content loaders;
* duplicate content models;
* direct gameplay API requests;
* remote image loading during gameplay;
* legacy randomization code;
* obsolete content-management flows;
* duplicate storage mechanisms;
* obsolete synchronization logic.

The removal should be deliberate.

A legacy component should only be deleted after:

1. its replacement exists;
2. production-equivalent content has been tested;
3. the replacement has passed offline tests;
4. no remaining feature depends on the legacy implementation.

---

## 23. Phase 20 — Validate the Complete End-to-End Pipeline

The final architecture must be tested as one complete system.

The expected pipeline is:

```text
Studio
  │
  ▼
Create / Edit Content
  │
  ▼
Review
  │
  ▼
Publish
  │
  ▼
Backend
  │
  ├── D1
  └── R2
       │
       ▼
Mobile Catalog
       │
       ▼
User selects Pack
       │
       ▼
Pack Download
       │
       ▼
Private Local Storage
       │
       ▼
Game Engine
       │
       ▼
Offline Gameplay
```

The test should begin with content creation and end with a real offline game.

This should be tested using realistic content rather than only a handful of development Cards.

The blueprint specifically calls for Studio to be introduced early enough to populate realistic Packs containing hundreds or thousands of Cards for Mobile testing.

---

## 24. Offline Test Gate

The final migration must pass an explicit offline test.

### Test procedure

1. Install the current migrated Mobile application.
2. Connect to the internet.
3. Browse Topics.
4. Select a Pack.
5. Download the Pack.
6. Verify the local Pack.
7. Disable all network access.
8. Restart BiGuess.
9. Select the downloaded Pack.
10. Configure Difficulty and Rounds.
11. Start a game.
12. Reveal identities.
13. Complete multiple rounds.
14. Start another game.
15. Restart the application.
16. Repeat the game while still offline.

Expected result:

```text
Network = unavailable

Gameplay = fully functional
```

The following must not be required:

```text
D1 request
Workers request
R2 image request
Realtime connection
Authentication request
```

Already-downloaded content must remain usable when the backend is unavailable. Backend failure should primarily affect browsing new content, downloading new Packs, checking updates, and Studio synchronization—not already-downloaded gameplay.

---

## 25. Content Synchronization Test Matrix

The migration should test at least these cases:

| Scenario                      | Expected behavior                             |
| ----------------------------- | --------------------------------------------- |
| New Pack                      | Pack appears in catalog and can be downloaded |
| Existing Pack unchanged       | No unnecessary full download                  |
| New Card                      | Only required new content is downloaded       |
| Modified Card                 | Local Card is updated                         |
| Changed image                 | Changed image asset is updated                |
| Pack deleted remotely         | Local copy removed after synchronization      |
| Device offline                | Existing downloaded Pack remains playable     |
| Interrupted download          | Download can safely recover/retry             |
| Repeated refresh              | Minimal remote work                           |
| Backend unavailable           | Existing local gameplay continues             |
| Application restarted offline | Downloaded Packs remain available             |
| Multiple Packs downloaded     | Each remains independently playable           |
| Local Pack removed            | User can download it again if still published |

---

## 26. Migration Data Validation

Before production migration, validate the complete content dataset.

Validation should check:

* Missing Topic identifiers.
* Missing Pack identifiers.
* Missing Card identifiers.
* Duplicate identifiers.
* Packs without Topics.
* Cards without Packs.
* Packs without enough Cards to be useful.
* Missing Card names.
* Missing image references.
* Invalid difficulty values.
* Duplicate Cards where applicable.
* Invalid image files.
* Excessive image sizes.
* Broken image references.
* Invalid publication states.

Difficulty must always resolve to:

```text
1
2
3
```

and Pack/Card relationships must remain valid.

The migration should also compare the old and new datasets:

```text
Old Content
      │
      ├── Topic count
      ├── Pack count
      ├── Card count
      └── Image count
             │
             ▼
New Content
      │
      ├── Topic count
      ├── Pack count
      ├── Card count
      └── Image count
```

Any unexpected difference should be investigated before the old dataset is retired.

---

## 27. Infrastructure Migration and Cost Control

The migration must preserve the project's free-tier-first philosophy.

The intended MVP architecture is:

| Component      | Technology              | Purpose                        |
| -------------- | ----------------------- | ------------------------------ |
| Mobile         | Flutter                 | Gameplay                       |
| Studio         | Flutter                 | Content management             |
| Authentication | Firebase Authentication | Studio Google login            |
| API            | Cloudflare Workers      | Backend API                    |
| Database       | Cloudflare D1           | Topics, Packs, Cards, metadata |
| Object storage | Cloudflare R2           | Images and content files       |
| Local storage  | Private device storage  | Offline Packs                  |
| Game state     | Local / in-memory       | Active game                    |

The migration should not introduce unnecessary infrastructure such as:

* Redis;
* Kubernetes;
* dedicated servers;
* microservices;
* multiple databases;
* realtime infrastructure;
* event buses;
* unnecessary queues.

The preferred architecture remains deliberately simple:

```text
Flutter
   │
   ▼
Workers
   │
   ├── D1
   └── R2
```

with Firebase Authentication for Studio login.

---

## 28. Monitoring During Migration

Infrastructure usage should be monitored from the beginning.

Important metrics include:

### D1

* Rows read per day.
* Rows written per day.
* Storage usage.
* Expensive queries.
* Full-table scans.

### Workers

* Requests per day.
* CPU usage.
* Failed requests.
* Endpoint usage.

### R2

* Storage size.
* Operations.
* Pack download volume.
* Image update volume.

### Mobile

* Number of downloaded Packs.
* Pack download failures.
* Update failures.
* Average Pack size.
* Cards per Pack.

These metrics should primarily be used to identify inefficient architecture before infrastructure limits become a problem.

The migration should therefore measure whether the new architecture actually achieves:

```text
Few remote requests
+
Large local reuse
+
Small incremental updates
=
Low infrastructure cost
```

---

## 29. Provider Independence

Cloudflare Workers + D1 + R2 is the preferred current architecture, but it must not become a permanent architectural assumption.

The application layer should avoid provider-specific dependencies wherever practical.

Provider evaluation should remain based on:

* free-tier limits;
* storage;
* bandwidth;
* request limits;
* reliability;
* Flutter compatibility;
* migration difficulty;
* simplicity;
* long-term viability.

The goal is not to use Cloudflare for its own sake.

The goal is:

> **Use the most cost-efficient infrastructure that satisfies BiGuess's requirements.**

This is another reason repository and data-access boundaries must be established during migration rather than after the system becomes heavily coupled to a provider.

---

## 30. Features Explicitly Excluded From the Migration

The migration should not become an excuse to implement future features prematurely.

The following should **not** delay the MVP migration:

* Community submissions.
* Public creator accounts.
* Public moderation workflows.
* Contributor ranking.
* XP.
* Levels.
* Badges.
* Achievements.
* Leaderboards.
* Realtime collaboration.
* Chat.
* Comments.
* Advanced analytics.
* AI-generated Cards.
* AI difficulty assignment.
* AI image discovery.
* Sophisticated conflict resolution.
* Realtime listeners.
* Complicated notifications.
* Enterprise-style permission management.
* Timers.
* Scoring systems.
* Digital winner verification.
* Multiplayer synchronization.

These are explicitly outside the MVP scope.

The migration should not carry these concerns into the architecture simply because they may exist in the long-term vision.

The architecture should leave room for future expansion without implementing that complexity now.

---

## 31. Community Content Must Remain a Future Extension

The migration should not implement public community publishing.

However, the new content model should not make future community content impossible.

The eventual model may be:

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
   ▼
Publish
   │
   ▼
Content Catalog
   │
   ▼
Players
```

Community-created content requires moderation and appropriate handling of copyright, trademarks, inappropriate content, spam, duplication, privacy, and other legal/platform concerns.

For the migration, it is sufficient to ensure that the Topic → Pack → Card architecture can later accommodate those workflows.

---

## 32. Legal and Content Metadata During Migration

Existing content may be retained during development, but the migration should avoid losing information about content origin.

Where practical, content records should eventually support:

* source;
* creator;
* ownership;
* licensing information;
* attribution;
* relevant rights metadata.

This is especially important for third-party images, characters, brands, photographs, and other protected material.

The migration itself does not establish ownership of third-party content.

The blueprint explicitly distinguishes BiGuess-owned source code, UI, original graphics, systems, documentation, and branding from third-party names, characters, logos, photographs, artwork, and trademarks.

This metadata can be expanded later without changing the core gameplay model.

---

## 33. Migration Rollback Strategy

Every major migration phase should have a rollback point.

Recommended checkpoints:

```text
Checkpoint 1
Current application
        ↓
Checkpoint 2
New content model
        ↓
Checkpoint 3
Extracted Game Engine
        ↓
Checkpoint 4
Local Packs
        ↓
Checkpoint 5
Remote catalog
        ↓
Checkpoint 6
Backend distribution
        ↓
Checkpoint 7
Studio
        ↓
Checkpoint 8
Production migration
        ↓
Checkpoint 9
Legacy removal
```

Production content should not be permanently deleted from the old system until the new pipeline has been validated.

For data migration, retain:

* original export;
* migration input;
* migration output;
* validation results;
* import logs;
* image-processing results.

This makes content migration reproducible and recoverable.

---

## 34. Final Migration Sequence

The complete recommended sequence is:

```text
1. Freeze current behavior
          ↓
2. Document current data and dependencies
          ↓
3. Define canonical Topic / Pack / Card models
          ↓
┌───────────────────────────────────────────────┴───────────────────────────────────────────────┐
│ Track A: Mobile & Engine Pipeline             │ Track B: Studio & Content Pipeline (Parallel) │
├───────────────────────────────────────────────┼───────────────────────────────────────────────┤
│ 4. Create migration adapters                  │ 7. Build BiGuess Studio foundation            │
│ 5. Extract the local Game Engine              │ 8. Implement local-first Studio workflow      │
│ 6. Introduce Local Content Repository         │ 9. Import existing content into Studio        │
│ 10. Convert existing content into Packs       │ 14. Implement Pack revisions & validation     │
│ 11. Move images into new asset pipeline       │ 15. Implement Topic/Pack publishing           │
│ 12. Prove offline gameplay                    │                                               │
│ 13. Define lightweight remote catalog         │                                               │
├───────────────────────────────────────────────┴───────────────────────────────────────────────┤
│ Shared Cloud Infrastructure & Distribution Pipeline                                           │
├───────────────────────────────────────────────────────────────────────────────────────────────┤
│ 16. Implement Workers API                                                                     │
│ 17. Implement D1 metadata storage                                                             │
│ 18. Implement R2 image/content storage                                                        │
│ 19. Implement Pack downloads & incremental synchronization                                    │
│ 20. Implement deletion synchronization & tombstones                                           │
└───────────────────────────────────────────────┬───────────────────────────────────────────────┘
                                                ↓
                                21. Replace legacy production content
                                                ↓
                                22. Remove obsolete content architecture
                                                ↓
                                23. Run complete end-to-end tests
                                                ↓
                                24. Run offline validation
                                                ↓
                                25. Monitor infrastructure usage
                                                ↓
                                26. Production migration
```

---

## 35. Migration Completion Criteria

The migration should be considered complete only when all of the following are true.

### Mobile

* Flutter Mobile uses the canonical Topic → Pack → Card model.
* Production content is no longer hardcoded into gameplay code.
* The Game Engine is independent from content meaning.
* Game selection and randomization are local.
* Difficulty is applied locally.
* Downloaded Packs are stored privately.
* Card images are available locally during gameplay.
* No network connection is required during gameplay.
* No realtime multiplayer system exists.
* Active Game State remains local/in-memory.
* Downloaded content persists between application launches.

### Content

* Topics organize Packs.
* Packs are the download/playable unit.
* Cards belong to Packs.
* Difficulty uses the defined 1–3 model.
* Images are stored separately from database metadata.
* Images are optimized before publication.
* Content is separated from the application binary.

### Backend

* Workers provides the backend API.
* D1 stores structured content metadata.
* R2 stores images/content files.
* Remote requests are lightweight.
* Individual Card requests are not required during gameplay.
* Content updates are incremental.
* Deleted Packs can be synchronized without realtime infrastructure.
* Provider-specific implementation is isolated behind repositories/data-access layers.

### Studio

* Studio can authenticate authorized users.
* Topics can be created and managed.
* Packs can be created and managed.
* Cards can be created and managed.
* Images can be uploaded and processed.
* Difficulty can be assigned.
* Content can be reviewed.
* Topics and Packs can be published.
* Published Packs can be updated by authorized collectors.
* Studio works primarily from local synchronized data.
* Bulk operations are supported where appropriate.

### Operations

* Existing production content has been migrated.
* Content counts have been validated.
* Image references have been validated.
* Offline gameplay has passed testing.
* Incremental updates have passed testing.
* Pack deletion synchronization has passed testing.
* Backend outage does not prevent already-downloaded gameplay.
* Infrastructure usage is monitored.
* The architecture remains within the intended free-tier-first constraints.

---

## 36. Final Target Architecture

After migration, the complete BiGuess architecture should converge toward:

```text
                           BiGuess
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
        BiGuess Mobile                  BiGuess Studio
              │                               │
              │                          Authentication
              │                               │
              │                               ▼
              │                         Studio Local Data
              │                               │
              │                               ▼
              │                         Batch Synchronization
              │                               │
              │                               ▼
              │                          Workers API
              │                               │
              │                    ┌──────────┴──────────┐
              │                    │                     │
              │                    ▼                     ▼
              │                   D1                     R2
              │              Metadata              Images/Files
              │                    │                     │
              │                    └──────────┬──────────┘
              │                               │
              │                         Published Content
              │                               │
              ▼                               ▼
       Remote Catalog ◄──────────────── Content Distribution
              │
              ▼
        Pack Download
              │
              ▼
       Private Local Storage
              │
       ┌──────┴──────┐
       │             │
    Local Cards   Local Images
       │             │
       └──────┬──────┘
              │
              ▼
        Local Game Engine
              │
              ▼
       Offline Gameplay
```

The resulting system should make the infrastructure largely invisible to the player.

From the player's perspective, the product remains simple:

```text
Open BiGuess
     ↓
Choose Topic
     ↓
Choose Pack(s)
     ↓
Download once
     ↓
Configure Difficulty + Rounds
     ↓
Start Game
     ↓
Receive random identities
     ↓
Play together in the real world
     ↓
Continue through rounds
     ↓
Finish
```

The architecture underneath that experience should handle content management, publishing, synchronization, storage, image optimization, and updates without making any of those concerns part of the actual game.

That is the final migration objective:

> **BiGuess should evolve from a game implementation that contains its own content into an offline-first game platform where the application is the engine, Packs are the content units, Studio is the content pipeline, and the backend is primarily a distribution system.**

The most important invariant throughout the migration is therefore:

> **Download content once, then play offline.**

This remains the architectural center of BiGuess, while the rest of the system exists to make that experience reliable, maintainable, extensible, and inexpensive.
