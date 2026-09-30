import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';


import { AnalyticsModule } from 'src/modules/analytics/analytics.module';
import { FileModule } from 'src/modules/file/file.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { AudioCoverageService } from './audio-coverage.service';
import { AudioResolver } from './audio-resolver.service';
import { ContentSource } from './content-source.service';
import { CourseContentExperimentController } from './course-content-experiment.controller';
import { CourseContentExperimentService } from './course-content-experiment.service';
import { CourseVersionAnalyticsController } from './course-version-analytics.controller';
import { CourseVersionAnalyticsService } from './course-version-analytics.service';
import { CourseVersionController } from './course-version.controller';
import { CourseVersionService } from './course-version.service';
import { VersionDubService } from './version-dub.service';
import { CourseContentExperimentRepository } from './repository/course-content-experiment.repository';
import { CourseContentVersionRepository } from './repository/course-content-version.repository';
import { CourseVersionActivationRepository } from './repository/course-version-activation.repository';
import { PublishedContentRepository } from './repository/published-content.repository';
import {
  CourseContentExperiment,
  CourseContentExperimentSchema,
} from './schema/course-content-experiment.schema';
import {
  CourseContentVersion,
  CourseContentVersionSchema,
} from './schema/course-content-version.schema';
import {
  CourseVersionActivation,
  CourseVersionActivationSchema,
} from './schema/course-version-activation.schema';
import {
  PublishedContent,
  PublishedContentSchema,
} from './schema/published-content.schema';
import { CourseModule } from '../course/course.module';
import { FeedbackModule } from '../feedback/user-feedback/user-feedback.module';
import { KeypointModule } from '../keypoint/keypoint.module';
import { LearningItemModule } from '../learning-item/learning-item.module';
import { LessonModule } from '../lesson/lesson.module';
import { UserProgressModule } from '../progress/src/modules/user-progress/user-progress.module';
import { KeypointAudioClipRepository } from '../voiceover/repository/keypoint-audio-clip.repository';
import { TtsModule } from '../voiceover/tts.module';
import {
  KeypointAudioClip,
  KeypointAudioClipSchema,
} from '../voiceover/schema/keypoint-audio-clip.schema';

/**
 * Content tags: freezing a course's working tree under a name, and reading
 * content either from the working tree or from a tag.
 *
 * Every content module is imported with `forwardRef` because they already form
 * a cycle among themselves (course <-> lesson <-> keypoint) and this module
 * joins it: `CourseModule` will import this one back so
 * `course-publish.scheduler.ts` can tag a course it publishes.
 *
 * Both providers are singletons — see the notes on `CourseVersionService` and
 * `ContentSource` for why that matters here.
 *
 * See `plans/260907-course-content-versions/README.md`.
 */
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CourseContentVersion.name, schema: CourseContentVersionSchema },
      { name: PublishedContent.name, schema: PublishedContentSchema },
      {
        name: CourseContentExperiment.name,
        schema: CourseContentExperimentSchema,
      },
      {
        name: CourseVersionActivation.name,
        schema: CourseVersionActivationSchema,
      },
      // Registered here rather than reached through `VoiceoverModule`: that
      // module imports CourseModule, which imports this one, and the resolver
      // needs nothing else from it. A provider's dependencies have to exist in
      // the module that DECLARES it, and this is the cheapest way to say so.
      { name: KeypointAudioClip.name, schema: KeypointAudioClipSchema },
    ]),
    // AuthGuard's own dependencies.
    forwardRef(() => AuthModule),
    // Speech synthesis and R2, for dubbing what a tag is missing. Deliberately
    // NOT `VoiceoverModule`: that one drags in CourseModule and would close a
    // cycle back to this module. `TtsModule` exists for exactly this reason —
    // see its own note.
    TtsModule,
    FileModule,
    // CourseRepository + RoadmapRepository, LessonRepository,
    // KeypointRepository, LearningItemRepository — the working-tree reads.
    forwardRef(() => CourseModule),
    forwardRef(() => LessonModule),
    forwardRef(() => KeypointModule),
    forwardRef(() => LearningItemModule),
    // UserProgressRepository — mốc "user bắt đầu khoá này lúc nào", để không
    // đưa người đang học giữa khoá vào đợt A/B.
    forwardRef(() => UserProgressModule),
    // UserEventRepository — phễu của bảng kết quả, đếm theo người.
    forwardRef(() => AnalyticsModule),
    // UserFeedbackRepository — cột CSAT của bảng so sánh phiên bản.
    forwardRef(() => FeedbackModule),
  ],
  controllers: [
    CourseVersionController,
    CourseContentExperimentController,
    CourseVersionAnalyticsController,
  ],
  providers: [
    CourseVersionService,
    ContentSource,
    AudioResolver,
    AudioCoverageService,
    VersionDubService,
    KeypointAudioClipRepository,
    CourseContentExperimentService,
    CourseContentExperimentRepository,
    CourseContentVersionRepository,
    PublishedContentRepository,
    CourseVersionActivationRepository,
    CourseVersionAnalyticsService,
  ],
  exports: [
    CourseVersionService,
    ContentSource,
    AudioCoverageService,
    CourseContentExperimentService,
    CourseContentVersionRepository,
    PublishedContentRepository,
  ],
})
export class CourseVersionModule {}
