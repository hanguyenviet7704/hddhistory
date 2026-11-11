import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { FileModule } from 'src/modules/file/file.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { AudioClipBackfillService } from './audio-clip-backfill.service';
import { KeypointAudioClipRepository } from './repository/keypoint-audio-clip.repository';
import { VoiceoverJobRepository } from './repository/voiceover-job.repository';
import { VoiceoverSettingsRepository } from './repository/voiceover-settings.repository';
import {
  KeypointAudioClip,
  KeypointAudioClipSchema,
} from './schema/keypoint-audio-clip.schema';
import {
  VoiceoverJob,
  VoiceoverJobSchema,
} from './schema/voiceover-job.schema';
import {
  VoiceoverSettings,
  VoiceoverSettingsSchema,
} from './schema/voiceover-settings.schema';
import { TtsModule } from './tts.module';
import { VoiceoverJobService } from './voiceover-job.service';
import { VoiceoverMergeService } from './voiceover-merge.service';
import { VoiceoverSettingsService } from './voiceover-settings.service';
import { VoiceoverController } from './voiceover.controller';
import { VoiceoverService } from './voiceover.service';
import { CourseModule } from '../course/course.module';
import { KeypointModule } from '../keypoint/keypoint.module';
import { LearningItemModule } from '../learning-item/learning-item.module';
import { LessonModule } from '../lesson/lesson.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: KeypointAudioClip.name, schema: KeypointAudioClipSchema },
      { name: VoiceoverJob.name, schema: VoiceoverJobSchema },
      { name: VoiceoverSettings.name, schema: VoiceoverSettingsSchema },
    ]),
    forwardRef(() => AuthModule),
    LoggerModule,
    FileModule,
    forwardRef(() => CourseModule),
    KeypointModule,
    LearningItemModule,
    LessonModule,
    TtsModule,
  ],
  controllers: [VoiceoverController],
  providers: [
    VoiceoverService,
    VoiceoverMergeService,
    VoiceoverJobService,
    VoiceoverSettingsService,
    VoiceoverJobRepository,
    VoiceoverSettingsRepository,
    KeypointAudioClipRepository,
    AudioClipBackfillService,
  ],
  // The version-aware read path resolves audio through this store, so it has
  // to leave the module that owns it.
  exports: [KeypointAudioClipRepository],
})
export class VoiceoverModule {}
