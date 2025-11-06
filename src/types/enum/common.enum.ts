import { ITranslation } from "../../utils/translate";

export enum LangCode {
  EN = "en",
  VI = "vi",
  // JA = "ja",
}

export enum OrderType {
  ASC = "asc",
  DESC = "desc",
}

export interface ILablel {
  id: number;
  icon: string;
  title: ITranslation;
  label: ITranslation;
}

export interface LablelPayload {
  id: number;
  icon: string;
  title: string;
  label: string;
}
