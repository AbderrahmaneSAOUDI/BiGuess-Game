# Repository Audit & Technical Assessment

> Initial repository code & architecture audit against project dossier

---

## **User:**

lets talk about my project, be honest and tell me whats good what not and what should I improve

  @GitHub check this repo: https://github.com/AbderrahmaneSAOUDI/BiGuess-Game  be honest with me and tell me everything

---

## **ChatGPT:**

I’m going to judge this as both a **product** and a **codebase**—not just whether it “looks impressive.” I’ll compare the repo against your project dossier, then call out the strengths, weak points, hidden risks, and what I’d prioritize next.

---

## **ChatGPT:**

One thing already stands out: the **documentation is ahead of the actual repository state**. For example, your README advertises `v0.25.0`, `pubspec.yaml` is `0.30.5+6`, while the latest commit history includes a `v0.31` commit followed by another `release: v0.30.5`. That kind of version drift makes a project feel less controlled than the underlying code may actually be.

---

## **ChatGPT:**

The second big issue is more product-facing: the UI registers **18 categories, but the repo only contains character-image folders for 6**. So “18 franchises” currently means “6 playable + 12 placeholders,” not 18 playable universes. That’s okay for a roadmap, but the current README wording oversells the shipped content.

---

## **ChatGPT:**

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

