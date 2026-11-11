part of '../../../output_practice.dart';

@lazySingleton
class OutputPracticeSocketDataSource {
  OutputPracticeSocketDataSource(@Named(DIKey.socketBaseUrl) this._socketBaseUrl);

  final String _socketBaseUrl;
  final Map<SocketServerEvent, StreamController<Map<String, dynamic>>> _eventControllers = {
    for (final event in SocketServerEvent.values) event: StreamController<Map<String, dynamic>>.broadcast(),
  };

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;
  io.Socket? get socket => _socket;

  Stream<Map<String, dynamic>> onRawEvent(SocketServerEvent event) => _eventControllers[event]!.stream;

  Stream<Map<String, dynamic>> onJoinedRoom() => onRawEvent(SocketServerEvent.joinedRoom);

  Stream<Map<String, dynamic>> onJoinRoomError() => onRawEvent(SocketServerEvent.joinRoomError);

  Stream<OutputPracticeAiStreamEvent> onOutputPracticeEvent() => onRawEvent(SocketServerEvent.outputPracticeEvent).map(_toStreamEvent);

  void connect({
    Map<String, dynamic>? query,
    Map<String, dynamic>? auth,
    Map<String, String>? extraHeaders,
    String? path,
  }) {
    _disposeSocket();

    final token = AppGlobalValue.accessToken.trim();
    final headers = <String, String>{
      NetworkConstant.contentType: NetworkConstant.contentTypeJson,
      if (token.isNotEmpty) NetworkConstant.authorization: 'Bearer $token',
      ...?extraHeaders,
    };
    final authPayload = <String, dynamic>{
      if (token.isNotEmpty) 'token': token,
      if (token.isNotEmpty) NetworkConstant.authorization: 'Bearer $token',
      ...?auth,
    };

    final optionsBuilder = io.OptionBuilder()
      ..setTransports(['websocket'])
      ..disableAutoConnect()
      ..enableForceNew()
      ..enableReconnection()
      ..setTimeout(NetworkConstant.connectTimeout)
      ..setExtraHeaders(headers);

    if (query?.isNotEmpty ?? false) {
      optionsBuilder.setQuery(query!);
    }
    if (authPayload.isNotEmpty) {
      optionsBuilder.setAuth(authPayload);
    }
    if (path?.trim().isNotEmpty ?? false) {
      optionsBuilder.setPath(path!.trim());
    }

    final socket = io.io(_socketBaseUrl, optionsBuilder.build());
    _socket = socket;
    _registerSocketListeners(socket);
    socket.connect();
  }

  void joinRoom(Map<String, dynamic> payload) => emit(SocketClientEvent.joinRoom.value, payload);

  void leaveRoom(Map<String, dynamic> payload) => emit(SocketClientEvent.leaveRoom.value, payload);

  void emit(String event, [dynamic payload]) {
    final currentSocket = _socket;
    if (currentSocket == null) {
      LogDev.warning('[OutputPracticeSocket] emit skipped: socket not initialized for event=$event');
      return;
    }

    currentSocket.emit(event, payload);
  }

  void disconnect() => _disposeSocket();

  void dispose() {
    _disposeSocket();
    for (final controller in _eventControllers.values) {
      controller.close();
    }
  }

  void _registerSocketListeners(io.Socket socket) {
    socket.onConnect((_) => LogDev.info('[OutputPracticeSocket] connected id=${socket.id}'));
    socket.onDisconnect((reason) => LogDev.info('[OutputPracticeSocket] disconnected reason=$reason'));
    socket.onConnectError((error) => LogDev.error('[OutputPracticeSocket] connect error: $error'));
    socket.onError((error) => LogDev.error('[OutputPracticeSocket] socket error: $error'));

    for (final event in SocketServerEvent.values) {
      socket.on(event.value, (payload) {
        _eventControllers[event]!.add(_normalizePayload(payload));
      });
    }
  }

  OutputPracticeAiStreamEvent _toStreamEvent(Map<String, dynamic> payload) {
    if (payload.isEmpty) {
      return const OutputPracticeAiStreamEvent.unknown();
    }

    try {
      return OutputPracticeAiStreamEvent.fromJson(payload);
    } catch (_) {
      return OutputPracticeAiStreamEvent.unknown(type: payload['type']?.toString() ?? '');
    }
  }

  Map<String, dynamic> _normalizePayload(dynamic payload) {
    if (payload == null) return const {};
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return payload.map((key, value) => MapEntry(key.toString(), value));
    if (payload is List && payload.isNotEmpty) return _normalizePayload(payload.first);
    if (payload is String) {
      try {
        final decoded = jsonDecode(payload);
        return _normalizePayload(decoded);
      } catch (_) {
        return {'content': payload};
      }
    }
    return {'value': payload};
  }

  void _disposeSocket() {
    _socket?.dispose();
    _socket = null;
  }
}
