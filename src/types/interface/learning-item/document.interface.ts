import { DocumentType } from "../../../utils/enum/course.enum";

export interface IMediaDocument {
  content: string;
  url?: string;
  thumbnail?: string;
}

export interface IDocument {
  id: number;
  type: DocumentType;
  data: IMediaDocument;
}
