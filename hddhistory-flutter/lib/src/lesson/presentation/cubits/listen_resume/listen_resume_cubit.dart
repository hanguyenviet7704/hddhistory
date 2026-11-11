part of '../../../lesson.dart';

/// One "đang nghe dở" bookmark — the LAST keypoint the reader was listening
/// to and the exact millisecond of its merged narration file. Survives app
/// kill (hydrated); consumed on lesson entry, wiped on keypoint completion.
///
/// Deliberately a single record, not a map: resume is "continue what I was
/// doing", not a library of positions. And deliberately merged-mode only —
/// legacy per-card keypoints have no cue map to land the deck with, so they
/// keep the old read-from-the-top entry.
@lazySingleton
class ListenResumeCubit extends HydratedCubit<ListenResumeState> {
  ListenResumeCubit() : super(ListenResumeState.initial());

  /// A bookmark older than this reads as a stale intention, not a session to
  /// continue — re-entering starts from the top like before.
  static const Duration maxAge = Duration(days: 7);

  /// Null before DI bootstrap (unit tests, early app start) — callers treat
  /// that as "no bookmark", keeping them testable without a container.
  static ListenResumeCubit? get instanceOrNull => AppDI.injector.isRegistered<ListenResumeCubit>() ? AppDI.injector.get<ListenResumeCubit>() : null;

  void record({required String keypointId, required int positionMs}) {
    if (keypointId.isEmpty) return;
    emit(
      ListenResumeState(
        keypointId: keypointId,
        positionMs: positionMs,
        updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  ListenResumeState? recordFor(String keypointId) {
    if (state.keypointId.isEmpty || state.keypointId != keypointId) return null;
    final age = DateTime.now().millisecondsSinceEpoch - state.updatedAtMillis;
    if (age > maxAge.inMilliseconds) return null;
    return state;
  }

  /// Named `clearFor` because [HydratedMixin] already owns `clear()` (wipe
  /// the whole storage bucket) — this only drops a matching bookmark.
  void clearFor(String keypointId) {
    if (state.keypointId != keypointId) return;
    emit(ListenResumeState.initial());
  }

  @visibleForTesting
  void emitForTest(ListenResumeState next) => emit(next);

  /// Pinned so an obfuscated release build cannot rename the key this
  /// cubit's state is stored under — see [HydrateBlocService].
  @override
  String get storagePrefix => 'ListenResumeCubit';

  @override
  ListenResumeState? fromJson(Map<String, dynamic> json) => ListenResumeState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ListenResumeState state) => state.toJson();
}
