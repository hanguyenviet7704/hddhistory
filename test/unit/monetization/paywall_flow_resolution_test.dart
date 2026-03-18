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

  group('resolvePaywallFlowDestination', () {
    test('returns back for standard paywall close', () {
      final destination = resolvePaywallFlowDestination(
        firstTimeUserFlow: false,
        action: PaywallFlowAction.close,
      );

      expect(destination, PaywallFlowDestination.back);
    });

    test('returns back for standard paywall success dismissal', () {
      final destination = resolvePaywallFlowDestination(
        firstTimeUserFlow: false,
        action: PaywallFlowAction.purchaseSuccess,
      );

      expect(destination, PaywallFlowDestination.back);
    });

    test('returns course for first-time paywall close', () {
      final destination = resolvePaywallFlowDestination(
        firstTimeUserFlow: true,
        action: PaywallFlowAction.close,
      );

      expect(destination, PaywallFlowDestination.course);
    });

    test('returns course for first-time paywall success dismissal', () {
      final destination = resolvePaywallFlowDestination(
        firstTimeUserFlow: true,
        action: PaywallFlowAction.purchaseSuccess,
      );

      expect(destination, PaywallFlowDestination.course);
    });
  });

  group('paywall close delay contract', () {
    test('delays close button for first-time paywall flow', () {
      expect(
        shouldDelayPaywallCloseButton(firstTimeUserFlow: true),
        isTrue,
      );
      expect(paywallCloseButtonDelay, const Duration(seconds: 5));
    });

    test('keeps close button immediate for standard paywall flow', () {
      expect(
        shouldDelayPaywallCloseButton(firstTimeUserFlow: false),
        isFalse,
      );
    });
  });

  group('resolvePremiumTrackingSource', () {
    final trackingService = AppTrackingService(NoOpTrackingService());

    test('returns first_time_user for onboarding paywall entry', () {
      expect(
        trackingService.resolvePremiumTrackingSource(PaywallEntryPoint.firstTimeUser),
        'first_time_user',
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
