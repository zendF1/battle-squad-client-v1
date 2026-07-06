import 'package:json_annotation/json_annotation.dart';

part 'shop_models.g.dart';

@JsonSerializable()
class ShopOffer {
  final String offerId;
  final String itemId;
  final String offerType;
  final String priceCurrency;
  final int priceAmount;
  final int quantity;
  final int? limitPerPlayer;
  final bool isActive;

  ShopOffer({
    required this.offerId,
    required this.itemId,
    required this.offerType,
    required this.priceCurrency,
    required this.priceAmount,
    required this.quantity,
    this.limitPerPlayer,
    required this.isActive,
  });

  factory ShopOffer.fromJson(Map<String, dynamic> json) =>
      _$ShopOfferFromJson(json);
  Map<String, dynamic> toJson() => _$ShopOfferToJson(this);
}

@JsonSerializable()
class PurchaseResponse {
  final String purchaseId;
  final String playerId;
  final String offerId;
  final String priceCurrency;
  final int priceAmount;
  final int quantityGranted;
  final String status;
  final String createdAt;

  PurchaseResponse({
    required this.purchaseId,
    required this.playerId,
    required this.offerId,
    required this.priceCurrency,
    required this.priceAmount,
    required this.quantityGranted,
    required this.status,
    required this.createdAt,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$PurchaseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PurchaseResponseToJson(this);
}
