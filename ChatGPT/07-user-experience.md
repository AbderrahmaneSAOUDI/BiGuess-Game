# User Experience & Physical Table Dynamics

> Designing around the physical room/table rather than phone screens

---

## **User:**

User Experience

---

## **ChatGPT:**

Yes. Now that the core philosophy is clear, **User Experience should be designed around the physical table, not around the app screens**.

I would make this section very concrete, because later it will become the reference for deciding what the Flutter app actually does.

### User Experience

# User Experience

## 1. The Core Experience

BiGuess should make a group able to start playing within seconds.

The ideal experience is:

**Open → Choose → Prepare → Reveal → Put the phone outward → Play.**

The application should handle the preparation and then become almost invisible.

The players should spend most of the session:

- looking at each other;
- asking questions;
- listening to answers;
- thinking;
- guessing;
- laughing;
- arguing about interpretations;
- and enjoying the social interaction.

The phone is a facilitator, not the center of attention.

---

## 2. Starting the Game

A player opens BiGuess.

The home screen should immediately communicate the main action:

**Play**

Secondary actions can provide access to:

- Content / Topics
- Downloads
- Settings
- About

The player should not need an account or internet connection to start playing with already-downloaded content.

---

## 3. Choosing What to Play

The group chooses what kind of identities they want to play with.

The content hierarchy should eventually be:

**Topic → Pack → Cards**

For example:

**Anime**
- Naruto
- One Piece
- Demon Slayer

**Football**
- World Cup Legends
- Famous Players
- Algerian Players

**Movies**
- Marvel
- Harry Potter
- Famous Actors

The player can select one or more packs.

### Single Pack

Example:

> One Piece

Every identity comes from that pack.

### Multiple Packs

Example:

> Naruto + One Piece + Dragon Ball

BiGuess combines the selected pools and randomizes across them.

### Randomize Everything

The group can choose:

> **All Available**

This allows BiGuess to select identities from all downloaded compatible packs.

The application should make this choice easy without forcing players to navigate through a large configuration system.

---

## 4. Difficulty

Difficulty determines **which identities can be selected**, not how players are allowed to ask questions.

Possible levels:

### Easy

Mostly highly recognizable identities.

### Medium

A broader selection requiring more knowledge.

### Hard

Less obvious or more specialized identities.

The difficulty should be determined by the content metadata.

For example, a football pack might classify Messi as Easy, a less famous international player as Medium, and an obscure historical player as Hard.

The actual conversation remains unrestricted.

An Easy identity might still take 20 questions.

A Hard identity might be discovered after 3 questions.

That is part of the fun.

---

## 5. Number of Players

BiGuess should support **two or more players**.

The application does not need to establish an online room or connect the players' phones.

Every player simply opens BiGuess independently.

The group decides who is participating.

For example:

**4 players**

Each player:

1. Opens BiGuess.
2. Selects the same topic/pack.
3. Starts a round.
4. Receives a random identity.
5. Turns the phone outward.

The players are physically together, so no digital synchronization is necessary for the core game.

---

## 6. Receiving the Identity

When a player starts a round, BiGuess privately prepares their identity.

The player should initially see an appropriate preparation/reveal state so they do not accidentally discover their own identity.

The final state is designed for the physical game:

**The player cannot see the identity.**

**Everyone else can.**

The player turns the phone toward the group.

The group can now see the image while its owner cannot.

This is one of the defining interactions of BiGuess and should receive particular attention during UI and usability testing.

---

## 7. Playing the Round

Once everyone has their identity visible to everyone else, the application should largely disappear.

Players take turns asking the group **Yes-or-No questions** about their own hidden identity.

Examples:

> “Am I a human?”

> “Am I a football player?”

> “Am I from Japan?”

> “Am I a villain?”

> “Do I have black hair?”

The group answers verbally.

The player uses those answers to narrow down the possibilities.

No question needs to be entered into the application.

No answer needs to be recorded.

No button needs to be pressed after every question.

The conversation itself is the game.

---

## 8. Guessing

When a player believes they know their identity, they announce their guess verbally.

The group determines whether the guess is correct.

BiGuess does not need to automatically verify the answer.

The application cannot reliably know what happened in the real-world conversation, and trying to enforce this would add unnecessary friction.

