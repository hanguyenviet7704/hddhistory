part of '../../course.dart';

@freezed
abstract class KeypointAudioEntity with _$KeypointAudioEntity {
  const factory KeypointAudioEntity({
    BaseMultiLanguage? url,
    BaseMultiLanguage? text,

    /// Per-CARD narration clips keyed by language code: `segments[lang][i]`
    /// narrates card `i` of the keypoint (`''` where a card has no narratable
    /// text, so indexes stay aligned with the cards on screen). The player loads
    /// only the current card's clip, which is what makes the voice land exactly
    /// on the page being read — no guessed timeline, and it can't run ahead into
    /// pages the reader hasn't reached.
    ///
    /// Absent on keypoints dubbed before per-card generation: those still have
    /// [url] (one clip for the whole keypoint) and simply get no per-card sync
    /// until they are re-dubbed.
    Map<String, List<String>>? segments,

    /// The keypoint's THEORY narration as one concatenated file per language,
    /// with a cue map carrying card IDENTITY (learningItemId + documentIndex)
    /// — the backend's authoritative answer to "which second reads which
    /// card", so the app never mirrors segment numbering. Absent until the
    /// keypoint is merged server-side; callers fall back to [segments].
    Map<String, MergedKeypointAudioEntity>? merged,
  }) = _KeypointAudioEntity;

  factory KeypointAudioEntity.fromJson(Map<String, dynamic> json) => _$KeypointAudioEntityFromJson(json);
}

@freezed
abstract class MergedAudioCueEntity with _$MergedAudioCueEntity {
  const factory MergedAudioCueEntity({
    @Default('') String learningItemId,
    @Default(0) int documentIndex,
    @Default(0) int startMs,

    /// 0 for a theory card with no narratable text (image-only) — the card
    /// exists in the map but occupies no time in the file.
    @Default(0) int durMs,
  }) = _MergedAudioCueEntity;

  factory MergedAudioCueEntity.fromJson(Map<String, dynamic> json) => _$MergedAudioCueEntityFromJson(json);
}

@freezed
abstract class MergedKeypointAudioEntity with _$MergedKeypointAudioEntity {
  const factory MergedKeypointAudioEntity({
    @Default('') String url,
    @Default(0) int durationMs,
    @Default([]) List<MergedAudioCueEntity> cues,
  }) = _MergedKeypointAudioEntity;

  factory MergedKeypointAudioEntity.fromJson(Map<String, dynamic> json) => _$MergedKeypointAudioEntityFromJson(json);
}

extension MergedKeypointAudioEntityX on MergedKeypointAudioEntity {
  /// A merged file is only worth switching modes for when it can drive the
  /// deck: a url to play and at least one audible cue to map cards with.
  bool get isUsable => url.isNotEmpty && cues.any((cue) => cue.durMs > 0);
}

extension KeypointAudioEntityExtension on KeypointAudioEntity {
  /// Clips for the active locale, falling back in the same order
  /// [BaseMultiLanguageExtension.text] uses so audio and copy never disagree
  /// about which language a keypoint is being consumed in.
  List<String> get resolvedSegments {
    final byLanguage = segments;
    if (byLanguage == null || byLanguage.isEmpty) return const [];

    final locale = AppDI.injector.get<LocaleCubit>().state;
    final preferred = switch (locale) {
      AppLocale.en => 'en',
      AppLocale.vi => 'vi',
      AppLocale.zh => 'zh',
      AppLocale.ja => 'ja',
      AppLocale.ko => 'ko',
    };

    for (final code in [preferred, 'en', 'vi', 'zh', 'ja', 'ko']) {
      final clips = byLanguage[code];
      if (clips != null && clips.any((clip) => clip.isNotEmpty)) return clips;
    }
    return const [];
  }

  /// The merged whole-keypoint narration for the active locale, or null when
  /// this keypoint has not been merged yet (then callers stay on the per-card
  /// path). Same locale fallback order as [resolvedSegments].
  MergedKeypointAudioEntity? get resolvedMerged {
    final byLanguage = merged;
    if (byLanguage == null || byLanguage.isEmpty) return null;

    final locale = AppDI.injector.get<LocaleCubit>().state;
    final preferred = switch (locale) {
      AppLocale.en => 'en',
      AppLocale.vi => 'vi',
      AppLocale.zh => 'zh',
      AppLocale.ja => 'ja',
      AppLocale.ko => 'ko',
    };

    for (final code in [preferred, 'en', 'vi', 'zh', 'ja', 'ko']) {
      final candidate = byLanguage[code];
      if (candidate != null && candidate.isUsable) return candidate;
    }
    return null;
  }
}
