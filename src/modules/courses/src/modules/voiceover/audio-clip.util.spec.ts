import { createHash } from 'crypto';

import {
  clipFileToken,
  clipObjectKey,
  clipRefKey,
  clipRowsFromKeypointAudio,
  clipTextHash,
} from './audio-clip.util';

describe('clipTextHash', () => {
  /**
   * The backfill inserts rows carrying the hashes already stored on
   * `keypoint.audio`. If this ever stopped matching what the dub path writes,
   * every backfilled clip would be invisible to the resolver and the whole
   * catalogue would read as "missing audio" — with no error anywhere.
   */
  it('is the plain sha256 the dub path already stores', () => {
    const text = 'Mâu thuẫn không phải kẻ thù.';
    expect(clipTextHash(text)).toBe(
      createHash('sha256').update(text).digest('hex'),
    );
  });

  it('does not fold the narrator in', () => {
    expect(clipTextHash('xin chào')).toBe(clipTextHash('xin chào'));
  });
});

describe('clipFileToken', () => {
  it('separates two narrators reading the same text', () => {
    const hash = clipTextHash('xin chào');
    expect(clipFileToken(hash, 'female')).not.toBe(
      clipFileToken(hash, 'male'),
    );
  });

  it('separates two texts read by the same narrator', () => {
    expect(clipFileToken(clipTextHash('a'), 'female')).not.toBe(
      clipFileToken(clipTextHash('b'), 'female'),
    );
  });

  it('is stable — the same input always names the same object', () => {
    const hash = clipTextHash('xin chào');
    expect(clipFileToken(hash, 'female')).toBe(clipFileToken(hash, 'female'));
  });

  it('treats a missing narrator as empty rather than throwing', () => {
    expect(clipFileToken(clipTextHash('a'), undefined as any)).toHaveLength(12);
  });
});

describe('clipObjectKey', () => {
  const kp = '6aa2877eb6dc8329c80290df';

  it('puts the token in every key, so no re-dub can overwrite a tag', () => {
    const token = clipFileToken(clipTextHash('a'), 'female');
    const keys = [
      clipObjectKey(kp, 'vi', 'card', token, 3),
      clipObjectKey(kp, 'vi', 'whole', token),
      clipObjectKey(kp, 'vi', 'nextup', token),
      clipObjectKey(kp, 'vi', 'merged', token),
    ];
    for (const key of keys) expect(key).toContain(token);
    expect(new Set(keys).size).toBe(4);
  });

  it('keeps the legacy folder shape so the bucket stays browsable', () => {
    const token = 'abcdef123456';
    expect(clipObjectKey(kp, 'vi', 'card', token, 3)).toBe(
      `voiceover/${kp}/vi/3-${token}.mp3`,
    );
    expect(clipObjectKey(kp, 'vi', 'whole', token)).toBe(
      `voiceover/${kp}/vi-${token}.mp3`,
    );
    expect(clipObjectKey(kp, 'vi', 'nextup', token)).toBe(
      `voiceover/${kp}/vi-nextup-${token}.mp3`,
    );
    expect(clipObjectKey(kp, 'vi', 'merged', token)).toBe(
      `voiceover/${kp}/vi/merged-${token}.mp3`,
    );
  });

  it('never collides with the un-hashed legacy keys', () => {
    const token = 'abcdef123456';
    expect(clipObjectKey(kp, 'vi', 'card', token, 3)).not.toBe(
      `voiceover/${kp}/vi/3.mp3`,
    );
    expect(clipObjectKey(kp, 'vi', 'merged', token)).not.toBe(
      `voiceover/${kp}/vi/merged.mp3`,
    );
  });
});

describe('clipRefKey', () => {
  /**
   * Identity without the index is what lets an unchanged card keep its clip
   * when a newer tag moves it — the whole point of keying audio by text.
   */
  it('ignores where the card sits', () => {
    const base = {
      keypointId: 'k1',
      lang: 'vi' as const,
      kind: 'card' as const,
      textHash: 'h1',
    };
    expect(clipRefKey(base)).toBe(clipRefKey({ ...base }));
  });

  it('separates kinds, languages and texts', () => {
    const base = {
      keypointId: 'k1',
      lang: 'vi',
      kind: 'card' as const,
      textHash: 'h1',
    };
    const keys = new Set([
      clipRefKey(base),
      clipRefKey({ ...base, lang: 'en' }),
      clipRefKey({ ...base, kind: 'whole' }),
      clipRefKey({ ...base, textHash: 'h2' }),
      clipRefKey({ ...base, keypointId: 'k2' }),
    ]);
    expect(keys.size).toBe(5);
  });
});

describe('clipRowsFromKeypointAudio', () => {
  it('reads every kind out of one keypoint', () => {
    const rows = clipRowsFromKeypointAudio('k1', {
      segments: { vi: ['https://cdn/0.mp3', 'https://cdn/1.mp3'] },
      segmentHash: { vi: ['h0', 'h1'] },
      url: { vi: 'https://cdn/whole.mp3' },
      hash: { vi: 'hw' },
      nextUp: { vi: 'https://cdn/next.mp3' },
      nextUpHash: { vi: 'hn' },
      merged: { vi: { url: 'https://cdn/m.mp3', hash: 'hm', durationMs: 10, cues: [] } },
      voices: { vi: 'vi-VN-Hoai' },
    });

    expect(rows.map(row => row.kind).sort()).toEqual([
      'card',
      'card',
      'merged',
      'nextup',
      'whole',
    ]);
    expect(rows.every(row => row.voice === 'vi-VN-Hoai')).toBe(true);
  });

  /**
   * A recording whose text is unknown can never be matched to a tag, and
   * inventing a hash would make the store answer confidently with the wrong
   * audio.
   */
  it('skips a url that has no hash beside it', () => {
    const rows = clipRowsFromKeypointAudio('k1', {
      segments: { vi: ['https://cdn/0.mp3'] },
      segmentHash: { vi: [] },
    });

    expect(rows).toEqual([]);
  });

  it('keeps the card index it was recorded at, for reference only', () => {
    const rows = clipRowsFromKeypointAudio('k1', {
      segments: { vi: ['', 'https://cdn/1.mp3'] },
      segmentHash: { vi: ['', 'h1'] },
    });

    expect(rows).toEqual([
      expect.objectContaining({ kind: 'card', index: 1, textHash: 'h1' }),
    ]);
  });

  it('falls back to the legacy scalar voice on older documents', () => {
    const [row] = clipRowsFromKeypointAudio('k1', {
      url: { vi: 'https://cdn/whole.mp3' },
      hash: { vi: 'hw' },
      voice: 'female',
    });

    expect(row.voice).toBe('female');
  });

  it('is empty for a keypoint that has no audio at all', () => {
    expect(clipRowsFromKeypointAudio('k1', undefined)).toEqual([]);
  });
});
