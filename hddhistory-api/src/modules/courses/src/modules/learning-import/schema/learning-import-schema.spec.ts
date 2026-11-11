import { model } from 'mongoose';

import {
  LearningImportJob,
  LearningImportJobSchema,
} from './learning-import-job.schema';
import { UserLesson, UserLessonSchema } from './user-lesson.schema';
import {
  ImportJobStage,
  ImportJobStatus,
  ImportSourceType,
  UserLessonAudioStatus,
} from '../enum/learning-import.enum';

/**
 * Schema validation, offline.
 *
 * `validateSync()` runs every Mongoose validator without touching a database,
 * which makes this whole class of bug testable on a laptop with no Mongo — and
 * that matters here, because it is exactly the class that got through: a
 * nullable field declared with `enum:` had `null` rejected by the enum
 * validator, so `POST /learning-imports` 500'd on the very first document it
 * tried to create. `tsc` cannot see it, a DI boot cannot see it, and the type
 * `ImportJobStage | null` says it is fine.
 */
describe('LearningImportJob schema', () => {
  const JobModel = model<LearningImportJob>(
    'LearningImportJobSpec',
    LearningImportJobSchema,
  );

  function buildJob(overrides: Record<string, unknown> = {}) {
    return new JobModel({
      userId: 'user-1',
      sourceType: ImportSourceType.PDF,
      source: { type: ImportSourceType.PDF, fileKey: 'k', fileName: 'a.pdf' },
      outputLocale: 'vi',
      ...overrides,
    });
  }

  /**
   * The regression. A freshly created job takes `stage`'s default of null, and
   * Mongoose validates defaults too -- so before the fix this threw
   * "`null` is not a valid enum value" and the import died at creation.
   */
  it('accepts a new job, whose stage defaults to null', () => {
    const error = buildJob().validateSync();

    expect(error).toBeUndefined();
  });

  it('accepts stage set back to null when a job stops running', () => {
    const error = buildJob({ stage: null }).validateSync();

    expect(error).toBeUndefined();
  });

  it.each(Object.values(ImportJobStage))('accepts stage %s', stage => {
    expect(buildJob({ stage }).validateSync()).toBeUndefined();
  });

  it('still rejects a stage that is not a real value', () => {
    const error = buildJob({ stage: 'nonsense' }).validateSync();

    expect(error?.errors?.stage).toBeDefined();
  });

  it.each(Object.values(ImportJobStatus))('accepts status %s', status => {
    expect(buildJob({ status }).validateSync()).toBeUndefined();
  });

  it('defaults a new job to queued and counting toward quota', () => {
    const job = buildJob();

    expect(job.status).toBe(ImportJobStatus.QUEUED);
    expect(job.countsTowardQuota).toBe(true);
    expect(job.stage).toBeNull();
  });
});

describe('UserLesson schema', () => {
  const LessonModel = model<UserLesson>('UserLessonSpec', UserLessonSchema);

  function buildLesson(overrides: Record<string, unknown> = {}) {
    return new LessonModel({
      userId: 'user-1',
      outputLocale: 'vi',
      source: { type: ImportSourceType.PDF },
      ...overrides,
    });
  }

  it('accepts a new lesson with no audio yet', () => {
    const lesson = buildLesson();

    expect(lesson.validateSync()).toBeUndefined();
    expect(lesson.audioStatus).toBe(UserLessonAudioStatus.NONE);
    expect(lesson.audio).toBeNull();
  });

  it.each(Object.values(UserLessonAudioStatus))(
    'accepts audioStatus %s',
    audioStatus => {
      expect(buildLesson({ audioStatus }).validateSync()).toBeUndefined();
    },
  );

  it('rejects an audioStatus outside the enum', () => {
    const error = buildLesson({ audioStatus: 'nonsense' }).validateSync();

    expect(error?.errors?.audioStatus).toBeDefined();
  });
});
