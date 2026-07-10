import { ITranslation } from "../../utils/translate";
import { ReanchorReasonStatus } from "../enum/reanchor-reason.enum";

// Admin-managed, per-course "why did you pause?" re-anchor prompts (PRD v2.0
// §9.1). Shown to the end user when they resume a course after a break.
export interface IReanchorReason {
  _id: string;
  courseId: string;
  reason: ITranslation;
  order: number;
  status: ReanchorReasonStatus;
  createdAt?: string;
  updatedAt?: string;
}

export interface ReanchorReasonPayload {
  courseId: string;
  reason: ITranslation;
  order?: number;
  status?: ReanchorReasonStatus;
}

// GET /reanchor-reasons — mirrors the habit list convention: the admin list
// always fetches with isAll=true (the API ignores `status` whenever `isAll`
// is set, so status filtering happens client side). `courseId` still narrows
// the query server side.
export interface ReanchorReasonListQuery {
  isAll?: boolean;
  courseId?: string;
  status?: ReanchorReasonStatus;
}
