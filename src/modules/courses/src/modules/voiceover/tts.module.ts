import { Module } from '@nestjs/common';

import { ConfigurationProvider } from '@base/config/configuration.provider';

import { TtsService } from './tts.service';
import { VbeeTtsService } from './vbee-tts.service';

/**
 * Speech synthesis on its own, with no catalogue attached.
 *
 * Split out of `VoiceoverModule` so the learning-import feature can dub a
 * user's generated lesson without importing that module -- which drags in
 * `CourseModule`, `KeypointModule`, `LessonModule` and `LearningItemModule`,
 * none of which a generated lesson has any use for, and each of which is a
 * chance at a dependency cycle.
 *
 * `TtsService` was always this: a pure `(text, lang) -> Buffer`. Only its
 * packaging was catalogue-shaped.
 */
@Module({
  providers: [TtsService, VbeeTtsService, ConfigurationProvider],
  // `VbeeTtsService` is exported for the two things that need it directly and
  // are NOT synthesis: the admin voice picker, and the guard that refuses to
  // switch a course to a provider whose credentials are missing.
  exports: [TtsService, VbeeTtsService],
})
export class TtsModule {}
