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
    @Default('') String currencyCode,
    @Default('') String currencySymbol,
    @Default(false) bool bestDeal,
  }) = _IapProductModel;

  factory IapProductModel.fromJson(Map<String, dynamic> json) => _$IapProductModelFromJson(json);
}

enum PaymentPlatform {
  @JsonValue('google')
  google,
  @JsonValue('apple')
  apple,
  @JsonValue('unknown')
  unknown
  ;

  static PaymentPlatform get fromDevicePlatform {
    if (Platform.isIOS) return apple;
    return google;
  }
}

extension IapProductModelExtension on IapProductModel {
  bool get isSale => id.contains('monthly');

  double get originalPrice => rawPrice * saleScale;

  String get originalPriceString {
    int currencySymbolIndex = price.indexOf(RegExp(r'[^0-9.,\s]'));
    if (currencySymbolIndex == -1) return price;
    if (currencySymbolIndex == 0) return '${price.substring(0, currencySymbolIndex)}${originalPrice.currency}';
    return '${originalPrice.currency}${price.substring(currencySymbolIndex)}';
  }

  double get saleScale => 2;

  int get salePercent => ((1 / saleScale) * 100).toInt();

  String period(BuildContext context) {
    return switch (id) {
      String _ when id.contains('monthly') => context.text.monetization.pricePerMonth,
      String _ when id.contains('weekly') => context.text.monetization.pricePerWeek,
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
    currencyCode: currencyCode,
    currencySymbol: currencySymbol,
    bestDeal: bestDeal,
  );
}

extension IapProductModelListExtension on List<IapProductModel> {
  List<IapProductModel> mapStoreData(List<IapProductModel> storeData) {
    List<IapProductModel> result = [];

    for (var index = 0; index < length; index++) {
      final item = this[index];
      final storeDataIndex = storeData.indexWhere((element) => element.productId == item.productId);
      if (storeDataIndex == -1) continue;
      final storeDataItem = storeData[storeDataIndex];
      result.add(
        item.copyWith(
          description: storeDataItem.description,
          price: storeDataItem.price,
          rawPrice: storeDataItem.rawPrice,
          currencyCode: storeDataItem.currencyCode,
          currencySymbol: storeDataItem.currencySymbol,
        ),
      );
    }

    result.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    result.sort((a, b) => b.bestDeal ? 1 : -1);
    return result;
  }
}
