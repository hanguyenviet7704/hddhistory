import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { Keypoint, KeypointSchema } from 'src/modules/courses/src/modules/keypoint/schema/keypoint.schema';
import { Lesson, LessonSchema } from 'src/modules/courses/src/modules/lesson/schema/lesson.schema';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { UserStreakRepository } from './repository/user-streak.repository';
import { UserStreak, UserStreakSchema } from './schema/user-streak.schema';
import { UserStreakController } from './user-streak.controller';
import { UserStreakService } from './user-streak.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserStreak.name, schema: UserStreakSchema },
      { name: Lesson.name, schema: LessonSchema },
      { name: Keypoint.name, schema: KeypointSchema },
    ]),
    forwardRef(() => AuthModule),
  ],
  controllers: [UserStreakController],
  providers: [UserStreakService, UserStreakRepository],
  exports: [UserStreakService, UserStreakRepository],
})
export class UserStreakModule {}
