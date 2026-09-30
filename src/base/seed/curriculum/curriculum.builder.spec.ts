import { buildSeedPlan, PeriodRef } from './curriculum.builder';
import { CurriculumFile } from './curriculum.types';

const PERIODS: PeriodRef[] = [
  { id: 'p04_ly', name: 'Nhà Lý', start: '1009', end: '1225' },
  { id: 'p05_tran', name: 'Nhà Trần', start: '1225', end: '1400' },
];

const FILE: CurriculumFile = {
  skillsets: [
    {
      periodId: 'p05_tran',
      courses: [
        {
          titleVi: 'Ba lần chống Mông–Nguyên',
          descriptionVi: 'Mô tả khoá.',
          lessons: [
            {
              titleVi: 'Lần thứ nhất, 1258',
              descriptionVi: 'Mô tả bài.',
              keypoints: [
                { titleVi: 'Đông Bộ Đầu', descriptionVi: 'x'.repeat(100) },
                { titleVi: 'Rút khỏi Thăng Long', descriptionVi: 'y'.repeat(100) },
                { titleVi: 'Kết cục', descriptionVi: 'z'.repeat(100) },
              ],
            },
          ],
        },
      ],
    },
    {
      periodId: 'p04_ly',
      courses: [
        {
          titleVi: 'Dời đô về Thăng Long',
          descriptionVi: 'Mô tả khoá.',
          lessons: [
            {
              titleVi: 'Chiếu dời đô',
              descriptionVi: 'Mô tả bài.',
              keypoints: [
                { titleVi: 'Lý do dời đô', descriptionVi: 'a'.repeat(100) },
                { titleVi: 'Đại La', descriptionVi: 'b'.repeat(100) },
                { titleVi: 'Hệ quả', descriptionVi: 'c'.repeat(100) },
              ],
            },
          ],
        },
      ],
    },
  ],
};

