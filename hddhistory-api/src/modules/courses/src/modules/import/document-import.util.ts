import {
  ImportRow,
  resolveAssetUrl,
  text,
  translationFromValues,
} from './excel-import.util';
import {
  DocumentType,
  ExerciseType,
} from '../learning-item/enum/learning-item.enum';
import { IDocument } from '../learning-item/interface/document.interface';

export function buildDocuments(
  rows: ImportRow[],
  ownerColumn: string,
  ownerValue: string,
  cdn?: string,
  explanationOptions: ImportRow[] = [],
): IDocument[] {
  let nextId = 1;

  return rows
    .filter(row => text(row.values[ownerColumn]) === ownerValue)
    .map(row => {
      const document = buildDocument(row, nextId, cdn, explanationOptions);
      nextId += 1;
      return document;
    });
}

export function buildDocumentsByOwnerValues(
  rows: ImportRow[],
  ownerColumn: string,
  ownerValues: string[],
  cdn?: string,
  explanationOptions: ImportRow[] = [],
): IDocument[] {
  let nextId = 1;
  const owners = new Set(ownerValues);

  return rows
    .filter(row =>
      text(row.values[ownerColumn])
        .split(',')
        .map(item => item.trim())
        .some(owner => owners.has(owner)),
    )
    .map(row => {
      const document = buildDocument(row, nextId, cdn, explanationOptions);
      nextId += 1;
      return document;
    });
}

export function buildQuestionDocumentGroups(
  rows: ImportRow[],
  questionCode: string,
  cdn?: string,
) {
  const groups = new Map<string, IDocument[]>();

  for (const row of rows) {
    if (text(row.values.question_code) !== questionCode) continue;

    const groupId = text(row.values.document_group_id);
    if (!groupId) continue;

    const groupDocuments = groups.get(groupId) ?? [];
    groupDocuments.push(buildDocument(row, groupDocuments.length + 1, cdn));
    groups.set(groupId, groupDocuments);
  }

  return Array.from(groups.entries()).map(([id, documents]) => ({
    id,
    documents,
  }));
}

export function buildDocument(
  row: ImportRow,
  id: number,
  cdn?: string,
  explanationOptions: ImportRow[] = [],
): IDocument {
  const type = text(row.values.document_type) as DocumentType;
  const data: any = {};
  const content = translationFromValues(row.values, 'document_content');
  const url = translationFromValues(row.values, 'document_url', value =>
    resolveAssetUrl(value, cdn),
  );
  const thumbnail = resolveAssetUrl(row.values.document_thumbnail, cdn);

  if (content) data.content = content;
  if (url) data.url = url;
  if (thumbnail) data.thumbnail = thumbnail;

  if (type === DocumentType.EXPLANATION) {
    data.options = buildExplanationOptions(
      text(row.values.explanation_code),
      explanationOptions,
      cdn,
    );
  }

  return { id, type, data };
}

export function buildExplanationOptions(
  explanationCode: string,
  rows: ImportRow[],
  cdn?: string,
) {
  let nextId = 1;

  return rows
    .filter(row => text(row.values.explanation_code) === explanationCode)
    .map(row => ({
      id: nextId++,
      icon: resolveAssetUrl(row.values.icon, cdn) || null,
      value: translationFromValues(row.values, 'value') ?? {},
      explanation: translationFromValues(row.values, 'explanation') ?? {},
    }));
}

export function isExerciseType(value: string): value is ExerciseType {
  return Object.values(ExerciseType).includes(value as ExerciseType);
}
