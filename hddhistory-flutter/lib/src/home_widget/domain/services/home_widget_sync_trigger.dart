part of '../../home_widget.dart';

class HomeWidgetSyncTrigger {
  static Timer? _pendingSync;
  static String _pendingChangedCourseId = '';

  const HomeWidgetSyncTrigger._();

  static void requestSync({
    String? localeCode,
    Duration delay = Duration.zero,
    String changedCourseId = '',
  }) {
    final resolvedLocaleCode = localeCode ?? _currentLocaleCode();
    final normalizedChangedCourseId = changedCourseId.trim();
    final effectiveChangedCourseId = normalizedChangedCourseId.isEmpty ? _pendingChangedCourseId : normalizedChangedCourseId;
    _pendingSync?.cancel();
    _pendingSync = null;
    _pendingChangedCourseId = '';

    if (!_canSync()) return;

    if (delay <= Duration.zero) {
      _syncNow(resolvedLocaleCode, effectiveChangedCourseId);
      return;
    }

    _pendingChangedCourseId = effectiveChangedCourseId;
    _pendingSync = Timer(delay, () {
      final pendingChangedCourseId = _pendingChangedCourseId;
      _pendingSync = null;
      _pendingChangedCourseId = '';
      _syncNow(resolvedLocaleCode, pendingChangedCourseId);
    });
  }

  static void requestDebouncedSync({String? localeCode, String changedCourseId = ''}) {
    requestSync(
      localeCode: localeCode,
      delay: const Duration(milliseconds: 400),
      changedCourseId: changedCourseId,
    );
  }

  static void _syncNow(String localeCode, String changedCourseId) {
    if (!_canSync()) return;

    final useCase = AppDI.injector.get<SyncHomeWidgetsUseCase>();
    unawaited(
      useCase(
        HomeWidgetSyncParams(
          localeCode: localeCode,
          changedCourseId: changedCourseId,
        ),
      ).run(),
    );
  }

  static bool _canSync() {
    return AppGlobalValue.accessToken.isNotEmpty && AppDI.injector.isRegistered<SyncHomeWidgetsUseCase>();
  }

  static String _currentLocaleCode() {
    if (AppDI.injector.isRegistered<LocaleCubit>()) {
      return AppDI.injector.get<LocaleCubit>().state.languageCode;
    }
    return AppLocale.vi.languageCode;
  }
}
