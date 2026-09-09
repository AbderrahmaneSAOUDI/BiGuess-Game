# Game Model & Data Hierarchy

> Topic / Pack / Card model, selection pools, rounds, randomization & settings

---

## **User:**

move to Game Model

---

## **ChatGPT:**

Yes. Let's move to the **Game Model**.

This is where I want to be especially careful, because the Game Model becomes the foundation for both the Flutter app and the Content Studio. If we get this wrong, everything above and below it becomes messy.

# Game Model

## 1. What is a BiGuess Game?

A **game session** is a temporary real-world activity involving a group of players.

It contains:

- players;
- selected content;
- game settings;
- one or more rounds.

The session itself does **not** need to exist on a server.

It can live entirely on the players' phones and in their physical interaction.

Conceptually:

```text
Game Session
│
├── Players
│
├── Content Selection
│
├── Settings
│
└── Rounds
     │
     ├── Round 1
     ├── Round 2
     └── ...
```

---

# 2. Players

A player is simply a person participating in the physical game.

There is no need for:

- account;
- username;
- profile;
- login;
- online identity.

For the MVP, the application only needs to know enough to generate the correct experience on **that device**.

For example:

```text
Player A → Phone A → Identity A
Player B → Phone B → Identity B
Player C → Phone C → Identity C
```

The application doesn't need to know that Player A is “Ahmed” or that Player B has an account.

The people themselves know who they are.

---

# 3. Topic

A **Topic** is the broad subject of the content.

Examples:

```text
Anime
Football
Movies
Countries
Food
Animals
History
Science
```

A Topic should primarily organize content.

It should **not** contain game logic specific to that subject.

For example, the game engine shouldn't contain:

```text
if topic == football:
    ...
else if topic == anime:
    ...
```

The same game mechanics should work regardless of the Topic.

---

# 4. Pack

A **Pack** is a playable collection of cards belonging to a Topic.

For example:

```text
Anime
│
├── Naruto
├── One Piece
├── Demon Slayer
└── Dragon Ball
```

Or:

```text
Football
│
├── World Cup Legends
├── Famous Players
├── Algerian Players
└── European Clubs
```

A pack is the natural unit that players download.

This is important.

The user doesn't need to download:

> “all Football.”

They download:

> **Algerian Players**

or:

> **World Cup Legends**

A pack should contain enough cards to provide a good playing experience.

---

# 5. Card

A **Card** is the fundamental playable identity.

It represents the answer that one player must discover.

Examples:

```text
Card
├── Image
├── Name
├── Difficulty
└── Metadata
```

The identity could be:

- Naruto Uzumaki
- Lionel Messi
- Japan
- Pizza
- Albert Einstein
- Simba
- The Godfather

The game engine doesn't need to care what the identity represents.

It simply knows:

> **This is the identity the player needs to guess.**

---

# 6. Topic → Pack → Card

This gives us our basic content hierarchy:

```text
Topic
  │
  ├── Pack
  │     ├── Card
  │     ├── Card
  │     └── Card
  │
  ├── Pack
  │     ├── Card
  │     └── Card
  │
  └── Pack
        ├── Card
        └── Card
```

This structure is intentionally generic.

It allows BiGuess to grow without changing its fundamental game engine.

---

# 7. What Does the Player Actually Select?

The player shouldn't necessarily have to select a single pack.

We want three fundamental content-selection modes:

### Single

Play from one specific pack.

Example:

> **Anime → Naruto**

---

### Selected

Combine multiple packs.

Example:

> **Naruto + One Piece + Dragon Ball**

The game creates one selection pool from all three.

---

### Random

Let BiGuess choose from the available content.

This could eventually mean:

> Random pack

or:

> Random topic

or:

> Random everything available offline.

We need to design the exact UX later, but the underlying game model should support this concept.

---

# 8. The Selection Pool

This is an important concept.

Before a round starts, BiGuess creates a **candidate pool**.

For example:

```text
Selected:
Naruto      → 150 cards
One Piece   → 200 cards
Dragon Ball → 120 cards

Candidate Pool
→ 470 cards
```

Difficulty can then filter that pool.

For example:

```text
Candidate Pool
      ↓
Difficulty = Medium
      ↓
270 eligible cards
```

