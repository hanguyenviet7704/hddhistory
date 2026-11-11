import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { SpacedReviewItemRepository } from './repository/spaced-review-item.repository';
import {
  SpacedReviewItem,
  SpacedReviewItemSchema,
} from './schema/spaced-review-item.schema';
import { SpacedReviewController } from './spaced-review.controller';
import { SpacedReviewService } from './spaced-review.service';
import { CourseVersionModule } from '../course-version/course-version.module';
import { UserProgressModule } from '../progress/src/modules/user-progress/user-progress.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SpacedReviewItem.name, schema: SpacedReviewItemSchema },
    ]),
    // ContentSource: đọc nội dung theo tag đang phát hành.
    forwardRef(() => CourseVersionModule),
    // AuthGuard's dependencies resolve in this module's context — see the same
    // note in saved-course.module.ts.
    forwardRef(() => AuthModule),
    forwardRef(() => UserProgressModule),
  ],
  controllers: [SpacedReviewController],
  providers: [SpacedReviewService, SpacedReviewItemRepository],
  exports: [SpacedReviewItemRepository],
})
export class SpacedReviewModule {}
