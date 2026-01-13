import { ITranslation } from "../../utils/translation";

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
  trackingLabel: string;
}

export interface LablelPayload {
  id: number;
  icon: string;
  title: ITranslation;
  label: ITranslation;
  trackingLabel?: string;
}

export interface IMotivation {
  image: string;
  content: ITranslation;
}
