import { Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { UpdateWarmUpConfigDto } from './dto/update-warm-up-config.dto';
import { WarmUpInactivityUnit } from './enum/warm-up-inactivity-unit.enum';
import { WarmUpConfigRepository } from './repository/warm-up-config.repository';
import { WARM_UP_CONFIG_KEY } from './schema/warm-up-config.schema';

@Injectable()
export class WarmUpConfigService {
  constructor(
    private readonly warmUpConfigRepository: WarmUpConfigRepository,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  async getConfig() {
    const config = await this.warmUpConfigRepository.findDefault();
    if (!config) {
      return {
        configKey: WARM_UP_CONFIG_KEY,
        enabled: false,
        inactivityValue: 3,
        inactivityUnit: WarmUpInactivityUnit.DAYS,
      };
    }

    // Backward compatibility: pre-existing documents only stored the legacy
    // `inactivityDays` field. Derive the value+unit pair on read so consumers
    // always receive the new shape; the next "Save changes" persists it.
    if (!config.inactivityUnit) {
      return {
        ...config,
        inactivityValue: config.inactivityValue ?? config.inactivityDays ?? 3,
        inactivityUnit: WarmUpInactivityUnit.DAYS,
      };
    }

    return config;
  }

  async updateConfig(dto: UpdateWarmUpConfigDto) {
    const now = new Date();

    return this.warmUpConfigRepository.upsertDefault({
      $set: {
        ...dto,
        updatedBy: this.user,
        updatedAt: now,
      },
      $setOnInsert: {
        configKey: WARM_UP_CONFIG_KEY,
        createdBy: this.user,
        createdAt: now,
      },
    });
  }
}
