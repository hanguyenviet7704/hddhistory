import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { GetListCategoryDto } from '../dto/get-list-category.dto';
import { Category } from '../schema/category.schema';

@Injectable()
export class CategoryRepository extends AbstractRepository<Category> {
  protected readonly logger = new Logger(CategoryRepository.name);
  constructor(
    @InjectModel(Category.name) model: Model<Category>,
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

  async findOption(getListCategoryDto: GetListCategoryDto) {
    const where: FilterQuery<Category> = {};

    const { page, take, search, isAll, status, onboardingIntroduces } =
      getListCategoryDto;

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

    return this.paginateQuery<Category>({
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

    const category = await this.model.exists({
      [`title.${lang}`]: normalizedTitle,
    });
    return category;
  }

  async getNextIndex() {
    const lastCategory = await this.model
      .findOne({}, { index: 1 })
      .sort({ index: -1 })
      .lean()
      .exec();

    const lastIndex = lastCategory?.index ?? 0;
    return lastIndex + 1;
  }
}
