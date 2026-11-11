import { Injectable } from '@nestjs/common';

import { CoachStatementKind } from './interface/reflection.interface';
import { CoachEvidenceRepository } from './repository/coach-evidence.repository';
import { CoachProblemStatementRepository } from './repository/coach-problem-statement.repository';
import { CoachSituationAnswerRepository } from './repository/coach-situation-answer.repository';

/**
 * The three things a session can leave behind, all of them the reader's own
 * words.
 *
 * Nothing the Coach said reaches this service. That is the whole boundary: if
 * a sentence was generated, it has no home here.
 */
@Injectable()
export class CoachReflectionService {
  constructor(
    private readonly evidenceRepository: CoachEvidenceRepository,
    private readonly problemStatementRepository: CoachProblemStatementRepository,
    private readonly situationAnswerRepository: CoachSituationAnswerRepository,
  ) {}

  /**
   * ⑤ "ĐỜI THẬT" — the only record that counts as having happened in the world.
   *
   * Written on exactly one transition: the reader answered "I did it" and then
   * told us what they said or did. Nothing else in this feature may write here.
   */
  async recordEvidence(params: {
    userId: string;
    planId: string;
    habitId?: string | null;
    content: string;
  }) {
    return this.evidenceRepository.create({
      userId: params.userId,
      planId: params.planId,
      habitId: params.habitId ?? null,
      content: params.content.trim(),
    });
  }

  /** ⑦ — "the real problem is …", written by the reader after the two columns. */
  async recordProblemStatement(params: {
    userId: string;
    sessionId: string;
    habitId?: string | null;
    content: string;
    kind?: CoachStatementKind;
    planId?: string | null;
    draftProposedCount?: number;
    draftKeptCount?: number;
  }) {
    return this.problemStatementRepository.create({
      userId: params.userId,
      sessionId: params.sessionId,
      habitId: params.habitId ?? null,
      content: params.content.trim(),
      kind: params.kind ?? CoachStatementKind.PROBLEM_STATEMENT,
      planId: params.planId ?? null,
      draftProposedCount: params.draftProposedCount ?? null,
      draftKeptCount: params.draftKeptCount ?? null,
    });
  }

  async recordSituationAnswer(params: {
    userId: string;
    sessionId: string;
    situationId: string;
    habitId?: string | null;
    variant: string;
    content: string;
    /** The scene's own question, as it was shown — see the schema. */
    promptSnapshot?: string | null;
    /** Which answer to this scene this is — 1 or 2 within one practice. */
    round?: number;
  }) {
    return this.situationAnswerRepository.create({
      userId: params.userId,
      sessionId: params.sessionId,
      situationId: params.situationId,
      habitId: params.habitId ?? null,
      variant: params.variant,
      content: params.content.trim(),
      promptSnapshot: params.promptSnapshot?.trim() || null,
      round: params.round ?? 1,
    });
  }

  async findEvidenceBetween(userId: string, from: Date, to: Date) {
    return this.evidenceRepository.findBetween(userId, from, to);
  }

  /** ⑤ "chữ của chính bạn" — the ⑦ sentence only, never a quick jot. */
  async findProblemStatementsBetween(userId: string, from: Date, to: Date) {
    return this.problemStatementRepository.findBetween(
      userId,
      from,
      to,
      CoachStatementKind.PROBLEM_STATEMENT,
    );
  }

  /**
   * "Có vấn đề lặp lại" — how many EARLIER sessions in the window told the
   * Coach something about this habit. The story conversation names a pattern
   * only from this number, never from the model's impression of one message.
   */
  async countSessionsAboutHabit(params: {
    userId: string;
    habitId: string;
    since: Date;
    exceptSessionId: string;
  }): Promise<number> {
    return this.problemStatementRepository.countSessionsAboutHabit({
      ...params,
      kinds: [CoachStatementKind.PROBLEM_STATEMENT, CoachStatementKind.QUICK_NOTE],
    });
  }

  /**
   * Habits the reader keeps stopping at — barrier rows per habit, most first.
   *
   * The first time these rows are READ by anything. They were written as "the
   * most valuable row in the feature" and then fed nothing; the course card
   * now uses them to point at the place the reader is actually stuck.
   */
  async countBarriersByHabit(userId: string) {
    return this.problemStatementRepository.countByHabit(
      userId,
      CoachStatementKind.BARRIER,
    );
  }

  async findAnswerPairs(userId: string) {
    return this.situationAnswerRepository.findAnswerPairs(userId);
  }

  /** Scenes this reader has answered, most recent first — the pool skips these. */
  async findAnsweredSituationIds(userId: string, habitId?: string | null) {
    return this.situationAnswerRepository.findAnsweredSituationIds(userId, habitId);
  }

  /** habitId → when it was last practised in the Coach. For "đến hạn nhất". */
  async latestPracticeByHabit(userId: string): Promise<Map<string, Date>> {
    return this.situationAnswerRepository.latestAnswerAtByHabit(userId);
  }

  /** ④ — a scene whose latest answer is at least `before` old, or null. */
  async findRetryCandidate(userId: string, before: Date) {
    return this.situationAnswerRepository.findRetryCandidate(userId, before);
  }

  /** The scene answered most recently — what "cảnh cũ" means when they ask. */
  async findLatestAnswered(userId: string, habitId?: string | null) {
    return this.situationAnswerRepository.findLatestAnswered(userId, habitId);
  }

  async countAnswersBetween(userId: string, from: Date, to: Date) {
    return this.situationAnswerRepository.countBetween(userId, from, to);
  }
}
