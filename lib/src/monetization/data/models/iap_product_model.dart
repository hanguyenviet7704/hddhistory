part of '../../monetization.dart';

@freezed
abstract class IapProductModel with _$IapProductModel {
  const factory IapProductModel({
    @Default('') String id,
    @Default('') String productId,
    @Default(PaymentPlatform.google) PaymentPlatform platform,
    @Default('') String title,
    @Default('') String description,
    @DefaultString() @Default('') String price,
    @Default(0) double rawPrice,
    @Default('') String currencyCode,
    @Default('') String currencySymbol,
  }) = _IapProductModel;

  factory IapProductModel.fromJson(Map<String, dynamic> json) => _$IapProductModelFromJson(json);
}

// export enum PaymentPlatform {
enum PaymentPlatform {
  @JsonValue('google')
  google,
  @JsonValue('apple')
  apple,
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
    productId: productId,
    platform: platform,
    title: title,
    description: description,
    price: price,
    rawPrice: rawPrice,
    currencyCode: currencyCode,
    currencySymbol: currencySymbol,
  );
}
