import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import {
  buildSnapshot,
  diffSnapshots,
  EntityCounts,
  SnapshotDiff,
  SnapshotInput,
} from './content-snapshot';
import { AudioCoverageService } from './audio-coverage.service';
import { VersionDubService } from './version-dub.service';
import { collectKeypointIds, collectLessonIds } from './content-traversal';
import { isTagName, nextPatchTag } from './course-version.util';
import { CreateCourseVersionDto } from './dto/create-course-version.dto';
import { CourseContentVersionRepository } from './repository/course-content-version.repository';
import { CourseVersionActivationRepository } from './repository/course-version-activation.repository';
import { PublishedContentRepository } from './repository/published-content.repository';
import { CourseContentVersion } from './schema/course-content-version.schema';
import { CourseRepository } from '../course/repository/course.repository';
import { RoadmapRepository } from '../course/repository/roadmap.repository';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { LearningItemRepository } from '../learning-item/repository/learning-item.repository';
import { LessonRepository } from '../lesson/repository/lesson.repository';

/** One row of the admin version table. */
export interface CourseVersionView {
  _id: string;
  tag: string;
  note?: string | null;
  entityCounts: EntityCounts;
  createdAt?: Date;
  createdBy?: IUserMeta | null;
  isCurrent: boolean;
}

export interface CourseVersionListView {
  versions: CourseVersionView[];
  currentTag: string | null;
  /** What to pre-fill the "new tag" field with. */
  nextTag: string;
  /** Working tree vs the tag being served — the "not published yet" banner. */
  pending: SnapshotDiff;
}

/**
 * Content tags for one course: freeze the working tree under a name, point the
 * course at a tag, roll back by pointing it at an older one.
 *
 * A singleton on purpose. The acting user arrives as an argument rather than
 * from an injected `RequestService`, because that injection would make this
 * provider request-scoped and `course-publish.scheduler.ts` has to call
 * `createTag` when it publishes a course that has no tag yet -- a
 * request-scoped dependency bubbles up and silently kills the @Cron that
 * imported it, exactly as documented on `SegmentModule`.
 *
 * See `plans/260907-course-content-versions/README.md`.
 */
/**
 * Tag này đã từng được phục vụ chưa — `null` khi sổ không phủ tới nó.
 *
 * Ba nhánh, theo thứ tự chắc chắn giảm dần:
 *  1. có hàng trong sổ, hoặc đang là bản được trỏ tới → CHẮC CHẮN đã/đang chạy;
 *  2. không có hàng, nhưng tag được đánh SAU khi sổ bắt đầu ghi → sổ đã phủ
 *     quãng đời của nó mà không thấy gì, nên chắc chắn chưa từng chạy;
 *  3. không có hàng và tag đánh TRƯỚC dòng đầu của sổ (hoặc không rõ ngày
 *     đánh) → không biết, và phải nói là không biết.
 */
const publishStateOf = (
  versionId: string,
  createdAt: Date | null,
  ctx: {
    published: Set<string>;
    currentVersionId: string | null;
    logStartedAt: Date | null;
  },
): boolean | null => {
  if (ctx.published.has(versionId) || versionId === ctx.currentVersionId) {
    return true;
  }
  if (ctx.logStartedAt && createdAt && +createdAt >= +ctx.logStartedAt) {
    return false;
  }

  return null;
};

@Injectable()
export class CourseVersionService {
  private readonly logger = new Logger(CourseVersionService.name);

  constructor(
    private readonly courseVersionRepository: CourseContentVersionRepository,
    private readonly publishedContentRepository: PublishedContentRepository,
    private readonly courseRepository: CourseRepository,
    private readonly roadmapRepository: RoadmapRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly activationRepository: CourseVersionActivationRepository,
    private readonly audioCoverage: AudioCoverageService,
    private readonly versionDub: VersionDubService,
  ) {}

  // ------------------------------------------------------------------- read

