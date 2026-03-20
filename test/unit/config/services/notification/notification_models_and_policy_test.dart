import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/services.dart';

void main() {
  group('Notification models and policy', () {
    test('permission status helpers expose authorization and requestability', () {
      const authorizedState = NotificationPermissionState(
        status: NotificationPermissionStatus.authorized,
        systemNotificationsEnabled: true,
        localNotificationsEnabled: true,
        pushNotificationsEnabled: true,
      );

      expect(NotificationPermissionStatus.authorized.isAuthorized, isTrue);
      expect(NotificationPermissionStatus.provisional.isAuthorized, isTrue);
      expect(NotificationPermissionStatus.denied.isAuthorized, isFalse);
      expect(NotificationPermissionStatus.notDetermined.canRequest, isTrue);
      expect(NotificationPermissionStatus.denied.canRequest, isFalse);
      expect(authorizedState.isAuthorized, isTrue);
    });

    test('payload visibility and copyWith preserve defaults while applying overrides', () {
      const payload = NotificationPayload(
        raw: <String, dynamic>{'type': 'lesson'},
        title: 'Original title',
      );
      final copied = payload.copyWith(
        body: 'Updated body',
        imageUrl: 'https://cdn.example.com/image.png',
      );
      final copiedWithoutBodyOverride = const NotificationPayload(body: 'Existing body').copyWith();

      expect(payload.hasVisibleContent, isTrue);
      expect(
        const NotificationPayload(
          title: '   ',
          body: '   ',
          imageUrl: '   ',
        ).hasVisibleContent,
        isFalse,
      );
      expect(copied.title, 'Original title');
      expect(copied.body, 'Updated body');
      expect(copied.imageUrl, 'https://cdn.example.com/image.png');
      expect(copied.raw['type'], 'lesson');
      expect(copiedWithoutBodyOverride.body, 'Existing body');
    });

    test('token state reports whether a normalized token exists', () {
      const emptyTokenState = NotificationTokenState(token: '   ');
      const validTokenState = NotificationTokenState(token: 'token-123');

      expect(emptyTokenState.hasToken, isFalse);
      expect(validTokenState.hasToken, isTrue);
    });

    test('foreground policy respects config overrides and payload hints', () {
      const policy = NotificationForegroundPolicy();
      const visiblePayload = NotificationPayload(
        raw: <String, dynamic>{NotificationConstants.foregroundRenderKey: 'true'},
        title: 'Visible',
      );

      expect(
        policy.shouldRender(
          payload: visiblePayload,
          config: const NotificationCoreConfig(enableLocal: false),
        ),
        isFalse,
      );
      expect(
        policy.shouldRender(
          payload: const NotificationPayload(),
          config: const NotificationCoreConfig(),
        ),
        isFalse,
      );
      expect(
        policy.shouldRender(
          payload: visiblePayload,
          config: NotificationCoreConfig(
            shouldRenderForegroundNotification: (_) => false,
          ),
        ),
        isFalse,
      );
      expect(
        policy.shouldRender(
          payload: visiblePayload,
          config: const NotificationCoreConfig(),
        ),
        isTrue,
      );
      expect(
        policy.shouldRender(
          payload: const NotificationPayload(
            raw: <String, dynamic>{NotificationConstants.foregroundRenderKey: '0'},
            title: 'Blocked',
          ),
          config: const NotificationCoreConfig(),
        ),
        isFalse,
      );
      expect(
        policy.shouldRender(
          payload: const NotificationPayload(title: 'Fallback'),
          config: const NotificationCoreConfig(),
        ),
        isTrue,
      );
    });
  });
}
