import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meup/meup.dart';

/// The poster's title is two separate faces at two origins (design: a serif
/// "Tuần" plus Billock digits). It rendered as the word ALONE once, silently —
/// nothing throws when half a title goes missing, so both halves are pinned.
void main() {
  // The calendar formats its month through `intl`, which needs its locale data
  // loaded — the app does this at startup (AppService), a test must do it here.
  setUpAll(() => initializeDateFormatting());

  testWidgets('draws both the title word and the zero-padded number', (tester) async {
    final monday = DateTime(2026, 8, 10);
    final recap = WeekRecapEntity(
      id: 'w1',
      weekNumber: 7,
      weekStart: monday,
      weekEnd: monday.add(const Duration(days: 7)),
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 350, height: 622, child: WeekRecapPoster(recap: recap)),
          ),
        ),
      ),
    );

    // The word comes from l10n; the number is always two digits.
    // Three passes paint the same string: the white halo under the ink, the
    // ink, and the thin white trim over it that thins the navy.
    expect(find.text('07'), findsNWidgets(3), reason: 'the Billock number slot');
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').isNotEmpty && w.data != '07',
      ),
      findsWidgets,
      reason: 'the title word and the fixed labels',
    );
  });

  testWidgets('keeps the whole title inside the poster, not clipped off the top', (
    tester,
  ) async {
    final monday = DateTime(2026, 8, 10);
    final recap = WeekRecapEntity(
      id: 'w1',
      weekNumber: 7,
      weekStart: monday,
      weekEnd: monday.add(const Duration(days: 7)),
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 350, height: 622, child: WeekRecapPoster(recap: recap)),
          ),
        ),
      ),
    );

    // Existence alone was not enough: the number rendered fine and was still
    // invisible, because centring it vertically pushed a tall display face above
    // y=0 where the poster's Stack clipped it. Nothing threw.
    //
    // Note the limit of this check — widget tests substitute a stub font, so it
    // pins the SLOT geometry, not what a real display face does with its own
    // ascent. Only the simulator shows that.
    final poster = tester.getRect(find.byType(WeekRecapPoster));
    for (final finder in [find.text('07').first, find.text('Week').first]) {
      final box = tester.getRect(finder);
      expect(
        box.top,
        greaterThanOrEqualTo(poster.top),
        reason: 'title escaped the top edge and would be clipped',
      );
      expect(box.bottom, lessThanOrEqualTo(poster.bottom));
      expect(box.left, greaterThanOrEqualTo(poster.left));
      expect(box.right, lessThanOrEqualTo(poster.right));
    }
  });
}
