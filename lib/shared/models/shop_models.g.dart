// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopOffer _$ShopOfferFromJson(Map<String, dynamic> json) => ShopOffer(
  offerId: json['offerId'] as String,
  itemId: json['itemId'] as String,
  offerType: json['offerType'] as String,
  priceCurrency: json['priceCurrency'] as String,
  priceAmount: (json['priceAmount'] as num).toInt(),
  quantity: (json['quantity'] as num).toInt(),
  limitPerPlayer: (json['limitPerPlayer'] as num?)?.toInt(),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$ShopOfferToJson(ShopOffer instance) => <String, dynamic>{
  'offerId': instance.offerId,
  'itemId': instance.itemId,
  'offerType': instance.offerType,
  'priceCurrency': instance.priceCurrency,
  'priceAmount': instance.priceAmount,
  'quantity': instance.quantity,
  'limitPerPlayer': instance.limitPerPlayer,
  'isActive': instance.isActive,
};

PurchaseResponse _$PurchaseResponseFromJson(Map<String, dynamic> json) =>
    PurchaseResponse(
      purchaseId: json['purchaseId'] as String,
      playerId: json['playerId'] as String,
      offerId: json['offerId'] as String,
      priceCurrency: json['priceCurrency'] as String,
      priceAmount: (json['priceAmount'] as num).toInt(),
      quantityGranted: (json['quantityGranted'] as num).toInt(),
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$PurchaseResponseToJson(PurchaseResponse instance) =>
    <String, dynamic>{
      'purchaseId': instance.purchaseId,
      'playerId': instance.playerId,
      'offerId': instance.offerId,
      'priceCurrency': instance.priceCurrency,
      'priceAmount': instance.priceAmount,
      'quantityGranted': instance.quantityGranted,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };
