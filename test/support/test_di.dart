import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

/// [LocaleCubit.setLocale] refetches localized server content (HomeCubit,
/// CourseRoadmapCubit) — a DI graph unit tests don't build. Tests only need
/// the slang locale switched and the state emitted.
class _TestLocaleCubit extends LocaleCubit {
  @override
  void setLocale(AppLocale locale) {
    if (locale == state) return;
    LocaleSettings.setLocale(locale);
    emit(locale);
  }
}

/// [LessonAudioCubit]'s constructor wires the OS-transport callbacks, so it
/// resolves the handler at construction time. The real handler owns a
/// `just_audio` player, which cannot exist in a unit test — any playback call
/// a test reaches throws [UnimplementedError] via [Fake], loudly instead of
/// silently.
///
/// Public (not `_Fake…`) so tests can read [entryCues] back off the injector.
class FakeLessonAudioHandler extends Fake implements LessonAudioHandler {
  @override
  void Function()? onOsPause;
  @override
  void Function()? onOsPlay;

  /// Entry-chime taps recorded instead of thrown: the cue is fire-and-forget
  /// chrome around a play intent, and tests asserting the intent flags
  /// ([LessonAudioCubit.listenEngaged], the chime suppression on a bookmarked
  /// position-load) must be able to cross it without hosting a player.
  int entryCues = 0;

  @override
  Future<void> playEntryCue() async {
    entryCues++;
  }
}

class _NoopAppEventService implements IAppEventService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> logAppInstall() async {}

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {}

  @override
  Future<bool> requestTrackingAuthorization() async => false;
}

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

  final localeCubit = _TestLocaleCubit();
  localeCubit.setLocale(locale);
  AppDI.injector.registerSingleton<LocaleCubit>(localeCubit);

  AppDI.injector.registerLazySingleton<LessonAudioHandler>(FakeLessonAudioHandler.new);

  final noopAppEventService = _NoopAppEventService();
  if (!AppDI.injector.isRegistered<IAppEventService>(instanceName: DIKey.facebookAppEventsService)) {
    AppDI.injector.registerSingleton<IAppEventService>(
      noopAppEventService,
      instanceName: DIKey.facebookAppEventsService,
    );
  }
  if (!AppDI.injector.isRegistered<IAppEventService>(instanceName: DIKey.tikTokAppEventService)) {
    AppDI.injector.registerSingleton<IAppEventService>(
      noopAppEventService,
      instanceName: DIKey.tikTokAppEventService,
    );
  }
}

Future<void> resetInjectorForTests() async {
  if (AppDI.injector.isRegistered<LocaleCubit>()) {
    await AppDI.injector.get<LocaleCubit>().close();
  }
  await AppDI.injector.reset();
}
