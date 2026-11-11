import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  const cues = [
    MergedAudioCueEntity(learningItemId: 't1', documentIndex: 0, startMs: 0, durMs: 4000),
    MergedAudioCueEntity(learningItemId: 't1', documentIndex: 1, startMs: 4000, durMs: 0),
    MergedAudioCueEntity(learningItemId: 't2', documentIndex: 0, startMs: 4000, durMs: 6000),
  ];
  const merged = MergedKeypointAudioEntity(url: 'https://x/m.mp3', durationMs: 10000, cues: cues);
  const timeline = MergedNarrationTimeline(merged);

  group('cueIndexAtMs', () {
    test('start of file is the first cue', () => expect(timeline.cueIndexAtMs(0), 0));
    test('inside the first cue', () => expect(timeline.cueIndexAtMs(3999), 0));
    test('a boundary belongs to the NEXT audible cue, skipping durMs 0', () => expect(timeline.cueIndexAtMs(4000), 2));
    test('past the end clamps to the last audible cue', () => expect(timeline.cueIndexAtMs(999999), 2));
  });

  group('cueIndexForCard', () {
    test('finds an audible card', () {
      expect(timeline.cueIndexForCard(learningItemId: 't2', documentIndex: 0), 2);
    });
    test('a silent card has no cue to point the player at', () {
      expect(timeline.cueIndexForCard(learningItemId: 't1', documentIndex: 1), isNull);
    });
    test('a card that was never dubbed has no cue', () {
      expect(timeline.cueIndexForCard(learningItemId: 'video', documentIndex: 0), isNull);
    });
  });

  test('endMsOf / lastAudibleCueIndex', () {
    expect(timeline.endMsOf(0), 4000);
    expect(timeline.lastAudibleCueIndex, 2);
  });

  test('nextAudibleCueAfter skips silent cues and saturates at the end', () {
    expect(timeline.nextAudibleCueAfter(0), 2); // cue 1 is silent
    expect(timeline.nextAudibleCueAfter(2), 2); // nothing audible after
  });
}
