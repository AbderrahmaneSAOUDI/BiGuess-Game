# Branch · BiGuess

- **Source URL:** https://chatgpt.com/share/6a93dc36-1d48-83e9-a89f-f55252621326
- **Conversation ID:** `6a93dc36-1d48-83e9-a89f-f55252621326`

---

## Turn 1: User

### 👤 User

lets talk about my project, be honest and tell me whats good what not and what should I improve

  @GitHub check this repo: https://github.com/AbderrahmaneSAOUDI/BiGuess-Game  be honest with me and tell me everything


---

### 🤖 Assistant (Note / Preamble)

I’m going to judge this as both a **product** and a **codebase**—not just whether it “looks impressive.” I’ll compare the repo against your project dossier, then call out the strengths, weak points, hidden risks, and what I’d prioritize next.


---

### 🤖 Assistant (Note / Preamble)

One thing already stands out: the **documentation is ahead of the actual repository state**. For example, your README advertises `v0.25.0`, `pubspec.yaml` is `0.30.5+6`, while the latest commit history includes a `v0.31` commit followed by another `release: v0.30.5`. That kind of version drift makes a project feel less controlled than the underlying code may actually be.


---

### 🤖 Assistant (Note / Preamble)

The second big issue is more product-facing: the UI registers **18 categories, but the repo only contains character-image folders for 6**. So “18 franchises” currently means “6 playable + 12 placeholders,” not 18 playable universes. That’s okay for a roadmap, but the current README wording oversells the shipped content.


---

### 🤖 Assistant

Yes. I went through the actual repository—not only the project description. I inspected the architecture, gameplay state, updater, Android configuration, tests, assets, release tooling, README, releases, and your uploaded technical dossier. 

One limitation before the review: this is a **source/repository audit**. I inspected the tests, but I did not execute `flutter test`, `flutter analyze`, or build the APK locally, so I won't pretend that I've verified the current HEAD builds cleanly.

## Overall verdict

**BiGuess has moved beyond a beginner Flutter project.** There are real signs of engineering maturity: Riverpod, separation of concerns, meaningful tests, automated asset tooling, ABI-specific releases, an OTA pipeline, image optimization, and thoughtful UI components.

But there's a strange imbalance:

> **The engineering surrounding the game is currently more sophisticated than the game itself.**

The release system, update engine, scripts, architecture and documentation are approaching what you'd expect in a serious app, while the actual gameplay loop remains essentially:

**choose category → countdown → reveal random character → play verbally → roll again.**

That isn't necessarily bad. A simple social game can succeed precisely because it's simple. The problem is that parts of your documentation and branding describe something considerably more complete than what is actually implemented.

My current assessment:

| Area | Score | Assessment |
|---|---:|---|
| Core concept | **7.5/10** | Easy to understand, social, offline, naturally replayable |
| UI/code polish | **8/10** | Considerably above a basic Flutter project |
| Gameplay depth | **4.5/10** | Core loop works, but most “game” structure is outside the app |
| Architecture | **7/10** | Good layering, but not as “strict Clean Architecture” as claimed |
| Testing | **6.5/10** | Real useful tests; important production paths remain uncovered |
| Tooling | **9/10** | One of the strongest parts of the repository |
| Release engineering | **5/10** | Ambitious and useful, but there are serious safety/process problems |
| Documentation accuracy | **4/10** | Impressive presentation, too much drift/overstatement |
| Repository hygiene | **5/10** | Transitional files and stale metadata weaken professionalism |
| Production readiness | **3.5/10** | Several blockers before serious public/store distribution |
| Portfolio value | **8.5/10** | Shows much more ability than another CRUD Flutter application |

---

# What I genuinely like

### The concept is understandable in seconds

That's valuable.

You don't need a tutorial about currencies, skill trees, matchmaking, inventory or complicated controls. Two people understand the core premise immediately.

The offline-first approach also fits the nature of the game. You don't need authentication, databases, servers or constant connectivity for the core interaction. That gives you almost-zero infrastructure cost and makes it suitable for gatherings and events.

And the non-repeating mode is a small but smart product decision. The implementation keeps a remaining deck and exhausts it before recycling rather than repeatedly throwing `Random()` at a list. 

### You have built a substantial content base

922 packaged character assets isn't a toy dataset. Your dossier breaks them down across six currently populated franchises, with One Piece alone containing hundreds. 

And the actual repository confirms the six populated content directories. 

That work matters because for this type of game, **content is a large part of the product moat**. Writing a random-character function is easy. Cleaning, naming, compressing, organizing and maintaining hundreds or thousands of usable cards isn't.

### The tooling is unusually strong

This may actually be the most impressive technical aspect of the project.

Your `scripts/` directory isn't fake documentation around three tiny utilities. It contains substantial tooling for asset audits, image optimization, manifest generation, filename normalization, character statistics, building and releasing. The release script alone is tens of kilobytes. 

You've thought about problems that many personal projects ignore:

asset consistency, Unicode filenames, duplicate detection, image compression, ABI builds, version synchronization, OTA deployment, release asset publishing, SHA-256 reporting.

That demonstrates engineering instincts beyond simply “I know Flutter.”

### The refactor is real

You genuinely have `domain`, `data`, `presentation`, `core`, and service separation. It's not just a folder diagram in the README. 

The category layer also uses an interface:

`ICategoryRepository → CategoryRepositoryImpl → use case → Riverpod providers`

which gives you replaceable data sources and makes a future remote/content-pack source much easier.  

### The tests aren't ceremonial

I was pleased by this.

You test the non-repeating algorithm, model transformations, repository behavior, Riverpod state, automatic disposal, themes, dialogs, animations, navigation and version decision logic.    

That's substantially better than the classic Flutter repository containing only the generated counter test.

### Your release artifacts are real

The project actually has GitHub releases with separate `arm64-v8a`, `armeabi-v7a` and `x86_64` APKs. The latest inspected release also has SHA-256 digests associated with its assets. 

So there's a significant difference between this and a portfolio project whose README says “production ready” while the developer has never produced a release build.

---

# Now the uncomfortable parts

## 1. BiGuess isn't yet much of a game *inside the application*

Look at the actual game state:

`isLoading`, countdown, image visibility, current asset, answer, started state, image pools. 

What's absent?

There are no players, scores, rounds won, match state, correct/incorrect guesses, current turn, question count, round history or winner.

And the primary GameScreen reflects exactly that: countdown, mystery box, character display and reroll. 

So most of the game exists as **social rules performed by the humans**, not game logic handled by the software.

That's perfectly valid for a party-game facilitator.

But then call it that internally when making decisions. Don't spend six months designing an MMO architecture around something whose real digital action is selecting a random card.

The next major work should increase **fun**, not infrastructure sophistication.

---

# 2. The “18 franchises” claim is misleading today

Your configuration registers 18 categories. 

But your character assets directory contains only six actual franchise directories. 

And all 18 cards are clickable—the category UI does not distinguish active from unavailable. 

The missing ones simply eventually produce the empty state because the data source returns an empty collection.  

Your README currently presents:

> “18 Curated Anime Franchises”

and then marks twelve as “Active Expansion.” 

That's technically explained later, but visually the headline creates the stronger impression.

I would change the public language to something such as:

**6 playable universes · 922 characters · more packs in development**

That's actually impressive already. There's no need to inflate it.

And in the UI, unavailable packs should be visibly marked **Coming Soon** and not behave like functioning categories.

---

# 3. Your documentation has become unreliable

This is one of the biggest “hidden” problems.

Your README badge says **v0.25.0**. 

`pubspec.yaml` currently says **0.30.5+6**. 

Your project dossier says **0.31.0+7**. 

And there really was a `v0.31` commit that changed the code to `0.31.0+7`, after which the repository went back to a `0.30.5` release state. 

That's not merely cosmetic. Version confusion is dangerous because your application has automatic update logic.

There are other examples.

The README says countdown options include `0, 1, 2, 3, 5`. 

The actual application currently defines:

`[2, 3, 5, 10]`. 

And that's exactly what the current settings UI renders. 

The README says System / Light / Dark. The current settings interface exposes only Light and Dark. 

The technical dossier says settings persist. They don't. They're ordinary in-memory Riverpod notifiers. Restarting the app rebuilds their defaults.  

Your dossier also describes APKs around ~15 MB; the current released split APKs are closer to roughly **25–30 MB**. 

Documentation becomes actively harmful when future-you trusts it instead of the code.

---

# 4. Your release Android app is signed with the DEBUG KEY

This is the most serious technical thing I found.

Your release configuration contains:

`signingConfig = signingConfigs.getByName("debug")`

inside `buildTypes.release`. 

That is not acceptable for a serious production release.

