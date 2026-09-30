import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { IOnboardingConfig } from '../interface/onboarding-config.interface';
import {
  DEFAULT_ONBOARDING_AGE_SECTION,
  DEFAULT_ONBOARDING_BRAIN_SECTION,
  DEFAULT_ONBOARDING_DESIRE_SECTION,
  DEFAULT_ONBOARDING_HABIT_SECTION,
  DEFAULT_ONBOARDING_HOW_SECTION,
  DEFAULT_ONBOARDING_LOADING_SECTION,
  DEFAULT_ONBOARDING_NAME_SECTION,
  DEFAULT_ONBOARDING_NOTIF_SECTION,
  DEFAULT_ONBOARDING_PATHS_SECTION,
  DEFAULT_ONBOARDING_PICK_SECTION,
  DEFAULT_ONBOARDING_REMINDER_SECTION,
  DEFAULT_ONBOARDING_THEME_SECTION,
  DEFAULT_ONBOARDING_WELCOME_SECTION,
  ONBOARDING_CONFIG_KEY,
  OnboardingConfig,
} from '../schema/onboarding-config.schema';

@Injectable()
export class OnboardingConfigRepository extends AbstractRepository<OnboardingConfig> {
  protected readonly logger = new Logger(OnboardingConfigRepository.name);

  constructor(
    @InjectModel(OnboardingConfig.name) model: Model<OnboardingConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findDefault(): Promise<OnboardingConfig> {
    return this.model.findOne({ configKey: ONBOARDING_CONFIG_KEY }).lean();
  }

  /**
   * Atomically returns the singleton config, creating it with default/empty
   * sections on first access. Safe under concurrent first requests (no
   * separate check-then-create race).
   */
  async findOrCreateDefault(user?: IUserMeta): Promise<OnboardingConfig> {
    const now = new Date();

    const doc = await this.model
      .findOneAndUpdate(
        { configKey: ONBOARDING_CONFIG_KEY },
        {
          $setOnInsert: {
            configKey: ONBOARDING_CONFIG_KEY,
            welcome: DEFAULT_ONBOARDING_WELCOME_SECTION,
            name: DEFAULT_ONBOARDING_NAME_SECTION,
            age: DEFAULT_ONBOARDING_AGE_SECTION,
            paths: DEFAULT_ONBOARDING_PATHS_SECTION,
            brain: DEFAULT_ONBOARDING_BRAIN_SECTION,
            habit: DEFAULT_ONBOARDING_HABIT_SECTION,
            notif: DEFAULT_ONBOARDING_NOTIF_SECTION,
            pick: DEFAULT_ONBOARDING_PICK_SECTION,
            theme: DEFAULT_ONBOARDING_THEME_SECTION,
            desire: DEFAULT_ONBOARDING_DESIRE_SECTION,
            how: DEFAULT_ONBOARDING_HOW_SECTION,
            reminder: DEFAULT_ONBOARDING_REMINDER_SECTION,
            loading: DEFAULT_ONBOARDING_LOADING_SECTION,
            createdAt: now,
            updatedAt: now,
            ...(user ? { createdBy: user, updatedBy: user } : {}),
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();

    // Backfill for a document created before `theme`/`desire`/`how`/`reminder`/
    // `loading` existed: `$setOnInsert` only ever fires for a brand-new
    // document, and `.lean()` skips Mongoose hydration, so the schema's own
    // `@Prop` default never gets a chance to fill the missing path either —
    // every environment's existing singleton would read these five sections
    // back as `undefined` forever. Patch in place (only the sections actually
    // missing on the doc just read) rather than touching sections an editor
    // may already have customized.
    const missing: Record<string, unknown> = {};
    if (doc.theme === undefined) {
      missing.theme = DEFAULT_ONBOARDING_THEME_SECTION;
    }
    if (doc.desire === undefined) {
      missing.desire = DEFAULT_ONBOARDING_DESIRE_SECTION;
    }
    if (doc.how === undefined) {
      missing.how = DEFAULT_ONBOARDING_HOW_SECTION;
    }
    if (doc.reminder === undefined) {
      missing.reminder = DEFAULT_ONBOARDING_REMINDER_SECTION;
    }
    if (doc.loading === undefined) {
      missing.loading = DEFAULT_ONBOARDING_LOADING_SECTION;
    }

    if (Object.keys(missing).length) {
      await this.model.updateOne(
        { configKey: ONBOARDING_CONFIG_KEY },
        { $set: missing },
      );
      return this.findDefault();
    }

    return doc;
  }

  /**
   * Upserts a (already section-merged) partial config into the singleton
   * document. `patch` is expected to already contain full section objects
   * (service merges each provided section against the current one so
   * untouched fields within a section are preserved).
   */
  async upsertConfig(
    patch: Partial<IOnboardingConfig>,
    user?: IUserMeta,
  ): Promise<OnboardingConfig> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: ONBOARDING_CONFIG_KEY },
        {
          $set: {
            ...patch,
            updatedAt: now,
            ...(user ? { updatedBy: user } : {}),
          },
          $setOnInsert: {
            configKey: ONBOARDING_CONFIG_KEY,
            createdAt: now,
            ...(user ? { createdBy: user } : {}),
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }
}
