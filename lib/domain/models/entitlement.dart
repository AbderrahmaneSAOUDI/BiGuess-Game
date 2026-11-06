/// Internal MVP access rules. Commercial billing remains deferred to F01.
final class Entitlement {
  static const freeStoredPackLimit = 5;
  static const freeRoundLimit = 10;

  final bool isProTestEnabled;

  const Entitlement({this.isProTestEnabled = false});

  /// Release builds always use Free rules, even if the QA define is supplied.
  const Entitlement.fromEnvironment({
    bool isReleaseBuild = const bool.fromEnvironment('dart.vm.product'),
    bool isProTestEnabled = const bool.fromEnvironment('isProTestEnabled'),
  }) : isProTestEnabled = !isReleaseBuild && isProTestEnabled;

  int? get maxStoredPacks => isProTestEnabled ? null : freeStoredPackLimit;
  int? get maxRounds => isProTestEnabled ? null : freeRoundLimit;

  bool allowsRounds(int rounds) =>
      rounds > 0 && (maxRounds == null || rounds <= maxRounds!);

  bool allowsNewPack(int storedPacks) =>
      maxStoredPacks == null || storedPacks < maxStoredPacks!;
}
