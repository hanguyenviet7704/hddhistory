import { ITranslation } from "../../../../utils/translate";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface ITheoryDocument {
  id: number;
  speechBubble: ITranslation;
  tag: ITag | null;
  document: IDocument[];
}

export interface TheoryDocumentPayload {
  id: number;
  speechBubble: ITranslation;
  tagId: string;
  document: IDocument[];
}