describe('buildSeedPlan', () => {
  it('xếp skillset theo thứ tự thời gian của periods, không theo thứ tự trong file', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(plan.skillsets.map((s) => s.title.vi)).toEqual(['Nhà Lý', 'Nhà Trần']);
    expect(plan.skillsets.map((s) => s.index)).toEqual([0, 1]);
  });

  it('đặt tên skillset và mô tả từ periods, kèm mốc năm', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    const ly = plan.skillsets.find((s) => s.title.vi === 'Nhà Lý');
    expect(ly.description.vi).toContain('1009');
    expect(ly.description.vi).toContain('1225');
  });

  it('mô tả chủ đề CHỈ là khoảng năm, không lặp lại tên thời kỳ', () => {
    // Dòng thời gian ở tab Khám phá đặt tên thời kỳ và khoảng năm trên hai
    // dòng riêng. Mô tả mà lặp lại tên thì app phải tách chuỗi bằng regex,
    // vốn vỡ ngay khi một tên thời kỳ tự chứa dấu ngoặc.
    const plan = buildSeedPlan(FILE, PERIODS);
    const ly = plan.categories.find((s) => s.title.vi === 'Nhà Lý');
    expect(ly.description.vi).toBe('1009 – 1225');
    expect(ly.description.vi).not.toContain('Nhà Lý');
  });

  it('chỉ điền locale vi, không bịa các locale khác', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(Object.keys(plan.skillsets[0].title)).toEqual(['vi']);
    expect(Object.keys(plan.keypoints[0].title)).toEqual(['vi']);
  });

  it('gán ảnh placeholder tuyệt đối .png theo thời kỳ cho mọi node', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    const abs = /^http:\/\/localhost:4000\/static\/history\/p\d{2}_\w+\.png$/;
    expect(plan.skillsets[0].image).toBe(
      'http://localhost:4000/static/history/p04_ly.png',
    );
    [plan.skillsets, plan.courses, plan.lessons, plan.keypoints].forEach(
      (docs) => {
        expect(docs.length).toBeGreaterThan(0);
        docs.forEach((d) => expect(d.image).toMatch(abs));
      },
    );
  });

  it('nhận base URL do nơi gọi truyền vào, bỏ dấu / thừa cuối', () => {
    const plan = buildSeedPlan(FILE, PERIODS, 'https://cdn.example.com/');
    expect(plan.skillsets[0].image).toBe(
      'https://cdn.example.com/static/history/p04_ly.png',
    );
    plan.keypoints.forEach((k) =>
      expect(k.image).toMatch(/^https:\/\/cdn\.example\.com\/static\/history\/.+\.png$/),
    );
  });

  it('nối course về đúng skillset và lesson về đúng course qua _localKey', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    const course = plan.courses.find((c) => c.title.vi === 'Dời đô về Thăng Long');
    expect(course.skillsetLocalKey).toBe('p04_ly');
    const lesson = plan.lessons.find((l) => l.title.vi === 'Chiếu dời đô');
    expect(lesson.courseLocalKey).toBe(course._localKey);
  });

  it('gắn tag phân biệt cho keypoint, đủ để khớp idempotent', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    plan.keypoints.forEach((k) => {
      expect(k.tag).toContain('vn-history');
      expect(k.tag).toContain(k._localKey);
    });
    const keys = plan.keypoints.map((k) => k._localKey);
    expect(new Set(keys).size).toBe(keys.length);
  });

  it('đặt numberOfLesson đúng số bài của khoá', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    plan.courses.forEach((c) => {
      const n = plan.lessons.filter((l) => l.courseLocalKey === c._localKey).length;
      expect(c.numberOfLesson).toBe(n);
    });
  });

  it('mỗi bài đúng một keypoint, lấy tên/mô tả/ảnh của bài, index 0', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(plan.lessons.every((l) => l.index === 0)).toBe(true);
    expect(plan.keypoints).toHaveLength(plan.lessons.length);
    plan.lessons.forEach((l) => {
      const kps = plan.keypoints.filter((k) => k.lessonLocalKey === l._localKey);
      expect(kps).toHaveLength(1);
      expect(kps[0].index).toBe(0);
      expect(kps[0].title).toEqual(l.title);
      expect(kps[0].description).toEqual(l.description);
      expect(kps[0].image).toBe(l.image);
    });
  });

  it('dùng status published để app thấy được ngay', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(plan.skillsets[0].status).toBe('published');
    expect(plan.courses[0].status).toBe('published');
    expect(plan.lessons[0].status).toBe('published');
  });

  it('ném lỗi khi periodId không có trong periods thay vì sinh ảnh sai', () => {
    const bad: CurriculumFile = {
      skillsets: [{ periodId: 'p99_khong_co', courses: [] }],
    };
    expect(() => buildSeedPlan(bad, PERIODS)).toThrow('p99_khong_co');
  });

  it('_localKey dùng NFC và trim, khớp với validator', () => {
    const nfd: CurriculumFile = JSON.parse(JSON.stringify(FILE));
    nfd.skillsets[1].courses[0].titleVi = ` ${'Dời đô'.normalize('NFD')} `;
    const nfc: CurriculumFile = JSON.parse(JSON.stringify(FILE));
    nfc.skillsets[1].courses[0].titleVi = 'Dời đô'.normalize('NFC');
    expect(buildSeedPlan(nfd, PERIODS).courses.map((c) => c._localKey)).toEqual(
      buildSeedPlan(nfc, PERIODS).courses.map((c) => c._localKey),
    );
  });

  describe('learningItems', () => {
    it('sinh đúng một theory cho mỗi keypoint, khớp qua _localKey', () => {
      const plan = buildSeedPlan(FILE, PERIODS);
      expect(plan.learningItems).toHaveLength(plan.keypoints.length);
      plan.keypoints.forEach((k, i) => {
        const li = plan.learningItems[i];
        expect(li.keypointLocalKey).toBe(k._localKey);
        expect(li.type).toBe('theory');
        expect(li.tag).toEqual(k.tag);
        expect(li.title).toEqual(k.title);
        expect(li.image).toBe(k.image);
        expect(li.index).toBe(0);
        expect(li.isSub).toBe(false);
        expect(li.questions).toEqual([]);
        expect(li.subQuestions).toEqual([]);
      });
    });

    it('documents[] một thẻ cho mỗi mục của bài, đúng thứ tự, id ổn định', () => {
      const plan = buildSeedPlan(FILE, PERIODS);
      const lessons = [...plan.lessons];
      const src = FILE.skillsets
        .flatMap((s) => s.courses)
        .flatMap((c) => c.lessons);
      lessons.forEach((l, i) => {
        const li = plan.learningItems[i];
        const entries = src.find((x) => x.titleVi === l.title.vi).keypoints;
        expect(li.documents).toHaveLength(entries.length);
        expect(li.documents.map((d) => d.id)).toEqual(
          entries.map((_, ei) => ei + 1),
        );
      });
    });

    it('tiêu đề mục vào khối title, mô tả vào khối text của đúng thẻ', () => {
      const plan = buildSeedPlan(FILE, PERIODS);
      const tran = plan.learningItems.find((li) => li.title.vi === 'Lần thứ nhất, 1258');
      expect(tran.documents.map((d) => d.document[0].data.content.vi)).toEqual([
        'Đông Bộ Đầu',
        'Rút khỏi Thăng Long',
        'Kết cục',
      ]);
      expect(tran.documents.map((d) => d.document[1].data.content.vi)).toEqual([
        'x'.repeat(100),
        'y'.repeat(100),
        'z'.repeat(100),
      ]);
      plan.learningItems.forEach((li) =>
        li.documents.forEach((d) => {
          expect(d.document.map((b) => b.type)).toEqual(['title', 'text']);
          expect(Object.keys(d.document[0].data.content)).toEqual(['vi']);
        }),
      );
    });

    describe('ảnh minh hoạ của thẻ', () => {
      const WITH_IMAGE: CurriculumFile = JSON.parse(JSON.stringify(FILE));
      const kps = WITH_IMAGE.skillsets[0].courses[0].lessons[0].keypoints;
      kps[1].image = 'https://upload.wikimedia.org/thumb/1200px-x.jpg';
      kps[1].imageFile = 'File:x.jpg';
      kps[1].imageLicense = 'CC BY-SA 4.0';
      kps[1].imageAuthor = '<a href="//commons.wikimedia.org/wiki/User:A">Nguyễn  Văn A</a>';

      const docsOf = (f: CurriculumFile) =>
        buildSeedPlan(f, PERIODS).learningItems.find(
          (li) => li.title.vi === 'Lần thứ nhất, 1258',
        ).documents;

      it('thẻ có ảnh: title, image (ghi công trong content), text; không có khối caption', () => {
        const d = docsOf(WITH_IMAGE)[1].document;
        expect(d.map((b) => b.type)).toEqual(['title', 'image', 'text']);
        expect(d.map((b) => b.id)).toEqual([1, 2, 3]);
        expect(d[1].data).toEqual({
          url: { vi: 'https://upload.wikimedia.org/thumb/1200px-x.jpg' },
          content: { vi: 'Ảnh: Nguyễn Văn A / CC BY-SA 4.0 — Wikimedia Commons' },
        });
      });

      it('không rõ tác giả: lời ghi công chỉ nêu giấy phép và Wikimedia Commons', () => {
        const f: CurriculumFile = JSON.parse(JSON.stringify(WITH_IMAGE));
        const k = f.skillsets[0].courses[0].lessons[0].keypoints[1];
        delete k.imageAuthor;
        const credit = (x: CurriculumFile) =>
          (docsOf(x)[1].document[1].data as { content: { vi: string } }).content.vi;
        expect(credit(f)).toBe('Ảnh: CC BY-SA 4.0 — Wikimedia Commons');
        k.imageAuthor = '<a href="x"> </a>';
        expect(credit(f)).toBe('Ảnh: CC BY-SA 4.0 — Wikimedia Commons');
      });

      it('thẻ không ảnh giữ nguyên hai khối title/text với id 1, 2', () => {
        const docs = docsOf(WITH_IMAGE);
        [0, 2].forEach((i) => {
          expect(docs[i].document.map((b) => b.type)).toEqual(['title', 'text']);
          expect(docs[i].document.map((b) => b.id)).toEqual([1, 2]);
        });
      });

      it('ảnh bìa của bài thay ảnh placeholder cho Lesson.image; bài không có giữ placeholder', () => {
        const f: CurriculumFile = JSON.parse(JSON.stringify(FILE));
        const lessons = f.skillsets[0].courses[0].lessons;
        lessons[0].image = 'https://upload.wikimedia.org/thumb/cover.jpg';
        const plan = buildSeedPlan(f, PERIODS);
        const first = plan.lessons.find((l) => l.title.vi === lessons[0].titleVi);
        expect(first.image).toBe('https://upload.wikimedia.org/thumb/cover.jpg');
        plan.lessons
          .filter((l) => l !== first)
          .forEach((l) => expect(l.image).toMatch(/\/static\/history\/p\d{2}_\w+\.png$/));
        // Chỉ Lesson.image đổi; keypoint/course/skillset vẫn là placeholder.
        expect(plan.keypoints[0].image).toMatch(/\.png$/);
        expect(plan.courses[0].image).toMatch(/\.png$/);
      });

      it('không sinh khối ảnh khi image là chuỗi rỗng, và không đụng file đầu vào', () => {
        const f: CurriculumFile = JSON.parse(JSON.stringify(FILE));
        f.skillsets[0].courses[0].lessons[0].keypoints[0].image = '';
        expect(docsOf(f)[0].document.map((b) => b.type)).toEqual(['title', 'text']);
        const snapshot = JSON.stringify(WITH_IMAGE);
        buildSeedPlan(WITH_IMAGE, PERIODS);
        expect(JSON.stringify(WITH_IMAGE)).toBe(snapshot);
      });

      it('xác định: cùng đầu vào có ảnh cho cùng kết quả', () => {
        expect(buildSeedPlan(WITH_IMAGE, PERIODS)).toEqual(
          buildSeedPlan(WITH_IMAGE, PERIODS),
        );
      });
    });

    it('xác định: cùng đầu vào cho cùng learningItems', () => {
      expect(buildSeedPlan(FILE, PERIODS).learningItems).toEqual(
        buildSeedPlan(FILE, PERIODS).learningItems,
      );
    });
  });

  describe('roadmaps', () => {
    const MULTI: CurriculumFile = {
      skillsets: [
        {
          periodId: 'p04_ly',
          courses: [
            {
              titleVi: 'Khoá nhiều bài',
              descriptionVi: 'Mô tả.',
              lessons: [
                {
                  titleVi: 'Bài A',
                  descriptionVi: 'Mô tả A.',
                  keypoints: [
                    { titleVi: 'A1', descriptionVi: 'x'.repeat(100) },
                    { titleVi: 'A2', descriptionVi: 'x'.repeat(100) },
                  ],
                },
                {
                  titleVi: 'Bài B',
                  descriptionVi: 'Mô tả B.',
                  keypoints: [
                    { titleVi: 'B1', descriptionVi: 'x'.repeat(100) },
                    { titleVi: 'B2', descriptionVi: 'x'.repeat(100) },
                  ],
                },
              ],
            },
          ],
        },
      ],
    };

    it('sinh đúng một roadmap cho mỗi khoá, khoá bằng _localKey của khoá', () => {
      const plan = buildSeedPlan(FILE, PERIODS);
      expect(plan.roadmaps).toHaveLength(plan.courses.length);
      expect(plan.roadmaps.map((r) => r.courseLocalKey)).toEqual(
        plan.courses.map((c) => c._localKey),
      );
    });

    it('một level duy nhất: id 1, level 1, nhãn theo tên khoá, ảnh của khoá', () => {
      const plan = buildSeedPlan(FILE, PERIODS);
      plan.roadmaps.forEach((r, i) => {
        expect(r.level.id).toBe(1);
        expect(r.level.level).toBe('level 1');
        expect(r.level.titleBadge).toEqual({ vi: plan.courses[i].title.vi });
        expect(r.level.badge).toBe(plan.courses[i].image);
      });
    });

    it('mỗi bài một node, đúng thứ tự, lessonIds trỏ đúng khoá bài', () => {
      const plan = buildSeedPlan(MULTI, PERIODS);
      const lessons = plan.lessons;
      const [r] = plan.roadmaps;
      expect(r.nodes).toHaveLength(2);
      r.nodes.forEach((n, i) => {
        expect(n.lessonLocalKeys).toEqual([lessons[i]._localKey]);
        expect(n.title).toEqual(lessons[i].title);
        expect(n.description).toEqual(lessons[i].description);
        expect(n.outputId).toBe('');
      });
      expect(new Set(r.nodes.map((n) => n.id)).size).toBe(2);
    });

    it('keypointIds: đúng một keypoint mỗi bài, theo thứ tự bài', () => {
      const plan = buildSeedPlan(MULTI, PERIODS);
      expect(plan.roadmaps[0].keypointLocalKeys).toEqual(
        plan.keypoints.map((k) => k._localKey),
      );
      expect(plan.roadmaps[0].keypointLocalKeys).toHaveLength(2);
    });

    it('xác định: cùng đầu vào cho cùng roadmaps', () => {
      expect(buildSeedPlan(MULTI, PERIODS).roadmaps).toEqual(
        buildSeedPlan(MULTI, PERIODS).roadmaps,
      );
    });
  });
});
