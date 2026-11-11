import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';



import { CoachDayLogModule } from 'src/modules/coach/src/modules/day-log/coach-day-log.module';
import { CoachPlanModule } from 'src/modules/coach/src/modules/plan/coach-plan.module';
import { CoachReflectionModule } from 'src/modules/coach/src/modules/reflection/coach-reflection.module';
import {
  HabitCheckin,
  HabitCheckinSchema,
} from 'src/modules/habit/src/modules/user-habit/schema/habit-checkin.schema';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { StudyJournalModule } from '../study-journal/study-journal.module';
import { WeekRecapHabitRepository } from './repository/week-recap-habit.repository';
import { WeekRecapRepository } from './repository/week-recap.repository';
import { WeekRecap, WeekRecapSchema } from './schema/week-recap.schema';
import { WeekRecapController } from './week-recap.controller';
import { WeekRecapService } from './week-recap.service';

// AuthModule: the controller's AuthGuard resolves its dependencies from THIS
// module's context, so leaving it out crash-loops the app at boot rather than
// failing the request — a mistake neither `tsc` nor `nest build` can see.
// forwardRef because auth reaches back into courses.
//
// StudyJournalModule is imported for its repository, not its service: the week
// window over `user_progress` is the same aggregation the journal calendar
// already runs, and a second copy would be a second definition of what a study
// day contains.
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: WeekRecap.name, schema: WeekRecapSchema },
      { name: HabitCheckin.name, schema: HabitCheckinSchema },
    ]),
    StudyJournalModule,
    // The LEAF coach modules, never CoachModule itself. CoachModule pulls in
    // the reminder dispatcher, which imports NotificationModule, which imports
    // THIS module — importing the parent here would close that ring and the app
    // would not boot. These three own only their own collections and import
    // nothing back.
    CoachDayLogModule,
    CoachPlanModule,
    CoachReflectionModule,
    forwardRef(() => AuthModule),
  ],
  controllers: [WeekRecapController],
  providers: [WeekRecapService, WeekRecapRepository, WeekRecapHabitRepository],
  // The repository is exported for the notification dispatcher, which needs the
  // snapshot's `viewedAt` (the weekly-recap reminder condition) — and must not
  // touch WeekRecapService, whose RequestService dependency would drag the
  // dispatcher's @Cron into request scope.
  exports: [WeekRecapService, WeekRecapRepository],
})
export class WeekRecapModule {}
