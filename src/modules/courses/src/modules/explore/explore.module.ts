import { Module } from '@nestjs/common';

import { SegmentModule } from 'src/modules/segment/segment.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { ExploreController } from './explore.controller';
import { ExploreService } from './explore.service';
import { CourseCollectionModule } from '../collection/course-collection.module';
import { CourseModule } from '../course/course.module';
import { UserProgressModule } from '../progress/src/modules/user-progress/user-progress.module';
import { RecentlyViewedModule } from '../recently-viewed/recently-viewed.module';

@Module({
  imports: [
    // AuthModule for the controller's AuthGuard — a guard resolves its
    // dependencies in the module that declares the controller, and nothing in
    // the build catches a missing one.
    AuthModule,
    CourseCollectionModule,
    CourseModule,
    RecentlyViewedModule,
    UserProgressModule,
    SegmentModule,
  ],
  controllers: [ExploreController],
  providers: [ExploreService],
  exports: [ExploreService],
})
export class ExploreModule {}
