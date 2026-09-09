# Product Principles & Design Filters

> Core product principles (frictionless, face-to-face, offline, scalable content)

---

## **User:**

Product Principles

---

## **ChatGPT:**

Absolutely. This section is arguably **more important than the tech stack**, because these principles become the filters we use later when deciding whether a feature belongs in BiGuess.

Based on the game definition we've established, I'd make the principles fairly strict.

## Product Principles

### 1. Real Life Comes First

**BiGuess exists to improve face-to-face interaction, not replace it.**

The players, their questions, reactions, arguments, jokes, and laughter are the actual game. The phone is only the facilitator.

Every feature should be evaluated against one question:

> **Does this make the real-world experience better, or does it make players spend more time interacting with their phones?**

If a feature makes the phone more important than the people, it needs a very strong justification.

---

### 2. The Phone Should Get Out of the Way

After the identities are assigned and displayed, the app should require as little interaction as possible.

Players should be able to:

- glance at their screen,
- see the identity clearly,
- turn the phone toward the group,
- ask their question,
- listen to the answer,
- think,
- and continue playing.

BiGuess should **not** require players to record every question, answer every turn through the app, or constantly manipulate the interface.

The ideal BiGuess session should feel almost like playing with physical cards.

---

### 3. Offline First, Not Offline Eventually

The core game must work without an internet connection.

No account.

No login.

No server.

No network connection.

No Firebase dependency.

No cloud requirement.

A group should be able to download BiGuess once and then play it anywhere.

This isn't merely a cost-saving decision. It is part of the identity of the product.

A game intended for gatherings should not fail because the café has bad Wi-Fi.

---

### 4. Humans Control the Game

BiGuess should facilitate the rules rather than attempt to police them.

The app cannot reliably know:

- whether somebody answered honestly,
- whether somebody cheated,
- whether a guess was technically correct,
- whether two players simultaneously guessed correctly,
- whether the group accepted an answer,
- whether someone skipped a question,
- whether an argument around an answer was funny or annoying.

And it doesn't need to.

The group decides.

BiGuess provides the tools and lets the people playing establish the social rules.

---

### 5. Zero Unnecessary Friction

Starting a game should be extremely fast.

The ideal flow should approach:

**Open → Choose → Start → Play.**

No account creation.

No room codes.

No invitations.

No matchmaking.

No waiting for other devices to connect.

No configuration screens that players have to understand before they can begin.

Optional settings can exist, but the default path should remain extremely short.

---

### 6. Randomness Must Feel Fair

Randomization is one of BiGuess's core responsibilities.

The application should provide predictable and trustworthy behavior around:

- random identity selection,
- avoiding unwanted repetition,
- empty or incomplete packs,
- player/session isolation,
- restarting sessions.

If a player receives the same identity repeatedly, or one person somehow gets noticeably favored, the physical game experience suffers.

The technology should quietly handle this problem without forcing the players to think about the algorithm.

---

### 7. Content Is the Game

The application itself is only half of BiGuess.

The other half is the content library.

A beautiful interface with ten cards won't create a great party game.

BiGuess should therefore be designed from the beginning to support a continuously expanding collection of topics, packs, and identities.

The architecture must allow us to move from:

**Anime**

to:

**Movies → Football → Countries → Food → History → Science → Animals → Games → ...**

without redesigning the game engine for every new subject.

---

### 8. Topic-Agnostic by Design

The core engine should not care whether a card represents:

- a fictional character,
- a football player,
- a country,
- a food,
- a movie,
- an animal,
- a historical figure,
- a scientist,
- or something we haven't thought of yet.

The fundamental model should therefore be something closer to:

**Topic → Pack → Card**

rather than building the application around anime franchises.

Anime can be the first major content family without becoming a limitation on the architecture.

---

### 9. Content Must Scale Independently From Code

Developers should not be required every time a new card is added.

A future content contributor should be able to add:

> Topic → Pack → Card → Image → Metadata

without modifying the game's source code.

This is one of the most important principles for BiGuess's long-term scalability.

The game engine should be stable while the content library continuously evolves.

---

### 10. Quality Over Quantity

Having thousands of cards isn't automatically better.

