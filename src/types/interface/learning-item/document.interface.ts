import { DocumentType } from "../../../utils/enum/course.enum";
import { ITranslation } from "../../../utils/translate";

export interface IExplanationOption {
  id: number;
  icon: string | null;
  value: ITranslation;
  explanation: ITranslation;
}
export interface IDocumentData {
  content: ITranslation;
  url?: ITranslation;
  thumbnail?: string;
  options?: IExplanationOption[];
}

export interface IDocument {
  id: number;
  type: DocumentType;
  data: IDocumentData;
}
