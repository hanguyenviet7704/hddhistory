import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/config/services/services.dart';

void main() {
  group('NotificationMessageRouter', () {
    const router = NotificationMessageRouter();

    test('builds local requests with deeplink, entity, image, and source metadata', () {
      const payload = NotificationPayload(
        source: NotificationPayloadSource.remote,
        sourceId: '42',
        type: 'lesson',
        title: 'Resume lesson',
        body: 'Continue from chapter 3',
        deeplink: 'hddhistory://lesson/42',
        entityId: 'lesson-42',
        imageUrl: 'https://cdn.example.com/lesson.png',
        raw: <String, dynamic>{'custom': 'value'},
      );

      final request = router.toLocalRequest(payload);

      expect(request.id, 42);
      expect(request.payload[NotificationConstants.payloadDeeplinkKey], 'hddhistory://lesson/42');
      expect(request.payload[NotificationConstants.payloadEntityIdKey], 'lesson-42');
      expect(
        request.payload[NotificationConstants.payloadImageUrlKey],
        'https://cdn.example.com/lesson.png',
      );
      expect(request.payload[NotificationConstants.payloadMessageIdKey], '42');
      expect(request.payload['custom'], 'value');
    });

    test('normalizes oversized source ids into a stable 32-bit local notification id', () {
      const payload = NotificationPayload(
        source: NotificationPayloadSource.remote,
        sourceId: '9223372036854775807',
        title: 'Oversized',
        body: 'ID should be normalized',
      );

      final firstRequest = router.toLocalRequest(payload);
      final secondRequest = router.toLocalRequest(payload);

      expect(firstRequest.id, isNotNull);
      expect(
        firstRequest.id,
        allOf(
          greaterThanOrEqualTo(-0x80000000),
          lessThanOrEqualTo(0x7FFFFFFF),
        ),
      );
      expect(firstRequest.id, secondRequest.id);
    });

    test('flattens nested map payloads from remote messages', () {
      final payload = router.fromRemoteMessage(
        const TransportRemoteMessage(
          data: <String, dynamic>{
            NotificationConstants.payloadNestedMessageKey: <String, dynamic>{
              NotificationConstants.payloadTypeKey: 'promo',
              NotificationConstants.payloadEntityIdKey: 'promo-1',
            },
          },
          messageId: 'remote-1',
          title: 'Promo title',
        ),
        config: const NotificationCoreConfig(),
      );

      expect(payload.type, 'promo');
      expect(payload.entityId, 'promo-1');
      expect(payload.title, 'Promo title');
      expect(payload.raw[NotificationConstants.payloadEntityIdKey], 'promo-1');
    });

    test('hydrates local action body when payload is missing it', () {
      final payload = router.fromLocalAction(
        TransportLocalAction(
          id: 7,
          title: 'Review reminder',
          body: 'Continue your speaking practice',
          payload: const <String, String>{NotificationConstants.payloadTypeKey: 'review'},
          performedAt: DateTime(2026, 3, 17, 9, 0),
        ),
        config: const NotificationCoreConfig(),
      );

      expect(payload.source, NotificationPayloadSource.local);
      expect(payload.sourceId, '7');
      expect(payload.title, 'Review reminder');
      expect(payload.body, 'Continue your speaking practice');
      expect(payload.type, 'review');
    });

    test('flattens nested json-string payloads from remote messages', () {
      final payload = router.fromRemoteMessage(
        const TransportRemoteMessage(
          data: <String, dynamic>{
            NotificationConstants.payloadNestedMessageKey: '{"type":"promo","entityId":"promo-2","deeplink":"hddhistory://promo/2"}',
          },
          messageId: 'remote-2',
        ),
        config: const NotificationCoreConfig(),
      );

      expect(payload.type, 'promo');
      expect(payload.entityId, 'promo-2');
      expect(payload.deeplink, 'hddhistory://promo/2');
      expect(payload.raw[NotificationConstants.payloadEntityIdKey], 'promo-2');
    });
  });
}
