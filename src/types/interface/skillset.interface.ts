import { ITranslation } from "../../utils/translate";
import { SkillsetStatus } from "../enum/skillset.enum";
import { BaseQuery } from "./common.interface";
import { ICourse } from "./course.interface";

export interface ISkillset {
  _id: string;
  title: ITranslation;
  description: ITranslation;
  status: SkillsetStatus;
  image: string;
  courses?: ICourse[];
}

export interface SkillsetPayload {
  title: ITranslation;
  description?: ITranslation;
  status: SkillsetStatus;
  image: string;
  courses?: ICourse[];
}

export class SkillsetListQuery extends BaseQuery {
  status?: SkillsetStatus;
  isAll?: boolean;
  constructor(init?: Partial<SkillsetListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.status) params.set("status", this.status);
    if (this.isAll) params.set("isAll", this.isAll.toString());

    return params.toString();
  }
}
