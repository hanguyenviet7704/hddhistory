part of '../../../coach.dart';

/// Ba sự kiện xem trước mà server phát trong lúc Coach đang viết.
enum CoachStreamEvent {
  /// Bắt đầu một lượt — xoá phần xem trước của lượt cũ nếu còn sót.
  started('coach:started'),

  /// Một mẩu chữ nữa. Không bao giờ chứa câu chốt khi chốt kiểm duyệt còn
  /// đang cân nhắc — phía server đã giữ lại (xem `CoachSentenceHold`).
  chunk('coach:chunk'),

  /// Hết phần xem trước. Câu trả lời thật nằm trong đáp REST.
  ended('coach:ended');

  const CoachStreamEvent(this.value);

  final String value;
}

/// Kênh xem trước của Coach.
///
/// Đây là một thứ **trang trí**, và phải được đối xử như vậy ở mọi dòng bên
/// dưới. Câu trả lời thật — lời đáp, chip, cảnh, bước máy trạng thái — vẫn về
/// bằng REST như xưa nay. Cái chạy qua đây chỉ là chữ, sớm, để người đọc có cái
/// để đọc trong lúc model viết; đáp REST về là phần xem trước bị thay thế.
///
/// Hệ quả cố ý: socket không nối được thì người đọc mất hiệu ứng chứ không mất
/// câu trả lời. Không có retry, không có hàng đợi, không có báo lỗi — một mẩu
/// chữ lỡ nhịp thì không còn nhịp nào đáng chờ nữa.
///
/// Không có `joinRoom`: server tự cho socket vào phòng của chính chủ, lấy từ
/// token đã xác thực. Room do client khai sẽ cho người này đọc được hội thoại
/// của người kia.
@lazySingleton
class CoachStreamDataSource {
  CoachStreamDataSource(@Named(DIKey.socketBaseUrl) this._socketBaseUrl);

  final String _socketBaseUrl;

  final Map<CoachStreamEvent, StreamController<Map<String, dynamic>>> _controllers = {
    for (final event in CoachStreamEvent.values)
      event: StreamController<Map<String, dynamic>>.broadcast(),
  };

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  Stream<Map<String, dynamic>> on(CoachStreamEvent event) => _controllers[event]!.stream;

  /// Mẩu chữ kế tiếp, đã bóc khỏi vỏ payload. Chuỗi rỗng bị bỏ.
  Stream<String> onChunk() => on(CoachStreamEvent.chunk)
      .map((payload) => payload['delta']?.toString() ?? '')
      .where((delta) => delta.isNotEmpty);

  Stream<void> onStarted() => on(CoachStreamEvent.started);

  Stream<void> onEnded() => on(CoachStreamEvent.ended);

  void connect() {
    final token = AppGlobalValue.accessToken.trim();
    // Không có token thì không có gì để nghe: server ngắt kết nối ngay.
    if (token.isEmpty) return;

    _disposeSocket();

    final socket = io.io(
      _socketBaseUrl,
      (io.OptionBuilder()
            ..setTransports(['websocket'])
            ..disableAutoConnect()
            ..enableForceNew()
            ..enableReconnection()
            ..setTimeout(NetworkConstant.connectTimeout)
            ..setExtraHeaders({
              NetworkConstant.contentType: NetworkConstant.contentTypeJson,
              NetworkConstant.authorization: 'Bearer $token',
            }))
          .build(),
    );

    _socket = socket;
    socket.onConnect((_) => LogDev.info('[CoachStream] connected id=${socket.id}'));
    socket.onDisconnect((reason) => LogDev.info('[CoachStream] disconnected reason=$reason'));
    // Log chứ không báo lên trên: không nối được là mất hiệu ứng, không phải lỗi.
    socket.onConnectError((error) => LogDev.warning('[CoachStream] connect error: $error'));
    socket.onError((error) => LogDev.warning('[CoachStream] socket error: $error'));

    for (final event in CoachStreamEvent.values) {
      socket.on(event.value, (payload) {
        _controllers[event]!.add(_normalize(payload));
      });
    }

    socket.connect();
  }

  void disconnect() => _disposeSocket();

  Map<String, dynamic> _normalize(dynamic payload) {
    if (payload == null) return const {};
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    if (payload is List && payload.isNotEmpty) return _normalize(payload.first);
    if (payload is String) return {'delta': payload};

    return const {};
  }

  void _disposeSocket() {
    _socket?.dispose();
    _socket = null;
  }
}
