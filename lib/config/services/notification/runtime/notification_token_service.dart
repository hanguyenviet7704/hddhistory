part of '../../services.dart';

class NotificationTokenService {
  NotificationTokenService();

  final StreamController<NotificationTokenState> _controller = StreamController<NotificationTokenState>.broadcast(sync: true);

  NotificationCoreConfig _config = const NotificationCoreConfig();
  NotificationTokenState _tokenState = const NotificationTokenState();
  StreamSubscription<String>? _refreshSubscription;

  Stream<NotificationTokenState> get stream => _controller.stream;
  String? get currentToken => _tokenState.hasToken ? _tokenState.token : null;

  void updateConfig(NotificationCoreConfig config) {
    _config = config;
  }

  Future<void> syncInitialToken(Future<String?> Function() getToken) async {
    LogDev.data('[NotificationTokenService] syncInitialToken');
    final token = await getToken();
    await _publishToken(token, isFromRefresh: false, emitToStream: false);
  }

  Future<void> bindRefreshStream(Stream<String> refreshStream) async {
    LogDev.data('[NotificationTokenService] bindRefreshStream');
    await _refreshSubscription?.cancel();
    _refreshSubscription = refreshStream.listen((token) {
      unawaited(_publishToken(token, isFromRefresh: true, emitToStream: true));
    });
  }

  Future<void> dispose() async {
    LogDev.data('[NotificationTokenService] dispose');
    await _refreshSubscription?.cancel();
    await _controller.close();
  }

  Future<void> _publishToken(
    String? token, {
    required bool isFromRefresh,
    required bool emitToStream,
  }) async {
    final normalizedToken = token?.trim();
    if (normalizedToken == null || normalizedToken.isEmpty) {
      LogDev.warning('[NotificationTokenService] publishToken skipped: empty token');
      return;
    }

    _tokenState = NotificationTokenState(
      token: normalizedToken,
      updatedAt: DateTime.now(),
      isFromRefresh: isFromRefresh,
    );
    LogDev.info(
      '[NotificationTokenService] token updated: '
      'source=${isFromRefresh ? 'refresh' : 'initial'} \r\nlength=${normalizedToken.length}\r\ntoken=$normalizedToken',
    );

    if (emitToStream && !_controller.isClosed) {
      _controller.add(_tokenState);
    }

    final callback = _config.onTokenChanged;
    if (callback != null) {
      await callback(_tokenState);
    }
  }
}
