import { Injectable } from '@nestjs/common';

import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { UpdateHabitConfigDto } from './dto/update-habit-config.dto';
import { IHabitConfig } from './interface/habit-config.interface';
import { HabitConfigRepository } from './repository/habit-config.repository';
import {
  DEFAULT_FREE_ACTIVE_HABIT_SLOTS,
  HABIT_CONFIG_KEY,
} from './schema/habit-config.schema';

// Plain singleton on purpose: this service must NOT inject the request-scoped
// RequestService, or NestJS would force the whole HabitConfigController (incl.
// the hot GET /habit-config read) — and every consumer, e.g. UserHabitService —
// into request scope, re-instantiating them on every request. The one write
// path that needs the actor takes it as a `user` argument from the controller.
@Injectable()
export class HabitConfigService {
  // In-memory cache of the single global config document. It changes ONLY via
  // the admin PUT, yet GET /habit-config is read on every Habit screen load —
  // so serving from memory removes a Mongo round-trip from that hot path (where
  // the read was showing up collateral-slow behind other concurrent habit
  // requests). A short TTL bounds staleness across PM2 cluster workers (a PUT on
  // one worker can't invalidate another's cache); updateConfig() refreshes the
  // local cache so the writing worker is instantly consistent.
  private cachedConfig: IHabitConfig | null = null;
  private cacheExpiresAt = 0;
  private static readonly CACHE_TTL_MS = 60_000;

  constructor(
    private readonly habitConfigRepository: HabitConfigRepository,
  ) {}

  async getConfig(): Promise<IHabitConfig> {
    if (this.cachedConfig && this.cacheExpiresAt > Date.now()) {
      return this.cachedConfig;
    }

    const config = await this.habitConfigRepository.findDefault();
    const resolved: IHabitConfig = config ?? {
      configKey: HABIT_CONFIG_KEY,
      freeActiveSlots: DEFAULT_FREE_ACTIVE_HABIT_SLOTS,
    };
    this.cacheConfig(resolved);

    return resolved;
  }

  /** The effective free-tier cap (config value, or the default when unset/invalid). */
  async getFreeActiveSlots(): Promise<number> {
    const config = await this.getConfig();
    const slots = config.freeActiveSlots;
    return Number.isInteger(slots) && slots >= 1
      ? slots
      : DEFAULT_FREE_ACTIVE_HABIT_SLOTS;
  }

  async updateConfig(dto: UpdateHabitConfigDto, user?: IUser) {
    const now = new Date();

    const updated = await this.habitConfigRepository.upsertDefault({
      $set: {
        ...dto,
        updatedBy: user,
        updatedAt: now,
      },
      $setOnInsert: {
        configKey: HABIT_CONFIG_KEY,
        createdBy: user,
        createdAt: now,
      },
    });

    // Keep the writing worker instantly consistent; other cluster workers pick
    // the change up within CACHE_TTL_MS.
    if (updated) {
      this.cacheConfig(updated);
    } else {
      this.invalidateCache();
    }

    return updated;
  }

  private cacheConfig(config: IHabitConfig) {
    this.cachedConfig = config;
    this.cacheExpiresAt = Date.now() + HabitConfigService.CACHE_TTL_MS;
  }

  private invalidateCache() {
    this.cachedConfig = null;
    this.cacheExpiresAt = 0;
  }
}
