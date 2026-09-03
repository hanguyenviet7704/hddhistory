import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

/// The banner's whole behaviour is three booleans read off one recap, and every
/// one of them is silent when wrong — the banner still draws, just in the wrong
/// state. So they are pinned here.
///
/// The "MỚI" pill in particular compares LOCAL CALENDAR DAYS, not a 24-hour
/// window: "today" means today to the reader, and a duration check would keep
/// the pill lit into tomorrow morning for anyone who opened their week in the
/// evening.
WeekRecapEntity _recap({DateTime? viewedAt, DateTime? dismissedAt, String id = 'w1'}) {
  final monday = DateTime(2026, 8, 10);

  return WeekRecapEntity(
    id: id,
    weekNumber: 1,
    weekStart: monday,
    weekEnd: monday.add(const Duration(days: 7)),
    viewedAt: viewedAt,
    dismissedAt: dismissedAt,
  );
}

void main() {
  group('CurrentWeekRecapEntity.shouldShowPopup', () {
    test('is false when the week was too quiet to wrap', () {
      expect(const CurrentWeekRecapEntity().shouldShowPopup, isFalse);
    });

    test('is true for a recap the reader has never been offered', () {
      expect(CurrentWeekRecapEntity(recap: _recap()).shouldShowPopup, isTrue);
    });

    test('is false once the reader opened it', () {
      final current = CurrentWeekRecapEntity(recap: _recap(viewedAt: DateTime.now()));
      expect(current.shouldShowPopup, isFalse);
    });

    test('is muted for the rest of the day "later" was pressed on', () {
      final current = CurrentWeekRecapEntity(recap: _recap(dismissedAt: DateTime.now()));
      expect(current.shouldShowPopup, isFalse);
    });

    test('re-offers the morning after "later" — the spec runs it Mon through Sun', () {
      final current = CurrentWeekRecapEntity(
        recap: _recap(dismissedAt: DateTime.now().subtract(const Duration(days: 1))),
      );
      expect(current.shouldShowPopup, isTrue);
    });

    test('never offers the id-less debug preview — there is nothing to stamp', () {
      final current = CurrentWeekRecapEntity(recap: _recap(id: ''));
      expect(current.shouldShowPopup, isFalse);
    });
  });

  group('CurrentWeekRecapEntity.isBannerNew', () {
    test('is false with no recap at all', () {
      expect(const CurrentWeekRecapEntity().isBannerNew, isFalse);
    });

    test('is true while the recap is still unopened', () {
      expect(CurrentWeekRecapEntity(recap: _recap()).isBannerNew, isTrue);
    });

    test('stays lit on the day the reader opened it', () {
      final now = DateTime.now();
      final earlierToday = DateTime(now.year, now.month, now.day);
      final current = CurrentWeekRecapEntity(recap: _recap(viewedAt: earlierToday));
      expect(current.isBannerNew, isTrue);
    });

    test('stays lit through any number of "later"s — only viewing puts it out', () {
      final current = CurrentWeekRecapEntity(
        recap: _recap(dismissedAt: DateTime.now().subtract(const Duration(days: 3))),
      );
      expect(current.isBannerNew, isTrue);
    });

    test('goes out the next day, not 24 hours later', () {
      // 23:30 yesterday is under 24h ago for most of today, but it is a
      // different calendar day and the pill must be out.
      final now = DateTime.now();
      final lateYesterday = DateTime(now.year, now.month, now.day).subtract(
        const Duration(minutes: 30),
      );
      final current = CurrentWeekRecapEntity(recap: _recap(viewedAt: lateYesterday));
      expect(current.isBannerNew, isFalse);
    });
  });

  group('CurrentWeekRecapEntity.hasArchive', () {
    test('is false before the reader has earned a single recap', () {
      expect(const CurrentWeekRecapEntity().hasArchive, isFalse);
    });

    test('is true from the first one', () {
      expect(const CurrentWeekRecapEntity(archiveCount: 1).hasArchive, isTrue);
    });
  });

  group('WeekRecapMood.fromValue', () {
    test('maps the server 1..3 scale', () {
      expect(WeekRecapMood.fromValue(1), WeekRecapMood.low);
      expect(WeekRecapMood.fromValue(2), WeekRecapMood.ok);
      expect(WeekRecapMood.fromValue(3), WeekRecapMood.good);
    });

    test('a day with no journal has no mood, and no chip', () {
      expect(WeekRecapMood.fromValue(null), isNull);
    });

    test('refuses 0 rather than reading it as the lowest level', () {
      // The scale is 1-based precisely because 0 is falsy in Dart; a 0 arriving
      // here is a bug upstream, not a sad day.
      expect(WeekRecapMood.fromValue(0), isNull);
      expect(WeekRecapMood.fromValue(4), isNull);
    });
  });
}