You need a proper release signing strategy—ideally a protected upload key + Play App Signing if you're going to Play Store, or a securely maintained production signing key for direct APK distribution.

And because Android signing identity affects upgrades, this is something I'd fix **before you accumulate a real user base**.

Related: the production application ID is still:

`com.flutter.gdg_guess_game` 

and your Dart package is still:

`gdg_guess_game`. 

Those feel like prototype leftovers from the project's origin.

If BiGuess is becoming an independent product, pick a permanent application ID tied to a namespace you control before store publication. Changing it afterward effectively creates another Android application.

---

# 5. You disabled important release safeguards

Your Android configuration explicitly says:

`abortOnError = false`

and:

`checkReleaseBuilds = false`. 

Meanwhile your release script runs `flutter analyze`, but if analysis fails it prints a warning and continues building. 

Worse, the release path I inspected doesn't gate a release on `flutter test`.

Yet your dossier presents testing as part of the release/pre-flight pipeline. 

This is backward.

The more automation you have, the **less forgiving it should be**.

A one-command release script that happily releases bad code is worse than manually running five commands.

I'd make a release impossible unless analysis, tests, asset audit, manifest verification and version-consistency checks all succeed.

---

# 6. There is no CI visible in the repository

Your dossier describes GitHub workflow automation, but the root repository currently doesn't contain a `.github` directory. 

I also found no PRs or issue activity in the connected repository.

For a project with this much release sophistication, that is a surprising omission.

You don't need enterprise DevOps. A simple GitHub Actions pipeline that runs analysis, tests, manifest verification and perhaps an Android build would already dramatically increase confidence.

Your local Python tooling should complement CI, not replace it.

---

# 7. The OTA system is clever, but it may be overbuilt

I like the implementation as an engineering exercise.

You detect device ABIs, download an APK with rolling speed/ETA, use a temporary file, atomically rename it, launch the Android installer and combine that with Shorebird.  

But this subsystem is disproportionately sophisticated relative to the actual game.

There are also concrete issues.

Your current update decision logic sends any same-major/minor version with `hasNativeChanges == false` into the Shorebird path—even when local and remote versions are already equal. 

That differs from your dossier's stated `localVersion >= remoteVersion → UpdateNone` policy. 

So you're potentially asking Shorebird whether a patch exists unnecessarily on normal launches.

Your APK downloader calculates SHA-256 during release publication, but the application itself does not verify a downloaded APK against an expected manifest checksum before launching installation. 

I'd put hashes in `version.json` and verify the file.

And your manifest uses:

`releases/latest/download/...`

rather than URLs tied explicitly to the expected version tag. 

That's fragile. A bad release/version-manifest sequence could make “latest” point at a binary inconsistent with the manifest.

There's another subtle bug: `version.json` declares a universal fallback `app-release.apk`. 

But the latest GitHub release I inspected contains the three split APKs and no universal `app-release.apk`. 

So your advertised fallback can currently resolve to a nonexistent release asset.

---

# 8. Your current self-updater is a problem for Google Play

Your Android manifest asks for `REQUEST_INSTALL_PACKAGES`. 

Google's current Play policy says an application distributed through Google Play may not update or replace itself using another update mechanism; Google also tightly restricts `REQUEST_INSTALL_PACKAGES` to apps where installing packages is part of the application's core purpose. A character guessing game clearly isn't a package manager.  

That doesn't mean your direct APK updater is useless.

It means you should probably have **distribution flavors**:

Direct/GitHub build → your APK updater can exist.

Google Play build → no `REQUEST_INSTALL_PACKAGES`, no self-APK installer; use Play's own update mechanism.

That's an architectural decision worth making now.

---

# 9. Anime artwork could become your biggest business problem

Technically, the characters are an asset.

Commercially, they may be a liability.

Your repository contains hundreds of anime character images and franchise logos. I cannot determine from the repository that you have licenses/permissions for them, and I found no rights documentation.

Google Play's IP policy requires developers to own or have appropriate rights to copyrighted/trademarked content included in an app/store listing. 

I am **not saying you've infringed anything**. I don't know where every image came from or what permissions you have.

I'm saying that before thinking seriously about monetization, stores, advertising or scaling downloads, you need a clear answer to:

**“What rights do BiGuess have to distribute these images and logos?”**

And there's another related repository issue: your README claims the project is MIT licensed. 

But GitHub reports `license: null`, and there isn't a `LICENSE` entry at repository root. 

Even after adding an MIT license, don't imply that MIT licensing covers third-party anime artwork. Code licensing and content licensing need to be separated.

---

# 10. “Strict Clean Architecture” is an exaggeration

The architecture is good.

The wording isn't accurate.

For example, your supposedly pure `domain` model `developer_info.dart` imports Flutter widgets and contains `Color` and `IconData`. 

A genuinely framework-independent domain layer wouldn't know Flutter exists.

`VersionService` also handles several concerns itself: HTTP access, package information, device ABI detection and update-policy decisions. 

And the update controller directly depends on concrete service classes rather than domain interfaces. 

None of this is terrible.

For BiGuess's size, I'd actually rather have pragmatic architecture than ten abstraction layers.

So I'd simply stop marketing it internally as “strict Clean Architecture.” Call it:

**layered architecture inspired by Clean Architecture**

That's accurate.

---

# 11. You're carrying migration debris

There are old root-level `lib/providers`, `lib/screens`, `lib/utils` and `lib/widgets` paths alongside the newer structure. Some are compatibility shims rather than duplicated implementations. For example, the old providers file mainly re-exports your new controllers. 

Same with the old screen path. 

That's sensible during migration.

But once nothing imports the compatibility paths anymore, remove them.

There's also this particularly suspicious file:

`lib/d_empty_list.dart`

containing:

> `// DON'T REMOVE THIS FILE, THE USER NEEDS IT`

and a completely empty category map. 

That looks like temporary AI/tooling scaffolding that accidentally became production repository material.

Root files such as `chatgpt_readme.md` and `bin.md` add to that sense of “developer workspace” rather than polished public open-source repository. 

---

# 12. The README is hurting the GitHub project

Your repository metadata currently describes the entire project as:

**“GDG Ghardaia”**

with no homepage and no GitHub topics. 

Your package description is:

**“A guess image game with multiple categories.”** 

Neither says why BiGuess is interesting.

The README is visually polished but stale, and words like:

**“The Ultimate…”**

aren't helping you.

The product doesn't need exaggerated adjectives. The underlying concept is good enough.

Something like:

> “An offline face-to-face guessing game for two players, built in Flutter. Pick a universe, reveal a secret character, and identify it through yes/no questions.”

is more confident because it doesn't have to claim superiority.

---

# 13. Your repository is surprisingly large

GitHub reports roughly **175 MB** for the repository. 

Yet the current compressed character footprint in your dossier is dramatically smaller. 

That strongly suggests your Git history is carrying older/uncompressed assets.

It's not urgent enough to blindly rewrite Git history, but I'd inspect your largest historical Git objects.

And more importantly, think ahead.

922 bundled images work.

5,000–20,000 cards across many subjects will turn the binary and repository into a content warehouse.

Eventually, you probably want **downloadable content packs** rather than shipping every category inside every APK.

That would also let someone interested only in Naruto, football and geography avoid downloading everything else.

---

# 14. The “fair non-repeating” system isn't as persistent as the marketing suggests

The algorithm itself works.

But your `gameRoundProvider` is `autoDispose`. When the player leaves the category, that state is destroyed, and reopening the category initializes the full deck again. 

You even test that reset behavior explicitly. 

So:

> “cycles through the entire roster before repeats”

is true **within the current category session**.

It isn't true across app sessions or leaving/reopening that category.

That's probably fine, but documentation should say what actually happens.

---

# 15. Your settings don't persist

This deserves emphasis because users notice it quickly.

Algorithm, countdown and hint settings are simple Riverpod `Notifier`s. 

Theme is the same. 

No SharedPreferences, Hive, SQLite or another persistence layer exists in that path.

If I set light theme + 5-second countdown + hide character names, close the app, and reopen it, I should reasonably expect those preferences to remain.

That's an easy, worthwhile improvement.

---

# 16. Web support deserves another look

Your README advertises Android + Web. 

But your application startup includes the updater, and that update stack directly imports `dart:io` in multiple places.   

That's a major red flag for the claimed web build.

I haven't run `flutter build web`, so I won't state as fact that the current code fails compilation. But I would expect the update infrastructure to need conditional imports/platform-specific implementations before I'd advertise Web as a verified supported platform.

Similarly, your categories grid hardcodes two columns. 

That's not really the “responsive large-screen/tablet/foldable” architecture suggested by parts of the documentation.

---

# 17. There is a product problem hidden inside your enormous rosters

**466 One Piece characters sounds impressive.**

