import { Module } from '@nestjs/common';

import { StudyJournalModule } from './study-journal/study-journal.module';
import { UserProgressModule } from './user-progress/user-progress.module';
import { UserStreakModule } from './user-streak/user-streak.module';
import { UserVideoLessonActivityModule } from './user-video-lesson-activity/user-video-lesson-activity.module';
import { WeekRecapModule } from './week-recap/week-recap.module';

@Module({
  imports: [
    StudyJournalModule,
    UserProgressModule,
    UserStreakModule,
    UserVideoLessonActivityModule,
    WeekRecapModule,
  ],
})
export class ProgressModule {}