The group remains the authority over the game.

---

## 9. Winning

The default game should allow the group to determine the winner naturally:

> **The first player to correctly identify their identity wins the round.**

BiGuess does not need to enforce this electronically.

The group can simply announce the winner.

Optional game modes may later introduce rounds or lightweight scoring, but the core experience should remain playable without any digital scorekeeping.

---

## 10. Rounds

Rounds are an optional structure rather than a requirement.

A group can simply play:

**Round → Winner → New Round**

If they want a longer session, they may configure:

- number of rounds;
- selected packs;
- difficulty;
- randomization rules.

The application should help prepare the next round without forcing players through unnecessary result screens.

A group that wants to immediately play again should be able to do so quickly.

---

## 11. Timer

The default game should have **no mandatory timer**.

Real conversations are unpredictable.

An identity might be discovered after three questions or thirty questions. Neither should be considered a problem.

A timer can instead be an optional game mode for groups that want additional pressure.

For example:

**Speed Mode**

> 60 seconds per player.

The timer should never be necessary for normal BiGuess.

---

## 12. Avoiding Repetition

BiGuess should provide a non-repeating randomization option.

Within a session, an identity should not normally be selected again until the available identities in the selected pool have been exhausted.

This makes BiGuess behave more like a shuffled physical deck than an unrestricted random-number generator.

The application should handle this automatically.

Players should not need to understand the algorithm.

---

## 13. Offline Experience

Downloaded packs should remain available without an internet connection.

A player can therefore:

1. Download a pack while connected.
2. Leave the internet.
3. Open BiGuess later.
4. Select the downloaded pack.
5. Play normally.

The core gameplay must not require:

- login;
- network connection;
- server availability;
- real-time synchronization;
- cloud database access.

Online connectivity is primarily used to discover, download, update, and manage content.

---

## 14. Content Discovery

The application can connect to the online content ecosystem when internet access is available.

Players should be able to discover:

- new topics;
- new packs;
- updated packs;
- community-created packs;
- recommended content.

A pack should clearly communicate its state.

For example:

**Downloaded**

> ✓ Available Offline

**Update Available**

> New version available · 4 MB

**Not Downloaded**

> Download · 18 MB

**Coming Soon**

> Content is still being prepared.

The player should always understand whether a pack is available offline.

---

## 15. Downloading Content

Content should be downloaded as **versioned packs**, rather than requiring the application to retrieve individual images during gameplay.

Example:

> **One Piece**
>
> 466 cards  
> 18 MB  
> Version 1.4
>
> **Download**

After installation:

> ✓ Available Offline

When a newer version becomes available:

> **Update available**
>
> 4.2 MB

This allows the base application to remain small while the content library grows independently.

---

## 16. Returning Players

When the player opens BiGuess again, the application should remember useful local information such as:

- downloaded packs;
- preferred theme;
- preferred difficulty;
- preferred countdown/mode settings;
- recently used content.

The player should not have to repeatedly configure the same environment.

However, BiGuess should not require an account merely to remember local preferences.

---

## 17. The Ideal Session

A successful BiGuess session should feel approximately like this:

### Before playing

A group sits together.

Someone says:

> “Let's play One Piece.”

Everyone opens BiGuess.

They select the same pack.

### Preparation

Each player starts a round.

Each phone chooses an identity.

Everyone turns their phone outward.

### The game

Player 1:

> “Am I a pirate?”

Group:

> “Yes.”

Player 2:

> “Am I a woman?”

Group:

> “No.”

Player 3:

> “Am I from the Straw Hat crew?”

The conversation continues.

Phones remain mostly stationary.

People interact with each other.

### Someone guesses

> “I'm Zoro!”

The group confirms it.

The player wins the round.

### Next round

Everyone taps once to get another identity.

The game continues.

The application never becomes the focus.

---

## 18. UX Design Rule

The most important UX measurement for BiGuess is not:

> “How many features can the player access?”

It is:

> **“How little attention does the player need to give the phone?”**

A good BiGuess interface should therefore minimize:

- text input;
- repeated taps;
- mandatory confirmations;
- animations that delay gameplay;
- complicated navigation;
- account requirements;
- network waiting;
- unnecessary notifications;
- mandatory scoring;
- mandatory timers;
- question tracking.

