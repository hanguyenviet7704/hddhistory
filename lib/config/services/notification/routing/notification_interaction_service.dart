part of '../../services.dart';

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
    LogDev.data(
      '[NotificationInteractionService] publish: '
      'type=${interaction.type} title="${interaction.payload.title}" actionKey=${interaction.actionKey}',
    );
    if (_controller.hasListener) {
      _controller.add(interaction);
    } else {
      LogDev.data('[NotificationInteractionService] queue interaction until listener is attached');
      _pendingInteractions.add(interaction);
    }

    final callback = _config.onInteraction;
    if (callback != null) {
      await callback(interaction);
    }
  }

  Future<void> dispose() => _controller.close();

  void _flushPendingInteractions() {
    if (_controller.hasListener && _pendingInteractions.isNotEmpty) {
      LogDev.data('[NotificationInteractionService] flush pending interactions: count=${_pendingInteractions.length}');
    }
    while (_controller.hasListener && _pendingInteractions.isNotEmpty) {
      _controller.add(_pendingInteractions.removeFirst());
    }
  }
}
