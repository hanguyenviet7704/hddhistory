part of '../../monetization.dart';

@freezed
abstract class IapProductModel with _$IapProductModel {
  const factory IapProductModel({
    @Default('') String id,
    @Default('') String productId,
    @JsonKey(unknownEnumValue: PaymentPlatform.unknown) @Default(PaymentPlatform.google) PaymentPlatform platform,
    @JsonKey(unknownEnumValue: ProductType.subscriptionAutoRenew) @Default(ProductType.subscriptionAutoRenew) ProductType type,
    @Default('') String title,
    @Default('') String description,
    @DefaultString() @Default('') String price,
    @Default(0) double rawPrice,
    @Default(0) double salePercent,
    @Default('') String currencyCode,
    @Default('') String currencySymbol,
    @Default(false) bool bestDeal,

    /// Another SKU on the same store, configured in admin, whose real price is
    /// struck through above this one's. A reference and never an amount, so the
    /// struck number stays localized per storefront (Apple prices in 175
    /// territories) and cannot drift from what the store charges.
    @Default('') String compareAtProductId,

    /// Filled by [IapProductModelListExtension.mapStoreData] from the store's
    /// answer for [compareAtProductId] — never sent by the API, which does not
    /// know local prices.
    @Default('') String compareAtPrice,
    @Default(0) double compareAtRawPrice,
    @Default('') String compareAtCurrencyCode,
  }) = _IapProductModel;

  factory IapProductModel.fromJson(Map<String, dynamic> json) => _$IapProductModelFromJson(json);
}

enum PaymentPlatform {
  @JsonValue('google')
  google,
  @JsonValue('apple')
  apple,
  @JsonValue('unknown')
  unknown;

  static PaymentPlatform get fromDevicePlatform {
    if (Platform.isIOS) return apple;
    return google;
  }
}

extension IapProductModelExtension on IapProductModel {
  bool get isSale => id.contains('monthly');

  String period(BuildContext context) {
    return switch (id) {
      String _ when id.contains('monthly') => context.l10n.monetization.pricePerMonth,
      String _ when id.contains('weekly') => context.l10n.monetization.pricePerWeek,
      _ => 'Not found product id',
    };
  }

  static IapProductModel fromProductDetails(ProductDetails productDetails) {
    return IapProductModel(
      productId: productDetails.id,
      title: productDetails.title,
      price: productDetails.price,
      rawPrice: productDetails.rawPrice,
      currencySymbol: productDetails.currencySymbol,
      currencyCode: productDetails.currencyCode,
      description: productDetails.description,
    );
  }

  IapProductEntity toEntity() => IapProductEntity(
    id: id,
    productId: productId,
    platform: platform,
    type: type,
    title: title,
    description: description,
    price: price,
    rawPrice: rawPrice,
    salePercent: salePercent,
    currencyCode: currencyCode,
    currencySymbol: currencySymbol,
    bestDeal: bestDeal,
    compareAtProductId: compareAtProductId,
    compareAtPrice: compareAtPrice,
    compareAtRawPrice: compareAtRawPrice,
    compareAtCurrencyCode: compareAtCurrencyCode,
  );
}

extension IapProductModelListExtension on List<IapProductModel> {
  List<IapProductModel> mapStoreData(List<IapProductModel> storeData) {
    final storeByProductId = {for (final item in storeData) item.productId: item};
    final result = <IapProductModel>[];

    for (final item in this) {
      final storeDataItem = storeByProductId[item.productId];
      if (storeDataItem == null) continue;
      // Absent when the SKU has no reference configured or the store did not
      // return it (unlisted, not approved yet, removed). Both cases simply
      // leave the struck-through price empty — never a blocked paywall.
      final compareAtItem = item.compareAtProductId.isEmpty ? null : storeByProductId[item.compareAtProductId];
      result.add(
        item.copyWith(
          title: storeDataItem.title,
          description: storeDataItem.description,
          price: storeDataItem.price,
          rawPrice: storeDataItem.rawPrice,
          currencyCode: storeDataItem.currencyCode,
          currencySymbol: storeDataItem.currencySymbol,
          compareAtPrice: compareAtItem?.price ?? '',
          compareAtRawPrice: compareAtItem?.rawPrice ?? 0,
          compareAtCurrencyCode: compareAtItem?.currencyCode ?? '',
        ),
      );
    }

    return result;
  }
}
