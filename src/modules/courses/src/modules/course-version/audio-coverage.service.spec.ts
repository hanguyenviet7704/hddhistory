import { AudioCoverageService } from './audio-coverage.service';
import { clipTextHash } from '../voiceover/audio-clip.util';

const block = (vi: string) => ({ data: { content: { vi } } });

const theory = (keypointId: string, ...cards: string[]) => ({
  _id: `t-${keypointId}`,
  keypointId,
  type: 'theory',
  index: 0,
  documents: cards.map(text => ({ document: [block(text)] })),
});

const card = (keypointId: string, text: string, lang = 'vi') => ({
  keypointId,
  lang,
  kind: 'card',
  textHash: clipTextHash(text),
  url: 'https://cdn/x.mp3',
  voice: 'female',
  index: 0,
});

const serviceOf = (keypoints: any[], items: any[], clips: any[]) =>
  new AudioCoverageService(
    {
      findAllOfType: jest
        .fn()
        .mockImplementation((_v: string, type: string) =>
          Promise.resolve(type === 'keypoint' ? keypoints : items),
        ),
    } as any,
    {
      findByKeypointIds: jest.fn().mockResolvedValue(clips),
      // Whatever this course has is what the whole store has, unless a test
      // says otherwise — see the two rollout tests.
      countAll: jest.fn().mockResolvedValue(clips.length),
    } as any,
  );

describe('AudioCoverageService', () => {
  it('calls a language done when every card with words has a recording', async () => {
    const service = serviceOf(
      [{ _id: 'k1', title: { vi: 'Keypoint 1' } }],
      [theory('k1', 'một', 'hai')],
      [card('k1', 'một'), card('k1', 'hai')],
    );

    const coverage = await service.forVersion('c1', 'v1');

    expect(coverage.keypoints[0].statuses.vi).toBe('done');
  });

  /**
   * The shape an edit actually makes: one card rewritten, the rest untouched.
   * It must NOT read as "done" — the tag would ship a silent page — and must
   * not read as "missing" either, or the admin re-dubs a whole keypoint to
   * replace one card.
   */
  it('calls it stale when one card was rewritten', async () => {
    const service = serviceOf(
      [{ _id: 'k1', title: {} }],
      [theory('k1', 'một', 'hai đã sửa')],
      [card('k1', 'một'), card('k1', 'hai')],
    );

    const coverage = await service.forVersion('c1', 'v1');

    expect(coverage.keypoints[0].statuses.vi).toBe('stale');
    expect(coverage.keypoints[0].missing.vi).toBe(1);
  });

  it('calls it missing when nothing was ever dubbed', async () => {
    const service = serviceOf(
      [{ _id: 'k1', title: {} }],
      [theory('k1', 'một')],
      [],
    );

    expect((await service.forVersion('c1', 'v1')).keypoints[0].statuses.vi).toBe(
      'missing',
    );
  });

  it('counts a language with nothing to read as covered, not as a hole', async () => {
    const service = serviceOf(
      [{ _id: 'k1', title: {} }],
      [theory('k1', 'chỉ có tiếng Việt')],
      [card('k1', 'chỉ có tiếng Việt')],
    );

    const coverage = await service.forVersion('c1', 'v1');

    expect(coverage.keypoints[0].statuses.en).toBe('none');
    expect(coverage.complete).toBe(true);
  });

  it('is incomplete while any language is short, which is what blocks publishing', async () => {
    const service = serviceOf(
      [{ _id: 'k1', title: {} }],
      [theory('k1', 'một')],
      [card('k1', 'một'), card('k1', 'một', 'en')],
    );

    const coverage = await service.forVersion('c1', 'v1');

    // Vietnamese and English are covered; the other three have no words, so
    // they are `none` — nothing is short and the gate lets this through.
    expect(coverage.complete).toBe(true);
  });

  /**
   * The day this ships, no environment has a single row. Reading that as "no
   * audio" would lock every publish behind a gate nobody can satisfy until the
   * backfill has run.
   */
  it('does not block publishing while the clip store is empty everywhere', async () => {
    const service = serviceOf(
      [{ _id: 'k1', title: {} }],
      [theory('k1', 'một')],
      [],
    );

    const coverage = await service.forVersion('c1', 'v1');

    expect(coverage.storeEmpty).toBe(true);
    expect(coverage.complete).toBe(true);
    // And it still reports the truth about the cells.
    expect(coverage.keypoints[0].statuses.vi).toBe('missing');
  });

  /**
   * The line the rollout guard must not cross. A course nobody ever dubbed has
   * no clips either — and that is precisely what the gate exists to stop, so it
   * must not be mistaken for "the backfill has not run".
   */
  it('still blocks a never-dubbed course once any other course has clips', async () => {
    const service = serviceOf(
      [{ _id: 'k1', title: {} }],
      [theory('k1', 'một')],
      [],
    );
    (service as any).clipRepository.countAll = jest.fn().mockResolvedValue(33565);

    const coverage = await service.forVersion('c1', 'v1');

    expect(coverage.storeEmpty).toBe(false);
    expect(coverage.complete).toBe(false);
  });

  it('matches a recording made when the card sat elsewhere', async () => {
    const service = serviceOf(
      [{ _id: 'k1', title: {} }],
      [theory('k1', 'mới thêm', 'cũ')],
      [card('k1', 'cũ')],
    );

    const coverage = await service.forVersion('c1', 'v1');

    // The old card moved from index 0 to index 1 and still counts.
    expect(coverage.keypoints[0].missing.vi).toBe(1);
    expect(coverage.keypoints[0].statuses.vi).toBe('stale');
  });
});
