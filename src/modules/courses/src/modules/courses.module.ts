import { Module } from '@nestjs/common';

import { AvatarModule } from './avatar/avatar.module';
import { CourseModule } from './course/course.module';
import { CourseCollectionModule } from './collection/course-collection.module';
import { CourseVersionModule } from './course-version/course-version.module';
import { InAppSurveyModule } from './feedback/in-app-survey/in-app-survey.module';
import { IssueReportModule } from './feedback/issue-report/issue-report.module';
import { FeedbackModule } from './feedback/user-feedback/user-feedback.module';
import { ExploreModule } from './explore/explore.module';
import { IconModule } from './icon/icon.module';
import { CourseImportModule } from './import/course-import.module';
import { KeypointModule } from './keypoint/keypoint.module';
import { LearningImportModule } from './learning-import/learning-import.module';
import { LearningItemModule } from './learning-item/learning-item.module';
import { LessonModule } from './lesson/lesson.module';
import { OutputPracticeModule } from './output-practice/output-practice.module';
import { ProgressModule } from './progress/src/modules/progress.module';
import { QuoteModule } from './quotes/quote.module';
import { RecentlyViewedModule } from './recently-viewed/recently-viewed.module';
import { SavedCardModule } from './saved-card/saved-card.module';
import { SavedCourseModule } from './saved-course/saved-course.module';
import { SearchHistoryModule } from './search-history/search-history.module';
import { SpacedReviewModule } from './spaced-review/spaced-review.module';
import { CategoryModule } from './category/category.module';
import { TagModule } from './tags/tag.module';
import { VoiceoverModule } from './voiceover/voiceover.module';
import { WarmUpModule } from './warm-up/warm-up.module';
import { WarmUpConfigModule } from './warm-up-config/warm-up-config.module';

@Module({
  imports: [
    AvatarModule,
    CourseModule,
    CourseVersionModule,
    CourseCollectionModule,
    ExploreModule,
    InAppSurveyModule,
    IssueReportModule,
    FeedbackModule,
    IconModule,
    CourseImportModule,
    KeypointModule,
    LearningImportModule,
    LearningItemModule,
    LessonModule,
    OutputPracticeModule,
    ProgressModule,
    QuoteModule,
    RecentlyViewedModule,
    SavedCardModule,
    SavedCourseModule,
    SearchHistoryModule,
    SpacedReviewModule,
    CategoryModule,
    TagModule,
    VoiceoverModule,
    WarmUpConfigModule,
    WarmUpModule,
  ],
})
export class CoursesModule {}
