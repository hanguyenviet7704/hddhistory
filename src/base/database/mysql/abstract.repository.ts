import {
  DeepPartial,
  FindManyOptions,
  FindOneOptions,
  FindOptionsOrder,
  FindOptionsSelect,
  FindOptionsWhere,
  Repository,
} from 'typeorm';

import {
  IPaginateParams,
  IResponseListPage,
} from '@utils/interface/paging/page.interface';
import { getPagination } from '@utils/paging';

import { AbstractEntity } from './abstract.entity';

export abstract class AbstractRepository<TEntity extends AbstractEntity> {
  constructor(protected readonly repository: Repository<TEntity>) {}

  async create(data: DeepPartial<TEntity>, userId?: string): Promise<TEntity> {
    data.createdBy = userId;
    data.updatedBy = userId;

    const entity = this.repository.create(data);
    return this.repository.save(entity);
  }

  async paginateQuery<T>(
    params: IPaginateParams<T> & {
      relations?: string[];
      select?: FindOptionsSelect<TEntity>;
      orderOptions?: FindOptionsOrder<TEntity>;
    },
  ): Promise<IResponseListPage<T>> {
    const {
      where,
      projection,
      orderBy,
      order,
      page,
      take,
      relations,
      select,
      orderOptions,
      options,
    } = params;
    const pagination = getPagination({ page, take });

    const sortField = orderBy ?? 'createdAt';
    const sortDirection =
      (order?.toUpperCase() as 'ASC' | 'DESC') ?? ('DESC' as const);

    const findOptions: FindManyOptions<TEntity> = {
      where: where as FindOptionsWhere<TEntity>,
      relations,
      select:
        select ??
        (projection as FindOptionsSelect<TEntity> | undefined) ??
        undefined,
      order:
        orderOptions ??
        ({
          [sortField]: sortDirection,
        } as FindOptionsOrder<TEntity>),
      skip: pagination.skip,
      take: pagination.take,
      ...(options ?? {}),
    };

    const [items, total] = await this.repository.findAndCount(findOptions);

    return {
      items: items as unknown as T[],
      itemsPerPage: pagination.take,
      totalPages: Math.ceil(total / pagination.take),
      currentPage: pagination.page,
    };
  }

  async findById(id: string): Promise<TEntity | null> {
    return this.repository.findOne({
      where: { id } as FindOptionsWhere<TEntity>,
    });
  }

  async exists(where: FindOptionsWhere<TEntity>): Promise<boolean> {
    const count = await this.repository.count({ where });
    return count > 0;
  }

  async findOne(
    where: FindOptionsWhere<TEntity>,
    options?: Omit<FindOneOptions<TEntity>, 'where'>,
  ): Promise<TEntity | null> {
    return this.repository.findOne({ where, ...(options ?? {}) });
  }

  async updateOne(
    where: FindOptionsWhere<TEntity>,
    data: DeepPartial<TEntity>,
    userId?: string,
  ) {
    data.updatedBy = userId;

    return this.repository.update(where, data as any);
  }

  async updateMany(
    where: FindOptionsWhere<TEntity>,
    data: DeepPartial<TEntity>,
    userId?: string,
  ) {
    return this.updateOne(where, data, userId);
  }

  async save(entity: DeepPartial<TEntity>) {
    return this.repository.save(entity);
  }

  async deleteOne(where: FindOptionsWhere<TEntity>) {
    return this.repository.delete(where);
  }

  getRepo() {
    return this.repository;
  }
}
