import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/l10n/l10n.g.dart';
import 'package:meup/src/monetization/monetization.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

Widget _wrapWithProviders(Widget child) {
  LocaleSettings.setLocale(AppLocale.en);
  return TranslationProvider(
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaywallPackageCard', () {
    testWidgets('shows sale badge for monthly id', (tester) async {
      final product = IapProductEntity(
        id: 'monthly_premium',
        price: r'$9.99',
        rawPrice: 9.99,
        planName: 'Monthly',
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          SizedBox(
            width: 320,
            child: PaywallPackageCard(
              product: product,
              selected: true,
              onTap: () {},
              showMostPopular: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('% off'), findsOneWidget);
      expect(find.textContaining('popular'), findsOneWidget);
    });
  });

  group('PaywallReviewCarousel', () {
    testWidgets('renders page indicator count matching feedback items', (tester) async {
      final controller = PageController();
      final feedbacks = [
        FeedbackContent(userName: 'A', title: 'Great', description: 'Nice', stars: 5),
        FeedbackContent(userName: 'B', title: 'Ok', description: 'Good', stars: 4),
      ];

      await tester.pumpWidget(
        _wrapWithProviders(
          SizedBox(
            height: 320,
            child: PaywallReviewCarousel(
              controller: controller,
              title: 'Reviews',
              feedbacks: feedbacks,
            ),
          ),
        ),
      );

      expect(find.byType(SmoothPageIndicator), findsOneWidget);
      final indicator = tester.widget(find.byType(SmoothPageIndicator)) as SmoothPageIndicator;
      expect(indicator.count, feedbacks.length);
    });
  });
}
