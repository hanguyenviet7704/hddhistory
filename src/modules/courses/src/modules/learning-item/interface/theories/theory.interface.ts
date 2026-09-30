import { IDocument } from '../document.interface';

export interface ITheoryDocument {
  id: number;
  tagId: string;
  document: IDocument[];
}
