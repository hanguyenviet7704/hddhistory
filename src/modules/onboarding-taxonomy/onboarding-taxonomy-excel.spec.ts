import * as fs from 'fs';
import * as path from 'path';

import * as ExcelJS from 'exceljs';

import { IOnboardingTaxonomyTree } from './interface/onboarding-taxonomy.interface';
import {
  buildTaxonomyWorkbook,
  mergeWithExistingTaxonomy,
  parseTaxonomyWorkbook,
} from './onboarding-taxonomy-excel';

function sheet(wb: ExcelJS.Workbook, name: string, rows: any[][]) {
  const ws = wb.addWorksheet(name);
  rows.forEach(r => ws.addRow(r));
}

describe('parseTaxonomyWorkbook', () => {
  it('parses the three sheets of the template into a tree + course rows', () => {
    const wb = new ExcelJS.Workbook();
    sheet(wb, 'Nhánh', [
      [
        'Mã nhánh',
        'Tên nhánh (vi)',
        'Tên nhánh (en)',
        'Mô tả ngắn (vi)',
        'Mô tả ngắn (en)',
        'Thứ tự',
        'Hiện ở câu 1 (Y/N)',
        'Skillset ID (tuỳ chọn)',
      ],
      ['CX', 'Cảm xúc & tinh thần', 'Emotions', 'sub vi', 'sub en', 1, 'Y', ''],
      ['KP', 'Khám phá não bộ', '', '', '', 6, 'N', '64abc'],
    ]);
    sheet(wb, 'Gói nhãn', [
      [
        'Mã nhánh',
        'Mã gói',
        'Vấn đề — đáp án câu 2 (vi)',
        'Vấn đề — đáp án câu 2 (en)',
        'Mong muốn — đáp án câu 3 (vi)',
        'Mong muốn — đáp án câu 3 (en)',
        'Nhãn chi tiết (vi)',
        'Mã nhãn chi tiết',
        'Thứ tự',
      ],
      [
        'CX',
        'CX-1',
        'Dễ căng thẳng',
        'Stressed',
        'Thả lỏng được trong ngày',
        'Relax',
        'A | B',
        'CX01 | CX02',
        1,
      ],
    ]);
    sheet(wb, 'Mapping Khoá học', [
      [
        'Course ID (tuỳ chọn)',
        'Khoá học',
        'Nhánh nội dung',
        'Trạng thái (tham khảo)',
        'Mã nhãn vấn đề',
        'Mã gói mong muốn',
      ],
      ['', 'Nội cảm thụ', 'CX', 'published', 'CX01 | CX02', 'CX-1'],
      ['64def', 'Khoá có id', 'KP', 'published', '', 'CX-1'],
    ]);

    const { tree, courseRows, errors } = parseTaxonomyWorkbook(wb, []);

    expect(errors).toEqual([]);
    expect(
      tree.branches.map(b => [b.code, b.isSelectable, b.skillsetId]),
    ).toEqual([
      ['CX', true, null],
      ['KP', false, '64abc'],
    ]);
    expect(tree.packages).toEqual([
      expect.objectContaining({
        code: 'CX-1',
        branchCode: 'CX',
        problemLabel: { vi: 'Dễ căng thẳng', en: 'Stressed' },
        desireLabel: { vi: 'Thả lỏng được trong ngày', en: 'Relax' },
        order: 1,
      }),
    ]);
    expect(tree.labels).toEqual([
      expect.objectContaining({
        code: 'CX01',
        packageCode: 'CX-1',
        label: { vi: 'A' },
        order: 1,
      }),
      expect.objectContaining({
        code: 'CX02',
        packageCode: 'CX-1',
        label: { vi: 'B' },
        order: 2,
      }),
    ]);
    expect(courseRows).toEqual([
      {
        rowNumber: 2,
        courseId: '',
        title: 'Nội cảm thụ',
        labelCodes: ['CX01', 'CX02'],
        desireCodes: ['CX-1'],
      },
      {
        rowNumber: 3,
        courseId: '64def',
        title: 'Khoá có id',
        labelCodes: [],
        desireCodes: ['CX-1'],
      },
    ]);
  });

  it('accepts the BA sheet layout: tab "Nhãn" with branch NAME and no (vi) suffix, branches reused from DB', () => {
    const wb = new ExcelJS.Workbook();
    sheet(wb, 'Nhãn', [
      [
        'Nhánh',
        'Mã gói',
        'Vấn đề — đáp án câu 2',
        'Mong muốn — đáp án câu 3',
        'Số nhãn chi tiết',
        'Nhãn chi tiết',
        'Mã nhãn chi tiết',
      ],
      [
        'Cảm xúc & tinh thần',
        'CX-2',
        'Suy nghĩ nhiều',
        'Đầu óc yên hơn',
        2,
        'X | Y',
        'CX06 | CX07',
      ],
    ]);
    const existing = [
      {
        code: 'CX',
        label: { vi: 'Cảm xúc & tinh thần' },
        subtitle: {},
        iconUrl: '',
        imageUrl: '',
        order: 1,
        isSelectable: true,
        skillsetId: null,
        isActive: true,
      },
    ];

    const { tree, errors } = parseTaxonomyWorkbook(wb, existing as any);

    expect(errors).toEqual([]);
    expect(tree.branches).toEqual(existing);
    expect(tree.packages[0]).toEqual(
      expect.objectContaining({
        code: 'CX-2',
        branchCode: 'CX',
        problemLabel: { vi: 'Suy nghĩ nhiều' },
      }),
    );
    expect(tree.labels.map(l => l.code)).toEqual(['CX06', 'CX07']);
  });

  it('reports mismatched label/code counts, unknown codes in the mapping sheet and a missing package sheet', () => {
    const wb = new ExcelJS.Workbook();
    sheet(wb, 'Gói nhãn', [
      [
        'Mã nhánh',
        'Mã gói',
        'Vấn đề — đáp án câu 2 (vi)',
        'Mong muốn — đáp án câu 3 (vi)',
        'Nhãn chi tiết (vi)',
        'Mã nhãn chi tiết',
      ],
      ['CX', 'CX-1', 'p', 'd', 'A | B', 'CX01'],
    ]);
    sheet(wb, 'Mapping Khoá học', [
      [
        'Course ID (tuỳ chọn)',
        'Khoá học',
        'Mã nhãn vấn đề',
        'Mã gói mong muốn',
      ],
      ['', 'K', 'ZZ99', 'CX-7'],
    ]);
    const { errors } = parseTaxonomyWorkbook(wb, []);
    expect(errors.map(e => e.message)).toEqual(
      expect.arrayContaining([
        expect.stringContaining('số nhãn'),
        expect.stringContaining('ZZ99'),
        expect.stringContaining('CX-7'),
      ]),
    );

    const empty = parseTaxonomyWorkbook(new ExcelJS.Workbook(), []);
    expect(empty.errors[0].message).toContain('Gói nhãn');
  });

  it('flags a duplicated package code as a structural error, pointing at the row of its last occurrence', () => {
    const wb = new ExcelJS.Workbook();
    sheet(wb, 'Gói nhãn', [
      [
        'Mã nhánh',
        'Mã gói',
        'Vấn đề — đáp án câu 2 (vi)',
        'Mong muốn — đáp án câu 3 (vi)',
        'Nhãn chi tiết (vi)',
        'Mã nhãn chi tiết',
      ],
      ['CX', 'CX-1', 'p1', 'd1', 'A', 'CX01'],
      ['CX', 'CX-1', 'p2', 'd2', 'B', 'CX02'],
    ]);
    const existing = [
      {
        code: 'CX',
        label: { vi: 'Cảm xúc' },
        subtitle: {},
        iconUrl: '',
        imageUrl: '',
        order: 1,
        isSelectable: true,
        skillsetId: null,
        isActive: true,
      },
    ];

    const { errors } = parseTaxonomyWorkbook(wb, existing as any);

    expect(errors).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          sheet: 'Gói nhãn',
          row: 3,
          column: 'Mã gói',
          message: expect.stringContaining('CX-1: mã package bị trùng'),
        }),
      ]),
    );
  });
});

