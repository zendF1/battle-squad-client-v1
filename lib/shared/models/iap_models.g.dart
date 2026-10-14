// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iap_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IAPProduct _$IAPProductFromJson(Map<String, dynamic> json) => IAPProduct(
  productId: json['productId'] as String,
  platformSkuId: Map<String, String>.from(json['platformSkuId'] as Map),
  gemAmount: (json['gemAmount'] as num).toInt(),
  bonusGemAmount: (json['bonusGemAmount'] as num).toInt(),
  priceUsd: (json['priceUsd'] as num).toDouble(),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$IAPProductToJson(IAPProduct instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'platformSkuId': instance.platformSkuId,
      'gemAmount': instance.gemAmount,
      'bonusGemAmount': instance.bonusGemAmount,
      'priceUsd': instance.priceUsd,
      'isActive': instance.isActive,
    };
