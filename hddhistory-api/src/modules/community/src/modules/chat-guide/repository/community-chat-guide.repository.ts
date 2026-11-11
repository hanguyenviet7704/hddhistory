import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CommunityLocale } from '../../../interface/community.interface';
import { CommunityChatGuide } from '../schema/community-chat-guide.schema';

@Injectable()
export class CommunityChatGuideRepository extends AbstractRepository<CommunityChatGuide> {
  protected readonly logger = new Logger(CommunityChatGuideRepository.name);

  constructor(
    @InjectModel(CommunityChatGuide.name) model: Model<CommunityChatGuide>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findByLocale(locale: CommunityLocale): Promise<CommunityChatGuide | null> {
    return this.model
      .findOne({ locale })
      .lean() as unknown as CommunityChatGuide | null;
  }

  // Every language at once, for the panel's editor.
  async findAll(): Promise<CommunityChatGuide[]> {
    return this.model.find().lean() as unknown as CommunityChatGuide[];
  }

  async upsert(
    locale: CommunityLocale,
    data: Partial<CommunityChatGuide>,
    user?: IUserMeta,
  ) {
    return this.findOneAndUpdate(
      { locale },
      {
        $set: { ...data, locale, updatedAt: new Date(), updatedBy: user },
        $setOnInsert: { createdAt: new Date(), createdBy: user },
      },
      { upsert: true, setDefaultsOnInsert: true },
    );
  }
}
