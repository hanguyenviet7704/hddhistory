import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('IapProductEntity.planPeriodLabel', () {
    test('an annual SKU is named by its own period, not the monthly-equivalent one', () {
      const product = IapProductEntity(productId: 'meup_premium_annual');

      expect(product.planPeriodLabel, l10n.monetization.planPeriodYear);
      expect(product.planPeriodLabel, isNot(product.periodLabel));
    });

    test('a 1y SKU is a year too', () {
      const product = IapProductEntity(productId: 'meup_premium_1y');

      expect(product.planPeriodLabel, l10n.monetization.planPeriodYear);
    });

    test('a quarterly SKU is named a quarter', () {
      const product = IapProductEntity(productId: 'meup_premium_3m');

      expect(product.planPeriodLabel, l10n.monetization.planPeriodQuarter);
    });

    test('a monthly SKU is named a month', () {
      const product = IapProductEntity(productId: 'meup_premium_1month');

      expect(product.planPeriodLabel, l10n.monetization.planPeriodMonth);
    });

    test('a weekly SKU is named a week', () {
      const product = IapProductEntity(productId: 'meup_premium_week');

      expect(product.planPeriodLabel, l10n.monetization.planPeriodWeek);
    });
  });
}
