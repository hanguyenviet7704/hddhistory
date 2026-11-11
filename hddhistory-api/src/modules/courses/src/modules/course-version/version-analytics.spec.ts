import {
  DROP_OFF_DEPTH_PCT,
  depthCurve,
  dropOffLessons,
  groupWindowsByTag,
  lessonShapesOf,
  liveSeconds,
  rangeOf,
  retentionCurve,
} from './version-analytics';

const d = (iso: string) => new Date(iso);

describe('groupWindowsByTag', () => {
  it('cho tag bị roll back rồi quay lại HAI đoạn rời nhau', () => {
    const rows = [
      { tag: 'v1.0.0', versionId: 'a', from: d('2026-09-01T00:00:00Z'), to: d('2026-09-03T00:00:00Z') },
      { tag: 'v1.0.1', versionId: 'b', from: d('2026-09-03T00:00:00Z'), to: d('2026-09-05T00:00:00Z') },
      { tag: 'v1.0.0', versionId: 'a', from: d('2026-09-05T00:00:00Z'), to: null },
    ];

    const grouped = groupWindowsByTag(rows);

    expect(grouped.map(g => g.tag)).toEqual(['v1.0.0', 'v1.0.1']);
    expect(grouped[0].windows).toHaveLength(2);
    expect(grouped[0].windows[1].to).toBeNull();
    expect(grouped[1].windows).toHaveLength(1);
  });

  it('sắp theo thời gian dù log trả về lộn xộn', () => {
    const grouped = groupWindowsByTag([
      { tag: 'v2.0.0', versionId: 'c', from: d('2026-09-09T00:00:00Z'), to: null },
      { tag: 'v1.0.0', versionId: 'a', from: d('2026-09-01T00:00:00Z'), to: d('2026-09-09T00:00:00Z') },
    ]);

    expect(grouped.map(g => g.tag)).toEqual(['v1.0.0', 'v2.0.0']);
  });
});

describe('liveSeconds', () => {
  it('cộng dồn qua các đoạn và tính đoạn đang mở tới bây giờ', () => {
    const now = d('2026-09-09T00:00:00Z');
    const total = liveSeconds(
      [
        { from: d('2026-09-01T00:00:00Z'), to: d('2026-09-02T00:00:00Z') },
        { from: d('2026-09-08T00:00:00Z'), to: null },
      ],
      now,
    );

    expect(total).toBe(2 * 86400);
  });
});

describe('retentionCurve', () => {
  const lessons = [
    { lessonId: 'l1', keypointIds: ['k1', 'k2'] },
    { lessonId: 'l2', keypointIds: ['k3', 'k4'] },
  ];

  it('chia cho mẫu số cố định, không reset theo bài', () => {
    const curve = retentionCurve({
      lessons,
      // Card cuối của bài 1 là k2, của bài 2 là k4.
      completersByKeypoint: { k1: 90, k2: 80, k3: 50, k4: 40 },
      courseViewers: 100,
    });

    expect(curve).toEqual([
      { lessonIndex: 1, lessonId: 'l1', pct: 80 },
      { lessonIndex: 2, lessonId: 'l2', pct: 40 },
    ]);
  });

  it('chưa ai mở khoá thì ra 0 chứ không phải NaN', () => {
    const curve = retentionCurve({
      lessons,
      completersByKeypoint: {},
      courseViewers: 0,
    });

    expect(curve.every(p => p.pct === 0)).toBe(true);
  });

  it('bài rỗng không kéo cả đường về NaN', () => {
    const curve = retentionCurve({
      lessons: [{ lessonId: 'l0', keypointIds: [] }],
      completersByKeypoint: { k1: 10 },
      courseViewers: 100,
    });

    expect(curve[0].pct).toBe(0);
  });
});

