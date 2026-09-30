import {
  BRANCH_CODE_REGEX,
  IOnboardingTaxonomyTree,
  LABEL_CODE_REGEX,
  PACKAGE_CODE_REGEX,
} from './interface/onboarding-taxonomy.interface';

export interface TaxonomyIssue {
  entity: 'branch' | 'package' | 'label';
  code: string;
  message: string;
}

const blank = (value?: string) => !value || !value.trim();

/**
 * Luật toàn cây, thuần để test được: mã đúng định dạng và duy nhất, quan hệ
 * cha–con tồn tại, mỗi gói có ≥1 nhãn, nhãn tiếng Việt không rỗng.
 * Trả [] khi hợp lệ.
 */
export function validateTaxonomyTree(
  tree: IOnboardingTaxonomyTree,
): TaxonomyIssue[] {
  const issues: TaxonomyIssue[] = [];
  const seen: Record<TaxonomyIssue['entity'], Set<string>> = {
    branch: new Set<string>(),
    package: new Set<string>(),
    label: new Set<string>(),
  };

  const checkCode = (
    entity: TaxonomyIssue['entity'],
    code: string,
    regex: RegExp,
  ) => {
    if (!regex.test(code)) {
      issues.push({
        entity,
        code,
        message: `mã ${entity} không đúng định dạng`,
      });
    }
    if (seen[entity].has(code)) {
      issues.push({ entity, code, message: `mã ${entity} bị trùng` });
    }
    seen[entity].add(code);
  };

  for (const branch of tree.branches) {
    checkCode('branch', branch.code, BRANCH_CODE_REGEX);
    if (blank(branch.label?.vi)) {
      issues.push({
        entity: 'branch',
        code: branch.code,
        message: 'tên nhánh (vi) rỗng',
      });
    }
  }

  const labelsPerPackage = new Map<string, number>();
  for (const label of tree.labels) {
    checkCode('label', label.code, LABEL_CODE_REGEX);
    labelsPerPackage.set(
      label.packageCode,
      (labelsPerPackage.get(label.packageCode) ?? 0) + 1,
    );
    if (blank(label.label?.vi)) {
      issues.push({
        entity: 'label',
        code: label.code,
        message: 'nhãn chi tiết (vi) rỗng',
      });
    }
  }

  for (const pkg of tree.packages) {
    checkCode('package', pkg.code, PACKAGE_CODE_REGEX);
    if (!seen.branch.has(pkg.branchCode)) {
      issues.push({
        entity: 'package',
        code: pkg.code,
        message: `nhánh ${pkg.branchCode} không tồn tại`,
      });
    }
    if (blank(pkg.problemLabel?.vi)) {
      issues.push({
        entity: 'package',
        code: pkg.code,
        message: 'vấn đề (vi) rỗng',
      });
    }
    if (blank(pkg.desireLabel?.vi)) {
      issues.push({
        entity: 'package',
        code: pkg.code,
        message: 'mong muốn (vi) rỗng',
      });
    }
    if (!labelsPerPackage.get(pkg.code)) {
      issues.push({
        entity: 'package',
        code: pkg.code,
        message: 'gói không có nhãn chi tiết nào',
      });
    }
  }

  for (const label of tree.labels) {
    if (!seen.package.has(label.packageCode)) {
      issues.push({
        entity: 'label',
        code: label.code,
        message: `gói ${label.packageCode} không tồn tại`,
      });
    }
  }

  return issues;
}
