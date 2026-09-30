import {
  CoachMemoryStatus,
  CoachMemoryType,
  ICoachMemory,
} from './interface/memory.interface';
import {
  MEMORY_ACTIVE_EVIDENCE,
  MEMORY_CARD_EPISODES_LIMIT,
  MEMORY_CARD_GOALS_LIMIT,
  MEMORY_CARD_LINE_MAX_CHARS,
  MEMORY_CARD_MAX_CHARS,
  MEMORY_CARD_PATTERNS_LIMIT,
  MEMORY_CARD_PEOPLE_LIMIT,
  MEMORY_CARD_PROGRESS_LIMIT,
  MEMORY_FRESHNESS_HALF_LIFE_DAYS,
} from '../../shared/coach.constant';

/**
 * THẺ NHỚ — mọi thứ Coach nhớ về một người, trong một ngân sách cố định.
 *
 * Bản trước dựng khối nhớ lại mỗi lượt từ bốn query và trả về một chuỗi dài
 * theo số dòng tìm được; cộng thêm 30 dòng transcript thô, prompt lớn dần theo
 * lịch sử của người dùng. Thẻ này là câu trả lời cho đúng chỗ đó: **kích thước
 * của nó không phụ thuộc vào độ dài lịch sử** (`MEMORY_CARD_MAX_CHARS`), nên
 * một người dùng ba năm và một người dùng ba ngày tốn đúng bằng nhau.
 *
 * Không có call AI nào ở đây, và đó là điểm chính: `episodes.situation` và
 * `memories.content` do bước cô đọng viết ra đã là MỘT DÒNG cô đọng sẵn. Nén
 * chúng lần thứ hai chỉ để có một đoạn văn xuôi thì vừa mất chi tiết vừa trả
 * tiền cho provider hai lần.
 *
 * Hàm thuần, nên luật cắt được pin bằng spec mà không cần database — giống
 * `mergeMemory`.
 */

export interface MemoryCardSource {
  /** `profile` · `context` · `preference` · `habit` — thứ Coach học được, KHÔNG phải điều user tự khai ở onboarding. */
  people: Array<Pick<ICoachMemory, 'content' | 'status' | 'evidenceCount'>>;
  goals: Array<{ goal: string; progress?: number | null }>;
  episodes: Array<{
    situation: string;
    emotion?: string | null;
    insight?: string | null;
  }>;
  /** Việc họ đã LÀM được cho một mục tiêu — thứ duy nhất trên thẻ là thành tích. */
  progress: Array<{ goal: string; action: string; result?: string | null }>;
  patterns: Array<Pick<ICoachMemory, 'content' | 'status' | 'evidenceCount'>>;
}

/**
 * Điều user TỰ KHAI ở onboarding không vào thẻ: nó đã có khối `readerFacts`
 * riêng, với một đoạn luật riêng ("trả lời được khi user hỏi, không tự đem
 * ra"). Thẻ là điều Coach HỌC ĐƯỢC từ các cuộc nói chuyện — trộn hai nguồn vào
 * một khối là cách nhanh nhất để model nói "bạn từng kể" về một thứ user chỉ
 * chọn trong form.
 */
export function buildMemoryCard(source: MemoryCardSource): string | null {
  // Thứ tự các khối CŨNG là thứ tự ưu tiên khi tràn cap: khối cuối rụng trước.
  // Rụng từ dưới lên nghĩa là khi hết chỗ, thứ mất đi là phỏng đoán (pattern)
  // chứ không phải dữ kiện (họ là ai) — đúng chiều an toàn.
  const blocks: Array<{ head: string; lines: string[] }> = [
    {
      head: 'About them',
      lines: source.people
        .slice(0, MEMORY_CARD_PEOPLE_LIMIT)
        .map((row) => line(`${row.content}${hedge(row)}`)),
    },
    {
      head: 'Working toward',
      lines: source.goals
        .slice(0, MEMORY_CARD_GOALS_LIMIT)
        .map((row) =>
          line(`${row.goal}${row.progress ? ` (${row.progress}% along)` : ''}`),
        ),
    },
    {
      head: 'Recent moments they told you about',
      lines: source.episodes
        .slice(0, MEMORY_CARD_EPISODES_LIMIT)
        .map((row) =>
          line(
            [
              row.situation,
              row.emotion ? `— ${row.emotion}` : '',
              row.insight ? `— they concluded: ${row.insight}` : '',
            ]
              .filter(Boolean)
              .join(' '),
          ),
        ),
    },
    {
      head: 'Already acted on',
      lines: source.progress
        .slice(0, MEMORY_CARD_PROGRESS_LIMIT)
        .map((row) =>
          line(`${row.goal}: ${row.action}${row.result ? ` → ${row.result}` : ''}`),
        ),
    },
    {
      head: 'Might tend to (a possibility, never a verdict)',
      lines: source.patterns
        .filter((row) => row.evidenceCount >= MEMORY_ACTIVE_EVIDENCE)
        .slice(0, MEMORY_CARD_PATTERNS_LIMIT)
        .map((row) => line(`${row.content}${hedge(row)}`)),
    },
  ]
    .map((block) => ({
      ...block,
      lines: block.lines.filter((text) => text.trim().length > 0),
    }))
    .filter((block) => block.lines.length > 0);

  if (!blocks.length) return null;

  // Cắt từ cuối lên, từng DÒNG một, cho tới khi vừa cap. Bỏ cả khối một lúc sẽ
  // hay xoá mất ba dòng để tiết kiệm một dòng.
  while (render(blocks).length > MEMORY_CARD_MAX_CHARS) {
    const last = blocks[blocks.length - 1];
    last.lines.pop();
    if (!last.lines.length) blocks.pop();
    if (!blocks.length) return null;
  }

  return render(blocks);
}