Then the game selects identities from that pool.

This keeps **content selection**, **difficulty**, and **randomization** separate.

That's good architecture.

---

# 9. Difficulty

Difficulty belongs to the **Card**, not the game engine.

For example:

```text
Naruto
Difficulty: Easy
```

```text
Shino Aburame
Difficulty: Hard
```

The game doesn't need to understand *why* something is difficult.

The content team determines that.

Then the game can simply do:

```text
Easy
→ select Easy cards

Medium
→ select Medium cards

Hard
→ select Hard cards
```

Later we can make the model more sophisticated if needed.

For example:

```text
difficulty = 1–5
```

instead of only:

```text
easy / medium / hard
```

But I would **not over-engineer this now**.

---

# 10. Round

A **Round** is one complete cycle of identity assignment and real-world guessing.

Conceptually:

```text
Start Round
     ↓
Build candidate pool
     ↓
Randomly assign identities
     ↓
Players expose phones
     ↓
Real-world questioning
     ↓
Someone wins
     ↓
Round ends
```

The application doesn't necessarily need to know exactly when the round ends.

The players know.

That's an important distinction.

---

# 11. Round Configuration

The round can have configuration such as:

```text
Content
Difficulty
Number of Rounds
```

Potentially:

```text
Randomization
```

depending on how we finalize the UX.

But the game should distinguish between:

### Game configuration

Things the app can actually control.

and:

### Real-world rules

Things the players control.

---

# 12. What the App Controls

BiGuess can control:

- content selection;
- randomization;
- identity assignment;
- difficulty filtering;
- number of rounds;
- local content availability;
- optional game configuration;
- preventing unnecessary identity repetition.

---

# 13. What the Players Control

The players control:

- who participates;
- whose turn it is;
- what questions are asked;
- whether an answer is truthful;
- whether someone is cheating;
- whether a guess is accepted;
- whether someone has correctly identified their identity;
- when a round is considered finished;
- arguments and house rules;
- whether they want to continue playing.

This separation should be considered **fundamental to the BiGuess design**.

The app shouldn't try to turn those physical/social rules into digital state unless there is a compelling reason.

---

# 14. Identity Assignment

Suppose there are four players:

```text
Player A
Player B
Player C
Player D
```

The application should independently generate:

```text
A → Card 37
B → Card 182
C → Card 91
D → Card 402
```

The identity should be unique within the round unless we explicitly decide otherwise for a future game mode.

The important part is:

> **Each player receives an identity that the other players can see, but the player themselves should not intentionally see.**

Again, the application provides the mechanism.

The players enforce the physical rule.

---

# 15. Randomization and Repetition

Randomization shouldn't simply mean:

```text
random number
```

every time.

We want something closer to a shuffled deck.

For example, if a selected pool contains 100 cards:

```text
Shuffle
 ↓
73
 ↓
12
 ↓
94
 ↓
31
...
```

Cards already used during the relevant session should normally be excluded until the pool is exhausted.

This prevents:

> Naruto → Naruto → Naruto

from happening repeatedly.

The exact scope of “already used” needs to be decided later:

- per round;
- per game session;
- per pack;
- or another model.

I currently recommend **per game session**, because it feels most like playing with a shuffled deck.

But we'll validate this when we design the detailed rules.

---

# 16. Multiple Players and Network Independence

This is one of the most important architectural consequences of our product philosophy.

Suppose four friends are playing.

We do **not** need:

```text
Phone A
   ↕
Firebase
   ↕
Phone B
   ↕
Phone C
   ↕
Phone D
```

Instead:

```text
Phone A → local content → local randomization → Identity A

Phone B → local content → local randomization → Identity B

Phone C → local content → local randomization → Identity C

Phone D → local content → local randomization → Identity D
```

The physical group coordinates the game.

That means the game remains playable even when:

- Wi-Fi doesn't exist;
- mobile data is unavailable;
- Firebase is down;
- the player has no account;
- the devices aren't connected to each other.

This is one of the strongest technical consequences of the game's real-world design.

---

# 17. Scoring

For the MVP, I would **not make scoring a core game mechanic**.

Your earlier reasoning is sound.

Imagine:

