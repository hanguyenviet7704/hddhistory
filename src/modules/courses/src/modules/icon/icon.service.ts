import { Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';

import { CreateIconDto } from './dto/create-icon.dto';
import { GetListIconDto } from './dto/get-list-icon.dto';
import { UpdateIconDto } from './dto/update-icon.dto';
import { IIcon } from './interface/icon.interface';
import { IconRepository } from './repository/icon.repository';
import { Icon } from './schema/icon.schema';

@Injectable()
export class IconService {
  constructor(
    private readonly iconRepository: IconRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createIconDto: CreateIconDto): Promise<Icon> {
    createIconDto._id = undefined;
    const icon = await this.iconRepository.create(
      { ...createIconDto } as IIcon,
      this.user,
    );

    return icon;
  }

  async findAll(getListIconDto: GetListIconDto) {
    const result = await this.iconRepository.findOption(getListIconDto);

    return result;
  }

  async findOne(id: string): Promise<Icon> {
    const icon = await this.iconRepository.findOne({ _id: id });
    if (!icon)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_ICON.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    return icon;
  }

  async update(id: string, updateIconDto: UpdateIconDto) {
    const icon = await this.iconRepository.findOne({ _id: id });
    if (!icon)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_ICON.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    updateIconDto._id = undefined;
    const update = await this.iconRepository.updateOne(
      { _id: id },
      {
        ...updateIconDto,
      } as IIcon,
      this.user,
    );

    return update;
  }

  async remove(id: string) {
    const icon = await this.iconRepository.findOne({ _id: id });
    if (!icon)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_ICON.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const res = await this.iconRepository.deleteOne({ _id: id });
    return res;
  }
}
