import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/rank_models.dart';

final myRankProvider = FutureProvider<PlayerRank>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/rank/me');
  return PlayerRank.fromJson(data);
});

final leaderboardProvider =
    FutureProvider.family<List<PlayerRank>, int>((ref, page) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get(
    '/rank/leaderboard',
    queryParams: {'page': page, 'limit': 50},
  );
  final rawList = data['leaderboard'] as List<dynamic>? ??
      data['players'] as List<dynamic>? ??
      data['data'] as List<dynamic>? ??
      [];
  return rawList
      .map((e) => PlayerRank.fromJson(e as Map<String, dynamic>))
      .toList();
});

final currentSeasonProvider = FutureProvider<Season>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/rank/seasons/current');
  return Season.fromJson(data);
});

class SeasonRewardService {
  final Ref _ref;

  SeasonRewardService(this._ref);

  Future<Map<String, dynamic>> claimReward({
    required String seasonId,
    required String tier,
  }) async {
    final client = _ref.read(apiClientProvider);
    final data = await client.post('/rank/reward/claim', data: {
      'seasonId': seasonId,
      'tier': tier,
    });
    return data;
  }
}

final seasonRewardServiceProvider = Provider<SeasonRewardService>(
  (ref) => SeasonRewardService(ref),
);