It may also make the game worse.

Suppose two normal One Piece fans play. They know Luffy, Zoro, Nami, Ace, Shanks, Law, Kaido…

Then the game pulls some obscure background character whose appearance they barely remember.

That's no longer deduction. It's:

> “Who the hell is that?”

Large datasets should not automatically mean one giant random pool.

This is where BiGuess could become meaningfully better than a random-image generator:

**Casual / Fan / Expert difficulty.**

Casual could contain ~30–50 famous characters.

Fan could contain 100–150.

Expert could expose everything.

That improves game design considerably without adding complicated technology.

---

# 18. Your two-phone story isn't actually a multiplayer implementation

Some documentation describes two phones.

But the source has no room, local network, Bluetooth, QR pairing, synchronized seeds or shared round state.

Two phones currently means two independent copies of the application coordinated by the humans.

Again: that's okay.

But I would call it **two-device play**, not multiplayer synchronization.

Your own old `chatgpt_readme.md` even describes both players rolling separate mystery characters and tracking scores manually. 

That's different from some of the newer documentation where one player acts as the answerer who sees the mystery card.

You need to decide what the **canonical BiGuess rules** actually are.

This is surprisingly important.

---

# What I would do next

Not another architecture refactor.

Not another animation system.

Not another deployment feature.

I would work in this order:

1. **Fix production blockers first.** Replace debug release signing, choose the final Android application ID, restore release lint checks, make `flutter analyze` fatal, run `flutter test` before releasing, add CI, fix the universal-APK URL, and get versioning back to one authoritative source.  
2. **Make documentation 100% truthful.** Say 6 playable categories/922 characters, correct countdown options, correct version, actual platforms, actual settings behavior, and separate shipped features from roadmap ideas.
3. **Resolve content/IP strategy before commercialization.** Document where assets come from, what rights apply, separate source-code licensing from content licensing, and decide whether long-term BiGuess can depend on copyrighted franchise imagery. 
4. **Improve the actual game.** Add player names, an optional scoreboard, round tracking, “correct / pass” actions, match target such as first-to-5, and a results screen. Keep the verbal interaction; don't turn it into a digital questionnaire.
5. **Add difficulty/roster presets.** Famous / Standard / Hardcore would improve playability much more than adding another 500 random characters.
6. **Clean category availability.** Active packs should be playable; upcoming packs should visibly say Coming Soon or be hidden.
7. **Persist preferences.** Theme, countdown, hint mode, difficulty, algorithm and perhaps last-used categories should survive restart.
8. **Prepare for non-anime content structurally.** Stop treating a category fundamentally as an “anime franchise.” Define generic `Topic → Pack → Card` metadata so the engine doesn't care whether a card represents a character, football player, country, food, film, historical person or something else.
9. **Move content toward packs.** Don't let the APK eventually contain every image BiGuess ever supports. Design optional downloadable/offline packs with metadata, versions and checksums.
10. **Only then consider real device synchronization.** A simple local-room/QR mode could eventually make two-phone BiGuess genuinely special, but I wouldn't build it before validating that people repeatedly enjoy the core game.

---

# The strategic thing I'd change

Right now I see two possible futures.

One is:

> **“Anime guessing game with hundreds of images.”**

That's fun but easy to copy, legally complicated, and limited.

The more interesting future is:

> **“A reusable social deduction/guessing platform built around content packs.”**

Anime becomes the first pack family rather than the identity of the engine.

Then BiGuess can support Character Guess, Football Guess, Country Guess, Cinema Guess, History Guess, Science Guess, Food Guess, etc., while preserving the same social mechanism.

At that point your existing separation between game logic and asset repositories becomes genuinely valuable.

But don't build fifty empty category buttons now.

Get **one complete experience** excellent first.

---

# One final observation

The project gives me a very specific impression:

**You enjoy engineering systems, and that strength is starting to pull you away from product development.**

The 38 KB release automation, Shorebird integration, ABI handling, update state machine, Clean Architecture refactor, asset auditing and generated manifests are much more sophisticated than required to display a random character.

That capability is good.

But the next jump in quality won't come from making the technical system more clever.

It comes from answering questions such as:

**What makes round 20 more fun than round 1? Why would friends open BiGuess again next weekend? Which characters are frustrating? How is a winner determined? How do beginners and hardcore fans play together? What makes BiGuess better than putting character names into a random-wheel website?**

Solve those and the project becomes a **product**.

Right now I would describe BiGuess as:

> **A surprisingly well-engineered and polished MVP with a strong foundation, but an underdeveloped game layer, inconsistent release discipline, and several serious production/distribution risks.**

I would absolutely keep working on it. But I would stop adding infrastructure for a while and make the **game itself catch up with the engineering.**


---

## Turn 2: User

### 👤 User

1. the game based on reality, like 2 or more players sit faced each other and all open the game and get random image and start questioning in reality and laugh on each other in reality, Its hard to control this , my goal is the real life enjoy, the game is just a tool to speedup randomizing instead of printing images and carrying them.

The score is hard to implement in perfect like what if two players click win, both will get +1 and this is a mistake, even if its realtime with firebase, still the same problem, Difficulty and rounds are logical to implement but something else no, like number of questions and timers can't measure and will kill the real life  fun. a hard image can take up to 30 questions and easy with 2 or 3 only.
also even if I thought to make it online using Firestore, I want to stay in free tier even if I upload it to Play Store, so anything taking lot of reads I will avoid for now, the game will not return money in the beginning so I will not invest on it, later on, its earning will become an investement.
tell me if I am right or not, be honest with me, hiding facts will not help the game to grow.
The offline, face-to-face nature is also an actual differentiator. Most mobile games try to keep people staring at their phones; my concept can make the phone a **tool for a real-world interaction**.

2. True that I started with Anime but the game will extend to other topics like films, anime, football, countries, food, scholar things, and many more. 

I know that I promised on 18 cards but only 6 has content, cuz I want to focus on project development and let images for someone else as data collector, like update the game so it has like a small dashboard to CRUD categories, sub-categories and content.


---

### 🤖 Assistant (Note / Preamble)

Your core product logic is much stronger than the version I inferred from the repo alone. The important distinction is this: **BiGuess is not trying to digitize the social game; it is trying to remove the annoying physical setup around the social game.** That changes what “missing features” actually mean.


---

### 🤖 Assistant (Note / Preamble)

Where I would change my earlier critique is this: **not having authoritative scores, turn counters, question counters, or synchronized rooms is not automatically a missing feature anymore.** In your intended product, some of those would actually be *anti-features* because they force the phone back into the center of an interaction that is supposed to happen between people.


---

### 🤖 Assistant

You are **mostly right**, and your clarification changes my assessment of BiGuess in an important way.

The key sentence is this:

> **The game is not trying to simulate the real-world interaction. It is replacing the printed cards.**

That is a much better product definition than “multiplayer guessing game.”

## 1. Keep the real game outside the phone

I agree with you here.

Imagine four friends sitting around a table. Each opens BiGuess, gets a character, puts the phone where the others can see it, and then the actual game begins:

“Am I a villain?”  
“No.”  
“Am I from the Leaf Village?”  
“Yes.”  
“Do I have Sharingan?”  
Everyone starts laughing because the answer is obvious except to the player.

**That interaction is the product.**

BiGuess's job is simply to make this process convenient:

**Open → choose content → randomize → reveal → get out of the way.**

If you start forcing players to tap after every question, confirm turns, press timers, register answers and constantly interact with the screen, you damage the thing that makes BiGuess interesting.

So I would revise something I said earlier:

### Don't add question tracking.

I previously mentioned number of questions. After your clarification, I don't recommend it for the normal game.

You're right about why.

An obscure character might legitimately take 25 questions. Naruto might take 3.

“Fewer questions = better” is not necessarily the goal.

And once players must do:

ask → answer → tap button → next player → tap button

you've transformed a natural conversation into administration.

Bad trade.

---

# 2. You're also right about timers

I would **not make a timer part of normal BiGuess gameplay**.

A conversation might naturally go:

“Are you human?”

“Yes.”

“Are you a pirate?”

Everyone starts arguing whether the character technically counts as a pirate.

Someone remembers a funny scene.

Thirty seconds disappear.

That is not wasted gameplay.

**That is the gameplay.**

A strict timer would often punish exactly the social interaction you're trying to create.

However, there's a distinction:

### Timer = bad as a rule, potentially good as an optional mode.

Later you could have:

- Normal — no pressure
- Speed Mode — e.g. 60/90 seconds
- Party Mode
- Hardcore

But the default should stay free-form.

Same principle for everything else:

> **Optional structure can add variety. Mandatory structure shouldn't interfere with conversation.**

---