describe('depthCurve', () => {
  it('là đúng trung bình theo người của tỉ lệ card đã đọc', () => {
    // 10 người mở bài; 10 người đọc card 1, 5 người đọc card 2.
    // Trung bình = (10 + 5) / (10 người × 2 card) = 75%.
    const curve = depthCurve({
      lessons: [{ lessonId: 'l1', keypointIds: ['k1', 'k2'] }],
      readersByKeypoint: { k1: 10, k2: 5 },
      openersByLesson: { l1: 10 },
    });

    expect(curve[0]).toEqual({
      lessonIndex: 1,
      lessonId: 'l1',
      pct: 75,
      openers: 10,
      cards: 2,
    });
  });

  it('bài chưa ai mở ra 0 và giữ nguyên trọng số 0', () => {
    const curve = depthCurve({
      lessons: [{ lessonId: 'l9', keypointIds: ['k9'] }],
      readersByKeypoint: {},
      openersByLesson: {},
    });

    expect(curve[0].pct).toBe(0);
    expect(curve[0].openers).toBe(0);
  });

  it('không đánh dấu bỏ dở cho bài chưa ai mở — 0% đó là không có dữ liệu', () => {
    const points = depthCurve({
      lessons: [
        { lessonId: 'l1', keypointIds: ['k1', 'k2'] },
        { lessonId: 'l2', keypointIds: ['k3', 'k4'] },
      ],
      readersByKeypoint: { k1: 10, k2: 1 },
      openersByLesson: { l1: 10 },
    });

    // Bài 1: (10+1)/(10×2) = 55% → trên ngưỡng. Bài 2: chưa ai mở.
    expect(points[0].pct).toBe(55);
    expect(dropOffLessons(points)).toEqual([]);
  });

  it('đánh dấu bài tụt dưới ngưỡng', () => {
    const points = depthCurve({
      lessons: [{ lessonId: 'l1', keypointIds: ['k1', 'k2', 'k3', 'k4'] }],
      readersByKeypoint: { k1: 10, k2: 2, k3: 1, k4: 1 },
      openersByLesson: { l1: 10 },
    });

    expect(points[0].pct).toBeLessThan(DROP_OFF_DEPTH_PCT);
    expect(dropOffLessons(points)).toEqual([1]);
  });
});

describe('rangeOf', () => {
  it('bỏ qua phiên bản chưa có số', () => {
    expect(rangeOf([55, null, 62, 48])).toEqual({ min: 48, max: 62 });
  });

  it('không có số nào thì không có khoảng nào', () => {
    expect(rangeOf([null, null])).toBeNull();
  });
});

describe('lessonShapesOf', () => {
  const lessons = [
    { _id: 'l1', keypoints: ['k1', 'k2'] },
    { _id: 'l2', keypoints: ['k3'] },
    { _id: 'l3', keypoints: ['k4', 'k5'] },
  ];

  it('đi theo thứ tự roadmap, không theo thứ tự trong snapshot', () => {
    const shapes = lessonShapesOf({
      roadmap: { levels: [{ nodes: [{ lessonIds: ['l3', 'l1'] }] }] },
      lessons,
    });

    expect(shapes.map(s => s.lessonId)).toEqual(['l3', 'l1', 'l2']);
    expect(shapes[0].keypointIds).toEqual(['k4', 'k5']);
  });

  it('bỏ qua id roadmap trỏ tới bài không có trong bản này', () => {
    const shapes = lessonShapesOf({
      roadmap: { levels: [{ nodes: [{ lessonIds: ['l9', 'l1'] }] }] },
      lessons: [{ _id: 'l1', keypoints: ['k1'] }],
    });

    expect(shapes.map(s => s.lessonId)).toEqual(['l1']);
  });

  it('không có roadmap thì vẫn giữ đủ bài theo thứ tự snapshot', () => {
    const shapes = lessonShapesOf({ roadmap: null, lessons });

    expect(shapes.map(s => s.lessonId)).toEqual(['l1', 'l2', 'l3']);
  });

  it('không nhân đôi bài bị roadmap tham chiếu hai lần', () => {
    const shapes = lessonShapesOf({
      roadmap: {
        levels: [{ nodes: [{ lessonIds: ['l1'] }, { lessonIds: ['l1'] }] }],
      },
      lessons: [{ _id: 'l1', keypoints: ['k1'] }],
    });

    expect(shapes).toHaveLength(1);
  });
});
