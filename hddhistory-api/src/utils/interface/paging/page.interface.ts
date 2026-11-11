import { OrderType } from '@utils/type/orderByType';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export interface IPaginateParams<T> {
  where?: any;
  page?: number;
  take?: number;
  orderBy?: string;
  order?: OrderType.DESC | OrderType.ASC;
  projection?: Record<string, any>;
  options?: Record<string, any>;

  /**
   * A multi-key sort, when one `orderBy` cannot say it.
   *
   * Wins over orderBy/order when both are given. Added for the moderation table,
   * which has to put pinned posts above everything else and THEN sort by date —
   * two keys, and sorting the page client-side would only reorder the twenty
   * rows already fetched, leaving a pinned post on page 3 exactly where it was.
   */
  sort?: Record<string, 1 | -1>;
}

export interface IResponseListPage<T> {
  items: T[];
  itemsPerPage: number;
  totalPages: number;
  currentPage: number;
}
