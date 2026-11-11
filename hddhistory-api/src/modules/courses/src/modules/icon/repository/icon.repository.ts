import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListIconDto } from '../dto/get-list-icon.dto';
import { Icon } from '../schema/icon.schema';

@Injectable()
export class IconRepository extends AbstractRepository<Icon> {
  protected readonly logger = new Logger(IconRepository.name);
  constructor(
    @InjectModel(Icon.name) model: Model<Icon>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(getListIconDto: GetListIconDto) {
    const where: FilterQuery<Icon> = {};

    const { page, take, search, order, orderBy } = getListIconDto;

    if (search) {
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    return this.paginateQuery<Icon>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }
}
