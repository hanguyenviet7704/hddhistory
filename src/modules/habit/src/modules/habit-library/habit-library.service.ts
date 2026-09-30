import { Injectable, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { UserMetaDto } from '@base/database/mongodb/abstract.dto';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CreateHabitLibraryDto } from './dto/create-habit-library.dto';
import { GetListHabitLibraryDto } from './dto/get-list-habit-library.dto';
import { ImportHabitLibraryDto } from './dto/import-habit-library.dto';
import { UpdateHabitLibraryDto } from './dto/update-habit-library.dto';
import { HabitLibraryStatus } from './enum/habit-library.enum';
import { HabitLibraryRepository } from './repository/habit-library.repository';
import { HabitLibrary } from './schema/habit-library.schema';
import { HabitContentResolver } from '../../shared/habit-content-resolver.service';

const LANG_KEYS = ['vi', 'en', 'zh', 'ja', 'ko'] as const;

// Plain singleton on purpose: this service is on the hot read path
// (UserHabitService.enrichWithLibrary → findByIds on every /user-habits load),
// so it must NOT inject the request-scoped RequestService — that would force
// itself, UserHabitService and both controllers to be re-instantiated per
// request. Admin write paths (create/importReplace) take the actor as a `user`
// argument supplied by the controller instead.
@Injectable()
export class HabitLibraryService {
  constructor(
    private readonly habitLibraryRepository: HabitLibraryRepository,
    private readonly resolver: HabitContentResolver,
    private readonly i18n: I18nService,
  ) {}

  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  private notFoundError() {
    return new NotFoundException(
      this.i18n.t('error.HABIT.NOT_FOUND', { lang: this.lang }),
    );
  }

  private pickLangs(value: any): Record<string, string> {
    const out: Record<string, string> = {};
    for (const k of LANG_KEYS) {
      const v = value?.[k];
      if (typeof v === 'string' && v.trim()) out[k] = v;
    }
    return out;
  }

  private meta(user?: IUser) {
    return plainToInstance(UserMetaDto, user, {
      excludeExtraneousValues: true,
    });
  }

  private stamp<T extends Record<string, any>>(doc: T, user?: IUser): T {
    const cleanUser = this.meta(user);
    return { ...doc, createdBy: cleanUser, updatedBy: cleanUser };
  }

  async findAll(dto: GetListHabitLibraryDto) {
    // End-user default stays published-only; admin passes `isAll` (every
    // status) or an explicit `status` filter.
    const status = dto.isAll
      ? undefined
      : (dto.status ?? HabitLibraryStatus.PUBLISHED);

    // Resolve a course to its keypoints HERE, through the same roadmap walk
    // importReplace uses. Doing it in the client from the lesson list instead
    // meant the filter and the import read two different sources: habits could
    // be attached exactly as the sheet asked and still be invisible under
    // their own course. Same walk on both sides makes that impossible.
    let keypointIds: string[] | undefined;
    if (dto.courseId) {
      const { byKeypointId } = await this.resolver.buildSectionMap(
        dto.courseId,
      );
      keypointIds = Array.from(byKeypointId.keys());
    }

    return this.habitLibraryRepository.findList({
      skillsetId: dto.skillsetId,
      keypointId: dto.keypointId,
      keypointIds,
      status,
    });
  }

  async findOne(id: string) {
    const habit = await this.habitLibraryRepository.findById(id);
    if (!habit) throw this.notFoundError();
    return habit;
  }

  /**
   * The published courses that teach this habit's keypoints — the habit
   * detail's "Read more on this" rail. Most-relevant course first.
   *
   * Capped, because the underlying relation is far wider than the rail. A habit
   * is shared by every keypoint that suggests it: on dev the busiest one is
   * attached to 167 keypoints spread over dozens of courses, and returning all
   * of them turned a browsable rail into a swipe with no end. The resolver
   * already sorts by how many of this habit's keypoints each course teaches, so
   * taking the head keeps the most relevant ones.
   */
  static readonly COURSES_FOR_HABIT_LIMIT = 7;

