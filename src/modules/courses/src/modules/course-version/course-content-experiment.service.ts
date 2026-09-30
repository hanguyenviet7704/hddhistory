import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { ExperimentFacts } from './content-version.resolver';
import {
  CONTENT_EXPERIMENT_EVENTS,
  CONTENT_EXPERIMENT_KEY_PARAM,
  CONTENT_EXPERIMENT_PARAM,
} from './course-content-experiment.constants';
import { CourseContentExperimentRepository } from './repository/course-content-experiment.repository';
import { CourseContentVersionRepository } from './repository/course-content-version.repository';
import {
  CourseContentExperiment,
  IExperimentArm,
} from './schema/course-content-experiment.schema';
import { UserEventRepository } from '../../../../analytics/repository/user-event.repository';
import { UserProgressRepository } from '../progress/src/modules/user-progress/repository/user-progress.repository';

/** Một dòng của bảng kết quả. */
export interface ExperimentArmStats {
  arm: 'A' | 'B';
  viewers: number;
  keypointStarts: number;
  keypointReads: number;
  completes: number;
  skips: number;
  exits: number;
  reports: number;
  /** % người thấy khoá mà hoàn thành ít nhất một keypoint. */
  completionRate: number;
}

export interface UpsertExperimentDto {
  key: string;
  percentB: number;
  startedAt: Date;
  arms: IExperimentArm[];
  note?: string | null;
}

/**
 * Một đợt A/B nội dung khoá học: hai tag của cùng một khoá làm hai nhánh, chia
 * người bằng `experimentBucket(key, userId)` nên không lưu bảng gán nhánh nào.
 *
 * Có chủ ý KHÔNG phải framework thí nghiệm tổng quát — đợt sau sẽ muốn chỉ số
 * và bảng đọc riêng. Xem ghi chú trên `PaywallBodyExperimentDto`.
 */
/**
 * Bao lâu thì đọc lại danh sách khoá đang trong đợt. Đủ ngắn để bật/tắt đợt có
 * hiệu lực gần như tức thì kể cả khi có nhiều instance, đủ dài để không thêm
 * một query vào mỗi lượt đọc màn chính.
 */
const ARM_CACHE_MS = 30_000;

@Injectable()
export class CourseContentExperimentService {
  private armCache: { at: number; courseIds: Set<string> } | null = null;

  constructor(
    private readonly experimentRepository: CourseContentExperimentRepository,
    private readonly courseVersionRepository: CourseContentVersionRepository,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly userEventRepository: UserEventRepository,
  ) {}

  // ------------------------------------------------------------------- admin

  async list(): Promise<CourseContentExperiment[]> {
    return this.experimentRepository.findAllNewestFirst();
  }

  /**
   * Tạo đợt, luôn ở trạng thái TẮT. Bật trước khi app biết đóng dấu nhánh lên
   * event là phục vụ hai bản khác nhau mà không đo được gì — trả giá trải
   * nghiệm không lấy được dữ liệu.
   */
  async create(
    dto: UpsertExperimentDto,
    actor?: IUserMeta | null,
  ): Promise<CourseContentExperiment> {
    const key = dto.key?.trim();
    if (!key) throw new BadRequestException('key là bắt buộc');

    if (await this.experimentRepository.findOneByKey(key)) {
      throw new ConflictException(
        `key ${key} đã dùng — đợt mới phải đổi key, kẻo trộn số liệu hai đợt`,
      );
    }

    await this.assertArmsUsable(dto.arms);

    return this.experimentRepository.create(
      {
        key,
        enabled: false,
        percentB: dto.percentB,
        startedAt: dto.startedAt,
        arms: dto.arms,
        note: dto.note ?? null,
      },
      actor ?? undefined,
    );
  }

  async setEnabled(
    id: string,
    enabled: boolean,
  ): Promise<CourseContentExperiment> {
    const run = await this.experimentRepository.findById(id);
    if (!run) throw new NotFoundException('không thấy đợt test');

    if (enabled) await this.assertArmsUsable(run.arms);

    await this.experimentRepository.updateOne({ _id: run._id }, {
      enabled,
    } as any);
    this.invalidateArmCache();

    return { ...run, enabled } as CourseContentExperiment;
  }

  /**
   * Dọn cache danh sách khoá đang trong đợt. Gọi sau mọi thay đổi cấu hình để
   * bật/tắt đợt có hiệu lực ngay thay vì trong vòng `ARM_CACHE_MS`.
   */
  invalidateArmCache(): void {
    this.armCache = null;
  }

