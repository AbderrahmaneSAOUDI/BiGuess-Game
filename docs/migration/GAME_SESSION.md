# Local GameSession contract (T13)

`gameSessionProvider` owns a temporary session in one `ProviderScope`. It has no
watched repository, settings or entitlement dependencies, timers, network calls,
or persistence. A new scope/process begins at Home. The existing reveal screen
remains a separate migration path; configuration and completion UI wiring belong
to T14/T16/T17.

`GameSessionConfiguration` freezes the Topic ID, selected Pack IDs, cumulative
maximum difficulty, rounds and locally resolved access tier. Free is the default
and permits 1–10 rounds; Pro permits any positive round count. This value is the
session boundary, separate from an editable configuration-screen draft.

| Event | Allowed state | Result |
| --- | --- | --- |
| `configure(configuration)` | Home, configuring | Replace setup; no Card assigned |
| `start(topic, installedPacks, installedCards)` | Configuring | Capture content, assign round index 0 |
| `nextRound()` | Active | Finish displayed round, assign next Card or complete |
| `requestReplay()` (Free) | Completed | Return `home` routing intent; keep session completed |
| `requestReplay()` (Pro) | Completed | Immediately assign index 0 using the same configuration/snapshot; return `game` |
| `exit()` | Any | Release content and draw state; repeated exits are safe |
| `returnHome()` | Any, when Home is reached | Clear configuration, content and counters; permit fresh setup |

Other transitions throw `StateError` without changing the session. Failed Start
validation leaves setup intact. Final-round completion assigns no extra Card.
`roundIndex` is zero-based, `roundNumber` is one-based during play/completion,
and `completedRounds` counts finished rounds. Completion has no assigned Card.

Free replay does not reset the counter by requesting navigation: the router must
reach Home and call `returnHome()` before another game can be configured. There
is no daily/lifetime counter, login, advertisement or network requirement.

## Installed content and safe points

Before Start, the caller obtains verified installed revisions and local image
references from the content layer. Do not supply newer cached catalog Cards.
For SQLite, use installed state and `getEligibleCards`; for `LocalPackStore`, use
the returned `InstalledLocalPack` metadata/Cards. Publication policy for already
installed unpublished content remains outside T13, as recorded in DECISIONS.

Start verifies one Topic, every selected Pack, non-deleted selected containers,
unique IDs and a nonempty cumulative-difficulty pool. It copies the selected
collections into `GameContentSnapshot`; their Topic/Pack/Card values are already
immutable. The local `CardSelectionEngine` supplies IDs and all assigned Cards
resolve from that snapshot. Later catalog updates, install activation, hiding,
tombstones or repository disposal never trigger a session read or rebuild.

`retainsContent` remains true through completion, allowing Pro replay and keeping
the gameplay resource boundary explicit. It becomes false at exit or Home.
Storage/sync must retain referenced image generations until that boundary;
immutable paths alone cannot protect files from arbitrary physical deletion.
`LocalPackStore` already retains previous activated generations. Tombstone
application and generation reclamation remain T41/T43 work.

```bash
flutter test test/unit/game_session_test.dart test/integration/game_session_content_test.dart
```

Tests cover exact Free round counts 1–10, Pro rounds above ten, deck refills,
invalid transitions/setup, exit, Home reset, replay, collection/provider
isolation, SQLite updates/unpublishing/deletion markers and installed Pack
replacement with the original image bytes remaining readable throughout play.
