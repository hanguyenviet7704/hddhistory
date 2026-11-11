export interface IOnboardingAnswer {
  userId: string;
  branchCodes: string[];
  packageCodes: string[];
  desireCode: string | null;
  reminderEnabled: boolean;
  reminderTime: string | null;
  recommendedCourseIds: string[];
  chosenCourseId: string | null;
  ageKey: string | null;
  completedAt: Date | null;
}

export interface IRecommendedCourse {
  _id: string;
  title: Record<string, string>;
  description?: Record<string, string>;
  image: string;
  categoryId: string;
  numberOfLesson: number;
  status: string;
  matchReason: {
    desire: boolean;
    labelCodes: string[];
    packageCodes: string[];
  };
}

export const REMINDER_TIME_REGEX = /^([01]\d|2[0-3]):(00|15|30|45)$/;
