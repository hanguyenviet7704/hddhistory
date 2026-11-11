import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { UserVideoLessonActivityRepository } from './repository/user-video-lesson-activity.repository';
import {
  UserVideoLessonActivity,
  UserVideoLessonActivitySchema,
} from './schema/user-video-lesson-activity.schema';
import { UserVideoLessonActivityController } from './user-video-lesson-activity.controller';
import { UserVideoLessonActivityService } from './user-video-lesson-activity.service';
import { LessonModule } from '../../../../lesson/lesson.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      {
        name: UserVideoLessonActivity.name,
        schema: UserVideoLessonActivitySchema,
      },
    ]),
    forwardRef(() => AuthModule),
    LoggerModule,
    forwardRef(() => LessonModule),
  ],
  controllers: [UserVideoLessonActivityController],
  providers: [UserVideoLessonActivityService, UserVideoLessonActivityRepository],
  exports: [UserVideoLessonActivityService, UserVideoLessonActivityRepository],
})
export class UserVideoLessonActivityModule {}