  async coursesForHabit(id: string) {
    const habit = await this.habitLibraryRepository.findById(id);
    if (!habit) throw this.notFoundError();
    const keypointIds = ((habit as any).keypointIds ?? []).map((kp: any) =>
      kp.toString(),
    );
    const courses = await this.resolver.coursesForKeypoints(keypointIds);
    return courses.slice(0, HabitLibraryService.COURSES_FOR_HABIT_LIMIT);
  }

  /**
   * Courses that OPEN with this habit — see
   * `HabitContentResolver.coursesWithKeypointsInFirstLesson`.
   */
  async coursesOpeningWithHabit(id: string) {
    const habit = await this.habitLibraryRepository.findById(id);
    if (!habit) return [];

    const keypointIds = (((habit as any).keypointIds ?? []) as any[]).map((kp) =>
      kp.toString(),
    );

    return this.resolver.coursesWithKeypointsInFirstLesson(keypointIds);
  }

  /**
   * Published courses whose lessons contain this keypoint, best match first.
   *
   * Ưu tiên 1 of the Coach's course card — "khoá chứa keypoint Coach vừa dùng ở
   * nhịp 4". Unlike `coursesOpeningWithHabit` the keypoint may sit in any
   * lesson: the promise here is "the thing I just said is in this course", not
   * "this course starts with it".
   */
  async coursesWithKeypoint(keypointId: string) {
    if (!keypointId) return [];

    return this.resolver.coursesForKeypoints([keypointId]);
  }

  /**
   * Published courses whose lessons CONTAIN this habit, best match first.
   *
   * The Coach's course card selects from these — the owner's call of
   * 2026-08-27 loosened the doc's "bài đầu tiên chứa habit" rule to "khoá chứa
   * habit": on real content almost no course opened with a habit, so the card
   * never appeared at all. A promise kept on lesson three beats one never made.
   */
  async coursesWithHabit(id: string) {
    const habit = await this.habitLibraryRepository.findById(id);
    if (!habit) return [];

    const keypointIds = (((habit as any).keypointIds ?? []) as any[]).map((kp) =>
      kp.toString(),
    );

    return this.resolver.coursesForKeypoints(keypointIds);
  }

  async create(dto: CreateHabitLibraryDto, user?: IUser) {
    return this.habitLibraryRepository.create(
      { ...dto } as unknown as Partial<HabitLibrary>,
      user,
    );
  }

  async update(id: string, dto: UpdateHabitLibraryDto) {
    const updated = await this.habitLibraryRepository.findOneAndUpdate(
      { _id: id },
      { $set: dto },
    );
    if (!updated) throw this.notFoundError();
    return updated;
  }

  async remove(id: string) {
    const habit = await this.habitLibraryRepository.findById(id);
    if (!habit) throw this.notFoundError();
    await this.habitLibraryRepository.deleteOne({ _id: id });
    return { deleted: true };
  }

  async findByIds(ids: string[]) {
    return this.habitLibraryRepository.findByIds(ids);
  }

