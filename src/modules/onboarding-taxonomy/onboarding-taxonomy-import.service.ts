import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import * as ExcelJS from 'exceljs';
import { Types } from 'mongoose';

import { CourseRepository } from 'src/modules/courses/src/modules/course/repository/course.repository';
import {
  getHeaders,
  ImportValidationError,
  readWorkbook,
  setCellByHeader,
  workbookToBuffer,
} from 'src/modules/courses/src/modules/import/excel-import.util';

import {
  buildTaxonomyWorkbook,
  COURSE_ID_HEADERS,
  ExportCourseRow,
  mergeWithExistingTaxonomy,
  parseTaxonomyWorkbook,
  SHEET_MAPPING,
} from './onboarding-taxonomy-excel';
import { OnboardingTaxonomyService } from './onboarding-taxonomy.service';
import { OnboardingBranchRepository } from './repository/onboarding-branch.repository';

const WARNING_SHEET = 'import_warnings';

@Injectable()
export class OnboardingTaxonomyImportService {
  private readonly logger = new Logger(OnboardingTaxonomyImportService.name);

  constructor(
    private readonly taxonomyService: OnboardingTaxonomyService,
    private readonly branchRepository: OnboardingBranchRepository,
    private readonly courseRepository: CourseRepository,
  ) {}

  /**
   * Hai pha, theo khuôn `keypoint.service.importKeypoints`: validate hết rồi
   * mới ghi. Lỗi taxonomy/mã lạ → 400 huỷ cả file; khoá không tìm thấy → cảnh
   * báo, bỏ dòng, ghi vào sheet `import_warnings`, các dòng khác vẫn ghi.
   * Trả lại chính workbook với cột Course ID đã điền cho dòng khớp theo tiêu đề.
   */
  async import(file: Express.Multer.File): Promise<{
    buffer: Buffer;
    warnings: number;
  }> {
    const workbook = await readWorkbook(file);
    const existingBranches = await this.branchRepository.findAll(false);
    const {
      tree: parsedTree,
      courseRows,
      errors,
    } = parseTaxonomyWorkbook(workbook, existingBranches);
    if (errors.length) {
      throw new BadRequestException({
        message: 'Excel import validation failed',
        errors,
      });
    }

    // Excel không tải theo isActive=false, iconUrl/imageUrl bỏ trống hay
    // zh/ja/ko — merge theo mã TRƯỚC khi ghi, vì replace() xoá hết rồi chèn
    // lại: import thẳng cây vừa đọc sẽ xoá âm thầm mọi field Excel không chở
    // theo. Đọc cây hiện tại trước khi ghi gì, giống taxonomyService.replace().
    const existingTree = await this.taxonomyService.getAdmin();
    const tree = mergeWithExistingTaxonomy(parsedTree, existingTree);

    // Pha 1b: tìm khoá trước khi ghi gì — để lỗi hạ tầng không để lại nửa
    // taxonomy.
    const resolved: { row: (typeof courseRows)[number]; courseId: string }[] =
      [];
    const warnings: ImportValidationError[] = [];
    for (const row of courseRows) {
      if (row.courseId && !Types.ObjectId.isValid(row.courseId)) {
        warnings.push({
          sheet: SHEET_MAPPING[0],
          row: row.rowNumber,
          column: 'Course ID (tuỳ chọn)',
          message: `Course ID ${row.courseId} không hợp lệ — bỏ qua dòng`,
        });
        continue;
      }
      const courseId =
        row.courseId ||
        (await this.courseRepository.findIdByViTitle(row.title));
      if (!courseId) {
        warnings.push({
          sheet: SHEET_MAPPING[0],
          row: row.rowNumber,
          column: 'Khoá học',
          message: `không tìm thấy khoá "${row.title}" — bỏ qua dòng`,
        });
        continue;
      }
      if (
        row.courseId &&
        !(await this.courseRepository.findById(row.courseId))
      ) {
        warnings.push({
          sheet: SHEET_MAPPING[0],
          row: row.rowNumber,
          column: 'Course ID (tuỳ chọn)',
          message: `Course ID ${row.courseId} không tồn tại — bỏ qua dòng`,
        });
        continue;
      }
      resolved.push({ row, courseId });
    }

    // Pha 2: ghi.
    await this.taxonomyService.replace(tree);
    const mappingSheet =
      workbook.getWorksheet(SHEET_MAPPING[0]) ??
      workbook.getWorksheet(SHEET_MAPPING[1]);
    // Đọc chấp nhận alias (Course ID (tuỳ chọn) / Course ID / id) — ghi lại
    // cũng phải resolve đúng alias đang có trên sheet, không hardcode header
    // đầy đủ, kẻo silently no-op khi sheet dùng alias ngắn.
    const mappingHeaders = mappingSheet ? getHeaders(mappingSheet) : [];
    const courseIdHeader = COURSE_ID_HEADERS.find(h =>
      mappingHeaders.includes(h),
    );
    for (const { row, courseId } of resolved) {
      await this.courseRepository.updateOnboardingTags(courseId, {
        onboardingLabelCodes: row.labelCodes,
        onboardingDesireCodes: row.desireCodes,
      });
      if (mappingSheet && courseIdHeader && !row.courseId) {
        setCellByHeader(mappingSheet, row.rowNumber, courseIdHeader, courseId);
      }
    }

    if (warnings.length) {
      const sheet = workbook.addWorksheet(WARNING_SHEET);
      sheet.addRow(['sheet', 'row', 'column', 'message']);
      for (const w of warnings)
        sheet.addRow([w.sheet, w.row, w.column ?? '', w.message]);
    }
    this.logger.log(
      `Onboarding taxonomy imported: ${tree.packages.length} packages, ${resolved.length} courses tagged, ${warnings.length} warnings`,
    );
    return {
      buffer: await workbookToBuffer(workbook),
      warnings: warnings.length,
    };
  }

