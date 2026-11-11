import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('IapProductEntity discount helpers', () {
    test('Given a 50 percent sale, When reading original price, Then divides by remaining price ratio', () {
      const product = IapProductEntity(
        productId: 'premium_annual',
        price: r'$50.00',
        rawPrice: 50,
        salePercent: 50,
        currencySymbol: r'$',
      );

      expect(product.hasDiscount, isTrue);
      expect(product.originalPrice, 100);
      expect(product.originalPriceString, r'$100');
    });

    test('Given no sale or invalid sale percent, When reading discount, Then treats price as undiscounted', () {
      for (final salePercent in [0, 100, 150]) {
        final product = IapProductEntity(rawPrice: 50, salePercent: salePercent.toDouble(), currencySymbol: r'$');

        expect(product.hasDiscount, isFalse);
        expect(product.originalPrice, 50);
        expect(product.originalPriceString, r'$50');
      }
    });
  });

  group('IapProductEntity period helpers', () {
    test('Given annual, quarterly, monthly, and weekly IDs, When reading per-period value, Then uses one billing period conversion only', () {
      const annual = IapProductEntity(productId: 'meup_premium_annual', rawPrice: 120, currencySymbol: r'$');
      const quarterly = IapProductEntity(productId: 'meup_premium_quarterly', rawPrice: 60, currencySymbol: r'$');
      const monthly = IapProductEntity(productId: 'meup_premium_monthly', rawPrice: 15, currencySymbol: r'$');
      const weekly = IapProductEntity(productId: 'meup_premium_weekly', rawPrice: 8, currencySymbol: r'$');

      expect(annual.perPeriodValue, 10);
      expect(quarterly.perPeriodValue, 20);
      expect(monthly.perPeriodValue, 15);
      expect(weekly.perPeriodValue, 8);
      expect(annual.pricePerPeriodString, r'$10');
      expect(quarterly.pricePerPeriodString, r'$20');
    });

    test('Given annual price that does not divide evenly, When formatting per-period price, Then rounds display value with currency symbol', () {
      const annual = IapProductEntity(productId: 'meup_premium_annual', rawPrice: 599000, currencyCode: 'VND', currencySymbol: '₫');

      expect(annual.perPeriodValue, closeTo(49916.6667, 0.0001));
      expect(annual.pricePerPeriodString, '₫49,917');
    });

    test('Given discounted price, When formatting original price, Then rounds display value with currency symbol', () {
      const annual = IapProductEntity(productId: 'meup_premium_annual', rawPrice: 50000, salePercent: 50, currencyCode: 'VND', currencySymbol: '₫');

      expect(annual.originalPriceString, '₫100,000');
    });
  });
}