  // Portable export: every published habit, reverse-mapped from keypointId to
  // (courseId, section, keypoint) via each course's roadmap. One row per
  // (habit x keypoint it is attached to).
  //
  // `courseId` is what an import reads back; `course` is the title, written
  // alongside it so the sheet stays readable to a content editor. Only the id
  // travels as identity — a title can be renamed or shared by two courses.
  async exportAll() {
    const { byId } = await this.resolver.buildCourseIndex();
    // keypointId -> { courseId, course, section, keypoint, titleVi } across all
    // courses.
    const kpIndex = new Map<
      string,
      {
        courseId: string;
        course: string;
        section: number;
        keypoint: number;
        titleVi: string;
      }
    >();
    for (const [courseId, course] of byId) {
      const { byKeypointId } = await this.resolver.buildSectionMap(courseId);
      for (const [kpId, loc] of byKeypointId) {
        if (!kpIndex.has(kpId)) {
          kpIndex.set(kpId, {
            courseId,
            // A course with no English title is still exportable now that the
            // id carries identity; it used to be skipped entirely, dropping its
            // habits from the file without a word.
            course: course.titleEn ?? '',
            ...loc,
          });
        }
      }
    }

    const habits = await this.habitLibraryRepository.findAllPublished();
    const out: Array<{
      id?: string;
      courseId: string;
      course: string;
      section: number;
      keypoint: number;
      keypointTitleVi: string;
      habitIndex: number;
      image: string;
      title: Record<string, string>;
      description: Record<string, string>;
      contexts: Record<string, string>;
      rubric: Record<string, string>;
      ladder: Record<string, string>;
    }> = [];
    for (const h of habits as any[]) {
      for (const kpId of h.keypointIds ?? []) {
        const loc = kpIndex.get(kpId?.toString());
        if (!loc) continue; // keypoint not in any roadmap — skip
        out.push({
          id: h._id?.toString(),
          courseId: loc.courseId,
          course: loc.course,
          section: loc.section,
          keypoint: loc.keypoint,
          keypointTitleVi: loc.titleVi,
          habitIndex: (h.order ?? 0) + 1,
          image: h.image ?? '',
          title: this.pickLangs(h.title),
          description: this.pickLangs(h.description ?? {}),
          contexts: this.pickLangs(h.contexts ?? {}),
          rubric: this.pickLangs(h.rubric ?? {}),
          ladder: this.pickLangs(h.ladder ?? {}),
        });
      }
    }
    out.sort(
      (a, b) =>
        a.course.localeCompare(b.course) ||
        a.section - b.section ||
        a.keypoint - b.keypoint ||
        a.habitIndex - b.habitIndex,
    );
    return out;
  }

  // Upsert per keypoint present in the file: for each resolved keypoint, match
  // incoming rows to existing habits by `id` (falling back to position/order)
  // and UPDATE them in place — preserving each habit's _id so adopted user
  // habits (UserHabit.habitId) stay valid — creating rows with no match and
  // deleting/detaching existing habits no longer present in the file. Missing
  // courses/keypoints are reported, never created.
  /**
   * A habit's identity across the whole library is its TITLE — the sheet's
   * habit vocabulary (H1..H24) has no other stable key that survives the
   * export/import round trip. Normalized the same way course titles are, with
   * `en` preferred and `vi` as the fallback for rows authored Vietnamese-first.
   */
  /** A translation map with blank values dropped, or null when nothing is left. */
  private nonEmptyLangs(
    value?: Record<string, string> | null,
  ): Record<string, string> | null {
    if (!value) return null;
    const kept = Object.fromEntries(
      Object.entries(value)
        .map(([lang, text]) => [lang, typeof text === 'string' ? text.trim() : ''])
        .filter(([, text]) => text),
    ) as Record<string, string>;

    return Object.keys(kept).length ? kept : null;
  }

  private habitTitleKey(title: any): string {
    const en = typeof title?.en === 'string' ? title.en.trim() : '';
    const vi = typeof title?.vi === 'string' ? title.vi.trim() : '';
    return this.resolver.normalizeTitle(en || vi);
  }