  /**
   * Bảng kết quả. Đếm theo NGƯỜI (`countUsersByParam`) chứ không theo số
   * event: một keypoint mở lại năm lần là một người học, đếm năm lần là dịch
   * tỉ lệ mà chẳng ai đổi hành vi.
   *
   * Lọc theo `content_experiment_key` nên cửa sổ thời gian trùng hai đợt không
   * bị trộn mẫu số.
   */
  async stats(
    key: string,
    appEnv: string,
  ): Promise<{
    key: string;
    enabled: boolean;
    percentB: number;
    startedAt: Date;
    endedAt?: Date | null;
    arms: ExperimentArmStats[];
  }> {
    const run = await this.experimentRepository.findOneByKey(key);
    if (!run) throw new NotFoundException(`không thấy đợt ${key}`);

    const from = run.startedAt;
    const to = run.endedAt ?? new Date();
    const whereParams = { [CONTENT_EXPERIMENT_KEY_PARAM]: key };

    const [
      viewers,
      keypointStarts,
      keypointReads,
      completes,
      skips,
      exits,
      reports,
    ] = await Promise.all(
      Object.values(CONTENT_EXPERIMENT_EVENTS).map(name =>
        this.userEventRepository.countUsersByParam({
          name,
          paramKey: CONTENT_EXPERIMENT_PARAM,
          appEnv,
          from,
          to,
          whereParams,
        }),
      ),
    );

    const arms: ExperimentArmStats[] = (['A', 'B'] as const).map(arm => {
      const seen = viewers[arm] ?? 0;
      const done = completes[arm] ?? 0;

      return {
        arm,
        viewers: seen,
        keypointStarts: keypointStarts[arm] ?? 0,
        keypointReads: keypointReads[arm] ?? 0,
        completes: done,
        skips: skips[arm] ?? 0,
        exits: exits[arm] ?? 0,
        reports: reports[arm] ?? 0,
        // Chia cho 0 phải ra 0, không ra NaN: bảng kết quả hiện ngay khi đợt
        // vừa bật, lúc chưa ai đóng dấu nhánh nào.
        completionRate: seen ? Math.round((done / seen) * 1000) / 10 : 0,
      };
    });

    return {
      key: run.key,
      enabled: run.enabled,
      percentB: run.percentB,
      startedAt: run.startedAt,
      endedAt: run.endedAt ?? null,
      arms,
    };
  }

  // ------------------------------------------------------------------- serve

  /**
   * Sự kiện của đợt cho khoá này, hoặc null khi khoá không tham gia. Trả null
   * cả khi một nhánh không tra được tag nữa (tag bị xoá sau khi cấu hình):
   * fail closed, vì phục vụ nửa vời còn tệ hơn không chạy.
   */
  async factsFor(
    courseId: string,
    viewerId: string,
  ): Promise<ExperimentFacts | null> {
    // Chặn sớm: phần lớn khoá không nằm trong đợt nào, và hàm này chạy trên
    // mọi lượt đọc nội dung.
    if (!(await this.courseIdsInRuns()).has(courseId)) return null;

    const run = await this.experimentRepository.findRunningForCourse(courseId);
    if (!run) return null;

    const arm = (run.arms ?? []).find(entry => entry.courseId === courseId);
    if (!arm) return null;

    const [versionA, versionB] = await Promise.all([
      this.courseVersionRepository.findOneByTag(courseId, arm.tagA),
      this.courseVersionRepository.findOneByTag(courseId, arm.tagB),
    ]);
    if (!versionA || !versionB) return null;

    const progressStartedAt =
      await this.userProgressRepository.findCourseStartedAt(viewerId, courseId);

    return {
      key: run.key,
      percentB: run.percentB,
      armA: String(versionA._id),
      armB: String(versionB._id),
      runStartedAt: run.startedAt,
      progressStartedAt,
    };
  }

  // --------------------------------------------------------------- internals

  private async courseIdsInRuns(): Promise<Set<string>> {
    const now = Date.now();
    if (this.armCache && now - this.armCache.at < ARM_CACHE_MS) {
      return this.armCache.courseIds;
    }

    const ids = await this.experimentRepository.findEnabledArmCourseIds();
    this.armCache = { at: now, courseIds: new Set(ids) };

    return this.armCache.courseIds;
  }

  /**
   * Kiểm ở lúc cấu hình chứ không để tới lúc serve: một đợt khai sai tag chỉ
   * lộ ra sau nhiều ngày chạy, và tới lúc đó số liệu đã hỏng.
   */
  private async assertArmsUsable(arms: IExperimentArm[]): Promise<void> {
    if (!arms?.length) {
      throw new BadRequestException('đợt phải có ít nhất một khoá');
    }

    for (const arm of arms) {
      if (arm.tagA === arm.tagB) {
        throw new BadRequestException(
          `khoá ${arm.courseId}: hai nhánh trùng tag ${arm.tagA} — test sẽ đo một thứ không tồn tại`,
        );
      }

      const [a, b] = await Promise.all([
        this.courseVersionRepository.findOneByTag(arm.courseId, arm.tagA),
        this.courseVersionRepository.findOneByTag(arm.courseId, arm.tagB),
      ]);
      if (!a || !b) {
        throw new BadRequestException(
          `khoá ${arm.courseId}: không thấy tag ${!a ? arm.tagA : arm.tagB}`,
        );
      }
    }
  }
}
