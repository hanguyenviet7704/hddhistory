import { DocumentType, KeypointLevel } from "../../utils/enum/course.enum";
import { LangCode } from "../../types/enum/common.enum";
import {
  ExerciseType,
  FormDragDropType,
} from "../../types/enum/learningItem.enum";
import { ITranslation } from "../../utils/translate";
import {
  cleanTranslation,
  updateTranslationValue,
} from "../../utils/translation";
import {
  ExerciseInput,
  ExerciseInputPayload,
} from "../../types/interface/learning-item/learning-item.interface";
import {
  IAnswer,
  IExerciseDragDrop,
  IOptions,
} from "../../types/interface/learning-item/excercises/drag-drop.interface";
import {
  IExerciseChoiceOption,
  IExerciseSingleChoice,
} from "../../types/interface/learning-item/excercises/single-choice.interface";
import {
  IExerciseSingleChoiceNoCorrectAnswer,
  IExerciseSingleChoiceNoCorrectAnswerDocumentGroup,
  IExerciseSingleChoiceNoCorrectAnswerOption,
} from "../../types/interface/learning-item/excercises/single-choice-no-correct-answer.interface";
import { IExerciseMultipleChoice } from "../../types/interface/learning-item/excercises/multiple-choice.interface";
import {
  IExerciseRecord,
  IScoringCriteria,
} from "../../types/interface/learning-item/excercises/record.interface";
import {
  IDocument,
  IDocumentData,
} from "../../types/interface/learning-item/document.interface";

const TEXTUAL_DOCUMENT_TYPES: DocumentType[] = [
  DocumentType.TITLE,
  DocumentType.CAPTION,
  DocumentType.TEXT,
];

const DEFAULT_LEVELS: KeypointLevel[] = [
  KeypointLevel.WEAK_POINT,
  KeypointLevel.MORE_PRACTICE,
  KeypointLevel.OPTIONAL_PRACTICE,
];

const isValidNumber = (value: unknown): value is number =>
  typeof value === "number" && !Number.isNaN(value);

export const isTextualDocumentType = (type: DocumentType) =>
  TEXTUAL_DOCUMENT_TYPES.includes(type);

export const getDocumentContentLabel = (type: DocumentType) => {
  switch (type) {
    case DocumentType.TITLE:
      return "Title";
    case DocumentType.CAPTION:
      return "Caption";
    default:
      return "Content";
  }
};

export const createEmptyDocumentData = (
  currentLang: LangCode,
): IDocumentData => ({
  content: { [currentLang]: "" },
  url: { [currentLang]: "" },
  thumbnail: "",
});

export const createDefaultTextDocument = (
  currentLang: LangCode,
): IDocument => ({
  id: 1,
  type: DocumentType.TEXT,
  data: createEmptyDocumentData(currentLang),
});

const createDefaultDocumentsForQuestion = (
  type: ExerciseType,
  currentLang: LangCode,
): IDocument[] =>
  type === ExerciseType.DRAG_DROP
    ? []
    : [createDefaultTextDocument(currentLang)];

export const createEmptyExerciseInput = (
  type: ExerciseType,
  id: number,
  currentLang: LangCode,
): ExerciseInput => {
  const defaultDocuments = createDefaultDocumentsForQuestion(type, currentLang);

  switch (type) {
    case ExerciseType.SINGLE_CHOICE:
      return {
        id,
        type,
        tag: null,
        document: defaultDocuments,
        explanation: { [currentLang]: "" },
        options: [] as IExerciseChoiceOption[],
        level: [...DEFAULT_LEVELS],
        maxScore: 10,
      } as IExerciseSingleChoice;
    case ExerciseType.MULTIPLE_CHOICE:
      return {
        id,
        type,
        tag: null,
        document: defaultDocuments,
        explanation: { [currentLang]: "" },
        options: [] as IExerciseChoiceOption[],
        level: [...DEFAULT_LEVELS],
        maxScore: 10,
      } as IExerciseMultipleChoice;
    case ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER:
      return {
        id,
        exerciseId: "",
        type,
        tag: null,
        document: defaultDocuments,
        explanation: { [currentLang]: "" },
        options: [] as IExerciseSingleChoiceNoCorrectAnswerOption[],
        documentGroups:
          [] as IExerciseSingleChoiceNoCorrectAnswerDocumentGroup[],
        level: [...DEFAULT_LEVELS],
        maxScore: 10,
      } as IExerciseSingleChoiceNoCorrectAnswer;
    case ExerciseType.DRAG_DROP:
      return {
        id,
        type,
        form: FormDragDropType.TextGapFilling,
        tag: null,
        document: defaultDocuments,
        explanation: { [currentLang]: "" },
        targetArea: { [currentLang]: "" },
        answer: [] as IAnswer[],
        options: [] as IOptions[],
        level: [...DEFAULT_LEVELS],
        maxScore: 10,
      } as IExerciseDragDrop;
    case ExerciseType.RECORD:
      return {
        id,
        type,
        tag: null,
        document: defaultDocuments,
        explanation: { [currentLang]: "" },
        record: "",
        maxDuration: 30,
        scoringCriteria: [],
        level: [...DEFAULT_LEVELS],
        maxScore: 10,
      } as IExerciseRecord;
    default:
      return {
        id,
        type: ExerciseType.SINGLE_CHOICE,
        tag: null,
        document: defaultDocuments,
        explanation: { [currentLang]: "" },
        options: [] as IExerciseChoiceOption[],
        level: [...DEFAULT_LEVELS],
        maxScore: 10,
      } as IExerciseSingleChoice;
  }
};

