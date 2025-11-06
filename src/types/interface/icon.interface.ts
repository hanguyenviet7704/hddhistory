import { BaseQuery } from "./common.interface";

export interface IIcon {
  _id: string;
  url: string;
}

export interface IconPayload {
  _id: string;
  url: string;
}

export class IconListQuery extends BaseQuery {
  constructor(init?: Partial<IconListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
