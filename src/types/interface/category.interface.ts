import { ITranslation } from "../../utils/translate";
import {
  CategoryOnboardingIntroduce,
  CategoryStatus,
} from "../enum/category.enum";
import { BaseQuery } from "./common.interface";
import { ICourse } from "./course.interface";

export interface ICategory {
  _id: string;
  title: ITranslation;
  description?: ITranslation;
  status: CategoryStatus;
  image: string;
  onboardingIntroduce?: CategoryOnboardingIntroduce | null;
  courses?: ICourse[];
  index?: number;
}

export type CategoryPayload = Omit<ICategory, "_id">;

export class CategoryListQuery extends BaseQuery {
  status?: CategoryStatus;
  isAll?: boolean;
  constructor(init?: Partial<CategoryListQuery>) {
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
