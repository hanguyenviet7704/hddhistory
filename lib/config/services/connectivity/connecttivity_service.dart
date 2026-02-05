part of '../services.dart';

@lazySingleton
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? connectivityStream;

  void init({Function(List<ConnectivityResult>)? onConnectivityChanged}) {
    connectivityStream = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      LogDev.info('Connectivity result: $result');
      onConnectivityChanged?.call(result);
    }); 
  }

  void updateListener(Function(List<ConnectivityResult>) listener) {
    connectivityStream?.cancel();
    init(onConnectivityChanged: listener);
  }
}
