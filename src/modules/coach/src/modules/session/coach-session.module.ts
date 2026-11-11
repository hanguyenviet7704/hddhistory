import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CourseModule } from 'src/modules/courses/src/modules/course/course.module';
import { CourseVersionModule } from 'src/modules/courses/src/modules/course-version/course-version.module';
import { KeypointModule } from 'src/modules/courses/src/modules/keypoint/keypoint.module';
import { LearningItemModule } from 'src/modules/courses/src/modules/learning-item/learning-item.module';
import { LessonModule } from 'src/modules/courses/src/modules/lesson/lesson.module';
import { UserProgressModule } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.module';
import { SavedCourseModule } from 'src/modules/courses/src/modules/saved-course/saved-course.module';
import { HabitLibraryModule } from 'src/modules/habit/src/modules/habit-library/habit-library.module';
import { HabitPracticeModule } from 'src/modules/habit/src/modules/habit-practice/habit-practice.module';
import { UserHabitModule } from 'src/modules/habit/src/modules/user-habit/user-habit.module';
import { SocketModule } from 'src/modules/socket/socket.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';
import { OnboardingsModule } from 'src/modules/user/src/modules/onboarding/onboarding.module';

import { CoachSessionService } from './coach-session.service';
import { CoachController } from './coach.controller';
import { CoachSessionRepository } from './repository/coach-session.repository';
import {
  CoachSession,
  CoachSessionSchema,
} from './schema/coach-session.schema';
import { CoachAiModule } from '../ai/coach-ai.module';
import { CoachBoostModule } from '../boost/coach-boost.module';
import { CoachConfigModule } from '../config/coach-config.module';
import { CoachDayLogModule } from '../day-log/coach-day-log.module';
import { CoachMemoryModule } from '../memory/coach-memory.module';
import { CoachMetricModule } from '../metric/coach-metric.module';
import { CoachPlanModule } from '../plan/coach-plan.module';
import { CoachProfileModule } from '../profile/coach-profile.module';
import { CoachQuizModule } from '../quiz/coach-quiz.module';
import { CoachRatingModule } from '../rating/coach-rating.module';
import { CoachReflectionModule } from '../reflection/coach-reflection.module';
import { CoachSafetyModule } from '../safety/coach-safety.module';
import { CoachScoreModule } from '../score/coach-score.module';
import { CoachSituationModule } from '../situation/coach-situation.module';

@Module({
  imports: [
    // ContentSource: đọc nội dung theo tag đang phát hành.
    forwardRef(() => CourseVersionModule),
    MongooseModule.forFeature([
      { name: CoachSession.name, schema: CoachSessionSchema },
    ]),
    // AuthGuard's dependencies resolve in the module that declares the route —
    // without this the app fails to BOOT rather than failing per request, and
    // neither tsc nor `nest build` can see it coming.
    forwardRef(() => AuthModule),
    // The reader profile scenes are keyed on: age comes off the user, and the
    // learning goal's label lives in the onboarding config.
    OnboardingsModule,
    CoachAiModule,
    CoachConfigModule,
    CoachDayLogModule,
    CoachPlanModule,
    CoachProfileModule,
    CoachRatingModule,
    CoachReflectionModule,
    CoachSafetyModule,
    CoachBoostModule,
    CoachScoreModule,
    CoachSituationModule,
    CoachMetricModule,
    // The preview channel: the coach mirrors its prose to the reader over this
    // socket while the model is still writing. `forwardRef` because the socket
    // module reaches AuthModule, which this module also holds a forwardRef to.
    forwardRef(() => SocketModule),
    // The memory layer: raw lines every turn, extraction after every session.
    CoachMemoryModule,
    CoachQuizModule,
    HabitLibraryModule,
    // Luồng 5 — the in-chat quiz reads the habit's practices and files the attempt.
    forwardRef(() => HabitPracticeModule),
    KeypointModule,
    // Luồng 2/3 — the talk reads the keypoint's theory and the course's lessons.
    forwardRef(() => LearningItemModule),
    forwardRef(() => LessonModule),
    // The course card's "Lưu" — the course goes to Để dành through the same
    // repository the library screen writes.
    SavedCourseModule,
    // The card's selector: what the reader has already studied (progress),
    // and courses in a category they have not started (catalogue). Neither
    // module imports anything under coach/, so no cycle to forwardRef.
    UserProgressModule,
    CourseModule,
    UserHabitModule,
  ],
  controllers: [CoachController],
  providers: [CoachSessionService, CoachSessionRepository],
  exports: [CoachSessionService, CoachSessionRepository],
})
export class CoachSessionModule {}
