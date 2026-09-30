import { mergeMemory } from './coach-memory-merge';
import {
  CoachMemoryStatus,
  CoachMemoryType,
  ICoachMemory,
} from './interface/memory.interface';

/**
 * The owner's rule in one sentence: "AI không được kết luận một pattern lâu
 * dài chỉ từ một câu nói." These pin the arithmetic that enforces it.
 */
describe('mergeMemory', () => {
  const now = new Date('2026-09-04T10:00:00Z');
  const known: ICoachMemory = {
    userId: 'u1',
    type: CoachMemoryType.PATTERN,
    content: 'Ngại đưa ra ý kiến trong meeting vì sợ bị đánh giá',
    confidence: 0.72,
    evidenceCount: 1,
    firstSeen: new Date('2026-09-01T10:00:00Z'),
    lastSeen: new Date('2026-09-01T10:00:00Z'),
    status: CoachMemoryStatus.POSSIBLE,
    sourceSessionIds: ['s1'],
  };

  it('a new pattern is only POSSIBLE, and never starts confident', () => {
    const row = mergeMemory(
      null,
      { type: CoachMemoryType.PATTERN, content: ' Ngại phát biểu ', confidence: 0.95 },
      's1',
      now,
    );
    expect(row.status).toBe(CoachMemoryStatus.POSSIBLE);
    expect(row.confidence).toBe(0.7);
    expect(row.evidenceCount).toBe(1);
    expect(row.content).toBe('Ngại phát biểu');
    expect(row.sourceSessionIds).toEqual(['s1']);
    expect(row.firstSeen).toBe(now);
  });

  it('a new profile fact is active at once — a job is not a diagnosis', () => {
    const row = mergeMemory(
      null,
      { type: CoachMemoryType.PROFILE, content: 'Làm marketing', confidence: 0.6 },
      's1',
      now,
    );
    expect(row.status).toBe(CoachMemoryStatus.ACTIVE);
    expect(row.confidence).toBe(0.6);
  });

  it('hearing it again reinforces the SAME row: evidence up, confidence up, and possible → active', () => {
    const row = mergeMemory(
      known,
      { id: 'm1', type: CoachMemoryType.PATTERN, content: known.content, confidence: 0.5 },
      's2',
      now,
    );
    expect(row.evidenceCount).toBe(2);
    expect(row.confidence).toBeCloseTo(0.82);
    expect(row.status).toBe(CoachMemoryStatus.ACTIVE);
    expect(row.sourceSessionIds).toEqual(['s1', 's2']);
    expect(row.lastSeen).toBe(now);
  });

  it('confidence never passes the ceiling, and a repeated session is not counted twice', () => {
    const row = mergeMemory(
      { ...known, confidence: 0.93, evidenceCount: 6, status: CoachMemoryStatus.ACTIVE },
      { id: 'm1', type: CoachMemoryType.PATTERN, content: known.content, confidence: 0.9 },
      's1',
      now,
    );
    expect(row.confidence).toBe(0.95);
    expect(row.sourceSessionIds).toEqual(['s1']);
  });

  it('the extraction may move a pattern to improving — behaviour changed', () => {
    const row = mergeMemory(
      { ...known, status: CoachMemoryStatus.ACTIVE, evidenceCount: 3 },
      {
        id: 'm1',
        type: CoachMemoryType.PATTERN,
        content: known.content,
        confidence: 0.8,
        status: CoachMemoryStatus.IMPROVING,
      },
      's5',
      now,
    );
    expect(row.status).toBe(CoachMemoryStatus.IMPROVING);
  });

  it('a garbage confidence falls to the floor rather than throwing', () => {
    const row = mergeMemory(
      null,
      { type: CoachMemoryType.CONTEXT, content: 'x', confidence: Number.NaN },
      's1',
      now,
    );
    expect(row.confidence).toBe(0.3);
  });
});
