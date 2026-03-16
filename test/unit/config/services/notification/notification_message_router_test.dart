import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/services.dart';

void main() {
  group('NotificationMessageRouter', () {
    const router = NotificationMessageRouter();

    test('normalizes remote payloads without leaking transport types', () {
      final payload = router.fromRemoteMessage(
        const TransportRemoteMessage(
          data: <String, dynamic>{
            'type': 'lesson',
            'navigate': '/lesson/42',
            'entityId': '42',
            'imageUrl': 'https://cdn.example.com/image.png',
            'message': '{"extra":"nested-value"}',
          },
          messageId: 'msg-1',
          title: 'New lesson',
          body: 'Tap to continue',
        ),
        config: const NotificationCoreConfig(),
      );

      expect(payload.source, NotificationPayloadSource.remote);
      expect(payload.sourceId, 'msg-1');
      expect(payload.type, 'lesson');
      expect(payload.title, 'New lesson');
      expect(payload.body, 'Tap to continue');
      expect(payload.deeplink, '/lesson/42');
      expect(payload.entityId, '42');
      expect(payload.imageUrl, 'https://cdn.example.com/image.png');
      expect(payload.raw['extra'], 'nested-value');
    });

    test('applies payload decoder but keeps default fallback fields', () {
      final payload = router.fromRemoteMessage(
        const TransportRemoteMessage(
          data: <String, dynamic>{'body': 'Raw body'},
          title: 'Raw title',
        ),
        config: NotificationCoreConfig(
          payloadDecoder: (raw) => const NotificationPayload(
            type: 'decoded',
            title: 'Decoded title',
          ),
        ),
      );

      expect(payload.type, 'decoded');
      expect(payload.title, 'Decoded title');
      expect(payload.body, 'Raw body');
      expect(payload.source, NotificationPayloadSource.remote);
    });

    test('maps local actions and rebuilds local requests with normalized payload', () {
      final payload = router.fromLocalAction(
        TransportLocalAction(
          id: 42,
          title: 'Reminder',
          body: 'Review your lesson',
          payload: <String, String>{'type': 'reminder'},
          performedAt: DateTime(2026),
        ),
        config: const NotificationCoreConfig(),
      );
      final request = router.toLocalRequest(payload);

      expect(payload.source, NotificationPayloadSource.local);
      expect(payload.sourceId, '42');
      expect(request.id, 42);
      expect(request.title, 'Reminder');
      expect(request.body, 'Review your lesson');
      expect(request.payload['type'], 'reminder');
      expect(request.payload['source'], 'local');
      expect(request.payload['title'], 'Reminder');
    });
  });
}
