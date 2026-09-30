import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

import archiver from 'archiver';
import ExcelJS from 'exceljs';

import { ITranslation } from '@utils/interface/common.interface';
import { R2Service } from 'src/modules/file/cloudflare/config/r2.config';

import { UserProgressExportStatus } from './enum/user-progress-export.enum';
import { UserProgressRepository } from './repository/user-progress.repository';
import { UserProgressExport } from './schema/user-progress-export.schema';
import { UserProgress } from './schema/user-progress.schema';
import { CourseRepository } from '../../../../course/repository/course.repository';
import { KeypointRepository } from '../../../../keypoint/repository/keypoint.repository';
import { LessonType } from '../../../../lesson/enum/lesson.enum';
import { LessonRepository } from '../../../../lesson/repository/lesson.repository';

import type { UserFeedbackRepository } from '../../../../feedback/user-feedback/repository/user-feedback.repository';
import type { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

export const EXPORT_JOB_NAME = 'all-user-progress';
export const EXPORT_FILE_KEY = 'exports/user-progress.zip';
export const EXPORT_XLSX_NAME = 'user-progress.xlsx';
export const EXPORT_ZIP_NAME = 'user-progress.zip';
export const EXPORT_SHEET_NAME = 'user-progress';
export const EXPORT_USERS_SHEET_NAME = 'users';
export const EXPORT_BATCH_SIZE = 500;
export const EXPORT_COOLDOWN_MS = 5 * 60 * 1000;

export type ExportLessonInfo = {
  title?: ITranslation;
  type?: LessonType;
  courseId?: string;
  keypoints?: Set<string>;
};

export type ExportCache = {
  course: Map<string, ITranslation>;
  lesson: Map<string, ExportLessonInfo>;
  keypoint: Map<string, ITranslation>;
};

export type ExportProgressDoc = Pick<UserProgress, 'userId' | 'courseId'> & {
  lessonsResult?: UserProgress['lessonsResult'];
};

type ExportArchiveOptions = {
  userProgressRepository: UserProgressRepository;
  courseRepository: CourseRepository;
  lessonRepository: LessonRepository;
  keypointRepository: KeypointRepository;
  userFeedbackRepository: UserFeedbackRepository;
  userRepository: UserRepository;
  r2Service: R2Service;
  lang?: string;
  fileKey?: string;
  batchSize?: number;
};

type ExportBatchOptions = {
  worksheet: ExcelJS.Worksheet;
  batch: ExportProgressDoc[];
  cache: ExportCache;
  courseRepository: CourseRepository;
  lessonRepository: LessonRepository;
  keypointRepository: KeypointRepository;
  lang?: string;
};

type FeedbackMapOptions = {
  userFeedbackRepository: UserFeedbackRepository;
  batchSize: number;
};

export async function buildExportArchive(
  options: ExportArchiveOptions,
): Promise<{ key: string; url: string }> {
  const {
    userProgressRepository,
    courseRepository,
    lessonRepository,
    keypointRepository,
    userFeedbackRepository,
    userRepository,
    r2Service,
    lang,
    fileKey = EXPORT_FILE_KEY,
    batchSize = EXPORT_BATCH_SIZE,
  } = options;

  const tempDir = await fs.promises.mkdtemp(
    path.join(os.tmpdir(), 'user-progress-export-'),
  );
  const xlsxPath = path.join(tempDir, EXPORT_XLSX_NAME);
  const zipPath = path.join(tempDir, EXPORT_ZIP_NAME);

  try {
    const workbook = new ExcelJS.stream.xlsx.WorkbookWriter({
      filename: xlsxPath,
      useStyles: false,
      useSharedStrings: true,
    });
    const progressWorksheet = workbook.addWorksheet(EXPORT_SHEET_NAME);
    const usersWorksheet = workbook.addWorksheet(EXPORT_USERS_SHEET_NAME);

    progressWorksheet.columns = [
      { header: 'userId', key: 'userId' },
      { header: 'courseId', key: 'courseId' },
      { header: 'courseTitle', key: 'courseTitle' },
      { header: 'lessonId', key: 'lessonId' },
      { header: 'lessonTitle', key: 'lessonTitle' },
      { header: 'lessonType', key: 'lessonType' },
      { header: 'lessonAverageScore', key: 'lessonAverageScore' },
      { header: 'lessonPassed', key: 'lessonPassed' },
      { header: 'lessonSubmittedAt', key: 'lessonSubmittedAt' },
      { header: 'keypointId', key: 'keypointId' },
      { header: 'keypointTitle', key: 'keypointTitle' },
      { header: 'keypointAverageScore', key: 'keypointAverageScore' },
      { header: 'keypointPassed', key: 'keypointPassed' },
      { header: 'keypointSubmittedAt', key: 'keypointSubmittedAt' },
      { header: 'exerciseId', key: 'exerciseId' },
      { header: 'exerciseType', key: 'exerciseType' },
      { header: 'exerciseForm', key: 'exerciseForm' },
      { header: 'exerciseScore', key: 'exerciseScore' },
      { header: 'exercisePassed', key: 'exercisePassed' },
      { header: 'exerciseIndex', key: 'exerciseIndex' },
    ];

    usersWorksheet.columns = [
      { header: 'userId', key: 'userId' },
      { header: 'userName', key: 'userName' },
      { header: 'userEmail', key: 'userEmail' },
      { header: 'anonymous', key: 'anonymous' },
      { header: 'createdAt', key: 'createdAt' },
      { header: 'hasProgress', key: 'hasProgress' },
      { header: 'roleplayCompleteCourseId', key: 'roleplayCompleteCourseId' },
      { header: 'roleplayCompleteLessonId', key: 'roleplayCompleteLessonId' },
      {
        header: 'roleplayCompleteKeypointId',
        key: 'roleplayCompleteKeypointId',
      },
      {
        header: 'roleplayCompleteContentRating',
        key: 'roleplayCompleteContentRating',
      },
      {
        header: 'roleplayCompleteExperienceRating',
        key: 'roleplayCompleteExperienceRating',
      },
      {
        header: 'roleplayCompleteOverallRating',
        key: 'roleplayCompleteOverallRating',
      },
      { header: 'roleplayCompleteComment', key: 'roleplayCompleteComment' },
      {
        header: 'roleplayCompleteSubmittedAt',
        key: 'roleplayCompleteSubmittedAt',
      },
      {
        header: 'roleplayIncompleteCourseId',
        key: 'roleplayIncompleteCourseId',
      },
      {
        header: 'roleplayIncompleteLessonId',
        key: 'roleplayIncompleteLessonId',
      },
      {
        header: 'roleplayIncompleteKeypointId',
        key: 'roleplayIncompleteKeypointId',
      },
      {
        header: 'roleplayIncompleteReasons',
        key: 'roleplayIncompleteReasons',
      },
      { header: 'roleplayIncompleteComment', key: 'roleplayIncompleteComment' },
      {
        header: 'roleplayIncompleteSubmittedAt',
        key: 'roleplayIncompleteSubmittedAt',
      },
      { header: 'keypointCompleteCourseId', key: 'keypointCompleteCourseId' },
      { header: 'keypointCompleteLessonId', key: 'keypointCompleteLessonId' },
      {
        header: 'keypointCompleteKeypointId',
        key: 'keypointCompleteKeypointId',
      },
      {
        header: 'keypointCompleteContentRating',
        key: 'keypointCompleteContentRating',
      },
      {
        header: 'keypointCompleteExperienceRating',
        key: 'keypointCompleteExperienceRating',
      },
      {
        header: 'keypointCompleteOverallRating',
        key: 'keypointCompleteOverallRating',
      },
      { header: 'keypointCompleteComment', key: 'keypointCompleteComment' },
      {
        header: 'keypointCompleteSubmittedAt',
        key: 'keypointCompleteSubmittedAt',
      },
      {
        header: 'keypointIncompleteCourseId',
        key: 'keypointIncompleteCourseId',
      },
      {
        header: 'keypointIncompleteLessonId',
        key: 'keypointIncompleteLessonId',
      },
      {
        header: 'keypointIncompleteKeypointId',
        key: 'keypointIncompleteKeypointId',
      },
      {
        header: 'keypointIncompleteReasons',
        key: 'keypointIncompleteReasons',
      },
      { header: 'keypointIncompleteComment', key: 'keypointIncompleteComment' },
      {
        header: 'keypointIncompleteSubmittedAt',
        key: 'keypointIncompleteSubmittedAt',
      },
    ];

    const cache: ExportCache = {
      course: new Map<string, ITranslation>(),
      lesson: new Map<string, ExportLessonInfo>(),
      keypoint: new Map<string, ITranslation>(),
    };

    const progressUserIds = new Set<string>();

    const cursor = userProgressRepository.model
      .find({}, { userId: 1, courseId: 1, lessonsResult: 1 })
      .lean()
      .cursor({ batchSize });

    let batch: ExportProgressDoc[] = [];
    for await (const progress of cursor) {
      if ((progress as any)?.userId) {
        progressUserIds.add(String((progress as any).userId));
      }
      batch.push(progress as ExportProgressDoc);
      if (batch.length >= batchSize) {
        await appendExportBatch({
          worksheet: progressWorksheet,
          batch,
          cache,
          courseRepository,
          lessonRepository,
          keypointRepository,
          lang,
        });
        batch = [];
      }
    }

    if (batch.length) {
      await appendExportBatch({
        worksheet: progressWorksheet,
        batch,
        cache,
        courseRepository,
        lessonRepository,
        keypointRepository,
        lang,
      });
    }

    progressWorksheet.commit();

    const feedbackByUserId = await buildFeedbackMap({
      userFeedbackRepository,
      batchSize,
    });

    const usersCursor = userRepository.model
      .find({}, { _id: 1, name: 1, email: 1, anonymous: 1, createdAt: 1 })
      .lean()
      .cursor({ batchSize });

    for await (const user of usersCursor) {
      const userId =
        (user as any)?._id?.toString?.() !== undefined
          ? (user as any)._id.toString()
          : String((user as any)._id);
      const feedback = feedbackByUserId.get(userId);
      const roleplayComplete = feedback?.roleplayComplete;
      const roleplayIncomplete = feedback?.roleplayIncomplete;
      const keypointComplete = feedback?.keypointComplete;
      const keypointIncomplete = feedback?.keypointIncomplete;
      usersWorksheet
        .addRow({
          userId,
          userName: (user as any)?.name ?? '',
          userEmail: (user as any)?.email ?? '',
          anonymous: Boolean((user as any)?.anonymous),
          createdAt: formatExportDate((user as any)?.createdAt),
          hasProgress: progressUserIds.has(userId),
          roleplayCompleteCourseId: roleplayComplete?.courseId ?? '',
          roleplayCompleteLessonId: roleplayComplete?.lessonId ?? '',
          roleplayCompleteKeypointId: roleplayComplete?.keypointId ?? '',
          roleplayCompleteContentRating: roleplayComplete?.contentRating ?? '',
          roleplayCompleteExperienceRating:
            roleplayComplete?.experienceRating ?? '',
          roleplayCompleteOverallRating: roleplayComplete?.overallRating ?? '',
          roleplayCompleteComment: roleplayComplete?.comment ?? '',
          roleplayCompleteSubmittedAt: formatExportDate(
            roleplayComplete?.submittedAt,
          ),
          roleplayIncompleteCourseId: roleplayIncomplete?.courseId ?? '',
          roleplayIncompleteLessonId: roleplayIncomplete?.lessonId ?? '',
          roleplayIncompleteKeypointId: roleplayIncomplete?.keypointId ?? '',
          roleplayIncompleteReasons: formatReasonList(
            roleplayIncomplete?.reasons,
          ),
          roleplayIncompleteComment: roleplayIncomplete?.comment ?? '',
          roleplayIncompleteSubmittedAt: formatExportDate(
            roleplayIncomplete?.submittedAt,
          ),
          keypointCompleteCourseId: keypointComplete?.courseId ?? '',
          keypointCompleteLessonId: keypointComplete?.lessonId ?? '',
          keypointCompleteKeypointId: keypointComplete?.keypointId ?? '',
          keypointCompleteContentRating: keypointComplete?.contentRating ?? '',
          keypointCompleteExperienceRating:
            keypointComplete?.experienceRating ?? '',
          keypointCompleteOverallRating: keypointComplete?.overallRating ?? '',
          keypointCompleteComment: keypointComplete?.comment ?? '',
          keypointCompleteSubmittedAt: formatExportDate(
            keypointComplete?.submittedAt,
          ),
          keypointIncompleteCourseId: keypointIncomplete?.courseId ?? '',
          keypointIncompleteLessonId: keypointIncomplete?.lessonId ?? '',
          keypointIncompleteKeypointId: keypointIncomplete?.keypointId ?? '',
          keypointIncompleteReasons: formatReasonList(
            keypointIncomplete?.reasons,
          ),
          keypointIncompleteComment: keypointIncomplete?.comment ?? '',
          keypointIncompleteSubmittedAt: formatExportDate(
            keypointIncomplete?.submittedAt,
          ),
        })
        .commit();
    }

    usersWorksheet.commit();
    await workbook.commit();

    await zipFile(xlsxPath, zipPath);

    return await uploadExportFile(r2Service, zipPath, fileKey);
  } finally {
    await fs.promises.rm(tempDir, { recursive: true, force: true });
  }
}

export async function appendExportBatch(options: ExportBatchOptions) {
  const {
    worksheet,
    batch,
    cache,
    courseRepository,
    lessonRepository,
    keypointRepository,
    lang,
  } = options;
  const courseIds = new Set<string>();
  const lessonIds = new Set<string>();
  const keypointIds = new Set<string>();

  for (const progress of batch) {
    if (progress.courseId) courseIds.add(progress.courseId);
    for (const lesson of progress.lessonsResult || []) {
      if (lesson.lessonId) lessonIds.add(lesson.lessonId);
      for (const keypoint of lesson.keypointsResult || []) {
        if (keypoint.keypointId) keypointIds.add(keypoint.keypointId);
      }
    }
  }

  const newCourseIds = [...courseIds].filter(id => !cache.course.has(id));
  const newLessonIds = [...lessonIds].filter(id => !cache.lesson.has(id));
  const newKeypointIds = [...keypointIds].filter(id => !cache.keypoint.has(id));

  if (newCourseIds.length) {
    const courses = await courseRepository.model
      .find({ _id: { $in: newCourseIds } }, { _id: 1, title: 1 })
      .lean();
    for (const course of courses) {
      cache.course.set(course._id.toString(), course.title || {});
    }
  }

  if (newLessonIds.length) {
    const lessons = await lessonRepository.model
      .find(
        { _id: { $in: newLessonIds } },
        { _id: 1, title: 1, type: 1, courseId: 1, keypoints: 1 },
      )
      .lean();
    for (const lesson of lessons) {
      const rawKeypoints = Array.isArray(lesson.keypoints)
        ? lesson.keypoints.filter(Boolean)
        : [];
      cache.lesson.set(lesson._id.toString(), {
        title: lesson.title || {},
        type: lesson.type,
        courseId: lesson.courseId,
        keypoints: rawKeypoints.length ? new Set(rawKeypoints) : undefined,
      });
    }
  }

  if (newKeypointIds.length) {
    const keypoints = await keypointRepository.model
      .find({ _id: { $in: newKeypointIds } }, { _id: 1, title: 1 })
      .lean();
    for (const keypoint of keypoints) {
      cache.keypoint.set(keypoint._id.toString(), keypoint.title || {});
    }
  }

  for (const progress of batch) {
    const courseTranslation = cache.course.get(progress.courseId);
    if (!courseTranslation) {
      continue;
    }
    const courseTitle = resolveTitle(courseTranslation, lang);
    for (const lesson of progress.lessonsResult || []) {
      const lessonInfo = cache.lesson.get(lesson.lessonId);
      if (!lessonInfo) {
        continue;
      }
      if (
        lessonInfo?.courseId &&
        lessonInfo.courseId.toString() !== progress.courseId
      ) {
        continue;
      }
      const lessonTitle = resolveTitle(lessonInfo?.title, lang);
      const lessonType = lesson.lessonType || lessonInfo?.type || '';
      const lessonSubmittedAt = formatExportDate(lesson.submittedAt);

      const keypoints = lesson.keypointsResult || [];
      if (!keypoints.length) {
        worksheet
          .addRow({
            userId: progress.userId,
            courseId: progress.courseId,
            courseTitle,
            lessonId: lesson.lessonId,
            lessonTitle,
            lessonType,
            lessonAverageScore: lesson.averageScore ?? 0,
            lessonPassed: lesson.passed ?? false,
            lessonSubmittedAt,
            keypointId: '',
            keypointTitle: '',
            keypointAverageScore: 0,
            keypointPassed: false,
            keypointSubmittedAt: '',
            exerciseId: '',
            exerciseType: '',
            exerciseForm: '',
            exerciseScore: 0,
            exercisePassed: false,
            exerciseIndex: 0,
          })
          .commit();
        continue;
      }

      for (const keypoint of keypoints) {
        if (
          lessonInfo?.keypoints?.size &&
          !lessonInfo.keypoints.has(keypoint.keypointId)
        ) {
          continue;
        }
        if (!cache.keypoint.has(keypoint.keypointId)) {
          continue;
        }
        const keypointTitle = resolveTitle(
          cache.keypoint.get(keypoint.keypointId),
          lang,
        );
        const keypointSubmittedAt = formatExportDate(keypoint.submittedAt);
        const exercises = keypoint.exercisesResult || [];

        if (!exercises.length) {
          worksheet
            .addRow({
              userId: progress.userId,
              courseId: progress.courseId,
              courseTitle,
              lessonId: lesson.lessonId,
              lessonTitle,
              lessonType,
              lessonAverageScore: lesson.averageScore ?? 0,
              lessonPassed: lesson.passed ?? false,
              lessonSubmittedAt,
              keypointId: keypoint.keypointId,
              keypointTitle,
              keypointAverageScore: keypoint.averageScore ?? 0,
              keypointPassed: keypoint.passed ?? false,
              keypointSubmittedAt,
              exerciseId: '',
              exerciseType: '',
              exerciseForm: '',
              exerciseScore: 0,
              exercisePassed: false,
              exerciseIndex: 0,
            })
            .commit();
          continue;
        }

        for (const [index, exercise] of exercises.entries()) {
          worksheet
            .addRow({
              userId: progress.userId,
              courseId: progress.courseId,
              courseTitle,
              lessonId: lesson.lessonId,
              lessonTitle,
              lessonType,
              lessonAverageScore: lesson.averageScore ?? 0,
              lessonPassed: lesson.passed ?? false,
              lessonSubmittedAt,
              keypointId: keypoint.keypointId,
              keypointTitle,
              keypointAverageScore: keypoint.averageScore ?? 0,
              keypointPassed: keypoint.passed ?? false,
              keypointSubmittedAt,
              exerciseId: exercise.exerciseId,
              exerciseType: exercise.type,
              exerciseForm: exercise.form,
              exerciseScore: exercise.score ?? 0,
              exercisePassed: exercise.passed ?? false,
              exerciseIndex: index + 1,
            })
            .commit();
        }
      }
    }
  }
}

export async function zipFile(sourcePath: string, zipPath: string) {
  await new Promise<void>((resolve, reject) => {
    const output = fs.createWriteStream(zipPath);
    const archive = archiver('zip', { zlib: { level: 9 } });

    output.on('close', () => resolve());
    output.on('error', reject);
    archive.on('error', reject);

    archive.pipe(output);
    archive.file(sourcePath, { name: path.basename(sourcePath) });
    archive.finalize();
  });
}

export async function uploadExportFile(
  r2Service: R2Service,
  filePath: string,
  key: string,
) {
  await r2Service.deleteFile(key).catch(() => undefined);
  const buffer = await fs.promises.readFile(filePath);

  return r2Service.uploadFile(
    key,
    buffer,
    'application/zip',
    {
      'Content-Length': buffer.length.toString(),
    },
    { cacheControl: 'no-store' },
  );
}

export function resolveTitle(title?: ITranslation, lang?: string) {
  if (!title) return '';
  const preferredLang = (lang || '') as keyof ITranslation;
  if (preferredLang && title[preferredLang]) return title[preferredLang];
  if (title.vi) return title.vi;
  if (title.en) return title.en;
  const fallback = Object.values(title).find(value => Boolean(value));
  return typeof fallback === 'string' ? fallback : '';
}

export function formatExportDate(value?: Date) {
  if (!value) return '';
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? '' : date.toISOString();
}

function formatReasonList(reasons?: string[]) {
  return Array.isArray(reasons) ? reasons.join(', ') : '';
}

async function buildFeedbackMap(options: FeedbackMapOptions) {
  const { userFeedbackRepository, batchSize } = options;
  const map = new Map<string, any>();

  const cursor = userFeedbackRepository.getFeedbackCursor(batchSize);

  for await (const feedback of cursor) {
    const userId =
      (feedback as any)?.userId?.toString?.() !== undefined
        ? (feedback as any).userId.toString()
        : String((feedback as any).userId);
    if (userId) map.set(userId, normalizeFeedback(feedback));
  }

  return map;
}

function normalizeFeedback(feedback: any) {
  if (!feedback) return feedback;
  const id = feedback?._id?.toString?.() ?? feedback?._id;
  return {
    ...feedback,
    _id: id,
  };
}

export function buildExportResponse(
  job?: UserProgressExport,
  now?: Date,
): {
  status: UserProgressExportStatus;
  fileKey?: string;
  fileUrl?: string;
  requestedAt?: Date;
  startedAt?: Date;
  finishedAt?: Date;
  cooldownRemainingMs?: number;
} {
  if (!job) {
    return {
      status: UserProgressExportStatus.PENDING,
    };
  }

  const lastRequestedAt = job.requestedAt || job.updatedAt || job.createdAt;
  const nowTime = now ? now.getTime() : Date.now();
  const remainingMs = lastRequestedAt
    ? Math.max(0, EXPORT_COOLDOWN_MS - (nowTime - lastRequestedAt.getTime()))
    : 0;

  const isCompleted = job.status === UserProgressExportStatus.COMPLETED;

  return {
    status: job.status,
    fileKey: isCompleted ? job.fileKey : undefined,
    fileUrl: isCompleted
      ? buildCacheBusterUrl(job.fileUrl, job.finishedAt || job.updatedAt)
      : undefined,
    requestedAt: job.requestedAt,
    startedAt: job.startedAt,
    finishedAt: job.finishedAt,
    cooldownRemainingMs: remainingMs,
  };
}

function buildCacheBusterUrl(url?: string, date?: Date) {
  if (!url || !date) return url;
  const separator = url.includes('?') ? '&' : '?';
  return `${url}${separator}v=${date.getTime()}`;
}
