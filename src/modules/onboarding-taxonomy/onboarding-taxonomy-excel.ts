import * as ExcelJS from 'exceljs';

import { ITranslation } from '@utils/interface/common.interface';
import {
  getRows,
  getSheet,
  ImportRow,
  ImportValidationError,
  numberValue,
  splitList,
  text,
} from 'src/modules/courses/src/modules/import/excel-import.util';

import {
  IOnboardingBranch,
  IOnboardingLabel,
  IOnboardingPackage,
  IOnboardingTaxonomyTree,
} from './interface/onboarding-taxonomy.interface';
import { normalizeTree } from './onboarding-taxonomy.service';
import { validateTaxonomyTree } from './onboarding-taxonomy.validator';

export const SHEET_GUIDE = 'Hướng dẫn';
export const SHEET_BRANCH = 'Nhánh';
export const SHEET_PACKAGE = ['Gói nhãn', 'Nhãn'];
export const SHEET_MAPPING = ['Mapping Khoá học', 'Mapping Khoa hoc'];

const LANGS = ['vi', 'en', 'zh', 'ja', 'ko'] as const;

export const BRANCH_HEADERS = [
  'Mã nhánh',
  'Tên nhánh (vi)',
  'Tên nhánh (en)',
  'Mô tả ngắn (vi)',
  'Mô tả ngắn (en)',
  'Icon URL',
  'Ảnh URL',
  'Thứ tự',
  'Hiện ở câu 1 (Y/N)',
  'Skillset ID (tuỳ chọn)',
];
export const PACKAGE_HEADERS = [
  'Mã nhánh',
  'Mã gói',
  'Vấn đề — đáp án câu 2 (vi)',
  'Vấn đề — đáp án câu 2 (en)',
  'Mong muốn — đáp án câu 3 (vi)',
  'Mong muốn — đáp án câu 3 (en)',
  'Nhãn chi tiết (vi)',
  'Mã nhãn chi tiết',
  'Thứ tự',
];
export const MAPPING_HEADERS = [
  'Course ID (tuỳ chọn)',
  'Khoá học',
  'Nhánh nội dung',
  'Trạng thái (tham khảo)',
  'Mã nhãn vấn đề',
  'Mã gói mong muốn',
];
/** Alias chấp nhận cho cột Course ID — dùng chung cho đọc VÀ ghi lại, để hai
 * bên không lệch nhau. */
export const COURSE_ID_HEADERS = ['Course ID (tuỳ chọn)', 'Course ID', 'id'];

export interface ParsedCourseRow {
  rowNumber: number;
  courseId: string;
  title: string;
  labelCodes: string[];
  desireCodes: string[];
}

export interface SourceRowRef {
  sheet: string;
  row: number;
  column: string;
}

export interface ParsedTaxonomyWorkbook {
  tree: IOnboardingTaxonomyTree;
  courseRows: ParsedCourseRow[];
  errors: ImportValidationError[];
  /** Dòng gốc theo mã (nhánh/gói/nhãn) — dùng để trỏ lỗi cấu trúc (từ
   * `validateTaxonomyTree`) về đúng dòng trong file thay vì hàng 0. */
  sourceRows: Map<string, SourceRowRef>;
}

/** Đọc ô theo danh sách header chấp nhận (header đầu tiên có mặt thắng). */
function pick(row: ImportRow, headers: string[]): any {
  for (const h of headers) {
    if (
      row.values[h] !== undefined &&
      row.values[h] !== null &&
      row.values[h] !== ''
    ) {
      return row.values[h];
    }
  }
  return undefined;
}

/** `Base (vi)`/`Base (en)`/… + `Base` trần = vi. Bỏ ngôn ngữ rỗng; {} khi không có gì. */
function translationOf(row: ImportRow, base: string): Record<string, string> {
  const out: Record<string, string> = {};
  for (const lang of LANGS) {
    const value = text(
      pick(row, lang === 'vi' ? [`${base} (vi)`, base] : [`${base} (${lang})`]),
    );
    if (value) out[lang] = value;
  }
  return out;
}

const up = (v: any) => text(v).toUpperCase();
const upList = (v: any) => splitList(v).map(s => s.toUpperCase());

/** So tên nhánh: bỏ hoa/thường + gộp khoảng trắng (không bỏ dấu, tên là tiếng Việt có dấu). */
export function norm(s: string): string {
  return s.trim().replace(/\s+/g, ' ').toLowerCase();
}

/**
 * Workbook → cây + dòng khoá + lỗi theo dòng. Thuần: không chạm DB; người gọi
 * đưa `existingBranches` để sheet "Nhãn" gốc (chỉ có TÊN nhánh, không có sheet
 * "Nhánh") vẫn import được.
 */
