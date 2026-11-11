import { ITranslation } from "../../utils/translate";
import { BaseQuery } from "./common.interface";

export interface IQuote {
  _id: string;
  content: ITranslation;
  backgroundColor: string;
  textColor: string;
}

export interface QuotePayload {
  content: ITranslation;
  backgroundColor: string;
  textColor: string;
}

export class QuoteListQuery extends BaseQuery {
  constructor(init?: Partial<QuoteListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
