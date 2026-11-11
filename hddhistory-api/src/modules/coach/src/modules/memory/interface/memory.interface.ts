/**
 * The Coach's memory of a reader (owner's doc "Context & User Memory
 * Architecture", 2026-09-04).
 *
 * Four layers, four collections: RAW (`coach_messages`, every line, never
 * summarised away), MEMORY (`coach_memories`, what the raw lines add up to
 * about the person), GOALS / EPISODES / PROGRESS (what they are working toward,
 * what happened, how it moved). Raw is the source of truth; memory is
 * compressed knowledge; retrieval picks what fits the current story.
 */

export enum CoachMemoryType {
  PROFILE = 'profile',
  PREFERENCE = 'preference',
  GOAL = 'goal',
  HABIT = 'habit',
  PATTERN = 'pattern',
  CONTEXT = 'context',
}

/**
 * A memory is never a fact. `possible` is what one conversation earns — a
 * pattern seen once is a possibility, not a trait; it becomes `active` only
 * with evidence. `improving` marks a pattern the reader is visibly moving
 * past; `inactive` retires one that stopped mattering.
 */
export enum CoachMemoryStatus {
  POSSIBLE = 'possible',
  ACTIVE = 'active',
  IMPROVING = 'improving',
  INACTIVE = 'inactive',
}

export enum CoachGoalStatus {
  ACTIVE = 'active',
  DONE = 'done',
  DROPPED = 'dropped',
}

export interface ICoachMessage {
  userId: string;
  sessionId: string;
  entry: string;
  role: 'user' | 'coach';
  step: string;
  content: string;
}

export interface ICoachMemory {
  userId: string;
  type: CoachMemoryType;
  content: string;
  /** 0–1. New memories cap below 0.7; each reinforcement adds a step. */
  confidence: number;
  evidenceCount: number;
  firstSeen: Date;
  lastSeen: Date;
  status: CoachMemoryStatus;
  sourceSessionIds: string[];
}

export interface ICoachGoal {
  userId: string;
  goal: string;
  status: CoachGoalStatus;
  priority: number;
  /** 0–100, the extraction's read of how far along it is. */
  progress: number;
  sourceSessionIds: string[];
}

export interface ICoachEpisode {
  userId: string;
  sessionId: string;
  situation: string;
  emotion?: string | null;
  insight?: string | null;
}

export interface ICoachProgress {
  userId: string;
  sessionId: string;
  goal: string;
  action: string;
  result: string;
}

/**
 * Thẻ nhớ — bản dựng sẵn của MEMORY, cộng câu chào cho lần mở phiên sau.
 *
 * Tầng thứ năm, và là tầng duy nhất được đọc ở đường nóng: bốn tầng kia là
 * nguồn, thẻ là thứ đi vào prompt. Kích thước của nó bị chặn cứng, nên prompt
 * không lớn theo lịch sử — xem `buildMemoryCard`.
 */
export interface ICoachMemoryCard {
  userId: string;
  card?: string | null;
  greetingTopic?: string | null;
  greetingLocale?: string | null;
  greetingUsedAt?: Date | null;
  builtAt?: Date | null;
  builtFromSessionId?: string | null;
}
