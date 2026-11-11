import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { SavedCardController } from './saved-card.controller';
import { SavedCardRepository } from './saved-card.repository';
import { SavedCardService } from './saved-card.service';
import { SavedCard, SavedCardSchema } from './schema/saved-card.schema';
import { CourseModule } from '../course/course.module';
import { CourseVersionModule } from '../course-version/course-version.module';
import { KeypointModule } from '../keypoint/keypoint.module';

@Module({
  imports: [
    // ContentSource: đọc nội dung theo tag đang phát hành.
    forwardRef(() => CourseVersionModule),
    MongooseModule.forFeature([
      { name: SavedCard.name, schema: SavedCardSchema },
    ]),
    // AuthGuard's dependencies resolve in this module's context — see the same
    // note in saved-course.module.ts.
    forwardRef(() => AuthModule),
    forwardRef(() => CourseModule),
    forwardRef(() => KeypointModule),
  ],
  controllers: [SavedCardController],
  providers: [SavedCardService, SavedCardRepository],
  exports: [SavedCardRepository],
})
export class SavedCardModule {}
