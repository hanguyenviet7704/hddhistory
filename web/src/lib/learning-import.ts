/**
 * Tạo bài học từ tài liệu của chính người dùng (PDF / YouTube).
 *
 * Hình dạng lấy từ `learning-import.service.ts` của API (`ImportJobSnapshot`,
 * `getQuota`) và dò lại trên API local — không suy từ model của app.
 */
import 'server-only';

import { request, type PageBreak } from './api';

export type ImportJobStatus =
  | 'queued'
  | 'processing'
  | 'completed'
  | 'failed'
  // Không bao giờ được LƯU: API tự suy ra khi nhịp tim của tiến trình đã tắt
  // quá 2 phút (deploy, sập máy). Lượt của người dùng không bị trừ.
  | 'interrupted';

export type ImportJobStage =
  | 'fetching'
  | 'generating'
  | 'validating'
  | 'saving'
  | 'dubbing';

/** Thứ app poll mỗi 3 giây — bản rút gọn của job, không phải document gốc. */
export interface ImportJob {
  id: string;
  status: ImportJobStatus;
  stage?: ImportJobStage | null;
  percent?: number;
  sourceType?: 'pdf' | 'youtube';
  /** Tên video, tên tệp hoặc URL — cái nào có thì hiện. */
  sourceLabel?: string;
  outputLocale?: string;
  /** Có ngay khi job `completed`: bài đã đọc được (dù phần sau có thể còn đang viết). */
  userLessonId?: string | null;
  errorCode?: string | null;
  createdAt?: string;
  completedAt?: string | null;
}

export interface ImportQuota {
  limit: number;
  used: number;
  remaining: number;
  /** Null với người dùng miễn phí: một lượt trọn đời, không có ngày hồi lại. */
  resetsAt: string | null;
  isPremium: boolean;
  /** Số lượt mỗi tuần NẾU có Premium — để câu mời nâng cấp không phải đoán số. */
  premiumLimit: number;
  /** Công tắc của admin. Tắt = chỉ đóng đường TẠO, bài đã có vẫn đọc được. */
  enabled: boolean;
  disabledNote: string;
}

export function isJobRunning(job: Pick<ImportJob, 'status'>): boolean {
  return job.status === 'queued' || job.status === 'processing';
}

export function getImportQuota(): Promise<ImportQuota> {
  // Lượt bị tiêu từ thiết bị khác nữa: số cũ dẫn tới bấm "Tạo" rồi mới bị từ
  // chối, tệ hơn một lần gọi thêm.
  return request<ImportQuota>('/api/v1/learning-imports/quota', {
    revalidate: 0,
  });
}

export function getImportJob(jobId: string): Promise<ImportJob> {
  return request<ImportJob>(
    `/api/v1/learning-imports/${encodeURIComponent(jobId)}`,
    { revalidate: 0 },
  );
}

/** Lịch sử nhập của chính người gọi, mới nhất trước. */
export function getImportJobs(page = 1, take = 5): Promise<PageBreak<ImportJob>> {
  return request<PageBreak<ImportJob>>(
    `/api/v1/learning-imports?page=${page}&take=${take}`,
    { revalidate: 0 },
  );
}
