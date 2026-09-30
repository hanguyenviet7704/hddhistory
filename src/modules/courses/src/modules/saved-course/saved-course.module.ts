import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { SavedCourseController } from './saved-course.controller';
import { SavedCourseRepository } from './saved-course.repository';
import { SavedCourseService } from './saved-course.service';
import { SavedCourse, SavedCourseSchema } from './schema/saved-course.schema';
import { CourseModule } from '../course/course.module';
import { UserProgressModule } from '../progress/src/modules/user-progress/user-progress.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SavedCourse.name, schema: SavedCourseSchema },
    ]),
    // The controller is behind AuthGuard, and a guard's dependencies resolve in
    // THIS module's context — without AuthModule here the app crash-loops on
    // boot with an unresolved-dependency error that no type-check can see.
    forwardRef(() => AuthModule),
    forwardRef(() => CourseModule),
    forwardRef(() => UserProgressModule),
  ],
  controllers: [SavedCourseController],
  providers: [SavedCourseService, SavedCourseRepository],
  exports: [SavedCourseRepository],
})
export class SavedCourseModule {}
