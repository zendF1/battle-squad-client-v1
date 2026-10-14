import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';

final appRemoteConfigProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final client = ref.read(apiClientProvider);
    final data = await client.get('/app/config');
    return data;
  } catch (e) {
    debugPrint('[AppConfig] Failed to load remote config: $e');
    return {};
  }
});
