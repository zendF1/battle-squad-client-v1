import 'package:json_annotation/json_annotation.dart';

part 'iap_models.g.dart';

@JsonSerializable()
class IAPProduct {
  final String productId;
  final Map<String, String> platformSkuId;
  final int gemAmount;
  final int bonusGemAmount;
  final double priceUsd;
  final bool isActive;

  IAPProduct({
    required this.productId,
    required this.platformSkuId,
    required this.gemAmount,
    required this.bonusGemAmount,
    required this.priceUsd,
    required this.isActive,
  });

  factory IAPProduct.fromJson(Map<String, dynamic> json) =>
      _$IAPProductFromJson(json);
  Map<String, dynamic> toJson() => _$IAPProductToJson(this);

  int get totalGems => gemAmount + bonusGemAmount;
}
