import { IOnboardingCourseCandidate } from 'src/modules/courses/src/modules/course/repository/course.repository';

export interface RecommendationInput {
  /** Gói đã chọn ở câu 2, theo thứ tự chọn. */
  packageCodes: string[];
  /** Mã gói đã chọn ở câu 3 (mong muốn), null nếu bỏ qua. */
  desireCode: string | null;
  /** Nhãn chi tiết của từng gói đã chọn. */
  labelsByPackage: Map<string, string[]>;
}

export interface MatchReason {
  desire: boolean;
  labelCodes: string[];
  packageCodes: string[];
}

export interface RankedCourse {
  course: IOnboardingCourseCandidate;
  matchReason: MatchReason;
}

interface Scored extends RankedCourse {
  /** 0 = khớp cả mong muốn + nhãn, 1 = chỉ mong muốn, 2 = chỉ nhãn vấn đề. */
  tier: number;
  packageHits: number;
  labelHits: number;
  earliestPackage: number;
  hasLessons: number;
  title: string;
}

/**
 * Luật §3.4 của design.md — ba TẦNG rồi mới so trong tầng: tầng 0 khớp cả
 * mong muốn và ≥1 nhãn, tầng 1 chỉ khớp mong muốn, tầng 2 chỉ khớp nhãn vấn
 * đề; trong tầng: số gói chạm được, số nhãn trùng, chạm gói chọn sớm hơn, có
 * bài học, tiêu đề. Thuần để test bảng xếp hạng không cần DB.
 */
export function rankCourses(
  candidates: IOnboardingCourseCandidate[],
  input: RecommendationInput,
): RankedCourse[] {
  const packageOfLabel = new Map<string, string>();
  for (const [pkg, labels] of input.labelsByPackage) {
    for (const label of labels) packageOfLabel.set(label, pkg);
  }
  const packageIndex = new Map(input.packageCodes.map((code, i) => [code, i]));

  const scored: Scored[] = [];
  for (const course of candidates) {
    const labelCodes = (course.onboardingLabelCodes ?? []).filter(code =>
      packageOfLabel.has(code),
    );
    const packageCodes = [
      ...new Set(labelCodes.map(code => packageOfLabel.get(code) as string)),
    ].sort((a, b) => (packageIndex.get(a) ?? 99) - (packageIndex.get(b) ?? 99));
    const desire =
      Boolean(input.desireCode) &&
      (course.onboardingDesireCodes ?? []).includes(input.desireCode as string);
    if (!desire && !labelCodes.length) continue;

    scored.push({
      course,
      matchReason: { desire, labelCodes, packageCodes },
      tier: desire && labelCodes.length ? 0 : desire ? 1 : 2,
      packageHits: packageCodes.length,
      labelHits: labelCodes.length,
      earliestPackage: packageCodes.length
        ? packageIndex.get(packageCodes[0]) ?? 99
        : 99,
      hasLessons: (course.numberOfLesson ?? 0) > 0 ? 1 : 0,
      title: course.title?.vi ?? course.title?.en ?? '',
    });
  }

  scored.sort(
    (a, b) =>
      a.tier - b.tier ||
      b.packageHits - a.packageHits ||
      b.labelHits - a.labelHits ||
      a.earliestPackage - b.earliestPackage ||
      b.hasLessons - a.hasLessons ||
      a.title.localeCompare(b.title, 'vi'),
  );

  return scored.map(({ course, matchReason }) => ({ course, matchReason }));
}
