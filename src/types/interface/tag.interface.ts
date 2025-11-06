import { ITranslation } from "../../utils/translate";
import { BaseQuery } from "./common.interface";

export interface ITag {
  _id: string;
  title: ITranslation;
  color: string;
  url: string;
}

export interface TagPayload {
  _id: string;
  title: string;
  color: string;
  url: string;
}

export class TagListQuery extends BaseQuery {
  constructor(init?: Partial<TagListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
