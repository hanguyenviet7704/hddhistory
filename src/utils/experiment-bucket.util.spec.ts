import { experimentBucket } from './experiment-bucket.util';

/**
 * Chia nhánh A/B. Dùng chung cho A/B thân paywall và A/B nội dung khoá học —
 * một hàm băm chứ không phải một framework, nhưng phải là MỘT bản: hai bản
 * copy lệch nhau sẽ làm một trong hai đợt test bị lệch nhánh mà nhìn màn hình
 * cấu hình vẫn thấy đúng.
 */
describe('experimentBucket', () => {
  it('luôn trả 0..99', () => {
    for (let i = 0; i < 200; i++) {
      const bucket = experimentBucket('run', `user-${i}`);
      expect(bucket).toBeGreaterThanOrEqual(0);
      expect(bucket).toBeLessThan(100);
      expect(Number.isInteger(bucket)).toBe(true);
    }
  });

  it('ổn định cho cùng một người trong cùng một đợt', () => {
    expect(experimentBucket('run-1', 'user-42')).toBe(
      experimentBucket('run-1', 'user-42'),
    );
  });

  /**
   * Vì sao `key` PHẢI đổi mỗi đợt: cùng key là trả mọi người về đúng nhánh cũ,
   * biến đợt mới thành phần tiếp của đợt cũ.
   */
  it('đổi key thì đổi cách chia', () => {
    const before = Array.from({ length: 200 }, (_, i) =>
      experimentBucket('run-1', `user-${i}`),
    );
    const after = Array.from({ length: 200 }, (_, i) =>
      experimentBucket('run-2', `user-${i}`),
    );

    const moved = before.filter((b, i) => b !== after[i]).length;
    expect(moved).toBeGreaterThan(150);
  });

  /**
   * Hai nhánh phải đúng CỠ như tỉ lệ đã cấu hình, không chỉ "đều đặn": băm yếu
   * trên id tăng dần sẽ lệch, và một tỉ lệ lệch là thí nghiệm thiên vị.
   */
  it('chia đúng cỡ tỉ lệ trên id tăng dần', () => {
    const ids = Array.from({ length: 4000 }, (_, i) => `68b0000000000000000${i}`);
    const inB = ids.filter(id => experimentBucket('run-1', id) < 50).length;

    expect(inB / ids.length).toBeGreaterThan(0.46);
    expect(inB / ids.length).toBeLessThan(0.54);
  });
});
