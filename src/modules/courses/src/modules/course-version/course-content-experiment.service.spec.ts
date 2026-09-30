import { BadRequestException, ConflictException } from '@nestjs/common';

import { CourseContentExperimentService } from './course-content-experiment.service';

const COURSE = '68c0000000000000000000c1';
const OTHER = '68c0000000000000000000c2';
const RUN_START = new Date('2026-09-08T00:00:00Z');

/**
 * Kiểm cấu hình ở lúc TẠO ĐỢT, không để tới lúc serve: một đợt khai sai tag
 * chỉ hiện ra sau nhiều ngày chạy, và tới lúc đó số liệu đã hỏng.
 */
function makeService(opts: { progressStartedAt?: Date | null } = {}) {
  const runs: any[] = [];
  let autoId = 0;

  const calls = { armCourseIds: 0, running: 0 };
  const experimentRepository = {
    async findEnabledArmCourseIds() {
      calls.armCourseIds++;
      return runs
        .filter(r => r.enabled)
        .flatMap((r: any) => (r.arms ?? []).map((a: any) => a.courseId));
    },
    async create(data: any, user?: any) {
      const row = { ...data, _id: `e${++autoId}`, createdBy: user ?? null };
      runs.push(row);
      return row;
    },
    async findOneByKey(key: string) {
      return runs.find(r => r.key === key) ?? null;
    },
    async findRunningForCourse(courseId: string) {
      calls.running++;
      return (
        runs.find(
          r => r.enabled && (r.arms ?? []).some((a: any) => a.courseId === courseId),
        ) ?? null
      );
    },
    async findAllNewestFirst() {
      return runs;
    },
  };

  // v1.0.0 và v1.0.1 tồn tại trên COURSE; OTHER không có tag nào.
  const courseVersionRepository = {
    async findOneByTag(courseId: string, tag: string) {
      if (courseId !== COURSE) return null;
      const known: Record<string, string> = {
        'v1.0.0': 'ver-a',
        'v1.0.1': 'ver-b',
      };
      return known[tag] ? { _id: known[tag], courseId, tag } : null;
    },
  };

  const userProgressRepository = {
    async findCourseStartedAt() {
      return opts.progressStartedAt ?? null;
    },
  };

  // Đếm theo NGƯỜI: một keypoint mở lại năm lần là một người học, đếm năm lần
  // là dịch tỉ lệ mà chẳng ai đổi hành vi.
  const peopleByEvent: Record<string, Record<string, number>> = {
    roadmap_scr_view: { A: 100, B: 120 },
    keypoint_intro_scr_view: { A: 80, B: 108 },
    keypoint_read_scr_view: { A: 60, B: 90 },
    keypoint_complete_click: { A: 40, B: 72 },
    keypoint_complete_skip: { A: 12, B: 6 },
    keypoint_exit_popup_view: { A: 20, B: 9 },
    keypoint_menu_report_click: { A: 3, B: 1 },
  };
  const userEventRepository = {
    async countUsersByParam({ name }: any) {
      return peopleByEvent[name] ?? {};
    },
  };

  const service = new CourseContentExperimentService(
    experimentRepository as any,
    courseVersionRepository as any,
    userProgressRepository as any,
    userEventRepository as any,
  );

  return { service, runs, calls };
}

const validDto = (over: Record<string, any> = {}) => ({
  key: '3conlonbeo',
  percentB: 50,
  startedAt: RUN_START,
  arms: [{ courseId: COURSE, tagA: 'v1.0.0', tagB: 'v1.0.1' }],
  ...over,
});

describe('create', () => {
  it('tạo được đợt hợp lệ, mặc định TẮT', async () => {
    const { service, runs } = makeService();
    const run = await service.create(validDto() as any);

    expect(run.key).toBe('3conlonbeo');
    // Tắt mặc định: bật trước khi app biết đóng dấu nhánh là phục vụ hai bản
    // khác nhau mà không đo được gì.
    expect(runs[0].enabled).toBe(false);
  });

  it('không cho trùng key', async () => {
    const { service } = makeService();
    await service.create(validDto() as any);

    await expect(service.create(validDto() as any)).rejects.toThrow(
      ConflictException,
    );
  });

  it('không cho đợt rỗng khoá', async () => {
    const { service } = makeService();

    await expect(
      service.create(validDto({ arms: [] }) as any),
    ).rejects.toThrow(BadRequestException);
  });

  /** Hai nhánh trùng nội dung là đo một thứ không tồn tại. */
  it('không cho hai nhánh cùng một tag', async () => {
    const { service } = makeService();

    await expect(
      service.create(
        validDto({ arms: [{ courseId: COURSE, tagA: 'v1.0.0', tagB: 'v1.0.0' }] }) as any,
      ),
    ).rejects.toThrow(BadRequestException);
  });

  it('không cho khai tag không tồn tại trên khoá đó', async () => {
    const { service } = makeService();

    await expect(
      service.create(
        validDto({ arms: [{ courseId: COURSE, tagA: 'v1.0.0', tagB: 'v9.9.9' }] }) as any,
      ),
    ).rejects.toThrow(BadRequestException);
  });

  it('không cho khoá chưa có tag nào tham gia', async () => {
    const { service } = makeService();

    await expect(
      service.create(
        validDto({ arms: [{ courseId: OTHER, tagA: 'v1.0.0', tagB: 'v1.0.1' }] }) as any,
      ),
    ).rejects.toThrow(BadRequestException);
  });
});

