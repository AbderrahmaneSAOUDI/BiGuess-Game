import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/entitlement.dart';

/// Override in tests, or run a non-release build with
/// --dart-define=isProTestEnabled=true for internal Pro QA.
final entitlementProvider = Provider<Entitlement>((ref) {
  return const Entitlement.fromEnvironment();
});
