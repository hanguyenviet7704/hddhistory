import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { UserFeedbackRepository } from './repository/user-feedback.repository';
import {
  UserFeedback,
  UserFeedbackSchema,
} from './schema/user-feedback.schema';
import { FeedbackController } from './user-feedback.controller';
import { FeedbackService } from './user-feedback.service';
import { Course, CourseSchema } from '../../course/schema/course.schema';
import {
  Keypoint,
  KeypointSchema,
} from '../../keypoint/schema/keypoint.schema';
import { Lesson, LessonSchema } from '../../lesson/schema/lesson.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserFeedback.name, schema: UserFeedbackSchema },
      { name: Course.name, schema: CourseSchema },
      { name: Lesson.name, schema: LessonSchema },
      { name: Keypoint.name, schema: KeypointSchema },
    ]),
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [FeedbackController],
  providers: [FeedbackService, UserFeedbackRepository],
  exports: [FeedbackService, UserFeedbackRepository],
})
export class FeedbackModule {}