export function parseTaxonomyWorkbook(
  workbook: ExcelJS.Workbook,
  existingBranches: IOnboardingBranch[],
): ParsedTaxonomyWorkbook {
  const errors: ImportValidationError[] = [];
  const sourceRows = new Map<string, SourceRowRef>();

  // ---- Nhánh (tuỳ chọn) ----
  const branchSheet = getSheet(workbook, [SHEET_BRANCH]);
  let branches: IOnboardingBranch[];
  if (branchSheet) {
    const branchRows = getRows(branchSheet);
    branches = branchRows.map((row, i) => ({
      code: up(pick(row, ['Mã nhánh'])),
      label: translationOf(row, 'Tên nhánh'),
      subtitle: translationOf(row, 'Mô tả ngắn'),
      iconUrl: text(pick(row, ['Icon URL'])),
      imageUrl: text(pick(row, ['Ảnh URL'])),
      order: numberValue(pick(row, ['Thứ tự'])) ?? i + 1,
      isSelectable:
        text(
          pick(row, ['Hiện ở câu 1 (Y/N)', 'Hiện ở câu 1']),
        ).toUpperCase() !== 'N',
      skillsetId:
        text(pick(row, ['Skillset ID (tuỳ chọn)', 'Skillset ID'])) || null,
      isActive: true,
    }));
    branches.forEach((b, i) => {
      if (!b.code) {
        errors.push({
          sheet: SHEET_BRANCH,
          row: i + 2,
          column: 'Mã nhánh',
          message: 'thiếu mã nhánh',
        });
      } else {
        sourceRows.set(b.code, {
          sheet: SHEET_BRANCH,
          row: branchRows[i].rowNumber,
          column: 'Mã nhánh',
        });
      }
    });
  } else {
    branches = existingBranches;
  }
  const branchByName = new Map(
    branches.map(b => [norm(b.label?.vi ?? ''), b.code]),
  );
  const branchCodes = new Set(branches.map(b => b.code));

  // ---- Gói nhãn (bắt buộc) ----
  const packageSheet = getSheet(workbook, SHEET_PACKAGE);
  const packages: IOnboardingPackage[] = [];
  const labels: IOnboardingLabel[] = [];
  if (!packageSheet) {
    errors.push({
      sheet: SHEET_PACKAGE[0],
      row: 1,
      message: `thiếu sheet "${SHEET_PACKAGE[0]}"`,
    });
  } else {
    const sheetName = packageSheet.name;
    const orderByBranch = new Map<string, number>();
    for (const row of getRows(packageSheet)) {
      let branchCode = up(pick(row, ['Mã nhánh']));
      if (!branchCode) {
        const name = text(pick(row, ['Nhánh']));
        branchCode = branchByName.get(norm(name)) ?? '';
        if (!branchCode) {
          errors.push({
            sheet: sheetName,
            row: row.rowNumber,
            column: 'Nhánh',
            message: `không tìm thấy nhánh "${name}"`,
          });
          continue;
        }
      } else if (!branchCodes.has(branchCode)) {
        errors.push({
          sheet: sheetName,
          row: row.rowNumber,
          column: 'Mã nhánh',
          message: `nhánh ${branchCode} không có trong sheet "${SHEET_BRANCH}"`,
        });
      }
      const code = up(pick(row, ['Mã gói']));
      if (!code) {
        errors.push({
          sheet: sheetName,
          row: row.rowNumber,
          column: 'Mã gói',
          message: 'thiếu mã gói',
        });
        continue;
      }
      const labelTexts = splitList(
        pick(row, ['Nhãn chi tiết (vi)', 'Nhãn chi tiết']),
      );
      const labelCodes = upList(pick(row, ['Mã nhãn chi tiết']));
      if (labelTexts.length !== labelCodes.length) {
        errors.push({
          sheet: sheetName,
          row: row.rowNumber,
          column: 'Mã nhãn chi tiết',
          message: `số nhãn (${labelTexts.length}) khác số mã (${labelCodes.length})`,
        });
      }
      const nextOrder = (orderByBranch.get(branchCode) ?? 0) + 1;
      orderByBranch.set(branchCode, nextOrder);
      packages.push({
        code,
        branchCode,
        problemLabel: translationOf(row, 'Vấn đề — đáp án câu 2'),
        desireLabel: translationOf(row, 'Mong muốn — đáp án câu 3'),
        order: numberValue(pick(row, ['Thứ tự'])) ?? nextOrder,
        isActive: true,
      });
      sourceRows.set(code, {
        sheet: sheetName,
        row: row.rowNumber,
        column: 'Mã gói',
      });
      labelCodes.forEach((labelCode, i) => {
        labels.push({
          code: labelCode,
          packageCode: code,
          label: { vi: labelTexts[i] ?? '' },
          order: i + 1,
        });
        sourceRows.set(labelCode, {
          sheet: sheetName,
          row: row.rowNumber,
          column: 'Mã nhãn chi tiết',
        });
      });
    }
  }
  const knownLabels = new Set(labels.map(l => l.code));
  const knownPackages = new Set(packages.map(p => p.code));

  // ---- Mapping Khoá học (tuỳ chọn) ----
  const courseRows: ParsedCourseRow[] = [];
  const mappingSheet = getSheet(workbook, SHEET_MAPPING);
  if (mappingSheet) {
    for (const row of getRows(mappingSheet)) {
      const labelCodes = upList(pick(row, ['Mã nhãn vấn đề']));
      const desireCodes = upList(
        pick(row, ['Mã gói mong muốn', 'Mã nhãn mong muốn']),
      );
      for (const c of labelCodes) {
        if (!knownLabels.has(c)) {
          errors.push({
            sheet: mappingSheet.name,
            row: row.rowNumber,
            column: 'Mã nhãn vấn đề',
            message: `mã nhãn ${c} không có trong taxonomy`,
          });
        }
      }
      for (const c of desireCodes) {
        if (!knownPackages.has(c)) {
          errors.push({
            sheet: mappingSheet.name,
            row: row.rowNumber,
            column: 'Mã gói mong muốn',
            message: `mã gói ${c} không có trong taxonomy`,
          });
        }
      }
      courseRows.push({
        rowNumber: row.rowNumber,
        courseId: text(pick(row, COURSE_ID_HEADERS)),
        title: text(pick(row, ['Khoá học'])),
        labelCodes,
        desireCodes,
      });
    }
  }

  // ---- Lỗi cấu trúc toàn cây (mã trùng/sai định dạng, quan hệ gãy…) ----
  // Chạy cùng validator dùng cho PUT /onboarding-taxonomy để 400 luôn trả
  // dưới cùng một khoá `errors[]` như `OnboardingTaxonomyService.replace()`
  // — dù hình dạng từng phần tử khác nhau ({sheet,row,column,message} ở đây
  // vs {entity,code,message} bên PUT), khoá chung là điều
  // AllExceptionsFilter thực sự forward, nên client chỉ cần đọc một chỗ.
  const structuralIssues = validateTaxonomyTree(
    normalizeTree({ branches, packages, labels }),
  );
  for (const issue of structuralIssues) {
    const source = sourceRows.get(issue.code);
    errors.push({
      sheet: source?.sheet ?? SHEET_PACKAGE[0],
      row: source?.row ?? 0,
      column: source?.column,
      message: `${issue.code}: ${issue.message}`,
    });
  }

  return {
    tree: { branches, packages, labels },
    courseRows,
    errors,
    sourceRows,
  };
}

