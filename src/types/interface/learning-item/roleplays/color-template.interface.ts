import { BaseQuery } from "../../common.interface";

export interface IColorStyle {
  backgroundColor: string;
  textColor: string;
}

export interface IConversationColor {
  left: IColorStyle;
  right: IColorStyle;
}

export interface IRoleplayColorTemplate {
  _id?: string;
  title: string;
  conversation: IConversationColor;
  leadingText: IColorStyle;
  hint: IColorStyle;
  transition: IColorStyle;
}

export class RoleplayColorTemplateListQuery extends BaseQuery {
  keypointId?: string;
  constructor(init?: Partial<RoleplayColorTemplateListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
