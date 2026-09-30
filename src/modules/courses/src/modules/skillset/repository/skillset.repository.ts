import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { GetListSkillsetDto } from '../dto/get-list-skillset.dto';
import { Skillset } from '../schema/skillset.schema';

@Injectable()
export class SkillsetRepository extends AbstractRepository<Skillset> {
  protected readonly logger = new Logger(SkillsetRepository.name);
  constructor(
    @InjectModel(Skillset.name) model: Model<Skillset>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  private getOnboardingIntroduceFilter(onboardingIntroduce?: string) {
    if (!onboardingIntroduce) return [];

    return onboardingIntroduce
      .split(',')
      .map(item => item.trim())
      .filter(Boolean);
  }

  async findOption(getListSkillsetDto: GetListSkillsetDto) {
    const where: FilterQuery<Skillset> = {};

    const { page, take, search, isAll, status, onboardingIntroduces } =
      getListSkillsetDto;

    if (status && !isAll) {
      where.status = status;
    }

    if (onboardingIntroduces && onboardingIntroduces.length > 0) {
      where.onboardingIntroduce = { $in: onboardingIntroduces };
    }

    if (search) {
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
        { [`description.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    return this.paginateQuery<Skillset>({
      where,
      page,
      take,
      orderBy: 'index',
      order: OrderType.ASC,
    });
  }

  async checkExitsTitle(title: string, lang = this.lang) {
    const normalizedTitle = title?.trim();
    if (!normalizedTitle) return null;

    const skillset = await this.model.exists({
      [`title.${lang}`]: normalizedTitle,
    });
    return skillset;
  }

  async getNextIndex() {
    const lastSkillset = await this.model
      .findOne({}, { index: 1 })
      .sort({ index: -1 })
      .lean()
      .exec();

    const lastIndex = lastSkillset?.index ?? 0;
    return lastIndex + 1;
  }
}
