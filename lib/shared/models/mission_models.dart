import 'package:json_annotation/json_annotation.dart';

part 'mission_models.g.dart';

@JsonSerializable()
class Mission {
  final String missionId;
  final String type;
  final String target;
  final int requiredValue;
  final int currentValue;
  final int rewardCoin;
  final int rewardGem;
  final List<String> rewardItems;
  final bool isClaimed;

  Mission({
    required this.missionId,
    required this.type,
    required this.target,
    required this.requiredValue,
    required this.currentValue,
    required this.rewardCoin,
    required this.rewardGem,
    required this.rewardItems,
    required this.isClaimed,
  });

  factory Mission.fromJson(Map<String, dynamic> json) =>
      _$MissionFromJson(json);
  Map<String, dynamic> toJson() => _$MissionToJson(this);
}

@JsonSerializable()
class ClaimResponse {
  final int rewardCoin;
  final int rewardGem;
  final String missionId;

  ClaimResponse({
    required this.rewardCoin,
    required this.rewardGem,
    required this.missionId,
  });

  factory ClaimResponse.fromJson(Map<String, dynamic> json) =>
      _$ClaimResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ClaimResponseToJson(this);
}
