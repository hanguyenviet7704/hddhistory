import { forwardRef, Module } from '@nestjs/common';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { WarmUpController } from './warm-up.controller';
import { WarmUpService } from './warm-up.service';
import { CourseVersionModule } from '../course-version/course-version.module';
import { LearningItemModule } from '../learning-item/learning-item.module';
import { LessonModule } from '../lesson/lesson.module';
import { UserProgressModule } from '../progress/src/modules/user-progress/user-progress.module';
import { WarmUpConfigModule } from '../warm-up-config/warm-up-config.module';

@Module({
  imports: [
    // ContentSource: đọc nội dung theo tag đang phát hành.
    forwardRef(() => CourseVersionModule),
    forwardRef(() => AuthModule),
    forwardRef(() => LessonModule),
    forwardRef(() => LearningItemModule),
    forwardRef(() => UserProgressModule),
    WarmUpConfigModule,
  ],
  controllers: [WarmUpController],
  providers: [WarmUpService],
  exports: [WarmUpService],
})
export class WarmUpModule {}
