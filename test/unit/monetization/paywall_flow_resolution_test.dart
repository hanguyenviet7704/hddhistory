import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

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

    // Values aligned to the tracking sheet's paywall `source` vocabulary —
    // tab "new" (2026-08) renamed profile_banner → upgrade and theme →
    // theme_locked, and gave the quota locked card its own keypoint_locked.
    test('returns system for automatic paywall entry', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.autoOpen),
        'system',
      );
    });

    test('returns roadmap for roadmap paywall entry', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.courseRoadmap),
        'roadmap',
      );
    });

    test('returns habit_slot for habit paywall entry', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.habit),
        'habit_slot',
      );
    });

    test('maps profile / settingPre entries to upgrade', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.profile),
        'upgrade',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.settingPre),
        'upgrade',
      );
    });

    test('maps the theme and quota locked-card entries to their locked names', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.theme),
        'theme_locked',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.keypointLocked),
        'keypoint_locked',
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