  /**
   * Những gì sheet `_VERSION` cần: tag đang phục vụ, tag ứng với
   * `contentVersionId` (null = bản đang sửa), và TOÀN BỘ lịch sử tag.
   *
   * Tách khỏi `listVersions` vì hàm đó đọc cả bản đang sửa và băm lại toàn bộ
   * nội dung để tính "có gì thay đổi chưa" — trả giá đó cho mỗi lần xuất
   * workbook, và cho MỖI khoá trong một lần sync cả thư mục Drive, là quá đắt
   * khi chỉ cần mấy cái tên và ngày.
   *
   * `everPublished` đọc từ sổ `course_version_activations`, nên nó phân biệt
   * được "đóng băng nhưng chưa bao giờ live" với "đã live rồi bị thay" — hai
   * thứ trông y như nhau nếu chỉ nhìn `currentVersionId`.
   *
   * Ba trạng thái, và trạng thái thứ ba là trạng thái bắt buộc: sổ chỉ tồn tại
   * từ khi tính năng cửa sổ phiên bản lên, nên với tag được đánh TRƯỚC dòng
   * đầu tiên của sổ thì câu trả lời là `null` = không biết. Trả `false` cho
   * mấy tag đó là in "chưa phát hành" lên một bản thực ra đã từng chạy.
   */
  async versionOverview(
    courseId: string,
    contentVersionId: string | null = null,
  ): Promise<{
    liveTag: string | null;
    contentTag: string | null;
    history: {
      tag: string;
      createdAt: Date | null;
      note?: string | null;
      everPublished: boolean | null;
    }[];
  }> {
    const [course, versions, activations] = await Promise.all([
      this.courseRepository.findById(courseId),
      this.courseVersionRepository.findByCourse(courseId),
      this.activationRepository.findByCourse(courseId),
    ]);

    const tagOf = new Map(
      versions.map(version => [String(version._id), version.tag]),
    );
    const currentVersionId = course?.currentVersionId
      ? String(course.currentVersionId)
      : null;
    const published = new Set(
      activations.map(row => String(row.versionId)),
    );
    // `findByCourse` sắp cũ nhất trước, nên hàng đầu là lúc sổ bắt đầu ghi.
    const logStartedAt = activations[0]?.from ?? null;

    return {
      liveTag: currentVersionId ? tagOf.get(currentVersionId) ?? null : null,
      contentTag: contentVersionId
        ? tagOf.get(String(contentVersionId)) ?? null
        : null,
      // `findByCourse` đã sắp mới nhất trước.
      history: versions.map(version => ({
        tag: version.tag,
        createdAt: (version as any).createdAt ?? null,
        note: version.note ?? null,
        everPublished: publishStateOf(
          String(version._id),
          (version as any).createdAt ?? null,
          { published, currentVersionId, logStartedAt },
        ),
      })),
    };
  }

  async listVersions(courseId: string): Promise<CourseVersionListView> {
    const course = await this.courseRepository.findById(courseId);
    if (!course) throw new NotFoundException('course was not found');

    const currentVersionId = course.currentVersionId
      ? String(course.currentVersionId)
      : null;
    const versions = await this.courseVersionRepository.findByCourse(courseId);

    const { rows } = buildSnapshot(await this.readWorkingTree(courseId));
    const published = currentVersionId
      ? await this.publishedContentRepository.findHashes(currentVersionId)
      : [];

    return {
      versions: versions.map(version =>
        this.viewOf(version, currentVersionId),
      ),
      currentTag:
        versions.find(v => String(v._id) === currentVersionId)?.tag ?? null,
      nextTag: nextPatchTag(versions.map(version => version.tag)),
      pending: diffSnapshots(rows, published),
    };
  }

  // ------------------------------------------------------------------ write

