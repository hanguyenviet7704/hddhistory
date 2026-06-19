import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('shouldConsumeFirstTimePaywallIntentAfterAuth', () {
    test('consumes explicit or persisted legacy intent without opening paywall directly', () {
      expect(
        shouldConsumeFirstTimePaywallIntentAfterAuth(showPaywallAfterAuth: true),
        isTrue,
      );
      expect(
        shouldConsumeFirstTimePaywallIntentAfterAuth(
          showPaywallAfterAuth: false,
          hasPendingFirstTimePaywallAfterAuth: true,
        ),
        isTrue,
      );
      expect(
        shouldConsumeFirstTimePaywallIntentAfterAuth(showPaywallAfterAuth: false),
        isFalse,
      );
    });
  });
}
