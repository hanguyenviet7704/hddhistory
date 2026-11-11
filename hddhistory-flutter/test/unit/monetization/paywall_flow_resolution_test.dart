import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('shouldHandlePaywallSuccess', () {
    test('returns true for paywall purchase success', () {
      expect(
        shouldHandlePaywallSuccess(
          action: PurchaseAction.purchase,
          origin: PurchaseOrigin.paywall,
        ),
        isTrue,
      );
    });

    test('returns false for paywall restore success', () {
      expect(
        shouldHandlePaywallSuccess(
          action: PurchaseAction.restore,
          origin: PurchaseOrigin.paywall,
        ),
        isFalse,
      );
    });

    test('returns false for non-paywall success origins', () {
      expect(
        shouldHandlePaywallSuccess(
          action: PurchaseAction.purchase,
          origin: PurchaseOrigin.other,
        ),
        isFalse,
      );
    });
  });

  group('paywall close delay contract', () {
    test('delays close button for all paywall entries', () {
      expect(shouldDelayPaywallCloseButton(), isTrue);
      // 2s since 98d539bc (2026-07-16); this pin still said the original 5s
      // and had been failing quietly ever since. Change the constant → change
      // this line CONSCIOUSLY: the delay is a product decision, not a tuning.
      expect(paywallCloseButtonDelay, const Duration(seconds: 2));
    });
  });

  group('resolvePremiumTrackingSource', () {
    final trackingService = AppTrackingService(NoOpTrackingService());

    // Values aligned to the tracking sheet's paywall `source` vocabulary — the
    // "New" tab's red cells (2026-09-16). That pass split `upgrade` into
    // settings_premium_banner / home_premium_button, folded keypoint_locked
    // back into roadmap, named lesson creation course_create, and collapsed the
    // guest/system pair on the auto-open paywall into one auto_open.
    test('reports the app-initiated paywall as auto_open', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.autoOpen),
        'auto_open',
      );
      // The post-onboarding paywall is the same app-initiated open, one screen
      // earlier.
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.onboarding),
        'auto_open',
      );
    });

    test('puts every course-content gate on roadmap', () {
      for (final entry in [
        PaywallEntryPoint.courseRoadmap,
        PaywallEntryPoint.inLesson,
        // The quota locked card lost its own value in the red cells.
        PaywallEntryPoint.keypointLocked,
      ]) {
        expect(trackingService.resolvePremiumTrackingSource(entry), 'roadmap');
      }
    });

    /// Kept deliberately outside the sheet's six (owner, 2026-09-16): a real,
    /// distinct door, and the Habit tab already uses this word.
    test('keeps habit_slot for the habit paywall entry', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.habit),
        'habit_slot',
      );
    });

    /// The split the sheet's own note asks for: "2 event này tách từ 1 event
    /// ban đầu (upgrade)". Reporting both doors as one value again would undo
    /// the only reason the value was split.
    test('splits the old upgrade value into its two doors', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.profile),
        'settings_premium_banner',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.settingPre),
        'settings_premium_banner',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.home),
        'home_premium_button',
      );
    });

    test('maps the theme gate and lesson creation to their own names', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.theme),
        'theme_locked',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.learningImport),
        'course_create',
      );
    });

    test('maps manageSubscription / other entries to system', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.manageSubscription),
        'system',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.other),
        'system',
      );
    });
  });
}
