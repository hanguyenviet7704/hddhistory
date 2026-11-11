import { Injectable, Logger } from '@nestjs/common';

import { CourseService } from 'src/modules/courses/src/modules/course/course.service';
import { CourseRepository } from 'src/modules/courses/src/modules/course/repository/course.repository';
import { LessonRepository } from 'src/modules/courses/src/modules/lesson/repository/lesson.repository';

export interface ResolvedCourse {
  courseId: string;
  categoryId: string;
  titleEn: string;
}

export interface KeypointLocation {
  section: number; // 1-based roadmap node index ("Phần n"), sequential across levels
  keypoint: number; // 1-based keypoint position within that node
  titleVi: string;
}

export interface CourseIndex {
  byTitleEn: Map<string, ResolvedCourse>;
  /**
   * Punctuation-insensitive fallback key -> course. Only holds titles whose
   * loose key is unique; a key shared by two courses is dropped rather than
   * guessed at, so a fallback match is never ambiguous.
   */
  byLooseTitleEn: Map<string, ResolvedCourse>;
  byId: Map<string, ResolvedCourse>;
  /**
   * English titles held by more than one course. The index keeps the first,
   * so anything imported under these titles lands on that one course and the
   * others silently get nothing — callers surface this instead of hiding it.
   */
  ambiguousTitleEn: Set<string>;
}

export interface SectionMap {
  // sections[sectionIdx-1][keypointIdx-1] = keypointId
  sections: string[][];
  byKeypointId: Map<string, KeypointLocation>;
}

/**
 * Shared read-only resolver used by both the re-anchor and habit-library
 * export/import services. It translates between environment-agnostic keys
 * (course `title.en`, `S{n}-KP{m}`) and per-environment ObjectIds so the same
 * .xlsx can be moved between dev and production.
 *
 * The section/keypoint ordering mirrors the roadmap exactly: a "section" is a
 * roadmap node (numbered sequentially across levels), and a keypoint's position
 * is its order within that node's lessons (sorted by lesson index, then the
 * lesson's ordered keypoints[]). Both directions share this logic so export and
 * import stay symmetric.
 */
@Injectable()
export class HabitContentResolver {
  private readonly logger = new Logger(HabitContentResolver.name);

  constructor(
    private readonly courseRepository: CourseRepository,
    private readonly courseService: CourseService,
    private readonly lessonRepository: LessonRepository,
  ) {}

  /**
   * The published courses teaching any of these keypoints — the habit detail's
   * "Read more on this" rail. Resolved through `lessons` (each lesson knows
   * its `courseId` and `keypoints`), which is two indexed queries; walking
   * every course's roadmap the way the import resolver does would rebuild the
   * whole catalog per request.
   *
   * Ordered by how many of the given keypoints each course teaches, so the
   * course MOST about this habit leads the rail.
   */
  async coursesForKeypoints(keypointIds: string[]) {
    if (!keypointIds.length) return [];
    const wanted = new Set(keypointIds.map(id => id.toString()));

    const lessons = await this.lessonRepository.findByKeypointIds(
      Array.from(wanted),
    );
    const hitsByCourse = new Map<string, number>();
    for (const lesson of lessons as any[]) {
      const courseId = lesson.courseId?.toString();
      if (!courseId) continue;
      const hits = ((lesson.keypoints ?? []) as any[]).filter(id =>
        wanted.has(id.toString()),
      ).length;
      if (hits > 0) {
        hitsByCourse.set(courseId, (hitsByCourse.get(courseId) ?? 0) + hits);
      }
    }

    const courses = await this.courseRepository.findPublishedSummariesByIds(
      Array.from(hitsByCourse.keys()),
    );
    return (courses as any[])
      .map(course => ({
        id: course._id.toString(),
        title: course.title,
        image: course.image ?? '',
        author: course.author ?? null,
        // The rail's reach chip. Sibling of `author` and blank for the same
        // reason — the card hides the chip rather than claiming "0 views".
        viewCount: course.viewCount ?? null,
        categoryId: course.categoryId?.toString() ?? '',
        keypointHits: hitsByCourse.get(course._id.toString()) ?? 0,
      }))
      .sort((a, b) => b.keypointHits - a.keypointHits);
  }

  /**
   * Courses whose FIRST lesson carries one of these keypoints.
   *
   * The Coach's card rule, straight from the doc: "khoá gợi ra phải có BÀI ĐẦU
   * TIÊN chứa habit đó. Không có khoá nào thoả → KHÔNG hiện card." Built on top
   * of the same lesson lookup as `coursesForKeypoints`, then narrowed — the
   * candidate set is small (a habit maps to a handful of lessons), so the extra
   * aggregate costs one round trip and saves offering a course whose first
   * lesson is about something else.
   */
  async coursesWithKeypointsInFirstLesson(keypointIds: string[]) {
    const candidates = await this.coursesForKeypoints(keypointIds);
    if (!candidates.length) return [];

    const wanted = new Set(keypointIds.map((id) => id.toString()));
    const firsts = (await this.lessonRepository.findFirstByCourseIds(
      candidates.map((course) => course.id),
    )) as Array<{ _id: unknown; keypoints?: unknown[] }>;

    const opensWith = new Set(
      firsts
        .filter((lesson) =>
          ((lesson.keypoints ?? []) as unknown[]).some((id) =>
            wanted.has(String(id)),
          ),
        )
        .map((lesson) => String(lesson._id)),
    );

    return candidates.filter((course) => opensWith.has(course.id));
  }

