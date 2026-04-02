part of '../../output_practice.dart';

@LazySingleton(as: IOutputPracticeSocketRepository)
class OutputPracticeSocketRepository implements IOutputPracticeSocketRepository {
  OutputPracticeSocketRepository(this._dataSource);

  final OutputPracticeSocketDataSource _dataSource;

  @override
  bool get isConnected => _dataSource.isConnected;

  @override
  Stream<Map<String, dynamic>> onJoinedRoom() => _dataSource.onJoinedRoom();

  @override
  Stream<Map<String, dynamic>> onJoinRoomError() => _dataSource.onJoinRoomError();

  @override
  Stream<OutputPracticeAiStreamEvent> onOutputPracticeEvent() => _dataSource.onOutputPracticeEvent();

  @override
  void connect() => _dataSource.connect();

  @override
  void disconnect() => _dataSource.disconnect();

  @override
  void joinRoom(String roomId) => _dataSource.joinRoom({'room': roomId});

  @override
  void leaveRoom(String roomId) => _dataSource.leaveRoom({'room': roomId});
}