The application should be fast, obvious, readable, and physically usable while the phone is facing away from its owner.

---

## 19. Physical-World Design Requirements

The UI must be designed for the unusual physical position of the phone.

The phone may be:

- held at arm's length;
- placed on a table;
- angled toward several people;
- viewed by people who are not holding it;
- used in bright or dim environments.

Therefore, identity presentation should prioritize:

- large imagery;
- strong contrast;
- minimal UI;
- clear orientation;
- no unnecessary controls;
- readable information from a distance.

The identity screen is not a normal mobile screen.

It is effectively a **digital physical card**.

That should influence its entire design.

---

## 20. The Product's Golden UX Rule

> **BiGuess should do everything necessary to prepare the game and almost nothing unnecessary once the game begins.**

The best compliment a player can give the application is not:

> “There are so many things to tap.”

It is:

> **“We opened it and started playing immediately.”**

This gives us a much clearer foundation than the current app's screen-by-screen design.

The **most important new requirement** I would carry forward into the technical architecture is the “digital physical card” concept. The identity/reveal screen isn't just another Flutter page—it is the physical interface between the app and the people around the table.

And this UX also confirms something important: **the Content Studio and content delivery system are going to be much more important to BiGuess's long-term scalability than online multiplayer.**

Next I'd define the **Game Model: `Topic → Pack → Card`**, including exactly what metadata a card needs, how randomization works with multiple players, how difficulty is represented, and how downloaded packs work locally.

---

## **User:**

2. Starting the Game: the user needs internet to download the needed packs then continue playing offline, and the loop repeats if user need to play in other topics/packs
3. Choosing What to Play: I like the option to play single/selected/random topics; but we have to think in easy to understand and use UX for all the gameplay settings, also for point 4 (Difficulty) and 10 (Rounds).

11) the timer is not part of the MVP, let say its not planning to be added to the game unless the community asked for it, I don't know if I am correct in this decision but this is what we will start with.

13. The core gameplay must require network connection is there is no packs downloaded yet.

15) Downloading Content should be encrypted inside the app, not as simple images in the phone storage, that will facilitate data scrapping. also no need for pack versioning, just compare content and download missing.

18. Keep animations, the attractive part of UI is animations so keep them and make them attractive, but never over effects.

---

## **ChatGPT:**

Agreed. Your corrections make the UX definition more accurate. I would **not rewrite the whole section yet**; I'd lock the changes first and carry them into the blueprint.

There are four important changes.

### 1. Internet is required for new content

The actual model is:

**No downloaded content → Internet required → Download → Play offline**

Then:

**Want another pack → Internet required → Download → Play offline**

So the app isn't “offline from first launch.” It's **offline after the required content has been downloaded**.

That is a better and more honest promise.

---

### 2. Gameplay settings need a much better UX

I agree that simply listing:

- difficulty
- rounds
- randomization

isn't enough.

We need to design the configuration experience so a group can understand it **without reading documentation**.

I would eventually aim for something like:

**Quick Play**

> What do you want to play?

**Topic**
- 🎌 Anime
- ⚽ Football
- 🎬 Movies
- 🌍 Countries
- 🎲 Random

**Content**
- One Pack
- Multiple Packs
- Everything downloaded

**Difficulty**
- Easy
- Medium
- Hard

**Rounds**
- 1
- 3
- 5
- Unlimited

And probably a **Quick Start** path where the player doesn't even have to configure everything.

But let's **not decide the exact UI yet**. We should solve that when we design the complete gameplay flow.

---

### 3. Timer is NOT an MVP feature

I actually think your decision is correct.

I would change the principle from:

> “Timer is optional.”

to:

> **“Timer is not part of the initial game. It may be considered later if real players request it.”**

That's an important distinction.

We're not designing a feature just because it *could* be useful.

We'll launch without it, observe how people actually play, and only introduce it if there's evidence that players want it.

That's exactly the kind of restraint I want us to maintain throughout the project.

---

### 4. Content should be encrypted locally

This is a good security/product requirement, with one important caveat:

**Encryption will discourage casual extraction; it cannot make content impossible to scrape.**

If the phone can display an image, a sufficiently determined attacker can eventually extract it from memory, capture the screen, reverse-engineer the app, etc.