  /**
   * The two sides of a title only have to agree on the characters a human
   * would read.
   *
   * A spreadsheet is not a database: Google Sheets autocorrects `'` into `’`
   * and `-` into `–`, pasted text arrives NFD-decomposed (`ê` as `e` + U+0302)
   * while Mongo stores NFC, and a stray zero-width space survives `.trim()`.
   * Every one of those makes two visually identical titles compare unequal —
   * and an unequal title means the whole course is skipped on import. Fold
   * them all away here, on both sides of the comparison.
   */
  normalizeTitle(value?: string): string {
    return (value ?? '')
      .normalize('NFC')
      // Zero-width space/joiners and BOM: invisible, and `.trim()` keeps them.
      .replace(/[\u200B-\u200D\uFEFF]/g, '')
      // Sheets autocorrect: curly quotes and the long dashes.
      .replace(/[\u2018\u2019\u02BC]/g, "'")
      .replace(/[\u201C\u201D]/g, '"')
      .replace(/[\u2010-\u2015]/g, '-')
      .replace(/\s+/g, ' ')
      .trim()
      .toLowerCase();
  }

  /**
   * Last-resort key: letters and digits only. Catches the differences
   * [normalizeTitle] cannot — a trailing full stop, a dropped question mark,
   * `&` vs `and` spacing — which are otherwise indistinguishable from "this
   * course does not exist". Only ever used when the exact key misses, and
   * only when it resolves to exactly one course.
   */
  looseTitleKey(value?: string): string {
    return this.normalizeTitle(value).replace(/[^\p{L}\p{N}]+/gu, '');
  }

  async buildCourseIndex(): Promise<CourseIndex> {
    const courses = await this.courseRepository.findAllBriefTitles();
    const byTitleEn = new Map<string, ResolvedCourse>();
    const byLooseTitleEn = new Map<string, ResolvedCourse>();
    const byId = new Map<string, ResolvedCourse>();
    const ambiguousTitleEn = new Set<string>();
    const looseCollisions = new Set<string>();

    for (const course of courses as any[]) {
      const titleEn = ((course?.title?.en ?? '') as string).trim();
      const entry: ResolvedCourse = {
        courseId: course._id.toString(),
        categoryId: course?.categoryId ? course.categoryId.toString() : '',
        titleEn,
      };
      byId.set(entry.courseId, entry);
      if (!titleEn) continue;

      const key = this.normalizeTitle(titleEn);
      if (byTitleEn.has(key)) {
        // First match still wins so the outcome stays deterministic, but a
        // second course under the same title means everything imported for it
        // lands on the first one and this course silently gets nothing. That
        // is indistinguishable from "the import didn't run" when you look at
        // the admin, so it has to reach the caller.
        ambiguousTitleEn.add(titleEn);
      } else {
        byTitleEn.set(key, entry);
      }

      const loose = this.looseTitleKey(titleEn);
      if (!loose) continue;
      if (byLooseTitleEn.has(loose) || looseCollisions.has(loose)) {
        // Two courses that differ only in punctuation: a fallback match could
        // pick the wrong one, so refuse to guess and drop the key entirely.
        byLooseTitleEn.delete(loose);
        looseCollisions.add(loose);
      } else {
        byLooseTitleEn.set(loose, entry);
      }
    }

    return { byTitleEn, byLooseTitleEn, byId, ambiguousTitleEn };
  }

  async buildSectionMap(courseId: string): Promise<SectionMap> {
    let roadmap: any;
    try {
      roadmap = await this.courseService.findRoadmap(courseId);
    } catch (e) {
      // No roadmap for this course — treat as "no keypoints".
      return { sections: [], byKeypointId: new Map() };
    }
    const sections: string[][] = [];
    const byKeypointId = new Map<string, KeypointLocation>();
    for (const level of roadmap?.levels ?? []) {
      for (const node of level?.nodes ?? []) {
        const lessons = [...(node?.lessons ?? [])].sort(
          (a: any, b: any) => (a?.index ?? 0) - (b?.index ?? 0),
        );
        const kpList: Array<{ id: string; titleVi: string }> = [];
        for (const lesson of lessons) {
          for (const kp of lesson?.keypoints ?? []) {
            const id = (kp?._id ?? kp)?.toString?.();
            if (!id) continue;
            kpList.push({ id, titleVi: (kp?.title?.vi ?? '') as string });
          }
        }
        const sectionIndex = sections.length + 1;
        kpList.forEach((kp, i) => {
          if (!byKeypointId.has(kp.id)) {
            byKeypointId.set(kp.id, {
              section: sectionIndex,
              keypoint: i + 1,
              titleVi: kp.titleVi,
            });
          }
        });
        sections.push(kpList.map(kp => kp.id));
      }
    }
    return { sections, byKeypointId };
  }
}
