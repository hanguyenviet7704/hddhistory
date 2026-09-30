import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CourseVersionModule } from 'src/modules/courses/src/modules/course-version/course-version.module';
import { KeypointModule } from 'src/modules/courses/src/modules/keypoint/keypoint.module';
import { HabitLibraryModule } from 'src/modules/habit/src/modules/habit-library/habit-library.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoachSituationController } from './coach-situation.controller';
import { CoachSituationService } from './coach-situation.service';
import { CoachSituationRepository } from './repository/coach-situation.repository';
import {
  CoachSituation,
  CoachSituationSchema,
} from './schema/coach-situation.schema';
import { CoachAiModule } from '../ai/coach-ai.module';

@Module({
  imports: [
    // ContentSource: đọc nội dung theo tag đang phát hành.
    forwardRef(() => CourseVersionModule),
    MongooseModule.forFeature([
      { name: CoachSituation.name, schema: CoachSituationSchema },
    ]),
    CoachAiModule,
    HabitLibraryModule,
    // The scene is grounded in the habit's own keypoints, which live here.
    KeypointModule,
    // The controller is guarded; a guard resolves its deps in the module that
    // declares the route.
    forwardRef(() => AuthModule),
  ],
  controllers: [CoachSituationController],
  providers: [CoachSituationService, CoachSituationRepository],
  exports: [CoachSituationService, CoachSituationRepository],
})
export class CoachSituationModule {}
