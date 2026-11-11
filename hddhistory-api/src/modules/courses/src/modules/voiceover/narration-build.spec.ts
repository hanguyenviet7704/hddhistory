import { clipTextHash } from './audio-clip.util';
import {
  buildNarrationSegments,
  buildNarrationText,
  readNarrationBlocks,
  stripNarrationHtml,
} from './narration-text.util';

const block = (content: Record<string, string>) => ({ data: { content } });

const theory = (...docs: Array<Record<string, string>[]>) => ({
  type: 'theory',
  documents: docs.map(blocks => ({ document: blocks.map(block) })),
});

const exercise = (...questions: Array<Record<string, string>[]>) => ({
  type: 'exercise',
  questions: questions.map(blocks => ({ document: blocks.map(block) })),
});

describe('stripNarrationHtml', () => {
  it('reads the words, not the markup', () => {
    expect(stripNarrationHtml('<p>Xin <b>chào</b></p><p>bạn</p>')).toBe(
      'Xin chào\nbạn',
    );
  });

  it('decodes the entities the editor emits', () => {
    expect(stripNarrationHtml('a&nbsp;&amp;&nbsp;b')).toBe('a & b');
  });

  it('drops what a voice would name instead of read', () => {
    expect(stripNarrationHtml('<p>Tuyệt vời ✨ “thật” đấy</p>')).toBe(
      'Tuyệt vời thật đấy',
    );
  });
});

describe('buildNarrationSegments', () => {
  it('keeps one entry per card, empty ones included', () => {
    const items = [theory([{ vi: 'thẻ một' }], [{ en: 'chỉ tiếng Anh' }])];

    // Card 2 has nothing in Vietnamese but still occupies index 1 — the app
    // numbers cards the same way, and a shifted index plays a neighbour's clip.
    expect(buildNarrationSegments(items, 'vi')).toEqual(['thẻ một', '']);
  });

  it('dubs an exercise from the question only, one card per question', () => {
    const items = [exercise([{ vi: 'câu hỏi 1' }], [{ vi: 'câu hỏi 2' }])];

    expect(buildNarrationSegments(items, 'vi')).toEqual([
      'câu hỏi 1',
      'câu hỏi 2',
    ]);
  });

  it('walks items in the order given, theory and exercise alike', () => {
    const items = [
      theory([{ vi: 'lý thuyết' }]),
      exercise([{ vi: 'bài tập' }]),
    ];

    expect(buildNarrationSegments(items, 'vi')).toEqual([
      'lý thuyết',
      'bài tập',
    ]);
  });

  it('joins a card built from several blocks', () => {
    const items = [theory([{ vi: 'đoạn một' }, { vi: 'đoạn hai' }])];

    expect(readNarrationBlocks(
      (items[0] as any).documents[0].document,
      'vi',
    )).toBe('đoạn một\n\nđoạn hai');
  });
});

describe('buildNarrationText', () => {
  it('drops empty cards before joining', () => {
    const items = [theory([{ vi: 'một' }], [{ en: 'x' }], [{ vi: 'ba' }])];

    expect(buildNarrationText(items, 'vi')).toBe('một\n\nba');
  });
});

/**
 * The one that actually matters.
 *
 * Every clip in `keypoint_audio_clips` is addressed by the hash of the string
 * these functions produce. If the text drifts by so much as a space, every
 * stored hash stops matching, the whole catalogue reads as "missing audio", and
 * a re-dub silently pays to synthesise audio that already exists. Nothing else
 * in the system would report an error.
 *
 * So the hash is pinned to a literal. A failure here is NOT "update the
 * expected value" — it means the change under test rewrites every hash in the
 * database, and the change needs a backfill plan (or to be undone).
 */
describe('narration hashing (golden)', () => {
  const items = [
    theory([{ vi: '<p>Mâu thuẫn <b>không</b> phải kẻ thù ✨</p>' }]),
    exercise([{ vi: '<p>Bạn thường làm gì khi &quot;nóng&quot; lên?</p>' }]),
  ];

  it('pins the card texts', () => {
    expect(buildNarrationSegments(items, 'vi')).toEqual([
      'Mâu thuẫn không phải kẻ thù',
      'Bạn thường làm gì khi nóng lên?',
    ]);
  });

  it('pins the hashes the clip store is keyed by', () => {
    expect(buildNarrationSegments(items, 'vi').map(clipTextHash)).toEqual([
      'ba1606830a41902715dee796c8c5f53e78cdad73d0c96d7ad498c32694e643c6',
      '5a0ede96390b0d5a56e550cc734f4d2743f57b3e9344d29159efbf0d1580909c',
    ]);
  });
});