describe('buildTaxonomyWorkbook', () => {
  it('writes the three sheets with the template headers and joins lists with " | "', () => {
    const wb = buildTaxonomyWorkbook(
      {
        branches: [
          {
            code: 'CX',
            label: { vi: 'Cảm xúc', en: 'Emo' },
            subtitle: { vi: 's' },
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
            problemLabel: { vi: 'p' },
            desireLabel: { vi: 'd' },
            order: 1,
            isActive: true,
          },
        ],
        labels: [
          { code: 'CX01', packageCode: 'CX-1', label: { vi: 'A' }, order: 1 },
          { code: 'CX02', packageCode: 'CX-1', label: { vi: 'B' }, order: 2 },
        ],
      },
      [
        {
          _id: 'id1',
          titleVi: 'Khoá',
          branchCode: 'CX',
          status: 'published',
          labelCodes: ['CX01'],
          desireCodes: ['CX-1'],
        },
      ],
    );
    expect(wb.worksheets.map(w => w.name)).toEqual([
      'Hướng dẫn',
      'Nhánh',
      'Gói nhãn',
      'Mapping Khoá học',
    ]);
    const pkg = wb.getWorksheet('Gói nhãn')!;
    expect(pkg.getRow(1).getCell(1).value).toBe('Mã nhánh');
    expect(pkg.getRow(2).getCell(7).value).toBe('A | B');
    expect(pkg.getRow(2).getCell(8).value).toBe('CX01 | CX02');
    const map = wb.getWorksheet('Mapping Khoá học')!;
    expect(map.getRow(2).getCell(1).value).toBe('id1');
  });
});

