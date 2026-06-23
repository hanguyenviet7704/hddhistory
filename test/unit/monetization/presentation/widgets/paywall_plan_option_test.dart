import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('PaywallPlanOption', () {
    testWidgets('renders selected styling, hides discount pill, and keeps best-deal badge', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        _wrap(
          PaywallPlanOption(
            selected: true,
            product: const IapProductEntity(
              id: 'annual-row',
              productId: 'meup_premium_annual',
              title: 'Annual',
              price: r'$59.99',
              rawPrice: 59.99,
              currencySymbol: r'$',
              salePercent: 50,
              bestDeal: true,
            ),
          ),
        ),
      );

      expect(find.text('ANNUAL'), findsOneWidget);
      expect(find.text(r'$59.99'), findsOneWidget);
      expect(find.text('-50%'), findsNothing);
      expect(find.text(l10n.monetization.mostPopularBadge.toUpperCase()), findsOneWidget);
      expect(_hasBorderColor(tester, const Color(0xFF4B44CA)), isTrue);
    });

    testWidgets('renders unselected discounted card with discount pill and original price', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        _wrap(
          PaywallPlanOption(
            product: const IapProductEntity(
              id: 'annual-row',
              productId: 'meup_premium_annual',
              price: r'$50',
              rawPrice: 50,
              currencySymbol: r'$',
              salePercent: 50,
              bestDeal: true,
            ),
          ),
        ),
      );

      expect(find.text('ANNUAL'), findsOneWidget);
      expect(find.text(r'$50'), findsOneWidget);
      expect(find.text(r'$100'), findsOneWidget);
      expect(find.text('-50%'), findsOneWidget);
      expect(find.text(l10n.monetization.mostPopularBadge.toUpperCase()), findsOneWidget);
    });

    testWidgets('uses localized period label from product id and calls onTap', (tester) async {
      var tapped = false;
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        _wrap(
          PaywallPlanOption(
            product: const IapProductEntity(
              id: 'monthly-row',
              productId: 'meup_premium_monthly',
              price: r'$9.99',
              rawPrice: 9.99,
              currencySymbol: r'$',
            ),
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('MONTHLY'), findsOneWidget);
      await tester.tap(find.text('MONTHLY'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => TranslationProvider(
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

bool _hasBorderColor(WidgetTester tester, Color color) {
  for (final container in tester.widgetList<Container>(find.byType(Container))) {
    final decoration = container.decoration;
    if (decoration is! BoxDecoration) continue;
    final border = decoration.border;
    if (border is! Border) continue;
    if (border.top.color == color || border.left.color == color || border.right.color == color || border.bottom.color == color) {
      return true;
    }
  }
  return false;
}
