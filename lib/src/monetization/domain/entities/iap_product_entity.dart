part of '../../monetization.dart';

@freezed
abstract class IapProductEntity with _$IapProductEntity {
  const factory IapProductEntity({
    @Default('') String id,
    @Default('') String productId,
    @Default(PaymentPlatform.google) PaymentPlatform platform,
    @Default(ProductType.subscriptionAutoRenew) ProductType type,
    @Default('') String title,
    @Default('') String description,
    @Default('') String price,
    @Default(0) double rawPrice,
    @Default('') String currencyCode,
    @Default('') String currencySymbol,
    @Default(false) bool bestDeal,
  }) = _IapProductEntity;

  factory IapProductEntity.fromJson(Map<String, dynamic> json) => _$IapProductEntityFromJson(json);
}

extension IapProductEntityX on IapProductEntity {
  bool get hasDiscount => rawPrice > 0 && rawPrice * saleScale > rawPrice + 0.01;

  double get saleScale => 2;

  int get salePercent => ((1 / saleScale) * 100).round();

  String get originalPriceString {
    final original = rawPrice * saleScale;
    if (currencySymbol.isNotEmpty) {
      return '$currencySymbol${original.currency}';
    }
    return original.currency;
  }

  String get periodLabel {
    // if (productId.contains('1y') || productId.toLowerCase().contains('year')) return t.monetization.pricePerYear;
    // if (productId.contains('3m') || productId.toLowerCase().contains('quarter')) return t.monetization.pricePerQuarter;
    // if (productId.toLowerCase().contains('life')) return t.monetization.pricePerLifetime;
    // if (productId.contains('week')) return t.monetization.pricePerWeek;
    // if (productId.contains('day')) return t.monetization.pricePerDay;

    return t.monetization.pricePerMonth;
  }

  double get _perPeriodValue {
    final idLower = productId.toLowerCase();

    if (idLower.contains('year') || idLower.contains('annual') || productId.contains('1y')) return rawPrice / 12;
    if (idLower.contains('quarter') || productId.contains('3m')) return rawPrice / 3;
    if (idLower.contains('week') || productId.contains('week')) return rawPrice / 4;
    if (idLower.contains('day') || productId.contains('day')) return rawPrice / 30;

    return rawPrice;
  }

  String get pricePerPeriodString {
    if (rawPrice <= 0) return price.isNotEmpty ? price : '--';
    final value = _perPeriodValue.roundToDouble();
    return currencySymbol.isNotEmpty ? '$currencySymbol${value.currency}' : value.currency;
  }

  double get perPeriodValue => _perPeriodValue;
}