export interface ExportCourseRow {
  _id: string;
  titleVi: string;
  branchCode: string;
  status: string;
  labelCodes: string[];
  desireCodes: string[];
}

/** Export == template: cùng builder; dữ liệu rỗng thì chỉ còn header + hướng dẫn. */
export function buildTaxonomyWorkbook(
  tree: IOnboardingTaxonomyTree,
  courses: ExportCourseRow[],
): ExcelJS.Workbook {
  const wb = new ExcelJS.Workbook();
  const guide = wb.addWorksheet(SHEET_GUIDE);
  [
    [
      'File import Onboarding taxonomy (nhánh → gói → nhãn chi tiết → khoá học)',
    ],
    [''],
    ['Tab', 'Import đọc gì', 'Ghi chú'],
    [
      SHEET_BRANCH,
      BRANCH_HEADERS.join(' | '),
      'Mã nhánh in hoa (CX, LV…). "N" ở "Hiện ở câu 1" = chỉ dùng để gắn khoá.',
    ],
    [
      SHEET_PACKAGE[0],
      PACKAGE_HEADERS.join(' | '),
      '1 gói = 1 vấn đề = 1 mong muốn. Nhãn và mã nhãn ngăn bằng |, số phần tử bằng nhau, mã duy nhất toàn file.',
    ],
    [
      SHEET_MAPPING[0],
      MAPPING_HEADERS.join(' | '),
      'Có Course ID thì khớp theo ID, trống thì khớp tiêu đề tiếng Việt. Khoá không tìm thấy → cảnh báo, bỏ qua dòng.',
    ],
    [''],
    [
      'Import THAY TOÀN BỘ taxonomy và cập nhật nhãn cho khoá có trong tab Mapping; khoá không có trong tab giữ nguyên.',
    ],
    ['Cột ngôn ngữ (en/zh/ja/ko) để trống thì app dùng bản tiếng Việt.'],
  ].forEach(r => guide.addRow(r));

  const bs = wb.addWorksheet(SHEET_BRANCH);
  bs.addRow(BRANCH_HEADERS);
  for (const b of [...tree.branches].sort((a, z) => a.order - z.order)) {
    bs.addRow([
      b.code,
      b.label?.vi ?? '',
      b.label?.en ?? '',
      b.subtitle?.vi ?? '',
      b.subtitle?.en ?? '',
      b.iconUrl ?? '',
      b.imageUrl ?? '',
      b.order,
      b.isSelectable ? 'Y' : 'N',
      b.skillsetId ?? '',
    ]);
  }

  const ps = wb.addWorksheet(SHEET_PACKAGE[0]);
  ps.addRow(PACKAGE_HEADERS);
  const labelsByPackage = new Map<string, IOnboardingLabel[]>();
  for (const l of tree.labels) {
    const list = labelsByPackage.get(l.packageCode) ?? [];
    list.push(l);
    labelsByPackage.set(l.packageCode, list);
  }
  for (const p of [...tree.packages].sort(
    (a, z) => a.branchCode.localeCompare(z.branchCode) || a.order - z.order,
  )) {
    const ls = (labelsByPackage.get(p.code) ?? []).sort(
      (a, z) => a.order - z.order,
    );
    ps.addRow([
      p.branchCode,
      p.code,
      p.problemLabel?.vi ?? '',
      p.problemLabel?.en ?? '',
      p.desireLabel?.vi ?? '',
      p.desireLabel?.en ?? '',
      ls.map(l => l.label?.vi ?? '').join(' | '),
      ls.map(l => l.code).join(' | '),
      p.order,
    ]);
  }

  const ms = wb.addWorksheet(SHEET_MAPPING[0]);
  ms.addRow(MAPPING_HEADERS);
  for (const c of courses) {
    ms.addRow([
      c._id,
      c.titleVi,
      c.branchCode,
      c.status,
      c.labelCodes.join(' | '),
      c.desireCodes.join(' | '),
    ]);
  }
  return wb;
}

