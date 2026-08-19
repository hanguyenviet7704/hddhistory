part of '../../monetization.dart';

/// Chu kỳ gia hạn của một gói, dùng cho hậu tố đơn vị trên thẻ gói.
enum IapPlanPeriod { week, month, quarter, year }

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

    /// The SKU this plan is priced against, and the store's own localized
    /// numbers for it. See [IapProductEntityX.hasCompareAtPrice].
    @Default('') String compareAtProductId,
    @Default('') String compareAtPrice,
    @Default(0) double compareAtRawPrice,
    @Default('') String compareAtCurrencyCode,
  }) = _IapProductEntity;

  factory IapProductEntity.fromJson(Map<String, dynamic> json) => _$IapProductEntityFromJson(json);
}

extension IapProductEntityX on IapProductEntity {
  bool get hasDiscount => rawPrice > 0 && salePercent > 0 && salePercent < 100;

  /// Whether the struck-through price above this plan can be shown. Every
  /// condition here is a case where showing it would be wrong rather than
  /// merely missing:
  /// - no store answer for the configured SKU (unlisted / not approved / no
  ///   reference configured at all)
  /// - the reference is not actually more expensive, so there is no saving
  /// - the two prices are in different currencies, which cannot be compared
  bool get hasCompareAtPrice =>
      compareAtPrice.isNotEmpty && rawPrice > 0 && compareAtRawPrice > rawPrice && (compareAtCurrencyCode.isEmpty || compareAtCurrencyCode == currencyCode);

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

  /// Số ngày một chu kỳ, suy từ product id như [_perPeriodValue] làm.
  ///
  /// Cùng một cách suy (theo id) chứ không phải một cách thứ hai: hai chỗ đoán
  /// chu kỳ theo hai luật khác nhau thì sớm muộn sẽ nói hai con số khác nhau về
  /// cùng một gói. 365/30 là số ngày THƯƠNG MẠI, không phải lịch — đây là dòng
  /// chữ "…/ngày" để so sánh gói, không phải một phép tính tiền.
  int get _periodDays {
    final idLower = productId.toLowerCase();

    if (idLower.contains('year') || idLower.contains('annual') || idLower.contains('1y')) return 365;
    if (idLower.contains('quarter') || idLower.contains('3m')) return 90;
    if (idLower.contains('week')) return 7;

    return 30;
  }

  /// Chu kỳ gia hạn của gói, cho hậu tố "/năm" trên thẻ (design `6b · Premium`).
  ///
  /// Suy từ CÙNG cách đọc product id mà [_periodDays] dùng — không phải
  /// [periodLabel]: nhãn đó là "mỗi tháng" kể cả với gói năm (app quy gói năm về
  /// giá mỗi tháng ở chỗ khác), nên ghép nó với TỔNG giá năm sẽ in ra
  /// "959.000đ/mỗi tháng" — một câu sai sự thật, không chỉ sai design.
  IapPlanPeriod get planPeriod {
    final idLower = productId.toLowerCase();

    if (idLower.contains('year') || idLower.contains('annual') || idLower.contains('1y')) return IapPlanPeriod.year;
    if (idLower.contains('quarter') || idLower.contains('3m')) return IapPlanPeriod.quarter;
    if (idLower.contains('week')) return IapPlanPeriod.week;

    return IapPlanPeriod.month;
  }

  /// Giá mỗi ngày, định dạng BÁM THEO chuỗi giá của store.
  ///
  /// Không dùng [_formatPriceWithCurrency]: nó đặt ký hiệu ở trước và nhóm số
  /// bằng locale mặc định của `NumberFormat()`, nên trên máy tiếng Việt nó in
  /// `đ2,627` ngay cạnh `959.000đ` của chính store — hai định dạng cho cùng một
  /// loại tiền, cạnh nhau trên một thẻ. Chuỗi của store là con số duy nhất người
  /// đọc có thể đối chiếu, nên ở đây sao lại dấu phân nhóm và vị trí ký hiệu của
  /// nó thay vì đoán locale.
  ///
  /// Rỗng khi không có giá thô để chia — thẻ bỏ hẳn dòng này thay vì in `--`.
  String get perDayPriceString {
    if (rawPrice <= 0) return '';

    final grouped = _groupThousands(
      (rawPrice / _periodDays).round().toString(),
      _storeGroupingSeparator,
    );
    if (currencySymbol.isEmpty) return grouped;

    // Interpolated, NOT escaped. `'\$currencySymbol\$grouped'` printed the
    // placeholder NAMES to the reader — `199.000đ/tháng $grouped$currencySymbol
    // /ngày` on a real device — and the literal was long enough to overrun the
    // struck price beside it, so the card read as two prices colliding.
    return price.trimLeft().startsWith(currencySymbol) ? '$currencySymbol$grouped' : '$grouped$currencySymbol';
  }

  /// Dấu phân nhóm nghìn mà STORE dùng trong [price] ('.' hoặc ','). Mặc định
  /// ',' khi giá quá nhỏ để có dấu nào — lúc đó nó cũng không được dùng.
  String get _storeGroupingSeparator {
    final match = RegExp(r'\d([.,])\d{3}').firstMatch(price);

    return match?.group(1) ?? ',';
  }

  static String _groupThousands(String digits, String separator) {
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(separator);
      out.write(digits[i]);
    }

    return out.toString();
  }

  String _formatPriceValue(double value) => value.round().currency;

  String _formatPriceWithCurrency(double value) {
    if (currencySymbol.isEmpty) return _formatPriceValue(value);
    return '$currencySymbol${_formatPriceValue(value)}';
  }
}
