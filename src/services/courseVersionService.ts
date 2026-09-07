import axiosClient from "./axiosClient";

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
 * về tag cũ. Xem `meup-api/plans/260907-course-content-versions/README.md`.
 */
export const courseVersionService = {
  async list(courseId: string) {
    const res = await axiosClient.get(`/courses/${courseId}/versions`);
    return res.data as CourseVersionList;
  },

  async create(
    courseId: string,
    payload: { tag: string; note?: string; setCurrent?: boolean }
  ) {
    const res = await axiosClient.post(
      `/courses/${courseId}/versions`,
      payload
    );
    return res.data as CourseVersion;
  },

  /** Phát hành một tag đã có — cũng chính là cách rollback. */
  async setCurrent(courseId: string, tag: string) {
    const res = await axiosClient.put(`/courses/${courseId}/current-version`, {
      tag,
    });
    return res.data as CourseVersion;
  },

  async remove(courseId: string, tag: string) {
    const res = await axiosClient.delete(
      `/courses/${courseId}/versions/${tag}`
    );
    return res.data as { deleted: boolean };
  },

  /** Chạy một lần cho mỗi môi trường: đánh v1.0.0 cho mọi khoá chưa có tag. */
  async backfill() {
    const res = await axiosClient.post(`/courses/versions/backfill`);
    return res.data as { tagged: string[]; skipped: string[] };
  },
};

export default courseVersionService;
