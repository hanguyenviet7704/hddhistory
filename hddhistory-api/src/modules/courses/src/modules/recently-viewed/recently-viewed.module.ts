import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { RecentlyViewedController } from './recently-viewed.controller';
import { RecentlyViewedRepository } from './recently-viewed.repository';
import { RecentlyViewedService } from './recently-viewed.service';
import { CourseModule } from '../course/course.module';
import {
  RecentlyViewedCourse,
  RecentlyViewedCourseSchema,
} from './schema/recently-viewed-course.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: RecentlyViewedCourse.name, schema: RecentlyViewedCourseSchema },
    ]),
    forwardRef(() => AuthModule),
    CourseModule,
  ],
  controllers: [RecentlyViewedController],
  providers: [RecentlyViewedService, RecentlyViewedRepository],
  // Explore's weekly-popular strip counts opens out of this collection, so the
  // repository has to leave the module.
  exports: [RecentlyViewedRepository],
})
export class RecentlyViewedModule {}
