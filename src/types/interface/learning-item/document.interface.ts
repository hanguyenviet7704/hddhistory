import { DocumentType } from "../../../utils/enum/course.enum";

export interface IMediaDocument {
  title: string;
  content: string;
  caption: string;
  url?: string;
  thumbnail?: string;
}

export interface IDocument {
  id: number;
  type: DocumentType;
  data: IMediaDocument;
}
