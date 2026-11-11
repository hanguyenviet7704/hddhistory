import { Types } from 'mongoose';

import {
  buildDocuments,
  buildQuestionDocumentGroups,
  isExerciseType,
} from './document-import.util';
import {
  ImportRow,
  hasTranslationValueForPrefix,
  numberValue,
  resolveAssetUrl,
  splitList,
  text,
  translationFromValues,
} from './excel-import.util';
import { ExerciseType } from '../learning-item/enum/learning-item.enum';
import { ExerciseInput } from '../learning-item/interface/learning-item.interface';

export interface ExerciseGroup {
  rows: ImportRow[];
  firstRow: ImportRow;
}

export function groupExerciseRows(rows: ImportRow[]) {
  const groups: ExerciseGroup[] = [];
  let current: ExerciseGroup | undefined;

  for (const row of rows) {
    const id = text(row.values.id);
    const startsItem =
      id ||
      text(row.values.keypoint_id) ||
      hasTranslationValueForPrefix(row.values, 'title');
    // Result files write the created id back onto every row of a group, so
    // consecutive rows carrying the same id are one item, not new ones.
    const continuesCurrent =
      id && current && text(current.firstRow.values.id) === id;

    if ((startsItem && !continuesCurrent) || !current) {
      current = { firstRow: row, rows: [] };
      groups.push(current);
    }
    current.rows.push(row);
  }

  return groups;
}

export function buildExerciseQuestions(
  rows: ImportRow[],
  documentRows: ImportRow[],
  optionRows: ImportRow[],
  documentGroupRows: ImportRow[],
  existingQuestions: ExerciseInput[] = [],
  cdn?: string,
): ExerciseInput[] {
  return rows.map((row, index) => {
    const questionCode = text(row.values.question_code);
    const type = text(row.values.question_type);
    const existing = existingQuestions[index] ?? {};
    const dailyWarmUpValue =
      row.values.isDailyWarmUp ??
      row.values.daily_warm_up ??
      row.values.is_daily_warm_up;
    const base: any = {
      id: index + 1,
      exerciseId:
        text(row.values.exercise_id) ||
        existing.exerciseId ||
        new Types.ObjectId().toString(),
      type,
      document: buildDocuments(
        documentRows,
        'question_code',
        questionCode,
        cdn,
      ),
      explanation:
        translationFromValues(row.values, 'explanation') ?? {},
      level: splitList(row.values.level),
      maxScore: numberValue(row.values.max_score) ?? 0,
      isDailyWarmUp:
        text(dailyWarmUpValue) === ''
          ? Boolean(existing.isDailyWarmUp)
          : parseBoolean(dailyWarmUpValue),
    };

    if (!isExerciseType(type)) return base;
    return buildByExerciseType(
      base,
      row,
      questionCode,
      optionRows,
      documentGroupRows,
      existing,
      cdn,
    );
  });
}

function buildByExerciseType(
  base: any,
  row: ImportRow,
  questionCode: string,
  optionRows: ImportRow[],
  documentGroupRows: ImportRow[],
  existing: ExerciseInput,
  cdn?: string,
) {
  const options = optionRows.filter(
    option => text(option.values.question_code) === questionCode,
  );

  if (
    base.type === ExerciseType.SINGLE_CHOICE ||
    base.type === ExerciseType.MULTIPLE_CHOICE
  ) {
    return {
      ...base,
      options: options.map(option => ({
        value: translationFromValues(option.values, 'value') ?? {},
        isCorrect: parseBoolean(option.values.is_correct),
      })),
    };
  }

  if (base.type === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) {
    return {
      ...base,
      options: options.map(option => ({
        value: translationFromValues(option.values, 'value') ?? {},
        documentGroupId: text(option.values.document_group_id),
      })),
      documentGroups: buildQuestionDocumentGroups(
        documentGroupRows,
        questionCode,
        cdn,
      ),
    };
  }

  if (base.type === ExerciseType.DRAG_DROP) {
    return {
      ...base,
      form: text(row.values.drag_form),
      targetArea:
        translationFromValues(row.values, 'target_area') ?? {},
      options: options.map((option, index) => ({
        id: index + 1,
        text: translationFromValues(option.values, 'value') ?? {},
      })),
      // Only option rows that actually carry an `answer` value are gap answers.
      // Distractor options (no answer column) must NOT produce empty answer
      // entries: the app treats answer[].length as the gap count and checks each
      // filled slot against answer[i].correctAnswer, so a phantom empty answer
      // adds an unfillable gap and marks every submission wrong (the "thừa ô
      // Answer" / wrong-check bug on imported Text Gap Filling questions).
      answer: options
        .filter(option =>
          hasTranslationValueForPrefix(option.values, 'answer'),
        )
        .map((option, index) => ({
          id: index + 1,
          correctAnswer:
            translationFromValues(option.values, 'answer') ?? {},
        })),
    };
  }

  if (base.type === ExerciseType.RECORD) {
    return {
      ...base,
      record: resolveAssetUrl(row.values.record_url, cdn),
      maxDuration: numberValue(row.values.record_max_duration),
      maxCharacter: numberValue(row.values.record_max_character),
      scoringCriteria: (existing as any).scoringCriteria ?? [],
    };
  }

  return base;
}

function parseBoolean(value: any) {
  return ['true', '1', 'yes'].includes(text(value).toLowerCase());
}
