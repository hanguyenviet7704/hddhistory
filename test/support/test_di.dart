import 'package:meup/meup.dart';

class _InMemoryHydratedStorage implements Storage {
  final Map<String, dynamic> _storage = <String, dynamic>{};

  @override
  dynamic read(String key) => _storage[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<void> close() async {}
}

Future<void> setupLocaleCubitForTests({AppLocale locale = AppLocale.en}) async {
  HydratedBloc.storage = _InMemoryHydratedStorage();
  await AppDI.injector.reset();

  final localeCubit = LocaleCubit();
  localeCubit.setLocale(locale);
  AppDI.injector.registerSingleton<LocaleCubit>(localeCubit);
}

Future<void> resetInjectorForTests() async {
  if (AppDI.injector.isRegistered<LocaleCubit>()) {
    await AppDI.injector.get<LocaleCubit>().close();
  }
  await AppDI.injector.reset();
}