Player A correctly guesses.

Player A presses:

> **I Won**

But Player B also presses it.

Who actually won?

The application cannot reliably determine reality.

Even Firebase doesn't solve that.

It can synchronize:

> “Both devices clicked.”

It cannot determine:

> “Who was actually correct first?”

Therefore:

### MVP

The group determines the winner.

### Future

If the community strongly wants digital scoring, we can explore mechanisms that **assist** scoring without pretending the phone can perfectly determine reality.

---

# 18. Timer

The Game Model should currently have **no timer**.

Not:

> “Timer = optional.”

But:

> **Timer is outside the MVP game model.**

If players later request it, we add it deliberately.

This keeps the initial model focused.

---

# 19. The Fundamental Game Loop

I think we can now describe BiGuess's core loop very simply:

```text
Choose Content
      ↓
Configure Game
      ↓
Create Candidate Pool
      ↓
Assign Random Identities
      ↓
Show Identities
      ↓
Players Turn Phones Outward
      ↓
Real-World Yes/No Questions
      ↓
Players Guess
      ↓
Round Ends
      ↓
Next Round / Finish
```

And critically:

**The middle of that diagram is not an application workflow.**

It's a **real-world activity**.

That's what makes BiGuess different.

---

# 20. The Game Model in One Diagram

```text
                         BI GUESS
                            │
                       Game Session
                            │
             ┌──────────────┼──────────────┐
             │              │              │
          Players        Settings       Content
             │              │              │
       ┌─────┴─────┐    ┌───┼────┐         │
       │           │    │   │    │         │
     Player A    Player B  ... Difficulty   │
                                           │
                                  ┌────────┴────────┐
                                  │                 │
                                Topic              Pack
                                  │                 │
                                  │             ┌───┴───┐
                                  │             │       │
                                  │           Card    Card
                                  │
                                  └── Packs...
                                          
                            ↓
                     Candidate Pool
                            ↓
                     Random Assignment
                            ↓
                      Player Identities
                            ↓
                 ┌──────────┼──────────┐
                 ↓          ↓          ↓
              Player A   Player B   Player C
                 │          │          │
                 └──────────┼──────────┘
                            ↓
                  REAL-WORLD GAMEPLAY
```

## The key architectural principle

> **The Game Model describes what BiGuess needs to prepare and facilitate. It does not attempt to model every action that happens around the table.**

That distinction will save us a *lot* of unnecessary complexity.

---

There are still a few decisions I deliberately haven't locked:

1. **Exactly what metadata a Card contains**
2. Whether a **Pack can belong to multiple Topics**
3. Whether difficulty is `Easy/Medium/Hard` or a numeric scale
4. Exactly how **Random Topic / Selected Topics / Random Packs** behave
5. The precise algorithm for preventing duplicates
6. How many cards are needed before a pack is considered playable
7. Whether the same card can appear on two different players' phones in one round
8. How a downloaded pack is represented locally
9. How community-created content fits into the same model

Those are worth solving next because they connect the **Game Model** directly to the **Content Architecture**.

And I think **Content Architecture** should be our next section—not the technical stack yet. Once we know exactly what a Topic, Pack, Card, submission, and downloadable content unit look like, choosing Firestore/R2/local database/encryption becomes much more straightforward.

---

## **User:**

3. **Topics**: are non playable and non downloadable, you can play only inside one Topic, no multi-topic games cuz it need lot of downloads (all topics should be offline ready) and will make the game laggy by randomize and do functions in 10k list of cards.

5) **Cards**: there is no need for extra information (eg. anime: human?, vilan? alive? .....), just image, name, Difficulty and pack related are enough for MVP. extra information can be asked in the table or in web, cuz if you open this door, there unlimited number of parameters and 90% stays null, like `Alive?` can be assigned only to human, countries can't be alive.

9. **Difficulty**: Easy is included in Medium and Hard, Medium is included in Hard, if player choose Hard, he will get Easy and Medium and Hard cards, a.k.a all cards in the pack. default is Easy. can't be changed during the game, you have to exit to packs menu and change settings.
10. **Round**: BiGuess controls only tracking number of rounds, doesn't care who win or lose, left for table.

