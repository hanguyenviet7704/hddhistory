import { KeypointAudioClipRepository } from './keypoint-audio-clip.repository';

const repositoryWith = (bulkWrite: jest.Mock) =>
  new KeypointAudioClipRepository(
    { bulkWrite } as any,
    {} as any,
  );

describe('KeypointAudioClipRepository.insertMissing', () => {
  /**
   * The bug this replaced: `insertMany({ ordered: false })` throws when one
   * batch carries two rows with the same identity — a keypoint really can hold
   * the same sentence twice — and the duplicate-key error was read as "nothing
   * inserted". A backfill reported 34,428 clips found, 0 written, and no error.
   */
  it('upserts rather than inserting, so a repeated identity is not an error', async () => {
    const bulkWrite = jest.fn().mockResolvedValue({ upsertedCount: 2 });
    const repository = repositoryWith(bulkWrite);

    const written = await repository.insertMissing([
      { keypointId: 'k1', lang: 'vi', kind: 'card', textHash: 'h', voice: 'v' },
      { keypointId: 'k1', lang: 'vi', kind: 'card', textHash: 'h', voice: 'v' },
    ]);

    expect(written).toBe(2);
    const [ops, options] = bulkWrite.mock.calls[0];
    expect(options).toEqual({ ordered: false });
    expect(ops).toHaveLength(2);
    expect(ops[0].updateOne.upsert).toBe(true);
  });

  /** Append-only: a clip already stored must never be rewritten. */
  it('only ever writes on insert', async () => {
    const bulkWrite = jest.fn().mockResolvedValue({ upsertedCount: 0 });
    const repository = repositoryWith(bulkWrite);

    await repository.insertMissing([
      { keypointId: 'k1', lang: 'vi', kind: 'card', textHash: 'h', url: 'u' },
    ]);

    const [ops] = bulkWrite.mock.calls[0];
    expect(Object.keys(ops[0].updateOne.update)).toEqual(['$setOnInsert']);
    expect(ops[0].updateOne.filter).toEqual({
      keypointId: 'k1',
      lang: 'vi',
      kind: 'card',
      textHash: 'h',
      voice: '',
    });
  });

  it('does not go to the database for an empty list', async () => {
    const bulkWrite = jest.fn();

    expect(await repositoryWith(bulkWrite).insertMissing([])).toBe(0);
    expect(bulkWrite).not.toHaveBeenCalled();
  });
});
