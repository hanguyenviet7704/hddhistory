import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoachContentController } from './coach-content.controller';
import { CoachContentService } from './coach-content.service';
import { CoachReflectionModule } from '../reflection/coach-reflection.module';
import { CoachSituationModule } from '../situation/coach-situation.module';
import { CoachSessionDipRepository } from './repository/coach-session-dip.repository';
import {
  CoachSession,
  CoachSessionSchema,
} from '../session/schema/coach-session.schema';

/**
 * The admin window onto reader-written text.
 *
 * Imports `CoachReflectionModule` for the three repositories it already exports,
 * and registers the session SCHEMA (not `CoachSessionModule`) for the one field
 * that lives there — importing the session module would close a cycle, since it
 * is the session that writes all of this in the first place.
 *
 * `CoachSituationModule` is imported outright: it knows nothing about this
 * module, so there is no cycle to dodge, and the scene text a situation answer
 * is joined back to belongs to its repository.
 */
@Module({
  imports: [
    CoachReflectionModule,
    CoachSituationModule,
    MongooseModule.forFeature([
      { name: CoachSession.name, schema: CoachSessionSchema },
    ]),
    // Guarded controller — see the same note on `CoachAiUsageModule`: without
    // this the app does not start.
    forwardRef(() => AuthModule),
  ],
  controllers: [CoachContentController],
  providers: [CoachContentService, CoachSessionDipRepository],
  exports: [CoachContentService],
})
export class CoachContentModule {}
