import { Injectable, Logger } from '@nestjs/common';

import { viewerMarketsForRequest } from '@utils/market-query.util';
import { OrderType } from '@utils/type/orderByType';
import { SegmentService } from 'src/modules/segment/segment.service';

import {
  EXPLORE_BECAUSE_YOU_SIZE,
  EXPLORE_COLLECTION_SIZE,
  EXPLORE_WEEKLY_TOP_SIZE,
} from './explore.constant';
import { shuffle, startOfCurrentWeek } from './explore.helper';
import {
  ExploreSectionType,
  IExploreResponse,
  IExploreSection,
} from './explore.interface';
import { CourseCollectionSlot } from '../collection/enum/course-collection.enum';
import { CourseCollectionRepository } from '../collection/repository/course-collection.repository';
import {
  COURSE_CARD_FIELDS,
  CourseRepository,
} from '../course/repository/course.repository';
import { countPassedItems } from '../progress/src/modules/user-progress/helper/passed-count.helper';
import { UserProgressRepository } from '../progress/src/modules/user-progress/repository/user-progress.repository';
import { RecentlyViewedRepository } from '../recently-viewed/recently-viewed.repository';

/**
 * How many recent progress rows to look through for the last finished course.
 * Twenty is generous for "recently studied" while keeping the follow-up course
 * lookup to one page.
 */
const RECENT_PROGRESS_LOOKBACK = 20;

/**
 * Candidates pulled before narrowing to three suggestions. Wider than the three
 * shown so the shuffle has something to choose from — otherwise "random three
 * in the category" would be the same three every time for a small category.
 */
const BECAUSE_YOU_CANDIDATE_POOL = 12;

@Injectable()
export class ExploreService {
  private readonly logger = new Logger(ExploreService.name);

  constructor(
    private readonly collectionRepository: CourseCollectionRepository,
    private readonly courseRepository: CourseRepository,
    private readonly recentlyViewedRepository: RecentlyViewedRepository,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly segmentService: SegmentService,
  ) {}

  /**
   * The whole Explore tab in one response, sections already in render order.
   *
   * Deliberately NOT a singleton-per-section set of endpoints: the tab would
   * otherwise open with three round trips, and the rules that decide what goes
   * where would have to be mirrored in the app.
   *
   * Every section is built independently and a failure inside one is logged and
   * dropped, never propagated — a broken weekly aggregate should cost the reader
   * one strip, not the entire tab.
   */
  async getExplore(userId: string, headers: any): Promise<IExploreResponse> {
    const viewerMarkets = viewerMarketsForRequest(headers);

    const [collections, weeklyTop, becauseYou] = await Promise.all([
      this.safely('collections', () =>
        this.buildCollectionSections(userId, viewerMarkets),
      ),
      this.safely('weeklyTop', () => this.buildWeeklyTopSection(viewerMarkets)),
      this.safely('becauseYou', () =>
        this.buildBecauseYouSection(userId, viewerMarkets),
      ),
    ]);

    const curated = collections ?? { top: [], bottom: [] };

    // The design's order, and the only place it is decided.
    const sections: IExploreSection[] = [
      ...curated.top,
      ...(weeklyTop ? [weeklyTop] : []),
      { type: ExploreSectionType.TOPIC_CHIPS },
      ...(becauseYou ? [becauseYou] : []),
      ...curated.bottom,
    ];

    return { sections };
  }

  private async safely<T>(
    label: string,
    build: () => Promise<T>,
  ): Promise<T | null> {
    try {
      return await build();
    } catch (error) {
      this.logger.error(
        `Explore section "${label}" failed: ${(error as Error)?.message}`,
        (error as Error)?.stack,
      );
      return null;
    }
  }

