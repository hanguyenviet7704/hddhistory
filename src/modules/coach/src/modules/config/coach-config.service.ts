import { Injectable } from '@nestjs/common';

import { UpdateCoachConfigDto } from './dto/update-coach-config.dto';
import { ICoachConfig, ICoachHotline } from './interface/coach-config.interface';
import { CoachConfigRepository } from './repository/coach-config.repository';
import {
  COACH_CONFIG_KEY,
  DEFAULT_COACH_HOTLINES,
} from './schema/coach-config.schema';
import {
  RATING_ASK_ENABLED_DEFAULT,
  RATING_ASK_EVERY_NTH_EXIT_DEFAULT,
  RATING_ASK_MAX_PER_USER_DEFAULT,
  RATING_ASK_MIN_DAYS_DEFAULT,
  RATING_ASK_PROBABILITY_DEFAULT,
  RATING_ASK_SNOOZE_DAYS_DEFAULT,
  TALK_FREE_MAX_TURNS_DEFAULT,
} from '../../shared/coach.constant';

@Injectable()
export class CoachConfigService {
  constructor(private readonly repository: CoachConfigRepository) {}

  /**
   * The effective config, with a safe shape when no document exists yet.
   *
   * Defaults to DISABLED. A fresh environment that has never been configured
   * should not be quietly running a feature that talks to people about hard
   * things — someone turns it on deliberately.
   */
  async get(): Promise<ICoachConfig> {
    const doc = await this.repository.findDefault();

    return {
      configKey: COACH_CONFIG_KEY,
      enabled: doc?.enabled ?? false,
      hotlines: doc?.hotlines ?? DEFAULT_COACH_HOTLINES,
      geminiModel: doc?.geminiModel ?? null,
      geminiSceneModel: doc?.geminiSceneModel ?? null,
      geminiFallbackModels: doc?.geminiFallbackModels ?? null,
      onboardAskStyle: doc?.onboardAskStyle ?? true,
      onboardAskAge: doc?.onboardAskAge ?? true,
      onboardAskGender: doc?.onboardAskGender ?? true,
      onboardAskJob: doc?.onboardAskJob ?? true,
      talkFreeMaxTurns: doc?.talkFreeMaxTurns ?? TALK_FREE_MAX_TURNS_DEFAULT,
      ratingAskEnabled: doc?.ratingAskEnabled ?? RATING_ASK_ENABLED_DEFAULT,
      ratingAskMinDays: doc?.ratingAskMinDays ?? RATING_ASK_MIN_DAYS_DEFAULT,
      ratingAskSnoozeDays: doc?.ratingAskSnoozeDays ?? RATING_ASK_SNOOZE_DAYS_DEFAULT,
      ratingAskEveryNthExit:
        doc?.ratingAskEveryNthExit ?? RATING_ASK_EVERY_NTH_EXIT_DEFAULT,
      ratingAskProbability:
        doc?.ratingAskProbability ?? RATING_ASK_PROBABILITY_DEFAULT,
      ratingAskMaxPerUser: doc?.ratingAskMaxPerUser ?? RATING_ASK_MAX_PER_USER_DEFAULT,
    };
  }

  async isEnabled(): Promise<boolean> {
    return (await this.get()).enabled;
  }

  /**
   * The crisis lines for one reader, most specific first.
   *
   * Exact locale + country wins; then the locale's country-less fallback; then
   * English as the last resort. Returning an empty list is a valid answer — the
   * ⑧ copy has a line for "we don't have a number for your region, please
   * contact local emergency services", which is more honest than showing a
   * number that does not work where they are.
   */
  async hotlinesFor(
    locale: string,
    country?: string | null,
  ): Promise<ICoachHotline[]> {
    const { hotlines } = await this.get();

    const exact = hotlines.filter(
      (h) =>
        h.locale === locale &&
        Boolean(h.country) &&
        h.country?.toUpperCase() === country?.toUpperCase(),
    );
    if (exact.length) return exact;

    const localeWide = hotlines.filter((h) => h.locale === locale && !h.country);
    if (localeWide.length) return localeWide;

    return hotlines.filter((h) => h.locale === 'en' && !h.country);
  }

  async update(dto: UpdateCoachConfigDto): Promise<ICoachConfig> {
    const set: Record<string, unknown> = {};
    if (dto.enabled !== undefined) set.enabled = dto.enabled;
    if (dto.hotlines !== undefined) set.hotlines = dto.hotlines;
    // An empty string is "clear the override" — back to env/code defaults.
    if (dto.geminiModel !== undefined) {
      set.geminiModel = dto.geminiModel.trim() || null;
    }
    if (dto.geminiSceneModel !== undefined) {
      set.geminiSceneModel = dto.geminiSceneModel.trim() || null;
    }
    if (dto.geminiFallbackModels !== undefined) {
      set.geminiFallbackModels = dto.geminiFallbackModels.trim() || null;
    }
    // Luồng 1 — the four optional onboarding questions.
    if (dto.onboardAskStyle !== undefined) set.onboardAskStyle = dto.onboardAskStyle;
    if (dto.onboardAskAge !== undefined) set.onboardAskAge = dto.onboardAskAge;
    if (dto.onboardAskGender !== undefined) set.onboardAskGender = dto.onboardAskGender;
    if (dto.onboardAskJob !== undefined) set.onboardAskJob = dto.onboardAskJob;
    // Luồng 2.
    if (dto.talkFreeMaxTurns !== undefined) set.talkFreeMaxTurns = dto.talkFreeMaxTurns;
    // Luồng 6 — the rating-ask gates. `!== undefined` and not a truthiness test:
    // 0 and false are how these knobs are switched OFF, so dropping falsy values
    // would make "tắt cổng này" the one edit admin cannot save.
    if (dto.ratingAskEnabled !== undefined) set.ratingAskEnabled = dto.ratingAskEnabled;
    if (dto.ratingAskMinDays !== undefined) set.ratingAskMinDays = dto.ratingAskMinDays;
    if (dto.ratingAskSnoozeDays !== undefined) {
      set.ratingAskSnoozeDays = dto.ratingAskSnoozeDays;
    }
    if (dto.ratingAskEveryNthExit !== undefined) {
      set.ratingAskEveryNthExit = dto.ratingAskEveryNthExit;
    }
    if (dto.ratingAskProbability !== undefined) {
      set.ratingAskProbability = dto.ratingAskProbability;
    }
    if (dto.ratingAskMaxPerUser !== undefined) {
      set.ratingAskMaxPerUser = dto.ratingAskMaxPerUser;
    }

    await this.repository.upsertDefault({ $set: set });

    return this.get();
  }
}
