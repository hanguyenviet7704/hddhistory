import {
  buildCues,
  computeMergeHash,
  computeTheoryCueSlots,
} from './voiceover-merge.util';

const theory = (id: string, docs: number) => ({
  _id: id,
  type: 'theory',
  documents: Array.from({ length: docs }, () => ({})),
});
const exercise = (id: string, questions: number) => ({
  _id: id,
  type: 'exercise',
  questions: Array.from({ length: questions }, () => ({})),
});
const video = (id: string, docs: number) => ({
  _id: id,
  type: 'video',
  documents: Array.from({ length: docs }, () => ({})),
});

describe('computeTheoryCueSlots', () => {
  it('numbers theory docs the way buildSegments does, skipping exercise questions', () => {
    // exercise first — the exact shape behind "first cards break"
    const items = [exercise('e1', 3), theory('t1', 2)];
    expect(computeTheoryCueSlots(items)).toEqual([
      { segmentIndex: 3, learningItemId: 't1', documentIndex: 0 },
      { segmentIndex: 4, learningItemId: 't1', documentIndex: 1 },
    ]);
  });

  it('video documents occupy segment indexes but produce no slots', () => {
    const items = [theory('t1', 1), video('v1', 2), theory('t2', 1)];
    expect(computeTheoryCueSlots(items)).toEqual([
      { segmentIndex: 0, learningItemId: 't1', documentIndex: 0 },
      { segmentIndex: 3, learningItemId: 't2', documentIndex: 0 },
    ]);
  });
});

describe('buildCues', () => {
  it('accumulates offsets and gives silent cards durMs 0', () => {
    const slots = computeTheoryCueSlots([theory('t1', 3)]);
    const durations = new Map([
      [0, 4000],
      [2, 6000],
    ]); // slot 1 has no clip
    expect(buildCues(slots, durations)).toEqual({
      durationMs: 10000,
      cues: [
        { learningItemId: 't1', documentIndex: 0, startMs: 0, durMs: 4000 },
        { learningItemId: 't1', documentIndex: 1, startMs: 4000, durMs: 0 },
        { learningItemId: 't1', documentIndex: 2, startMs: 4000, durMs: 6000 },
      ],
    });
  });
});

describe('computeMergeHash', () => {
  const slots = computeTheoryCueSlots([theory('t1', 2)]);
  it('is stable for identical inputs', () => {
    expect(computeMergeHash('voiceA', slots, ['h0', 'h1'])).toEqual(
      computeMergeHash('voiceA', slots, ['h0', 'h1']),
    );
  });
  it('changes when the voice changes (same text)', () => {
    expect(computeMergeHash('voiceA', slots, ['h0', 'h1'])).not.toEqual(
      computeMergeHash('voiceB', slots, ['h0', 'h1']),
    );
  });
  it('changes when a card hash changes', () => {
    expect(computeMergeHash('voiceA', slots, ['h0', 'h1'])).not.toEqual(
      computeMergeHash('voiceA', slots, ['h0', 'CHANGED']),
    );
  });
});
