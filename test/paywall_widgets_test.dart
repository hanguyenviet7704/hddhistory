import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/l10n/l10n.dart';
import 'package:meup/src/monetization/monetization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.setLocaleSync(AppLocale.en);

  testWidgets('PaywallPlanCard renders sale and popular badges', (tester) async {
    const product = IapProductEntity(
      id: 'premium_monthly',
      price: r'$9.99',
      rawPrice: 9.99,
      currencySymbol: r'$',
      durationType: 'month',
      durationValue: 1,
      planName: 'Monthly',
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body: PaywallPlanCard(
                product: product,
                isSelected: true,
                isMostPopular: true,
                onTap: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('% off'), findsOneWidget);
    expect(find.text('Most popular'), findsOneWidget);
    expect(find.textContaining('per month'), findsWidgets);
    expect(find.textContaining('9.99'), findsWidgets);
  });
}

void _noop() {}