  async createTag(
    courseId: string,
    dto: CreateCourseVersionDto,
    /** Who is tagging. Omitted for unattended tags (scheduler, backfill). */
    actor?: IUserMeta | null,
    /**
     * Whether publishing this tag has to wait for its audio.
     *
     * Only the admin panel asks for it. The unattended callers below —
     * `autoTag` (Drive sync) and `ensureTagged` (the "no live course without a
     * tag" safety net) — must NOT be gated: refusing them leaves a live course
     * serving the working tree, or a synced sheet silently not reaching the
     * app, which is worse than a tag that is briefly short of narration.
     */
    opts?: { enforceAudio?: boolean },
  ): Promise<CourseVersionView> {
    if (!isTagName(dto.tag)) {
      throw new BadRequestException(
        'tag must look like v1.0.0 (no leading zeros)',
      );
    }

    const clash = await this.courseVersionRepository.findOneByTag(
      courseId,
      dto.tag,
    );
    if (clash) {
      throw new ConflictException(`tag ${dto.tag} already exists`);
    }

    const { rows, entityCounts } = buildSnapshot(
      await this.readWorkingTree(courseId),
    );

    const version = await this.courseVersionRepository.create(
      {
        courseId,
        tag: dto.tag,
        note: dto.note ?? null,
        entityCounts,
      },
      actor ?? undefined,
    );
    const versionId = String(version._id);

    // No transaction: the dev database is not guaranteed to be a replica set.
    // A tag whose rows failed to insert would resolve to no content at all, so
    // the tag is removed again rather than left half-built.
    try {
      await this.publishedContentRepository.insertRows(
        versionId,
        courseId,
        rows,
      );
    } catch (error) {
      this.logger.error(
        `freezing content for ${courseId} ${dto.tag} failed, removing the tag`,
        error as Error,
      );
      await this.courseVersionRepository.deleteOne({ _id: version._id });
      throw error;
    }

    if (dto.setCurrent) {
      await this.pointCourseAt(courseId, versionId, dto.tag, {
        enforceAudio: opts?.enforceAudio,
      });
    }

    return this.viewOf(version, dto.setCurrent ? versionId : null);
  }

  /**
   * Tag and publish in one step, naming the tag automatically. This is what
   * the Google Sheet / Excel round-trip needs: without it the content team
   * would sync a sheet and see nothing change on the app, because a tagged
   * course only ever serves what a tag holds.
   *
   * Unattended by design -- `actor` is optional so drive-sync can call it.
   */
  async autoTag(
    courseId: string,
    actor?: IUserMeta | null,
  ): Promise<CourseVersionView> {
    const existing = await this.courseVersionRepository.findByCourse(courseId);
    const tag = nextPatchTag(existing.map(version => version.tag));

    return this.createTag(courseId, { tag, setCurrent: true }, actor ?? null);
  }

  /**
   * Đảm bảo khoá có ít nhất một tag và đang trỏ vào đó — chốt an toàn của mục
   * 6: không được tồn tại khoá đang live mà không có tag, vì khoá như thế sẽ
   * phục vụ bản đang sửa cho user thật.
   *
   * Gọi từ `course-publish.scheduler.ts` (cron mỗi phút, `updateMany`
   * idempotent) nên bản thân nó phải idempotent: tên tag CỐ ĐỊNH `v1.0.0` và
   * nuốt xung đột trùng khoá, chứ không patch-bump như `autoTag` — hai tick
   * chồng nhau mà patch-bump thì sẽ đẻ ra cả v1.0.0 và v1.0.1.
   *
   * Trả null khi khoá đã có tag (hoặc vừa bị tick khác tag xong).
   */
  async ensureInitialTag(
    courseId: string,
    actor?: IUserMeta | null,
  ): Promise<CourseVersionView | null> {
    const existing = await this.courseVersionRepository.findByCourse(courseId);
    if (existing.length) return null;

    try {
      return await this.createTag(
        courseId,
        { tag: 'v1.0.0', setCurrent: true },
        actor ?? null,
      );
    } catch (error: any) {
      // Chỉ nuốt đúng cái xung đột "đã có tag rồi". Lỗi khác (ví dụ đóng băng
      // nội dung thất bại) phải nổ ra để tick sau thử lại và log thấy được.
      const isDuplicate =
        error instanceof ConflictException ||
        String(error?.message ?? '').includes('E11000');
      if (isDuplicate) {
        this.logger.log(
          `Course ${courseId} was tagged concurrently; skipping initial tag`,
        );

        return null;
      }

      throw error;
    }
  }

  /** Rollback and roll-forward are the same operation. */
  async setCurrent(courseId: string, tag: string): Promise<CourseVersionView> {
    const version = await this.courseVersionRepository.findOneByTag(
      courseId,
      tag,
    );
    if (!version) throw new NotFoundException(`tag ${tag} was not found`);

    const versionId = String(version._id);
    await this.pointCourseAt(courseId, versionId, tag, { enforceAudio: true });

    return this.viewOf(version, versionId);
  }

  /**
   * "Tag này có đủ audio chưa", cho đúng một tag.
   *
   * Nhận TÊN tag chứ không phải id: admin đang cầm tên, và người đọc lỗi ở
   * `assertAudioComplete` cũng thấy tên.
   */
  async audioCoverageOf(courseId: string, tag: string) {
    const version = await this.courseVersionRepository.findOneByTag(
      courseId,
      tag,
    );
    if (!version) throw new NotFoundException(`tag ${tag} was not found`);

    return {
      tag,
      ...(await this.audioCoverage.forVersion(courseId, String(version._id))),
    };
  }

