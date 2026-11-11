import { ITranslation } from "../../utils/translate";

export interface OnboardingBranch {
  code: string;
  label: ITranslation;
  subtitle: ITranslation;
  iconUrl: string;
  imageUrl: string;
  order: number;
  /** Hiện ở câu 1. false = chỉ để gắn khoá (vd Khám phá não bộ). */
  isSelectable: boolean;
  categoryId: string | null;
  isActive: boolean;
}

/** 1 gói = 1 đáp án câu 2 (vấn đề) = 1 đáp án câu 3 (mong muốn). */
export interface OnboardingPackage {
  code: string;
  branchCode: string;
  problemLabel: ITranslation;
  desireLabel: ITranslation;
  order: number;
  isActive: boolean;
}

/** Nhãn chi tiết: chỉ để khớp gói ↔ khoá, user không thấy. */
export interface OnboardingLabel {
  code: string;
  packageCode: string;
  label: ITranslation;
  order: number;
}

export interface OnboardingTaxonomyTree {
  branches: OnboardingBranch[];
  packages: OnboardingPackage[];
  labels: OnboardingLabel[];
}

export const emptyTaxonomyTree = (): OnboardingTaxonomyTree => ({ branches: [], packages: [], labels: [] });