  private async buildCollectionSections(
    userId: string,
    viewerMarkets: string[] | null,
  ): Promise<{ top: IExploreSection[]; bottom: IExploreSection[] }> {
    const published = await this.collectionRepository.findPublishedOrdered();
    if (!published.length) return { top: [], bottom: [] };

    // Segment targeting, by the same call banner slides and popups use: rows
    // with no segmentIds pass untouched, the rest need the viewer to match one.
    const visible = await this.segmentService.filterItemsForViewer(
      published as any[],
      userId,
    );

    const sections = await Promise.all(
      visible.map(async (collection: any) => {
        const courses = await this.courseRepository.findCollectionCoursesByIds(
          collection.courseIds ?? [],
          viewerMarkets,
        );

        return {
          slot: collection.slot,
          section: {
            type: ExploreSectionType.CURATED,
            id: collection._id.toString(),
            title: collection.title,
            // Editor order, unshuffled: the client reorders for display on
            // every visit, so shuffling here too would only mean the reader's
            // first look is already scrambled twice over. The cap is enforced
            // when the collection is saved, so the whole list is shown.
            courses: courses.slice(0, EXPLORE_COLLECTION_SIZE),
          } as IExploreSection,
        };
      }),
    );

    // An empty strip is a heading with nothing under it — drop it rather than
    // render a titled void. Happens when every pinned course is unpublished or
    // hidden in this reader's market.
    const withCourses = sections.filter(s => s.section.courses?.length);

    return {
      top: withCourses
        .filter(s => s.slot === CourseCollectionSlot.TOP)
        .map(s => s.section),
      bottom: withCourses
        .filter(s => s.slot !== CourseCollectionSlot.TOP)
        .map(s => s.section),
    };
  }

  private async buildWeeklyTopSection(
    viewerMarkets: string[] | null,
  ): Promise<IExploreSection | null> {
    const since = startOfCurrentWeek();
    const ranked = await this.recentlyViewedRepository.aggregateTopOpenedSince(
      since,
      // Over-fetch: some of the most-opened courses may since have been
      // unpublished or be invisible in this market, and dropping them must not
      // leave the card with two tiles.
      EXPLORE_WEEKLY_TOP_SIZE * 4,
    );
    if (!ranked.length) return null;

    const courses = await this.courseRepository.findCollectionCoursesByIds(
      ranked.map(r => r.courseId),
      viewerMarkets,
    );
    if (!courses.length) return null;

    const counts = new Map(ranked.map(r => [r.courseId, r.learnerCount]));
    // `findCollectionCoursesByIds` restored the id order, which here IS the
    // ranking — so the first three surviving courses are ranks 1 to 3.
    const top = courses.slice(0, EXPLORE_WEEKLY_TOP_SIZE).map(course => ({
      ...course,
      learnerCount: counts.get(course._id.toString()) ?? 0,
    }));

    return { type: ExploreSectionType.WEEKLY_TOP, courses: top };
  }

  private async buildBecauseYouSection(
    userId: string,
    viewerMarkets: string[] | null,
  ): Promise<IExploreSection | null> {
    const progress = await this.userProgressRepository.findOption({
      userId,
      page: 1,
      take: RECENT_PROGRESS_LOOKBACK,
      orderBy: 'updatedAt',
      order: OrderType.DESC,
    });

    const rows = progress?.items ?? [];
    if (!rows.length) return null;

    const studiedIds = rows.map((row: any) => row.courseId?.toString());
    const studied = await this.courseRepository.findBriefByIds(studiedIds);
    const byId = new Map(studied.map((c: any) => [c._id.toString(), c]));

    // Rows arrive newest-studied first, so the first finished one IS the most
    // recently finished course — the one the section is named after.
    let finished: any = null;
    for (const row of rows) {
      const course = byId.get(row.courseId?.toString());
      if (!course || !course.numberOfLesson) continue;
      // Same completion test the Continue-learning card and saved-courses use,
      // via the shared helper — two definitions of "finished" would eventually
      // disagree on the same course.
      if (countPassedItems(row.lessonsResult) >= course.numberOfLesson) {
        finished = course;
        break;
      }
    }
    if (!finished?.categoryId) return null;

    const candidates = await this.courseRepository.findPublishedInCategories({
      categoryIds: [finished.categoryId.toString()],
      // Nothing the reader has already opened: suggesting a course they
      // finished last week reads as the app not paying attention.
      excludeIds: studiedIds,
      viewerMarkets,
      limit: BECAUSE_YOU_CANDIDATE_POOL,
      // The default projection is the Coach's, which has no `numberOfLesson`:
      // the client would read 0 and refuse to open the course, telling the
      // reader it has no lessons yet.
      select: COURSE_CARD_FIELDS,
    });
    if (candidates.length < EXPLORE_BECAUSE_YOU_SIZE) return null;

    // WHICH three, not just their order: the spec asks for three random courses
    // from the category, and the candidate pool is wider than three precisely
    // so this choice has something to choose from.
    const picked = shuffle(candidates);

    return {
      type: ExploreSectionType.BECAUSE_YOU,
      sourceCourse: finished,
      courses: picked.slice(0, EXPLORE_BECAUSE_YOU_SIZE),
    };
  }
}
