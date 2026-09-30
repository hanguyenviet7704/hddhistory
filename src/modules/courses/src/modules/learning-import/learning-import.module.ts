import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { ConfigurationProvider } from '@base/config/configuration.provider';
import { LoggerModule } from '@base/logging/logger.module';
import { FileModule } from 'src/modules/file/file.module';
import { SubscriptionsModule } from 'src/modules/payment/subscriptions/subscriptions.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { TtsModule } from '../voiceover/tts.module';
import { GeminiLessonGeneratorService } from './ai/gemini-lesson-generator.service';
import { UserLessonVoiceoverService } from './audio/user-lesson-voiceover.service';
import { LearningImportAdminController } from './learning-import-admin.controller';
import { LearningImportConfigService } from './learning-import-config.service';
import { LearningImportQuotaService } from './learning-import-quota.service';
import { LearningImportRunnerService } from './learning-import-runner.service';
import { LearningImportStatsService } from './learning-import-stats.service';
import { LearningImportController } from './learning-import.controller';
import { LearningImportService } from './learning-import.service';
import { LearningImportConfigRepository } from './repository/learning-import-config.repository';
import { LearningImportJobRepository } from './repository/learning-import-job.repository';
import { UserLessonRepository } from './repository/user-lesson.repository';
import {
  LearningImportConfig,
  LearningImportConfigSchema,
} from './schema/learning-import-config.schema';
import {
  LearningImportJob,
  LearningImportJobSchema,
} from './schema/learning-import-job.schema';
import { UserLesson, UserLessonSchema } from './schema/user-lesson.schema';
import { PdfSourceResolver } from './source/pdf-source.resolver';
import { YoutubeSourceResolver } from './source/youtube-source.resolver';
import { UserLessonCompletionService } from './user-lesson-completion.service';
import { UserLessonCompletionSweep } from './user-lesson-completion.sweep';
import { UserLessonPracticeService } from './user-lesson-practice.service';
import { UserLessonController } from './user-lesson.controller';
import { UserLessonService } from './user-lesson.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: LearningImportJob.name, schema: LearningImportJobSchema },
      { name: UserLesson.name, schema: UserLessonSchema },
      { name: LearningImportConfig.name, schema: LearningImportConfigSchema },
    ]),
    // Every controller here is @UseGuards(AuthGuard); without AuthModule the
    // guard's dependencies cannot resolve and the app crash-loops on boot --
    // something neither `tsc` nor `nest build` can see.
    forwardRef(() => AuthModule),
    LoggerModule,
    // R2Service, to fetch the uploaded PDF back out of storage.
    FileModule,
    // SubscriptionService, for the server-side premium check.
    SubscriptionsModule,
    // Speech synthesis only. Deliberately NOT VoiceoverModule, which would drag
    // in Course/Keypoint/Lesson/LearningItem -- none of which a generated lesson
    // has any use for, and each a chance at a dependency cycle.
    TtsModule,
  ],
  controllers: [
    LearningImportController,
    UserLessonController,
    LearningImportAdminController,
  ],
  providers: [
    LearningImportService,
    UserLessonService,
    LearningImportQuotaService,
    LearningImportConfigService,
    LearningImportConfigRepository,
    LearningImportStatsService,
    LearningImportRunnerService,
    LearningImportJobRepository,
    UserLessonRepository,
    PdfSourceResolver,
    YoutubeSourceResolver,
    GeminiLessonGeneratorService,
    UserLessonVoiceoverService,
    UserLessonCompletionService,
    UserLessonCompletionSweep,
    UserLessonPracticeService,
    // The AI client reads GEMINI_* straight off `Configuration`, same as
    // OutputPracticeAiModule does for its own host/token.
    ConfigurationProvider,
  ],
  // Output practice asks this one question -- "is this section a generated
  // lesson, and what should the AI know about it" -- and gets nothing else from
  // this module.
  exports: [UserLessonPracticeService],
})
export class LearningImportModule {}