# 3. Your scoreboard concern is absolutely legitimate

There's a deeper problem than Firebase here.

Suppose Player A presses **Won**.

Player B also presses **Won**.

Firestore can perfectly synchronize:

```text
A score: +1
B score: +1
```

Technically flawless.

Semantically wrong.

Because Firebase knows what buttons were pressed.

It **doesn't know what happened around the table**.

That's the distinction.

To solve it authoritatively you'd need something like:

Player A claims win → Player B confirms → server updates score.

Now you've added:

claim → notification → confirmation → synchronization

to something everyone sitting at the same table already knows.

That is ridiculous friction for your use case.

So no, I wouldn't build real-time authoritative scoring now.

### A simple optional scorekeeper is different

Eventually, if players ask for it, you could have a completely dumb scoreboard:

```text
Ahmed       3   [-] [+]
Sara        2   [-] [+]
Yacine      4   [-] [+]
```

No validation.

No Firebase.

No pretending BiGuess knows who actually won.

It's basically a digital piece of paper.

And even that should probably be secondary.

Your instinct here is good:

> **Don't solve social truth with database synchronization.**

---

# 4. Offline isn't just a technical convenience

This point you made is important enough that I'd make it central to the product positioning.

Most games say:

> Look at the screen.

BiGuess says:

> Look at each other.

That's meaningful.

I wouldn't market it as:

**“An offline game because we don't need a server.”**

I'd market the philosophy:

> **Your phone picks the mystery. Your friends make the game.**

Or conceptually:

> **BiGuess uses the phone to start the fun, not replace it.**

The device is the facilitator.

That's actually much more interesting than another online quiz app.

---

# 5. So should you build Firebase multiplayer?

At this stage:

## No.

Not because Firebase is bad.

Because **it doesn't solve an important problem for your core product**.

And it would add:

authentication, room creation, disconnect handling, stale rooms, listeners, security rules, reconnect states, version mismatches, synchronization logic, latency edge cases, database schemas and ongoing cloud dependency.

For what?

Players who are already **physically sitting beside each other**.

Your current offline system has a remarkable architecture:

```text
0 accounts
0 matchmaking
0 server
0 room failures
0 latency
0 database dependency
0 cloud gameplay cost
```

That's excellent.

Don't throw it away because “multiplayer apps normally use Firebase.”

---

# 6. Your concern about Firestore costs is also rational

Current Standard Firestore free quota is **50,000 document reads/day, 20,000 writes/day, 20,000 deletes/day, 1 GiB storage and 10 GiB/month outbound transfer**. Real-time listener updates count as document reads. 

For a small launch, you could probably stay comfortably within that.

But that's almost beside the point.

Your thinking should not be:

> “Can I squeeze real-time multiplayer into 50k reads?”

It should be:

> “Why am I spending even 500 reads on something BiGuess doesn't need?”

That's the stronger engineering decision.

Use infrastructure where it creates value.

---

# 7. Where I would potentially use Firebase later

Not for the core round.

I'd consider it much later for things like:

**Remote catalog metadata**, update announcements, pack availability, anonymous usage statistics, community submissions, favorites sync, optional accounts, or remotely downloadable packs.

Those things can add value without controlling the real-world interaction.

And even there, start carefully.

For your **content dashboard**, Firebase may actually not be the best first choice either.

---

# 8. Your dashboard idea is much more important than online multiplayer

This part of your message interests me more:

> “I want to focus on project development and let images for someone else as data collector, like update the game so it has like a small dashboard to CRUD categories, sub-categories and content.”

**Yes.**

That solves an actual scaling bottleneck.

Right now the hidden problem of BiGuess isn't:

> “How will 4 phones synchronize scores?”

It's:

> **“How do we efficiently turn 922 cards into 5,000+ quality cards without the developer manually touching every file?”**

That's where tooling creates enormous leverage.

And you already have the beginnings of this philosophy with your Python asset scripts, manifest generator, optimizer, audit system and statistics tools. 

I would extend that.

---

# 9. But I wouldn't make that dashboard part of the player's app

I'd create something conceptually separate:

# BiGuess Content Studio

Used only by you/data collectors.

Think:

```text
BiGuess
    Player application

BiGuess Content Studio
    Internal content-management application
```

The collector sees something like:

```text
Topics
├── Anime
│   ├── Naruto
│   ├── One Piece
│   └── Attack on Titan
│
├── Football
│   ├── Players
│   ├── Clubs
│   └── Legends
│
├── Geography
│   ├── Countries
│   ├── Flags
│   └── Landmarks
```

Then:

**Add card**

```text
Name:
Lionel Messi

Image:
[messi.webp]

Pack:
Football Players

Difficulty:
Easy / Medium / Hard

Tags:
Argentina
Barcelona
PSG
Inter Miami

Status:
Draft / Ready
```

Press save.

The tool handles the ugly work.

---

# 10. The dashboard should automate your data collector's job

I wouldn't stop at basic CRUD.

Make it do the things that currently require technical knowledge:

- drag-and-drop image import
- WebP conversion/compression
- file renaming
- duplicate detection
- broken-image validation
- character-name normalization
- missing-image detection
- preview the exact in-game card
- category/pack assignment
- difficulty tagging
- image dimensions/size warnings
- card counts
- regenerate manifests
- export the content pack

Then your collector doesn't need to understand:

```text
assets_manifest.dart
pubspec.yaml
folder naming
Python scripts
Flutter
Git
```

They just manage content.

**That's excellent separation of responsibility.**

---

# 11. I wouldn't put the dashboard data in Firebase first

You can build the dashboard **without any backend at all**.

This is probably what I'd do initially.

The dashboard edits something such as:

```text
/content
    /anime
        /naruto
            pack.json
            /images
        /one_piece
            pack.json
            /images
```

For example:

```json
{
  "id": "naruto",
  "title": "Naruto",
  "topic": "anime",
  "status": "published",
  "cards": [
    {
      "id": "naruto_uzumaki",
      "name": "Naruto Uzumaki",
      "image": "naruto_uzumaki.webp",
      "difficulty": "easy"
    }
  ]
}
```

Then your existing scripts turn that content into the optimized packaged game data.

No server.

No Firestore.

No monthly bill.

No production database.

No Internet requirement.

And the data collector can work on a cloned repository or a synchronized content folder.

---

# 12. Be careful if you intend Firebase Storage for images

There's an important current Firebase detail you should know.

As of 2026, using **Cloud Storage for Firebase requires the project to be on the Blaze/pay-as-you-go plan**, although no-cost usage allowances still exist. Spark-only projects can't use the Firebase Storage buckets. 

So if your requirement is literally:

> **“I don't want a billing account attached at all.”**

then I would **not base your image CMS on Firebase Storage**.

That's another reason a Git/content-pipeline solution is attractive during the early phase.

---

# 13. Your expansion beyond anime makes sense

And it actually makes me more optimistic about the concept.

Anime alone creates a niche app.

This:

```text
Anime
Movies
Football
Countries
Food
History
Science
Cartoons
Games
Celebrities
Animals
Brands
Cars
...
```

creates a **game engine**.

That's substantially stronger.

But there's one architectural decision I'd make now:

## Stop treating “category” as synonymous with “anime franchise.”

Your code currently has things like:

```dart
GameCategory(
    name: 'Naruto',
    path: 'assets/images/naruto',
)
```

and the application's tagline is still explicitly anime-oriented. 

I'd move the conceptual model toward:

```text
Topic
    ↓
Pack
    ↓
Card
```

rather than:

```text
Category = franchise
```

---

# 14. Why `Topic → Pack → Card` is better

Example:

### Anime

```text
Anime
 ├── Naruto
 ├── One Piece
 └── Dragon Ball
```

### Football

```text
Football
 ├── Famous Players
 ├── World Cup Legends
 ├── Clubs
 └── Managers
```

### Geography

```text
Geography
 ├── Country Flags
 ├── Maps
 ├── Landmarks
 └── Capitals
```

### Movies

```text
Movies
 ├── Marvel Characters
 ├── Harry Potter
 ├── Movie Actors
 └── Famous Movies
```

And the game engine doesn't care.

It receives:

```text
Card:
    image
    answer
    difficulty
    pack
```

That's it.

BiGuess becomes generic.

---

# 15. Difficulty becomes much more valuable with your philosophy

Here I strongly agree with your earlier thought.

Not because difficulty should change the rules.

It should change the **random pool**.

Example One Piece:

### Casual

```text
Luffy
Zoro
Nami
Sanji
Ace
Shanks
Law
Kaido
...
```

Maybe 40 characters.

### Fan

Maybe 150.

### Expert

All 466.

Then two normal fans can enjoy One Piece without constantly getting:

> “Who even is this?”

