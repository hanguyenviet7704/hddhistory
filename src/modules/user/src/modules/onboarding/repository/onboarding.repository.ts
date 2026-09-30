import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListOnboardingDto } from '../dto/get-list-onboarding.dto';
import { Onboarding } from '../schema/onboarding';

@Injectable()
export class OnboardingRepository extends AbstractRepository<Onboarding> {
  protected readonly logger = new Logger(OnboardingRepository.name);
  constructor(
    @InjectModel(Onboarding.name) model: Model<Onboarding>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(getListOnboardingDto: GetListOnboardingDto) {
    const where: FilterQuery<Onboarding> = {};

    const { page, take, search, order, orderBy } = getListOnboardingDto;

    if (search) {
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
        { [`description.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    return this.paginateQuery<Onboarding>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async checkExitskey(key: string) {
    const onboarding = await this.model.exists({ key });
    return onboarding;
  }

  async findByFieldAndIds(field: string, ids: number[] = []) {
    const numericIds = ids.map(id => Number(id));
    const doc = await this.model.findOne().lean();

    if (!doc) return [];

    const fieldData = (doc as any)[field];
    if (!Array.isArray(fieldData)) return [];

    return fieldData.filter((item: any) => numericIds.includes(item.id));
  }

  /**
   * Slice several fields out of the singleton onboarding-config document in a
   * SINGLE query. `findByFieldAndIds` re-fetches the entire (multi-KB,
   * multi-language) config doc once per field; callers that need multiple
   * fields (e.g. AuthService.getOnboardings) should use this to avoid N
   * sequential full-document round-trips.
   *
   * @param fieldIds map of `{ field: idsToKeep }`
   * @returns map of `{ field: matchedItems }` (empty array for missing fields)
   */
  async findFieldsByIds(
    fieldIds: Record<string, number[]>,
  ): Promise<Record<string, any[]>> {
    const doc = await this.model.findOne().lean();
    const result: Record<string, any[]> = {};

    for (const [field, ids] of Object.entries(fieldIds)) {
      const numericIds = (ids || []).map(id => Number(id));
      const fieldData = doc ? (doc as any)[field] : null;
      result[field] = Array.isArray(fieldData)
        ? fieldData.filter((item: any) => numericIds.includes(item.id))
        : [];
    }

    return result;
  }
}
