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

    test('returns auto_open for automatic paywall entry', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.autoOpen),
        'auto_open',
      );
    });

    test('returns course_roadmap for roadmap paywall entry', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.courseRoadmap),
        'course_roadmap',
      );
    });

    test('keeps non-roadmap explicit entries mapped to setting_pre', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.profile),
        'setting_pre',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.manageSubscription),
        'setting_pre',
      );
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.settingPre),
        'setting_pre',
      );
    });
  });
}