/**
 * Excel is a lossy transport: the sheet has no column for `isActive`, no zh/ja/ko
 * translation columns, and a re-export always writes `iconUrl`/`imageUrl` back so
 * those two survive — but an admin who never touched them on this round trip
 * still uploads a sheet where they parsed as `''`. Since `replace()` deletes the
 * three collections and re-inserts from scratch, importing the parsed tree
 * as-is would silently wipe every field Excel cannot carry.
 *
 * This merges per code: an existing branch/package/label keeps its stored
 * value for any field the sheet left empty (translations merged per locale — a
 * locale absent from the parsed row keeps its stored string), `isActive` is
 * ALWAYS kept from storage for a known code (the sheet has no such column at
 * all, so there is no "explicit false" to honour), and a brand-new code keeps
 * the parsed row untouched (there is nothing stored to fall back to, and the
 * parser already defaults a new `isActive` to `true`).
 */
export function mergeWithExistingTaxonomy(
  parsed: IOnboardingTaxonomyTree,
  existing: IOnboardingTaxonomyTree,
): IOnboardingTaxonomyTree {
  const mergeTranslation = (
    parsedT: ITranslation | undefined,
    existingT: ITranslation | undefined,
  ): ITranslation => {
    const merged: Record<string, string> = {
      ...(existingT as Record<string, string> | undefined),
    };
    for (const [lang, value] of Object.entries(parsedT ?? {})) {
      if (value) merged[lang] = value;
    }
    return merged;
  };

  const branchByCode = new Map(existing.branches.map(b => [b.code, b]));
  const packageByCode = new Map(existing.packages.map(p => [p.code, p]));
  const labelByCode = new Map(existing.labels.map(l => [l.code, l]));

  return {
    branches: parsed.branches.map(b => {
      const prev = branchByCode.get(b.code);
      if (!prev) return b;
      return {
        ...b,
        label: mergeTranslation(b.label, prev.label),
        subtitle: mergeTranslation(b.subtitle, prev.subtitle),
        iconUrl: b.iconUrl || prev.iconUrl,
        imageUrl: b.imageUrl || prev.imageUrl,
        skillsetId: b.skillsetId || prev.skillsetId,
        isActive: prev.isActive,
      };
    }),
    packages: parsed.packages.map(p => {
      const prev = packageByCode.get(p.code);
      if (!prev) return p;
      return {
        ...p,
        problemLabel: mergeTranslation(p.problemLabel, prev.problemLabel),
        desireLabel: mergeTranslation(p.desireLabel, prev.desireLabel),
        isActive: prev.isActive,
      };
    }),
    labels: parsed.labels.map(l => {
      const prev = labelByCode.get(l.code);
      if (!prev) return l;
      return {
        ...l,
        label: mergeTranslation(l.label, prev.label),
      };
    }),
  };
}
