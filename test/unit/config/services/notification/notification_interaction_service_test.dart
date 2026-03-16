import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/notification/notification_core_config.dart';
import 'package:meup/config/services/notification/routing/notification_interaction_service.dart';

void main() {
  group('NotificationInteractionService', () {
    test('flushes queued interactions when a listener attaches', () async {
      final service = NotificationInteractionService();
      final firstInteraction = NotificationInteraction(
        type: NotificationInteractionType.coldStart,
        payload: const NotificationPayload(title: 'Queued'),
        occurredAt: DateTime(2026),
      );
      final received = <NotificationInteraction>[];

      await service.publish(firstInteraction);
      final subscription = service.stream.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(received, <NotificationInteraction>[firstInteraction]);

      await subscription.cancel();
      await service.dispose();
    });

    test('invokes the configured callback for every interaction', () async {
      final service = NotificationInteractionService();
      NotificationInteraction? callbackInteraction;
      final interaction = NotificationInteraction(
        type: NotificationInteractionType.openedApp,
        payload: const NotificationPayload(title: 'Opened'),
        occurredAt: DateTime(2026, 1, 2),
      );

      service.updateConfig(
        NotificationCoreConfig(
          onInteraction: (value) {
            callbackInteraction = value;
          },
        ),
      );

      await service.publish(interaction);

      expect(callbackInteraction, interaction);
      await service.dispose();
    });
  });
}
