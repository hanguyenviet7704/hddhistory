import { Types } from 'mongoose';

import { ExerciseResult } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/schema/user-progress.schema';

import { HabitCheckinMethod } from '../../user-habit/enum/user-habit.enum';
import { HabitPracticeStatus } from '../enum/habit-practice.enum';

export interface IHabitPractice {
  habitId: Types.ObjectId | string;
  learningItemId: Types.ObjectId | string;
  order: number;
  status: HabitPracticeStatus;
}

export interface IHabitPracticeAttempt {
  userHabitId: Types.ObjectId | string;
  habitId: Types.ObjectId | string;
  // Date-only (UTC midnight), the same normalisation habit_checkins.date uses,
  // so an attempt can be lined up with the check-in it filed.
  date: Date;
  method: HabitCheckinMethod;
  learningItemId?: Types.ObjectId | string | null;
  exercisesResult: ExerciseResult[];
  score?: number;
  total?: number;
  mood?: number;
  completedAt: Date;
}
