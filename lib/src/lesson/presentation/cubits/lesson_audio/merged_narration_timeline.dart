part of '../../../lesson.dart';

/// Pure cue math for one merged keypoint narration file. Card identity in,
/// file time out — the ONLY place the app converts between the two, so the
/// deck never mirrors backend segment numbering again.
class MergedNarrationTimeline {
  const MergedNarrationTimeline(this.merged);

  final MergedKeypointAudioEntity merged;

  List<MergedAudioCueEntity> get _cues => merged.cues;

  MergedAudioCueEntity? cueAt(int index) => (index < 0 || index >= _cues.length) ? null : _cues[index];

  int endMsOf(int index) {
    final cue = cueAt(index);
    return cue == null ? 0 : cue.startMs + cue.durMs;
  }

  int get lastAudibleCueIndex {
    for (var i = _cues.length - 1; i >= 0; i--) {
      if (_cues[i].durMs > 0) return i;
    }
    return -1;
  }

  /// Smallest AUDIBLE cue index after [index], or [index] when nothing
  /// audible follows — the gate bound then stays where it is.
  int nextAudibleCueAfter(int index) {
    for (var i = index + 1; i < _cues.length; i++) {
      if (_cues[i].durMs > 0) return i;
    }
    return index;
  }

  /// The audible cue [positionMs] falls in. A boundary (or a zero-length gap)
  /// belongs to the NEXT audible cue — the voice is about to read it; past
  /// the last audible cue's end, clamps to that cue.
  int cueIndexAtMs(int positionMs) {
    var lastAudible = -1;
    for (var i = 0; i < _cues.length; i++) {
      final cue = _cues[i];
      if (cue.durMs <= 0) continue;
      if (positionMs < cue.startMs + cue.durMs) return i;
      lastAudible = i;
    }
    return lastAudible;
  }

  /// File-time home of one CARD, or null when the card has nothing audible —
  /// the caller leaves narration alone exactly as the per-card path does for
  /// a missing clip.
  int? cueIndexForCard({required String learningItemId, required int documentIndex}) {
    for (var i = 0; i < _cues.length; i++) {
      final cue = _cues[i];
      if (cue.learningItemId == learningItemId && cue.documentIndex == documentIndex) {
        return cue.durMs > 0 ? i : null;
      }
    }
    return null;
  }
}
