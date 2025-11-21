import { DocumentType } from "../../../utils/enum/course.enum";
import { ITranslation } from "../../../utils/translate";

export interface IMediaDocument {
  content: ITranslation;
  url?: ITranslation;
  thumbnail?: string;
}

export interface IDocument {
  id: number;
  type: DocumentType;
  data: IMediaDocument;
}
