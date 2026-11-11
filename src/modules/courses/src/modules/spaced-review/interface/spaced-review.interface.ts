import { ITranslation } from '@utils/interface/common.interface';

import { ExerciseInput } from '../../learning-item/interface/learning-item.interface';

export interface ISpacedReviewKeypoint {
  keypointId: string;
  lessonId: string;
  courseId: string;
  title: ITranslation;
  questions: ExerciseInput[];
}

export interface ISpacedReviewTodayResponse {
  /** Tổng số keypoint đang đến hạn — có thể lớn hơn số trong phiên này. */
  dueCount: number;
  /** Phiên hôm nay: tối đa vài keypoint, mỗi keypoint vài câu. */
  keypoints: ISpacedReviewKeypoint[];
  /** Hạn ôn gần nhất khi hôm nay không còn gì — để app báo "ôn tiếp vào…". */
  nextDueAt: Date | null;
}

export interface ISpacedReviewSubmitResponse {
  updated: number;
  nextDueAt: Date | null;
}
