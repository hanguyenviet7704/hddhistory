part of '../services.dart';

/// Stand-in store products for the DEV flavor.
///
/// App Store Connect has no app record for `com.hddhistory.app.dev` at all (only
/// `com.hddhistory.app` exists), so StoreKit can never return a product on a dev
/// build — on a device, on the Firebase distribution, or on the simulator
/// without an Xcode-launched `.storekit` file. `getProducts` therefore comes
/// back empty and the paywall dies at the "Configured store product is
/// missing" guard, which makes the whole screen impossible to review on dev.
///
/// These fill only the gap: any SKU the real store did not return. If a store
/// product does exist it always wins, so this never masks a genuine listing.
///
/// Prices are illustrative. They do NOT come from App Store Connect and must
/// never be read as the real charge — purchasing one of these fails, since no
/// such product exists in any store. To exercise an actual transaction use the
/// StoreKit configuration file (`ios/Runner/HDDhistory.storekit`, dev scheme, run
/// from Xcode) or a sandbox account against the production bundle.
abstract final class DevMockProducts {
  /// Rough VND price points, chosen to look plausible next to the real
  /// catalogue rather than to match it.
  static const _basePriceVnd = <String, double>{
    '1m': 199000,
    '3m': 499000,
    '1y': 1199000,
  };

  /// Only ever active on the dev flavor.
  static bool get isEnabled => F.appFlavor == Flavor.dev;

  /// Returns placeholders for [requestedIds] the store did not resolve.
  /// Empty on any non-dev flavor, and empty when the store answered fully.
  static List<ProductDetails> fillMissing({
    required Set<String> requestedIds,
    required List<ProductDetails> resolved,
  }) {
    if (!isEnabled) return const [];

    final resolvedIds = resolved.map((product) => product.id).toSet();
    final missing = requestedIds.where((id) => !resolvedIds.contains(id));
    if (missing.isEmpty) return const [];

    final mocks = missing.map(_buildFor).toList();
    LogDev.warning(
      'DEV: no store listing for ${mocks.map((m) => m.id).join(', ')} — '
      'substituting mock products so the paywall can render. '
      'Purchasing these will fail; they are display-only.',
    );
    return mocks;
  }

  static ProductDetails _buildFor(String productId) {
    final rawPrice = _priceFor(productId);
    return ProductDetails(
      id: productId,
      title: productId,
      description: 'DEV mock product',
      price: _format(rawPrice),
      rawPrice: rawPrice,
      currencyCode: 'VND',
      currencySymbol: '₫',
    );
  }

  /// Derives a price from the SKU's period and any `_NNoff` discount suffix,
  /// so a discounted SKU reads as cheaper than its base — otherwise a voucher
  /// swap would look like it changed nothing.
  static double _priceFor(String productId) {
    final id = productId.toLowerCase();
    final base = _basePriceVnd.entries
        .firstWhere(
          (entry) => id.contains(entry.key),
          orElse: () => const MapEntry('1m', 199000),
        )
        .value;

    final discount = RegExp(r'_(\d{1,2})off').firstMatch(id);
    if (discount == null) return base;

    final percent = int.tryParse(discount.group(1) ?? '') ?? 0;
    if (percent <= 0 || percent >= 100) return base;
    // Round to a whole thousand so it reads like a real VND price point.
    return ((base * (100 - percent) / 100) / 1000).round() * 1000;
  }

  static String _format(double amount) {
    final digits = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '$buffer₫';
  }
}
