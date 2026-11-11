import { plainToInstance } from 'class-transformer';
import { AnyBulkWriteOperation } from 'mongodb';
import {
  Model,
  SaveOptions,
  FilterQuery,
  QueryOptions,
  UpdateQuery,
  Connection,
  ProjectionType,
} from 'mongoose';

import {
  IPaginateParams,
  IResponseListPage,
} from '@utils/interface/paging/page.interface';
import { getPagination } from '@utils/paging';

import { UserMetaDto } from './abstract.dto';
import { IUserMeta } from './abstract.interface';
import { AbstractDocument } from './abstract.schema';

export abstract class AbstractRepository<TDocument extends AbstractDocument> {
  constructor(
    readonly model: Model<TDocument>,
    private readonly connection: Connection,
  ) {}

  async create(
    data: Partial<TDocument>,
    user?: IUserMeta,
    options?: SaveOptions,
  ): Promise<TDocument> {
    if (user) {
      const cleanUser = plainToInstance(UserMetaDto, user, {
        excludeExtraneousValues: true,
      });
      data.createdBy = cleanUser as unknown as IUserMeta;
      data.updatedBy = cleanUser as unknown as IUserMeta;
    }
    const createdDocument = new this.model({
      ...data,
    });

    return (
      await createdDocument.save(options)
    ).toJSON() as unknown as TDocument;
  }

  async paginateQuery<T>(
    params: IPaginateParams<T>,
  ): Promise<IResponseListPage<T>> {
    const { where, projection, options, orderBy, order, page, take } = params;
    const sort = params.sort ?? { [orderBy]: order };
    const pagination = getPagination({ page, take });

    const [documents, total] = await Promise.all([
      this.model
        .find(where, projection)
        .limit(pagination.take)
        .skip(pagination.skip)
        .sort(sort)
        .setOptions(options)
        .lean(),
      this.model.countDocuments(where),
    ]);

    const items = documents as unknown as T[];

    return {
      items,
      itemsPerPage: pagination.take,
      totalPages: Math.ceil(total / pagination.take),
      currentPage: pagination.page,
    };
  }

  async findById(id: string): Promise<TDocument | null> {
    return this.model.findById(id);
  }

  async exists(filterQuery: FilterQuery<TDocument>) {
    return this.model.exists(filterQuery);
  }

  async findOne(
    filterQuery: FilterQuery<TDocument>,
    select?: ProjectionType<TDocument>,
    option?: QueryOptions,
  ): Promise<TDocument> {
    const document = await this.model.findOne(filterQuery, select, option);

    return document as TDocument;
  }

  async findOneAndUpdate(
    filterQuery: FilterQuery<TDocument>,
    data: UpdateQuery<TDocument>,
    options?: QueryOptions,
  ): Promise<TDocument | null> {
    const document = await this.model.findOneAndUpdate(filterQuery, data, {
      lean: true,
      new: true,
      ...options,
    });

    return document as TDocument;
  }

  async updateOne(
    filterQuery: FilterQuery<TDocument>,
    data: Partial<TDocument>,
    user?: IUserMeta,
    options?: QueryOptions,
  ) {
    data.updatedAt = new Date();
    if (user) {
      const cleanUser = plainToInstance(UserMetaDto, user, {
        excludeExtraneousValues: true,
      });
      data.updatedBy = cleanUser as unknown as IUserMeta;
    }

    return this.model.updateOne(filterQuery, data, options);
  }

  async updateMany(
    filterQuery: FilterQuery<TDocument>,
    data: Partial<TDocument>,
    user?: IUserMeta,
    options?: QueryOptions,
  ) {
    data.updatedAt = new Date();
    if (user) {
      const cleanUser = plainToInstance(UserMetaDto, user, {
        excludeExtraneousValues: true,
      });
      data.updatedBy = cleanUser as unknown as IUserMeta;
    }
    return this.model.updateMany(filterQuery, data, options);
  }

  async bulkWrite(data: AnyBulkWriteOperation<any>[]) {
    return this.model.bulkWrite(data);
  }

  async deleteOne(filterQuery: FilterQuery<TDocument>) {
    return this.model.deleteOne(filterQuery);
  }

  async startTransaction() {
    const session = await this.connection.startSession();
    session.startTransaction();
    return session;
  }
}
