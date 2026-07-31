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
  }) = _KeypointAudioEntity;

  factory KeypointAudioEntity.fromJson(Map<String, dynamic> json) => _$KeypointAudioEntityFromJson(json);
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
}
