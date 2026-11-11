import { Types } from 'mongoose';

import { ITranslation } from '@utils/interface/common.interface';

import { ReanchorReasonStatus } from '../enum/reanchor-reason.enum';

export interface IReanchorReason {
  courseId: Types.ObjectId | string;
  reason: ITranslation;
  order: number;
  status: ReanchorReasonStatus;
}