  /** Ghi bù mọi thẻ mà tag này còn thiếu. Chạy nền, hỏi tiến độ ở snapshot. */
  async dubMissingOf(courseId: string, tag: string) {
    const version = await this.courseVersionRepository.findOneByTag(
      courseId,
      tag,
    );
    if (!version) throw new NotFoundException(`tag ${tag} was not found`);

    return this.versionDub.start(courseId, String(version._id), tag);
  }

  dubStatus() {
    return this.versionDub.snapshot();
  }

  async deleteTag(
    courseId: string,
    tag: string,
  ): Promise<{ deleted: boolean }> {
    const version = await this.courseVersionRepository.findOneByTag(
      courseId,
      tag,
    );
    if (!version) throw new NotFoundException(`tag ${tag} was not found`);

    const course = await this.courseRepository.findById(courseId);
    if (course && String(course.currentVersionId) === String(version._id)) {
      throw new ConflictException(
        'this tag is the one being served; point the course at another tag first',
      );
    }

    await this.publishedContentRepository.deleteByVersion(String(version._id));
    await this.courseVersionRepository.deleteOne({ _id: version._id });

    return { deleted: true };
  }

  /**
   * Rollout: give every untagged course a `v1.0.0` of exactly what it serves
   * today and point it there, so the day this ships users see no difference.
   * Idempotent — a course that already has any tag is skipped.
   *
   * An endpoint rather than a script because the hosted dev API talks to a
   * different Mongo than a local `.env`, so this has to be runnable through
   * the API with a bearer token.
   */
  async backfill(): Promise<{ tagged: string[]; skipped: string[] }> {
    const tagged: string[] = [];
    const skipped: string[] = [];

    const alreadyTagged = new Set(
      await this.courseVersionRepository.findTaggedCourseIds(),
    );

    for (const courseId of await this.courseRepository.findAllIds()) {
      if (alreadyTagged.has(courseId)) {
        skipped.push(courseId);
        continue;
      }

      await this.ensureInitialTag(courseId);
      tagged.push(courseId);
    }

    return { tagged, skipped };
  }

  // --------------------------------------------------------------- internals

  /**
   * Point the course at a tag AND refresh `Course.published` from that tag's
   * own `course` row. Reading it from the tag rather than from the live course
   * is what makes a rollback restore the old title: `Course.published` holds
   * only one version, the tag holds the master copy.
   */
  /**
   * Refuse to serve a tag whose audio is not complete.
   *
   * Complete means every keypoint × every one of the five languages is `done`
   * or `none` — the owner's call (2026-09-16): a language shipped without
   * narration is a market that goes silent with nobody watching.
   *
   * **A tag that has already been served is let through.** This endpoint is
   * also the rollback, and a rollback happens when something is on fire; a
   * publish gate that blocks the way back is worse than the hole it closes.
   * Anything that has run before is a state users have already lived with.
   */
  private async assertAudioComplete(
    courseId: string,
    versionId: string,
    tag: string,
  ): Promise<void> {
    const activations = await this.activationRepository.findByCourse(courseId);
    const everPublished = activations.some(
      row => String(row.versionId) === versionId,
    );
    if (everPublished) return;

    const coverage = await this.audioCoverage.forVersion(courseId, versionId);
    if (coverage.complete) return;

    // Named, not counted: "12 ô thiếu" tells the content team nothing about
    // where to look, and this message is the whole repair instruction.
    const gaps = coverage.keypoints
      .filter(row => Object.keys(row.missing).length)
      .slice(0, 5)
      .map(row => {
        const title =
          row.title?.vi || row.title?.en || Object.values(row.title ?? {})[0];

        return `${title ?? row.keypointId} (${Object.keys(row.missing).join(', ')})`;
      });
    const more = coverage.keypoints.filter(row =>
      Object.keys(row.missing).length,
    ).length - gaps.length;

    throw new ConflictException(
      `tag ${tag} chưa đủ audio: ${coverage.summary.missing} ô chưa có, ` +
        `${coverage.summary.stale} ô mới sửa chữ. Thiếu ở: ${gaps.join(' · ')}` +
        (more > 0 ? ` và ${more} keypoint nữa.` : '.'),
    );
  }

