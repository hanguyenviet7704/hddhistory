part of '../models.dart';

@freezed
abstract class IapProduct with _$IapProduct {
  const factory IapProduct({
    @Default('') String id,
    @Default('') String title,
    @Default('') String description,
    @DefaultString() @Default('') String price, // localized (e.g. ฿99.00)
    @Default(0) double rawPrice, // localized (e.g. ฿99.00)
    @Default('') String currencySymbol,
    @Default('') String currencyCode,
    @Default(false) bool isSubscription,
    @Default('') String planName,
    @Default(PaymentProvider()) PaymentProvider paymentProvider,
    @Default('') String externalPlanId,
    @Default('') String durationType,
    @Default(0) int durationValue,
    @Default('') String currency,
    @Default(false) bool isActive,
    @Default([]) List<Feature> features,
  }) = _IapProduct;

  factory IapProduct.fromJson(Map<String, dynamic> json) => _$IapProductFromJson(json);
}

extension IapProductExtension on IapProduct {
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
      String _ when id.contains('monthly') => 'context.text.monetMonthLabel',
      String _ when id.contains('weekly') => 'context.text.monetWeekLabel',
      _ => 'Not found product id',
    };
  }

  static IapProduct fromProductDetails(ProductDetails productDetails) {
    return IapProduct(
      id: productDetails.id,
      title: productDetails.title,
      price: productDetails.price,
      rawPrice: productDetails.rawPrice,
      currencySymbol: productDetails.currencySymbol,
      currencyCode: productDetails.currencyCode,
      description: productDetails.description,
    );
  }
}
