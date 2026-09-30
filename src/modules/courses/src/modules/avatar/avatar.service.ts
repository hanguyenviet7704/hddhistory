import { Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';

import { CreateAvatarDto } from './dto/create-avatar.dto';
import { GetListAvatarDto } from './dto/get-list-avatar.dto';
import { UpdateAvatarDto } from './dto/update-avatar.dto';
import { IAvatar } from './interface/avatar.interface';
import { AvatarRepository } from './repository/avatar.repository';
import { Avatar } from './schema/avatar.schema';

@Injectable()
export class AvatarService {
  constructor(
    private readonly avatarRepository: AvatarRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createAvatarDto: CreateAvatarDto): Promise<Avatar> {
    createAvatarDto._id = undefined;
    const avatar = await this.avatarRepository.create(
      { ...createAvatarDto } as IAvatar,
      this.user,
    );

    return avatar;
  }

  async findAll(getListAvatarDto: GetListAvatarDto) {
    const result = await this.avatarRepository.findOption(getListAvatarDto);

    return result;
  }

  async findOne(id: string): Promise<Avatar> {
    const avatar = await this.avatarRepository.findOne({ _id: id });
    if (!avatar)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_AVATAR.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    return avatar;
  }

  async update(id: string, updateAvatarDto: UpdateAvatarDto) {
    const avatar = await this.avatarRepository.findOne({ _id: id });
    if (!avatar)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_AVATAR.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    updateAvatarDto._id = undefined;
    const update = await this.avatarRepository.updateOne(
      { _id: id },
      {
        ...updateAvatarDto,
      } as IAvatar,
      this.user,
    );

    return update;
  }

  async remove(id: string) {
    const avatar = await this.avatarRepository.findOne({ _id: id });
    if (!avatar)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_AVATAR.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const res = await this.avatarRepository.deleteOne({ _id: id });
    return res;
  }
}
