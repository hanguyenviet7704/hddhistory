part of '../../../output_practice.dart';

enum SocketServerEvent {
  joinedRoom('joinedRoom'),
  joinRoomError('joinRoomError'),
  chatStarted('chat:started'),
  chatChunk('chat:chunk'),
  chatEnded('chat:ended'),
  outputPracticeEvent('output-practice:event');

  const SocketServerEvent(this.value);

  final String value;
}