That preserves real-world gameplay without asking the phone to control anything.

It's exactly the type of feature BiGuess should have:

> **The software improves the setup; humans retain the game.**

---

# 16. Rounds can work the same way

You mentioned rounds are logical.

Yes, although I'd keep them lightweight.

For example before playing:

```text
Quick Play
──────────

Difficulty
[Casual] [Fan] [Expert]

Characters
[10] [20] [All]

Avoid repeats
[✓]
```

But I wouldn't require a formal “Round 1 / Round 2 / Round 3” lifecycle unless users want that.

Another possibility:

```text
Session
12 / 40 cards seen
```

That's informational rather than controlling.

---

# 17. I now disagree with one part of my previous recommendation

I said:

> “Add player names, scoreboard, correct/pass actions, match target and results screen.”

With your clarified goal, I would now split that apart.

### I still like:

- difficulty
- content packs
- favorites
- exclude/choose packs
- session non-repeat behavior
- maybe lightweight optional score sheet
- “next/random”
- content quality controls

### I would NOT prioritize:

- accounts
- multiplayer rooms
- automatic score validation
- synchronized turns
- question tracking
- mandatory round timers
- server-authoritative winners
- answer buttons for every question
- complicated results flows

Those aren't missing features.

Some would actually **damage your design philosophy**.

---

# 18. But there is one danger in your argument

Don't use:

> “It's a real-life game.”

as an excuse to never improve the digital experience.

BiGuess still has to provide enough value that people don't say:

> “Why don't I just use Google Images + a random number?”

The application's value needs to come from exceptional preparation:

**curated content, beautiful cards, instant setup, fair randomization, no repetitions, difficulty control, huge topic variety, smooth UX and zero friction.**

That's where you have to beat printed cards and random websites.

The phone doesn't need to control the game.

But it needs to be the **best possible deck of cards**.

That's your standard.

---

# 19. About the six vs eighteen categories

Your explanation is completely reasonable **as a development strategy**.

Developer:

> develops engine + tools.

Data collector:

> populates content.

Good division.

What I criticized was only the **user-facing claim**.

Internally:

```text
18 planned
6 populated
12 waiting for collector
```

No problem.

Publicly:

> “18 available universes”

when only six actually contain cards is the problem.

I'd simply make the UI honest:

```text
Anime

✓ Naruto
✓ One Piece
✓ Attack on Titan
✓ Black Clover
✓ Demon Slayer
✓ Hunter × Hunter

🔒 Bleach                Coming Soon
🔒 Dragon Ball           Coming Soon
🔒 Jujutsu Kaisen        Coming Soon
...
```

Then having 18 cards is actually useful.

Users understand the roadmap.

---

# 20. The dashboard could eventually solve that automatically

Each pack could have:

```text
status:
  draft
  collecting
  ready
  published
```

Then the application doesn't manually decide.

Your data might say:

```json
{
  "name": "Bleach",
  "status": "collecting",
  "cardCount": 17
}
```

UI:

**Bleach — Coming Soon**

Later collector reaches your threshold and you mark:

```json
"status": "published"
```

Now it's playable.

Clean.

---

# Where I think BiGuess should go

My product architecture would now be:

```text
                   BIGUESS
                      │
        ┌─────────────┴─────────────┐
        │                           │
     GAME APP                CONTENT STUDIO
        │                           │
   for players                for your team
        │                           │
  intentionally simple       intentionally powerful
        │                           │
  Topic → Pack → Random      CRUD topics
  Difficulty                CRUD packs
  Reveal                    CRUD cards
  Next                      Optimize images
  Settings                  Validate data
        │                    Generate content
        │                           │
        └──────────── packaged content ────────┘
```

No Firebase required.

No server required.

No accounts required.

And later:

```text
                Optional Cloud Layer
                       │
        ┌──────────────┼───────────────┐
        ↓              ↓               ↓
   pack updates    submissions      analytics
```

**without changing the core offline game.**

---

# My updated rating of the concept

Given your explanation, I'd change the product-side assessment.

I previously gave gameplay depth around **4.5/10** because I was judging the application as if it were supposed to contain the game.

That's the wrong frame.

I would now separate these:

| Area | Assessment |
|---|---:|
| Real-world game concept | **8/10** |
| Phone-as-facilitator philosophy | **9/10** |
| Current digital facilitator | **7/10** |
| Content scalability today | **5/10** |
| Content scalability after Studio/CMS | **potentially 9/10** |
| Need for online multiplayer now | **2/10** |
| Need for Firebase gameplay now | **1/10** |
| Difficulty system value | **9/10** |
| Automatic scoreboard value | **3/10** |
| Question/timer tracking value | **2/10 default, 6/10 optional modes** |

So yes: **your reasoning is sound.**

The part I'd push you hardest on is not to add more and more Flutter architecture now. Your next important engineering challenge should be:

> **Make adding 1,000 new cards dramatically easier than adding the first 1,000.**

If you accomplish that while keeping the player application extremely simple, BiGuess can grow from an anime app into a broad **offline social-game platform without turning into a cloud-dependent multiplayer app**.

And that direction fits your concept much better than Firebase rooms ever would.


---

## Turn 3: User

### 👤 User

let start over, save your memories about all what discussed in this chat and let start over like we are preparing for new project, start with the big idea to the goals of the project to the tech stack needed to help needed to everything and then in the end update the existing app to follow our vision and plan in place of keeping updating something is not clear yet.

as always be fully honest with me and don't hide anything from me even if it hurts.

what do you think?


---

### 🤖 Assistant

Yes — I think restarting the **planning**, not the codebase, is exactly the right move.

And there is one important limitation first: because this project has memory disabled, I can’t permanently save new memories outside this project/conversation. But I can use everything we’ve discussed here as working context while we build the new vision. So we should turn the important decisions into an actual project document later instead of relying on chat memory.

What I would change from how we approached BiGuess before is this:

> **We stop asking “what feature should we add next?” and start asking “what exactly is BiGuess supposed to become?”**

The existing Flutter app should no longer dictate the product. It becomes an implementation we will eventually **adapt to the product specification**.

## The reset I recommend

We should design BiGuess again as if there were no code yet, while keeping everything we learned from the existing implementation.

We go in this order:

1. **The big idea**
   - What problem does BiGuess solve?
   - Why should it exist?
   - What makes it different?
   - What is explicitly *not* part of the product?

2. **Product philosophy**
   - Phone as facilitator, not the center of gameplay.
   - Real-world interaction comes first.
   - Offline-first.
   - Minimal interruption during play.
   - No technology merely because it sounds impressive.

3. **Target users and situations**
   - Friends
   - Families
   - Students
   - Events
   - Communities
   - Casual players vs enthusiasts
   - Two players vs groups

4. **The actual game system**
   - How a session starts.
   - What players choose.
   - Topics / packs / cards.
   - Randomization.
   - Difficulty.
   - Repetition rules.
   - Optional modes.
   - What happens physically between players.
   - What the application deliberately refuses to control.

5. **Content architecture**
   - Anime
   - Movies
   - Football
   - Countries
   - Food
   - scholars / educational subjects
   - future topics we haven't imagined yet
   - `Topic → Pack → Card`
   - difficulty, tags, metadata, availability, language, source/rights, etc.

6. **BiGuess Content Studio**
   - Internal tool for your team/data collectors.
   - CRUD topics, packs and cards.
   - Image processing.
   - Validation.
   - Duplicate checking.
   - Metadata.
   - publishing states.
   - pack generation.
   - eventually remote publishing if appropriate.

7. **Technical architecture**
   Only after the product model is clear:
   - Flutter app architecture
   - local database or generated assets
   - content package format
   - state management
   - offline storage
   - update mechanisms
   - backend only where genuinely useful
   - admin/content tools
   - CI/CD
   - testing

8. **Cost strategy**
   - What must remain free.
   - What can use free tiers.
   - What shouldn't require a backend at all.
   - When cloud infrastructure becomes justified.
   - How costs scale with users/content.

9. **Legal and content strategy**
   This one cannot be ignored.
   - copyrighted characters
   - franchise logos
   - football/player photography
   - movie artwork
   - licensing
   - attribution where applicable
   - user-generated/community content later
   - Play Store policy

10. **Business model**
    Not necessarily monetization immediately.
    We define possible futures:
    - completely free
    - ads
    - premium packs
    - one-time Pro
    - sponsored packs/events
    - community-created packs
    - institutional/educational use

    Then we make sure today's architecture doesn't destroy tomorrow's possibilities.

11. **MVP definition**
    We decide what BiGuess **1.0 actually needs**.

    Not everything we can build.

    Only what proves the concept.

12. **Roadmap**
    For example:
    - Foundation
    - Content system
    - MVP
    - Closed testing
    - Play Store
    - additional topics
    - Content Studio maturity
    - optional cloud services
    - monetization if there is real usage

