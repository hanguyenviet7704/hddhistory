import { Injectable } from '@nestjs/common';

import { ICoachProfile } from './interface/profile.interface';
import { CoachProfileRepository } from './repository/coach-profile.repository';
import {
  EXIT_PLEA_OFF_AFTER,
  ONBOARD_VERSION,
} from '../../shared/coach.constant';
import { CoachPersona } from '../../shared/coach.enum';

@Injectable()
export class CoachProfileService {
  constructor(private readonly repository: CoachProfileRepository) {}

  async get(userId: string): Promise<ICoachProfile> {
    const doc = await this.repository.findByUser(userId);

    return {
      userId,
      lastPersona: doc?.lastPersona ?? null,
      ratingSkipCount: doc?.ratingSkipCount ?? 0,
      ratingHidden: doc?.ratingHidden ?? false,
      ratingAskedAt: doc?.ratingAskedAt ?? null,
      ratingSnoozedAt: doc?.ratingSnoozedAt ?? null,
      ratingAskCount: doc?.ratingAskCount ?? 0,
      exitCount: doc?.exitCount ?? 0,
      exitDeclinedStreak: doc?.exitDeclinedStreak ?? 0,
      exitFeedbackGiven: doc?.exitFeedbackGiven ?? false,
      exitFeedbackSkips: doc?.exitFeedbackSkips ?? 0,
      address: doc?.address ?? null,
      goalText: doc?.goalText ?? null,
      barrierText: doc?.barrierText ?? null,
      currentPractice: doc?.currentPractice ?? null,
      learningStyle: doc?.learningStyle ?? null,
      occupation: doc?.occupation ?? null,
      occupationRaw: doc?.occupationRaw ?? null,
      onboardedAt: doc?.onboardedAt ?? null,
      onboardVersion: doc?.onboardVersion ?? null,
    };
  }

  /**
   * Luồng 1 — the onboarding's answers, written as one row the moment it ends
   * (finished or skipped). `onboardedAt` is what keeps it to once per reader:
   * "chạy đúng một lần đời user, trước MOOD của phiên đầu tiên".
   */
  async completeOnboarding(
    userId: string,
    answers: Partial<
      Pick<
        ICoachProfile,
        | 'address'
        | 'goalText'
        | 'barrierText'
        | 'currentPractice'
        | 'learningStyle'
        | 'occupation'
        | 'occupationRaw'
      >
    >,
  ): Promise<void> {
    const set: Record<string, unknown> = { onboardedAt: new Date(), onboardVersion: ONBOARD_VERSION };
    for (const [key, value] of Object.entries(answers)) {
      if (value !== undefined && value !== null && String(value).trim()) set[key] = value;
    }
    await this.repository.upsertForUser(userId, { $set: set });
  }

  /**
   * Luồng 6 — the plea was shown and the reader answered it. Staying (or a
   * session that runs to its end — see `resetExitStreak`) breaks the run;
   * closing anyway lengthens it, and at `EXIT_PLEA_OFF_AFTER` the plea is
   * retired for this reader: "đủ 2 phiên liền thì tắt hẳn luồng 6".
   */
  async recordExit(
    userId: string,
    stayed: boolean,
  ): Promise<{ exitPlea: boolean }> {
    const current = (await this.repository.findByUser(userId))?.exitDeclinedStreak ?? 0;
    const next = stayed ? 0 : current + 1;
    await this.repository.upsertForUser(userId, {
      $set: { exitDeclinedStreak: next },
    });

    return { exitPlea: next < EXIT_PLEA_OFF_AFTER };
  }

  /** "Đừng xưng anh nữa" — the reader changed how they want to be called, mid-talk. */
  async setAddress(userId: string, address: string): Promise<void> {
    await this.repository.upsertForUser(userId, { $set: { address } });
  }

  async resetExitStreak(userId: string): Promise<void> {
    await this.repository.upsertForUser(userId, {
      $set: { exitDeclinedStreak: 0 },
    });
  }

  /** Whether the close button may plead at all for this reader. */
  async exitPleaEnabled(userId: string): Promise<boolean> {
    const streak = (await this.repository.findByUser(userId))?.exitDeclinedStreak ?? 0;

    return streak < EXIT_PLEA_OFF_AFTER;
  }

  /** Pre-lights the persona picker. The reader still taps — it is never applied for them. */
  async rememberPersona(userId: string, persona: CoachPersona) {
    return this.repository.upsertForUser(userId, {
      $set: { lastPersona: persona },
    });
  }

  /**
   * The rating sheet was shown and the reader dealt with it.
   *
   * Two different clocks on purpose: somebody who ANSWERED has told us what
   * they think and can be left alone for a long while, while somebody who chose
   * ⟨Để sau⟩ has told us only that this was a bad moment. `ratingAskCount`
   * counts both — the ceiling is about how often we interrupt, not about how
   * often we get an answer.
   */
  async recordRatingAsk(userId: string, answered: boolean): Promise<void> {
    const now = new Date();
    const current = (await this.repository.findByUser(userId))?.ratingAskCount ?? 0;

    await this.repository.upsertForUser(userId, {
      $set: {
        ratingAskCount: current + 1,
        ...(answered ? { ratingAskedAt: now } : { ratingSnoozedAt: now }),
      },
    });
  }
}
