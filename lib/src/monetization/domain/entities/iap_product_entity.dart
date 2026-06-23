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
    @Default(0) double salePercent,
    @Default('') String currencyCode,
    @Default('') String currencySymbol,
    @Default(false) bool bestDeal,
  }) = _IapProductEntity;

  factory IapProductEntity.fromJson(Map<String, dynamic> json) => _$IapProductEntityFromJson(json);
}

extension IapProductEntityX on IapProductEntity {
  bool get hasDiscount => rawPrice > 0 && salePercent > 0 && salePercent < 100;

  double get saleScale => (salePercent / 100);

  double get originalPrice {
    if (!hasDiscount) return rawPrice;
    return rawPrice / (1 - saleScale);
  }

  String get originalPriceString {
    return _formatPriceWithCurrency(originalPrice);
  }

  String get periodLabel {
    // if (productId.contains('1y') || productId.toLowerCase().contains('year')) return t.monetization.pricePerYear;
    // if (productId.contains('3m') || productId.toLowerCase().contains('quarter')) return t.monetization.pricePerQuarter;
    // if (productId.toLowerCase().contains('life')) return t.monetization.pricePerLifetime;
    // if (productId.contains('week')) return t.monetization.pricePerWeek;
    // if (productId.contains('day')) return t.monetization.pricePerDay;

    final idLower = productId.toLowerCase();
    if (idLower.contains('year') || idLower.contains('annual') || idLower.contains('1y')) return l10n.monetization.pricePerMonth;
    if (idLower.contains('quarter') || idLower.contains('3m')) return l10n.monetization.pricePerMonth;
    if (idLower.contains('month')) return l10n.monetization.pricePerMonth;
    if (idLower.contains('week')) return l10n.monetization.pricePerWeek;
    return l10n.monetization.pricePerMonth;
  }

  double get _perPeriodValue {
    final idLower = productId.toLowerCase();

    if (idLower.contains('year') || idLower.contains('annual') || idLower.contains('1y')) return rawPrice / 12;
    if (idLower.contains('quarter') || idLower.contains('3m')) return rawPrice / 3;

    return rawPrice;
  }

  String get pricePerPeriodString {
    if (rawPrice <= 0) return price.isNotEmpty ? price : '--';
    return _formatPriceWithCurrency(_perPeriodValue);
  }

  double get perPeriodValue => _perPeriodValue;

  String _formatPriceValue(double value) => value.round().currency;

  String _formatPriceWithCurrency(double value) {
    if (currencySymbol.isEmpty) return _formatPriceValue(value);
    return '$currencySymbol${_formatPriceValue(value)}';
  }
}