So our goal shouldn't be:

> “Impossible to scrape.”

It should be:

> **“Don't make the content trivially extractable from ordinary device storage.”**

That means we should avoid:

```text
/storage/emulated/0/BiGuess/
    naruto/
       naruto.webp
       sasuke.webp
       ...
```

Instead, downloaded content can be stored in the app's private storage in an encrypted/package format, with the game engine decrypting what it needs at runtime.

We should design the exact mechanism later when we reach the technical architecture.

---

## One correction to my previous recommendation: pack versioning

I agree with your goal, but I want to challenge the implementation slightly.

You said:

> “No need for pack versioning, just compare content and download missing.”

**The user should absolutely not have to think about versions.**

But internally, I still recommend some concept of content revision/hash.

Not necessarily:

> `One Piece v1.4`

visible to the user.

Instead:

```text
Server catalog
     ↓
content fingerprint
     ↓
compare with local fingerprint
     ↓
download only what's missing/changed
```

Why?

Because otherwise the client has to compare potentially thousands of individual pieces every time.

We can make the system appear versionless to the user while still having efficient internal integrity/version information.

So I'd define the principle as:

> **Content updates should be transparent to users and download only what is necessary. Internal fingerprints or revisions may be used to make synchronization efficient and reliable.**

That's the best of both approaches.

---

# And yes: KEEP the animations

I want to explicitly correct the wording in the UX section.

The principle shouldn't be:

> “Minimize animations.”

It should be:

> **“Animations should enhance the experience without becoming the experience.”**

BiGuess can absolutely have a strong visual personality.

In fact, I think it **should**.

The app needs to feel exciting when:

- selecting a topic;
- shuffling cards;
- generating identities;
- transitioning into a round;
- revealing/setting up the identity;
- completing a round;
- starting the next round.

But there's a difference between:

**Good**

> *smooth shuffle → card movement → satisfying transition → identity appears*

and:

**Bad**

> *8-second cinematic animation before every round because the developer wanted to show off the animation system.*

The first creates excitement.

The second creates friction.

So the rule I'd lock is:

> **BiGuess should have attractive, expressive animations that reinforce the game's playful personality while remaining fast and unobtrusive during actual gameplay.**

That's much more appropriate.

---

## One more thing I want to add

The **identity screen** deserves special treatment.

It's probably the most important screen in the entire application.

Not because it has the most features.

Because it has to solve a weird physical problem:

**The owner must not see it, while everyone else must see it clearly.**

That's essentially a **digital physical card**.

We should eventually test things like:

- image size;
- brightness;
- contrast;
- viewing distance;
- orientation;
- accidental touches;
- screen timeout;
- whether the owner can accidentally peek;
- whether the group can recognize the identity immediately;
- whether the screen works when placed on a table.

This is where real-world testing will matter more than conventional mobile-app UX theory.

---

### So I would now lock these UX principles:

**Core flow**

> Download required content → Configure game → Generate identities → Turn phones outward → Real-world gameplay → New round.

**Connectivity**

> Internet for discovering/downloading content; downloaded content works offline.

**Settings**

> Simple, understandable configuration for topic selection, difficulty, randomization and rounds.

**Timer**

> Not part of MVP. Reconsider only based on community demand.

**Content storage**

> Downloaded content should be protected in private/encrypted application storage rather than exposed as ordinary image files.

**Updates**

> Automatic/transparent content comparison; download only missing or changed content. Internal fingerprints/revisions are allowed.

**Animations**

> Attractive and expressive, but fast and purposeful. Never let effects interfere with gameplay.

**Core philosophy**

> The application prepares the game; the people play the game.

I think these are solid enough to move forward.

**Next: Game Model.**

That's where we define exactly what **Topic → Pack → Card** means, what a card contains, how randomization works across multiple players and multiple packs, how difficulty is represented, how duplicates are prevented, and what the local downloaded-content model looks like.

---

## **User:**

- whether the owner can accidentally peek; 
-  whether the group can recognize the identity immediately; 
-  whether the screen works when placed on a table.

you can't control those situations, they are part of the real life rules, the group should control those.

I will put all `lib/` flutter folder beside and start new one inspiring from the old one, also I am thinking on making the game playable without downloading but stays online to fetch one image each time then I canceled the idea from my head because it takes a lot of reads and that's not good for my free tier.

