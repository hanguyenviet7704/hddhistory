import { Module } from '@nestjs/common';

import { CourseModule } from 'src/modules/courses/src/modules/course/course.module';
import { LessonModule } from 'src/modules/courses/src/modules/lesson/lesson.module';

import { HabitContentResolver } from './habit-content-resolver.service';

// Shared read-only resolver (course title.en <-> id, S/KP <-> keypointId,
// keypointIds -> courses) used by the re-anchor and habit-library
// export/import flows and the habit detail's "Read more on this" rail.
@Module({
  imports: [CourseModule, LessonModule],
  providers: [HabitContentResolver],
  exports: [HabitContentResolver],
})
export class HabitContentModule {}
