import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('shouldPreparePaywallAutoOpen', () {
    test('allows enabled eligible non-premium user below rollout bucket', () {
      expect(
        shouldPreparePaywallAutoOpen(
          enabled: true,
          sessionRolloutPercent: 50,
          rolloutBucket: 49,
          isSuppressed: false,
          hasCompletedOnboarding: true,
          userId: 'user-1',
          accessToken: 'token',
          isPremium: false,
        ),
        isTrue,
      );
    });

    test('rejects disabled, zero rollout, and bucket outside rollout', () {
      bool allowed({required bool enabled, required int percent, required int bucket}) {
        return shouldPreparePaywallAutoOpen(
          enabled: enabled,
          sessionRolloutPercent: percent,
          rolloutBucket: bucket,
          isSuppressed: false,
          hasCompletedOnboarding: true,
          userId: 'user-1',
          accessToken: 'token',
          isPremium: false,
        );
      }

      expect(allowed(enabled: false, percent: 100, bucket: 0), isFalse);
      expect(allowed(enabled: true, percent: 0, bucket: 0), isFalse);
      expect(allowed(enabled: true, percent: 50, bucket: 50), isFalse);
      expect(allowed(enabled: true, percent: 100, bucket: 99), isTrue);
    });

    test('rejects suppressed, onboarding-incomplete, unauthenticated, and premium sessions', () {
      bool allowed({
        bool suppressed = false,
        bool completed = true,
        String userId = 'user-1',
        String token = 'token',
        bool premium = false,
      }) {
        return shouldPreparePaywallAutoOpen(
          enabled: true,
          sessionRolloutPercent: 100,
          rolloutBucket: 0,
          isSuppressed: suppressed,
          hasCompletedOnboarding: completed,
          userId: userId,
          accessToken: token,
          isPremium: premium,
        );
      }

      expect(allowed(suppressed: true), isFalse);
      expect(allowed(completed: false), isFalse);
      expect(allowed(userId: ''), isFalse);
      expect(allowed(token: ''), isFalse);
      expect(allowed(premium: true), isFalse);
    });
  });
}
