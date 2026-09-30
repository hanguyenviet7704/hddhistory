import { Injectable } from '@nestjs/common';

import { RecordCourseViewDto } from './dto/recently-viewed.dto';
import { RecentlyViewedRepository } from './recently-viewed.repository';
import { CourseRepository } from '../course/repository/course.repository';

@Injectable()
export class RecentlyViewedService {
  constructor(
    private readonly recentlyViewedRepository: RecentlyViewedRepository,
    private readonly courseRepository: CourseRepository,
  ) {}

  async recordView(userId: string, dto: RecordCourseViewDto): Promise<void> {
    await this.recentlyViewedRepository.upsertView(userId, dto.courseId);
  }

  /**
   * Recently-viewed courses for the user, most-recent first. Returns brief
   * course docs (same shape the search results / explore lists consume).
   */
  async getRecent(userId: string) {
    const courseIds =
      await this.recentlyViewedRepository.getRecentCourseIds(userId);
    if (!courseIds.length) return [];

    const courses = await this.courseRepository.findBriefByIds(courseIds);

    // Re-order to match the recency order (and drop ids whose course was
    // unpublished/deleted since it was viewed).
    const byId = new Map(courses.map(c => [c._id.toString(), c]));
    return courseIds.map(id => byId.get(id)).filter(Boolean);
  }

  async clearAll(userId: string): Promise<void> {
    await this.recentlyViewedRepository.clearAll(userId);
  }
}
