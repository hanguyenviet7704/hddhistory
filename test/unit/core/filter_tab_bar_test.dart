import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  testWidgets('FilterTabBar renders all tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: FilterTabBar(
              tabs: const ['All', 'Feel better', 'Think better'],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Feel better'), findsOneWidget);
    // Third tab may be off-screen in a scrollable list; scroll to it.
    await tester.scrollUntilVisible(find.text('Think better'), 50);
    expect(find.text('Think better'), findsOneWidget);
  });

  testWidgets('FilterTabBar calls onTabSelected on tap', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int tapped = -1;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: FilterTabBar(
              tabs: const ['All', 'Feel better'],
              selectedIndex: 0,
              onTabSelected: (i) => tapped = i,
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Feel better'));
    await tester.tap(find.text('Feel better'));
    expect(tapped, 1);
  });
}
