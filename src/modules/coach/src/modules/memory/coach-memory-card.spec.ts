import {
  buildMemoryCard,
  freshnessScore,
  MemoryCardSource,
  rankByFreshness,
  splitForCard,
} from './coach-memory-card';
import { CoachMemoryStatus, CoachMemoryType } from './interface/memory.interface';
import {
  MEMORY_CARD_MAX_CHARS,
  MEMORY_FRESHNESS_HALF_LIFE_DAYS,
} from '../../shared/coach.constant';

/**
 * Câu hỏi của owner (2026-09-17): "muốn coach luôn nhớ cảnh của user nhưng
 * phải rút gọn raw, không thì tràn context". Mấy test này pin đúng chỗ đó —
 * ngân sách của thẻ là một cap CỨNG, không phải một giới hạn số dòng, nên nó
 * không thể phình ra theo lịch sử dù dữ liệu vào có bao nhiêu.
 */
describe('buildMemoryCard', () => {
  const source: MemoryCardSource = {
    people: [
      {
        content: 'Làm marketing ở một công ty nhỏ',
        status: CoachMemoryStatus.ACTIVE,
        evidenceCount: 3,
      },
    ],
    goals: [{ goal: 'Nói ý kiến trong họp mà không sợ', progress: 40 }],
    episodes: [
      {
        situation: 'Họp thứ Ba bị trưởng phòng ngắt lời',
        emotion: 'bực',
        insight: 'lần sau nói ngay từ đầu',
      },
    ],
    progress: [
      { goal: 'Nói ý kiến trong họp', action: 'Nói trước hai câu ở họp thứ Năm', result: 'không ai ngắt' },
    ],
    patterns: [
      {
        content: 'Hay im lặng khi bị phản đối',
        status: CoachMemoryStatus.ACTIVE,
        evidenceCount: 2,
      },
    ],
  };

  it('không có gì thì trả null, chứ không phải chuỗi rỗng', () => {
    // Một chuỗi rỗng vẫn đi qua `?.trim()` của prompt và để lại một tiêu đề
    // khối trống trong prompt — phiên đầu tiên của một người không được mang
    // bóng của một phiên chưa từng có.
    expect(
      buildMemoryCard({ people: [], goals: [], episodes: [], progress: [], patterns: [] }),
    ).toBeNull();
  });

  it('dựng đủ bốn khối, cảnh user kể nằm trong đó', () => {
    const card = buildMemoryCard(source) as string;
    expect(card).toContain('About them');
    expect(card).toContain('Working toward');
    expect(card).toContain('Họp thứ Ba bị trưởng phòng ngắt lời');
    expect(card).toContain('they concluded: lần sau nói ngay từ đầu');
    expect(card).toContain('Might tend to');
    // Việc đã làm được là thứ duy nhất trên thẻ mang tính thành tích — bản
    // `contextFor` cũ có nó, nên thẻ không được đánh rơi.
    expect(card).toContain('Already acted on');
    expect(card).toContain('Nói trước hai câu ở họp thứ Năm → không ai ngắt');
  });

  it('pattern chỉ có một lần bằng chứng thì không lên thẻ', () => {
    const card = buildMemoryCard({
      ...source,
      patterns: [
        {
          content: 'Trì hoãn việc khó',
          status: CoachMemoryStatus.POSSIBLE,
          evidenceCount: 1,
        },
      ],
    }) as string;
    expect(card).not.toContain('Trì hoãn việc khó');
  });

  it('dòng phỏng đoán mang chữ rào, dòng đã nghe nhiều lần mang số lần', () => {
    const card = buildMemoryCard({
      people: [
        {
          content: 'Sống một mình',
          status: CoachMemoryStatus.POSSIBLE,
          evidenceCount: 1,
        },
      ],
      goals: [],
      episodes: [],
      progress: [],
      patterns: [],
    }) as string;
    expect(card).toContain('Sống một mình (possibly)');
    expect(buildMemoryCard(source) as string).toContain('(heard 3×)');
  });

  it('200 dòng vào thì thẻ vẫn ≤ cap, và cắt từ phỏng đoán trước', () => {
    const many = (n: number, text: string) =>
      Array.from({ length: n }, (_, i) => ({
        content: `${text} ${i} ${'x'.repeat(200)}`,
        status: CoachMemoryStatus.ACTIVE,
        evidenceCount: 5,
      }));
    const card = buildMemoryCard({
      people: many(100, 'người'),
      goals: Array.from({ length: 50 }, (_, i) => ({
        goal: `mục tiêu ${i} ${'y'.repeat(200)}`,
        progress: 10,
      })),
      episodes: Array.from({ length: 50 }, (_, i) => ({
        situation: `cảnh ${i} ${'z'.repeat(200)}`,
        emotion: 'lo',
        insight: null,
      })),
      progress: Array.from({ length: 20 }, (_, i) => ({
        goal: `mục tiêu ${i}`,
        action: `đã làm ${i} ${'w'.repeat(200)}`,
        result: '',
      })),
      patterns: many(50, 'hay'),
    }) as string;

    expect(card.length).toBeLessThanOrEqual(MEMORY_CARD_MAX_CHARS);
    // Dữ kiện giữ lại, phỏng đoán rụng — đúng chiều an toàn khi hết chỗ.
    expect(card).toContain('About them');
    expect(card).not.toContain('Might tend to');
  });

  it('dòng dài bị cắt ở ranh giới từ, không đứt giữa từ', () => {
    const card = buildMemoryCard({
      people: [
        {
          content: `${'từ '.repeat(80)}cuối`,
          status: CoachMemoryStatus.ACTIVE,
          evidenceCount: 1,
        },
      ],
      goals: [],
      episodes: [],
      progress: [],
      patterns: [],
    }) as string;
    expect(card).toContain('…');
    expect(card).not.toContain('t…');
  });
});

