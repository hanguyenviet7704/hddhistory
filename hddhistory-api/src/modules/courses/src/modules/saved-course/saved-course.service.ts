import { Injectable } from '@nestjs/common';

import { IResponseListPage } from '@utils/interface/paging/page.interface';
import { getPagination } from '@utils/paging';

import { GetSavedCoursesDto, SaveCourseDto } from './dto/saved-course.dto';
import { SavedCourseStatus } from './enum/saved-course.enum';
import { SavedCourseRepository } from './saved-course.repository';
import { CourseRepository } from '../course/repository/course.repository';
import { countPassedItems } from '../progress/src/modules/user-progress/helper/passed-count.helper';
import { UserProgressRepository } from '../progress/src/modules/user-progress/repository/user-progress.repository';

@Injectable()
export class SavedCourseService {
  constructor(
    private readonly savedCourseRepository: SavedCourseRepository,
    private readonly courseRepository: CourseRepository,
    private readonly userProgressRepository: UserProgressRepository,
  ) {}

  async save(userId: string, dto: SaveCourseDto): Promise<void> {
    await this.savedCourseRepository.save(userId, dto.courseId);
  }

  async remove(userId: string, courseId: string): Promise<void> {
    await this.savedCourseRepository.remove(userId, courseId);
  }

  /**
   * Just the ids. The app keeps these in a set so the bookmark on the roadmap
   * header draws filled or hollow without an `isSaved` join on every course
   * payload the catalogue serves.
   */
  async getSavedIds(userId: string): Promise<string[]> {
    return this.savedCourseRepository.findCourseIds(userId);
  }

  /**
   * The Saved screen's list.
   *
   * Bucketing needs the user's progress against every saved course, and the
   * bucket is what the `status` chip filters on — so the filter cannot be
   * pushed into the `saved_courses` query and the page is cut after the join.
   * A bookmark list is user-curated and small (tens, not thousands), so the two
   * round trips read the whole set; if that ever stops being true this wants a
   * denormalised status on the row instead.
   */
  async getSaved(
    userId: string,
    dto: GetSavedCoursesDto,
  ): Promise<IResponseListPage<any>> {
    const pagination = getPagination({ page: dto.page, take: dto.take });
    const empty: IResponseListPage<any> = {
      items: [],
      itemsPerPage: pagination.take,
      totalPages: 0,
      currentPage: pagination.page,
    };

    const savedIds = await this.savedCourseRepository.findCourseIds(userId);
    if (!savedIds.length) return empty;

    const [courses, progressRows] = await Promise.all([
      this.courseRepository.findBriefByIds(savedIds),
      this.userProgressRepository.findProgressByCourseIds(userId, savedIds),
    ]);
    if (!courses.length) return empty;

    const passedByCourse = new Map<string, number>();
    for (const row of progressRows) {
      passedByCourse.set(
        row.courseId.toString(),
        countPassedItems(row.lessonsResult),
      );
    }

    // `findBriefByIds` resolves the `$in` in its own order, so recency has to be
    // restored from the saved-id order — same reason `my-course` re-ranks.
    const savedRank = new Map<string, number>();
    savedIds.forEach((id, index) => {
      if (!savedRank.has(id)) savedRank.set(id, index);
    });

    const enriched = courses
      .map((course: any) => {
        const id = course._id.toString();
        const passed = passedByCourse.get(id) ?? 0;
        const total = course.numberOfLesson ?? 0;

        return {
          ...course,
          numberOfLessonPassed: passed,
          savedStatus: this.resolveStatus(passed, total),
        };
      })
      .sort(
        (a, b) =>
          (savedRank.get(a._id.toString()) ?? Number.MAX_SAFE_INTEGER) -
          (savedRank.get(b._id.toString()) ?? Number.MAX_SAFE_INTEGER),
      );

    const filtered = dto.status
      ? enriched.filter(course => course.savedStatus === dto.status)
      : enriched;

    return {
      items: filtered.slice(pagination.skip, pagination.skip + pagination.take),
      itemsPerPage: pagination.take,
      totalPages: Math.ceil(filtered.length / pagination.take),
      currentPage: pagination.page,
    };
  }

  /**
   * A course with no items yet (`numberOfLesson === 0`, e.g. COMING_SOON) can
   * never satisfy `passed >= total` meaningfully — treating 0/0 as finished
   * would file an unreleased course under "Finished", so it stays in Up next.
   */
  private resolveStatus(passed: number, total: number): SavedCourseStatus {
    if (passed <= 0) return SavedCourseStatus.UP_NEXT;
    if (total > 0 && passed >= total) return SavedCourseStatus.FINISHED;
    return SavedCourseStatus.IN_PROGRESS;
  }
}
