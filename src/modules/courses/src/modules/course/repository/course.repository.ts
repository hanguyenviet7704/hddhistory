import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model, Types } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { withMarketVisibility } from '@utils/market-query.util';
import { OrderType } from '@utils/type/orderByType';

import { GetListCourseDto } from '../dto/get-list-course.dto';
import { CourseStatus } from '../enum/course.enum';
import { Course } from '../schema/course.schema';

/**
 * Everything a course CARD needs to render AND to be tapped.
 *
 * Named because omitting a field here fails silently and far away: a card
 * without `numberOfLesson` deserialises to 0 on the client, and the tap handler
 * reads that as "this course has no lessons yet" and refuses to open it.
 */
export const COURSE_CARD_FIELDS =
  'title _id skillsetId level image description status numberOfLesson isNew publishAt newDurationDays author viewCount';

/** A course as a candidate for onboarding recommendation — card fields plus
 * the two onboarding v3 tag arrays the matching logic filters on. */
export interface IOnboardingCourseCandidate {
  _id: Types.ObjectId;
  title: Record<string, string>;
  description?: Record<string, string>;
  image: string;
  skillsetId: string;
  numberOfLesson?: number;
  status: CourseStatus;
  createdAt?: Date;
  onboardingLabelCodes: string[];
  onboardingDesireCodes: string[];
}

const ONBOARDING_CANDIDATE_FIELDS =
  '_id title description image skillsetId numberOfLesson status createdAt onboardingLabelCodes onboardingDesireCodes';

