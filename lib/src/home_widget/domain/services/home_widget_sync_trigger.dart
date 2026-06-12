part of '../../home_widget.dart';

class HomeWidgetSyncTrigger {
  static Timer? _pendingSync;

  const HomeWidgetSyncTrigger._();

  static void requestSync({
    String? localeCode,
    Duration delay = Duration.zero,
  }) {
    final resolvedLocaleCode = localeCode ?? _currentLocaleCode();
    _pendingSync?.cancel();
    _pendingSync = null;

    if (delay <= Duration.zero) {
      _syncNow(resolvedLocaleCode);
      return;
    }

    _pendingSync = Timer(delay, () {
      _pendingSync = null;
      _syncNow(resolvedLocaleCode);
    });
  }

  static void requestDebouncedSync({String? localeCode}) {
    requestSync(
      localeCode: localeCode,
      delay: const Duration(milliseconds: 400),
    );
  }

  static void _syncNow(String localeCode) {
    if (AppGlobalValue.accessToken.isEmpty) return;
    if (!AppDI.injector.isRegistered<SyncHomeWidgetsUseCase>()) return;

    final useCase = AppDI.injector.get<SyncHomeWidgetsUseCase>();
    unawaited(useCase(HomeWidgetSyncParams(localeCode: localeCode)).run());
  }

  static String _currentLocaleCode() {
    if (AppDI.injector.isRegistered<LocaleCubit>()) {
      return AppDI.injector.get<LocaleCubit>().state.languageCode;
    }
    return AppLocale.en.languageCode;
  }
}
