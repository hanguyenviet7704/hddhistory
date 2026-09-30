import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoursePublishScheduler } from './course-publish.scheduler';
import { CourseController } from './course.controller';
import { CourseService } from './course.service';
import { CourseRepository } from './repository/course.repository';
import { RoadmapRepository } from './repository/roadmap.repository';
import { Course, CourseSchema } from './schema/course.schema';
import { Roadmap, RoadmapSchema } from './schema/roadmap.schema';
import { CourseVersionModule } from '../course-version/course-version.module';
import { KeypointModule } from '../keypoint/keypoint.module';
import { LessonModule } from '../lesson/lesson.module';
import { UserProgressModule } from '../progress/src/modules/user-progress/user-progress.module';
import { TagModule } from '../tags/tag.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Course.name, schema: CourseSchema },
      { name: Roadmap.name, schema: RoadmapSchema },
    ]),
    forwardRef(() => AuthModule),
    // ContentSource: đọc nội dung theo tag đang phát hành thay vì bản
    // đang sửa. forwardRef vì CourseVersionModule import lại module này.
    forwardRef(() => CourseVersionModule),
    LoggerModule,
    forwardRef(() => LessonModule),
    forwardRef(() => KeypointModule),
    forwardRef(() => TagModule),
    forwardRef(() => UserProgressModule),
  ],
  controllers: [CourseController],
  providers: [CourseService, CourseRepository, RoadmapRepository, CoursePublishScheduler],
  exports: [CourseService, CourseRepository, RoadmapRepository],
})
export class CourseModule {}
