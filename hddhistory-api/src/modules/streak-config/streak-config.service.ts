import { Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { UpdateStreakConfigDto } from './dto/update-streak-config.dto';
import { StreakConfigRepository } from './repository/streak-config.repository';
import { StreakConfig } from './schema/streak-config.schema';

@Injectable()
export class StreakConfigService {
  constructor(
    private readonly streakConfigRepository: StreakConfigRepository,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /** Find-or-create the singleton config so this endpoint never 404s. */
  async getConfig(): Promise<StreakConfig> {
    return this.streakConfigRepository.findOrCreateDefault(this.user);
  }

  /**
   * Partial update -- only the fields present in the body change. Sending
   * `{ popupEnabled: false }` must not silently reset the delay back to its
   * default.
   */
  async updateConfig(dto: UpdateStreakConfigDto): Promise<StreakConfig> {
    await this.getConfig();

    const patch: Partial<StreakConfig> = {};
    if (dto.popupEnabled !== undefined) patch.popupEnabled = dto.popupEnabled;
    if (dto.triggerAfterSeconds !== undefined) {
      patch.triggerAfterSeconds = dto.triggerAfterSeconds;
    }
    if (dto.autoHideSeconds !== undefined) {
      patch.autoHideSeconds = dto.autoHideSeconds;
    }

    return this.streakConfigRepository.upsertConfig(patch, this.user);
  }
}