14) **Identity Assignment**: BiGuess can't control that the card shouldn't repeat in the table, random stays fully random across phone while they are not (and may will be not) related together.

20. the game named `BiGuess` not `Bi Guess` , respect the name, its like Facebook and Face Book.

There are still a few decisions I deliberately haven't locked:
Questions:

1. **Exactly what metadata a Card contains** 
2.  Whether a **Pack can belong to multiple Topics** 
3.  Whether difficulty is `Easy/Medium/Hard` or a numeric scale 
4.  Exactly how **Random Topic / Selected Topics / Random Packs** behave 
5.  The precise algorithm for preventing duplicates 
6.  How many cards are needed before a pack is considered playable 
7.  Whether the same card can appear on two different players' phones in one round 
8.  How a downloaded pack is represented locally 
9.  How community-created content fits into the same model

Answers:

1. (Name, Image, Difficulty, Pack related to)
2. No, pack belongs to one Topic ONLY, but Topic has many Packs inside.
3. yes you can make it numeric 1,2,3 with if (=1) then diff = "Easy" else .... it will take less memory with three constant time conditional tests.
4. you can't select many topics for one game, but you can choose one/selected/all\_random packs to start the game, don't forget that all selected packs should be downloaded already.
5. its already made and ready, it creates a list of cards data, and each replay, the chosen card removed from the list till the list is empty and fill it again from cached (downloaded) packs.
6. 2 or more.
7. yes, you can't control this.
8. I don't know, but shouldn't appear in the phone storage, cached in the app itself.
9. not part of the MVP, but we have BiGuess Studio may add this feature to (now its for admins and data collectors only).

---

## **ChatGPT:**

Yes. These answers make the model **much cleaner**. More importantly, you've now made several decisions that prevent us from accidentally turning BiGuess into a database-heavy “smart” game.

I want to lock these decisions and also point out one thing I disagree with slightly: **using numeric difficulty internally is good; making the code depend on magic numbers everywhere is not.** We can have `1/2/3` as the stored representation while exposing meaningful constants/enums in code.

Also, I fully respect the branding: **BiGuess**, always one word and capital B/G.

## Updated Game Model — Locked Decisions

### 1. Topic

A **Topic is an organizational container, not playable content**.

For example:

```text
Anime
├── Naruto
├── One Piece
├── Dragon Ball
└── Demon Slayer
```

```text
Football
├── World Cup
├── Players
├── Clubs
└── Algerian Football
```

Important consequences:

- A Topic itself cannot be downloaded.
- A Topic itself cannot be played.
- A game can use **exactly one Topic**.
- A Topic contains multiple Packs.
- Packs are the actual downloadable/playable units.

This is a good decision.

And your reason for avoiding multi-topic games is technically sound: there's no reason to make the app construct and randomize enormous cross-topic pools when the user can simply choose a pack within one topic.

---

# 2. Pack

A Pack belongs to **exactly one Topic**.

```text
Topic
  └── Pack
       ├── Card
       ├── Card
       ├── Card
       └── ...
```

A Pack is:

- playable;
- downloadable;
- cached locally;
- the main content unit selected by the player.

A Pack cannot belong to multiple Topics.

That's excellent for keeping the content model predictable.

---

# 3. Card

For MVP, a Card contains only:

```text
Card
├── name
├── image
├── difficulty
└── pack
```

That's it.

And I agree with your reasoning about **not creating a universal attribute database**.

For example, we could start with:

```text
isHuman
isAlive
isVillain
isMale
isFromJapan
isFootballPlayer
...
```

Then someone immediately asks:

> Why doesn't Country have `isAlive`?

Then:

> Why doesn't food have `isMale`?

Then:

> Why doesn't a movie have `isFootballPlayer`?

And suddenly we've built an enormous sparse schema where most fields are meaningless.

That's not BiGuess's job.

The group can ask:

> “Am I alive?”

if the context makes sense.

They can answer based on their knowledge.

Or they can look something up if they want.

**BiGuess provides the mystery identity, not the encyclopedia required to solve it.**

That's an important boundary.

---

# 4. Difficulty

Your hierarchy is particularly nice:

```text
Easy ⊂ Medium ⊂ Hard
```

Meaning:

