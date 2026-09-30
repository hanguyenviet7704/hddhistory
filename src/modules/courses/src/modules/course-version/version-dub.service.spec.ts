import { VersionDubService } from './version-dub.service';
import { clipTextHash } from '../voiceover/audio-clip.util';

const block = (vi: string) => ({ data: { content: { vi } } });

const theory = (keypointId: string, ...cards: string[]) => ({
  _id: `t-${keypointId}`,
  keypointId,
  type: 'theory',
  index: 0,
  documents: cards.map(text => ({ document: [block(text)] })),
});

const existingClip = (keypointId: string, text: string, voice = 'vi-VN-Hoai') => ({
  keypointId,
  lang: 'vi',
  kind: 'card',
  textHash: clipTextHash(text),
  url: 'https://cdn/have.mp3',
  voice,
  index: 0,
});

const build = (items: any[], clips: any[]) => {
  const tts = {
    synthesizeMp3: jest.fn().mockResolvedValue(Buffer.from('mp3')),
    resolveVoiceName: jest.fn().mockResolvedValue('default-voice'),
  };
  const cloudflare = {
    uploadExternalFile: jest
      .fn()
      .mockImplementation(({ key }: any) =>
        Promise.resolve({ key, url: `https://cdn/${key}` }),
      ),
  };
  const clipRepository = {
    findByKeypointIds: jest.fn().mockResolvedValue(clips),
    insertMissing: jest.fn().mockResolvedValue(0),
  };
  const publishedContentRepository = {
    findAllOfType: jest
      .fn()
      .mockImplementation((_v: string, type: string) =>
        Promise.resolve(type === 'keypoint' ? [{ _id: 'k1', title: {} }] : items),
      ),
  };

  const service = new VersionDubService(
    tts as any,
    cloudflare as any,
    clipRepository as any,
    publishedContentRepository as any,
  );

  return { service, tts, cloudflare, clipRepository, publishedContentRepository };
};

/** The background run resolves on its own; give it a turn of the loop. */
const settle = () => new Promise(resolve => setImmediate(resolve));

describe('VersionDubService', () => {
  it('records only the cards the tag is missing', async () => {
    const { service, tts } = build(
      [theory('k1', 'đã có', 'chưa có')],
      [existingClip('k1', 'đã có')],
    );

    const snapshot = await service.start('c1', 'v1', 'v1.0.1');
    await settle();

    expect(snapshot.total).toBe(1);
    expect(tts.synthesizeMp3).toHaveBeenCalledTimes(1);
    expect(tts.synthesizeMp3.mock.calls[0][0]).toBe('chưa có');
  });

  /**
   * One card read by another narrator is how a keypoint ends up sounding
   * broken while every cell in the grid says `done`.
   */
  it('reuses the narrator its neighbours were read by', async () => {
    const { service, tts } = build(
      [theory('k1', 'đã có', 'chưa có')],
      [existingClip('k1', 'đã có', 'vi-VN-Hoai')],
    );

    await service.start('c1', 'v1', 'v1.0.1');
    await settle();

    expect(tts.synthesizeMp3.mock.calls[0][3]).toBe('vi-VN-Hoai');
    expect(tts.resolveVoiceName).not.toHaveBeenCalled();
  });

  it('falls back to the default narrator when nothing was ever dubbed', async () => {
    const { service, tts } = build([theory('k1', 'chưa có')], []);

    await service.start('c1', 'v1', 'v1.0.1');
    await settle();

    expect(tts.synthesizeMp3.mock.calls[0][3]).toBe('default-voice');
  });

  it('puts the text token in the object key, so it cannot overwrite a tag', async () => {
    const { service, cloudflare } = build([theory('k1', 'chưa có')], []);

    await service.start('c1', 'v1', 'v1.0.1');
    await settle();

    const { key } = cloudflare.uploadExternalFile.mock.calls[0][0];
    expect(key).toMatch(/^voiceover\/k1\/vi\/0-[0-9a-f]{12}\.mp3$/);
  });

  it('saves a row addressed by the text, not by the position', async () => {
    const { service, clipRepository } = build([theory('k1', 'chưa có')], []);

    await service.start('c1', 'v1', 'v1.0.1');
    await settle();

    expect(clipRepository.insertMissing).toHaveBeenCalledWith([
      expect.objectContaining({
        keypointId: 'k1',
        lang: 'vi',
        kind: 'card',
        textHash: clipTextHash('chưa có'),
        voice: 'default-voice',
      }),
    ]);
  });

  it('counts a failed card instead of sinking the run', async () => {
    const { service, tts, clipRepository } = build(
      [theory('k1', 'một', 'hai')],
      [],
    );
    tts.synthesizeMp3
      .mockRejectedValueOnce(new Error('tts down'))
      .mockResolvedValueOnce(Buffer.from('mp3'));

    await service.start('c1', 'v1', 'v1.0.1');
    await settle();

    const snapshot = service.snapshot();
    expect(snapshot.failed).toBe(1);
    expect(snapshot.done).toBe(1);
    // The one that worked is still saved.
    expect(clipRepository.insertMissing.mock.calls[0][0]).toHaveLength(1);
  });

  it('refuses to start a second run on top of a running one', async () => {
    const { service, tts } = build([theory('k1', 'một')], []);
    let release: (v: any) => void = () => undefined;
    tts.synthesizeMp3.mockReturnValue(new Promise(r => (release = r)));

    await service.start('c1', 'v1', 'v1.0.1');
    const second = await service.start('c1', 'v1', 'v1.0.2');

    // Same run, not a second one — two runs would pay for the same audio twice.
    expect(second.tag).toBe('v1.0.1');
    release(Buffer.from('mp3'));
  });

  it('never reads or writes the tag itself', async () => {
    const { service, publishedContentRepository } = build(
      [theory('k1', 'chưa có')],
      [],
    );

    await service.start('c1', 'v1', 'v1.0.1');
    await settle();

    // Reads the frozen content, yes — but only `findAllOfType`. Nothing on this
    // repository that writes is reachable from here.
    for (const call of publishedContentRepository.findAllOfType.mock.calls) {
      expect(['keypoint', 'learningItem']).toContain(call[1]);
    }
  });
});
