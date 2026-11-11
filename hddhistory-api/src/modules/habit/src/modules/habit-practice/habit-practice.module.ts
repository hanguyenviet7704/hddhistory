import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CourseVersionModule } from 'src/modules/courses/src/modules/course-version/course-version.module';
import { KeypointModule } from 'src/modules/courses/src/modules/keypoint/keypoint.module';
import { LearningItemModule } from 'src/modules/courses/src/modules/learning-item/learning-item.module';
import { UserProgressModule } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { HabitPracticeAdminController } from './habit-practice-admin.controller';
import { HabitPracticeController } from './habit-practice.controller';
import { HabitPracticeService } from './habit-practice.service';
import { HabitPracticeAttemptRepository } from './repository/habit-practice-attempt.repository';
import { HabitPracticeRepository } from './repository/habit-practice.repository';
import {
  HabitPracticeAttempt,
  HabitPracticeAttemptSchema,
} from './schema/habit-practice-attempt.schema';
import {
  HabitPractice,
  HabitPracticeSchema,
} from './schema/habit-practice.schema';
import { HabitLibraryModule } from '../habit-library/habit-library.module';
import { UserHabitModule } from '../user-habit/user-habit.module';

/**
 * Habit practices: the `habit_practices` join (which authored `learning_item`
 * serves as practice for a habit) and `habit_practice_attempts` (a finished
 * session with per-question detail).
 *
 * `LearningItemModule` is imported to hydrate the pointed-at content,
 * `HabitLibraryModule` to read a habit's `keypointIds` — the app's practice list
 * is derived from the keypoint's exercises unless an author curated it, so the
 * habit doc is on the read path, not just the join rows — and `UserHabitModule`
 * so a submitted attempt files the day's check-in through
 * `UserHabitService.checkIn`, keeping streak recomputation in one place.
 *
 * All three are `forwardRef`ed. No edge is circular today, but `learning-item`
 * already forwardRefs half of its own imports, and the natural next step here —
 * the Habit-screen payload listing each habit's practices — would add the
 * habit→practice→habit edge. Cheap now, an import-cycle debug session later.
 *
 * `AuthModule` is imported because both controllers here are behind
 * `@UseGuards(AuthGuard)`, and a guard's dependencies must resolve in the
 * context of the module whose controllers use it — Nest does not resolve them
 * from wherever the guard class happens to live. AuthGuard needs `JwtUtil` and
 * `UserRepository`, which only `AuthModule` exports; `Reflector`, `I18nService`
 * and `LoggerService` are global. Importing `UserHabitModule` is NOT enough:
 * it imports AuthModule but does not re-export it, and module imports are not
 * transitive. Leaving this out crash-looped the dev API on boot with
 * "can't resolve dependencies of the AuthGuard (?, ...) ... JwtUtil at index
 * [0] is available in the HabitPracticeModule context".
 */
@Module({
  imports: [
    // ContentSource: đọc nội dung theo tag đang phát hành.
    forwardRef(() => CourseVersionModule),
    MongooseModule.forFeature([
      { name: HabitPractice.name, schema: HabitPracticeSchema },
      {
        name: HabitPracticeAttempt.name,
        schema: HabitPracticeAttemptSchema,
      },
    ]),
    forwardRef(() => AuthModule),
    forwardRef(() => LearningItemModule),
    forwardRef(() => HabitLibraryModule),
    forwardRef(() => UserHabitModule),
    // The app read filters derived practice to the keypoints the user has
    // PASSED — `UserProgressRepository` is the progress source of truth.
    forwardRef(() => UserProgressModule),
    // Hydrate names each practice's source keypoint (`keypointTitle`), so the
    // app can tag quiz cards dealt across several keypoints.
    forwardRef(() => KeypointModule),
  ],
  // Admin controller first: `habit-practices/admin` is more specific than the
  // app controller's paths, so registering it ahead keeps a future `:id` route
  // from swallowing `/admin`.
  controllers: [HabitPracticeAdminController, HabitPracticeController],
  providers: [
    HabitPracticeService,
    HabitPracticeRepository,
    HabitPracticeAttemptRepository,
  ],
  exports: [
    HabitPracticeService,
    HabitPracticeRepository,
    HabitPracticeAttemptRepository,
  ],
})
export class HabitPracticeModule {}