  private async pointCourseAt(
    courseId: string,
    versionId: string,
    tag: string,
    opts?: { enforceAudio?: boolean },
  ): Promise<void> {
    if (opts?.enforceAudio) await this.assertAudioComplete(courseId, versionId, tag);

    const published = await this.publishedContentRepository.findEntity(
      versionId,
      'course',
      courseId,
    );

    await this.courseRepository.updateOne({ _id: courseId }, {
      currentVersionId: versionId,
      published: published ?? null,
    } as any);

    await this.recordActivation(courseId, versionId, tag);
  }

  /**
   * Ghi lại "từ giờ khoá này phục vụ tag kia" vào sổ cửa sổ thời gian, để bảng
   * so sánh phiên bản gán được event học tập về đúng tag.
   *
   * Ba điều khiến hàm này không tầm thường:
   *
   *  - **Trỏ lại đúng tag đang live thì không ghi gì.** `createTag` gọi
   *    `pointCourseAt` mỗi lần, và cron `autoTag` cũng vậy; nếu mỗi lần đều
   *    cắt một đoạn mới thì sổ đầy những đoạn dài 0 giây và mọi phép chia theo
   *    cửa sổ đều lệch.
   *  - **Đoạn trước đóng ĐÚNG mốc đoạn sau mở** (cùng một `now`), nên dải cửa
   *    sổ không hở một khe nào — một event rơi vào khe hở là một event không
   *    thuộc phiên bản nào và biến mất khỏi cả hai cột.
   *  - **Không được làm gãy việc đánh tag.** Sổ này là dữ liệu báo cáo, còn
   *    `currentVersionId` là thứ người học đang đọc. Nếu ghi sổ lỗi thì chỉ
   *    log rồi đi tiếp: mất một dòng báo cáo còn hơn để nguyên khoá không
   *    chuyển được phiên bản.
   */
  private async recordActivation(
    courseId: string,
    versionId: string,
    tag: string,
  ): Promise<void> {
    try {
      const open = await this.activationRepository.findOpenWindow(courseId);
      if (open && String(open.versionId) === String(versionId)) return;

      const now = new Date();
      await this.activationRepository.closeOpenWindows(courseId, now);
      await this.activationRepository.openWindow({
        courseId,
        versionId,
        tag,
        from: now,
      });
    } catch (error) {
      this.logger.error(
        `không ghi được cửa sổ phiên bản cho khoá ${courseId} (${tag}): ${error}`,
      );
    }
  }

  /**
   * Everything a tag freezes, read from the collections the admin edits.
   * Lessons are the UNION of the lessons carrying this `courseId` and the ones
   * the roadmap references — see `collectLessonIds`.
   */
  private async readWorkingTree(courseId: string): Promise<SnapshotInput> {
    const course = await this.courseRepository.findById(courseId);
    if (!course) throw new NotFoundException('course was not found');

    const [roadmap] = await this.roadmapRepository.findByCourseIds([courseId]);
    const courseLessons = await this.lessonRepository.findAllForExport(
      courseId,
    );

    const lessonIds = collectLessonIds({
      courseLessons: courseLessons as any[],
      roadmap: roadmap as any,
    });
    const lessons = await this.lessonRepository.findFullByIds(lessonIds);

    const keypointIds = collectKeypointIds({
      lessons: lessons as any[],
      roadmap: roadmap as any,
    });
    const keypoints = await this.keypointRepository.findKeypointsByIds(
      keypointIds,
    );
    const learningItems =
      await this.learningItemRepository.findAllByKeypointIds(keypointIds);

    return {
      course: course as any,
      roadmap: (roadmap ?? null) as any,
      lessons: lessons as any[],
      keypoints: keypoints as any[],
      learningItems: learningItems as any[],
    };
  }

  private viewOf(
    version: CourseContentVersion,
    currentVersionId: string | null,
  ): CourseVersionView {
    return {
      _id: String(version._id),
      tag: version.tag,
      note: version.note ?? null,
      entityCounts: version.entityCounts,
      createdAt: version.createdAt,
      createdBy: version.createdBy ?? null,
      isCurrent: String(version._id) === currentVersionId,
    };
  }
}
