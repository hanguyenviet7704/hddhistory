import { Module } from '@nestjs/common';

import { HabitConfigModule } from './src/modules/habit-config/habit-config.module';
import { HabitLibraryModule } from './src/modules/habit-library/habit-library.module';
import { HabitPracticeModule } from './src/modules/habit-practice/habit-practice.module';
import { ReanchorReasonModule } from './src/modules/reanchor-reason/reanchor-reason.module';
import { UserHabitModule } from './src/modules/user-habit/user-habit.module';

@Module({
  imports: [
    HabitConfigModule,
    HabitLibraryModule,
    HabitPracticeModule,
    UserHabitModule,
    ReanchorReasonModule,
  ],
  exports: [
    HabitConfigModule,
    HabitLibraryModule,
    HabitPracticeModule,
    UserHabitModule,
    ReanchorReasonModule,
  ],
})
export class HabitModule {}
