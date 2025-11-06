import { LangCode } from "../../types/enum/common.enum";

export interface LangOption {
  code: LangCode;
  label: string;
  countryCode: string;
}
