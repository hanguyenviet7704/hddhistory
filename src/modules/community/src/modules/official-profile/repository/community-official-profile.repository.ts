import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CommunityOfficialProfile } from '../schema/community-official-profile.schema';

/** There is one team, so there is one row. */
export const OFFICIAL_PROFILE_KEY = 'official';

@Injectable()
export class CommunityOfficialProfileRepository extends AbstractRepository<CommunityOfficialProfile> {
  protected readonly logger = new Logger(
    CommunityOfficialProfileRepository.name,
  );

  constructor(
    @InjectModel(CommunityOfficialProfile.name)
    model: Model<CommunityOfficialProfile>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async get(): Promise<CommunityOfficialProfile | null> {
    return this.model
      .findOne({ key: OFFICIAL_PROFILE_KEY })
      .lean() as unknown as CommunityOfficialProfile | null;
  }

  async upsert(
    data: Partial<CommunityOfficialProfile>,
    user?: IUserMeta,
  ): Promise<CommunityOfficialProfile | null> {
    return this.findOneAndUpdate(
      { key: OFFICIAL_PROFILE_KEY },
      {
        $set: { ...data, updatedAt: new Date(), updatedBy: user },
        $setOnInsert: { createdAt: new Date(), createdBy: user },
      },
      { upsert: true, setDefaultsOnInsert: true },
    );
  }
}
