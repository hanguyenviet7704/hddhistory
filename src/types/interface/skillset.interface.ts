import { ITranslation } from "../../utils/translate";
import { BaseQuery } from "./common.interface";
import { ICourse } from "./cource.interface";

export interface ISkillset {
  _id: string;
  title: ITranslation;
  description: ITranslation;
  image: string;
  courses?: ICourse[];
}

export interface SkillsetPayload {
  title: string;
  description: string;
  image: string;
  courses?: ICourse[];
}

export class SkillsetListQuery extends BaseQuery {
  constructor(init?: Partial<SkillsetListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
