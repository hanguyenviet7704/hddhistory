import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListStudyThemeDto } from '../dto/get-list-study-theme.dto';
import { IStudyThemePresetPublic } from '../interface/study-theme-preset.interface';
import { StudyThemePreset } from '../schema/study-theme-preset.schema';

@Injectable()
export class StudyThemePresetRepository extends AbstractRepository<StudyThemePreset> {
  protected readonly logger = new Logger(StudyThemePresetRepository.name);

  constructor(
    @InjectModel(StudyThemePreset.name) model: Model<StudyThemePreset>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // Public catalogue consumed by the mobile app: active presets only,
  // projected down to exactly the fields the client needs (no _id, isActive,
  // createdAt/updatedAt/createdBy/updatedBy), sorted by order asc then name.
  async findActive(): Promise<IStudyThemePresetPublic[]> {
    return this.model
      .find({ isActive: true })
      .select(
        'key mode category name gradient imageUrl videoUrl audioUrl thumbUrl overlay isDark order isPremium -_id',
      )
      .sort({ order: 1, name: 1 })
      .lean();
  }

  async findOption(getListStudyThemeDto: GetListStudyThemeDto) {
    const where: FilterQuery<StudyThemePreset> = {};
    const { page, take, search, order, orderBy, mode, category, isActive } =
      getListStudyThemeDto;

    if (search?.trim()) {
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      where.$or = [
        { name: { $regex: escaped, $options: 'i' } },
        { category: { $regex: escaped, $options: 'i' } },
        { key: { $regex: escaped, $options: 'i' } },
      ];
    }

    if (mode) where.mode = mode;
    if (category) where.category = category;
    if (isActive !== undefined) where.isActive = isActive;

    return this.paginateQuery<StudyThemePreset>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }
}