  async export(): Promise<Buffer> {
    const tree = await this.taxonomyService.getAdmin();
    const courses = await this.courseRepository.findAllForExport();
    const branchOfPackage = new Map(
      tree.packages.map(p => [p.code, p.branchCode]),
    );
    const rows: ExportCourseRow[] = courses.map((c: any) => ({
      _id: String(c._id),
      titleVi: c.title?.vi ?? c.title?.en ?? '',
      branchCode: branchOfPackage.get((c.onboardingDesireCodes ?? [])[0]) ?? '',
      status: c.status ?? '',
      labelCodes: c.onboardingLabelCodes ?? [],
      desireCodes: c.onboardingDesireCodes ?? [],
    }));
    return workbookToBuffer(buildTaxonomyWorkbook(tree, rows));
  }

  /** Mẫu = export hiện tại; DB trống thì thêm 1 dòng ví dụ mỗi sheet. */
  async template(): Promise<Buffer> {
    const tree = await this.taxonomyService.getAdmin();
    if (tree.packages.length) return this.export();
    const wb: ExcelJS.Workbook = buildTaxonomyWorkbook(
      {
        branches: [
          {
            code: 'CX',
            label: { vi: 'Cảm xúc & tinh thần', en: 'Emotions & mind' },
            subtitle: { vi: 'Hiểu cảm xúc để làm chủ cuộc sống' },
            iconUrl: '',
            imageUrl: '',
            order: 1,
            isSelectable: true,
            skillsetId: null,
            isActive: true,
          },
        ],
        packages: [
          {
            code: 'CX-1',
            branchCode: 'CX',
            problemLabel: { vi: 'Dễ căng thẳng' },
            desireLabel: { vi: 'Thả lỏng được trong ngày' },
            order: 1,
            isActive: true,
          },
        ],
        labels: [
          {
            code: 'CX01',
            packageCode: 'CX-1',
            label: { vi: 'Người lúc nào cũng căng cứng' },
            order: 1,
          },
        ],
      },
      [
        {
          _id: '',
          titleVi: 'Nội cảm thụ: Lắng nghe tín hiệu cơ thể',
          branchCode: 'CX',
          status: 'published',
          labelCodes: ['CX01'],
          desireCodes: ['CX-1'],
        },
      ],
    );
    return workbookToBuffer(wb);
  }
}
