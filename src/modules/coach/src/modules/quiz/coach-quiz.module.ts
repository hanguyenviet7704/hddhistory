import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CourseVersionModule } from 'src/modules/courses/src/modules/course-version/course-version.module';

import { CoachQuizService } from './coach-quiz.service';
import { CoachQuizSeenRepository } from './repository/coach-quiz-seen.repository';
import { CoachQuizSetRepository } from './repository/coach-quiz-set.repository';
import { CoachQuizSeen, CoachQuizSeenSchema } from './schema/coach-quiz-seen.schema';
import { CoachQuizSet, CoachQuizSetSchema } from './schema/coach-quiz-set.schema';
import { KeypointModule } from '../../../../courses/src/modules/keypoint/keypoint.module';
import { LearningItemModule } from '../../../../courses/src/modules/learning-item/learning-item.module';
import { HabitLibraryModule } from '../../../../habit/src/modules/habit-library/habit-library.module';
import { CoachAiModule } from '../ai/coach-ai.module';

/** The generated in-chat quiz: written from a keypoint, stored, served once per reader. */
@Module({
  imports: [
    // ContentSource: đọc nội dung theo tag đang phát hành.
    forwardRef(() => CourseVersionModule),
    MongooseModule.forFeature([
      { name: CoachQuizSet.name, schema: CoachQuizSetSchema },
      { name: CoachQuizSeen.name, schema: CoachQuizSeenSchema },
    ]),
    CoachAiModule,
    forwardRef(() => HabitLibraryModule),
    forwardRef(() => KeypointModule),
    forwardRef(() => LearningItemModule),
  ],
  providers: [CoachQuizService, CoachQuizSetRepository, CoachQuizSeenRepository],
  exports: [CoachQuizService],
})
export class CoachQuizModule {}
