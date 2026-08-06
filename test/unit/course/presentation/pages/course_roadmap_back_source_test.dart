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

    test('shows NO back button for the Courses-tab default', () {
      // Reaching the roadmap by tapping its own tab (or returning from roleplay)
      // has nothing behind it — a back button there would be a dead end.
      expect(roadmapShowsBackButton('nav_course'), isFalse);
    });

    test('shows NO back button for an unset source', () {
      expect(roadmapShowsBackButton(''), isFalse);
    });

    test('keeps the Home and Explore sets disjoint', () {
      // A source in both sets would make the back destination ambiguous:
      // _backFromRoadmap checks the Home set first, so an overlap would silently
      // send an Explore-opened roadmap back to Home instead.
      expect(roadmapHomeSources.intersection(roadmapExploreSources), isEmpty);
    });
  });
}
