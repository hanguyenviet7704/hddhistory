import {
  coachTimeLeftMs,
  detachedFromCoachDeadline,
  withCoachDeadline,
} from './coach-deadline';

/**
 * Ngân sách thời gian cho một request của Coach — thêm 2026-09-16.
 *
 * Lý do có file này: cái đắt nhất ở đây KHÔNG phải phép trừ, mà là hành vi của
 * `AsyncLocalStorage` với promise không ai await. Một lượt được cấp 20s có thể
 * châm ngòi hai việc cố ý chạy ngoài đồng hồ người đọc — viết quiz cho ngày mai
 * (được 40s của riêng nó) và trích trí nhớ sau khi câu trả lời đã gửi đi. Ngữ
 * cảnh async bám theo promise không await y hệt như promise có await, nên nếu
 * không tách ra thì cả hai thừa kế số mili-giây còn lại của lượt và bị cắt ngang
 * bởi một cái trần vốn không dành cho chúng.
 *
 * `tsc` và `nest build` đều không thấy được chuyện đó. Chỉ có test.
 */
describe('coach deadline', () => {
  it('ngoài mọi request thì trả null — "tự lo lấy timeout", không phải "hết giờ"', () => {
    expect(coachTimeLeftMs()).toBeNull();
  });

  it('trong ngân sách thì đếm ngược, không vượt quá ngân sách đã cấp', async () => {
    await withCoachDeadline(5_000, async () => {
      const left = coachTimeLeftMs();
      expect(left).not.toBeNull();
      expect(left as number).toBeGreaterThan(4_000);
      expect(left as number).toBeLessThanOrEqual(5_000);
    });
  });

  it('không bao giờ đi âm — hết giờ là 0', async () => {
    await withCoachDeadline(-1, async () => {
      expect(coachTimeLeftMs()).toBe(0);
    });
  });

  it('ngân sách theo kịp cả những lần await lồng sâu', async () => {
    await withCoachDeadline(5_000, async () => {
      await Promise.resolve();
      await new Promise(resolve => setImmediate(resolve));
      expect(coachTimeLeftMs()).not.toBeNull();
    });
  });

  it('BẪY: promise không await vẫn thừa kế ngân sách của lượt', async () => {
    let seen: number | null = -1;

    await withCoachDeadline(5_000, async () => {
      // Đúng hình dạng của `void this.memoryService.extractFromSession(...)`.
      void (async () => {
        seen = coachTimeLeftMs();
      })();
    });
    await new Promise(resolve => setImmediate(resolve));

    expect(seen).not.toBeNull();
  });

  it('tách ra thì việc nền chạy NGOÀI ngân sách, dù khởi động từ trong lượt', async () => {
    let seen: number | null = -1;

    await withCoachDeadline(5_000, async () => {
      detachedFromCoachDeadline(() => {
        void (async () => {
          seen = coachTimeLeftMs();
        })();
      });
    });
    await new Promise(resolve => setImmediate(resolve));

    expect(seen).toBeNull();
  });

  it('trả lại nguyên giá trị của hàm được tách — không nuốt promise', () => {
    const promise = detachedFromCoachDeadline(() => Promise.resolve(7));

    return expect(promise).resolves.toBe(7);
  });
});
