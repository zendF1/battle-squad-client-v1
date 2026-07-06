import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/mission_models.dart';

final dailyMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/missions/daily');
  final rawList = data['missions'] as List<dynamic>? ??
      data['data'] as List<dynamic>? ??
      [];
  return rawList
      .map((e) => Mission.fromJson(e as Map<String, dynamic>))
      .toList();
});

final achievementsProvider = FutureProvider<List<Mission>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/missions/achievements');
  final rawList = data['missions'] as List<dynamic>? ??
      data['data'] as List<dynamic>? ??
      [];
  return rawList
      .map((e) => Mission.fromJson(e as Map<String, dynamic>))
      .toList();
});

Future<ClaimResponse> claimMission(WidgetRef ref, String missionId) async {
  final client = ref.read(apiClientProvider);
  final data = await client.post(
    '/missions/claim',
    data: {'mission_id': missionId},
  );
  return ClaimResponse.fromJson(data);
}
