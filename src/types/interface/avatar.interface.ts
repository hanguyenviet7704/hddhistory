import { BaseQuery } from "./common.interface";

export interface IAvatar {
  _id: string;
  url: string;
}

export interface AvatarPayload {
  _id: string;
  url: string;
}

export class AvatarListQuery extends BaseQuery {
  constructor(init?: Partial<AvatarListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
