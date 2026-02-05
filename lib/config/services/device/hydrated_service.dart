part of '../services.dart';

class HydrateBlocService {
  HydrateBlocService._();
  static final HydrateBlocService _instance = HydrateBlocService._();
  static HydrateBlocService get instance => _instance;

  Future<void> initialize() async {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: kIsWeb ? HydratedStorageDirectory.web : HydratedStorageDirectory((await getTemporaryDirectory()).path),
    );
  }
}