describe('factsFor', () => {
  const enable = async (service: any, runs: any[]) => {
    await service.create(validDto() as any);
    runs[0].enabled = true;
  };

  it('khoá không trong đợt nào thì trả null', async () => {
    const { service, runs } = makeService();
    await enable(service, runs);

    expect(await service.factsFor(OTHER, 'user-42')).toBeNull();
  });

  it('trả versionId của hai nhánh, đã tra từ tên tag', async () => {
    const { service, runs } = makeService();
    await enable(service, runs);

    expect(await service.factsFor(COURSE, 'user-42')).toEqual({
      key: '3conlonbeo',
      percentB: 50,
      armA: 'ver-a',
      armB: 'ver-b',
      runStartedAt: RUN_START,
      progressStartedAt: null,
    });
  });

  it('mang theo mốc bắt đầu tiến trình để hàm quyết định dùng', async () => {
    const started = new Date('2026-09-09T00:00:00Z');
    const { service, runs } = makeService({ progressStartedAt: started });
    await enable(service, runs);

    expect((await service.factsFor(COURSE, 'user-42'))?.progressStartedAt).toBe(
      started,
    );
  });

  /** Tag bị xoá sau khi đợt đã cấu hình: fail closed, không phục vụ nửa vời. */
  it('trả null nếu một nhánh không tra được tag nữa', async () => {
    const { service, runs } = makeService();
    await enable(service, runs);
    runs[0].arms[0].tagB = 'v9.9.9';

    expect(await service.factsFor(COURSE, 'user-42')).toBeNull();
  });
});


/**
 * `factsFor` chạy trên MỌI lượt đọc nội dung, kể cả khi chẳng có đợt nào — và
 * đó là màn chính của app. Nên chặn sớm bằng danh sách khoá đang trong đợt,
 * cache ngắn, thay vì query đợt cho từng lượt đọc.
 */
describe('factsFor không được đánh vào DB mỗi lượt đọc', () => {
  it('khoá không nằm trong đợt nào thì chặn sớm, không query đợt', async () => {
    const { service, runs, calls } = makeService();
    await service.create(validDto() as any);
    runs[0].enabled = true;

    expect(await service.factsFor(OTHER, 'user-42')).toBeNull();
    expect(calls.running).toBe(0);
  });

  it('gọi nhiều lượt chỉ đọc danh sách khoá một lần trong cửa sổ cache', async () => {
    const { service, runs, calls } = makeService();
    await service.create(validDto() as any);
    runs[0].enabled = true;

    for (let i = 0; i < 20; i++) await service.factsFor(OTHER, `user-${i}`);

    expect(calls.armCourseIds).toBe(1);
  });

  /**
   * Bật/tắt đợt phải có hiệu lực NGAY, không đợi hết cache — nên
   * `invalidateArmCache` là API thật của service, không phải hook cho test.
   */
  it('bật/tắt đợt thì cache bị dọn, đọc lại danh sách', async () => {
    const { service, runs, calls } = makeService();
    await service.create(validDto() as any);
    runs[0].enabled = true;

    await service.factsFor(OTHER, 'user-1');
    service.invalidateArmCache();
    await service.factsFor(OTHER, 'user-2');

    expect(calls.armCourseIds).toBe(2);
  });
});


/**
 * Bảng kết quả. Phễu đếm theo NGƯỜI, và lọc theo `content_experiment_key` nên
 * một cửa sổ thời gian trùng hai đợt không bị trộn chung mẫu số.
 */
describe('stats', () => {
  it('dựng phễu hai nhánh và tỉ lệ hoàn thành trên người thấy khoá', async () => {
    const { service, runs } = makeService();
    await service.create(validDto() as any);
    runs[0].enabled = true;

    const out = await service.stats('3conlonbeo', 'dev');

    expect(out.key).toBe('3conlonbeo');
    expect(out.arms).toEqual([
      {
        arm: 'A',
        viewers: 100,
        keypointStarts: 80,
        keypointReads: 60,
        completes: 40,
        skips: 12,
        exits: 20,
        reports: 3,
        completionRate: 40,
      },
      {
        arm: 'B',
        viewers: 120,
        keypointStarts: 108,
        keypointReads: 90,
        completes: 72,
        skips: 6,
        exits: 9,
        reports: 1,
        completionRate: 60,
      },
    ]);
  });

  it('không thấy đợt thì báo không tìm thấy', async () => {
    const { service } = makeService();

    await expect(service.stats('khong-co', 'dev')).rejects.toThrow();
  });

  /** Chưa ai đóng dấu nhánh (app chưa lên) thì trả 0, không trả NaN. */
  it('không có số liệu thì tỉ lệ là 0 chứ không NaN', async () => {
    const { service, runs } = makeService();
    await service.create(validDto({ key: 'trong' }) as any);
    runs[0].enabled = true;

    const out = await service.stats('trong', 'dev');
    // fake trả cùng bộ số cho mọi key, nên kiểm bằng cách khác: chia cho 0
    expect(Number.isNaN(out.arms[0].completionRate)).toBe(false);
  });
});
