import axiosClient from "./axiosClient";
import { unwrapApi } from "../utils/unwrapApi";

/** Hướng tốt của chỉ số — server là nơi định nghĩa, xem VERSION_METRICS. */
export type MetricPolarity = 1 | 0 | -1;

export interface MetricDefinition {
  key: string;
  group: string;
  label: string;
  hint?: string;
  unit: string;
  dec: number;
  polarity: MetricPolarity;
  type?: "date";
}

export interface VersionMetrics {
  pub: string | null;
  cardSec: number | null;
  lessonMin: number | null;
  done: number | null;
  courseDone: number | null;
  csat: number | null;
  bugs: number | null;
}

export interface RetentionPoint {
  lessonIndex: number;
  lessonId: string;
  pct: number;
}

export interface DepthPoint {
  lessonIndex: number;
  lessonId: string;
  pct: number;
  openers: number;
  cards: number;
}

export interface VersionRow {
  tag: string;
  versionId: string;
  note?: string | null;
  createdAt: string | null;
  publishedAt: string | null;
  live: boolean;
  windows: { from: string; to: string | null }[];
  liveDays: number;
  lessons: number;
  cards: number;
  metrics: VersionMetrics;
  sample: {
    courseViewers: number;
    lessonOpeners: number;
    csatResponses: number;
  };
  retention: RetentionPoint[];
  depth: DepthPoint[];
  dropOffLessons: number[];
}

export interface VersionComparison {
  courseId: string;
  courseTitle: string;
  currentTag: string | null;
  generatedAt: string;
  metrics: MetricDefinition[];
  versions: VersionRow[];
  ranges: Record<string, { min: number; max: number } | null>;
}

export interface ComparableCourse {
  id: string;
  title: string;
}

/**
 * Bảng so sánh phiên bản nội dung.
 *
 * MỌI hàm ở đây phải bóc phong bì `{statusCode,message,data}` — một field đọc
 * ra `undefined` rồi bị `.map()`/`.trim()` trong render là làm TRẮNG cả trang
 * admin, không toast không log. Xem `utils/unwrapApi.ts`.
 */
export const versionAnalyticsService = {
  async courses(): Promise<ComparableCourse[]> {
    const res = await axiosClient.get("/course-version-analytics/courses");

    return unwrapApi<ComparableCourse[]>(res.data) ?? [];
  },

  async compare(courseId: string, env = "dev"): Promise<VersionComparison> {
    const res = await axiosClient.get(
      `/course-version-analytics/compare/${courseId}`,
      { params: { env } },
    );

    return unwrapApi<VersionComparison>(res.data);
  },
};

export default versionAnalyticsService;
