# T14 — Game setup and internal entitlements

After Pack selection, `GameConfigurationScreen` defaults to **Easy** and
**10 rounds**. Difficulty is cumulative: Medium includes Easy + Medium; Hard
includes all three levels. The screen shows the eligible Card count. Start is
disabled for a missing installation, an empty eligible pool, a nonpositive or
noninteger round count, or more than 10 rounds with Free access.

`ContentRepository.getInstalledCardsForPack` distinguishes an unavailable Pack
(`null`) from an installed empty Pack (`[]`). Bundled content is already local.
The SQLite adapter returns installed Card snapshots, never a newer cached-only
catalog revision. No network check belongs to setup or play.

Start revalidates the live inputs and creates a `GameContentSnapshot` with a
`GameSessionConfiguration`. Its Card list and settings are immutable. The
existing reveal controller consumes this detached snapshot and captures its
legacy countdown/algorithm settings once. Later content, entitlement or settings
changes cannot change the active pool, difficulty or round count. The setup
route is replaced so Back exits to Packs. The controller stops accepting draws
at the configured count and offers Return to Packs. Full session-screen and
completion/replay presentation remain T16/T17; the existing reveal stays intact.

## Internal Pro QA

`entitlementProvider` defaults to `Entitlement.fromEnvironment()`. Without an
explicit test opt-in, Free allows at most **5 simultaneously installed Packs**
and **10 rounds per game**. There is no daily/cumulative quota. All Cards within
the selected installed content remain accessible.

For a non-release QA build:

```bash
flutter run --dart-define=isProTestEnabled=true
```

This removes both numeric limits. Positive integer rounds are still required.
Release builds ignore this define and always default to Free. There is no
customer-facing entitlement switch, billing SDK, receipt validation, login or
online entitlement request. Commercial entitlement work remains F01.

Automated tests can explicitly override access:

```dart
entitlementProvider.overrideWithValue(
  const Entitlement(isProTestEnabled: true),
)
```

The importer accepts the same value through
`LocalPackStore.openDefault(entitlement: ref.read(entitlementProvider))` or its
constructor. Its default also reads the compile-time environment. The five-Pack
check runs inside the installation writer lock. Updating/retrying an existing
Pack uses no additional slot. Returning to Free never evicts existing Packs;
new installations are rejected while at/above the cap. Bundled fallback content
does not consume downloaded-Pack slots. Pack removal UI remains separate work.

## Verification

```bash
flutter test test/unit/game_setup_test.dart test/unit/pack_entitlement_test.dart
flutter test test/integration/game_setup_content_test.dart
flutter test test/widget/game_configuration_screen_test.dart test/widget/content_navigation_test.dart
```

Tests exercise defaults and navigation, cumulative filtering, invalid entries,
uninstalled/cached-only content, Pro configuration, immutable settings and pools,
duplicate taps and the exact draw cap. Import tests cover the sixth-Pack
rejection, updates at the cap, Pro imports and concurrent slot contention.
