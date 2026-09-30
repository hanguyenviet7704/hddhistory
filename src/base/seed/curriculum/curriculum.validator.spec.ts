import { CurriculumFile } from './curriculum.types';
import { validateCurriculum, SeedRef } from './curriculum.validator';

const SEED: SeedRef = {
  periodIds: new Set(['p04_ly', 'p05_tran']),
  entityIds: new Set(['ly_thuong_kiet', 'tran_hung_dao']),
};

function keypoint(i: number, l = 0) {
  return {
    titleVi: `Ý chính ${i}`,
    // Mỗi keypoint một nội dung riêng, nếu không sẽ dính bộ phát hiện copy-paste.
    descriptionVi: `Nội dung riêng của bài ${l}, ý ${i}. `.padEnd(120, 'x'),
    entityIds: ['ly_thuong_kiet'],
  };
}

function lesson(i: number) {
  return {
    titleVi: `Bài ${i}`,
    descriptionVi: 'Mô tả bài học đủ dài để qua kiểm tra.',
    keypoints: [keypoint(1, i), keypoint(2, i), keypoint(3, i)],
  };
}

function valid(): CurriculumFile {
  return {
    skillsets: [
      {
        periodId: 'p04_ly',
        courses: [
          {
            titleVi: 'Dời đô về Thăng Long',
            descriptionVi: 'Mô tả khoá học đủ dài để qua kiểm tra.',
            lessons: [lesson(1), lesson(2), lesson(3), lesson(4), lesson(5)],
          },
        ],
      },
    ],
  };
}

