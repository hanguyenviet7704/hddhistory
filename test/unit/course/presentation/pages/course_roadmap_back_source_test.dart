import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('roadmapShowsBackButton', () {
    // Every source a Home entry point passes to setRoadmapSource. Kept as a
    // literal list rather than derived from the widget tree: the bug this guards
    // was a Home card shipping a source string nobody registered, and only an
    // independent list catches that.
    const homeEntryPointSources = [
      'home_continue_learning', // course_card.dart — "Học tiếp nào"
      'home_recommended', // home_page.dart — Recommended strip
      'home_new_today', // home_page.dart — "Khoá học mới hôm nay"
      'onboarding', // onboard_v2_pick_theme_page.dart — first course
    ];

    for (final source in homeEntryPointSources) {
      test('shows a back button for the Home source "$source"', () {
        // Without this, tapping that entry point strands the user on a roadmap
        // with no way back: the roadmap is the ROOT of its own shell branch, so
        // there is nothing on the stack to pop.
        expect(roadmapShowsBackButton(source), isTrue);
        expect(roadmapHomeSources.contains(source), isTrue, reason: 'back must return to the Home tab, not Explore');
      });
    }

    for (final source in roadmapExploreSources) {
      test('shows a back button for the Explore source "$source"', () {
        expect(roadmapShowsBackButton(source), isTrue);
      });
    }

    test('a course opened from a collection list can get back to Explore', () {
      // The collection list is a drill-down FROM Explore and the roadmap is its
      // branch root, so an unregistered source would strand the reader there.
      expect(roadmapShowsBackButton(kRoadmapSourceCollectionList), isTrue);
      expect(roadmapExploreSources.contains(kRoadmapSourceCollectionList), isTrue);
    });

    // The "Tiếp tục học" chip floats above the nav bar on every tab, so it has
    // one source per tab. This is the case that shipped broken once: a bare
    // 'resume_chip' drew no back button and left the reader stuck on the
    // roadmap (owner, 2026-09-16: "thiếu nút back").
    const resumeChipSourcesByTab = {
      kRoadmapSourceResumeChipHome: roadmapHomeSources,
      kRoadmapSourceResumeChipExplore: roadmapExploreSources,
      kRoadmapSourceResumeChipLibrary: roadmapLibrarySources,
      kRoadmapSourceResumeChipHabit: roadmapHabitSources,
    };

    resumeChipSourcesByTab.forEach((source, group) {
      test('resume chip source "$source" has a back button that returns to its own tab', () {
        expect(roadmapShowsBackButton(source), isTrue);
        expect(group.contains(source), isTrue, reason: 'back must return to the tab the chip was tapped on');
      });
    });

    test('shows a back button for the habit detail rail', () {
      // "Đọc thêm" inside the habit detail sheet pops the sheet and .go()s to
      // the roadmap — the sheet is gone and the roadmap is its branch's root,
      // so without this the user is stranded exactly as 'home_new_today' was.
      expect(roadmapShowsBackButton('habit_detail'), isTrue);
    });

    test('shows a back button for a course attached to a community post', () {
      // The attached-course card `.go()`s to the roadmap from the Community
      // branch, so the roadmap is its branch's root with nothing to pop —
      // the same strand as 'home_new_today' and 'habit_detail'.
      expect(roadmapShowsBackButton(kRoadmapSourceCommunityPost), isTrue);
    });

    test('shows NO back button for the Courses-tab default', () {
      // Reaching the roadmap by tapping its own tab (or returning from roleplay)
      // has nothing behind it — a back button there would be a dead end.
      expect(roadmapShowsBackButton('nav_course'), isFalse);
    });

    test('shows NO back button for an unset source', () {
      expect(roadmapShowsBackButton(''), isFalse);
    });

    test('keeps the Home, Explore and Habit sets disjoint', () {
      // A source in two sets would make the back destination ambiguous:
      // _backFromRoadmap checks them in order, so an overlap would silently send
      // the user to whichever set is tested first rather than where they came
      // from.
      expect(roadmapHomeSources.intersection(roadmapExploreSources), isEmpty);
      expect(roadmapHabitSources.intersection(roadmapHomeSources), isEmpty);
      expect(roadmapHabitSources.intersection(roadmapExploreSources), isEmpty);
    });
  });
}
