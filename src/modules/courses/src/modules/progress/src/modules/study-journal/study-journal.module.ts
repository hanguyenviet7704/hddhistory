import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';


import {
  HabitCheckin,
  HabitCheckinSchema,
} from 'src/modules/habit/src/modules/user-habit/schema/habit-checkin.schema';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';


import { StudyJournalHabitRepository } from './repository/study-journal-habit.repository';
import { StudyJournalRepository } from './repository/study-journal.repository';
import { StudyJournalController } from './study-journal.controller';
import { StudyJournalService } from './study-journal.service';
import {
  UserProgress,
  UserProgressSchema,
} from '../user-progress/schema/user-progress.schema';

// AuthModule: the controller's AuthGuard resolves its own dependencies from
// THIS module's context, so leaving it out crash-loops the app at boot rather
// than failing the request. forwardRef because auth reaches back into courses.
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserProgress.name, schema: UserProgressSchema },
      { name: HabitCheckin.name, schema: HabitCheckinSchema },
    ]),
    forwardRef(() => AuthModule),
  ],
  controllers: [StudyJournalController],
  providers: [
    StudyJournalService,
    StudyJournalRepository,
    StudyJournalHabitRepository,
  ],
  // The repository is exported alongside the service because `week-recap`
  // needs exactly the same week-window aggregation over `user_progress`, and a
  // second copy of that 60-line pipeline is how the two screens start
  // disagreeing about what a study day contains.
  exports: [StudyJournalService, StudyJournalRepository],
})
export class StudyJournalModule {}
