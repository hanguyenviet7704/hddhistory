part of '../../output_practice.dart';

abstract interface class IOutputPracticeSocketRepository {
  bool get isConnected;

  Stream<Map<String, dynamic>> onJoinedRoom();
  Stream<Map<String, dynamic>> onJoinRoomError();
  Stream<OutputPracticeAiStreamEvent> onOutputPracticeEvent();

  void connect();
  void disconnect();
  void joinRoom(String roomId);
  void leaveRoom(String roomId);
}