| Selected difficulty | Cards available |
|---|---|
| Easy | Easy |
| Medium | Easy + Medium |
| Hard | Easy + Medium + Hard |

So difficulty is really an **upper difficulty boundary**, rather than an exact difficulty filter.

That makes the UX much more intuitive:

> **Easy** → familiar cards  
> **Medium** → familiar + moderately difficult  
> **Hard** → everything

And:

> **Easy is the default.**

Difficulty cannot be changed during an active game.

To change it:

**Exit → Packs/Play configuration → Change difficulty → Start again.**

I agree with this. Changing the pool in the middle of a session would complicate the mental model for very little benefit.

### Internal representation

I would store:

```text
difficulty: 1
difficulty: 2
difficulty: 3
```

and define them in code as something equivalent to:

```text
EASY = 1
MEDIUM = 2
HARD = 3
```

Then the selection logic is beautifully simple:

```text
card.difficulty <= selectedDifficulty
```

That gives you the exact behavior you described without repeatedly storing strings like `"Easy"` in every card.

---

# 5. Pack Selection

Now we have a much clearer structure.

The player first chooses:

> **One Topic**

Then chooses what to play from inside that Topic.

Three modes:

### One Pack

Example:

> Anime → Naruto

Only Naruto cards are used.

### Selected Packs

Example:

> Anime → Naruto + One Piece + Dragon Ball

The cards from those downloaded packs form the pool.

### Random Packs

BiGuess randomly selects packs **within the chosen Topic**.

This is important:

```text
Anime
  ↓
Random Packs
  ↓
Anime packs only
```

Not:

```text
Anime + Football + Movies + Countries
```

That keeps the game coherent and the content requirements manageable.

---

# 6. Download Requirement

This is now very clear.

A pack must be **downloaded before it can participate in a game**.

So if the player selects:

```text
Naruto ✓ Downloaded
One Piece ✓ Downloaded
Dragon Ball ✗ Not downloaded
```

and chooses all three:

> **Start Game**

BiGuess should stop them and explain that Dragon Ball needs to be downloaded.

It should never silently start downloading a huge amount of content in the background while the group is waiting to play.

The UX should make content availability obvious.

---

# 7. Randomization

You already have the correct approach here, and I would keep it.

When a game starts, BiGuess creates a local list from the cached/downloaded cards.

For example:

```text
Pool:
A
B
C
D
E
F
G
```

When a card is selected:

```text
Pool:
A
B
C
D
F
G
```

`E` is removed.

Next:

```text
Pool:
A
B
C
D
G
```

Eventually:

```text
Pool:
[]
```

Then BiGuess rebuilds the list from the cached pack data.

This gives you the behavior of a shuffled deck.

### Important clarification

This is **local to each device**.

There is no attempt to synchronize these lists between players.

---

# 8. Identity Assignment

This is an important correction from our previous model.

BiGuess **does not guarantee that identities are unique across players**.

Each phone operates independently.

For example:

```text
Phone A → Naruto

Phone B → Luffy

Phone C → Naruto

Phone D → Sasuke
```

Yes, Naruto can appear twice.

That's acceptable because:

> **BiGuess cannot know that these phones belong to the same game.**

And you don't want to introduce networking merely to solve this.

This is a perfect example of the principle:

> **Don't solve a problem that the real-world players can simply handle.**

If they don't want duplicates, that's part of how they choose to play.

---

# 9. Round

A round is simply:

> **One cycle of card assignment.**

BiGuess can track:

```text
Round 1
Round 2
Round 3
...
```

But it does **not** track:

```text
Player A won
Player B lost
Player C guessed correctly
```

The app doesn't know.

The table does.

So if the user chooses:

> **5 rounds**

BiGuess's responsibility is basically:

```text
Round 1 → prepare
Round 2 → prepare
Round 3 → prepare
Round 4 → prepare
Round 5 → finish
```

Who won each round is outside the digital game model.

---

# 10. Timer

**Removed from the MVP.**

Not optional.

Not hidden behind a setting.

Not implemented “just in case.”

It simply doesn't exist in the initial game.

If players eventually request it, we'll revisit the decision based on actual feedback.

I think that's the correct product discipline.

---

