import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';
import { viewerMarketsForRequest } from '@utils/market-query.util';
import {
  getTranslationValue,
  hasAnyTranslationValue,
} from '@utils/translate';
import { OrderType } from '@utils/type/orderByType';

import { CreateCategoryDto } from './dto/create-category.dto';
import { GetListCategoryDto } from './dto/get-list-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { CategoryRepository } from './repository/category.repository';
import { Category } from './schema/category.schema';
import { CourseRepository } from '../course/repository/course.repository';

@Injectable()
export class CategoryService {
  constructor(
    private readonly categoryRepository: CategoryRepository,
    private readonly courseRepository: CourseRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /**
   * Markets to scope each category's course list to, or `null` for the admin
   * panel. Home and Explore both read their courses through here, so a course
   * published to Japan only must drop out of a Vietnamese reader's categories
   * exactly as it drops out of the catalogue.
   */
  private get viewerMarkets(): string[] | null {
    return viewerMarketsForRequest(this.requestService.headers);
  }

  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createCategoryDto: CreateCategoryDto): Promise<Category> {
    const { title } = createCategoryDto;
    const titleByLang = getTranslationValue(title, this.lang);

    if (!titleByLang && !hasAnyTranslationValue(title)) {
      throw new BadRequestException('title is required');
    }

    if (titleByLang) {
      // check title exists
      const titleExists = await this.categoryRepository.checkExitsTitle(
        titleByLang,
        this.lang,
      );
      if (titleExists)
        throw new ConflictException(
          this.i18n.t('error.CATEGORY.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    const category = await this.categoryRepository.create(
      {
        ...createCategoryDto,
        index: 0,
      },
      this.user,
    );

    return category;
  }

  async findAll(getListCategoryDto: GetListCategoryDto) {
    const result = await this.categoryRepository.findOption(getListCategoryDto);

    // Batch fetch courses for all categories in a single query, then group
    // in-memory. The global createdAt-ASC sort is preserved per category
    // because grouping a sorted list keeps each bucket's relative order.
    const categoryIds = result.items.map(item => item._id.toString());
    const courses = await this.courseRepository.findBriefByCategoryIds(
      categoryIds,
      OrderType.ASC,
      'createdAt',
      this.viewerMarkets,
    );

    const coursesByCategory = new Map<string, typeof courses>();
    for (const course of courses) {
      const key = course.categoryId.toString();
      const list = coursesByCategory.get(key) ?? [];
      list.push(course);
      coursesByCategory.set(key, list);
    }

    for (const item of result.items) {
      item.courses = coursesByCategory.get(item._id.toString()) ?? [];
    }

    return result;
  }

  async findOne(id: string): Promise<Category> {
    const category = await this.categoryRepository.findOne({ _id: id });
    if (!category)
      throw new NotFoundException(
        this.i18n.t('error.CATEGORY.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    // lấy danh sách course
    const courses = await this.courseRepository.findAllBrief(
      category._id.toString(),
      OrderType.ASC,
      'createdAt',
      this.viewerMarkets,
    );

    category.courses = courses.list;

    return category;
  }

  async update(id: string, updateCategoryDto: UpdateCategoryDto) {
    const { title } = updateCategoryDto;
    const category = await this.categoryRepository.findOne({ _id: id });
    if (!category)
      throw new NotFoundException(
        this.i18n.t('error.CATEGORY.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    if (title) {
      const titleByLang = getTranslationValue(title, this.lang);
      const mergedTitle = { ...(category.title ?? {}), ...title };

      if (!titleByLang && !hasAnyTranslationValue(mergedTitle)) {
        throw new BadRequestException('title is required');
      }

      if (!titleByLang) {
        return this.categoryRepository.updateOne(
          { _id: id },
          {
            ...updateCategoryDto,
          },
          this.user,
        );
      }

      // check title exists
      const titleExists = await this.categoryRepository.checkExitsTitle(
        titleByLang,
        this.lang,
      );
      if (titleExists && titleExists._id.toString() !== id)
        throw new ConflictException(
          this.i18n.t('error.CATEGORY.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    const update = await this.categoryRepository.updateOne(
      { _id: id },
      {
        ...updateCategoryDto,
      },
      this.user,
    );

    return update;
  }

  async remove(id: string) {
    const category = await this.categoryRepository.findOne({ _id: id });
    if (!category)
      throw new NotFoundException(
        this.i18n.t('error.CATEGORY.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    const res = await this.categoryRepository.deleteOne({ _id: id });
    return res;
  }
}
