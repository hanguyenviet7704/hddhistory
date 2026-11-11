part of '../../../common.dart';

/// Persists the user's haptic (vibration) feedback preference and keeps
/// [AppHaptic.enabled] in sync WITHOUT needing a `BuildContext`, so every
/// `AppHaptic.*` call anywhere in the app — including from cubits, services,
/// and code that runs before a Settings screen ever opens — respects it.
@lazySingleton
class HapticSettingCubit extends HydratedCubit<bool> {
  HapticSettingCubit() : super(true) {
    // Applies the restored/persisted value immediately at startup, before
    // this cubit is ever read from a widget.
    AppHaptic.enabled = state;
  }

  void setEnabled(bool value) {
    if (value == state) return;
    emit(value);
  }

  void toggle() => setEnabled(!state);

  @override
  void onChange(Change<bool> change) {
    super.onChange(change);
    AppHaptic.enabled = change.nextState;
  }

  /// Pinned so an obfuscated release build cannot rename the key this
  /// cubit's state is stored under — see [HydrateBlocService].
  @override
  String get storagePrefix => 'HapticSettingCubit';

  @override
  bool fromJson(Map<String, dynamic> json) => json['enabled'] as bool? ?? true;

  @override
  Map<String, dynamic> toJson(bool state) => {'enabled': state};
}