function render(blocks: Array<{ head: string; lines: string[] }>): string {
  return blocks
    .map((block) => `${block.head}:\n${block.lines.map((l) => `- ${l}`).join('\n')}`)
    .join('\n');
}

/**
 * Bao nhiêu chắc chắn được nói ra cùng dòng chữ.
 *
 * "Memory không phải sự thật tuyệt đối" là luật của tầng này, và chỗ duy nhất
 * luật đó chạm tới model là mấy chữ này — một dòng `possible` không kèm dấu
 * ngoặc sẽ được đọc như một dữ kiện.
 */
function hedge(row: Pick<ICoachMemory, 'status' | 'evidenceCount'>): string {
  if (row.status === CoachMemoryStatus.POSSIBLE) return ' (possibly)';
  if (row.status === CoachMemoryStatus.IMPROVING) return ' (they are moving past this)';
  if (row.evidenceCount > 1) return ` (heard ${row.evidenceCount}×)`;

  return '';
}

function line(text: string): string {
  const clean = text.replace(/\s+/g, ' ').trim();
  if (clean.length <= MEMORY_CARD_LINE_MAX_CHARS) return clean;

  // Cắt ở ranh giới từ: một dòng đứt giữa từ đọc như dữ liệu lỗi, và model
  // thỉnh thoảng đoán nốt phần bị mất.
  const cut = clean.slice(0, MEMORY_CARD_LINE_MAX_CHARS);
  const lastSpace = cut.lastIndexOf(' ');

  return `${(lastSpace > MEMORY_CARD_LINE_MAX_CHARS / 2 ? cut.slice(0, lastSpace) : cut).trimEnd()}…`;
}

/**
 * Điểm hiệu dụng của một memory: chắc chắn, nhân với độ tươi.
 *
 * `findLiveForUser` cũ sort `confidence: -1`, nên một dòng đã leo tới 0.95 từ
 * tháng trước chiếm chỗ vĩnh viễn và thứ vừa nghe tuần này không bao giờ vào
 * nổi prompt. Nửa đời `MEMORY_FRESHNESS_HALF_LIFE_DAYS` ngày: sau hai tháng
 * không nhắc lại, một dòng chỉ còn một nửa trọng lượng — vẫn còn đó, chỉ là
 * không còn chen được lên trước chuyện đang xảy ra.
 */
export function freshnessScore(
  row: Pick<ICoachMemory, 'confidence' | 'lastSeen'>,
  now: Date = new Date(),
): number {
  const ageDays = Math.max(
    0,
    (now.getTime() - new Date(row.lastSeen ?? now).getTime()) / 86_400_000,
  );
  const confidence = Number.isFinite(row.confidence) ? row.confidence : 0;

  return confidence * Math.pow(0.5, ageDays / MEMORY_FRESHNESS_HALF_LIFE_DAYS);
}

/** Cùng một thứ tự cho cả việc chọn dòng vào thẻ và việc chọn dòng phải nghỉ. */
export function rankByFreshness<T extends Pick<ICoachMemory, 'confidence' | 'lastSeen'>>(
  rows: T[],
  now: Date = new Date(),
): T[] {
  return [...rows].sort((a, b) => freshnessScore(b, now) - freshnessScore(a, now));
}

/** Nhóm memory theo chỗ của nó trên thẻ. `pattern` là khối riêng vì nó là phỏng đoán. */
export function splitForCard<
  T extends Pick<ICoachMemory, 'type' | 'content' | 'status' | 'evidenceCount'>,
>(rows: T[]): { people: T[]; patterns: T[] } {
  return {
    people: rows.filter((row) => row.type !== CoachMemoryType.PATTERN),
    patterns: rows.filter((row) => row.type === CoachMemoryType.PATTERN),
  };
}
