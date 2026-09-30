import { Module } from '@nestjs/common';

import { ConfigurationProvider } from '@base/config/configuration.provider';

import { CoachAi } from './coach-ai.types';
import { GeminiCoachService } from './gemini-coach.service';
import { CoachAiUsageModule } from '../ai-usage/coach-ai-usage.module';
import { CoachConfigModule } from '../config/coach-config.module';

/**
 * The provider seam.
 *
 * Everything downstream injects the abstract `CoachAi`; swapping providers is
 * one line here and no change anywhere else.
 *
 * `ConfigurationProvider` has to be listed here, not just imported somewhere
 * upstream: `GeminiCoachService` injects `Configuration`, and a provider's
 * dependencies resolve in the context of the module that declares it. Without
 * it the whole app crash-looped on boot with "Nest can't resolve dependencies
 * of the GeminiCoachService (?)" — same reason `LearningImportModule` lists it
 * for its own Gemini client.
 */
@Module({
  // `GeminiCoachService` injects the usage recorder — and the coach config,
  // for the admin-editable model overrides — and by the same rule spelled out
  // above, those dependencies have to resolve in THIS module's context.
  imports: [CoachAiUsageModule, CoachConfigModule],
  providers: [
    { provide: CoachAi, useClass: GeminiCoachService },
    ConfigurationProvider,
  ],
  exports: [CoachAi],
})
export class CoachAiModule {}
