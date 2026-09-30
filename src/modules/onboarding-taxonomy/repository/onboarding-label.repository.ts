import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { plainToInstance } from 'class-transformer';
import { Connection, Model } from 'mongoose';

import { UserMetaDto } from '@base/database/mongodb/abstract.dto';
import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { IOnboardingLabel } from '../interface/onboarding-taxonomy.interface';
import { OnboardingLabel } from '../schema/onboarding-label.schema';

@Injectable()
export class OnboardingLabelRepository extends AbstractRepository<OnboardingLabel> {
  protected readonly logger = new Logger(OnboardingLabelRepository.name);

  constructor(
    @InjectModel(OnboardingLabel.name) model: Model<OnboardingLabel>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findAll(): Promise<IOnboardingLabel[]> {
    return this.model.find({}).sort({ order: 1, code: 1 }).lean();
  }

  /**
   * Import/lưu cây là THAY TOÀN BỘ: xoá hết rồi chèn lại. Không transaction
   * (Mongo dev là standalone) — caller đã validate xong trước khi gọi, nên cửa
   * sổ lỗi chỉ còn là lỗi hạ tầng.
   */
  async replaceAll(rows: IOnboardingLabel[], user?: IUserMeta): Promise<void> {
    await this.model.deleteMany({});
    if (!rows.length) return;
    const cleanUser = user
      ? (plainToInstance(UserMetaDto, user, {
          excludeExtraneousValues: true,
        }) as unknown as IUserMeta)
      : undefined;
    const meta = cleanUser
      ? { createdBy: cleanUser, updatedBy: cleanUser }
      : {};
    await this.model.insertMany(rows.map(row => ({ ...row, ...meta })));
  }

  async findByPackageCodes(
    packageCodes: string[],
  ): Promise<IOnboardingLabel[]> {
    if (!packageCodes.length) return [];
    return this.model
      .find({ packageCode: { $in: packageCodes } })
      .sort({ order: 1 })
      .lean();
  }
}
