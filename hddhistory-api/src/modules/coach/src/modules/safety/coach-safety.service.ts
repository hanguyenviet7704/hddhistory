import { Injectable, Logger } from '@nestjs/common';

import { matchesRiskKeyword } from './risk-keywords';
import { CoachAi } from '../ai/coach-ai.types';
import { CoachConfigService } from '../config/coach-config.service';

export interface CoachSafetyVerdict {
  risk: boolean;
  /** Which layer caught it — logged, so the classifier's real value is measurable. */
  by: 'keyword' | 'model' | 'none';
}

/**
 * ⑧, in two layers that fail in opposite directions.
 *
 * The keyword net is local, instant, and can never be unavailable — but it is
 * narrow. The model classifier is broad and multilingual — but it is a network
 * call. Running them together means the narrow-and-certain layer is the floor
 * and the broad layer is the ceiling, and losing either one degrades rather
 * than breaks.
 */
@Injectable()
export class CoachSafetyService {
  private readonly logger = new Logger(CoachSafetyService.name);

  constructor(
    private readonly ai: CoachAi,
    private readonly configService: CoachConfigService,
  ) {}

  /**
   * The keyword layer alone — synchronous, so callers can short-circuit before
   * spending a model call on a message that is already going to ⑧.
   */
  screen(text: string): boolean {
    return matchesRiskKeyword(text);
  }

  /**
   * The model layer.
   *
   * FAILS OPEN, and that is a decision rather than an oversight. Failing closed
   * would route a reader to a crisis line every time the provider hiccups —
   * someone describing an ordinary bad week would be told to call an emergency
   * number, which is both wrong and the last time they would trust this
   * feature with anything. The keyword net still stands underneath, so failing
   * open degrades coverage rather than removing it.
   *
   * Failures are logged at warn so a classifier that has been silently down for
   * a week is visible rather than merely tolerated.
   */
  async classify(text: string, locale: string): Promise<CoachSafetyVerdict> {
    if (matchesRiskKeyword(text)) return { risk: true, by: 'keyword' };

    try {
      const verdict = await this.ai.classifyRisk(text, locale);

      return verdict.risk
        ? { risk: true, by: 'model' }
        : { risk: false, by: 'none' };
    } catch (error: any) {
      this.logger.warn(
        `Risk classifier unavailable, falling back to keyword net only: ${error?.message}`,
      );

      return { risk: false, by: 'none' };
    }
  }

  /** The hotline block shown when ⑧ fires, resolved for this reader. */
  async resolveHotlines(locale: string, country?: string | null) {
    return this.configService.hotlinesFor(locale, country);
  }
}