describe('freshnessScore', () => {
  const now = new Date('2026-09-17T00:00:00Z');

  it('một dòng không được nhắc lại đúng một nửa đời thì còn nửa trọng lượng', () => {
    const old = new Date(
      now.getTime() - MEMORY_FRESHNESS_HALF_LIFE_DAYS * 86_400_000,
    );
    expect(freshnessScore({ confidence: 0.8, lastSeen: old }, now)).toBeCloseTo(0.4, 5);
  });

  it('chuyện tuần này thắng chuyện tháng trước, dù tháng trước chắc hơn', () => {
    // Đây là lỗi của bản cũ: sort `confidence:-1` khiến một dòng 0.95 cũ chiếm
    // chỗ vĩnh viễn và thứ vừa nghe không bao giờ vào nổi prompt.
    const ranked = rankByFreshness(
      [
        {
          confidence: 0.95,
          lastSeen: new Date(now.getTime() - 300 * 86_400_000),
          content: 'cũ',
        },
        {
          confidence: 0.6,
          lastSeen: new Date(now.getTime() - 2 * 86_400_000),
          content: 'mới',
        },
      ],
      now,
    );
    expect(ranked[0].content).toBe('mới');
  });
});

describe('splitForCard', () => {
  it('tách pattern ra khỏi dữ kiện, vì hai khối nói bằng hai giọng khác nhau', () => {
    const { people, patterns } = splitForCard([
      {
        type: CoachMemoryType.PROFILE,
        content: 'Làm dev',
        status: CoachMemoryStatus.ACTIVE,
        evidenceCount: 1,
      },
      {
        type: CoachMemoryType.PATTERN,
        content: 'Hay nhận thêm việc',
        status: CoachMemoryStatus.ACTIVE,
        evidenceCount: 2,
      },
    ]);
    expect(people).toHaveLength(1);
    expect(patterns).toHaveLength(1);
  });
});
