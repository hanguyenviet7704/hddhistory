part of '../../../output_practice.dart';

@lazySingleton
class OutputPracticeSocketCubit extends Cubit<OutputPracticeSocketState> {
  OutputPracticeSocketCubit(this._repository) : super(const OutputPracticeSocketState()) {
    _joinedSubscription = _repository.onJoinedRoom().listen((_) {
      final roomId = state.activeRoomId;
      _cancelJoinTimeout();
      emit(
        state.copyWith(
          status: OutputPracticeSocketStatus.joined,
          activeRoomId: roomId,
          errorMessage: null,
        ),
      );
    });

    _joinErrorSubscription = _repository.onJoinRoomError().listen((payload) {
      _handleJoinFailure(payload['message']?.toString() ?? payload['content']?.toString());
    });

    _eventSubscription = _repository.onOutputPracticeEvent().listen((event) {
      emit(
        state.copyWith(
          latestEvent: event,
          eventTick: state.eventTick + 1,
        ),
      );
    });
  }

  final IOutputPracticeSocketRepository _repository;
  StreamSubscription<Map<String, dynamic>>? _joinedSubscription;
  StreamSubscription<Map<String, dynamic>>? _joinErrorSubscription;
  StreamSubscription<OutputPracticeAiStreamEvent>? _eventSubscription;
  Timer? _joinTimeoutTimer;

  void connectAndJoin(String roomId, {bool allowRetry = true}) {
    if (roomId.isEmpty) return;

    _cancelJoinTimeout();
    emit(
      state.copyWith(
        status: OutputPracticeSocketStatus.connecting,
        activeRoomId: roomId,
        errorMessage: null,
        latestEvent: null,
        hasRetriedInitialJoin: false,
      ),
    );

    _repository.connect();
    emit(
      state.copyWith(
        status: OutputPracticeSocketStatus.joining,
        activeRoomId: roomId,
      ),
    );
    _repository.joinRoom(roomId);
    _joinTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (allowRetry && !state.hasRetriedInitialJoin) {
        emit(state.copyWith(hasRetriedInitialJoin: true));
        connectAndJoin(roomId, allowRetry: false);
        return;
      }
      _handleJoinFailure('Unable to connect to the practice room.');
    });
  }

  void reconnect() {
    final roomId = state.activeRoomId;
    if (roomId.isEmpty) return;
    connectAndJoin(roomId, allowRetry: false);
  }

  void disconnect({bool leaveRoom = true}) {
    final roomId = state.activeRoomId;
    _cancelJoinTimeout();
    if (leaveRoom && roomId.isNotEmpty) {
      _repository.leaveRoom(roomId);
    }
    _repository.disconnect();
    emit(const OutputPracticeSocketState());
  }

  void _handleJoinFailure(String? message) {
    _cancelJoinTimeout();
    emit(
      state.copyWith(
        status: OutputPracticeSocketStatus.joinFailure,
        errorMessage: message?.trim().isNotEmpty == true ? message!.trim() : 'Unable to connect to the practice room.',
      ),
    );
  }

  void _cancelJoinTimeout() {
    _joinTimeoutTimer?.cancel();
    _joinTimeoutTimer = null;
  }

  @override
  Future<void> close() {
    _cancelJoinTimeout();
    _joinedSubscription?.cancel();
    _joinErrorSubscription?.cancel();
    _eventSubscription?.cancel();
    _repository.disconnect();
    return super.close();
  }
}