describe('validateCurriculum', () => {
  it('không báo lỗi với dữ liệu hợp lệ', () => {
    expect(validateCurriculum(valid(), SEED)).toEqual([]);
  });

  it('bắt periodId không có trong vn_history_seed.json', () => {
    const f = valid();
    f.skillsets[0].periodId = 'p99_khong_co';
    const errors = validateCurriculum(f, SEED);
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('p99_khong_co');
    expect(errors[0]).toContain('skillsets[0]');
  });

  it('bắt entityId không có trong seed', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints[0].entityIds = ['nguoi_bia'];
    const errors = validateCurriculum(f, SEED);
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('nguoi_bia');
  });

  it('bắt title rỗng và nêu đúng đường dẫn tới chỗ hỏng', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints[1].titleVi = '   ';
    const errors = validateCurriculum(f, SEED);
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('skillsets[0].courses[0].lessons[0].keypoints[1]');
  });

  it('bắt bài học có ít hơn 3 keypoint', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints = [keypoint(1)];
    const errors = validateCurriculum(f, SEED);
    expect(errors.some((e) => e.includes('keypoint'))).toBe(true);
  });

  it('nhận 3–6 thẻ mỗi bài, từ chối 2 và 7', () => {
    const at = (n: number) => {
      const f = valid();
      f.skillsets[0].courses[0].lessons[0].keypoints = Array.from(
        { length: n },
        (_, i) => keypoint(i + 1, 9),
      );
      return validateCurriculum(f, SEED);
    };
    expect(at(3)).toHaveLength(0);
    expect(at(6)).toHaveLength(0);
    expect(at(2).some((e) => e.includes('keypoint'))).toBe(true);
    expect(at(7).some((e) => e.includes('keypoint'))).toBe(true);
  });

  it('bắt keypoint quá ngắn — dấu hiệu nội dung bỏ dở', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints[0].descriptionVi = 'Ngắn quá.';
    const errors = validateCurriculum(f, SEED);
    expect(errors.some((e) => e.includes('ngắn'))).toBe(true);
  });

  it('bắt hai khoá trùng tên trong cùng một thời kỳ', () => {
    const f = valid();
    f.skillsets[0].courses.push({ ...f.skillsets[0].courses[0] });
    const errors = validateCurriculum(f, SEED);
    expect(errors.some((e) => e.includes('trùng'))).toBe(true);
  });

  it('gom mọi lỗi chứ không dừng ở lỗi đầu tiên', () => {
    const f = valid();
    f.skillsets[0].periodId = 'p99_khong_co';
    f.skillsets[0].courses[0].titleVi = '';
    expect(validateCurriculum(f, SEED).length).toBeGreaterThanOrEqual(2);
  });

  it('không sập khi gặp node null, vẫn gom các lỗi còn lại', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints[0] = null;
    f.skillsets[0].courses[0].lessons[1] = null;
    f.skillsets[0].courses.push(null);
    f.skillsets.push(null);
    const errors = validateCurriculum(f, SEED);
    expect(errors).toHaveLength(4);
    expect(errors.join('\n')).toContain(
      'skillsets[0].courses[0].lessons[0].keypoints[0]',
    );
  });

  describe('vòng sửa 1', () => {
    const LP = 'skillsets[0].courses[0].lessons';

    it('không ném khi entityIds không phải mảng', () => {
      const f = valid();
      (f.skillsets[0].courses[0].lessons[0].keypoints[0] as any).entityIds =
        'ly_thuong_kiet';
      let errors: string[];
      expect(() => (errors = validateCurriculum(f, SEED))).not.toThrow();
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain(`${LP}[0].keypoints[0]`);
      expect(errors[0]).toContain('entityIds');
    });

    it('không ném khi titleVi của khoá không phải chuỗi, và báo sai kiểu chứ không phải thiếu', () => {
      const f = valid();
      (f.skillsets[0].courses[0] as any).titleVi = 5;
      (f.skillsets[0].courses[0].lessons[0] as any).titleVi = {};
      let errors: string[];
      expect(() => (errors = validateCurriculum(f, SEED))).not.toThrow();
      expect(errors).toHaveLength(2);
      expect(errors[0]).toContain('skillsets[0].courses[0]');
      expect(errors[0]).toContain('phải là chuỗi');
      expect(errors[0]).not.toContain('thiếu');
      expect(errors[1]).toContain(`${LP}[0]`);
    });

    it('bắt bài trùng tên trong cùng khoá, nêu cả hai đường dẫn', () => {
      const f = valid();
      f.skillsets[0].courses[0].lessons[1].titleVi = 'Bài 1';
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain(`${LP}[1]`);
      expect(errors[0]).toContain(`${LP}[0]`);
    });

    it('bắt keypoint trùng tên trong cùng bài, nêu cả hai đường dẫn', () => {
      const f = valid();
      f.skillsets[0].courses[0].lessons[0].keypoints[2].titleVi = 'Ý chính 1';
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain(`${LP}[0].keypoints[2]`);
      expect(errors[0]).toContain(`${LP}[0].keypoints[0]`);
    });

    it('cho phép keypoint trùng tên ở hai bài khác nhau', () => {
      expect(validateCurriculum(valid(), SEED)).toEqual([]);
    });

    it('bắt periodId lặp ở hai skillset', () => {
      const f = valid();
      f.skillsets.push(JSON.parse(JSON.stringify(f.skillsets[0])));
      // đổi nội dung để chỉ còn lỗi periodId
      f.skillsets[1].courses[0].titleVi = 'Khoá khác';
      f.skillsets[1].courses[0].lessons.forEach((l, li) =>
        l.keypoints.forEach((k, ki) => (k.descriptionVi = `khác ${li} ${ki} `.padEnd(100, 'q'))),
      );
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain('skillsets[1]');
      expect(errors[0]).toContain('skillsets[0]');
    });

    it('bắt skillsets rỗng', () => {
      expect(validateCurriculum({ skillsets: [] }, SEED)).toHaveLength(1);
    });

    it('bắt descriptionVi lặp giữa hai keypoint ở hai bài, nêu cả hai đường dẫn', () => {
      const f = valid();
      const lessons = f.skillsets[0].courses[0].lessons;
      lessons[3].keypoints[1].descriptionVi = lessons[0].keypoints[2].descriptionVi;
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain(`${LP}[3].keypoints[1]`);
      expect(errors[0]).toContain(`${LP}[0].keypoints[2]`);
    });

    it('bắt descriptionVi giống hệt titleVi của chính nó', () => {
      const f = valid();
      const k = f.skillsets[0].courses[0].lessons[0].keypoints[0];
      k.titleVi = k.descriptionVi;
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain(`${LP}[0].keypoints[0]`);
      expect(errors[0]).toContain('giống hệt titleVi');
    });

    it('cấm "::" trong title', () => {
      const f = valid();
      f.skillsets[0].courses[0].lessons[0].keypoints[0].titleVi = 'a::b';
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain(`${LP}[0].keypoints[0]`);
      expect(errors[0]).toContain('::');
    });

    it('so tên theo NFC và bỏ khoảng trắng đầu cuối', () => {
      const f = valid();
      const nfc = 'Dời đô'.normalize('NFC');
      f.skillsets[0].courses[0].titleVi = nfc;
      f.skillsets[0].courses.push({
        ...JSON.parse(JSON.stringify(f.skillsets[0].courses[0])),
        titleVi: ` ${'Dời đô'.normalize('NFD')} `,
      });
      f.skillsets[0].courses[1].lessons.forEach((l, li) =>
        l.keypoints.forEach((k, ki) => (k.descriptionVi = `khác ${li} ${ki} `.padEnd(100, 'q'))),
      );
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain('skillsets[0].courses[1]');
      expect(errors[0]).toContain('trùng');
    });

    it('phần tử là mảng bị báo "không phải object" đúng một lần', () => {
      const f = valid();
      (f.skillsets[0].courses[0].lessons as any[])[1] = [];
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain('không phải object');
    });
  });

  describe('ảnh minh hoạ của thẻ', () => {
    const KP = 'skillsets[0].courses[0].lessons[0].keypoints[0]';
    const withImage = (image: unknown) => {
      const f = valid();
      (f.skillsets[0].courses[0].lessons[0].keypoints[0] as any).image = image;
      return f;
    };

    it('nhận thẻ có image https cùng các trường nguồn', () => {
      const f = withImage('https://upload.wikimedia.org/a/1200px-b.jpg');
      Object.assign(f.skillsets[0].courses[0].lessons[0].keypoints[0], {
        imageFile: 'File:b.jpg',
        imageLicense: 'Public domain',
        imageSource: 'https://vi.wikipedia.org/wiki/B',
        imageAuthor: 'Ai đó',
      });
      expect(validateCurriculum(f, SEED)).toEqual([]);
    });

    it('nhận thẻ không có image', () => {
      expect(validateCurriculum(valid(), SEED)).toEqual([]);
    });

    it('từ chối image không phải chuỗi mà không ném', () => {
      let errors: string[];
      expect(() => (errors = validateCurriculum(withImage(42), SEED))).not.toThrow();
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain(KP);
      expect(errors[0]).toContain('image phải là chuỗi');
      expect(validateCurriculum(withImage(null), SEED)[0]).toContain('null');
    });

    it('từ chối image không phải https://', () => {
      ['http://x.org/a.jpg', '/static/a.jpg', '', 'https://'].forEach((u) => {
        const errors = validateCurriculum(withImage(u), SEED);
        expect(errors).toHaveLength(1);
        expect(errors[0]).toContain('https://');
      });
    });

    it('từ chối trường nguồn không phải chuỗi', () => {
      const f = valid();
      (f.skillsets[0].courses[0].lessons[0].keypoints[0] as any).imageLicense = 1;
      const errors = validateCurriculum(f, SEED);
      expect(errors).toHaveLength(1);
      expect(errors[0]).toContain('imageLicense');
    });
  });
});
