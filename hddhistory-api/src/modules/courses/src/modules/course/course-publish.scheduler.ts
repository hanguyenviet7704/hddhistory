import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

import { CourseRepository } from './repository/course.repository';
import { CourseVersionService } from '../course-version/course-version.service';

/**
 * Auto-publishes scheduled Coming Soon courses.
 *
 * Every minute, any course with `status = coming_soon` and a `publishAt` in
 * the past is flipped to `published` in the database — so the status shown in
 * the admin matches what end users actually see. The app's "New course" badge
 * window (`publishAt … +newDurationDays`) keeps working after the flip since
 * both fields stay on the document.
 *
 * The update is a single idempotent `updateMany`, so a missed tick just means
 * the flip happens on the next one, and concurrent runs can't double-apply.
 */
@Injectable()
export class CoursePublishScheduler {
  private readonly logger = new Logger(CoursePublishScheduler.name);

  constructor(
    private readonly courseRepository: CourseRepository,
    // Singleton on purpose -- if CourseVersionService injected the
    // request-scoped RequestService, that scope would bubble up here and
    // silently kill this @Cron. See the note on CourseVersionService.
    private readonly courseVersionService: CourseVersionService,
  ) {}

  @Cron(CronExpression.EVERY_MINUTE)
  async publishDueCourses(): Promise<void> {
    try {
      // Read the ids first: `updateMany` only reports a count, and a course
      // going live must already have a content tag, or it would serve the
      // working tree -- half-finished edits included -- to real users.
      const dueIds = await this.courseRepository.findDueComingSoonIds();
      const published = await this.courseRepository.publishDueComingSoonCourses();
      if (published > 0) {
        this.logger.log(
          `Auto-published ${published} scheduled course(s) whose publishAt passed`,
        );
      }

      for (const courseId of dueIds) {
        // Idempotent and it swallows a raced duplicate, so a missed or
        // overlapping tick is harmless.
        const tag = await this.courseVersionService.ensureInitialTag(courseId);
        if (tag) {
          this.logger.log(`Tagged newly published course ${courseId} ${tag.tag}`);
        }
      }
    } catch (error: any) {
      // Never let a scheduler tick take anything else down; log and retry on
      // the next minute.
      this.logger.error(
        `Failed to auto-publish scheduled courses: ${error?.message}`,
        error?.stack,
      );
    }
  }
}