13. **Only then do we reopen the existing repository.**

    At that point we compare:

    **Vision → Required architecture → Existing implementation**

    And every current component gets one of four decisions:

    **Keep / Refactor / Replace / Delete.**

That last part is important.

I don't want us to say:

> “We've already written this service, so let's somehow make it fit.”

That's sunk-cost thinking.

If something in the current application doesn't belong in the new product, we remove it.

If something is already excellent, we keep it.

---

# There is also something I think you did wrong before

Since you asked me not to hide uncomfortable conclusions:

You began engineering the product **before the product itself was completely defined**.

That's why BiGuess currently has some unusually advanced infrastructure for its stage — OTA mechanisms, release automation, architecture layers, asset scripts, etc. — while basic questions like the exact long-term content model and product identity were still evolving.

That's not catastrophic.

In fact, a lot of that work is reusable.

But it is a warning.

You enjoy building systems, and because you're capable of building them, there is a danger that BiGuess becomes **technically sophisticated faster than it becomes useful or fun**.

We need to prevent that this time.

For every proposed feature, we should ask:

> **What real user problem does this solve?**

If the answer is weak, we don't build it.

Firebase because “multiplayer usually needs Firebase”? No.

Accounts because “apps normally have accounts”? No.

AI because “AI is popular”? No.

A backend because “proper apps have backends”? No.

If a static JSON file does the job better, we use JSON.

If local storage solves it, we keep it local.

If humans sitting around the table can handle something better than software, **we let humans handle it**.

That simplicity could become one of BiGuess's biggest strengths.

---

# I also don't want us to throw away the existing app

Starting over conceptually does **not** mean rewriting Flutter from zero.

That would probably be wasteful.

There are already useful assets:

your Flutter UI, Riverpod experience, category/card logic, asset tooling, image optimization, release scripts, tests, update research and almost 1,000 pieces of initial content.

We'll treat all of that as raw material.

But none of it gets immunity.

The **new specification becomes the authority**.

Not the current code.

---

# The first document we should create

Before touching a single Flutter file, I want us to eventually have something like:

**BIGUESS_PRODUCT_BLUEPRINT.md**

Containing:

> **Vision**  
> Why BiGuess exists.
>
> **Product Principles**  
> Rules we will not compromise.
>
> **User Experience**  
> What happens from opening the app to putting the phone down.
>
> **Game Model**  
> Topic → Pack → Card.
>
> **Content System**  
> How thousands of cards are created and maintained.
>
> **Technical Architecture**  
> Only the technology justified by those requirements.
>
> **Content Studio**  
> How non-developers contribute.
>
> **Distribution & Updates**
>
> **Costs**
>
> **Legal/IP**
>
> **Business Possibilities**
>
> **MVP**
>
> **Future Vision**
>
> **Migration Plan From Current BiGuess**

That document would become much more valuable than continuing to accumulate code without a stable north star.

---

And one more thing: during this process I don't want to act as someone whose role is to approve your ideas.

If I think an idea is weak, I'll tell you.

If you're solving a problem that doesn't exist, I'll tell you.

If an architecture is overengineered, I'll tell you.

If something has serious Play Store, copyright, financial, scalability or UX implications, we'll deal with it instead of hiding it behind enthusiasm.

And if something you propose is genuinely better than my suggestion—as happened with your explanation of why authoritative scoring doesn't fit the real-world nature of BiGuess—I'll change my position rather than defend the previous answer.

So yes.

**I think we should reset the product design completely, establish the vision first, design the product/content/business/technical systems around that vision, and only then transform the current BiGuess codebase into that product.**

The first thing we should define is **BiGuess's Big Idea** — not features, not Flutter, not Firebase, not databases. The one-paragraph definition of what BiGuess is, why it exists, and why someone should choose it over printed cards, a website, or another party game.


---

## Turn 4: User

### 👤 User

The file is now ready, let me introduce you the game:

- **BiGuess** is an offline party game played face-to-face where everyone sits together, picks a topic, and starts a round on their own phone. Each player turns their screen outward toward the group so everyone else can see their secret character except themselves. Players then take turns asking the group quick **Yes or No** questions about their own hidden image, racing to be the first to deduce who they are through pure real-life conversation and laughter.


---

### 🤖 Assistant

This is the right place to begin. The blueprint is currently an empty structure, so we can build it from first principles instead of forcing the existing app into it. 

Your description also reveals the most important thing about BiGuess:

> **The phone does not contain the game. The people do.**

The app's role is to privately assign each player something they cannot see, show it to everyone else, and then largely disappear while the real interaction happens face-to-face.

I would make one small but important correction before we turn your description into the official definition: don't use **“character”** as the fundamental object. That works for anime and movies, but later you want football players, countries, foods, scholars, and other subjects. The product language needs to survive all of those.

I would use **identity** or **card** at the product level.

So our working definition becomes:

> **BiGuess is an offline, face-to-face party guessing game where two or more players sit together, choose a topic, and each receive a hidden identity on their own phone. Players turn their screens outward so everyone except the phone's owner can see the identity. Taking turns, each player asks the group Yes-or-No questions and uses the answers to figure out who—or what—they are. The phones handle the setup and randomization; the actual game happens through real conversation, deduction, reactions, and laughter.**

I think this is substantially stronger than calling it simply an “offline guessing game.”

## The Big Idea

Before filling the rest of the blueprint, I would formally define BiGuess around this concept:

**BiGuess turns smartphones into reusable mystery cards for real-world social play.**

Traditionally, this kind of game needs printed cards, prepared lists, physical headbands/cards, someone assigning identities, or improvised pieces of paper.

BiGuess removes that preparation:

**Choose → Randomize → Show others → Play in real life.**

And then the app intentionally gets out of the way.

That last part is crucial.

We are **not** building a digital party game where everyone spends the session tapping buttons.

We are building a **digital facilitator for a physical social game**.

That distinction should influence almost every future product decision.

---

## Why BiGuess exists

I'd write the first section of the blueprint approximately like this:

### Vision

**BiGuess exists to make spontaneous face-to-face guessing games effortless.**

People should be able to sit together, open their phones, choose something they all enjoy, and begin playing within seconds—without preparing cards, printing images, assigning characters manually, creating accounts, joining online rooms, or depending on an internet connection.

BiGuess uses technology only for the parts technology improves: choosing content, assigning hidden identities, randomizing cards, avoiding unwanted repetitions, organizing large collections, and making new topics instantly accessible.

The conversation itself remains human.

Players look at each other, ask questions, argue about answers, make bad guesses, recognize inside jokes, help or mislead one another according to their own house rules, and enjoy the reactions happening around the table.

**BiGuess should reduce the friction required to start real-world fun without replacing that fun with screen interaction.**

---

That gives us a very important design test.

From now on, whenever we consider a feature, we can ask:

> **Does this help people start or enjoy the face-to-face interaction, or does it unnecessarily pull their attention back toward the phone?**

If it's the second, the feature needs a very strong justification.

For example:

**Good fit**
- topic selection
- packs
- randomization
- difficulty
- avoiding repeats
- content filters
- quick reroll
- readable cards
- offline content
- optional session configuration

**Potentially bad fit**
- requiring players to record every question
- forcing players to confirm every turn
- mandatory countdowns during questioning
- real-time server synchronization for actions everyone can already see
- constantly updating score screens
- chat
- online matchmaking in the core experience

Not because those technologies are inherently bad.

Because they may be bad **for BiGuess**.

---

There is one other product question hidden inside your description that we should settle early.

You wrote:

> “racing to be the first to deduce who they are”

That implies a competitive shared round where **everyone has an identity simultaneously**, everyone asks questions in turns, and the first person to correctly identify theirs wins.

That's a clear and good game model.

I think we should make that the **canonical BiGuess mode**, rather than keeping the previous ambiguity where one person might be the guesser and another the answerer.

So the core round would conceptually be:

**2+ players → everybody receives one hidden identity → everybody exposes their screen → players ask one Yes/No question per turn → anybody may attempt a guess according to the agreed rules → first correct identification wins the round.**

We don't necessarily need the app to enforce any of those rules.

But **we need the product specification to know what game it is supporting.**

And one final refinement: because BiGuess will extend far beyond people/characters, the natural question eventually won't always be:

> “Who am I?”

For countries, foods, animals, objects, etc., it becomes:

> **“Who or what am I?”**

That sounds like a tiny wording detail now, but these are exactly the assumptions worth fixing before they get buried throughout the UI, data model and source code.

So I would consider our first foundational decision established:

