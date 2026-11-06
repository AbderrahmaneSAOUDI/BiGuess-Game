import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/images/content_image_loader.dart';

/// Override for an isolated private store in tests or alternate local sources.
final contentImageLoaderProvider = Provider<ContentImageLoader>((ref) {
  return ContentImageLoader.shared;
});
