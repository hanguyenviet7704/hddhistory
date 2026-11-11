import { Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { UpdateLearningImportConfigDto } from './dto/update-learning-import-config.dto';
import { LearningImportConfigRepository } from './repository/learning-import-config.repository';
import { LearningImportConfig } from './schema/learning-import-config.schema';

/**
 * The feature's own on/off switch — see the schema for why it is config and not
 * an env var.
 */
@Injectable()
export class LearningImportConfigService {
  constructor(
    private readonly configRepository: LearningImportConfigRepository,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /** Find-or-create the singleton, so this never 404s and an empty collection
   *  behaves exactly as the feature did before the switch existed. */
  getConfig(): Promise<LearningImportConfig> {
    return this.configRepository.findOrCreateDefault(this.user);
  }

  /**
   * Partial update: sending `{ enabled: false }` must not also wipe the note the
   * admin typed last week.
   */
  async updateConfig(
    dto: UpdateLearningImportConfigDto,
  ): Promise<LearningImportConfig> {
    await this.getConfig();

    const patch: Partial<LearningImportConfig> = {};
    if (dto.enabled !== undefined) patch.enabled = dto.enabled;
    if (dto.disabledNote !== undefined) patch.disabledNote = dto.disabledNote;
    // The pools replace wholesale (the panel edits each as one grid), but each
    // only when SENT — a toggle-only PUT must not wipe the art.
    if (dto.courseCoverUrls !== undefined) {
      patch.courseCoverUrls = dto.courseCoverUrls;
    }
    if (dto.keypointImageUrls !== undefined) {
      patch.keypointImageUrls = dto.keypointImageUrls;
    }

    return this.configRepository.upsertConfig(patch, this.user);
  }
}
