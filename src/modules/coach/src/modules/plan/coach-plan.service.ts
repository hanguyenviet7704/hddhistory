import { Injectable } from '@nestjs/common';

import {
  CoachPlanAnswer,
  CoachPlanSource,
  CoachPlanStatus,
  CoachReminderDays,
} from './enum/plan.enum';
import { CoachPlanRepository } from './repository/coach-plan.repository';
import { CoachPlan } from './schema/coach-plan.schema';
import { NO_OCCASION_SLEEP_LIMIT } from '../../shared/coach.constant';

@Injectable()
export class CoachPlanService {
  constructor(private readonly repository: CoachPlanRepository) {}

  async findPending(userId: string, limit?: number) {
    return this.repository.findPending(userId, limit);
  }

  async countPending(userId: string): Promise<number> {
    return this.repository.countPending(userId);
  }

  async findById(id: string) {
    return this.repository.findById(id);
  }

  /**
   * A new commitment, in the reader's own words.
   *
   * `context` and `action` are stored exactly as typed — no trimming beyond
   * whitespace, no capitalisation, no rewriting. The ④ push quotes them back
   * verbatim and the whole mechanism rests on the reader recognising their own
   * sentence.
   *
   * Creating one for a habit closes any older pending commitment on the same
   * habit: two live promises about the same thing is a backlog, and the newer
   * one is the one they just made.
   */
  async create(params: {
    userId: string;
    context: string;
    action: string;
    source: CoachPlanSource;
    habitId?: string | null;
  }): Promise<CoachPlan> {
    const { userId, context, action, source, habitId } = params;

    const created = await this.repository.create({
      userId,
      context: context.trim(),
      action: action.trim(),
      source,
      habitId: habitId ?? null,
      status: CoachPlanStatus.PENDING,
      consecutiveNoOccasion: 0,
    });

    if (habitId) {
      await this.repository.replacePendingForHabit(
        userId,
        habitId,
        created._id.toString(),
      );
    }

    return created;
  }

  /**
   * File what the reader answered when asked back.
   *
   * Three consecutive "no occasion" answers put the plan to sleep — the context
   * is not appearing and continuing to ask turns a reminder into nagging.
   * "Missed it" resets the counter exactly as "did it" does, because the
   * occasion DID arrive: the commitment is still live, and the design is
   * explicit that not taking it is not a failure.
   */
  async recordAnswer(
    planId: string,
    answer: CoachPlanAnswer,
  ): Promise<{ slept: boolean }> {
    const plan = await this.repository.findById(planId);
    if (!plan) return { slept: false };

    const nextCount =
      answer === CoachPlanAnswer.NONE ? plan.consecutiveNoOccasion + 1 : 0;

    const slept = nextCount >= NO_OCCASION_SLEEP_LIMIT;

    await this.repository.updateOne(
      { _id: planId },
      {
        lastAskedAt: new Date(),
        lastAnswer: answer,
        consecutiveNoOccasion: nextCount,
        ...(slept ? { status: CoachPlanStatus.SLEEPING } : {}),
        // Acting on it closes the commitment: the evidence row is the record
        // that it happened, and asking again next week would be asking about
        // something already done.
        ...(answer === CoachPlanAnswer.DONE
          ? { status: CoachPlanStatus.DONE }
          : {}),
      } as Partial<CoachPlan>,
    );

    return { slept };
  }

  async setReminder(
    planId: string,
    reminder: {
      enabled: boolean;
      hour?: number;
      minute?: number;
      days?: CoachReminderDays;
      customDays?: number[];
      /** "Chỉ một lần" — the reader-local date, YYYY-MM-DD. */
      onceDate?: string | null;
    },
  ) {
    return this.repository.updateOne({ _id: planId }, {
      reminder: {
        enabled: reminder.enabled,
        hour: reminder.hour ?? 20,
        minute: reminder.minute ?? 0,
        days: reminder.days ?? CoachReminderDays.DAILY,
        customDays:
          reminder.days === CoachReminderDays.CUSTOM
            ? [...new Set((reminder.customDays ?? []).filter((d) => d >= 1 && d <= 7))]
            : [],
        onceDate:
          reminder.days === CoachReminderDays.ONCE
            ? (reminder.onceDate ?? null)
            : null,
      },
    } as Partial<CoachPlan>);
  }

  /**
   * ②A "Có dịp mà chưa làm" → the commitment is too big or its context is
   * wrong, and the reader took the smaller version.
   *
   * The old plan is REPLACED, not deleted — it stays in the habit's history —
   * and the new one inherits the reminder, since the reader set that time for
   * this habit rather than for a particular wording of the promise.
   */
  async shrink(
    oldPlanId: string,
    next: { context: string; action: string },
  ): Promise<CoachPlan | null> {
    const old = await this.repository.findById(oldPlanId);
    if (!old) return null;

    const created = await this.repository.create({
      userId: old.userId,
      context: next.context.trim(),
      action: next.action.trim(),
      source: CoachPlanSource.SHRINK,
      habitId: old.habitId ?? null,
      status: CoachPlanStatus.PENDING,
      consecutiveNoOccasion: 0,
      reminder: old.reminder,
    });

    await this.repository.updateOne(
      { _id: oldPlanId },
      { status: CoachPlanStatus.REPLACED } as Partial<CoachPlan>,
    );

    return created;
  }

  /**
   * ②A "Chưa gặp dịp" → "Đổi bối cảnh": the promise stands, the setting moves.
   *
   * An edit, not a new plan: nothing about the commitment was wrong except
   * where it was waiting to happen, and a new row would restart the
   * "asked back about" history for no reason.
   */
  async updateContext(planId: string, context: string) {
    return this.repository.updateOne(
      { _id: planId },
      { context: context.trim() } as Partial<CoachPlan>,
    );
  }

  async markNotified(planIds: string[]) {
    if (!planIds.length) return;

    await this.repository.updateMany(
      { _id: { $in: planIds } },
      { lastNotifiedAt: new Date() } as Partial<CoachPlan>,
    );
  }

  async findAnsweredBetween(userId: string, from: Date, to: Date) {
    return this.repository.findAnsweredBetween(userId, from, to);
  }
}