# 11. Scoring

Also outside the MVP.

No:

- winner buttons;
- score counters;
- question counters;
- automatic winner detection;
- synchronized scoring.

The real-world group decides.

---

# 12. The Game Model Is Now Much Smaller

We can describe the MVP model as:

```text
Topic
  │
  └── Pack
       │
       └── Cards
            │
            ├── Name
            ├── Image
            └── Difficulty (1–3)
```

Then:

```text
Game
│
├── One Topic
│
├── One / Selected / Random Packs
│
├── Difficulty
│
├── Number of Rounds
│
└── Players
```

And during a round:

```text
Selected Packs
      ↓
Build Card Pool
      ↓
Filter:
card.difficulty <= selectedDifficulty
      ↓
Random selection
      ↓
Local card removed from pool
      ↓
Identity displayed
      ↓
Real-world gameplay
```

That's **much cleaner** than where we started.

---

# 13. Local Content

Your requirement is:

> **Downloaded content should not appear as ordinary files in the user's accessible phone storage.**

Correct.

The content should live inside the application's private storage/cache.

Conceptually:

```text
BiGuess App
│
├── App Database
│
├── Downloaded Pack Data
│
├── Encrypted Images
│
└── Game State
```

rather than:

```text
Downloads/
  BiGuess/
    Naruto/
      naruto.jpg
      sasuke.jpg
```

And I agree that this should be part of the architecture from the beginning rather than bolted on later.

Again, this isn't perfect DRM—nothing displayed on a device can be made completely impossible to extract—but it prevents casual scraping and makes the content significantly less exposed.

---

# 14. Community Content

For the MVP:

**Not part of the player-facing game system.**

But the architecture should **not prevent it**.

That's an important distinction.

Today:

```text
BiGuess Studio
      ↓
Admins / Data Collectors
      ↓
Official content
      ↓
Publish
```

Later:

```text
Community Creator
      ↓
Submission
      ↓
BiGuess Studio
      ↓
Review / Accept / Reject
      ↓
Publish
      ↓
BiGuess users
```

So we're designing for the possibility without making the MVP carry all the complexity of a community platform.

---

# 15. One thing I want to explicitly lock

You said:

> “Topics are non playable and non downloadable.”

I think we should make the terminology very strict:

### Topic

**A category for organizing Packs.**

### Pack

**A downloadable collection of Cards that can be played.**

### Card

**A playable identity.**

That gives us a very clean vocabulary throughout:

> “Choose a Topic.”

> “Choose a Pack.”

> “Download the Pack.”

> “Start the Game.”

> “Receive a Card.”

No ambiguity.

---

# Current Game Model

So, if I were putting this into our project blueprint today, the model would be:

```text
                         BiGuess
                            │
                       Game Session
                            │
              ┌─────────────┼─────────────┐
              │             │             │
            Topic        Settings       Rounds
              │             │             │
              │       ┌─────┼─────┐       │
              │       │     │     │       │
              │   Difficulty Packs Rounds │
              │                         │
              ↓                         │
            Packs                        │
              │                          │
              ↓                          │
            Cards                        │
              │                          │
       ┌──────┼────────┐                 │
       │      │        │                 │
      Name   Image  Difficulty           │
                     1/2/3               │
                                         │
              └──────────────┬───────────┘
                             ↓
                      Local Card Pool
                             ↓
                     Random Assignment
                             ↓
                       Player's Card
                             ↓
                   REAL-WORLD GAMEPLAY
```

And the philosophy behind it is:

> **BiGuess manages content, configuration, randomization, and round progression. The players manage the actual social game.**

I think we're now at a good point to move to **Content Architecture**.

That's where we should design the other half of this system: how content goes from **BiGuess Studio → storage → catalog → download → encrypted local cache → playable pack**, including how the current admin/data-collector workflow works and how we leave a clean path for community submissions later.

---

## **User:**

Nooo rounds specified after choosing packs, like between pack and game, he can update settings or keep defaults

---

## **ChatGPT:**

Yes — you're right. I put **Rounds** at the wrong level in the model.

The flow should be:

```text
Open BiGuess
    ↓
Choose Topic
    ↓
Choose Pack(s)
    ↓
Configure Game
    ↓
Start Game
    ↓
Round 1
    ↓
Round 2
    ↓
...
```

