import { Logger } from '@nestjs/common';

import {
  buildSectionNarrationScripts,
  stripHtml,
} from './user-lesson-narration.util';
import { sanitizeForNarration } from '../../voiceover/narration-text.util';
import { TtsService } from '../../voiceover/tts.service';
import { ILessonSection } from '../interface/learning-import.interface';
import {
  capitalizeFirstLetter,
  normalizeSections,
} from '../learning-import.util';

/**
 * How many clips synthesize at once inside ONE prefetcher.
 *
 * Below the dub run's own 4: prefetch overlaps a live generation stream and a
 * chained dub run on the same process, and the Edge endpoint punishes bursts.
 */
const PREFETCH_CONCURRENCY = 3;

/**
 * Starts a card's narration the moment its text exists in the generation
 * stream, so that by the time the KEYPOINT closes its clips are already made —
 * "text done" and "audio done" land together instead of half a minute apart
 * (user requirement, 2026-08-13: a finished keypoint must have its voice).
 *
 * The cache key is the SANITIZED NARRATION SCRIPT — the exact string the dub
 * run derives from the stored keypoint — built here through the same
 * normalize → script → sanitize pipeline. Keying by anything positional
 * (keypoint index, card index) would break the moment normalization drops an
 * empty card and shifts everything after it.
 *
 * A failed prefetch resolves null and costs nothing: the dub run falls back to
 * its own synthesis, retries included. This class only ever SAVES time.
 */
export class UserLessonClipPrefetcher {
  private readonly logger = new Logger(UserLessonClipPrefetcher.name);

  private readonly clips = new Map<string, Promise<Buffer | null>>();
  private inFlight = 0;
  private readonly queue: (() => void)[] = [];

  constructor(
    private readonly ttsService: TtsService,
    private readonly lang: string,
    /** Resolved ONCE by the creator, so prefetched and fallback clips can
     *  never be spoken by two different narrators. */
    readonly voice: string,
  ) {}

  /** Queue a streamed card's narration, normalized exactly as it will be stored. */
  ensureSection(section: ILessonSection): void {
    const normalized = normalizeSections([section]);
    if (normalized.length === 0) return;

    const script = sanitizeForNarration(
      buildSectionNarrationScripts(normalized)[0] ?? '',
    );
    this.ensure(script);
  }

  /** Queue a takeaway's narration, through the same stored-shape transforms. */
  ensureTakeaway(takeaway: string): void {
    const stored = capitalizeFirstLetter((takeaway ?? '').trim());
    if (!stored) return;

    this.ensure(sanitizeForNarration(stripHtml(stored)));
  }

  /**
   * The clip for [script], if this prefetcher ever started one — otherwise
   * null immediately, and the caller synthesizes for itself.
   */
  take(script: string): Promise<Buffer | null> {
    return this.clips.get(script) ?? Promise.resolve(null);
  }

  private ensure(script: string): void {
    if (!script || this.clips.has(script)) return;

    this.clips.set(
      script,
      this.throttled(async () => {
        try {
          return await this.ttsService.synthesizeMp3(
            script,
            this.lang,
            undefined,
            this.voice,
          );
        } catch (error: any) {
          // Quietly: the dub run will retry this exact script itself.
          this.logger.warn(
            `Prefetch synthesis failed (falls back to dub-time): ${error?.message}`,
          );

          return null;
        }
      }),
    );
  }

  /** Simple semaphore: at most [PREFETCH_CONCURRENCY] synths in flight. */
  private async throttled<T>(work: () => Promise<T>): Promise<T> {
    if (this.inFlight >= PREFETCH_CONCURRENCY) {
      await new Promise<void>(resolve => this.queue.push(resolve));
    }
    this.inFlight++;
    try {
      return await work();
    } finally {
      this.inFlight--;
      this.queue.shift()?.();
    }
  }
}
