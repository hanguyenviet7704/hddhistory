import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/services.dart';

void main() {
  group('NotificationTokenService', () {
    test('publishes callbacks for initial and refreshed tokens', () async {
      final service = NotificationTokenService();
      final callbackEvents = <NotificationTokenState>[];
      final streamEvents = <NotificationTokenState>[];
      final refreshController = StreamController<String>.broadcast(sync: true);
      final subscription = service.stream.listen(streamEvents.add);

      service.updateConfig(
        NotificationCoreConfig(
          onTokenChanged: (tokenState) async {
            callbackEvents.add(tokenState);
          },
        ),
      );

      await service.syncInitialToken(() async => 'initial-token');
      await service.bindRefreshStream(refreshController.stream);
      refreshController.add('refresh-token');
      await Future<void>.delayed(Duration.zero);

      expect(callbackEvents, hasLength(2));
      expect(callbackEvents.first.token, 'initial-token');
      expect(callbackEvents.first.isFromRefresh, isFalse);
      expect(callbackEvents.last.token, 'refresh-token');
      expect(callbackEvents.last.isFromRefresh, isTrue);
      expect(streamEvents, hasLength(1));
      expect(streamEvents.single.token, 'refresh-token');

      await subscription.cancel();
      await refreshController.close();
      await service.dispose();
    });
  });
}
