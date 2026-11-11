import axiosClient from "./axiosClient";
import { unwrapApi } from "../utils/unwrapApi";

export interface CourseVersionEntityCounts {
  lessons: number;
  keypoints: number;
  learningItems: number;
}

export interface ContentEntityRef {
  entityType: "course" | "roadmap" | "lesson" | "keypoint" | "learningItem";
  entityId: string;
}

/** Bản đang sửa so với tag đang phát hành. */
export interface SnapshotDiff {
  added: ContentEntityRef[];
  changed: ContentEntityRef[];
  removed: ContentEntityRef[];
  total: number;
}

export interface CourseVersion {
  _id: string;
  tag: string;
  note?: string | null;
  entityCounts: CourseVersionEntityCounts;
  createdAt?: string;
  createdBy?: { _id?: string; email?: string; name?: string } | null;
  isCurrent: boolean;
}

export type AudioCoverageStatus = "done" | "stale" | "missing" | "none";

export interface KeypointAudioCoverage {
  keypointId: string;
  title: Record<string, string>;
  statuses: Record<string, AudioCoverageStatus>;
  /** Số thẻ có chữ mà chưa có bản thu, theo ngôn ngữ. */
  missing: Record<string, number>;
}

/**
 * Tình trạng audio của MỘT tag, xét theo chữ của chính tag đó.
 *
 * Đây là lý do "v1.0.0 có audio mà v1.0.1 thì không" trả lời được: bản thu
 * định danh bằng hash đoạn chữ, nên tag nào chữ không đổi thì dùng lại đúng
 * bản thu cũ, tag nào sửa chữ thì hiện thiếu. `complete: false` là thứ chặn
 * phát hành.
 */
export interface CourseAudioCoverage {
  tag: string;
  courseId: string;
  versionId: string;
  langs: string[];
  summary: Record<AudioCoverageStatus, number>;
  complete: boolean;
  keypoints: KeypointAudioCoverage[];
}

export interface VersionDubSnapshot {
  state: "idle" | "running" | "done";
  courseId: string | null;
  tag: string | null;
  total: number;
  done: number;
  failed: number;
  startedAt?: string;
  finishedAt?: string;
  lastErrors: string[];
}

export interface CourseVersionList {
  versions: CourseVersion[];
  currentTag: string | null;
  /** Tên gợi ý cho tag kế tiếp (patch +1). */
  nextTag: string;
  pending: SnapshotDiff;
}

/**
 * Phiên bản nội dung của một khoá học. Sửa nội dung bao nhiêu cũng được, user
 * vẫn đọc tag đang phát hành cho tới khi đánh tag mới; rollback = trỏ current
 * về tag cũ. Xem `hddhistory-api/plans/260907-course-content-versions/README.md`.
 */
export const courseVersionService = {
  async list(courseId: string) {
    const res = await axiosClient.get(`/courses/${courseId}/versions`);
    return unwrapApi<CourseVersionList>(res.data);
  },

  async audioCoverage(courseId: string, tag: string) {
    const res = await axiosClient.get(
      `/courses/${courseId}/versions/${tag}/audio-coverage`
    );
    return unwrapApi<CourseAudioCoverage>(res.data);
  },

  async dubMissing(courseId: string, tag: string) {
    const res = await axiosClient.post(
      `/courses/${courseId}/versions/${tag}/dub-missing`
    );
    return unwrapApi<VersionDubSnapshot>(res.data);
  },

  async dubStatus() {
    const res = await axiosClient.get(`/courses/versions/dub-status`);
    return unwrapApi<VersionDubSnapshot>(res.data);
  },

  async create(
    courseId: string,
    payload: { tag: string; note?: string; setCurrent?: boolean }
  ) {
    const res = await axiosClient.post(
      `/courses/${courseId}/versions`,
      payload
    );
    return unwrapApi<CourseVersion>(res.data);
  },

  /** Phát hành một tag đã có — cũng chính là cách rollback. */
  async setCurrent(courseId: string, tag: string) {
    const res = await axiosClient.put(`/courses/${courseId}/current-version`, {
      tag,
    });
    return unwrapApi<CourseVersion>(res.data);
  },

  async remove(courseId: string, tag: string) {
    const res = await axiosClient.delete(
      `/courses/${courseId}/versions/${tag}`
    );
    return unwrapApi<{ deleted: boolean }>(res.data);
  },

  /** Chạy một lần cho mỗi môi trường: đánh v1.0.0 cho mọi khoá chưa có tag. */
  async backfill() {
    const res = await axiosClient.post(`/courses/versions/backfill`);
    return unwrapApi<{ tagged: string[]; skipped: string[] }>(res.data);
  },
};

export default courseVersionService;
