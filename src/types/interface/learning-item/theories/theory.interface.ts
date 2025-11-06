import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface ITheoryDocument {
  id: number;
  speechBubble: string;
  tag: ITag | null;
  document: IDocument[];
}

export interface TheoryDocumentPayload {
  id: number;
  speechBubble: string;
  tag: string;
  document: IDocument[];
}
