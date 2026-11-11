import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';
import {
  getTranslationValue,
  hasAnyTranslationValue,
  normalizeTranslation,
} from '@utils/translate';

import { CreateTagDto } from './dto/create-tag.dto';
import { GetListTagDto } from './dto/get-list-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';
import { ITag } from './interface/tag.interface';
import { TagRepository } from './repository/tag.repository';
import { Tag } from './schema/tag.schema';

@Injectable()
export class TagService {
  constructor(
    private readonly tagRepository: TagRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createTagDto: CreateTagDto): Promise<Tag> {
    const { title } = createTagDto;
    const titleByLang = getTranslationValue(title, this.lang);

    if (!titleByLang) {
      throw new BadRequestException('title is required');
    }

    // check title exits
    const titleExits = await this.tagRepository.checkExitsTitle(
      titleByLang,
      this.lang,
    );
    if (titleExits)
      throw new ConflictException(
        this.i18n.t('error.COURSE_TAG.TITLE_EXISTS', {
          lang: this.lang,
        }),
      );

    const parseTitle = normalizeTranslation(title, this.lang);
    createTagDto._id = undefined;

    const tag = await this.tagRepository.create(
      { ...createTagDto, title: parseTitle } as ITag,
      this.user,
    );

    return tag;
  }

  async findAll(getListTagDto: GetListTagDto) {
    const result = await this.tagRepository.findOption(getListTagDto);

    return result;
  }

  async findOne(id: string): Promise<Tag> {
    const tag = await this.tagRepository.findOne({ _id: id });
    if (!tag)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_TAG.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    return tag;
  }

  async update(id: string, updateTagDto: UpdateTagDto) {
    const { title } = updateTagDto;
    const tag = await this.tagRepository.findOne({ _id: id });
    if (!tag)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_TAG.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const titleByLang = getTranslationValue(title, this.lang);
    const mergedTitle = normalizeTranslation(title, this.lang, tag.title);

    if (title !== undefined && !titleByLang && !hasAnyTranslationValue(mergedTitle)) {
      throw new BadRequestException('title is required');
    }

    if (titleByLang) {
      // check title exits
      const titleExits = await this.tagRepository.checkExitsTitle(
        titleByLang,
        this.lang,
      );
      if (titleExits && titleExits._id.toString() !== id)
        throw new ConflictException(
          this.i18n.t('error.COURSE_TAG.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    updateTagDto._id = undefined;
    const update = await this.tagRepository.updateOne(
      { _id: id },
      {
        ...updateTagDto,
        title: title ? mergedTitle : tag.title,
      } as ITag,
      this.user,
    );

    return update;
  }

  async remove(id: string) {
    const tag = await this.tagRepository.findOne({ _id: id });
    if (!tag)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_TAG.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const res = await this.tagRepository.deleteOne({ _id: id });
    return res;
  }
}