---

## **ChatGPT:**

Exactly. I agree with your correction.

Those three points I added were drifting into **trying to engineer the real-life rules**, which goes against the philosophy we've established.

BiGuess can control:

- what identity is selected;
- how it is displayed;
- how content is downloaded;
- what settings are configured;
- how the digital game state works.

BiGuess **cannot and should not control**:

- whether someone accidentally sees their identity;
- whether someone intentionally cheats;
- whether the group can recognize an image;
- how people hold their phones;
- whether someone puts the phone on a table;
- whether somebody gives a misleading answer;
- whether the group accepts a guess;
- whether somebody argues about an answer.

Those are **social rules**, not software requirements.

So I'd explicitly add this principle:

> **BiGuess does not attempt to police physical gameplay. The group is responsible for how the game is played in the real world.**

That keeps the product beautifully simple.

---

# And I strongly agree with your decision about fetching one image at a time

I think cancelling that idea was the correct decision.

At first glance:

> “Don't make users download packs. Just fetch the image when needed.”

sounds convenient.

But it creates a bad architecture for BiGuess.

Imagine 6 players × multiple rounds × image requests.

Now you're generating:

- network dependency during gameplay;
- repeated storage/CDN requests;
- latency;
- failures when internet is weak;
- more infrastructure usage;
- potentially significant read/request costs;
- a worse experience in exactly the environments where BiGuess should work.

And most importantly:

> **You're making the core game dependent on the network.**

That's contrary to the product vision.

Your pack model is much cleaner:

```text
               INTERNET
                   │
                   ▼
          Discover available pack
                   │
                   ▼
              Download
                   │
                   ▼
          Encrypted local pack
                   │
             ┌─────┴─────┐
             │           │
          Internet     NO INTERNET
             │           │
             ▼           ▼
        Update content   PLAY
```

Once the pack is downloaded, gameplay should ideally generate **zero network traffic**.

That's a very strong architecture.

---

# One subtle point about your free tier concern

I wouldn't optimize the entire architecture around:

> “How do I stay inside Firebase's free tier forever?”

I'd instead optimize around:

> **“How do I minimize unnecessary cloud operations?”**

Those are different philosophies.

If BiGuess becomes genuinely popular, eventually paying for infrastructure is a **good problem**.

For example:

```text
10 users
→ free infrastructure

1,000 users
→ probably still cheap

10,000 users
→ some costs

100,000 users
→ meaningful costs

1,000,000 users
→ congratulations, BiGuess is a real product
```

At that point, worrying about whether you crossed a free-tier limit isn't the important problem anymore.

But **unnecessary reads are bad at every scale**, so designing the content system to avoid them is absolutely correct.

---

# Your new Flutter project decision

I also support this:

> **Put the existing `lib/` aside and start a clean implementation inspired by the old one.**

I actually prefer that over incrementally modifying the existing architecture.

Not because the old code is necessarily bad.

Because we're now changing the **product architecture**, not just adding features.

The old project becomes:

> **Reference implementation / laboratory**

The new project becomes:

> **BiGuess according to the new blueprint**

You can selectively bring over things that are proven useful:

- UI components
- animations
- utilities
- image optimization ideas
- data structures
- testing approaches
- release automation
- lessons learned

But nothing gets copied merely because it already exists.

That gives us a clean opportunity to ask:

> **“If we were building BiGuess today knowing everything we know now, how would we structure it?”**

That's exactly the mindset I want.

---

## One thing I would NOT do yet

Don't start creating the new Flutter folders today just because we've defined the first pieces.

We're still missing several fundamental decisions:

**Game Model**  
↓  
**Content Architecture**  
↓  
**Content Studio**  
↓  
**Offline Storage & Synchronization**  
↓  
**Technical Architecture**  
↓  
**MVP**  
↓  
**Implementation**

If we start coding now, we'll probably repeat the same problem we're trying to escape.

We're close, though.

The next section—**Game Model**—is where the vision starts becoming an actual system.

And I think we should be particularly strict there about separating:

**what BiGuess knows and controls**

from

**what the players know and control.**

That distinction is going to make the eventual architecture much cleaner.

---