> **BiGuess is an offline-first, face-to-face social guessing platform where smartphones replace the preparation and physical mystery cards—not the human interaction. Two or more players each receive a hidden identity, expose it to everyone else, and deduce their own identity through turn-based Yes-or-No conversation.**

From here, the next blueprint section should be **Product Principles — the rules BiGuess will refuse to compromise even as it grows.**


---

## Turn 5: User

### 👤 User

Product Principles


---

### 🤖 Assistant

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

## Turn 6: User

### 👤 User

3. I don't know if I am correct or not but I guess storing images and categories and packs online in Firestore or CloudFlare is better so we let the app content grow by the community with separated app to control content and accept/refuse community uploads.

One thing we can do is adding download to cache option for categories and packs, so the plays downloads once and play offline forever.
This way the app stay under 10Mb with unlimited content. and save offline promise with online update and optimization.

12. Optional Rules, Not Forced Rules: I agree with some only:

- Timer
- Number of rounds
- Difficulty
- Randomize all the Category (or chosen categories)

others are not good, you can't measure them.

14. explain this more and easier.

17) How to earn money then? or it will be freemium?


---

### 🤖 Assistant

Yes. I think your new idea is **better than bundling all content inside the APK**, but I would change one part of the proposal:

> **Don't put everything in Firestore.**

Separate **metadata** from **images/content files**.

Your idea is essentially moving BiGuess from:

**“An app containing a collection of cards”**

to:

**“A small game engine with an expandable content platform.”**

That is a much stronger long-term architecture.

---

# 1. Online content + offline packs

I strongly like this direction.

The architecture becomes:

```text
                         BiGuess
                            │
                ┌───────────┴───────────┐
                │                       │
          Game Engine              Content Platform
                │                       │
                │               ┌───────┴────────┐
                │               │                │
                │            Metadata          Images
                │               │                │
                │          Firestore/DB      Object Storage
                │                             
                └───────────────┬───────────────┘
                                │
                         Download Pack
                                ↓
                         Local Device
                                │
                         Play completely
                            OFFLINE
```

So the APK contains the **engine**, not the entire universe.

That is exactly what you want if the eventual library becomes huge.

Your current 922-character dataset is already useful for development, but imagine:

- 100 topics
- 500 packs
- 100,000 cards
- thousands of images

You absolutely don't want all of that inside the APK.

---

# 2. Your “download once, play forever” idea is excellent

I would make this an explicit product principle.

A player sees:

> **Naruto**
>
> 450 cards  
> 28 MB  
>
> **Download**

After downloading:

> ✓ Available Offline

Then they can go somewhere with **zero internet** and play.

Later, when they reconnect:

> Naruto Pack  
> **Update available — 4.2 MB**

They update it.

This gives us a really nice combination:

### Small base application

Potentially under 10 MB if the engine/assets are kept lean.

### Unlimited expandable content

Theoretical library isn't constrained by the APK.

### Offline gameplay

Downloaded packs remain available.

### Online freshness

Content can improve without releasing a new app version.

### Lower bandwidth

Updates can be incremental rather than forcing the user to download everything again.

That's a very good architecture for BiGuess.

---

# 3. But don't promise “offline forever” literally

I'd phrase the principle as:

> **Downloaded content remains playable offline until the player removes it.**

Because “forever” creates unnecessary expectations around future format compatibility, corrupted storage, OS changes, etc.

But from the player's perspective:

**Download once → no internet required to play that pack.**

That's exactly the experience we want.

---

# 4. Firestore vs Cloudflare

This is where I want to be careful.

### Firestore

Good for:

- pack metadata
- categories
- versions
- publishing status
- card metadata
- moderation state
- community submissions
- user-related metadata later

Not ideal for:

- storing thousands/millions of image files themselves.

### Object storage

Much better for:

- images
- thumbnails
- pack archives
- potentially audio/video later

Cloudflare R2 is one candidate.

Other possibilities exist too.

The important architectural decision isn't:

> “Firebase or Cloudflare?”

It's:

> **Database for structured metadata + object storage/CDN for large files.**

That keeps the system sane.

---

# 5. And this makes your Content Studio much more powerful

Now I understand your dashboard idea better.

I wouldn't think of it merely as:

> “CRUD categories.”

I'd think:

# BiGuess Content Studio

It becomes the **control center for the entire content ecosystem.**

You have:

```text
Topics
Packs
Cards
Images
Contributors
Submissions
Moderation
Publishing
Versions
Statistics
```

A collector could create:

**Topic: Football**

↓

**Pack: World Cup Legends**

↓

Add 100 cards.

Then the system automatically:

- validates images
- compresses them
- creates thumbnails
- checks duplicates
- validates metadata
- generates pack version
- calculates hashes
- publishes approved content
- makes it available to players

The player never knows any of this exists.

They just see:

> **World Cup Legends**
>
> 100 cards
>
> **Download**

That's the right abstraction.

---

# 6. Community content could become huge

And this is where your idea gets really interesting.

Eventually:

**You don't have to create all BiGuess content yourself.**

A community member could submit:

> “Marvel Villains Pack”

or

> “Algerian Football Legends”

or

> “Famous Egyptian Actors”

or

> “90s Cartoons”

or

> “Islamic History Scholars”

or whatever people want.

But crucially:

### Community content should NOT automatically become public.

Workflow:

```text
User creates pack
       ↓
Submission
       ↓
Moderation
       ↓
Accept / Reject
       ↓
Published
       ↓
Available to everyone
```

That gives you a scalable content pipeline.

But it also introduces **moderation, copyright, abuse and quality problems** that we will eventually need to design properly.

Don't underestimate that part.

---

# 7. Copyright becomes MUCH more important here

This is one of the biggest things I want us to put into the blueprint.

If users can upload:

> One Piece characters

or

> Marvel characters

or

> Messi images

you can't simply assume:

> “The community uploaded it, so we're fine.”

You're operating the platform distributing that content.

That means community-generated content introduces:

- copyright complaints
- trademark issues
- impersonation
- inappropriate images
- spam
- malicious uploads
- duplicate content
- potentially illegal content

So a community marketplace/content system is **not just a technical feature**.

It's a product + moderation + legal system.

I still think it is worth designing for.

Just not pretending it's free complexity.

---

# 8. About Principle #12 — I agree with your correction

I would actually rewrite it.

Instead of:

> Optional Rules, Not Forced Rules

I'd call it:

# Configurable Game Modes, Minimal Enforcement

BiGuess should support only options that the application can meaningfully implement.

Your current list is good:

### Timer

The app can measure time.

### Number of rounds

The app can manage rounds.

### Difficulty

The app can select appropriate cards.

### Randomize categories

The app can select from one or multiple packs.

And that's enough for the core product.

I would **not** add:

- question counters
- automatic winner detection
- “correct answer” buttons
- answer validation
- mandatory score tracking

because those depend on human behavior that the phone cannot reliably observe.

The software should manage **things it knows**.

Humans manage **things humans know**.

That's a very useful BiGuess design rule.

---

# 9. Principle #14 — in simple words

You asked me to explain it more easily.

It basically means:

> **Don't spend money before the game makes money.**

Imagine BiGuess has:

100 users.

If we build:

- Firebase
- expensive servers
- image processing infrastructure
- real-time multiplayer
- databases
- analytics pipelines
- cloud functions

we might end up paying monthly bills while earning:

**$0.**

That's backwards.

Instead:

### Stage 1

Use free/cheap infrastructure.

Build the product.

Get users.

Learn what they actually want.

### Stage 2

Suppose you reach:

10,000 users.

Now you discover:

> “Our image delivery costs $30/month.”

Fine.

If BiGuess is earning $200/month, that's sustainable.

### Stage 3

Suppose you reach:

100,000 users.

Now infrastructure costs $300/month.

But BiGuess earns $2,000/month.

Still fine.

### Stage 4

Eventually:

> Revenue → pays infrastructure → remaining revenue → funds development.

That's healthy.

So the principle is:

> **Scale costs when the product proves it deserves to scale.**

Not:

> “Never pay for anything.”

That's an important distinction.

If paying $20/month saves you 30 hours of work or makes the product dramatically better, we can pay it.

We just don't commit to unnecessary recurring costs before there's a reason.

---

# 10. This doesn't mean everything must stay free forever

I don't want us to accidentally create a “never spend money” religion.

There are things worth paying for:

- domain
- professional email
- app-store fees
- reliable object storage
- CDN
- monitoring
- backups
- moderation tools
- design assets
- eventually servers

The question is:

> **Does the value justify the cost at this stage?**

That's the decision rule.

---

# 11. Now the monetization question

You asked earlier:

> “How do I earn money then? Freemium?”

My honest answer:

## I would NOT decide that yet.

That's not avoiding the question.

It's because **we don't yet know what users will value enough to pay for.**

