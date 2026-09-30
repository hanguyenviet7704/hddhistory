import { AudioResolver } from './audio-resolver.service';
import { clipTextHash } from '../voiceover/audio-clip.util';
import { computeMergeHash, computeTheoryCueSlots } from '../voiceover/voiceover-merge.util';

const block = (vi: string) => ({ data: { content: { vi } } });

const theoryItem = (id: string, index: number, ...cards: string[]) => ({
  _id: id,
  keypointId: 'k1',
  type: 'theory',
  index,
  documents: cards.map(text => ({ document: [block(text)] })),
});

const clip = (over: Partial<any>) => ({
  keypointId: 'k1',
  lang: 'vi',
  kind: 'card',
  textHash: '',
  url: '',
  voice: 'female',
  index: -1,
  ...over,
});

const repositoryOf = (clips: any[]) => ({
  findByKeypointIds: jest.fn().mockResolvedValue(clips),
});

describe('AudioResolver', () => {
  it('matches a clip by the text of THIS version, not by position', async () => {
    const items = [theoryItem('t1', 0, 'thẻ một', 'thẻ hai')];
    // Recorded when "thẻ hai" was the FIRST card. The tag under test has it
    // second — keying by text is what lets it still be found.
    const clips = [
      clip({ textHash: clipTextHash('thẻ hai'), url: 'https://cdn/two.mp3', index: 0 }),
    ];
    const resolver = new AudioResolver(repositoryOf(clips) as any);

    const [keypoint] = await resolver.attach([{ _id: 'k1' }], 'v1', async () => items);

    expect(keypoint.audio.segments.vi).toEqual(['', 'https://cdn/two.mp3']);
  });

  it('leaves a card whose text changed empty rather than playing the old clip', async () => {
    const items = [theoryItem('t1', 0, 'chữ đã sửa')];
    const clips = [
      clip({ textHash: clipTextHash('chữ cũ'), url: 'https://cdn/old.mp3' }),
    ];
    const resolver = new AudioResolver(repositoryOf(clips) as any);

    const [keypoint] = await resolver.attach([{ _id: 'k1' }], 'v1', async () => items);

    expect(keypoint.audio.segments.vi ?? []).not.toContain('https://cdn/old.mp3');
  });

  /**
   * The whole reason audio was taken out of the snapshot: the copy frozen in a
   * tag points at urls whose bytes a later re-dub used to overwrite.
   */
  it('discards the audio frozen in the tag', async () => {
    const items = [theoryItem('t1', 0, 'thẻ một')];
    // One clip for this keypoint — enough for the store to "know" it, so the
    // rollout guard below stays out of the way.
    const clips = [
      clip({ textHash: clipTextHash('chữ khác'), url: 'https://cdn/other.mp3' }),
    ];
    const resolver = new AudioResolver(repositoryOf(clips) as any);

    const [keypoint] = await resolver.attach([{ _id: 'k1', audio: { segments: { vi: ['https://cdn/stale.mp3'] } } }], 'v1', async () => items);

    expect(JSON.stringify(keypoint.audio)).not.toContain('stale.mp3');
  });

  /**
   * The day this ships the clip store is empty. Resolving against it would hand
   * every tagged course silence — far worse than the stale-audio bug being
   * fixed — so a keypoint the store has never heard of keeps what the tag
   * froze, exactly as before.
   */
  it('keeps the frozen audio for a keypoint the store has never heard of', async () => {
    const items = [theoryItem('t1', 0, 'thẻ một')];
    const resolver = new AudioResolver(repositoryOf([]) as any);

    const [keypoint] = await resolver.attach(
      [{ _id: 'k1', audio: { segments: { vi: ['https://cdn/frozen.mp3'] } } }],
      'v1',
      async () => items,
    );

    expect(keypoint.audio.segments.vi).toEqual(['https://cdn/frozen.mp3']);
  });

  it('keeps index N meaning card N when a card has no clip', async () => {
    const items = [theoryItem('t1', 0, 'một', 'hai', 'ba')];
    const clips = [
      clip({ textHash: clipTextHash('ba'), url: 'https://cdn/three.mp3' }),
    ];
    const resolver = new AudioResolver(repositoryOf(clips) as any);

    const [keypoint] = await resolver.attach([{ _id: 'k1' }], 'v1', async () => items);

    expect(keypoint.audio.segments.vi).toEqual([
      '',
      '',
      'https://cdn/three.mp3',
    ]);
  });

  it('prefers the newest row when the same text was dubbed twice', async () => {
    const items = [theoryItem('t1', 0, 'một')];
    const hash = clipTextHash('một');
    // Repository contract: oldest first.
    const clips = [
      clip({ textHash: hash, url: 'https://cdn/old-voice.mp3', voice: 'female' }),
      clip({ textHash: hash, url: 'https://cdn/new-voice.mp3', voice: 'male' }),
    ];
    const resolver = new AudioResolver(repositoryOf(clips) as any);

    const [keypoint] = await resolver.attach([{ _id: 'k1' }], 'v1', async () => items);

    expect(keypoint.audio.segments.vi).toEqual(['https://cdn/new-voice.mp3']);
  });

  it('resolves the merged file by recomputing its hash for each known voice', async () => {
    const items = [theoryItem('t1', 0, 'một', 'hai')];
    const slots = computeTheoryCueSlots(items);
    const segmentHashes = [clipTextHash('một'), clipTextHash('hai')];
    const mergeHash = computeMergeHash('female', slots, segmentHashes);
    const clips = [
      clip({ textHash: segmentHashes[0], url: 'https://cdn/1.mp3' }),
      clip({ textHash: segmentHashes[1], url: 'https://cdn/2.mp3' }),
      clip({
        kind: 'merged',
        textHash: mergeHash,
        url: 'https://cdn/merged.mp3',
        durationMs: 4200,
        cues: [{ learningItemId: 't1', documentIndex: 0, startMs: 0, durMs: 2000 }],
      }),
    ];
    const resolver = new AudioResolver(repositoryOf(clips) as any);

    const [keypoint] = await resolver.attach([{ _id: 'k1' }], 'v1', async () => items);

    expect(keypoint.audio.merged.vi).toEqual({
      url: 'https://cdn/merged.mp3',
      durationMs: 4200,
      hash: mergeHash,
      cues: [{ learningItemId: 't1', documentIndex: 0, startMs: 0, durMs: 2000 }],
    });
  });

  it('walks learning items in index order, whatever order they arrive in', async () => {
    const first = theoryItem('t1', 0, 'một');
    const second = { ...theoryItem('t2', 1, 'hai'), _id: 't2' };
    const clips = [
      clip({ textHash: clipTextHash('hai'), url: 'https://cdn/two.mp3' }),
    ];
    const resolver = new AudioResolver(repositoryOf(clips) as any);

    // Reversed on purpose: `findAllOfType` returns insertion order, not index.
    const [keypoint] = await resolver.attach([{ _id: 'k1' }], 'v1', async () => [second, first]);

    expect(keypoint.audio.segments.vi).toEqual(['', 'https://cdn/two.mp3']);
  });

  it('takes the next-up hash from the tag, since this keypoint cannot derive it', async () => {
    const items = [theoryItem('t1', 0, 'một')];
    const clips = [
      clip({ kind: 'nextup', textHash: 'frozen-hash', url: 'https://cdn/next.mp3' }),
    ];
    const resolver = new AudioResolver(repositoryOf(clips) as any);

    const [keypoint] = await resolver.attach([{ _id: 'k1', audio: { nextUpHash: { vi: 'frozen-hash' } } }], 'v1', async () => items);

    expect(keypoint.audio.nextUp.vi).toBe('https://cdn/next.mp3');
  });

  it('does not touch the database again for a keypoint it has already resolved', async () => {
    const items = [theoryItem('t1', 0, 'một')];
    const repository = repositoryOf([
      clip({ textHash: clipTextHash('một'), url: 'https://cdn/1.mp3' }),
    ]);
    const resolver = new AudioResolver(repository as any);
    const loadItems = jest.fn().mockResolvedValue(items);

    await resolver.attach([{ _id: 'k1' }], 'v1', loadItems);
    const [second] = await resolver.attach([{ _id: 'k1' }], 'v1', loadItems);

    // The learning-item read is the expensive half — a whole course's theory
    // bodies in five languages — so the cache has to spare it, not just the
    // clip query.
    expect(loadItems).toHaveBeenCalledTimes(1);
    expect(repository.findByKeypointIds).toHaveBeenCalledTimes(1);
    expect(second.audio.segments.vi).toEqual(['https://cdn/1.mp3']);
  });

  it('caches per version, so two tags of one keypoint never share a result', async () => {
    const repository = repositoryOf([
      clip({ textHash: clipTextHash('một'), url: 'https://cdn/1.mp3' }),
    ]);
    const resolver = new AudioResolver(repository as any);

    await resolver.attach([{ _id: 'k1' }], 'v1', async () => [
      theoryItem('t1', 0, 'một'),
    ]);
    const [other] = await resolver.attach([{ _id: 'k1' }], 'v2', async () => [
      theoryItem('t1', 0, 'chữ khác'),
    ]);

    expect(other.audio.segments.vi ?? []).not.toContain('https://cdn/1.mp3');
  });

  it('does not query when there is nothing to resolve', async () => {
    const repository = repositoryOf([]);
    const resolver = new AudioResolver(repository as any);

    await resolver.attach([], 'v1', async () => []);

    expect(repository.findByKeypointIds).not.toHaveBeenCalled();
  });
});
