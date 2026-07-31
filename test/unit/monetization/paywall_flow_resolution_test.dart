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
      expect(paywallCloseButtonDelay, const Duration(seconds: 5));
    });
  });

  group('resolvePremiumTrackingSource', () {
    final trackingService = AppTrackingService(NoOpTrackingService());

    // Values aligned to the tracking sheet's paywall `source` vocabulary
    // (profile_banner / habit_slot / roadmap / system / theme).
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

    test('maps profile / settingPre entries to profile_banner', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.profile),
        'profile_banner',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.settingPre),
        'profile_banner',
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