export const cleanDocumentItems = (documents: IDocument[]) =>
  documents
    .map((doc) => {
      const cleanedContent = cleanTranslation(doc.data?.content);
      const cleanedUrl = cleanTranslation(doc.data?.url);
      const cleanedData: Partial<IDocumentData> = { ...doc.data };

      if (cleanedContent && Object.keys(cleanedContent).length > 0) {
        cleanedData.content = cleanedContent;
      } else {
        delete cleanedData.content;
      }

      if (cleanedUrl && Object.keys(cleanedUrl).length > 0) {
        cleanedData.url = cleanedUrl;
      } else {
        delete cleanedData.url;
      }

      if (!cleanedData.thumbnail) delete cleanedData.thumbnail;

      const hasValue =
        (isTextualDocumentType(doc.type) &&
          !!cleanedData.content &&
          Object.keys(cleanedData.content).length > 0) ||
        ((doc.type === DocumentType.IMAGE ||
          doc.type === DocumentType.AUDIO ||
          doc.type === DocumentType.ANIMATION) &&
          !!cleanedData.url) ||
        (doc.type === DocumentType.VIDEO &&
          (!!cleanedData.url || !!cleanedData.thumbnail));

      return hasValue ? ({ ...doc, data: cleanedData as IDocumentData } as IDocument) : null;
    })
    .filter(Boolean) as IDocument[];

export const cleanDocumentGroups = (
  groups?: IExerciseSingleChoiceNoCorrectAnswerDocumentGroup[],
) => {
  if (!Array.isArray(groups)) return [];
  return groups
    .map((group) => ({
      ...group,
      id: group.id || "",
      documents: cleanDocumentItems(group.documents || []),
    }))
    .filter((group) => {
      const hasId = typeof group.id === "string" && group.id.trim().length > 0;
      const hasDocs = group.documents.length > 0;
      return hasId || hasDocs;
    });
};

export const rebalanceRecordScoringCriteria = (
  criteriaInput?: Partial<IScoringCriteria>[],
  exerciseMaxScore?: number,
): IScoringCriteria[] => {
  const sanitized =
    criteriaInput?.map((item) => ({
      criteria: (item.criteria ?? { en: "" }) as ITranslation,
      maxScore: isValidNumber(item.maxScore)
        ? Math.max(0, Math.round(item.maxScore))
        : 0,
    })) || [];

  if (!sanitized.length) return [];
  if (!isValidNumber(exerciseMaxScore)) return sanitized;

  const result = sanitized.map((item) => ({ ...item }));
  const lastIndex = result.length - 1;
  let manualSum = 0;

  result.forEach((item, index) => {
    if (index === lastIndex) return;
    item.maxScore = isValidNumber(item.maxScore)
      ? Math.max(0, Math.round(item.maxScore))
      : 0;
    manualSum += item.maxScore;
  });

  result[lastIndex].maxScore = Math.max(
    0,
    Math.round(exerciseMaxScore) - manualSum,
  );

  return result;
};

export const convertExerciseInputToPayload = (
  question: ExerciseInput,
): ExerciseInputPayload => {
  const questionData = question as any;
  const { tag, speechBubble, ...questionWithoutTag } = questionData;
  const convertedQuestion: any = {
    ...questionWithoutTag,
    tagId: questionData.tag?._id || "",
  };

  const cleanedExplanation = cleanTranslation(questionData.explanation);
  if (cleanedExplanation) convertedQuestion.explanation = cleanedExplanation;

  const cleanedTargetArea = cleanTranslation(questionData.targetArea);
  if (cleanedTargetArea) convertedQuestion.targetArea = cleanedTargetArea;

  if (Array.isArray(questionData.options)) {
    convertedQuestion.options = questionData.options.map((opt: any) => {
      const cleanedOption = { ...opt };
      const cleanedValue = cleanTranslation(opt.value);
      if (cleanedValue) cleanedOption.value = cleanedValue;
      const cleanedText = cleanTranslation(opt.text);
      if (cleanedText) cleanedOption.text = cleanedText;
      return cleanedOption;
    });
  }

  if (Array.isArray(questionData.answer)) {
    convertedQuestion.answer = questionData.answer.map((ans: any) => {
      const cleanedAnswer = { ...ans };
      const cleanedCorrectAnswer = cleanTranslation(ans.correctAnswer);
      if (cleanedCorrectAnswer) {
        cleanedAnswer.correctAnswer = cleanedCorrectAnswer;
      }
      return cleanedAnswer;
    });
  }

  const cleanedDocuments = questionData.document?.length
    ? cleanDocumentItems(questionData.document)
    : [];
  if (cleanedDocuments.length > 0) {
    convertedQuestion.document = cleanedDocuments;
  }

  if (questionData.type === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) {
    convertedQuestion.documentGroups = cleanDocumentGroups(
      questionData.documentGroups || [],
    );
  }

  if (questionData.type === ExerciseType.RECORD) {
    convertedQuestion.scoringCriteria = rebalanceRecordScoringCriteria(
      questionData.scoringCriteria,
      questionData.maxScore,
    );
  }

  return convertedQuestion as ExerciseInputPayload;
};

export const ensureTranslation = (
  value: ITranslation | string | undefined,
  lang: LangCode,
) => {
  if (!value) return { [lang]: "" };
  if (typeof value === "string") {
    return updateTranslationValue(undefined, lang, value);
  }
  return value;
};
