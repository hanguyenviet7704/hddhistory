import { Injectable } from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { UpsertCommunityOfficialProfileDto } from './dto/upsert-community-official-profile.dto';
import { CommunityOfficialProfileRepository } from './repository/community-official-profile.repository';

@Injectable()
export class CommunityOfficialProfileService {
  constructor(
    private readonly repository: CommunityOfficialProfileRepository,
  ) {}

  /**
   * The stored identity, or empty strings when nobody has set one.
   *
   * Empty is meaningful rather than missing: the app falls back to its own
   * localised name and the generated "M" disc, which is what readers see today.
   */
  async get() {
    const profile = await this.repository.get();

    return {
      name: profile?.name ?? '',
      avatar: profile?.avatar ?? '',
    };
  }

  async upsert(dto: UpsertCommunityOfficialProfileDto, user: IUserMeta) {
    await this.repository.upsert(
      {
        name: dto.name?.trim() ?? '',
        avatar: dto.avatar?.trim() ?? '',
      },
      user,
    );

    return this.get();
  }
}
