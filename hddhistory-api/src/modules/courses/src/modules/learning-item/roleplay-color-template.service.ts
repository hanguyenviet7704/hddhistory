import { Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';

import { RoleplayColorTemplateDto } from './dto/roleplays/color-template.dto';
import { GetListRoleplayColorTemplateDto } from './dto/roleplays/get-color-template.dto';
import { RoleplayColorTemplateRepository } from './repository/color-template.repository';

@Injectable()
export class RoleplayColorTemplateService {
  constructor(
    private readonly roleplayColorTemplateRepository: RoleplayColorTemplateRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(dto: RoleplayColorTemplateDto) {
    return this.roleplayColorTemplateRepository.create(dto, this.user);
  }

  async update(id: string, dto: RoleplayColorTemplateDto) {
    const colorTemplate = await this.roleplayColorTemplateRepository.findOne({
      _id: id,
    });
    if (!colorTemplate)
      throw new NotFoundException(
        this.i18n.t('error.ROLEPLAY_COLOR_TEMPLATE_NOT_FOUND.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    return this.roleplayColorTemplateRepository.updateOne(
      { _id: id },
      dto,
      this.user,
    );
  }

  async remove(id: string) {
    const colorTemplate = await this.roleplayColorTemplateRepository.findOne({
      _id: id,
    });
    if (!colorTemplate)
      throw new NotFoundException(
        this.i18n.t('error.ROLEPLAY_COLOR_TEMPLATE_NOT_FOUND.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    return this.roleplayColorTemplateRepository.deleteOne({ _id: id });
  }

  async findAll(dto: GetListRoleplayColorTemplateDto) {
    return this.roleplayColorTemplateRepository.findOption(dto);
  }

  async findOne(id: string) {
    const colorTemplate = await this.roleplayColorTemplateRepository.findOne({
      _id: id,
    });
    if (!colorTemplate)
      throw new NotFoundException(
        this.i18n.t('error.ROLEPLAY_COLOR_TEMPLATE_NOT_FOUND.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    return this.roleplayColorTemplateRepository.findOne({ _id: id });
  }
}
