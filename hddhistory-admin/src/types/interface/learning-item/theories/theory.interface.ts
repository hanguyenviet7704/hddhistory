import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface ITheoryDocument {
  id: number;
  tag: ITag | null;
  document: IDocument[];
}

export interface TheoryDocumentPayload {
  id: number;
  tagId: string;
  document: IDocument[];
}
