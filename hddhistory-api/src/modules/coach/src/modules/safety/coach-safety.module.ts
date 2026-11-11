import { Module } from '@nestjs/common';

import { CoachSafetyService } from './coach-safety.service';
import { CoachAiModule } from '../ai/coach-ai.module';
import { CoachConfigModule } from '../config/coach-config.module';

@Module({
  imports: [CoachAiModule, CoachConfigModule],
  providers: [CoachSafetyService],
  exports: [CoachSafetyService],
})
export class CoachSafetyModule {}
