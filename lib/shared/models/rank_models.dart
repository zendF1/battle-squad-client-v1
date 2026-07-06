import 'package:json_annotation/json_annotation.dart';

part 'rank_models.g.dart';

@JsonSerializable()
class PlayerRank {
  final String playerId;
  final String displayName;
  final String seasonId;
  final int rating;
  final String tier;
  final int division;
  final int wins;
  final int losses;
  final int draws;
  final int winStreak;
  final String? highestTier;
  final String updatedAt;
  final int? rankPos;

  PlayerRank({
    required this.playerId,
    required this.displayName,
    required this.seasonId,
    required this.rating,
    required this.tier,
    required this.division,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winStreak,
    this.highestTier,
    required this.updatedAt,
    this.rankPos,
  });

  factory PlayerRank.fromJson(Map<String, dynamic> json) =>
      _$PlayerRankFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerRankToJson(this);
}

@JsonSerializable()
class Season {
  final String seasonId;
  final String name;
  final String startsAt;
  final String endsAt;
  final String status;

  Season({
    required this.seasonId,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  factory Season.fromJson(Map<String, dynamic> json) =>
      _$SeasonFromJson(json);
  Map<String, dynamic> toJson() => _$SeasonToJson(this);
}
