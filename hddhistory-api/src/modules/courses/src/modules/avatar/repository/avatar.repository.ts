import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListAvatarDto } from '../dto/get-list-avatar.dto';
import { Avatar } from '../schema/avatar.schema';

@Injectable()
export class AvatarRepository extends AbstractRepository<Avatar> {
  protected readonly logger = new Logger(AvatarRepository.name);
  constructor(
    @InjectModel(Avatar.name) model: Model<Avatar>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(getListAvatarDto: GetListAvatarDto) {
    const where: FilterQuery<Avatar> = {};

    const { page, take, search, order, orderBy } = getListAvatarDto;

    if (search) {
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    return this.paginateQuery<Avatar>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findAllBrief() {
    const where: FilterQuery<Avatar> = {};

    const list = await this.model.find(where).select('name url').lean();

    return { list };
  }

  async findBriefByIds(ids: string[]) {
    if (!ids.length) return { list: [] };

    const list = await this.model
      .find({ _id: { $in: ids } })
      .select('name url')
      .lean();

    return { list };
  }
}
