import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  testWidgets('renders force update content and forwards update taps', (tester) async {
    var updateTapCount = 0;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, child) => MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
        child: ForceUpdateContent(
          onUpdatePressed: () => updateTapCount += 1,
        ),
      ),
    );

    expect(find.text("We're getting better!"), findsOneWidget);
    expect(find.text('For more features and a better user experience,\nupgrade your app please.'), findsOneWidget);
    expect(find.text('Go to Update'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == AppAsset.images.app.forceUpdateDecor.path,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Go to Update'));
    await tester.pump();

    expect(updateTapCount, 1);
  });
}
