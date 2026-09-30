import { Module } from '@nestjs/common';

import { CoachAiModule } from './src/modules/ai/coach-ai.module';
import { CoachAiUsageModule } from './src/modules/ai-usage/coach-ai-usage.module';
import { CoachBoostModule } from './src/modules/boost/coach-boost.module';
import { CoachConfigModule } from './src/modules/config/coach-config.module';
import { CoachContentModule } from './src/modules/content/coach-content.module';
import { CoachDayLogModule } from './src/modules/day-log/coach-day-log.module';
import { CoachMetricModule } from './src/modules/metric/coach-metric.module';
import { CoachPlanModule } from './src/modules/plan/coach-plan.module';
import { CoachProfileModule } from './src/modules/profile/coach-profile.module';
import { CoachRatingModule } from './src/modules/rating/coach-rating.module';
import { CoachReflectionModule } from './src/modules/reflection/coach-reflection.module';
import { CoachReminderModule } from './src/modules/reminder/coach-reminder.module';
import { CoachSafetyModule } from './src/modules/safety/coach-safety.module';
import { CoachScoreModule } from './src/modules/score/coach-score.module';
import { CoachSessionModule } from './src/modules/session/coach-session.module';
import { CoachSituationModule } from './src/modules/situation/coach-situation.module';

/**
 * AI Coach v2 — see `plans/260824-ai-coach-v2/README.md`.
 *
 * The state machine lives here rather than in the app because every rule this
 * feature has is a rule about what gets WRITTEN, and only a repository can hold
 * one of those. The model is called at ten of the twenty-three steps and never
 * decides a transition.
 */
@Module({
  imports: [
    CoachAiModule,
    CoachAiUsageModule,
    CoachBoostModule,
    CoachConfigModule,
    CoachContentModule,
    CoachDayLogModule,
    CoachMetricModule,
    CoachPlanModule,
    CoachProfileModule,
    CoachRatingModule,
    CoachReflectionModule,
    CoachReminderModule,
    CoachSafetyModule,
    CoachScoreModule,
    CoachSituationModule,
    CoachSessionModule,
  ],
  exports: [
    CoachConfigModule,
    CoachDayLogModule,
    CoachPlanModule,
    CoachReflectionModule,
    CoachSessionModule,
  ],
})
export class CoachModule {}
