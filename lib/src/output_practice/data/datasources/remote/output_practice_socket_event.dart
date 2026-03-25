part of '../../../output_practice.dart';

enum SocketServerEvent {
  joinedRoom('joinedRoom'),
  joinRoomError('joinRoomError'),
  outputPracticeEvent('output-practice:event')
  ;

  const SocketServerEvent(this.value);

  final String value;
}

enum SocketClientEvent {
  joinRoom('joinRoom'),
  leaveRoom('leaveRoom')
  ;

  const SocketClientEvent(this.value);

  final String value;
}
