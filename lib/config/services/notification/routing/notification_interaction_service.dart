import 'dart:async';
import 'dart:collection';

import '../notification_core_config.dart';

class NotificationInteractionService {
  NotificationInteractionService() {
    _controller = StreamController<NotificationInteraction>.broadcast(
      sync: true,
      onListen: _flushPendingInteractions,
    );
  }

  final Queue<NotificationInteraction> _pendingInteractions = Queue<NotificationInteraction>();
  late final StreamController<NotificationInteraction> _controller;

  NotificationCoreConfig _config = const NotificationCoreConfig();

  Stream<NotificationInteraction> get stream => _controller.stream;

  void updateConfig(NotificationCoreConfig config) {
    _config = config;
    _flushPendingInteractions();
  }

  Future<void> publish(NotificationInteraction interaction) async {
    if (_controller.hasListener) {
      _controller.add(interaction);
    } else {
      _pendingInteractions.add(interaction);
    }

    final callback = _config.onInteraction;
    if (callback != null) {
      await callback(interaction);
    }
  }

  Future<void> dispose() => _controller.close();

  void _flushPendingInteractions() {
    while (_controller.hasListener && _pendingInteractions.isNotEmpty) {
      _controller.add(_pendingInteractions.removeFirst());
    }
  }
}
