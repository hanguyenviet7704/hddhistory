import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { LessonController } from './lesson.controller';
import { LessonService } from './lesson.service';
import { LessonRepository } from './repository/lesson.repository';
import { Lesson, LessonSchema } from './schema/lesson.schema';
import { AvatarModule } from '../avatar/avatar.module';
import { CourseModule } from '../course/course.module';
import { CourseVersionModule } from '../course-version/course-version.module';
import { KeypointModule } from '../keypoint/keypoint.module';
import { UserProgressModule } from '../progress/src/modules/user-progress/user-progress.module';
import { TagModule } from '../tags/tag.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Lesson.name, schema: LessonSchema }]),
    forwardRef(() => AuthModule),
    // ContentSource: đọc nội dung theo tag đang phát hành thay vì bản
    // đang sửa. forwardRef vì CourseVersionModule import lại module này.
    forwardRef(() => CourseVersionModule),
    LoggerModule,
    forwardRef(() => KeypointModule),
    forwardRef(() => TagModule),
    forwardRef(() => AvatarModule),
    forwardRef(() => CourseModule),
    forwardRef(() => UserProgressModule),
  ],
  controllers: [LessonController],
  providers: [LessonService, LessonRepository],
  exports: [LessonService, LessonRepository],
})
export class LessonModule {}