  /**
   * Replace the library with the sheet's habit map — ONE doc per habit, its
   * `keypointIds` the union of every keypoint the sheet attaches it to.
   *
   * The sheet's model is a SHARED habit: H1 is suggested by dozens of
   * keypoints. This used to be flattened into one doc per (habit, keypoint)
   * pair — same title, ~40 different `_id`s — which made the same habit
   * adoptable once per keypoint: `UserHabit.habitId` differed each time, so
   * neither the server nor the app could tell the copies were one habit, and
   * users ended up with duplicate cards on the Habit tab. Grouping by
   * [habitTitleKey] restores the model the schema was built for (`keypointIds`
   * is an array for exactly this reason).
   *
   * Reconciliation is also by title: the first existing doc with the title is
   * updated IN PLACE (adopted habits keep pointing at a live doc), surplus
   * same-title docs are deleted, titles gone from the sheet are deleted. A
   * flattened library therefore collapses to one doc per habit on the first
   * import after this change — adopted habits that referenced a surplus copy
   * are orphaned then, which on dev is the accepted cost of de-duplicating.
   *
   * Two things the shared doc cannot carry are knowingly dropped: a
   * per-keypoint suggestion order (the sheet may put H1 first on one keypoint
   * and third on another — first seen wins) and a per-course skillset (first
   * seen wins as well).
   */
  async importReplace(dto: ImportHabitLibraryDto, user?: IUser) {
    const { byId } = await this.resolver.buildCourseIndex();
    const byCourse = new Map<string, ImportHabitLibraryDto['rows']>();
    for (const row of dto.rows) {
      const key = (row.courseId ?? '').trim();
      if (!byCourse.has(key)) byCourse.set(key, []);
      byCourse.get(key)!.push(row);
    }

    let created = 0;
    let updated = 0;
    let deleted = 0;
    const coursesMissing: string[] = [];
    const keypointsUnresolved: Array<{
      course: string;
      section: number;
      keypoint: number;
    }> = [];
    const errors: Array<{ course: string; message: string }> = [];
    const matchedCourses = new Set<string>();

    // ---- Phase 1: resolve every row to its keypoint, habit identity intact.
    type ResolvedRow = {
      titleKey: string;
      title: Record<string, string>;
      skillsetId: any;
      order: number;
      kpId: string;
      course: string;
      image: string;
      description: Record<string, string> | null;
  contexts: Record<string, string> | null;
  rubric: Record<string, string> | null;
  ladder: Record<string, string> | null;
};
    const resolvedRows: ResolvedRow[] = [];
    for (const [key, rows] of byCourse) {
      // Exact, by id. No title lookup and no loose fallback: those existed to
      // survive punctuation drift in a title column, and brought with them the
      // failure they were meant to soften — two courses sharing a title, where
      // the habits silently went to whichever one was indexed first.
      const course = key ? byId.get(key) : undefined;
      if (!course) {
        // Label by title where the sheet supplied one; an ObjectId alone tells
        // an editor nothing about which rows to go and fix. Name the row count
        // too — one bullet used to stand for a whole course, so losing 24 rows
        // looked the same as losing 3.
        const label = rows[0].course?.trim() || '(no title in sheet)';
        coursesMissing.push(
          `${label} [${key || 'blank Course ID'}] (${rows.length} rows)`,
        );
        continue;
      }
      matchedCourses.add(key);
      // What the reports call this course. The stored title beats the sheet's,
      // which is now only a hint and may be stale after a rename.
      const label = course.titleEn?.trim() || rows[0].course?.trim() || key;
      const { sections } = await this.resolver.buildSectionMap(course.courseId);

      for (const r of rows) {
        const section = sections[(r.section ?? 0) - 1];
        const kpId = section ? section[(r.keypoint ?? 0) - 1] : undefined;
        if (!kpId) {
          keypointsUnresolved.push({
            course: label,
            section: r.section,
            keypoint: r.keypoint,
          });
          continue;
        }
        resolvedRows.push({
          titleKey: this.habitTitleKey(r.title),
          title: this.pickLangs(r.title),
          skillsetId: course.skillsetId,
          order: (r.habitIndex ?? 1) - 1,
          kpId,
          course: label,
          image: (r.image ?? '').trim(),
          description: this.nonEmptyLangs(r.description),
          contexts: this.nonEmptyLangs(r.contexts),
          rubric: this.nonEmptyLangs(r.rubric),
          ladder: this.nonEmptyLangs(r.ladder),
        });
      }
    }

    // ---- Phase 2: one group per habit, keypointIds as the union.
    type HabitGroup = {
      title: Record<string, string>;
      skillsetId: any;
      order: number;
      kpIds: Set<string>;
      course: string;
      image: string;
      description: Record<string, string> | null;
      contexts: Record<string, string> | null;
      rubric: Record<string, string> | null;
      ladder: Record<string, string> | null;
    };
    const groups = new Map<string, HabitGroup>();
    for (const row of resolvedRows) {
      const group = groups.get(row.titleKey);
      if (group) {
        group.kpIds.add(row.kpId);
        // Unlike skillsetId and order — where the first row seen wins — the
        // first NON-EMPTY picture wins. One habit is repeated across every
        // keypoint that suggests it, often dozens of rows; making an editor
        // paste the same url into all of them to avoid a blank one clobbering
        // it would be a trap. Leave every row blank and it still clears.
        if (!group.image && row.image) group.image = row.image;
        // Same rule for the Coach's grounding text: first non-empty wins.
        if (!group.description && row.description) group.description = row.description;
        if (!group.contexts && row.contexts) group.contexts = row.contexts;
        if (!group.rubric && row.rubric) group.rubric = row.rubric;
        if (!group.ladder && row.ladder) group.ladder = row.ladder;
      } else {
        groups.set(row.titleKey, {
          title: row.title,
          skillsetId: row.skillsetId,
          order: row.order,
          kpIds: new Set([row.kpId]),
          course: row.course,
          image: row.image,
          description: row.description,
          contexts: row.contexts,
          rubric: row.rubric,
          ladder: row.ladder,
        });
      }
    }

    // ---- Phase 3: reconcile against the whole library, by title.
    const existing = (await this.habitLibraryRepository.findList(
      {},
    )) as any[];
    const existingByTitle = new Map<string, any[]>();
    for (const doc of existing) {
      const key = this.habitTitleKey(doc.title);
      const bucket = existingByTitle.get(key) ?? [];
      bucket.push(doc);
      existingByTitle.set(key, bucket);
    }

    for (const [titleKey, group] of groups) {
      try {
        const fields = {
          title: group.title,
          skillsetId: group.skillsetId,
          order: group.order,
          status: HabitLibraryStatus.PUBLISHED,
          keypointIds: Array.from(group.kpIds),
          // Written even when blank, so emptying the column in the sheet
          // actually removes the picture. A replace import treats the sheet as
          // the whole truth; a field that only ever gets set and never cleared
          // would leave the file unable to undo its own edit.
          image: group.image || null,
          // Unlike the picture, a blank column here does NOT clear: these are
          // written by the Coach team in admin as often as by the sheet, and
          // a habit sheet that never carried them must not wipe them.
          ...(group.description ? { description: group.description } : {}),
          ...(group.contexts ? { contexts: group.contexts } : {}),
          ...(group.rubric ? { rubric: group.rubric } : {}),
          ...(group.ladder ? { ladder: group.ladder } : {}),
        };
        const docs = existingByTitle.get(titleKey) ?? [];
        if (docs.length) {
          await this.habitLibraryRepository.findOneAndUpdate(
            { _id: docs[0]._id },
            { $set: { ...fields, updatedBy: this.meta(user) } },
          );
          updated++;
          // Surplus same-title docs are the flattened duplicates — remove
          // them. Adopted habits pointing at one are orphaned; keeping the
          // duplicates alive is what produced duplicate cards to begin with.
          for (const extra of docs.slice(1)) {
            await this.habitLibraryRepository.deleteById(extra._id.toString());
            deleted++;
          }
        } else {
          const inserted = await this.habitLibraryRepository.insertManyDocs([
            this.stamp(fields, user) as unknown as Partial<HabitLibrary>,
          ]);
          created += inserted.length;
        }
      } catch (e: any) {
        errors.push({ course: group.course, message: e?.message ?? 'error' });
      }
    }

    // Titles gone from the sheet: their docs go too.
    for (const [titleKey, docs] of existingByTitle) {
      if (groups.has(titleKey)) continue;
      for (const doc of docs) {
        await this.habitLibraryRepository.deleteById(doc._id.toString());
        deleted++;
      }
    }

    return {
      // rowsReceived vs rowsApplied is the one check that catches a silent
      // loss: every other number can look healthy while most of the file went
      // nowhere. They differ exactly when rows were skipped, and the lists
      // below say which. Rows deliberately COLLAPSE into shared docs now, so
      // `applied` counts resolved rows, while created/updated count docs.
      rowsReceived: dto.rows.length,
      rowsApplied: resolvedRows.length,
      coursesMatched: matchedCourses.size,
      coursesMissing,
      // `coursesMatchedLoosely` and `coursesAmbiguous` are gone with the title
      // lookup that produced them: matching on `courseId` is exact, so a course
      // is either found or reported missing — there is no third outcome to warn
      // about any more.
      keypointsMatched: new Set(resolvedRows.map(row => row.kpId)).size,
      keypointsUnresolved,
      created,
      updated,
      deleted,
      detached: 0,
      errors,
    };
  }
}
