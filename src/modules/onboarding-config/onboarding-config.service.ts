import { Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { UpdateOnboardingConfigDto } from './dto/update-onboarding-config.dto';
import {
  IOnboardingAgeSection,
  IOnboardingBrainSection,
  IOnboardingConfig,
  IOnboardingDesireSection,
  IOnboardingHabitSection,
  IOnboardingHowSection,
  IOnboardingLoadingSection,
  IOnboardingNameSection,
  IOnboardingNotifSection,
  IOnboardingPathsSection,
  IOnboardingPickSection,
  IOnboardingReminderSection,
  IOnboardingThemeSection,
  IOnboardingWelcomeSection,
} from './interface/onboarding-config.interface';
import { OnboardingConfigRepository } from './repository/onboarding-config.repository';
import { OnboardingConfig } from './schema/onboarding-config.schema';

@Injectable()
export class OnboardingConfigService {
  constructor(
    private readonly onboardingConfigRepository: OnboardingConfigRepository,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /** Find-or-create the singleton config so this endpoint never 404s. */
  async getConfig(): Promise<OnboardingConfig> {
    return this.onboardingConfigRepository.findOrCreateDefault(this.user);
  }

  /**
   * Admin partial update. Every section is optional; when a section is
   * provided, its fields are merged over the current section (so omitted
   * fields within an updated section keep their existing value) and the
   * merged result is upserted into the singleton document.
   */
  async updateConfig(
    dto: UpdateOnboardingConfigDto,
  ): Promise<OnboardingConfig> {
    const current = await this.getConfig();

    const patch: Partial<IOnboardingConfig> = {};

    if (dto.welcome) {
      patch.welcome = {
        ...current.welcome,
        ...dto.welcome,
      } as IOnboardingWelcomeSection;
    }
    if (dto.name) {
      patch.name = { ...current.name, ...dto.name } as IOnboardingNameSection;
    }
    if (dto.age) {
      patch.age = { ...current.age, ...dto.age } as IOnboardingAgeSection;
    }
    if (dto.paths) {
      patch.paths = {
        ...current.paths,
        ...dto.paths,
      } as IOnboardingPathsSection;
    }
    if (dto.brain) {
      patch.brain = {
        ...current.brain,
        ...dto.brain,
      } as IOnboardingBrainSection;
    }
    if (dto.habit) {
      patch.habit = {
        ...current.habit,
        ...dto.habit,
      } as IOnboardingHabitSection;
    }
    if (dto.notif) {
      patch.notif = {
        ...current.notif,
        ...dto.notif,
      } as IOnboardingNotifSection;
    }
    if (dto.pick) {
      patch.pick = { ...current.pick, ...dto.pick } as IOnboardingPickSection;
    }
    if (dto.theme) {
      patch.theme = {
        ...current.theme,
        ...dto.theme,
      } as IOnboardingThemeSection;
    }
    if (dto.desire) {
      patch.desire = {
        ...current.desire,
        ...dto.desire,
      } as IOnboardingDesireSection;
    }
    if (dto.how) {
      patch.how = { ...current.how, ...dto.how } as IOnboardingHowSection;
    }
    if (dto.reminder) {
      patch.reminder = {
        ...current.reminder,
        ...dto.reminder,
      } as IOnboardingReminderSection;
    }
    if (dto.loading) {
      patch.loading = {
        ...current.loading,
        ...dto.loading,
      } as IOnboardingLoadingSection;
    }
    // Bug cũ: toggle admin gửi field này nhưng patch không copy nó, nên chưa
    // bao giờ được lưu (đọc lại luôn ra default `false` của schema). So sánh
    // với `undefined` chứ không dùng truthy check, để `false` vẫn được lưu.
    if (dto.showPaywallAfterOnboarding !== undefined) {
      patch.showPaywallAfterOnboarding = dto.showPaywallAfterOnboarding;
    }

    return this.onboardingConfigRepository.upsertConfig(patch, this.user);
  }
}
