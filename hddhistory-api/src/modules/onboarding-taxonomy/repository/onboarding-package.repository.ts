import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { plainToInstance } from 'class-transformer';
import { Connection, Model } from 'mongoose';

import { UserMetaDto } from '@base/database/mongodb/abstract.dto';
import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { IOnboardingPackage } from '../interface/onboarding-taxonomy.interface';
import { OnboardingPackage } from '../schema/onboarding-package.schema';

@Injectable()
export class OnboardingPackageRepository extends AbstractRepository<OnboardingPackage> {
  protected readonly logger = new Logger(OnboardingPackageRepository.name);

  constructor(
    @InjectModel(OnboardingPackage.name) model: Model<OnboardingPackage>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findAll(activeOnly = false): Promise<IOnboardingPackage[]> {
    return this.model
      .find(activeOnly ? { isActive: true } : {})
      .sort({ order: 1, code: 1 })
      .lean();
  }

  /**
   * Import/lưu cây là THAY TOÀN BỘ: xoá hết rồi chèn lại. Không transaction
   * (Mongo dev là standalone) — caller đã validate xong trước khi gọi, nên cửa
   * sổ lỗi chỉ còn là lỗi hạ tầng.
   */
  async replaceAll(
    rows: IOnboardingPackage[],
    user?: IUserMeta,
  ): Promise<void> {
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

  async findByCodes(codes: string[]): Promise<IOnboardingPackage[]> {
    if (!codes.length) return [];
    return this.model.find({ code: { $in: codes } }).lean();
  }
}
