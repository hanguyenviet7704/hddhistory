import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListTagDto } from '../dto/get-list-tag.dto';
import { Tag } from '../schema/tag.schema';

@Injectable()
export class TagRepository extends AbstractRepository<Tag> {
  protected readonly logger = new Logger(TagRepository.name);
  constructor(
    @InjectModel(Tag.name) model: Model<Tag>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(getListTagDto: GetListTagDto) {
    const where: FilterQuery<Tag> = {};

    const { page, take, search, order, orderBy } = getListTagDto;

    if (search) {
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    return this.paginateQuery<Tag>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findAllBrief() {
    const where: FilterQuery<Tag> = {};

    const list = await this.model
      .find(where)
      .select('title _id color url')
      .lean();

    return { list };
  }

  async findBriefByIds(ids: string[]) {
    if (!ids.length) return { list: [] };

    const list = await this.model
      .find({ _id: { $in: ids } })
      .select('title _id color url')
      .lean();

    return { list };
  }

  async checkExitsTitle(title: string, lang = this.lang) {
    const normalizedTitle = title?.trim();
    if (!normalizedTitle) return null;

    const course = await this.model.exists({
      [`title.${lang}`]: normalizedTitle,
    });
    return course;
  }
}
