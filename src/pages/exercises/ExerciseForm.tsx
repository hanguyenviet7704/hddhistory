import React, { useState, useEffect } from "react";
import {
  ILearningItem,
  LearningItemPayload,
} from "../../types/interface/learning-item/learning-item.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { learningItemService } from "../../services/learningItemService";
import {
  LearningItemType,
  ExerciseType,
  FormDragDropType,
} from "../../types/enum/learningItem.enum";
import { PlusCircleIcon, TrashIcon } from "@heroicons/react/24/outline";
import { PlusIcon } from "lucide-react";
import { PuzzlePieceIcon, XMarkIcon } from "@heroicons/react/24/solid";
import { motion, AnimatePresence } from "framer-motion";
import { DndContext, closestCenter } from "@dnd-kit/core";
import {
  arrayMove,
  SortableContext,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import SortableItem from "../../components/common/SortableItem";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { Combobox } from "@headlessui/react";
import { useNavigate } from "react-router-dom";
import LearningItemConfirm from "../../components/learning-item/LearningItemConfirm";
import { keypointService } from "../../services/keypointService";
import { DocumentType, KeypointLevel } from "../../utils/enum/course.enum";
import {
  IExerciseChoiceOption,
  IExerciseSingleChoice,
} from "../../types/interface/learning-item/excercises/single-choice.interface";
import {
  IExerciseSingleChoiceNoCorrectAnswer,
  IExerciseSingleChoiceNoCorrectAnswerOption,
  IExerciseSingleChoiceNoCorrectAnswerDocumentGroup,
} from "../../types/interface/learning-item/excercises/single-choice-no-correct-answer.interface";
import { IExerciseMultipleChoice } from "../../types/interface/learning-item/excercises/multiple-choice.interface";
import {
  IAnswer,
  IExerciseDragDrop,
  IOptions,
} from "../../types/interface/learning-item/excercises/drag-drop.interface";
import { IExerciseRecord } from "../../types/interface/learning-item/excercises/record.interface";
import {
  IDocument,
  IDocumentData,
} from "../../types/interface/learning-item/document.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { ITag } from "../../types/interface/tag.interface";
import { ITranslation } from "../../utils/translate";
import {
  getTranslationValue,
  getCurrentTranslationValue,
  updateTranslationValue,
  cleanTranslation,
} from "../../utils/translation";
import { LangCode } from "../../types/enum/common.enum";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";
import { IScoringCriteria } from "../../types/interface/learning-item/excercises/record.interface";

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

const rebalanceRecordScoringCriteria = (
  criteriaInput?: Partial<IScoringCriteria>[],
  exerciseMaxScore?: number,
  lang?: LangCode,
): IScoringCriteria[] => {
  const sanitized =
    criteriaInput?.map((item) => ({
      criteria: (item.criteria ?? { en: "" }) as ITranslation,
      maxScore: isValidNumber(item.maxScore)
        ? Math.max(0, Math.round(item.maxScore))
        : 0,
    })) || [];

  if (!sanitized.length) return [];

  if (!isValidNumber(exerciseMaxScore)) {
    return sanitized.map((item) => ({
      ...item,
      maxScore: isValidNumber(item.maxScore) ? item.maxScore : 0,
    }));
  }

  const lastIndex = sanitized.length - 1;
  if (lastIndex < 0) return [];

  const result = sanitized.map((item) => ({ ...item }));

  const manualIndices = result
    .map((_, idx) => idx)
    .filter((idx) => idx !== lastIndex);

  let manualSum = 0;
  manualIndices.forEach((idx) => {
    const val = result[idx].maxScore;
    const normalized = isValidNumber(val) ? Math.max(0, Math.round(val)) : 0;
    result[idx].maxScore = normalized;
    manualSum += normalized;
  });

  const remaining = Math.max(0, Math.round(exerciseMaxScore) - manualSum);
  result[lastIndex].maxScore = remaining;

  return result;
};

const isTextualDocumentType = (type: DocumentType) =>
  TEXTUAL_DOCUMENT_TYPES.includes(type);

const cleanDocumentItems = (documents: IDocument[]) => {
  return documents
    .map((doc) => {
      const cleanedContent = cleanTranslation(doc.data?.content);
      const cleanedUrl = cleanTranslation(doc.data?.url);
      const cleanedData: any = { ...doc.data };
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
      if (!cleanedData.thumbnail) {
        delete cleanedData.thumbnail;
      }

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

      return hasValue ? ({ ...doc, data: cleanedData } as IDocument) : null;
    })
    .filter(Boolean) as IDocument[];
};

const cleanDocumentGroups = (
  groups?: IExerciseSingleChoiceNoCorrectAnswerDocumentGroup[],
): IExerciseSingleChoiceNoCorrectAnswerDocumentGroup[] => {
  if (!Array.isArray(groups)) return [];
  return groups
    .map((group) => ({
      ...group,
      id: group.id || "",
      documents: cleanDocumentItems(group.documents || []),
    }))
    .filter((group) => {
      const hasId = typeof group.id === "string" && group.id.trim().length > 0;
      const hasDocs = group.documents && group.documents.length > 0;
      return hasId || hasDocs;
    });
};

const getDocumentContentLabel = (type: DocumentType) => {
  switch (type) {
    case DocumentType.TITLE:
      return "Title";
    case DocumentType.CAPTION:
      return "Caption";
    default:
      return "Content";
  }
};

const createEmptyDocumentData = (currentLang: LangCode): IDocumentData => ({
  content: { [currentLang]: "" },
  url: { [currentLang]: "" },
  thumbnail: "",
});

const createDefaultTextDocument = (currentLang: LangCode): IDocument => ({
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

// Helper component to display text with truncation and tooltip
const TextWithTooltip = ({
  text = "",
  maxLength = 100,
  lang = LangCode.EN,
}: {
  text?: string | ITranslation;
  maxLength?: number;
  lang?: LangCode;
}) => {
  if (!text) return null;

  const displayText =
    typeof text === "string" ? text : getTranslationValue(text, lang);

  if (!displayText) return null;

  return (
    <div className="relative group">
      <span className="truncate inline-block max-w-xl">
        {displayText.length > maxLength
          ? `${displayText.substring(0, maxLength)}...`
          : displayText}
      </span>
      {displayText.length > maxLength && (
        <div className="absolute bottom-full left-0 mb-2 hidden group-hover:block z-10 bg-gray-800 text-white text-xs rounded py-2 px-3 w-64 max-h-40 overflow-y-auto shadow-lg">
          {displayText}
        </div>
      )}
    </div>
  );
};

// Helper component to display tag with icon and title
const TagDisplay = ({ tag, lang }: { tag: ITag | null; lang: LangCode }) => {
  if (!tag) return null;

  return (
    <div className="flex items-center gap-1">
      {tag.url && (
        <img
          src={tag.url}
          alt={tag.title?.[lang] || "Tag url"}
          className="w-5 h-5 object-contain flex-shrink-0"
        />
      )}
      <span>{tag.title?.[lang]}</span>
    </div>
  );
};

interface ExerciseFormProps {
  exercise?: ILearningItem;
  onSave?: (exercise: ILearningItem) => void;
  onCancel?: () => void;
}

export default function ExerciseForm({
  exercise,
  onSave,
  onCancel,
}: ExerciseFormProps) {
  const navigate = useNavigate();
  const lang = useSelector(
    (state: RootState) => state.lang.code,
  ) as keyof ITranslation as LangCode;
  const isEditMode = !!exercise;
  const { showSuccess, showError } = useNotification();

  // State for keypoint search
  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [keypointQuery, setKeypointQuery] = useState("");
  const [selectedKeypoint, setSelectedKeypoint] = useState<IKeypoint | null>(
    null,
  );

  // State for question ID counters - separate for each section
  const [nextQuestionIdForQuestions, setNextQuestionIdForQuestions] =
    useState(1);
  const [nextQuestionIdForSubQuestions, setNextQuestionIdForSubQuestions] =
    useState(1);

  // State for drag-drop option and answer ID counters (these are global, which is correct)
  const [nextOptionId, setNextOptionId] = useState(1);
  const [nextAnswerId, setNextAnswerId] = useState(1);

  // Sync exercise prop -> local state (important when fetch async)
  const [currentExercise, setCurrentExercise] = useState<ILearningItem>(
    () =>
      exercise ??
      ({
        _id: "",
        keypointId: "",
        type: LearningItemType.EXERCISE,
        title: { [lang]: "" },
        image: "",
        isSub: false,
        tag: [],
        questions: [],
        subQuestions: [],
        documents: [],
        index: 0,
      } as ILearningItem),
  );

  useEffect(() => {
    if (exercise) {
      // Find max question ID for each section and set nextQuestionId accordingly
      const maxQuestionIdForQuestions = [...exercise.questions].reduce(
        (max, q) => Math.max(max, q.id ?? 0),
        0,
      );
      setNextQuestionIdForQuestions(maxQuestionIdForQuestions + 1);

      const maxQuestionIdForSubQuestions = [...exercise.subQuestions].reduce(
        (max, q) => Math.max(max, q.id ?? 0),
        0,
      );
      setNextQuestionIdForSubQuestions(maxQuestionIdForSubQuestions + 1);

      // Find max option and answer IDs for drag-drop questions (global)
      const maxOptionId = [...exercise.questions, ...exercise.subQuestions]
        .filter((q) => q.type === ExerciseType.DRAG_DROP)
        .flatMap((q) => (q as IExerciseDragDrop).options || [])
        .reduce((max, opt) => Math.max(max, opt.id || 0), 0);
      setNextOptionId(maxOptionId + 1);

      const maxAnswerId = [...exercise.questions, ...exercise.subQuestions]
        .filter((q) => q.type === ExerciseType.DRAG_DROP)
        .flatMap((q) => (q as IExerciseDragDrop).answer || [])
        .reduce((max, ans) => Math.max(max, ans.id || 0), 0);
      const startOptionId = maxOptionId + 1;
      const startAnswerId = maxAnswerId + 1;
      setNextOptionId(startOptionId);
      setNextAnswerId(startAnswerId);

      let optionCounter = startOptionId;
      let answerCounter = startAnswerId;

      const normalizeDragDropIds = (q: any) => {
        if (q.type !== ExerciseType.DRAG_DROP) return q;
        const normalizedOptions = (q.options || []).map((opt: any) =>
          opt && opt.id ? opt : { ...opt, id: optionCounter++ },
        );
        const normalizedAnswers = (q.answer || []).map((ans: any) =>
          ans && ans.id ? ans : { ...ans, id: answerCounter++ },
        );
        return { ...q, options: normalizedOptions, answer: normalizedAnswers };
      };

      const normalizedQuestions = exercise.questions.map(normalizeDragDropIds);
      const normalizedSubQuestions =
        exercise.subQuestions.map(normalizeDragDropIds);

      setNextOptionId(optionCounter);
      setNextAnswerId(answerCounter);
      setCurrentExercise({
        ...exercise,
        questions: normalizedQuestions,
        subQuestions: normalizedSubQuestions,
      });
    }
  }, [exercise]); // Remove lang from dependency to prevent reset on language change

  // Separate effect to update title language when creating new exercise
  useEffect(() => {
    if (!exercise && currentExercise._id === "") {
      // Only update the title field to ensure it has the current language
      setCurrentExercise((prev) => ({
        ...prev,
        title: { [lang]: (prev.title as ITranslation)?.[lang] || "" },
      }));
    }
  }, [lang, exercise, currentExercise._id]);

  const [saving, setSaving] = useState(false);
  const [modalOpen, setModalOpen] = useState<{
    section: "questions" | "subQuestions" | null;
    questionType: ExerciseType;
    question?: any;
    formData?: any;
  }>({ section: null, questionType: ExerciseType.SINGLE_CHOICE });
  const [confirmDeleteQuestion, setConfirmDeleteQuestion] = useState<{
    section: "questions" | "subQuestions";
    itemId: number | null;
    itemTitle: string;
  } | null>(null);

  const [confirmDeleteExercise, setConfirmDeleteExercise] = useState(false);
  const [showExerciseTypePopup, setShowExerciseTypePopup] = useState(false);
  const [currentSectionForPopup, setCurrentSectionForPopup] = useState<
    "questions" | "subQuestions" | null
  >(null);

  // Fetch keypoint based on query
  useEffect(() => {
    let active = true;
    const fetchKeypoints = async () => {
      try {
        const res = await keypointService.getList({
          page: 1,
          take: 20,
          search: keypointQuery,
        });
        const list: IKeypoint[] = res.data.items ?? [];
        if (active) setKeypoints(list);
      } catch (err) {
        console.error("fetchKeypoints", err);
      }
    };
    fetchKeypoints();
    return () => {
      active = false;
    };
  }, [keypointQuery]);

  // Fetch selected keypoint details when keypointId changes
  useEffect(() => {
    if (currentExercise.keypointId) {
      const fetchKeypointDetail = async () => {
        try {
          const res = await keypointService.getById(currentExercise.keypointId);

          if (res.data) {
            setSelectedKeypoint(res.data);
          }
        } catch (err) {
          console.error("fetchKeypointDetail", err);
        }
      };
      fetchKeypointDetail();
    } else {
      setSelectedKeypoint(null);
    }
  }, [currentExercise.keypointId]);

  // Helper function to convert questions to payload format
  const convertQuestionsToPayload = (questions: any[]) => {
    return questions.map((question) => {
      // Convert tag from ITag to string (ID)
      const tagId = question.tag?._id || "";

      // Clean ITranslation fields
      const { tag, speechBubble, ...questionWithoutTag } = question;
      const convertedQuestion: any = {
        ...questionWithoutTag,
        tagId,
      };

      const cleanedExplanation = cleanTranslation(question.explanation);
      if (cleanedExplanation) {
        convertedQuestion.explanation = cleanedExplanation;
      }

      const cleanedTargetArea = cleanTranslation(question.targetArea);
      if (cleanedTargetArea) {
        convertedQuestion.targetArea = cleanedTargetArea;
      }

      // Process options with translations
      if (question.options?.length) {
        convertedQuestion.options = question.options.map((opt: any) => {
          const cleanedOption: any = { ...opt };
          const cleanedValue = cleanTranslation(opt.value);
          if (cleanedValue) {
            cleanedOption.value = cleanedValue;
          }
          const cleanedText = cleanTranslation(opt.text);
          if (cleanedText) {
            cleanedOption.text = cleanedText;
          }
          return cleanedOption;
        });
      }

      // Process answers with translations
      if (question.answer?.length) {
        convertedQuestion.answer = question.answer.map((ans: any) => {
          const cleanedAnswer: any = { ...ans };
          const cleanedCorrectAnswer = cleanTranslation(ans.correctAnswer);
          if (cleanedCorrectAnswer) {
            cleanedAnswer.correctAnswer = cleanedCorrectAnswer;
          }
          return cleanedAnswer;
        });
      }

      // Process documents with translations
      const cleanedDocuments = question.document?.length
        ? cleanDocumentItems(question.document)
        : [];
      if (cleanedDocuments.length > 0) {
        convertedQuestion.document = cleanedDocuments;
      }

      if (question.type === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) {
        convertedQuestion.documentGroups = cleanDocumentGroups(
          question.documentGroups || [],
        );
      }

      return convertedQuestion;
    });
  };

  // Save entire exercise (create or update)
  const handleSaveExercise = async () => {
    try {
      setSaving(true);
      const payload: LearningItemPayload = {
        keypointId: currentExercise.keypointId,
        title: cleanTranslation(currentExercise.title) || {},
        type: LearningItemType.EXERCISE,
        image: currentExercise.image,
        tag: currentExercise.tag || [],
        isSub: currentExercise.isSub,
        questions: convertQuestionsToPayload(currentExercise.questions || []),
        subQuestions: convertQuestionsToPayload(
          currentExercise.subQuestions || [],
        ),
        index: currentExercise.index,
      };

      let res;
      if (currentExercise._id) {
        res = await learningItemService.update(currentExercise._id, payload);
      } else {
        res = await learningItemService.create(payload);
      }

      const savedExercise = res.data?.data ?? res.data;
      await new Promise((resolve) => setTimeout(resolve, 500));
      onSave?.(savedExercise);

      isEditMode
        ? showSuccess("Saved exercise successfully")
        : showSuccess("Create exercise successfully");
    } catch (err) {
      console.error("handleSaveExercise", err);
      showError(
        (err as any).response?.data?.message || "Failed to save exercise",
      );
    } finally {
      setSaving(false);
    }
  };

  // Reorder questions and reassign IDs
  const handleReorder = (
    section: "questions" | "subQuestions" | null,
    activeId: number,
    overId: number,
  ) => {
    if (!section) return;

    setCurrentExercise((prev) => {
      if (!prev) return prev;
      const list = prev[section] || [];

      const activeIndex = list.findIndex((item) => item.id === activeId);
      const overIndex = list.findIndex((item) => item.id === overId);

      if (activeIndex === -1 || overIndex === -1 || activeIndex === overIndex) {
        return prev;
      }

      const newList = arrayMove(list, activeIndex, overIndex);

      // Reassign IDs starting from 1
      const reassignedList = newList.map((item, index) => ({
        ...item,
        id: index + 1,
      }));

      // Update the next ID for this section
      if (section === "questions") {
        setNextQuestionIdForQuestions(reassignedList.length + 1);
      } else if (section === "subQuestions") {
        setNextQuestionIdForSubQuestions(reassignedList.length + 1);
      }

      return { ...prev, [section]: reassignedList };
    });
  };

  // Open exercise type popup
  const handleOpenExerciseTypePopup = (
    section: "questions" | "subQuestions",
  ) => {
    setCurrentSectionForPopup(section);
    setShowExerciseTypePopup(true);
  };

  // Select exercise type and open question form
  const handleSelectExerciseType = (questionType: ExerciseType) => {
    if (!currentSectionForPopup) return;

    // Get the appropriate next ID based on section
    const nextId =
      currentSectionForPopup === "questions"
        ? nextQuestionIdForQuestions
        : currentSectionForPopup === "subQuestions"
          ? nextQuestionIdForSubQuestions
          : 0;

    const formData = createEmptyQuestion(questionType, nextId);

    setModalOpen({
      section: currentSectionForPopup,
      questionType,
      formData,
    });

    setShowExerciseTypePopup(false);
    setCurrentSectionForPopup(null);
  };

  const handleOpenModal = (
    section: "questions" | "subQuestions",
    questionType: ExerciseType,
    question?: any,
  ) => {
    // Get the appropriate next ID based on section
    const nextId =
      section === "questions"
        ? nextQuestionIdForQuestions
        : section === "subQuestions"
          ? nextQuestionIdForSubQuestions
          : 0;

    // If there is question data (editing), copy the data
    // If not (adding new), create empty question
    const formData = question
      ? { ...question }
      : createEmptyQuestion(questionType, nextId);

    // Open modal with corresponding information
    setModalOpen({ section, questionType, question, formData });
  };

  // Create empty question based on type
  const createEmptyQuestion = (
    type: ExerciseType,
    id: number,
    currentLang: LangCode = lang,
  ) => {
    const defaultDocuments = createDefaultDocumentsForQuestion(
      type,
      currentLang,
    );
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
          completionTime: 60,
          mainQuestion: 0,
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
          completionTime: 60,
          mainQuestion: 0,
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
          completionTime: 60,
          mainQuestion: 0,
        } as IExerciseSingleChoiceNoCorrectAnswer;
      case ExerciseType.DRAG_DROP:
        return {
          id,
          type,
          tag: null,
          document: defaultDocuments,
          explanation: { [currentLang]: "" },
          targetArea: { [currentLang]: "" },
          answer: [] as IAnswer[],
          options: [] as IOptions[],
          level: [...DEFAULT_LEVELS],
          maxScore: 10,
          completionTime: 60,
          form: FormDragDropType.TextGapFilling,
          mainQuestion: 0,
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
          completionTime: 60,
          mainQuestion: 0,
        } as IExerciseRecord;
      default:
        return null;
    }
  };

  // Request delete question
  const requestDeleteQuestion = (
    section: "questions" | "subQuestions",
    itemId: number,
    itemTitle = "question",
  ) => {
    setConfirmDeleteQuestion({ section, itemId, itemTitle });
  };

  // Delete entire exercise
  const handleDeleteExercise = async () => {
    if (!currentExercise._id) return;
    try {
      await learningItemService.remove(currentExercise._id);
      setConfirmDeleteExercise(false);
      if (onCancel) {
        onCancel();
      } else {
        navigate("/exercise");
      }
    } catch (err) {
      console.error(err);
    } finally {
      setConfirmDeleteExercise(false);
    }
  };

  // Handle saving question and exercise together
  const handleSaveQuestionAndExercise = async (questionData: any) => {
    try {
      setSaving(true);

      let updatedExercise;
      if (modalOpen.question) {
        // Update existing question
        const section = modalOpen.section!;
        const existing = currentExercise[section] || [];
        const updatedList = existing.map((q) =>
          q.id === questionData.id ? questionData : q,
        );
        updatedExercise = { ...currentExercise, [section]: updatedList };
      } else {
        // Add new question
        const section = modalOpen.section!;
        const existing = currentExercise[section] || [];
        updatedExercise = {
          ...currentExercise,
          [section]: [...existing, questionData],
        };

        // Update the next ID for this section
        if (section === "questions") {
          setNextQuestionIdForQuestions(nextQuestionIdForQuestions + 1);
        } else if (section === "subQuestions") {
          setNextQuestionIdForSubQuestions(nextQuestionIdForSubQuestions + 1);
        }
      }

      setCurrentExercise(updatedExercise);

      const payload: LearningItemPayload = {
        keypointId: updatedExercise.keypointId,
        title: cleanTranslation(updatedExercise.title) || {},
        type: LearningItemType.EXERCISE,
        image: updatedExercise.image,
        tag: updatedExercise.tag || [],
        isSub: updatedExercise.isSub,
        questions: convertQuestionsToPayload(updatedExercise.questions || []),
        subQuestions: convertQuestionsToPayload(
          updatedExercise.subQuestions || [],
        ),
        index: updatedExercise.index,
      };

      if (updatedExercise._id) {
        await learningItemService.update(updatedExercise._id, payload);
      } else {
        const res = await learningItemService.create(payload);
        const savedExercise = res.data?.data ?? res.data;
        setCurrentExercise(savedExercise);
        onSave?.(savedExercise);
      }

      showSuccess("Question saved successfully");
      setModalOpen({ section: null, questionType: ExerciseType.SINGLE_CHOICE });
    } catch (err) {
      console.error("handleSaveQuestionAndExercise", err);
      showError(
        (err as any).response?.data?.message || "Failed to save question",
      );
    } finally {
      setSaving(false);
    }
  };

  // Handle deleting question and saving exercise together
  const handleDeleteQuestionAndSaveExercise = async () => {
    if (!confirmDeleteQuestion) return;
    const { section, itemId } = confirmDeleteQuestion;
    if (!section || !itemId) {
      setConfirmDeleteQuestion(null);
      return;
    }

    try {
      setSaving(true);

      const newList = (currentExercise[section] || []).filter(
        (q) => q.id !== itemId,
      );

      const reassignedList = newList.map((item, index) => ({
        ...item,
        id: index + 1,
      }));

      if (section === "questions") {
        setNextQuestionIdForQuestions(reassignedList.length + 1);
      } else if (section === "subQuestions") {
        setNextQuestionIdForSubQuestions(reassignedList.length + 1);
      }

      const updatedExercise = { ...currentExercise, [section]: reassignedList };
      setCurrentExercise(updatedExercise);

      const payload: LearningItemPayload = {
        keypointId: updatedExercise.keypointId,
        title: cleanTranslation(updatedExercise.title) || {},
        type: LearningItemType.EXERCISE,
        image: updatedExercise.image,
        tag: updatedExercise.tag || [],
        isSub: updatedExercise.isSub,
        questions: convertQuestionsToPayload(updatedExercise.questions || []),
        subQuestions: convertQuestionsToPayload(
          updatedExercise.subQuestions || [],
        ),
        index: updatedExercise.index,
      };

      if (updatedExercise._id) {
        await learningItemService.update(updatedExercise._id, payload);
      }

      showSuccess("Question deleted successfully");
      setConfirmDeleteQuestion(null);
    } catch (err) {
      console.error("handleDeleteQuestionAndSaveExercise", err);
      showError(
        (err as any).response?.data?.message || "Failed to delete question",
      );
    } finally {
      setSaving(false);
    }
  };

  // Render questions section with drag and drop
  const renderQuestionsSection = (
    section: "questions" | "subQuestions",
    title: string,
  ) => {
    const list = currentExercise[section] || [];

    return (
      <div className="mb-6 bg-gray-50 rounded-xl p-6 shadow-sm">
        <div className="flex justify-start gap-3 mb-4">
          <h2 className="text-xl font-semibold text-gray-800">{title}</h2>
        </div>

        <p className="text-sm text-gray-500 mb-4">
          👉 Drag to reorder. Click on item to edit.
        </p>

        <DndContext
          collisionDetection={closestCenter}
          onDragEnd={(event) => {
            const { active, over } = event;

            if (over && active.id !== over.id) {
              const activeId =
                typeof active.id === "string" ? parseInt(active.id) : active.id;
              const overId =
                typeof over.id === "string" ? parseInt(over.id) : over.id;

              handleReorder(section, activeId, overId);
            }
          }}
        >
          <SortableContext
            items={list.map((item) => item.id!.toString())}
            strategy={verticalListSortingStrategy}
          >
            {list.length > 0 ? (
              <div className="space-y-3">
                {list.map((question) => (
                  <SortableItem key={question.id} id={question.id!.toString()}>
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                    >
                      <div className="flex items-start gap-3">
                        <div className="flex-shrink-0 mt-1">
                          <PuzzlePieceIcon className="h-6 w-6 text-yellow-500" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between mb-2">
                            <h3 className="font-medium text-gray-800 truncate">
                              Question {question.id} ({question.type})
                            </h3>
                            <div className="flex gap-1">
                              <button
                                onClick={() =>
                                  handleOpenModal(
                                    section,
                                    question.type || ExerciseType.SINGLE_CHOICE,
                                    question,
                                  )
                                }
                                className="text-blue-600 hover:text-blue-800 p-1 rounded"
                                title="Edit"
                              >
                                <svg
                                  xmlns="http://www.w3.org/2000/svg"
                                  className="h-5 w-5"
                                  viewBox="0 0 20 20"
                                  fill="currentColor"
                                >
                                  <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                                </svg>
                              </button>
                              <button
                                onClick={() =>
                                  requestDeleteQuestion(
                                    section,
                                    question.id || 0,
                                    `Question ${question.id}`,
                                  )
                                }
                                className="text-red-500 hover:text-red-700 p-1 rounded"
                                title="Delete"
                              >
                                <TrashIcon className="h-5 w-5" />
                              </button>
                            </div>
                          </div>

                          <div className="text-sm text-gray-600 space-y-1">
                            {question.tag && (
                              <div className="flex items-start">
                                <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                  Tag:
                                </span>
                                <TagDisplay tag={question.tag} lang={lang} />
                              </div>
                            )}

                            {question.mainQuestion !== undefined &&
                              question.mainQuestion !== null && (
                                <div className="flex items-start">
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Main question:
                                  </span>
                                  <TextWithTooltip
                                    text={
                                      question.mainQuestion?.toString() || ""
                                    }
                                  />
                                </div>
                              )}

                            {question.document &&
                              question.document.length > 0 && (
                                <div className="mt-2 p-2 bg-gray-50 rounded">
                                  <span className="font-medium text-gray-700">
                                    Content:
                                  </span>
                                  {question.document.map(
                                    (doc: IDocument, index: number) => (
                                      <div
                                        key={index}
                                        className="ml-2 mt-1 text-xs"
                                      >
                                        <span className="font-semibold text-green-600">
                                          {doc.type.toUpperCase()}
                                        </span>
                                        {isTextualDocumentType(doc.type) &&
                                          doc.data.content && (
                                            <div className="ml-1">
                                              <TextWithTooltip
                                                text={doc.data.content}
                                                maxLength={50}
                                                lang={lang}
                                              />
                                            </div>
                                          )}
                                        {doc.type === DocumentType.IMAGE &&
                                          getTranslationValue(
                                            doc.data.url,
                                            lang,
                                          ) && (
                                            <div className="ml-1">
                                              <TextWithTooltip
                                                text={doc.data.url}
                                                maxLength={50}
                                                lang={lang}
                                              />
                                            </div>
                                          )}
                                        {doc.type === DocumentType.AUDIO &&
                                          getTranslationValue(
                                            doc.data.url,
                                            lang,
                                          ) && (
                                            <div className="ml-1">
                                              <TextWithTooltip
                                                text={doc.data.url}
                                                maxLength={50}
                                                lang={lang}
                                              />
                                            </div>
                                          )}
                                        {doc.type === DocumentType.VIDEO && (
                                          <>
                                            {getTranslationValue(
                                              doc.data.url,
                                              lang,
                                            ) && (
                                              <div className="ml-1">
                                                <TextWithTooltip
                                                  text={doc.data.url}
                                                  maxLength={50}
                                                  lang={lang}
                                                />
                                              </div>
                                            )}
                                          </>
                                        )}
                                      </div>
                                    ),
                                  )}
                                </div>
                              )}

                            {question.explanation && (
                              <div className="flex items-start">
                                <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                  Explanation:
                                </span>
                                <TextWithTooltip
                                  text={question.explanation}
                                  lang={lang}
                                />
                              </div>
                            )}

                            {(question.type === ExerciseType.SINGLE_CHOICE ||
                              question.type === ExerciseType.MULTIPLE_CHOICE) &&
                              Array.isArray((question as any).options) && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Options:
                                  </span>
                                  <ul className="mt-1 space-y-1">
                                    {(question as any).options.map(
                                      (opt: any, idx: number) => (
                                        <li
                                          key={idx}
                                          className="flex items-center"
                                        >
                                          <span
                                            className={`w-3 h-3 rounded-full mr-2 ${
                                              opt.isCorrect
                                                ? "bg-green-500"
                                                : "bg-gray-300"
                                            }`}
                                          ></span>
                                          <TextWithTooltip
                                            text={opt.value}
                                            lang={lang}
                                          />
                                        </li>
                                      ),
                                    )}
                                  </ul>
                                </div>
                              )}

                            {question.type ===
                              ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER &&
                              Array.isArray((question as any).options) && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Options:
                                  </span>
                                  <ul className="mt-1 space-y-1">
                                    {(question as any).options.map(
                                      (opt: any, idx: number) => (
                                        <li
                                          key={idx}
                                          className="flex items-center gap-2"
                                        >
                                          <TextWithTooltip
                                            text={opt.value}
                                            lang={lang}
                                          />
                                          {opt.documentGroupId && (
                                            <span className="text-xs text-gray-500">
                                              ({opt.documentGroupId})
                                            </span>
                                          )}
                                        </li>
                                      ),
                                    )}
                                  </ul>
                                </div>
                              )}

                            {question.type ===
                              ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER &&
                              Array.isArray((question as any).documentGroups) &&
                              (question as any).documentGroups.length > 0 && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Document Groups:
                                  </span>
                                  <div className="flex flex-wrap gap-2 mt-1">
                                    {(question as any).documentGroups.map(
                                      (group: any, idx: number) => (
                                        <span
                                          key={`${group.id || "group"}-${idx}`}
                                          className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-sky-100 text-sky-800"
                                        >
                                          {group.id || "Untitled"}
                                        </span>
                                      ),
                                    )}
                                  </div>
                                </div>
                              )}

                            {question.type === ExerciseType.DRAG_DROP && (
                              <div>
                                <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                  Form Type:
                                </span>
                                {"form" in question && (
                                  <span>
                                    {question.form || "Not specified"}
                                  </span>
                                )}
                              </div>
                            )}

                            {question.type === ExerciseType.DRAG_DROP &&
                              "targetArea" in question && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Target Area:
                                  </span>
                                  <TextWithTooltip
                                    text={question.targetArea}
                                    lang={lang}
                                  />
                                </div>
                              )}

                            {question.type === ExerciseType.DRAG_DROP &&
                              "options" in question &&
                              Array.isArray(question.options) &&
                              question.options.length > 0 && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Options:
                                  </span>
                                  <ul className="mt-1 space-y-1">
                                    {question.options.map(
                                      (opt: any, idx: number) => (
                                        <li
                                          key={opt.id || idx}
                                          className="flex items-center"
                                        >
                                          <TextWithTooltip
                                            text={opt.text}
                                            lang={lang}
                                          />
                                        </li>
                                      ),
                                    )}
                                  </ul>
                                </div>
                              )}

                            {question.type === ExerciseType.DRAG_DROP &&
                              "answer" in question &&
                              Array.isArray(question.answer) &&
                              question.answer.length > 0 && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Answer:
                                  </span>
                                  <ul className="mt-1 space-y-1">
                                    {question.answer.map(
                                      (ans: any, idx: number) => (
                                        <li
                                          key={ans.id || idx}
                                          className="flex items-center"
                                        >
                                          <TextWithTooltip
                                            text={ans.correctAnswer}
                                            lang={lang}
                                          />
                                        </li>
                                      ),
                                    )}
                                  </ul>
                                </div>
                              )}

                            {question.type === ExerciseType.RECORD &&
                              "maxDuration" in question && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Max Duration:
                                  </span>
                                  <span>{question.maxDuration} seconds</span>
                                </div>
                              )}

                            {question.type === ExerciseType.RECORD &&
                              "maxCharacter" in question && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Max Character:
                                  </span>
                                  <span>
                                    {question.maxCharacter} characters
                                  </span>
                                </div>
                              )}

                            {question.type === ExerciseType.RECORD &&
                              "scoringCriteria" in question && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Criteria:
                                  </span>
                                  <span>
                                    {question.scoringCriteria?.length}
                                  </span>
                                </div>
                              )}

                            {"level" in question &&
                              (question.level?.length ?? 0) > 0 && (
                                <div>
                                  <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                    Level:
                                  </span>
                                  <div className="flex flex-wrap gap-1 mt-1">
                                    {question.level?.map(
                                      (level: KeypointLevel, idx: number) => (
                                        <span
                                          key={idx}
                                          className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800"
                                        >
                                          {level}
                                        </span>
                                      ),
                                    )}
                                  </div>
                                </div>
                              )}
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  </SortableItem>
                ))}
              </div>
            ) : null}

            <div className="text-center pt-5">
              <button
                className="text-blue-500 hover:text-blue-700 transition-colors"
                onClick={() => handleOpenExerciseTypePopup(section)}
              >
                <PlusCircleIcon className="h-8 w-8" />
              </button>
            </div>
          </SortableContext>
        </DndContext>
      </div>
    );
  };

  // Question form component with dynamic options
  const QuestionForm = ({
    question,
    onSave,
    onCancel,
    questionType,
    section,
    formData,
  }: {
    question?: any;
    onSave: (q: any) => void;
    onCancel: () => void;
    questionType: ExerciseType;
    section: "questions" | "subQuestions";
    formData: any;
  }) => {
    const [localFormData, setLocalFormData] = useState<any>(formData);
    const [isExplanationOpen, setIsExplanationOpen] = useState(false);

    const [localNextOptionId, setLocalNextOptionId] = useState(nextOptionId);
    const [localNextAnswerId, setLocalNextAnswerId] = useState(nextAnswerId);

    const getScoringCriteria = () =>
      Array.isArray(localFormData.scoringCriteria)
        ? (localFormData.scoringCriteria as Partial<IScoringCriteria>[])
        : [];

    const addScoringCriteria = () => {
      const current = getScoringCriteria();
      handleChange("scoringCriteria", [
        ...current,
        { criteria: { [lang]: "" }, maxScore: undefined },
      ]);
    };

    const removeScoringCriteria = (index: number) => {
      const current = getScoringCriteria();
      const next = current.filter((_, idx) => idx !== index);
      handleChange("scoringCriteria", next);
    };

    const updateScoringCriteria = (
      index: number,
      field: keyof IScoringCriteria,
      value: string | ITranslation,
    ) => {
      const current = getScoringCriteria();
      if (!current[index]) return;

      const parsedValue =
        field === "maxScore"
          ? value === ""
            ? undefined
            : Number(value)
          : field === "criteria" && typeof value === "string"
            ? updateTranslationValue(current[index].criteria || {}, lang, value)
            : value;

      const next = current.map((item, idx) =>
        idx === index ? ({ ...item, [field]: parsedValue } as any) : item,
      );

      if (field === "maxScore" && typeof parsedValue === "number") {
        const totalValue = 100;
        const lastIndex = next.length - 1;
        if (lastIndex >= 0) {
          const isLast = index === lastIndex;
          const manualSumExceptLast = next.reduce((sum, item, idx) => {
            if (idx === lastIndex || idx === index) return sum;
            const val =
              typeof item.maxScore === "number" && !Number.isNaN(item.maxScore)
                ? Math.max(0, Math.round(item.maxScore))
                : 0;
            return sum + val;
          }, 0);

          const maxAllowed = Math.max(0, totalValue - manualSumExceptLast);
          const adjusted = Math.min(
            Math.max(0, Math.round(parsedValue)),
            maxAllowed,
          );

          next[index] = { ...next[index], maxScore: adjusted };

          const manualSumWithCurrent = manualSumExceptLast + adjusted;
          const remainder = Math.max(0, totalValue - manualSumWithCurrent);
          if (lastIndex >= 0) {
            next[lastIndex] = { ...next[lastIndex], maxScore: remainder };
          }
        }
      }

      handleChange("scoringCriteria", next);
    };

    const handlePasteCriteria = (
      index: number,
      e: React.ClipboardEvent<HTMLTextAreaElement>,
    ) => {
      const pasted = e.clipboardData.getData("text");
      if (!pasted) return;
      const lines = pasted
        .split(/\r?\n/)
        .map((l) => l.trim())
        .filter(Boolean);
      if (lines.length <= 1) return;
      e.preventDefault();

      const current = getScoringCriteria();
      const next = [...current];
      if (!next[index]) {
        next[index] = { criteria: { [lang]: "" }, maxScore: undefined };
      }
      lines.forEach((line, offset) => {
        const targetIndex = index + offset;
        const existing = next[targetIndex];
        next[targetIndex] = {
          ...existing,
          criteria: updateTranslationValue(
            (existing as any)?.criteria || {},
            lang,
            line,
          ),
          maxScore: existing?.maxScore,
        } as any;
      });
      handleChange("scoringCriteria", next);
    };

    const applyQuestionDefaults = (data: any) => {
      if (!data) return data;
      const type = data.type || questionType;
      const updated = { ...data };

      if (
        (type === ExerciseType.SINGLE_CHOICE ||
          type === ExerciseType.MULTIPLE_CHOICE) &&
        (!updated.options || updated.options.length === 0)
      ) {
        updated.options = [{ value: { [lang]: "" }, isCorrect: false }];
      }

      if (type === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) {
        if (!updated.options || updated.options.length === 0) {
          updated.options = [{ value: { [lang]: "" }, documentGroupId: "" }];
        } else {
          updated.options = updated.options.map((opt: any) => ({
            value: opt?.value || { [lang]: "" },
            documentGroupId: opt?.documentGroupId || "",
          }));
        }

        updated.documentGroups = Array.isArray(updated.documentGroups)
          ? updated.documentGroups.map((group: any) => ({
              id: group?.id || "",
              documents: group?.documents || [],
            }))
          : [];
      }

      if (
        type === ExerciseType.DRAG_DROP &&
        (!updated.answer || updated.answer.length === 0)
      ) {
        const newId = localNextAnswerId;
        updated.answer = [{ correctAnswer: { [lang]: "" }, id: newId }];
        setLocalNextAnswerId(newId + 1);
      }

      return updated;
    };

    // Update local form data when formData prop changes
    useEffect(() => {
      const hasExplanation =
        getTranslationValue(formData?.explanation, lang).trim().length > 0;
      setIsExplanationOpen(hasExplanation);
      if (
        formData &&
        typeof formData.mainQuestion === "string" &&
        formData.mainQuestion !== ""
      ) {
        const parsed = parseInt(formData.mainQuestion, 10);
        setLocalFormData(
          applyQuestionDefaults({
            ...formData,
            mainQuestion: Number.isNaN(parsed) ? undefined : parsed,
          }),
        );
      } else {
        setLocalFormData(applyQuestionDefaults(formData));
      }
    }, [formData]);

    const handleChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => {
        if (field === "mainQuestion") {
          if (value === "" || value === null || value === undefined) {
            return { ...prev, [field]: undefined };
          }
          const parsed = parseInt(value, 10);
          return {
            ...prev,
            [field]: Number.isNaN(parsed) ? prev[field] : parsed,
          };
        }

        return { ...prev, [field]: value };
      });
    };

    const handleDocumentChange = (
      index: number,
      field: keyof IDocument,
      value: any,
    ) => {
      setLocalFormData((prev: any) => {
        const currentDocs = prev.document || [];
        const newDocuments = [...currentDocs];
        const updatedDoc = {
          ...newDocuments[index],
          [field]: value,
        };
        if (field === "type") {
          updatedDoc.data = createEmptyDocumentData(lang);
        }
        newDocuments[index] = updatedDoc;
        return { ...prev, document: newDocuments };
      });
    };

    const handleDataChange = (
      docIndex: number,
      field: keyof IDocumentData,
      value: string | ITranslation,
    ) => {
      setLocalFormData((prev: any) => {
        const currentDocs = prev.document || [];
        const newDocuments = [...currentDocs];
        const currentDoc = newDocuments[docIndex];
        const targetFieldValue = currentDoc?.data?.[field];
        const shouldTranslate =
          (field === "content" || field === "url") && typeof value === "string";

        newDocuments[docIndex] = {
          ...currentDoc,
          data: {
            ...currentDoc.data,
            [field]: shouldTranslate
              ? updateTranslationValue(
                  (targetFieldValue as ITranslation) || {},
                  lang,
                  value,
                )
              : value,
          },
        };
        return { ...prev, document: newDocuments };
      });
    };

    const renderDocumentFields = (doc: IDocument, index: number) => {
      if (isTextualDocumentType(doc.type)) {
        const label = getDocumentContentLabel(doc.type);
        const isLongForm = doc.type === DocumentType.TEXT;
        const placeholder =
          doc.type === DocumentType.TEXT
            ? "Enter content"
            : `Enter ${label.toLowerCase()}`;

        return (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {label}
            </label>
            {isLongForm ? (
              <textarea
                value={getCurrentTranslationValue(doc.data.content, lang)}
                onChange={(e) =>
                  handleDataChange(index, "content", e.target.value)
                }
                rows={3}
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder={placeholder}
              />
            ) : (
              <input
                type="text"
                value={getCurrentTranslationValue(doc.data.content, lang)}
                onChange={(e) =>
                  handleDataChange(index, "content", e.target.value)
                }
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder={placeholder}
              />
            )}
          </div>
        );
      }

      const mediaUrl = getCurrentTranslationValue(doc.data.url, lang) || "";

      if (doc.type === DocumentType.IMAGE) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Image URL"
              uploadPayload={{
                prefix: "",
                folder: "exercises",
              }}
            />
          </div>
        );
      }

      if (doc.type === DocumentType.AUDIO) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Audio URL"
              uploadPayload={{
                prefix: "",
                folder: "exercises",
              }}
              accept="audio/*"
            />
          </div>
        );
      }

      if (doc.type === DocumentType.VIDEO) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Video URL"
              uploadPayload={{
                prefix: "",
                folder: "exercises",
              }}
              accept="video/*"
            />
          </div>
        );
      }

      if (doc.type === DocumentType.ANIMATION) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Animation URL"
              uploadPayload={{
                prefix: "",
                folder: "exercises",
              }}
              accept="application/json,.json,.lottie"
            />
          </div>
        );
      }

      return null;
    };

    const renderGroupDocumentFields = (
      doc: IDocument,
      groupIndex: number,
      docIndex: number,
    ) => {
      if (isTextualDocumentType(doc.type)) {
        const label = getDocumentContentLabel(doc.type);
        const isLongForm = doc.type === DocumentType.TEXT;
        const placeholder =
          doc.type === DocumentType.TEXT
            ? "Enter content"
            : `Enter ${label.toLowerCase()}`;

        return (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {label}
            </label>
            {isLongForm ? (
              <textarea
                value={getCurrentTranslationValue(doc.data.content, lang)}
                onChange={(e) =>
                  handleGroupDataChange(
                    groupIndex,
                    docIndex,
                    "content",
                    e.target.value,
                  )
                }
                rows={3}
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder={placeholder}
              />
            ) : (
              <input
                type="text"
                value={getCurrentTranslationValue(doc.data.content, lang)}
                onChange={(e) =>
                  handleGroupDataChange(
                    groupIndex,
                    docIndex,
                    "content",
                    e.target.value,
                  )
                }
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder={placeholder}
              />
            )}
          </div>
        );
      }

      const mediaUrl = getCurrentTranslationValue(doc.data.url, lang) || "";

      if (doc.type === DocumentType.IMAGE) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) =>
                handleGroupDataChange(groupIndex, docIndex, "url", newUrl)
              }
              label="Image URL"
              uploadPayload={{
                prefix: "",
                folder: "exercises",
              }}
            />
          </div>
        );
      }

      if (doc.type === DocumentType.AUDIO) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) =>
                handleGroupDataChange(groupIndex, docIndex, "url", newUrl)
              }
              label="Audio URL"
              uploadPayload={{
                prefix: "",
                folder: "exercises",
              }}
              accept="audio/*"
            />
          </div>
        );
      }

      if (doc.type === DocumentType.VIDEO) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) =>
                handleGroupDataChange(groupIndex, docIndex, "url", newUrl)
              }
              label="Video URL"
              uploadPayload={{
                prefix: "",
                folder: "exercises",
              }}
              accept="video/*"
            />
          </div>
        );
      }

      if (doc.type === DocumentType.ANIMATION) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) =>
                handleGroupDataChange(groupIndex, docIndex, "url", newUrl)
              }
              label="Animation URL"
              uploadPayload={{
                prefix: "",
                folder: "exercises",
              }}
              accept="application/json,.json,.lottie"
            />
          </div>
        );
      }

      return null;
    };

    const addNewDocument = () => {
      // Tìm ID lớn nhất hiện tại từ các document trong form
      const currentMaxId = (localFormData.document || []).reduce(
        (max: number, doc: IDocument) => Math.max(max, doc.id || 0),
        0,
      );
      const newId = currentMaxId + 1;

      setLocalFormData((prev: any) => ({
        ...prev,
        document: [
          ...(prev.document || []),
          {
            id: newId,
            type: DocumentType.TEXT,
            data: createEmptyDocumentData(lang),
          },
        ],
      }));
    };

    const removeDocument = (index: number) => {
      setLocalFormData((prev: any) => {
        const documents = prev.document || [];
        return {
          ...prev,
          document: documents.filter((_: IDocument, i: number) => i !== index),
        };
      });
    };

    const handleSave = () => {
      // Cập nhật global counters cho options và answers
      setNextOptionId(localNextOptionId);
      setNextAnswerId(localNextAnswerId);

      const cleanedDocuments = localFormData.document?.length
        ? cleanDocumentItems(localFormData.document)
        : [];

      const cleanedDocumentGroups =
        questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER
          ? cleanDocumentGroups(localFormData.documentGroups || [])
          : undefined;

      let normalizedScoring = localFormData.scoringCriteria;
      if (questionType === ExerciseType.RECORD) {
        normalizedScoring = rebalanceRecordScoringCriteria(
          localFormData.scoringCriteria,
          100,
          lang,
        );
      }

      const nextPayload = {
        ...localFormData,
        document: cleanedDocuments,
        scoringCriteria: normalizedScoring,
      } as any;

      if (questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) {
        nextPayload.documentGroups = cleanedDocumentGroups;
      }

      onSave(nextPayload);
    };

    // Add new option
    const addOption = () => {
      if (
        questionType === ExerciseType.SINGLE_CHOICE ||
        questionType === ExerciseType.MULTIPLE_CHOICE
      ) {
        const newOptions = [
          ...localFormData.options,
          { value: { [lang]: "" }, isCorrect: false },
        ];
        handleChange("options", newOptions);
      } else if (questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) {
        const newOptions = [
          ...localFormData.options,
          { value: { [lang]: "" }, documentGroupId: "" },
        ];
        handleChange("options", newOptions);
      } else if (questionType === ExerciseType.DRAG_DROP) {
        const newId = localNextOptionId;
        setLocalNextOptionId(newId + 1);

        const newOptions = [
          ...localFormData.options,
          { text: { [lang]: "" }, id: newId },
        ];
        handleChange("options", newOptions);
      }
    };

    // Remove option
    const removeOption = (index: number) => {
      if (
        questionType === ExerciseType.SINGLE_CHOICE ||
        questionType === ExerciseType.MULTIPLE_CHOICE ||
        questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER
      ) {
        const newOptions = [...localFormData.options];
        newOptions.splice(index, 1);
        handleChange("options", newOptions);
      } else if (questionType === ExerciseType.DRAG_DROP) {
        const newOptions = [...localFormData.options];
        newOptions.splice(index, 1);
        handleChange("options", newOptions);
      }
    };

    // Update option value
    const updateOptionValue = (index: number, value: string) => {
      if (
        questionType === ExerciseType.SINGLE_CHOICE ||
        questionType === ExerciseType.MULTIPLE_CHOICE ||
        questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER
      ) {
        const newOptions = [...localFormData.options];
        const currentTranslation = newOptions[index].value || {};
        const updatedTranslation = updateTranslationValue(
          currentTranslation,
          lang,
          value,
        );
        newOptions[index] = { ...newOptions[index], value: updatedTranslation };
        handleChange("options", newOptions);
      } else if (questionType === ExerciseType.DRAG_DROP) {
        const newOptions = [...localFormData.options];
        const currentTranslation = newOptions[index].text || {};
        const updatedTranslation = updateTranslationValue(
          currentTranslation,
          lang,
          value,
        );
        newOptions[index] = { ...newOptions[index], text: updatedTranslation };
        handleChange("options", newOptions);
      }
    };

    const updateOptionDocumentGroupId = (
      index: number,
      documentGroupId: string,
    ) => {
      if (questionType !== ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) return;
      const newOptions = [...localFormData.options];
      newOptions[index] = { ...newOptions[index], documentGroupId };
      handleChange("options", newOptions);
    };

    // Update option correctness
    const updateOptionCorrectness = (index: number, isCorrect: boolean) => {
      if (
        questionType === ExerciseType.SINGLE_CHOICE ||
        questionType === ExerciseType.MULTIPLE_CHOICE
      ) {
        const newOptions = [...localFormData.options];
        newOptions[index] = { ...newOptions[index], isCorrect };
        handleChange("options", newOptions);
      }
    };

    // Add new answer
    const addAnswer = () => {
      const newId = localNextAnswerId;
      setLocalNextAnswerId(newId + 1);

      const newAnswer = [
        ...localFormData.answer,
        { correctAnswer: { [lang]: "" }, id: newId },
      ];
      handleChange("answer", newAnswer);
    };

    // Remove answer
    const removeAnswer = (index: number) => {
      const newAnswer = localFormData.answer.filter(
        (_: any, i: number) => i !== index,
      );
      if (newAnswer.length === 0) {
        const newId = localNextAnswerId;
        setLocalNextAnswerId(newId + 1);
        newAnswer.push({ correctAnswer: { [lang]: "" }, id: newId });
      }
      handleChange("answer", newAnswer);
    };

    // Update answer value
    const updateAnswerValue = (index: number, value: string) => {
      const newAnswer = [...localFormData.answer];
      const currentTranslation = newAnswer[index].correctAnswer || {};
      const updatedTranslation = updateTranslationValue(
        currentTranslation,
        lang,
        value,
      );
      newAnswer[index] = {
        ...newAnswer[index],
        correctAnswer: updatedTranslation,
      };
      handleChange("answer", newAnswer);
    };

    const getTranslationTokens = (
      value: ITranslation | string | undefined,
    ): Set<string> => {
      const tokens = new Set<string>();
      if (!value) return tokens;

      if (typeof value === "string") {
        const normalized = value.trim().toLowerCase();
        if (normalized) tokens.add(normalized);
        return tokens;
      }

      Object.values(value).forEach((text) => {
        if (!text) return;
        const normalized = text.trim().toLowerCase();
        if (normalized) tokens.add(normalized);
      });

      return tokens;
    };

    const ensureTranslation = (
      value: ITranslation | string | undefined,
    ): ITranslation => {
      if (!value) return { [lang]: "" };
      if (typeof value === "string") {
        return updateTranslationValue(undefined, lang, value);
      }
      return value;
    };

    const mergeTranslations = (
      target: ITranslation | undefined,
      source: ITranslation,
    ): ITranslation => {
      const merged: ITranslation = { ...(target || {}) };
      Object.entries(source).forEach(([code, text]) => {
        if (!text || !text.trim()) return;
        const existing = merged[code as LangCode];
        if (!existing || !existing.trim()) {
          merged[code as LangCode] = text;
        }
      });
      return merged;
    };

    const hasOverlap = (a: Set<string>, b: Set<string>) => {
      let found = false;
      b.forEach((token) => {
        if (a.has(token)) found = true;
      });
      return found;
    };

    const shuffleArray = <T,>(items: T[]): T[] => {
      const result = [...items];
      for (let i = result.length - 1; i > 0; i -= 1) {
        const j = Math.floor(Math.random() * (i + 1));
        [result[i], result[j]] = [result[j], result[i]];
      }
      return result;
    };

    const handleShuffleOptions = () => {
      if (questionType !== ExerciseType.DRAG_DROP) return;

      const currentOptions = Array.isArray(localFormData.options)
        ? localFormData.options
        : [];
      const currentAnswers = Array.isArray(localFormData.answer)
        ? localFormData.answer
        : [];

      let nextId = localNextOptionId;
      const mergedOptions = [...currentOptions];
      const optionTokens = mergedOptions.map((opt: IOptions) =>
        getTranslationTokens(opt.text),
      );

      currentAnswers.forEach((ans: IAnswer) => {
        const answerTranslation = ensureTranslation(ans.correctAnswer);
        const answerTokens = getTranslationTokens(answerTranslation);
        if (answerTokens.size === 0) return;

        const matchIndex = optionTokens.findIndex((tokens) =>
          hasOverlap(tokens, answerTokens),
        );

        if (matchIndex === -1) {
          mergedOptions.push({ id: nextId++, text: answerTranslation });
          optionTokens.push(getTranslationTokens(answerTranslation));
          return;
        }

        const existingOption = mergedOptions[matchIndex];
        const mergedText = mergeTranslations(
          existingOption.text,
          answerTranslation,
        );
        mergedOptions[matchIndex] = { ...existingOption, text: mergedText };
        optionTokens[matchIndex] = getTranslationTokens(mergedText);
      });

      const shuffled = shuffleArray(mergedOptions);
      setLocalFormData((prev: any) => ({ ...prev, options: shuffled }));
      if (nextId !== localNextOptionId) setLocalNextOptionId(nextId);
    };

    const handlePasteOptions = (
      index: number,
      e: React.ClipboardEvent<HTMLInputElement | HTMLTextAreaElement>,
    ) => {
      const pasted = e.clipboardData.getData("text");
      if (!pasted) return;
      const lines = pasted
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean);
      if (lines.length <= 1) return;
      e.preventDefault();

      setLocalFormData((prev: any) => {
        const newOptions = [...(prev.options || [])];
        let nextId = localNextOptionId;
        if (!newOptions[index]) {
          if (questionType === ExerciseType.DRAG_DROP) {
            newOptions[index] = { text: { [lang]: "" }, id: nextId++ };
          } else if (
            questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER
          ) {
            newOptions[index] = { value: { [lang]: "" }, documentGroupId: "" };
          } else {
            newOptions[index] = { value: { [lang]: "" }, isCorrect: false };
          }
        }

        lines.forEach((line, offset) => {
          const targetIndex = index + offset;
          const existing = newOptions[targetIndex];
          if (questionType === ExerciseType.DRAG_DROP) {
            const id = existing?.id ?? nextId++;
            newOptions[targetIndex] = {
              ...existing,
              id,
              text: updateTranslationValue(existing?.text || {}, lang, line),
            };
          } else if (
            questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER
          ) {
            newOptions[targetIndex] = {
              ...existing,
              value: updateTranslationValue(existing?.value || {}, lang, line),
              documentGroupId: existing?.documentGroupId || "",
            };
          } else {
            newOptions[targetIndex] = {
              ...existing,
              value: updateTranslationValue(existing?.value || {}, lang, line),
              isCorrect: existing?.isCorrect ?? false,
            };
          }
        });

        if (nextId !== localNextOptionId) setLocalNextOptionId(nextId);
        return { ...prev, options: newOptions };
      });
    };

    const handlePasteAnswers = (
      index: number,
      e: React.ClipboardEvent<HTMLInputElement | HTMLTextAreaElement>,
    ) => {
      const pasted = e.clipboardData.getData("text");
      if (!pasted) return;
      const lines = pasted
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean);
      if (lines.length <= 1) return;
      e.preventDefault();

      setLocalFormData((prev: any) => {
        const newAnswer = [...(prev.answer || [])];
        let nextId = localNextAnswerId;
        if (!newAnswer[index]) {
          newAnswer[index] = { correctAnswer: { [lang]: "" }, id: nextId++ };
        }

        lines.forEach((line, offset) => {
          const targetIndex = index + offset;
          const existing = newAnswer[targetIndex];
          const id = existing?.id ?? nextId++;
          newAnswer[targetIndex] = {
            ...existing,
            id,
            correctAnswer: updateTranslationValue(
              existing?.correctAnswer || {},
              lang,
              line,
            ),
          };
        });

        if (nextId !== localNextAnswerId) setLocalNextAnswerId(nextId);
        return { ...prev, answer: newAnswer };
      });
    };

    const showShuffleButton =
      questionType === ExerciseType.DRAG_DROP &&
      (localFormData.form === FormDragDropType.TextGapFilling ||
        localFormData.form === FormDragDropType.ArrangeTheSequence);

    const documentGroupIds = Array.isArray(localFormData.documentGroups)
      ? localFormData.documentGroups
          .map((group: any) =>
            typeof group?.id === "string" ? group.id.trim() : "",
          )
          .filter(Boolean)
      : [];

    const addDocumentGroup = () => {
      setLocalFormData((prev: any) => ({
        ...prev,
        documentGroups: [
          ...(prev.documentGroups || []),
          {
            id: "",
            documents: [createDefaultTextDocument(lang)],
          },
        ],
      }));
    };

    const removeDocumentGroup = (index: number) => {
      setLocalFormData((prev: any) => {
        const groups = prev.documentGroups || [];
        return {
          ...prev,
          documentGroups: groups.filter((_: any, i: number) => i !== index),
        };
      });
    };

    const updateDocumentGroupId = (index: number, value: string) => {
      setLocalFormData((prev: any) => {
        const groups = [...(prev.documentGroups || [])];
        const current = groups[index] || { id: "", documents: [] };
        groups[index] = { ...current, id: value };
        return { ...prev, documentGroups: groups };
      });
    };

    const addDocumentToGroup = (groupIndex: number) => {
      setLocalFormData((prev: any) => {
        const groups = [...(prev.documentGroups || [])];
        const group = groups[groupIndex] || { id: "", documents: [] };
        const currentDocs = group.documents || [];
        const currentMaxId = currentDocs.reduce(
          (max: number, doc: IDocument) => Math.max(max, doc.id || 0),
          0,
        );
        const newId = currentMaxId + 1;
        const nextDocuments = [
          ...currentDocs,
          {
            id: newId,
            type: DocumentType.TEXT,
            data: createEmptyDocumentData(lang),
          },
        ];
        groups[groupIndex] = { ...group, documents: nextDocuments };
        return { ...prev, documentGroups: groups };
      });
    };

    const removeDocumentFromGroup = (groupIndex: number, docIndex: number) => {
      setLocalFormData((prev: any) => {
        const groups = [...(prev.documentGroups || [])];
        const group = groups[groupIndex];
        if (!group) return prev;
        const documents = group.documents || [];
        groups[groupIndex] = {
          ...group,
          documents: documents.filter(
            (_: IDocument, i: number) => i !== docIndex,
          ),
        };
        return { ...prev, documentGroups: groups };
      });
    };

    const handleGroupDocumentChange = (
      groupIndex: number,
      docIndex: number,
      field: keyof IDocument,
      value: any,
    ) => {
      setLocalFormData((prev: any) => {
        const groups = [...(prev.documentGroups || [])];
        const group = groups[groupIndex] || { id: "", documents: [] };
        const documents = [...(group.documents || [])];
        const updatedDoc = {
          ...documents[docIndex],
          [field]: value,
        };
        if (field === "type") {
          updatedDoc.data = createEmptyDocumentData(lang);
        }
        documents[docIndex] = updatedDoc;
        groups[groupIndex] = { ...group, documents };
        return { ...prev, documentGroups: groups };
      });
    };

    const handleGroupDataChange = (
      groupIndex: number,
      docIndex: number,
      field: keyof IDocumentData,
      value: string | ITranslation,
    ) => {
      setLocalFormData((prev: any) => {
        const groups = [...(prev.documentGroups || [])];
        const group = groups[groupIndex] || { id: "", documents: [] };
        const documents = [...(group.documents || [])];
        const currentDoc = documents[docIndex];
        const targetFieldValue = currentDoc?.data?.[field];
        const shouldTranslate =
          (field === "content" || field === "url") && typeof value === "string";

        documents[docIndex] = {
          ...currentDoc,
          data: {
            ...currentDoc.data,
            [field]: shouldTranslate
              ? updateTranslationValue(
                  (targetFieldValue as ITranslation) || {},
                  lang,
                  value,
                )
              : value,
          },
        };
        groups[groupIndex] = { ...group, documents };
        return { ...prev, documentGroups: groups };
      });
    };

    return (
      <div className="space-y-4">
        {/* Common fields */}
        {section === "subQuestions" && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Main question
            </label>
            <input
              type="number"
              value={
                typeof localFormData.mainQuestion === "number"
                  ? localFormData.mainQuestion
                  : ""
              }
              onChange={(e) =>
                handleChange(
                  "mainQuestion",
                  e.target.value === "" ? "" : Number(e.target.value),
                )
              }
              className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="Enter main question ID"
            />
          </div>
        )}

        {/* Documents Section */}
        <div className="border rounded-lg p-4 bg-gray-50">
          <div className="flex justify-between items-center mb-3">
            <h3 className="font-medium text-gray-800">Content Documents</h3>
          </div>

          {localFormData.document?.map((doc: IDocument, index: number) => (
            <div key={doc.id} className="border rounded-lg p-4 bg-white mb-3">
              <div className="flex justify-between items-center mb-3">
                <h4 className="font-medium text-sky-400">
                  Content {index + 1}
                </h4>
                <button
                  type="button"
                  onClick={() => removeDocument(index)}
                  className="text-red-500 hover:text-red-700"
                >
                  <TrashIcon className="h-4 w-4" />
                </button>
              </div>

              <div className="space-y-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Type
                  </label>
                  <select
                    value={doc.type}
                    onChange={(e) =>
                      handleDocumentChange(
                        index,
                        "type",
                        e.target.value as DocumentType,
                      )
                    }
                    className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                  >
                    <option value={DocumentType.TITLE}>Title</option>
                    <option value={DocumentType.CAPTION}>Caption</option>
                    <option value={DocumentType.TEXT}>Text</option>
                    <option value={DocumentType.IMAGE}>Image</option>
                    <option value={DocumentType.VIDEO}>Video</option>
                    <option value={DocumentType.AUDIO}>Audio</option>
                    <option value={DocumentType.ANIMATION}>Animation</option>
                  </select>
                </div>
                {renderDocumentFields(doc, index)}
              </div>
            </div>
          ))}

          <div className="text-center">
            <button
              type="button"
              onClick={addNewDocument}
              className="px-3 py-1 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700"
            >
              Add Content
            </button>
          </div>
        </div>

        <div
          className={
            isExplanationOpen ? "border rounded-lg p-3 bg-gray-50" : "p-0"
          }
        >
          <button
            type="button"
            onClick={() => setIsExplanationOpen((prev) => !prev)}
            className="inline-flex items-center gap-1 text-base font-semibold text-gray-700"
          >
            <span>Explanation</span>
            <span className="text-blue-600">
              {isExplanationOpen ? "↑" : "↓"}
            </span>
          </button>
          {isExplanationOpen && (
            <textarea
              value={getCurrentTranslationValue(
                localFormData.explanation,
                lang,
              )}
              onChange={(e) =>
                handleChange(
                  "explanation",
                  updateTranslationValue(
                    localFormData.explanation || {},
                    lang,
                    e.target.value,
                  ),
                )
              }
              rows={3}
              className="mt-2 border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="Enter explanation"
            />
          )}
        </div>

        {/* Type-specific fields */}
        {(questionType === ExerciseType.SINGLE_CHOICE ||
          questionType === ExerciseType.MULTIPLE_CHOICE) && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Options
            </label>
            <div className="space-y-3">
              {localFormData.options.map((opt: any, idx: number) => (
                <div key={idx} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={getCurrentTranslationValue(opt.value, lang)}
                    onChange={(e) => updateOptionValue(idx, e.target.value)}
                    onPaste={(e) => handlePasteOptions(idx, e)}
                    className="flex-1 border rounded-lg p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    placeholder={`Option ${idx + 1}`}
                  />
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={opt.isCorrect}
                      onChange={(e) =>
                        updateOptionCorrectness(idx, e.target.checked)
                      }
                      className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                    />
                    <span className="ml-1 text-sm">
                      {questionType === ExerciseType.SINGLE_CHOICE
                        ? "Correct"
                        : "Correct Answer"}
                    </span>
                  </label>
                  {localFormData.options.length > 2 && (
                    <button
                      type="button"
                      onClick={() => removeOption(idx)}
                      className="text-red-500 hover:text-red-700 p-1"
                    >
                      <TrashIcon className="h-5 w-5" />
                    </button>
                  )}
                </div>
              ))}
              <button
                type="button"
                onClick={addOption}
                className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <PlusIcon className="h-4 w-4 mr-1" />
                Add Option
              </button>
            </div>
          </div>
        )}

        {questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Options
            </label>
            <datalist id="no-correct-answer-document-group-ids">
              {documentGroupIds.map((id: string) => (
                <option key={id} value={id} />
              ))}
            </datalist>
            <div className="space-y-3">
              {localFormData.options.map((opt: any, idx: number) => (
                <div
                  key={idx}
                  className="grid grid-cols-1 md:grid-cols-3 gap-2 items-center"
                >
                  <input
                    type="text"
                    value={getCurrentTranslationValue(opt.value, lang)}
                    onChange={(e) => updateOptionValue(idx, e.target.value)}
                    onPaste={(e) => handlePasteOptions(idx, e)}
                    className="border rounded-lg p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    placeholder={`Option ${idx + 1}`}
                  />
                  <input
                    type="text"
                    list="no-correct-answer-document-group-ids"
                    value={opt.documentGroupId || ""}
                    onChange={(e) =>
                      updateOptionDocumentGroupId(idx, e.target.value)
                    }
                    className="border rounded-lg p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    placeholder="Document group ID (optional)"
                  />
                  <div className="flex justify-end">
                    {localFormData.options.length > 1 && (
                      <button
                        type="button"
                        onClick={() => removeOption(idx)}
                        className="text-red-500 hover:text-red-700 p-1"
                      >
                        <TrashIcon className="h-5 w-5" />
                      </button>
                    )}
                  </div>
                </div>
              ))}
              <button
                type="button"
                onClick={addOption}
                className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <PlusIcon className="h-4 w-4 mr-1" />
                Add Option
              </button>
            </div>
          </div>
        )}

        {questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER && (
          <div className="border rounded-lg p-4 bg-gray-50 space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="font-medium text-gray-800">Document Groups</h3>
            </div>

            {(localFormData.documentGroups || []).length === 0 ? (
              <p className="text-sm text-gray-500">
                Chưa có group. Thêm group để gắn card cho từng kịch bản.
              </p>
            ) : (
              <div className="space-y-4">
                {(localFormData.documentGroups || []).map(
                  (group: any, groupIndex: number) => (
                    <div
                      key={`group-${groupIndex}`}
                      className="border rounded-lg p-4 bg-white"
                    >
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex-1">
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Group ID
                          </label>
                          <input
                            type="text"
                            value={group.id || ""}
                            onChange={(e) =>
                              updateDocumentGroupId(groupIndex, e.target.value)
                            }
                            className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                            placeholder="e.g., cardA"
                          />
                        </div>
                        <button
                          type="button"
                          onClick={() => removeDocumentGroup(groupIndex)}
                          className="ml-3 text-red-500 hover:text-red-700"
                        >
                          <TrashIcon className="h-5 w-5" />
                        </button>
                      </div>

                      {(group.documents || []).map(
                        (doc: IDocument, docIndex: number) => (
                          <div
                            key={doc.id || docIndex}
                            className="border rounded-lg p-4 bg-gray-50 mb-3"
                          >
                            <div className="flex justify-between items-center mb-3">
                              <h4 className="font-medium text-sky-400">
                                Content {docIndex + 1}
                              </h4>
                              <button
                                type="button"
                                onClick={() =>
                                  removeDocumentFromGroup(groupIndex, docIndex)
                                }
                                className="text-red-500 hover:text-red-700"
                              >
                                <TrashIcon className="h-4 w-4" />
                              </button>
                            </div>

                            <div className="space-y-3">
                              <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                  Type
                                </label>
                                <select
                                  value={doc.type}
                                  onChange={(e) =>
                                    handleGroupDocumentChange(
                                      groupIndex,
                                      docIndex,
                                      "type",
                                      e.target.value as DocumentType,
                                    )
                                  }
                                  className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                                >
                                  <option value={DocumentType.TITLE}>
                                    Title
                                  </option>
                                  <option value={DocumentType.CAPTION}>
                                    Caption
                                  </option>
                                  <option value={DocumentType.TEXT}>
                                    Text
                                  </option>
                                  <option value={DocumentType.IMAGE}>
                                    Image
                                  </option>
                                  <option value={DocumentType.VIDEO}>
                                    Video
                                  </option>
                                  <option value={DocumentType.AUDIO}>
                                    Audio
                                  </option>
                                  <option value={DocumentType.ANIMATION}>
                                    Animation
                                  </option>
                                </select>
                              </div>
                            </div>
                            {renderGroupDocumentFields(
                              doc,
                              groupIndex,
                              docIndex,
                            )}
                          </div>
                        ),
                      )}

                      <div className="text-center">
                        <button
                          type="button"
                          onClick={() => addDocumentToGroup(groupIndex)}
                          className="px-3 py-1 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700"
                        >
                          Add Content
                        </button>
                      </div>
                    </div>
                  ),
                )}
              </div>
            )}
            <div className="flex justify-center pt-2">
              <button
                type="button"
                onClick={addDocumentGroup}
                className="text-blue-600 hover:text-blue-800 p-2 rounded-full"
                title="Add Group"
              >
                <PlusCircleIcon className="h-6 w-6" />
              </button>
            </div>
          </div>
        )}

        {questionType === ExerciseType.DRAG_DROP && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Form Type
            </label>
            <select
              value={localFormData.form || FormDragDropType.TextGapFilling}
              onChange={(e) => handleChange("form", e.target.value)}
              className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
            >
              <option value={FormDragDropType.TextGapFilling}>
                Text Gap Filling
              </option>
              <option value={FormDragDropType.CuesPlacement}>
                Cues Placement
              </option>
              <option value={FormDragDropType.StressPlacement}>
                Stress Placement
              </option>
              <option value={FormDragDropType.ArrangeTheSequence}>
                Arrange the Sequence
              </option>
            </select>
          </div>
        )}

        {questionType === ExerciseType.DRAG_DROP && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Target Area
            </label>
            <textarea
              rows={3}
              value={getCurrentTranslationValue(localFormData.targetArea, lang)}
              onChange={(e) =>
                handleChange(
                  "targetArea",
                  updateTranslationValue(
                    localFormData.targetArea || {},
                    lang,
                    e.target.value,
                  ),
                )
              }
              className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400 whitespace-pre-wrap"
              placeholder="Enter target area"
            />
          </div>
        )}

        {questionType === ExerciseType.DRAG_DROP && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Answer
            </label>
            <div className="space-y-2">
              {localFormData.answer.map((ans: any, idx: number) => (
                <div key={ans.id} className="flex items-center">
                  <input
                    type="text"
                    value={getCurrentTranslationValue(ans.correctAnswer, lang)}
                    onChange={(e) => updateAnswerValue(idx, e.target.value)}
                    onPaste={(e) => handlePasteAnswers(idx, e)}
                    className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    placeholder={`Answer ${idx + 1}`}
                  />
                  <button
                    type="button"
                    onClick={() => removeAnswer(idx)}
                    className="ml-2 text-red-500 hover:text-red-700"
                  >
                    <TrashIcon className="h-5 w-5" />
                  </button>
                </div>
              ))}
              <button
                type="button"
                onClick={addAnswer}
                className="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <PlusIcon className="h-4 w-4 mr-1" />
                Add Answer
              </button>
            </div>
          </div>
        )}

        {questionType === ExerciseType.DRAG_DROP && (
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="block text-sm font-medium text-gray-700">
                Options
              </label>
              {showShuffleButton && (
                <button
                  type="button"
                  onClick={handleShuffleOptions}
                  className="text-sm text-blue-600 hover:text-blue-700"
                >
                  Shuffle
                </button>
              )}
            </div>
            <div className="space-y-2">
              {localFormData.options.map((opt: any, idx: number) => (
                <div key={opt.id} className="flex items-center">
                  <input
                    type="text"
                    value={getCurrentTranslationValue(opt.text, lang)}
                    onChange={(e) => updateOptionValue(idx, e.target.value)}
                    onPaste={(e) => handlePasteOptions(idx, e)}
                    className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    placeholder={`Option ${idx + 1}`}
                  />
                  <button
                    type="button"
                    onClick={() => removeOption(idx)}
                    className="ml-2 text-red-500 hover:text-red-700"
                  >
                    <TrashIcon className="h-5 w-5" />
                  </button>
                </div>
              ))}
              <button
                type="button"
                onClick={addOption}
                className="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <PlusIcon className="h-4 w-4 mr-1" />
                Add Option
              </button>
            </div>
          </div>
        )}

        {questionType === ExerciseType.RECORD && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Max Duration (seconds)
            </label>
            <input
              type="number"
              value={localFormData.maxDuration}
              onChange={(e) =>
                handleChange("maxDuration", parseInt(e.target.value))
              }
              className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="Enter max duration"
            />
          </div>
        )}

        {questionType === ExerciseType.RECORD && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Max Character (seconds)
            </label>
            <input
              type="number"
              value={localFormData.maxCharacter}
              onChange={(e) =>
                handleChange("maxCharacter", parseInt(e.target.value))
              }
              className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="Enter max character"
            />
          </div>
        )}

        {questionType === ExerciseType.RECORD && (
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-700">
                Scoring Criteria
              </span>
              <button
                type="button"
                onClick={addScoringCriteria}
                className="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <PlusIcon className="h-4 w-4 mr-1" />
                Add Criteria
              </button>
            </div>

            {getScoringCriteria().length === 0 ? (
              <p className="text-sm text-gray-500">
                Chưa có tiêu chí. Thêm mới để chấm điểm.
              </p>
            ) : (
              <div className="space-y-3">
                {getScoringCriteria().map((criteriaItem, index) => (
                  <div
                    key={`scoring-${index}`}
                    className="border rounded-lg p-3 space-y-2"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-semibold text-gray-700">
                        Criterion {index + 1}
                      </span>
                      <button
                        type="button"
                        onClick={() => removeScoringCriteria(index)}
                        className="text-red-500 hover:text-red-700"
                      >
                        <TrashIcon className="h-5 w-5" />
                      </button>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                      <div className="md:col-span-2">
                        <label className="block text-xs font-medium text-gray-600 mb-1">
                          Description
                        </label>
                        <textarea
                          value={getCurrentTranslationValue(
                            criteriaItem.criteria,
                            lang,
                          )}
                          onChange={(e) =>
                            updateScoringCriteria(
                              index,
                              "criteria",
                              e.target.value,
                            )
                          }
                          onPaste={(e) => handlePasteCriteria(index, e)}
                          rows={2}
                          className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400 whitespace-pre-wrap"
                          placeholder="e.g., Pronunciation clarity"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-gray-600 mb-1">
                          Max Score
                        </label>
                        <input
                          type="number"
                          value={
                            typeof criteriaItem.maxScore === "number"
                              ? criteriaItem.maxScore
                              : ""
                          }
                          onChange={(e) =>
                            updateScoringCriteria(
                              index,
                              "maxScore",
                              e.target.value,
                            )
                          }
                          className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                          placeholder="Auto"
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Level field for all question types */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Level
          </label>
          <div className="space-y-2">
            {Object.values(KeypointLevel).map((level) => (
              <label key={level} className="flex items-center">
                <input
                  type="checkbox"
                  checked={localFormData.level?.includes(level) || false}
                  onChange={(e) => {
                    const newLevel = e.target.checked
                      ? [...(localFormData.level || []), level]
                      : (localFormData.level || []).filter(
                          (l: KeypointLevel) => l !== level,
                        );
                    handleChange("level", newLevel);
                  }}
                  className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                />
                <span className="ml-2 text-sm">{level}</span>
              </label>
            ))}
          </div>
        </div>

        <div className="sticky bottom-0 bg-white pt-4 mt-6 border-t flex justify-end gap-2">
          <button
            className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition"
            onClick={onCancel}
          >
            Cancel
          </button>
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
            onClick={handleSave}
            disabled={saving}
          >
            {saving ? (
              <>Saving...</>
            ) : question ? (
              "Update Question"
            ) : (
              "Add Question"
            )}
          </button>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Card: left image / right form */}
        <div className="bg-white shadow-xl rounded-xl overflow-hidden flex flex-col md:flex-row">
          {/* LEFT: image + image input */}
          <div className="flex-1 flex flex-col items-center p-6 bg-gray-50">
            <div className="w-full max-w-md">
              {currentExercise.image ? (
                <img
                  src={currentExercise.image}
                  alt={currentExercise.title?.[lang]}
                  className="w-full max-h-[320px] object-cover rounded-xl shadow-lg border border-gray-200"
                />
              ) : (
                <div className="w-full h-[320px] bg-gray-100 flex items-center justify-center rounded-xl border border-dashed border-gray-300 text-gray-400">
                  <div className="text-center">
                    <p>No image</p>
                  </div>
                </div>
              )}
            </div>

            <div className="mt-6 w-full max-w-md">
              <label className="block mb-2 text-sm font-medium text-gray-700">
                Image URL
              </label>
              <input
                value={currentExercise.image || ""}
                onChange={(e) =>
                  setCurrentExercise((prev) => ({
                    ...prev,
                    image: e.target.value,
                  }))
                }
                className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                placeholder="Paste image link..."
              />
            </div>
          </div>

          {/* RIGHT: form */}
          <div className="flex-[1.5] p-6">
            <div className="flex justify-between items-center mb-6">
              <h1 className="text-2xl md:text-3xl font-bold text-gray-800">
                {isEditMode ? "✏️ Edit Exercise" : "🌱 Create New Exercise"}
              </h1>
            </div>

            <div className="space-y-6">
              {/* Title */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Title *
                </label>
                <input
                  value={currentExercise.title[lang] || ""}
                  onChange={(e) =>
                    setCurrentExercise((prev) => ({
                      ...prev,
                      title: { ...prev.title, [lang]: e.target.value },
                    }))
                  }
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  placeholder="Exercise title..."
                  required
                />
              </div>

              {/* Keypoint: Combobox always shown */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Keypoint *
                </label>

                <Combobox<string | null>
                  value={currentExercise.keypointId || null}
                  onChange={(val: string | null) => {
                    setCurrentExercise((prev) =>
                      prev ? { ...prev, keypointId: val ?? "" } : prev,
                    );
                    setKeypointQuery("");
                  }}
                >
                  <div className="relative">
                    <Combobox.Input
                      displayValue={(val: string | null) => {
                        if (selectedKeypoint) {
                          return selectedKeypoint.title?.[lang] || "";
                        }
                        return keypointQuery;
                      }}
                      onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                        setKeypointQuery(e.target.value)
                      }
                      className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                      placeholder="Search keypoint..."
                    />

                    <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                      {keypoints
                        .filter((k) =>
                          k.title?.[lang]
                            ?.toLowerCase()
                            .includes(keypointQuery.toLowerCase()),
                        )
                        .map((c) => (
                          <Combobox.Option
                            key={c._id}
                            value={c._id}
                            className="cursor-pointer px-3 py-3 hover:bg-blue-50"
                          >
                            {c.title?.[lang]}
                          </Combobox.Option>
                        ))}
                    </Combobox.Options>
                  </div>
                </Combobox>
              </div>

              {/* Tags */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Tags
                </label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {currentExercise.tag?.map((tag, index) => (
                    <div
                      key={index}
                      className="flex items-center bg-indigo-100 rounded-md"
                    >
                      <input
                        type="text"
                        value={tag}
                        onChange={(e) => {
                          const newTags = [...(currentExercise.tag || [])];
                          newTags[index] = e.target.value;
                          setCurrentExercise({
                            ...currentExercise,
                            tag: newTags,
                          });
                        }}
                        className="px-3 py-1 bg-transparent border-0 focus:ring-0 text-sm"
                        placeholder="Enter tag"
                      />
                      <button
                        type="button"
                        onClick={() => {
                          const newTags = (currentExercise.tag || []).filter(
                            (_, i) => i !== index,
                          );
                          setCurrentExercise({
                            ...currentExercise,
                            tag: newTags,
                          });
                        }}
                        className="text-red-600 hover:text-red-800 px-2 py-1"
                      >
                        <svg
                          className="w-4 h-4"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                          xmlns="http://www.w3.org/2000/svg"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth="2"
                            d="M6 18L18 6M6 6l12 12"
                          ></path>
                        </svg>
                      </button>
                    </div>
                  ))}
                </div>
                <button
                  type="button"
                  onClick={() =>
                    setCurrentExercise({
                      ...currentExercise,
                      tag: [...(currentExercise.tag || []), ""],
                    })
                  }
                  className="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <svg
                    className="w-4 h-4 mr-1"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M12 4v16m8-8H4"
                    ></path>
                  </svg>
                  Add Tag
                </button>
              </div>

              {/* Index Input */}
              <div className="flex items-center justify-start gap-10">
                {/* Is Sub checkbox */}
                <div>
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={currentExercise.isSub}
                      onChange={(e) =>
                        setCurrentExercise({
                          ...currentExercise,
                          isSub: e.target.checked,
                        })
                      }
                      className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                    />
                    <span className="ml-2 block text-sm text-gray-700">
                      Is Sub
                    </span>
                  </label>
                </div>
              </div>
            </div>
            <div className="flex pt-4 gap-2 justify-end">
              <button
                onClick={handleSaveExercise}
                disabled={saving}
                className={`flex items-center justify-center gap-2 px-6 py-3 rounded-lg text-white font-semibold shadow transition ${
                  saving
                    ? "bg-gray-400 cursor-not-allowed"
                    : "bg-gradient-to-r from-blue-600 to-green-500 hover:opacity-90"
                }`}
              >
                {saving ? (
                  <>Saving...</>
                ) : isEditMode ? (
                  "Save Exercise"
                ) : (
                  "Create Exercise"
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Questions sections */}
        {currentExercise._id ? (
          <div className="mt-8">
            {renderQuestionsSection("questions", "Questions")}
            {renderQuestionsSection("subQuestions", "Sub Questions")}
          </div>
        ) : null}

        {/* If in edit mode, show Delete button */}
        {currentExercise._id && (
          <div className="flex justify-center mt-8">
            <button
              onClick={() => setConfirmDeleteExercise(true)}
              className="px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg shadow hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2"
            >
              <TrashIcon className="h-5 w-5" />
              Delete Exercise
            </button>
          </div>
        )}

        {/* Delete confirmation modal */}
        <AnimatePresence>
          {confirmDeleteExercise && (
            <LearningItemConfirm
              title="Confirm Delete"
              message="Are you sure you want to delete this exercise? This action cannot be undone."
              onCancel={() => setConfirmDeleteExercise(false)}
              onConfirm={handleDeleteExercise}
            />
          )}
        </AnimatePresence>

        {/* Exercise type selection popup */}
        <AnimatePresence>
          {showExerciseTypePopup && (
            <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[9999]">
              <motion.div
                initial={{ opacity: 0, y: 100 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 100 }}
                className="bg-white w-full max-w-md rounded-t-2xl shadow-xl p-6"
              >
                <h2 className="text-xl font-bold mb-4">Select Question Type</h2>
                <div className="grid grid-cols-2 gap-4">
                  <button
                    onClick={() =>
                      handleSelectExerciseType(ExerciseType.SINGLE_CHOICE)
                    }
                    className="p-4 bg-blue-50 rounded-lg hover:bg-blue-100 transition flex flex-col items-center gap-2"
                  >
                    <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                      <span className="text-blue-600 font-bold">A</span>
                    </div>
                    <span className="font-medium">Single Choice</span>
                  </button>
                  <button
                    onClick={() =>
                      handleSelectExerciseType(
                        ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER,
                      )
                    }
                    className="p-4 bg-cyan-50 rounded-lg hover:bg-cyan-100 transition flex flex-col items-center gap-2"
                  >
                    <div className="w-10 h-10 rounded-full bg-cyan-100 flex items-center justify-center">
                      <span className="text-cyan-600 font-bold">S</span>
                    </div>
                    <span className="font-medium">
                      Single Choice No Correct Answer
                    </span>
                  </button>
                  <button
                    onClick={() =>
                      handleSelectExerciseType(ExerciseType.MULTIPLE_CHOICE)
                    }
                    className="p-4 bg-purple-50 rounded-lg hover:bg-purple-100 transition flex flex-col items-center gap-2"
                  >
                    <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center">
                      <span className="text-purple-600 font-bold">A</span>
                    </div>
                    <span className="font-medium">Multiple Choice</span>
                  </button>
                  <button
                    onClick={() =>
                      handleSelectExerciseType(ExerciseType.DRAG_DROP)
                    }
                    className="p-4 bg-green-50 rounded-lg hover:bg-green-100 transition flex flex-col items-center gap-2"
                  >
                    <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="h-6 w-6 text-green-600"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"
                        />
                      </svg>
                    </div>
                    <span className="font-medium">Drag & Drop</span>
                  </button>
                  <button
                    onClick={() =>
                      handleSelectExerciseType(ExerciseType.RECORD)
                    }
                    className="p-4 bg-red-50 rounded-lg hover:bg-red-100 transition flex flex-col items-center gap-2"
                  >
                    <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="h-6 w-6 text-red-600"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"
                        />
                      </svg>
                    </div>
                    <span className="font-medium">Recording</span>
                  </button>
                </div>
                <button
                  onClick={() => {
                    setShowExerciseTypePopup(false);
                    setCurrentSectionForPopup(null);
                  }}
                  className="mt-6 w-full py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition"
                >
                  Cancel
                </button>
              </motion.div>
            </div>
          )}
        </AnimatePresence>

        {/* Question form modal */}
        <AnimatePresence>
          {modalOpen.section && (
            <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[9999]">
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="bg-white w-[600px] rounded-xl shadow-xl flex flex-col"
                style={{ maxHeight: "90vh" }}
              >
                <div className="p-6 pt-6 border-b border-gray-200 flex justify-between items-center">
                  <h2 className="text-xl font-bold">
                    {modalOpen.question ? (
                      <>
                        Edit Question
                        {modalOpen.question.id != null ? (
                          <>
                            {" "}
                            <span className="text-black font-semibold">
                              {modalOpen.question.id}
                            </span>
                          </>
                        ) : null}
                      </>
                    ) : (
                      "New Question"
                    )}
                  </h2>

                  <button
                    onClick={() =>
                      setModalOpen({
                        section: null,
                        questionType: ExerciseType.SINGLE_CHOICE,
                      })
                    }
                    className="text-gray-500 hover:text-gray-700 p-1 rounded-full transition-colors"
                  >
                    <XMarkIcon className="h-6 w-6" />
                  </button>
                </div>

                <div className="flex-grow overflow-y-auto p-6 relative">
                  <QuestionForm
                    question={modalOpen.question}
                    onSave={handleSaveQuestionAndExercise}
                    onCancel={() =>
                      setModalOpen({
                        section: null,
                        questionType: ExerciseType.SINGLE_CHOICE,
                      })
                    }
                    questionType={modalOpen.questionType}
                    section={modalOpen.section}
                    formData={modalOpen.formData}
                  />
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>

        {/* Delete confirmation modal for questions */}
        <AnimatePresence>
          {confirmDeleteQuestion && (
            <LearningItemConfirm
              title="Confirm Delete"
              message={`Are you sure you want to delete "${confirmDeleteQuestion.itemTitle}"?`}
              onCancel={() => setConfirmDeleteQuestion(null)}
              onConfirm={handleDeleteQuestionAndSaveExercise}
            />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
