import { Injectable, Logger } from '@nestjs/common';
import { Interval } from '@nestjs/schedule';

import { UserLessonRepository } from './repository/user-lesson.repository';
import { UserLesson } from './schema/user-lesson.schema';
import {
  GENERATION_STALE_MS,
  UserLessonCompletionService,
} from './user-lesson-completion.service';

const SWEEP_EVERY_MS = 2 * 60 * 1000;

/**
 * How many lessons one tick may pick up, per category.
 *
 * The sweep is a safety net, not a batch processor: in the normal case the
 * runner's own fire-and-forget finishes every lesson and this finds nothing.
 * A backlog only exists after a deploy killed runs mid-flight, and draining it
 * two-at-a-time keeps the Gemini and Edge-TTS load indistinguishable from
 * ordinary traffic.
 */
const MAX_PER_TICK = 2;

/**
 * The net under plans/260813-progressive-import: whatever the in-process
 * completion runs drop — deploy, crash, provider outage — this picks back up,
 * forever, on a per-lesson backoff.
 *
 * Scope is lessons with a `generation` record (the progressive pipeline's own),
 * which is enforced in the repository queries. Lessons that predate the
 * pipeline are deliberately untouched: leaving their audio as-is was an
 * explicit product decision (2026-08-13), not a gap.
 */
@Injectable()
export class UserLessonCompletionSweep {
  private readonly logger = new Logger(UserLessonCompletionSweep.name);

  /** Re-entrancy latch: a slow tick must not stack behind itself. */
  private running = false;

  constructor(
    private readonly userLessonRepository: UserLessonRepository,
    private readonly completionService: UserLessonCompletionService,
  ) {}

  @Interval(SWEEP_EVERY_MS)
  async sweep(): Promise<void> {
    if (this.running) return;
    this.running = true;

    try {
      const staleBefore = new Date(Date.now() - GENERATION_STALE_MS);

      const partial = await this.userLessonRepository.findStalledPartial(
        staleBefore,
        MAX_PER_TICK,
      );
      for (const lesson of partial.filter(candidate => this.due(candidate))) {
        this.logger.log(
          `Resuming content generation for lesson ${lesson._id} (attempt ${(lesson.generation?.attempts ?? 0) + 1})`,
        );
        await this.completionService.continueGeneration(String(lesson._id));
      }

      const silent = await this.userLessonRepository.findAudioIncomplete(
        staleBefore,
        MAX_PER_TICK,
      );
      for (const lesson of silent.filter(candidate => this.due(candidate))) {
        this.logger.log(
          `Topping up narration for lesson ${lesson._id} (attempt ${(lesson.generation?.attempts ?? 0) + 1})`,
        );
        await this.completionService.topUpAudio(String(lesson._id));
      }
    } catch (error: any) {
      this.logger.error(`Completion sweep failed: ${error?.message}`);
    } finally {
      this.running = false;
    }
  }

  /**
   * Per-lesson backoff: 1, 2, 4… minutes between runs, capped at 32.
   *
   * Grows so a lesson that fails against a downed provider does not burn a
   * Gemini call every two minutes all night, and CAPS (rather than giving up)
   * because eventual completeness is the whole promise — a lesson may not stay
   * partial, however long its source or the provider misbehaves.
   */
  private due(lesson: UserLesson): boolean {
    const attempts = lesson.generation?.attempts ?? 0;
    const lastAttemptAt = lesson.generation?.lastAttemptAt;
    if (!lastAttemptAt) return true;

    const backoffMs = Math.min(2 ** Math.max(0, attempts - 1), 32) * 60 * 1000;

    return Date.now() - new Date(lastAttemptAt).getTime() >= backoffMs;
  }
}