@Injectable()
export class CourseRepository extends AbstractRepository<Course> {
  protected readonly logger = new Logger(CourseRepository.name);
  constructor(
    @InjectModel(Course.name) model: Model<Course>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  // Resolve per request. This repository is a singleton, so a field
  // initializer (`lang = I18nContext.current().lang`) would capture the very
  // first request's locale and freeze it for every later request — making
  // language-scoped queries (search, title-uniqueness) use the wrong language.
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  /**
   * `viewerMarkets` is the market allow-list check (see `withMarketVisibility`):
   * an array filters the catalogue to what that viewer's markets may see, while
   * `null`/`undefined` filters nothing at all. The distinction is the admin
   * panel — it reads this same route and must see every course, including one
   * published to Japan only.
   */
  /**
   * `searchPublished` searches the frozen editorial fields (`published.*`)
   * instead of the draft ones. Without it the app's search would match the
   * title an editor is still working on -- the ten `title.*` indexes are on
   * this collection, which is exactly why `Course.published` is cached here.
   * See `plans/260907-course-content-versions/README.md`.
   */
  async findOption(
    getListCourseDto: GetListCourseDto,
    viewerMarkets?: string[] | null,
    searchPublished = false,
  ) {
    const where: FilterQuery<Course> = {};

    const {
      page,
      take,
      search,
      status,
      statuses,
      level,
      order,
      orderBy,
      ids,
      isAll,
      skillsetIds,
      onboardingSymptoms,
    } = getListCourseDto;

    if (ids) where._id = { $in: ids };

    if (search?.trim()) {
      // Escape regex metacharacters so a term like "C++" or "(beta)" matches
      // literally instead of being interpreted as a pattern.
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      // Search ONLY the active locale's fields — never mix languages. A query
      // typed in the current language must not match another language's
      // title/description (e.g. an English term hitting `title.en` while the
      // app is Vietnamese). Results stay in the language being searched.
      const lang = this.lang;
      const like = { $regex: escaped, $options: 'i' };
      where.$or = searchPublished
        ? [
            { [`published.title.${lang}`]: like },
            { [`published.description.${lang}`]: like },
            // Khoá chưa có tag: `published` là null, và bản đang sửa CHÍNH LÀ
            // nội dung app đang đọc, nên vẫn phải tìm được.
            { published: null, [`title.${lang}`]: like },
            { published: null, [`description.${lang}`]: like },
          ]
        : [{ [`title.${lang}`]: like }, { [`description.${lang}`]: like }];
    }

    // An explicit list wins over both `status` and `isAll`: it is how a
    // caller asks for "everything a learner may see" without having to know
    // that `isAll` disables status filtering entirely.
    if (statuses?.length) {
      where.status = { $in: statuses };
    } else if (status && !isAll) {
      where.status = status;
    }

    if (level) {
      where.level = level;
    }

    if (skillsetIds?.length) {
      where.skillsetId = { $in: skillsetIds };
    }

    if (onboardingSymptoms?.length) {
      where.onboardingSymptoms = { $in: onboardingSymptoms };
    }

    return this.paginateQuery<Course>({
      // Merged with `$and`, never spread: `where.$or` may already hold the
      // title/description search, and a spread would drop it silently.
      where: withMarketVisibility(where, viewerMarkets),
      page,
      take,
      orderBy,
      order,
    });
  }

  async checkExitsTitle(title: string, lang = this.lang) {
    const normalizedTitle = title?.trim();
    if (!normalizedTitle) return null;

    const course = await this.model.exists({
      [`title.${lang}`]: normalizedTitle,
    });
    return course;
  }

  async findAllForExport(courseId?: string) {
    return this.model
      .find(courseId ? { _id: courseId } : {})
      .sort({ _id: 1 })
      .lean();
  }

  async findAllBrief(
    skillsetId: string,
    order: OrderType,
    orderBy: string,
    viewerMarkets?: string[] | null,
  ) {
    const where: FilterQuery<Course> = {
      skillsetId,
      status: { $in: [CourseStatus.PUBLISHED, CourseStatus.COMING_SOON] },
    };

    const list = await this.model
      .find(withMarketVisibility(where, viewerMarkets))
      .sort({ [orderBy]: order })
      .select(
        'title _id skillsetId level image description status numberOfLesson isNew publishAt newDurationDays author viewCount',
      )
      .lean();

    return { list };
  }

  async findBriefBySkillsetIds(
    skillsetIds: string[],
    order: OrderType,
    orderBy: string,
    viewerMarkets?: string[] | null,
  ) {
    if (!skillsetIds.length) return [];

    const where: FilterQuery<Course> = {
      skillsetId: { $in: skillsetIds },
      status: { $in: [CourseStatus.PUBLISHED, CourseStatus.COMING_SOON] },
    };

    return (
      this.model
        .find(withMarketVisibility(where, viewerMarkets))
        .sort({ [orderBy]: order })
        // `description` (ITranslation, 5 languages, ~450B/course) is intentionally
        // omitted: no surface that consumes this skillsets brief renders a course
        // description (Home, Explore, change-course, my-courses show only title +
        // image + badge). It was ~30% of the /skillsets payload.
        .select(
          'title _id skillsetId level image status numberOfLesson isNew publishAt newDurationDays author viewCount',
        )
        .lean()
    );
  }

  /**
   * Just the content-tag pointer for these courses, any status. Backs the
   * batch version resolution behind cross-course lists (saved cards, daily
   * warm-up), where every item can sit on a different tag and resolving them
   * one at a time would be N round-trips per render.
   * See `plans/260907-course-content-versions/README.md`.
   */
  async findVersionPointers(
    courseIds: string[],
  ): Promise<Array<{ _id: any; currentVersionId?: string | null }>> {
    const objectIds = courseIds.filter(id => Types.ObjectId.isValid(id));
    if (!objectIds.length) return [];

    return this.model
      .find({ _id: { $in: objectIds } }, { currentVersionId: 1 })
      .lean<Array<{ _id: any; currentVersionId?: string | null }>>();
  }

  /**
   * Every course id, any status. Used by the content-version backfill, which
   * has to reach draft and coming-soon courses too -- a course published later
   * must already have a tag, or it would go live untagged.
   * See `plans/260907-course-content-versions/README.md`.
   */
  async findAllIds(): Promise<string[]> {
    const ids = await this.model.distinct('_id');

    return ids.map(String);
  }

  /**
   * Brief course docs for the given ids (published / coming-soon only).
   * Order is not guaranteed — callers that need a specific order should
   * re-sort by the input ids.
   */
  async findBriefByIds(ids: string[]) {
    // Uncastable ids dropped for the same reason as
    // `KeypointRepository.findBriefByIds` — see its doc. These lists come from
    // client-written rows, and a CastError here 500s the caller's whole list.
    const objectIds = ids.filter(id => Types.ObjectId.isValid(id));
    if (!objectIds.length) return [];

    const where: FilterQuery<Course> = {
      _id: { $in: objectIds },
      status: { $in: [CourseStatus.PUBLISHED, CourseStatus.COMING_SOON] },
    };

    return this.model
      .find(where)
      .select(
        'title _id skillsetId level image description status numberOfLesson isNew publishAt newDurationDays author viewCount',
      )
      .lean();
  }

  /** Ứng viên cho gợi ý onboarding: published + hiện được ở thị trường + chạm ≥1 nhãn hoặc mong muốn. */
  async findOnboardingCandidates(params: {
    labelCodes: string[];
    desireCode: string | null;
    viewerMarkets?: string[] | null;
  }): Promise<IOnboardingCourseCandidate[]> {
    const or: FilterQuery<Course>[] = [];
    if (params.labelCodes.length)
      or.push({ onboardingLabelCodes: { $in: params.labelCodes } });
    if (params.desireCode)
      or.push({ onboardingDesireCodes: params.desireCode });
    if (!or.length) return [];
    const where: FilterQuery<Course> = {
      status: CourseStatus.PUBLISHED,
      // A 0-lesson course deserialises as `numberOfLesson: 0` on the client,
      // and the tap handler reads that as "nothing to open" and refuses to
      // launch it (see `COURSE_CARD_FIELDS` doc above) — so a freshly tagged
      // but still-empty course must never win the "Phù hợp nhất" onboarding
      // slot. `findPublishedFallback` already filters this; the ranker's
      // `hasLessons` is only a tiebreak, not a filter, so it has to happen here.
      numberOfLesson: { $gt: 0 },
      $or: or,
    };
    return this.model
      .find(withMarketVisibility(where, params.viewerMarkets))
      .select(ONBOARDING_CANDIDATE_FIELDS)
      .lean() as unknown as Promise<IOnboardingCourseCandidate[]>;
  }

  /** Bù cho đủ 3: trước hết khoá có mong muốn cùng nhánh, rồi khoá published mới nhất. */
  async findPublishedFallback(params: {
    excludeIds: string[];
    desireCodes: string[];
    limit: number;
    viewerMarkets?: string[] | null;
  }): Promise<IOnboardingCourseCandidate[]> {
    if (params.limit <= 0) return [];
    const exclude = params.excludeIds.map(id => new Types.ObjectId(id));
    const base: FilterQuery<Course> = {
      status: CourseStatus.PUBLISHED,
      _id: { $nin: exclude },
      numberOfLesson: { $gt: 0 },
    };
    const rows: IOnboardingCourseCandidate[] = [];
    if (params.desireCodes.length) {
      const byDesire = await this.model
        .find(
          withMarketVisibility(
            { ...base, onboardingDesireCodes: { $in: params.desireCodes } },
            params.viewerMarkets,
          ),
        )
        .select(ONBOARDING_CANDIDATE_FIELDS)
        .sort({ createdAt: -1 })
        .limit(params.limit)
        .lean();
      rows.push(...(byDesire as unknown as IOnboardingCourseCandidate[]));
    }
    if (rows.length < params.limit) {
      const taken = [...exclude, ...rows.map(r => r._id)];
      const newest = await this.model
        .find(
          withMarketVisibility(
            { ...base, _id: { $nin: taken } },
            params.viewerMarkets,
          ),
        )
        .select(ONBOARDING_CANDIDATE_FIELDS)
        .sort({ createdAt: -1 })
        .limit(params.limit - rows.length)
        .lean();
      rows.push(...(newest as unknown as IOnboardingCourseCandidate[]));
    }
    return rows;
  }

  async updateOnboardingTags(
    courseId: string,
    tags: { onboardingLabelCodes: string[]; onboardingDesireCodes: string[] },
  ): Promise<void> {
    await this.model.updateOne({ _id: courseId }, { $set: tags });
  }

  /** Import khớp khoá theo tiêu đề tiếng Việt khi sheet không có Course ID. */
  async findIdByViTitle(title: string): Promise<string | null> {
    const normalized = title.trim().replace(/\s+/g, ' ');
    if (!normalized) return null;
    const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const row = await this.model
      .findOne({
        'title.vi': { $regex: `^\\s*${escaped}\\s*$`, $options: 'i' },
      })
      .select('_id')
      .lean();
    return row ? String(row._id) : null;
  }

  async updateNumberOfLesson(number: number, id: string) {
    await this.model.updateOne({ _id: id }, { numberOfLesson: number });
  }

  // Every course's id + title + skillset, all statuses — used by the
  // habit/reanchor export-import resolver to map a course's English title to
  // its id (and reuse the course's skillsetId when seeding habits).
  async findAllBriefTitles() {
    return this.model
      .find({})
      .select('title _id skillsetId voiceoverViProvider')
      .lean();
  }

  /**
   * The Vietnamese voiceover provider of one course, without loading the rest
   * of it. Read once per course by a dub run (never per keypoint), so it stays
   * a projection rather than a full document fetch.
   */
  async findVoiceoverViProvider(courseId: string): Promise<string | null> {
    const course: any = await this.model
      .findById(courseId)
      .select('voiceoverViProvider')
      .lean();
    return course?.voiceoverViProvider ?? null;
  }

  /** Card-sized summaries for a known id set — published only, since these
   * surface to end users ("Read more on this"). */
  async findPublishedSummariesByIds(ids: string[]) {
    if (!ids.length) return [];
    return this.model
      .find({ _id: { $in: ids }, status: CourseStatus.PUBLISHED })
      .select('title image author skillsetId viewCount')
      .lean();
  }

  /**
   * Courses for an editor-curated Explore strip, in the order the editor
   * arranged them.
   *
   * Separate from `findBriefByIds` for one reason: market visibility. A
   * collection is a hand-picked list, so nothing else filters it — without this
   * an editor in Hanoi could pin a course that a reader in another market is
   * not allowed to open, and the strip would hand them a dead tile.
   *
   * Mongo returns `$in` in its own order, so the caller's order is restored
   * here rather than left to the client.
   */
  async findCollectionCoursesByIds(
    ids: string[],
    viewerMarkets?: string[] | null,
  ) {
    const objectIds = ids.filter(id => Types.ObjectId.isValid(id));
    if (!objectIds.length) return [];

    const where: FilterQuery<Course> = {
      _id: { $in: objectIds },
      status: { $in: [CourseStatus.PUBLISHED, CourseStatus.COMING_SOON] },
    };

    const rows = await this.model
      .find(withMarketVisibility(where, viewerMarkets))
      .select(COURSE_CARD_FIELDS)
      .lean();

    const rank = new Map(ids.map((id, index) => [id, index]));
    return rows.sort(
      (a, b) =>
        (rank.get(a._id.toString()) ?? Number.MAX_SAFE_INTEGER) -
        (rank.get(b._id.toString()) ?? Number.MAX_SAFE_INTEGER),
    );
  }

  /**
   * Published courses with lessons in any of these skillsets, none of the
   * excluded ids, newest first.
   *
   * Newest rather than `$sample` on purpose: the Coach's course card is
   * resolved once at the tail and shown again on resume, and a card that
   * changes its mind between two renders reads as a glitch. Same market
   * visibility as the catalogue — a course the reader cannot open in the app
   * is not a suggestion.
   */
  async findPublishedInSkillsets(params: {
    skillsetIds: string[];
    excludeIds: string[];
    viewerMarkets?: string[] | null;
    limit?: number;
    /**
     * Defaults to the Coach's narrow projection, which renders a name and an
     * image and nothing else. A surface whose cards can be TAPPED must pass
     * `COURSE_CARD_FIELDS` — see its doc.
     */
    select?: string;
  }) {
    const {
      skillsetIds,
      excludeIds,
      viewerMarkets,
      limit = 5,
      select = 'title image author skillsetId viewCount',
    } = params;
    if (!skillsetIds.length) return [];

    const excluded = excludeIds
      .filter(id => Types.ObjectId.isValid(id))
      .map(id => new Types.ObjectId(id));

    const where: FilterQuery<Course> = {
      skillsetId: { $in: skillsetIds },
      status: CourseStatus.PUBLISHED,
      numberOfLesson: { $gt: 0 },
      ...(excluded.length ? { _id: { $nin: excluded } } : {}),
    };

    return this.model
      .find(withMarketVisibility(where, viewerMarkets))
      .select(select)
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
  }

  async findRandomPublishedCourseIdInSkillset(
    skillsetId: string,
    excludedCourseId?: string,
    viewerMarkets?: string[] | null,
  ): Promise<string | null> {
    const match: FilterQuery<Course> = {
      skillsetId,
      status: CourseStatus.PUBLISHED,
      numberOfLesson: { $gt: 0 },
    };

    if (excludedCourseId && Types.ObjectId.isValid(excludedCourseId)) {
      match._id = { $ne: new Types.ObjectId(excludedCourseId) };
    }

    const [course] = await this.model.aggregate<{ _id: Types.ObjectId }>([
      { $match: withMarketVisibility(match, viewerMarkets) },
      { $sample: { size: 1 } },
      { $project: { _id: 1 } },
    ]);

    return course?._id.toString() ?? null;
  }

  /**
   * The most recently created published course that has lessons — what the daily
   * new-course notification announces.
   *
   * Ordered by `createdAt`, not `publishAt`: a Coming Soon course scheduled for a
   * future date is not published yet, and one flipped by hand may have no
   * `publishAt` at all, so creation time is the only field every course has.
   * `numberOfLesson > 0` because pushing a course with nothing to open is a dead
   * end, and it is the same filter the suggest-course widgets use.
   */
  async findNewestPublished() {
    return this.model
      .findOne(
        withMarketVisibility(
          {
            status: CourseStatus.PUBLISHED,
            numberOfLesson: { $gt: 0 },
          },
          // `[]` -- a viewer belonging to no market -- resolves to "untargeted
          // courses only", which is exactly what this caller needs. The push
          // runs on a cron and announces ONE course to every recipient in the
          // tick (`resolveSharedContext` hoists it), so there is no viewer to
          // target by. Announcing a Vietnam-only course to Japan would be a
          // notification whose content the reader cannot find in the app.
          // Consequence, on purpose: a day whose newest course is
          // market-restricted has no new-course push. Per-market announcements
          // are a separate job.
          [],
        ),
      )
      .sort({ createdAt: -1 })
      .lean();
  }

  /**
   * Flips every Coming Soon course whose scheduled `publishAt` has passed to
   * Published. Courses with no `publishAt` stay Coming Soon until edited by
   * hand. `publishAt`/`newDurationDays` are kept on the document — the app
   * still derives the "New course" window (`publishAt … +newDurationDays`)
   * from them after the flip. Idempotent, so overlapping runs are harmless.
   * Returns the number of courses published.
   */
  /**
   * Ids of the courses the next `publishDueComingSoonCourses` will flip. Read
   * before the flip because `updateMany` only reports a count, and a course
   * going live needs a content tag -- a live course without one would serve
   * the working tree to real users.
   * See `plans/260907-course-content-versions/README.md`.
   */
  async findDueComingSoonIds(now: Date = new Date()): Promise<string[]> {
    const ids = await this.model.distinct('_id', {
      status: CourseStatus.COMING_SOON,
      publishAt: { $ne: null, $lte: now },
    });

    return ids.map(String);
  }

  async publishDueComingSoonCourses(now: Date = new Date()): Promise<number> {
    const result = await this.model.updateMany(
      {
        status: CourseStatus.COMING_SOON,
        publishAt: { $ne: null, $lte: now },
      },
      { $set: { status: CourseStatus.PUBLISHED } },
    );

    return result.modifiedCount ?? 0;
  }
}
