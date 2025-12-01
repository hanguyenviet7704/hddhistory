part of '../../monetization.dart';

@freezed
abstract class IapProductModel with _$IapProductModel {
  const factory IapProductModel({
    @Default('') String id,
    @Default('') String title,
    @Default('') String description,
    @DefaultString() @Default('') String price, // localized (e.g. ฿99.00)
    @Default(0) double rawPrice, // localized (e.g. ฿99.00)
    @Default('') String currencySymbol,
    @Default('') String currencyCode,
    @Default(false) bool isSubscription,
    @Default('') String planName,
    @Default(PaymentProviderModel()) PaymentProviderModel paymentProvider,
    @Default('') String externalPlanId,
    @Default('') String durationType,
    @Default(0) int durationValue,
    @Default('') String currency,
    @Default(false) bool isActive,
    @Default([]) List<FeatureModel> features,
  }) = _IapProductModel;

  factory IapProductModel.fromJson(Map<String, dynamic> json) => _$IapProductModelFromJson(json);
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
      String _ when id.contains('monthly') => 'context.text.monetMonthLabel',
      String _ when id.contains('weekly') => 'context.text.monetWeekLabel',
      _ => 'Not found product id',
    };
  }

  static IapProductModel fromProductDetails(ProductDetails productDetails) {
    return IapProductModel(
      id: productDetails.id,
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
    title: title,
    description: description,
    price: price,
    rawPrice: rawPrice,
    currencySymbol: currencySymbol,
    currencyCode: currencyCode,
    isSubscription: isSubscription,
    planName: planName,
    paymentProvider: paymentProvider.toEntity(),
    externalPlanId: externalPlanId,
    durationType: durationType,
    durationValue: durationValue,
    currency: currency,
    isActive: isActive,
    features: features.map((f) => f.toEntity()).toList(),
  );
}