So **game settings come after content selection and immediately before starting the game**.

### Correct UX hierarchy

**1. Topic**

Choose exactly one Topic.

**2. Packs**

Choose:

- One Pack
- Selected Packs
- Random Pack(s)

All selected packs must already be downloaded.

**3. Game Settings**

Once the content is selected, the user gets the settings screen.

Here they can either:

> **Start with defaults**

or modify:

- **Difficulty** — Easy by default
- **Rounds** — default value
- potentially other MVP settings we eventually decide belong here

Then:

> **Start Game**

This is much more natural because the player first answers:

> *“What are we playing?”*

and only then:

> *“How do we want to play it?”*

### The important distinction

The **game** owns the settings.

The **round** doesn't.

So:

```text
Game
├── Topic
├── Selected Packs
├── Difficulty
├── Number of Rounds
└── Rounds
     ├── Round 1
     ├── Round 2
     └── Round 3
```

The settings are established **before Round 1** and remain fixed throughout that game.

If the player wants to change difficulty or number of rounds:

> **Exit Game → return to configuration → change settings → start a new game.**

That's consistent with your earlier rule that settings cannot be changed during gameplay.

### Final flow

I would lock the core flow as:

```text
                    BiGuess
                       ↓
                 Choose Topic
                       ↓
                  Choose Packs
                       ↓
                ┌──────────────┐
                │ Game Settings│
                │              │
                │ Difficulty   │
                │ Rounds       │
                │ Defaults ✓   │
                └──────┬───────┘
                       ↓
                  Start Game
                       ↓
                    Round 1
                       ↓
                  Round 2...
                       ↓
                 Game Finished
```

And yes, **“keep defaults” should be a first-class UX path**, not something users have to configure manually every time. Most casual groups should be able to select their content and immediately start.

This correction also makes the eventual UI structure much cleaner. **Topic selection, Pack selection, and Game Configuration are three distinct stages**, rather than mixing game settings into the content model.

---

## **User:**

type me what to write in the md file for Game Model.

---

## **ChatGPT:**

Yes. Since this is going directly into the project blueprint, I would keep it **precise and implementation-oriented**, without prematurely deciding the technical storage architecture.

Replace the `Game Model` section in your MD with this:

## Game Model

### 1. Game Structure

A BiGuess game is a temporary face-to-face game session played by two or more people, where each player uses their own phone.

A game consists of:

- One selected **Topic**
- One or more selected **Packs** belonging to that Topic
- Game settings
- One or more **Rounds**

The application manages content selection, configuration, random card assignment, and round progression.

The actual guessing, questioning, answering, winning, and other social interactions happen between the players in real life and are not controlled by the application.

---

### 2. Topic

A **Topic** is an organizational category containing multiple Packs.

Examples:

- Anime
- Football
- Movies
- Countries
- Food
- Animals
- History
- Science

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

- **Name**
- **Image**
- **Difficulty**
- **Pack**

No additional semantic attributes are required.

BiGuess does not attempt to store every possible property of an identity, such as:

- Is the person human?
- Is the person alive?
- Is the character a villain?
- Is the character male?
- Is the identity from a specific country?
- etc.

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

| Selected Difficulty | Eligible Cards |
|---|---|
| Easy | Easy |
| Medium | Easy + Medium |
| Hard | Easy + Medium + Hard |

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

- Difficulty
- Number of Rounds

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

- who won;
- who lost;
- who guessed first;
- whether a guess was correct;
- how many questions were asked;
- whether players followed the rules.

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

- enter questions;
- record answers;
- validate answers;
- press a button after every question;
- report guesses;
- confirm winners.

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

This version now reflects your corrections: **Topic is non-playable, one Topic per game, Packs are the downloadable units, settings happen after Pack selection, difficulty is cumulative, rounds are tracked but not scored, card assignment is completely independent per phone, and the MVP has no timer or scoring.**

One detail I deliberately kept flexible is the exact behavior of **“Random Packs”**. We know it must operate *inside the chosen Topic* and only use downloaded Packs, but we should define exactly what “random” means when we design the Pack-selection UX.

---

