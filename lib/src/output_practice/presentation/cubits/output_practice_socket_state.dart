part of '../../output_practice.dart';

enum OutputPracticeSocketStatus {
  disconnected,
  connecting,
  joining,
  joined,
  joinFailure,
}

class OutputPracticeSocketState {
  const OutputPracticeSocketState({
    this.status = OutputPracticeSocketStatus.disconnected,
    this.activeRoomId = '',
    this.errorMessage,
    this.latestEvent,
    this.eventTick = 0,
    this.hasRetriedInitialJoin = false,
  });

  final OutputPracticeSocketStatus status;
  final String activeRoomId;
  final String? errorMessage;
  final OutputPracticeAiStreamEvent? latestEvent;
  final int eventTick;
  final bool hasRetriedInitialJoin;

  bool get isJoined => status == OutputPracticeSocketStatus.joined && activeRoomId.isNotEmpty;

  OutputPracticeSocketState copyWith({
    OutputPracticeSocketStatus? status,
    String? activeRoomId,
    Object? errorMessage = _outputPracticeSocketNoValue,
    Object? latestEvent = _outputPracticeSocketNoValue,
    int? eventTick,
    bool? hasRetriedInitialJoin,
  }) {
    return OutputPracticeSocketState(
      status: status ?? this.status,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      errorMessage: errorMessage == _outputPracticeSocketNoValue ? this.errorMessage : errorMessage as String?,
      latestEvent: latestEvent == _outputPracticeSocketNoValue ? this.latestEvent : latestEvent as OutputPracticeAiStreamEvent?,
      eventTick: eventTick ?? this.eventTick,
      hasRetriedInitialJoin: hasRetriedInitialJoin ?? this.hasRetriedInitialJoin,
    );
  }
}

const Object _outputPracticeSocketNoValue = Object();
