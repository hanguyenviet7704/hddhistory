import { OrderType } from "../enum/common.enum";

export class BaseQuery {
  page: number = 1;
  take: number = 20;
  search: string = "";
  order: OrderType = OrderType.DESC;
  orderBy: string = "createdAt";

  constructor(init?: Partial<BaseQuery>) {
    Object.assign(this, init);
  }

  toQueryParams(): string {
    const params = new URLSearchParams();

    if (this.page) params.set("page", String(this.page));
    if (this.take) params.set("take", String(this.take));
    if (this.search) params.set("search", this.search);
    if (this.order) params.set("order", this.order);
    if (this.orderBy) params.set("orderBy", this.orderBy);

    return params.toString();
  }
}
