import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';

import { CreateStudyThemeDto } from './dto/create-study-theme.dto';
import { GetListStudyThemeDto } from './dto/get-list-study-theme.dto';
import { UpdateStudyThemeDto } from './dto/update-study-theme.dto';
import { IStudyThemePreset } from './interface/study-theme-preset.interface';
import { StudyThemePresetRepository } from './repository/study-theme-preset.repository';
import { StudyThemePreset } from './schema/study-theme-preset.schema';

@Injectable()
export class StudyThemeService {
  constructor(
    private readonly studyThemePresetRepository: StudyThemePresetRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  // GET /study-themes — what the mobile app calls to render the picker.
  async findActive() {
    return this.studyThemePresetRepository.findActive();
  }

  // GET /study-themes/all — admin table, includes inactive presets.
  async findAll(getListStudyThemeDto: GetListStudyThemeDto) {
    return this.studyThemePresetRepository.findOption(getListStudyThemeDto);
  }

  async create(
    createStudyThemeDto: CreateStudyThemeDto,
  ): Promise<StudyThemePreset> {
    const keyExists = await this.studyThemePresetRepository.exists({
      key: createStudyThemeDto.key,
    });
    if (keyExists) {
      throw new ConflictException(
        this.i18n.t('error.STUDY_THEME.KEY_EXISTS', { lang: this.lang }),
      );
    }

    return this.studyThemePresetRepository.create(
      { ...createStudyThemeDto } as IStudyThemePreset,
      this.user,
    );
  }

  async update(key: string, updateStudyThemeDto: UpdateStudyThemeDto) {
    const preset = await this.studyThemePresetRepository.findOne({ key });
    if (!preset) {
      throw new NotFoundException(
        this.i18n.t('error.STUDY_THEME.NOT_FOUND', { lang: this.lang }),
      );
    }

    return this.studyThemePresetRepository.updateOne(
      { key },
      { ...updateStudyThemeDto } as Partial<StudyThemePreset>,
      this.user,
    );
  }

  async remove(key: string) {
    const preset = await this.studyThemePresetRepository.findOne({ key });
    if (!preset) {
      throw new NotFoundException(
        this.i18n.t('error.STUDY_THEME.NOT_FOUND', { lang: this.lang }),
      );
    }

    return this.studyThemePresetRepository.deleteOne({ key });
  }
}
