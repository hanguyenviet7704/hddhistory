import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListRoleplayColorTemplateDto } from '../dto/roleplays/get-color-template.dto';
import { RoleplayColorTemplate } from '../schema/color-template.schema';

@Injectable()
export class RoleplayColorTemplateRepository extends AbstractRepository<RoleplayColorTemplate> {
  protected readonly logger = new Logger(RoleplayColorTemplateRepository.name);
  constructor(
    @InjectModel(RoleplayColorTemplate.name)
    model: Model<RoleplayColorTemplate>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(
    getListRoleplayColorTemplateDto: GetListRoleplayColorTemplateDto,
  ) {
    const where: FilterQuery<RoleplayColorTemplate> = {};

    const { page, take, search, order, orderBy } =
      getListRoleplayColorTemplateDto;

    if (search) {
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    return this.paginateQuery<RoleplayColorTemplate>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }
}