But I would design BiGuess so several models remain possible.

### Option A — Free core + premium packs

For example:

**Free**
- several topics
- community packs
- offline downloads
- normal gameplay

**Premium**
- special curated packs
- advanced packs
- exclusive collections
- premium content bundles

This is probably the most natural model.

---

### Option B — Ads outside gameplay

Potentially:

Free users:

- ads in menus/content browsing

But:

**Absolutely no intrusive ads during a round.**

Imagine five friends finally start playing and:

> “WATCH THIS 30 SECOND RAID SHADOW LEGENDS AD”

No.

That would violate the entire philosophy of BiGuess.

If advertising exists, it should be peripheral.

---

### Option C — BiGuess Pro

One-time purchase or subscription could unlock:

- unlimited pack downloads
- advanced customization
- premium packs
- content creation tools
- advanced session modes
- no ads

But I would be cautious about subscriptions.

A party game doesn't naturally scream:

> **$4.99/month**

A one-time purchase may feel much more appropriate.

---

### Option D — Paid community packs

Eventually, creators could make premium packs.

For example:

> **Algerian Football Legends**
>
> 150 cards
>
> Free / 0.99 / etc.

Then you potentially have:

**creator → BiGuess → player**

But this is much later.

Because now you're building a marketplace with payments, moderation, refunds, creator policies, taxes, copyright issues, etc.

That's a business by itself.

---

# 12. My favorite long-term model for BiGuess

If BiGuess actually becomes popular, I could see something like:

```text
                    BiGuess
                       │
        ┌──────────────┼───────────────┐
        │              │               │
      Free          Premium        Community
        │              │               │
   Core packs      Curated packs    User packs
   Free topics     Special packs    Free + paid
   Offline         Pro features     Creator system
```

But **don't build all of this now**.

The MVP should prove:

> **Do people actually enjoy playing this together?**

If the answer is yes, then we build the economy around the behavior.

---

# 13. And there's an even better reason to separate content from the app

Imagine six months from now you add:

**Football**

You shouldn't have to:

```text
modify Dart
↓
add assets
↓
release APK
↓
wait for Play Store review
↓
users update
↓
finally play
```

Instead:

```text
Content Studio
      ↓
Football Pack v1.0
      ↓
Publish
      ↓
Users see it
      ↓
Download
      ↓
Play offline
```

That's **much closer to a real content platform.**

The app becomes increasingly stable while the content continuously evolves.

---

# 14. One architecture decision I strongly recommend

Don't make the app download individual images one by one during normal gameplay.

Instead, think in **versioned packs**.

For example:

```text
One Piece
  v1.4
  466 cards
  18.4 MB
  SHA-256: ...
```

Download once.

Store locally.

The app knows:

```text
Installed:
One Piece v1.3

Available:
One Piece v1.4
```

Then it downloads the update.

This gives you:

- fewer network requests
- easier integrity verification
- simpler caching
- atomic updates
- predictable offline behavior
- easy rollback
- better CDN performance

And it fits your existing experience with manifests/hashes extremely well.

We don't throw away that work—we redesign it around the new product model.

---

# 15. This changes our technical architecture considerably

I'm now leaning toward:

```text
                    BI GUESS APP
                         │
             ┌───────────┴───────────┐
             │                       │
       Game Engine              Content Engine
             │                       │
             │                Remote Catalog
             │                       │
             │                 Pack Manager
             │                       │
             │                Local Pack Store
             │                       │
             └───────────┬───────────┘
                         │
                    Offline Game
```

And separately:

```text
              BIGUESS CONTENT STUDIO
                         │
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
       Catalog        Moderation     Publishing
          │              │              │
          └──────────────┼──────────────┘
                         ↓
                  Object Storage/CDN
```

The important thing:

**The game engine doesn't depend on the cloud during gameplay.**

The cloud is primarily a **content distribution system**.

That's exactly what we want.

---

# And I think we've just discovered an important part of BiGuess's identity

BiGuess isn't simply:

> “An offline game.”

It's more precise to say:

> **BiGuess is an offline-first social game with an online content ecosystem.**

That's much more powerful.

The **gameplay** is offline.

The **library** can evolve online.

The player can choose:

> “I want Naruto.”

Download it.

Then put the phone away and play.

Tomorrow they discover:

> “Oh, they added Football.”

Download it.

Next week:

> “Someone made Algerian Football Legends.”

Download it.

The phone remains a tool, while the **content ecosystem keeps the tool fresh**.

I think this should become one of the central architectural decisions in the blueprint.


---

## Turn 7: User

### 👤 User

I afree


---

### 🤖 Assistant

Good. Then I think we have our first **locked architectural/product decision**:

> **BiGuess gameplay is offline-first; content is an online, expandable ecosystem that can be downloaded into offline packs.**

I would now put that into the blueprint as an official principle rather than continuing to debate it.

### Our next step

Let's move to **User Experience**.

Before touching Flutter, we should design the exact experience of a real group playing BiGuess:

**Opening the app → choosing a topic → choosing a pack/difficulty → players receiving identities → positioning the phones → playing → finishing the round → starting another round.**

And we should deliberately identify **every point where the app should disappear and let the people play**.

Once that flow is crystal clear, we'll define the **Game Model (`Topic → Pack → Card`)**, then the content ecosystem, then the Content Studio, and only after that the technology stack.

That's the order I'd strongly recommend.


---

## Turn 8: User

### 👤 User

User Experience


---

### 🤖 Assistant

Yes. Now that the core philosophy is clear, **User Experience should be designed around the physical table, not around the app screens**.

I would make this section very concrete, because later it will become the reference for deciding what the Flutter app actually does.

### User Experience

:::writing{variant="document" id="58321"}
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
:::

This gives us a much clearer foundation than the current app's screen-by-screen design.

The **most important new requirement** I would carry forward into the technical architecture is the “digital physical card” concept. The identity/reveal screen isn't just another Flutter page—it is the physical interface between the app and the people around the table.

And this UX also confirms something important: **the Content Studio and content delivery system are going to be much more important to BiGuess's long-term scalability than online multiplayer.** 

Next I'd define the **Game Model: `Topic → Pack → Card`**, including exactly what metadata a card needs, how randomization works with multiple players, how difficulty is represented, and how downloaded packs work locally.


---

## Turn 9: User

### 👤 User

2. Starting the Game: the user needs internet to download the needed packs then continue playing offline, and the loop repeats if user need to play in other topics/packs
3. Choosing What to Play: I like the option to play single/selected/random topics; but we have to think in easy to understand and use UX for all the gameplay settings, also for point 4 (Difficulty) and 10 (Rounds).

11) the timer is not part of the MVP, let say its not planning to be added to the game unless the community asked for it, I don't know if I am correct in this decision but this is what we will start with.

13. The core gameplay must require network connection is there is no packs downloaded yet.

15) Downloading Content should be encrypted inside the app, not as simple images in the phone storage, that will facilitate data scrapping. also no need for pack versioning, just compare content and download missing.

18. Keep animations, the attractive part of UI is animations so keep them and make them attractive, but never over effects.


---

### 🤖 Assistant

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

## Turn 10: User

### 👤 User

- whether the owner can accidentally peek; 
-  whether the group can recognize the identity immediately; 
-  whether the screen works when placed on a table.

you can't control those situations, they are part of the real life rules, the group should control those.

I will put all `lib/` flutter folder beside and start new one inspiring from the old one, also I am thinking on making the game playable without downloading but stays online to fetch one image each time then I canceled the idea from my head because it takes a lot of reads and that's not good for my free tier.


---

### 🤖 Assistant

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

## Turn 11: User

### 👤 User

move to Game Model


---

### 🤖 Assistant

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

## Turn 12: User

### 👤 User

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

### 🤖 Assistant

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

## Turn 13: User

### 👤 User

Nooo rounds specified after choosing packs, like between pack and game, he can update settings or keep defaults


---

### 🤖 Assistant

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

## Turn 14: User

### 👤 User

type me what to write in the md file for Game Model.


---

### 🤖 Assistant

Yes. Since this is going directly into the project blueprint, I would keep it **precise and implementation-oriented**, without prematurely deciding the technical storage architecture.

Replace the `Game Model` section in your MD with this:

:::writing{variant="document" id="74163"}
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
:::

This version now reflects your corrections: **Topic is non-playable, one Topic per game, Packs are the downloadable units, settings happen after Pack selection, difficulty is cumulative, rounds are tracked but not scored, card assignment is completely independent per phone, and the MVP has no timer or scoring.**

One detail I deliberately kept flexible is the exact behavior of **“Random Packs”**. We know it must operate *inside the chosen Topic* and only use downloaded Packs, but we should define exactly what “random” means when we design the Pack-selection UX.


---
