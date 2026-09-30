import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import {
  UserProgress,
  UserProgressSchema,
} from 'src/modules/courses/src/modules/progress/src/modules/user-progress/schema/user-progress.schema';
import { SubscriptionsModule } from 'src/modules/payment/subscriptions/subscriptions.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';


import { HabitCheckinRepository } from './repository/habit-checkin.repository';
import { UserHabitRepository } from './repository/user-habit.repository';
import { UserProgressReadRepository } from './repository/user-progress-read.repository';
import { HabitCheckin, HabitCheckinSchema } from './schema/habit-checkin.schema';
import { UserHabit, UserHabitSchema } from './schema/user-habit.schema';
import { UserHabitAdminController } from './user-habit-admin.controller';
import { UserHabitAdminService } from './user-habit-admin.service';
import { UserHabitController } from './user-habit.controller';
import { UserHabitService } from './user-habit.service';
import { HabitConfigModule } from '../habit-config/habit-config.module';
import { HabitLibraryModule } from '../habit-library/habit-library.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserHabit.name, schema: UserHabitSchema },
      { name: HabitCheckin.name, schema: HabitCheckinSchema },
      { name: UserProgress.name, schema: UserProgressSchema },
    ]),
    AuthModule,
    HabitConfigModule,
    HabitLibraryModule,
    SubscriptionsModule,
  ],
  // Admin controller first: its `user-habits/admin` paths are more specific
  // than the app controller's `:id` patterns, so registering it ahead of
  // UserHabitController keeps a future `@Get(':id')` from swallowing `/admin`.
  controllers: [UserHabitAdminController, UserHabitController],
  providers: [
    UserHabitService,
    UserHabitAdminService,
    UserHabitRepository,
    HabitCheckinRepository,
    UserProgressReadRepository,
  ],
  // HabitCheckinRepository is exported so the notification module can ask
  // "which habits are still unchecked today" without owning habit collections.
  exports: [UserHabitService, UserHabitRepository, HabitCheckinRepository],
})
export class UserHabitModule {}
