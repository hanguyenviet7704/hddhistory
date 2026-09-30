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

import { CreateSkillsetDto } from './dto/create-skillset.dto';
import { GetListSkillsetDto } from './dto/get-list-skillset.dto';
import { UpdateSkillsetDto } from './dto/update-skillset.dto';
import { SkillsetRepository } from './repository/skillset.repository';
import { Skillset } from './schema/skillset.schema';
import { CourseRepository } from '../course/repository/course.repository';

@Injectable()
export class SkillsetService {
  constructor(
    private readonly skillsetRepository: SkillsetRepository,
    private readonly courseRepository: CourseRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /**
   * Markets to scope each skillset's course list to, or `null` for the admin
   * panel. Home and Explore both read their courses through here, so a course
   * published to Japan only must drop out of a Vietnamese reader's skillsets
   * exactly as it drops out of the catalogue.
   */
  private get viewerMarkets(): string[] | null {
    return viewerMarketsForRequest(this.requestService.headers);
  }

  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createSkillsetDto: CreateSkillsetDto): Promise<Skillset> {
    const { title } = createSkillsetDto;
    const titleByLang = getTranslationValue(title, this.lang);

    if (!titleByLang && !hasAnyTranslationValue(title)) {
      throw new BadRequestException('title is required');
    }

    if (titleByLang) {
      // check title exists
      const titleExists = await this.skillsetRepository.checkExitsTitle(
        titleByLang,
        this.lang,
      );
      if (titleExists)
        throw new ConflictException(
          this.i18n.t('error.SKILLSET.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    const skillset = await this.skillsetRepository.create(
      {
        ...createSkillsetDto,
        index: 0,
      },
      this.user,
    );

    return skillset;
  }

  async findAll(getListSkillsetDto: GetListSkillsetDto) {
    const result = await this.skillsetRepository.findOption(getListSkillsetDto);

    // Batch fetch courses for all skillsets in a single query, then group
    // in-memory. The global createdAt-ASC sort is preserved per skillset
    // because grouping a sorted list keeps each bucket's relative order.
    const skillsetIds = result.items.map(item => item._id.toString());
    const courses = await this.courseRepository.findBriefBySkillsetIds(
      skillsetIds,
      OrderType.ASC,
      'createdAt',
      this.viewerMarkets,
    );

    const coursesBySkillset = new Map<string, typeof courses>();
    for (const course of courses) {
      const key = course.skillsetId.toString();
      const list = coursesBySkillset.get(key) ?? [];
      list.push(course);
      coursesBySkillset.set(key, list);
    }

    for (const item of result.items) {
      item.courses = coursesBySkillset.get(item._id.toString()) ?? [];
    }

    return result;
  }

  async findOne(id: string): Promise<Skillset> {
    const skillset = await this.skillsetRepository.findOne({ _id: id });
    if (!skillset)
      throw new NotFoundException(
        this.i18n.t('error.SKILLSET.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    // lấy danh sách course
    const courses = await this.courseRepository.findAllBrief(
      skillset._id.toString(),
      OrderType.ASC,
      'createdAt',
      this.viewerMarkets,
    );

    skillset.courses = courses.list;

    return skillset;
  }

  async update(id: string, updateSkillsetDto: UpdateSkillsetDto) {
    const { title } = updateSkillsetDto;
    const skillset = await this.skillsetRepository.findOne({ _id: id });
    if (!skillset)
      throw new NotFoundException(
        this.i18n.t('error.SKILLSET.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    if (title) {
      const titleByLang = getTranslationValue(title, this.lang);
      const mergedTitle = { ...(skillset.title ?? {}), ...title };

      if (!titleByLang && !hasAnyTranslationValue(mergedTitle)) {
        throw new BadRequestException('title is required');
      }

      if (!titleByLang) {
        return this.skillsetRepository.updateOne(
          { _id: id },
          {
            ...updateSkillsetDto,
          },
          this.user,
        );
      }

      // check title exists
      const titleExists = await this.skillsetRepository.checkExitsTitle(
        titleByLang,
        this.lang,
      );
      if (titleExists && titleExists._id.toString() !== id)
        throw new ConflictException(
          this.i18n.t('error.SKILLSET.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    const update = await this.skillsetRepository.updateOne(
      { _id: id },
      {
        ...updateSkillsetDto,
      },
      this.user,
    );

    return update;
  }

  async remove(id: string) {
    const skillset = await this.skillsetRepository.findOne({ _id: id });
    if (!skillset)
      throw new NotFoundException(
        this.i18n.t('error.SKILLSET.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    const res = await this.skillsetRepository.deleteOne({ _id: id });
    return res;
  }
}
