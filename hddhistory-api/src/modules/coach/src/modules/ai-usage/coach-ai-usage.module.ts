import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoachAiUsageController } from './coach-ai-usage.controller';
import { CoachAiUsageService } from './coach-ai-usage.service';
import { CoachAiUsageRepository } from './repository/coach-ai-usage.repository';
import {
  CoachAiUsage,
  CoachAiUsageSchema,
} from './schema/coach-ai-usage.schema';
import {
  CoachSession,
  CoachSessionSchema,
} from '../session/schema/coach-session.schema';

/**
 * Cost telemetry for the coach's AI calls.
 *
 * Registers the session SCHEMA (not `CoachSessionModule`) because the report
 * needs a session count as a denominator, and importing the session module would
 * close a cycle: session → ai → ai-usage → session.
 */
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachAiUsage.name, schema: CoachAiUsageSchema },
      { name: CoachSession.name, schema: CoachSessionSchema },
    ]),
    // Guarded controller — `AuthGuard` resolves ITS OWN dependencies in the
    // context of the module that declares the controller, so a module with a
    // guarded route and no AuthModule crash-loops the whole app at boot with
    // "can't resolve dependencies of the AuthGuard". `tsc` and `nest build`
    // cannot see it; only Nest walking the graph can.
    forwardRef(() => AuthModule),
  ],
  controllers: [CoachAiUsageController],
  providers: [CoachAiUsageService, CoachAiUsageRepository],
  exports: [CoachAiUsageService],
})
export class CoachAiUsageModule {}