describe('parseTaxonomyWorkbook against the real BA template', () => {
  it('parses plans/260918-onboarding-v3-taxonomy/onboarding-taxonomy-template.xlsx with 0 errors', async () => {
    const filePath = path.join(
      process.cwd(),
      'plans',
      '260918-onboarding-v3-taxonomy',
      'onboarding-taxonomy-template.xlsx',
    );
    const buffer = fs.readFileSync(filePath);
    const wb = new ExcelJS.Workbook();
    await wb.xlsx.load(buffer as any);

    const { tree, courseRows, errors } = parseTaxonomyWorkbook(wb, []);

    expect(errors).toEqual([]);
    expect(tree.branches.length).toBe(6);
    expect(tree.packages.length).toBe(26);
    expect(tree.labels.length).toBe(115);
    expect(courseRows.length).toBe(52);
  });
});

describe('mergeWithExistingTaxonomy', () => {
  it('keeps iconUrl, a zh translation and isActive:false from storage when the re-imported sheet carries none of them', () => {
    const existing: IOnboardingTaxonomyTree = {
      branches: [
        {
          code: 'CX',
          label: { vi: 'Cảm xúc & tinh thần', en: 'Emotions', zh: '情感' },
          subtitle: { vi: 'sub cũ' },
          iconUrl: 'https://cdn/icon.png',
          imageUrl: 'https://cdn/image.png',
          order: 1,
          isSelectable: true,
          skillsetId: '64abc',
          isActive: false,
        },
      ],
      packages: [
        {
          code: 'CX-1',
          branchCode: 'CX',
          problemLabel: { vi: 'Dễ căng thẳng', zh: '压力大' },
          desireLabel: { vi: 'Thả lỏng được' },
          order: 1,
          isActive: false,
        },
      ],
      labels: [
        {
          code: 'CX01',
          packageCode: 'CX-1',
          label: { vi: 'Người lúc nào cũng căng cứng', zh: '总是很紧绷的人' },
          order: 1,
        },
      ],
    };
    // Excel không có cột isActive/zh, và Excel export chỉ chở lại
    // iconUrl/imageUrl khi chúng có giá trị — mô phỏng một sheet re-import mà
    // admin đã sửa vài ô vi/en nhưng chưa từng chạm các field trên.
    const parsed: IOnboardingTaxonomyTree = {
      branches: [
        {
          code: 'CX',
          label: { vi: 'Cảm xúc & tinh thần (sửa)', en: 'Emotions' },
          subtitle: { vi: 'sub mới' },
          iconUrl: '',
          imageUrl: '',
          order: 1,
          isSelectable: true,
          skillsetId: null,
          isActive: true, // parser luôn ghi true — sheet không có cột này
        },
      ],
      packages: [
        {
          code: 'CX-1',
          branchCode: 'CX',
          problemLabel: { vi: 'Dễ căng thẳng (sửa)' },
          desireLabel: { vi: 'Thả lỏng được' },
          order: 1,
          isActive: true,
        },
      ],
      labels: [
        {
          code: 'CX01',
          packageCode: 'CX-1',
          label: { vi: 'Người lúc nào cũng căng cứng (sửa)' },
          order: 1,
        },
      ],
    };

    const merged = mergeWithExistingTaxonomy(parsed, existing);

    expect(merged.branches[0]).toEqual({
      code: 'CX',
      label: { vi: 'Cảm xúc & tinh thần (sửa)', en: 'Emotions', zh: '情感' },
      subtitle: { vi: 'sub mới' },
      iconUrl: 'https://cdn/icon.png',
      imageUrl: 'https://cdn/image.png',
      order: 1,
      isSelectable: true,
      skillsetId: '64abc',
      isActive: false,
    });
    expect(merged.packages[0]).toEqual({
      code: 'CX-1',
      branchCode: 'CX',
      problemLabel: { vi: 'Dễ căng thẳng (sửa)', zh: '压力大' },
      desireLabel: { vi: 'Thả lỏng được' },
      order: 1,
      isActive: false,
    });
    expect(merged.labels[0]).toEqual({
      code: 'CX01',
      packageCode: 'CX-1',
      label: { vi: 'Người lúc nào cũng căng cứng (sửa)', zh: '总是很紧绷的人' },
      order: 1,
    });
  });

  it('keeps a brand-new code exactly as parsed, with no existing row to fall back to', () => {
    const parsed: IOnboardingTaxonomyTree = {
      branches: [
        {
          code: 'NEW',
          label: { vi: 'Mới' },
          subtitle: {},
          iconUrl: '',
          imageUrl: '',
          order: 2,
          isSelectable: true,
          skillsetId: null,
          isActive: true,
        },
      ],
      packages: [],
      labels: [],
    };
    const merged = mergeWithExistingTaxonomy(parsed, {
      branches: [],
      packages: [],
      labels: [],
    });
    expect(merged.branches[0]).toEqual(parsed.branches[0]);
  });
});