A giant collection containing obscure, duplicated, incorrectly named, low-quality, or inappropriate images can make the game worse.

BiGuess should prioritize:

- recognizable identities,
- good image quality,
- accurate metadata,
- useful difficulty classification,
- consistent presentation,
- appropriate pack organization.

A carefully curated 100-card pack can be better than a random 1,000-card pack.

---

### 11. Difficulty Should Affect the Content, Not the Conversation

Difficulty belongs primarily in **what gets selected**, not in controlling how people play.

For example:

**Easy**
→ highly recognizable identities

**Medium**
→ broader collection

**Hard**
→ obscure identities / deeper knowledge

The app shouldn't decide that an “Expert” player gets only 10 questions.

The players can take 2 questions or 30 questions.

The conversation determines the difficulty of the actual round.

---

### 12. Optional Rules, Not Forced Rules

BiGuess should support different ways groups naturally want to play.

Some groups may want:

- a timer,
- a fixed number of rounds,
- a score,
- first-to-five,
- specific difficulty,
- specific packs.

Others may want absolutely none of that.

Therefore:

> **Rules that don't need software enforcement should remain optional.**

The default experience should be the simplest version of the game.

---

### 13. Privacy by Default

The core game should require no personal information.

There is no reason for BiGuess to know who is playing.

No account should be necessary for the fundamental experience.

If future online features require accounts or analytics, they should be introduced because they provide meaningful value—not because accounts are considered standard app architecture.

---

### 14. Free and Cheap to Operate at the Beginning

BiGuess is not expected to generate significant revenue immediately.

Therefore, early infrastructure should reflect that reality.

We should prefer:

**local computation > static content > generated content packages > inexpensive/free infrastructure > paid infrastructure**

rather than designing around services that create recurring costs before the product has proven demand.

Cloud services can be introduced later when:

> **usage justifies the cost.**

Revenue should eventually finance infrastructure—not the other way around.

---

### 15. Don't Build Technology for Imaginary Problems

This one should be written in bold in our internal specification.

**No feature should exist simply because it is technically interesting.**

Examples:

> “We need Firebase because it's a multiplayer game.”

Not necessarily.

> “We need accounts.”

Why?

> “We need real-time synchronization.”

For what?

> “We need AI.”

What problem does it solve?

> “We need a backend.”

What cannot be done locally?

If the simplest solution works, **the simplest solution wins.**

---

### 16. The Core Game Must Survive Without the Internet

Even if BiGuess eventually gains:

- cloud content,
- accounts,
- statistics,
- community packs,
- online features,
- synchronization,
- monetization,

none of those should destroy the fundamental offline game.

The player should always be able to rely on the basic experience:

**Choose a topic → receive identities → turn phones outward → play.**

That is the foundation.

---

### 17. Don't Let Monetization Corrupt the Core Experience

If BiGuess eventually earns money, monetization should not undermine the reason people enjoy it.

We should be extremely cautious with:

- intrusive advertisements during rounds,
- forced online connectivity,
- paywalls around basic gameplay,
- unnecessary accounts,
- excessive notifications,
- mechanics designed primarily to generate engagement metrics.

A group sitting around a table should never feel like it is being interrupted by an advertising platform.

---

### 18. Build for the Real World, Not Screenshots

A beautiful screenshot isn't enough.

BiGuess should be tested in actual environments:

- sitting around a table,
- bright sunlight,
- dim rooms,
- different phone sizes,
- multiple players,
- people holding phones at different angles,
- people laughing/talking while playing,
- players who don't know the app,
- poor/no internet.

The question isn't:

> “Does this screen look good?”

It's:

> **“Does this work when five friends are actually playing?”**

That's the standard.

---

# The principles in one sentence

If we eventually need to reduce all of this to a single rule:

> **BiGuess uses technology to remove the friction around a social game, while deliberately leaving the social game itself to the people.**

That, to me, is the **north star**.

And there are two principles I'd put at the very top of the engineering specification:

**1. Real life comes first.**

**2. Simplicity beats technical sophistication.**

Those two principles should protect us from the biggest mistake we could make with BiGuess: turning a wonderfully simple face-to-face game into another app where everyone spends the evening staring at their phones.

---

