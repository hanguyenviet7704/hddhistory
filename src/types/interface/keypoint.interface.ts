import { ITranslation } from "../../utils/translate";
import { BaseQuery } from "./common.interface";

export interface IKeypoint {
  _id: string;
  title: ITranslation;
  description: ITranslation;
  tag?: string[];
  image: string;
}

export interface KeypointPayload {
  title: string;
  description: string;
  tag?: string[];
  image: string;
}

export class KeypointListQuery extends BaseQuery {
  constructor(init?: Partial<KeypointListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
