import { ITranslation } from '@utils/interface/common.interface';

/** Nhánh = đáp án câu 1 (lĩnh vực). `isSelectable=false` (vd Khám phá não bộ) chỉ để gắn khoá. */
export interface IOnboardingBranch {
  code: string;
  label: ITranslation;
  subtitle: ITranslation;
  iconUrl: string;
  imageUrl: string;
  order: number;
  isSelectable: boolean;
  /** Skillset tương ứng để Home xếp thứ tự theo nhánh đã chọn. */
  skillsetId: string | null;
  isActive: boolean;
}

/** Gói = 1 đáp án câu 2 (vấn đề) = 1 đáp án câu 3 (mong muốn). Mã mong muốn == mã gói. */
export interface IOnboardingPackage {
  code: string;
  branchCode: string;
  problemLabel: ITranslation;
  desireLabel: ITranslation;
  order: number;
  isActive: boolean;
}

/** Nhãn chi tiết: không hiện cho user, chỉ khớp gói ↔ khoá (Course.onboardingLabelCodes). */
export interface IOnboardingLabel {
  code: string;
  packageCode: string;
  label: ITranslation;
  order: number;
}

export interface IOnboardingTaxonomyTree {
  branches: IOnboardingBranch[];
  packages: IOnboardingPackage[];
  labels: IOnboardingLabel[];
}

/** Bản public cho app: chỉ active, không kèm labels. */
export interface IOnboardingTaxonomyPublic {
  branches: IOnboardingBranch[];
  packages: IOnboardingPackage[];
}

export const BRANCH_CODE_REGEX = /^[A-Z]{2,4}$/;
export const PACKAGE_CODE_REGEX = /^[A-Z]{2,4}-\d+$/;
export const LABEL_CODE_REGEX = /^[A-Z]{2,4}\d{2,}$/;
