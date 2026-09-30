export interface IUserStreak {
  userId: string;
  weekStartDate: Date;
  weekStudy: boolean[];
  studyTime: number;
  currentStreak: number;
  bestStreak: number;
}

export interface IUserStreakResponse {
  weekStartDate: Date;
  weekStudy: boolean[];
  studyTime: number;
  currentStreak: number;
  bestStreak: number;
}
