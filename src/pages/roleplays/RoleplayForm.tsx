import React, { useState, useEffect } from "react";
import {
  ILearningItem,
  LearningItemPayload,
  ExerciseInput,
  ExerciseInputPayload,
} from "../../types/interface/learning-item/learning-item.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { learningItemService } from "../../services/learningItemService";
import {
  LearningItemType,
  ExerciseType,
  FormDragDropType,
  RoleplaySectionType,
  SectionConversationPosition,
} from "../../types/enum/learningItem.enum";
import { KeypointLevel } from "../../utils/enum/course.enum";
import { PlusCircleIcon, TrashIcon } from "@heroicons/react/24/outline";
import { PlusIcon, XMarkIcon } from "@heroicons/react/24/solid";
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
import { DocumentType } from "../../utils/enum/course.enum";
import {
  IExerciseChoiceOption,
  IExerciseSingleChoice,
} from "../../types/interface/learning-item/excercises/single-choice.interface";
import { IExerciseDragDrop } from "../../types/interface/learning-item/excercises/drag-drop.interface";
import {
  IExerciseRecord,
  IScoringCriteria,
} from "../../types/interface/learning-item/excercises/record.interface";
import {
  IDocument,
  IMediaDocument,
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
import { avatarService } from "../../services/avatarService";
import { iconService } from "../../services/iconService";
import {
  IConversation,
  IHint,
  ILeadingText,
  ISection,
  ISectionContent,
  ISectionContentPayload,
  ISectionPayload,
} from "../../types/interface/learning-item/roleplays/section.interface";
import { IAvatar } from "../../types/interface/avatar.interface";

const TEXTUAL_DOCUMENT_TYPES: DocumentType[] = [
  DocumentType.TITLE,
  DocumentType.CAPTION,
  DocumentType.TEXT,
];

const isTextualDocumentType = (type: DocumentType) =>
  TEXTUAL_DOCUMENT_TYPES.includes(type);

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

const createEmptyMediaDocument = (currentLang: LangCode): IMediaDocument => ({
  content: { [currentLang]: "" },
  url: "",
  thumbnail: "",
});

const distributeEvenlyIntegers = (slots: number, total: number) => {
  if (slots <= 0) return [];
  const base = Math.floor(total / slots);
  let remainder = total - base * slots;
  return Array.from({ length: slots }, () => {
    if (remainder > 0) {
      remainder -= 1;
      return base + 1;
    }
    return base;
  });
};

const scaleValuesToTotal = (values: number[], target: number) => {
  if (!values.length) return [];
  const normalized = values.map((val) => Math.max(0, Math.round(val)));
  const total = normalized.reduce((sum, val) => sum + val, 0);

  if (total === 0) {
    return distributeEvenlyIntegers(values.length, target);
  }

  const raw = normalized.map((val) => (val / total) * target);
  const floored = raw.map((val) => Math.floor(val));
  let remainder = target - floored.reduce((sum, val) => sum + val, 0);

  const fractionalOrder = raw
    .map((val, idx) => ({ idx, frac: val - floored[idx] }))
    .sort((a, b) => b.frac - a.frac);

  fractionalOrder.forEach(({ idx }) => {
    if (remainder > 0) {
      floored[idx] += 1;
      remainder -= 1;
    }
  });

  let cursor = 0;
  while (remainder > 0 && floored.length > 0) {
    floored[cursor % floored.length] += 1;
    remainder -= 1;
    cursor += 1;
  }

  return floored;
};

const rebalanceRecordScoringCriteria = (
  criteriaInput?: Partial<IScoringCriteria>[],
  exerciseMaxScore?: number,
  lang?: LangCode
): IScoringCriteria[] => {
  const isValidNumber = (value: unknown): value is number =>
    typeof value === "number" && !Number.isNaN(value);

  const sanitized =
    criteriaInput?.map((item) => ({
      criteria: (item.criteria ?? { en: "" }) as ITranslation,
      maxScore: isValidNumber(item.maxScore)
        ? Math.max(0, Math.round(item.maxScore))
        : undefined,
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

  if (manualSum > exerciseMaxScore) {
    const manualValues = manualIndices.map((idx) => result[idx].maxScore || 0);
    const scaled = scaleValuesToTotal(manualValues, exerciseMaxScore);
    manualIndices.forEach((idx, order) => {
      result[idx].maxScore = scaled[order] || 0;
    });
    manualSum = exerciseMaxScore;
  }

  const remaining = Math.max(0, exerciseMaxScore - manualSum);
  result[lastIndex].maxScore = remaining;

  return result.map((item) => ({
    ...item,
    maxScore: item.maxScore || 0,
  }));
};

// Helper component to display text with truncation and tooltip
const TextWithTooltip = ({
  text = "",
  maxLength = 150,
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
const TagDisplay = ({
  tag,
  lang,
}: {
  tag: ITag | null;
  lang: keyof ITranslation;
}) => {
  if (!tag) return null;

  return (
    <div className="flex items-center gap-1">
      {tag.url && (
        <img
          src={tag.url}
          alt={tag.title?.[lang] || ""}
          className="w-5 h-5 object-contain flex-shrink-0"
        />
      )}
      <span>{tag.title?.[lang]}</span>
    </div>
  );
};

// Color picker component with text input
const ColorPicker = ({
  value,
  onChange,
  label,
}: {
  value: string;
  onChange: (value: string) => void;
  label: string;
}) => {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
      </label>
      <div className="flex items-center gap-2">
        <input
          type="color"
          value={value || "#000000"}
          onChange={(e) => onChange(e.target.value)}
          className="h-10 w-20 border border-gray-300 rounded cursor-pointer"
        />
        <input
          type="text"
          value={value || "#000000"}
          onChange={(e) => onChange(e.target.value)}
          className="flex-1 border rounded-lg p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
          placeholder="#000000"
        />
      </div>
    </div>
  );
};

// Avatar selector component
const AvatarSelector = ({
  value,
  onChange,
  label,
}: {
  value: IAvatar | null | undefined;
  onChange: (value: IAvatar | null) => void;
  label: string;
}) => {
  const [avatars, setAvatars] = useState<IAvatar[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAvatars = async () => {
      try {
        const res = await avatarService.getList({ page: 1, take: 1000 });
        setAvatars(res.data.items || res.data || []);
      } catch (err) {
        console.error("fetchAvatars", err);
      } finally {
        setLoading(false);
      }
    };
    fetchAvatars();
  }, []);

  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
      </label>
      {loading ? (
        <div className="flex items-center justify-center h-20 border border-gray-200 rounded-lg">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
        </div>
      ) : (
        <div className="border border-gray-200 rounded-lg p-2 max-h-32 overflow-y-auto">
          <div className="grid grid-cols-8 gap-2">
            {avatars.map((avatar) => (
              <button
                key={avatar._id}
                type="button"
                onClick={() => onChange(avatar)}
                className={`w-full flex flex-col items-center gap-1 p-1 rounded-lg border-2 text-xs ${
                  value?._id === avatar._id
                    ? "border-blue-500"
                    : "border-gray-300"
                }`}
              >
                <div className="w-12 h-12 rounded-full overflow-hidden border">
                  <img
                    src={avatar.url}
                    alt={avatar.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                <span className="truncate max-w-[72px]">{avatar.name}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

// Icon selector component
const IconSelector = ({
  value,
  onChange,
  label,
}: {
  value: string;
  onChange: (value: string) => void;
  label: string;
}) => {
  const [icons, setIcons] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchIcons = async () => {
      try {
        const res = await iconService.getList({ page: 1, take: 100 });
        setIcons(res.data.items || []);
      } catch (err) {
        console.error("fetchIcons", err);
      } finally {
        setLoading(false);
      }
    };
    fetchIcons();
  }, []);

  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
      </label>
      {loading ? (
        <div className="flex items-center justify-center h-20 border border-gray-200 rounded-lg">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
        </div>
      ) : (
        <div className="border border-gray-200 rounded-lg p-2 max-h-32 overflow-y-auto">
          <div className="grid grid-cols-8 gap-2">
            {icons.map((icon) => (
              <button
                key={icon._id}
                type="button"
                onClick={() => onChange(icon.url)}
                className={`w-10 h-10 border-2 ${
                  value === icon.url ? "border-blue-500" : "border-gray-300"
                } overflow-hidden flex items-center justify-center`}
              >
                <img
                  src={icon.url}
                  alt={icon.name}
                  className="w-full h-full object-contain"
                />
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

// Keypoint selector component
const KeypointSelector = ({
  value,
  onChange,
  label,
}: {
  value: string;
  onChange: (value: string) => void;
  label: string;
}) => {
  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [keypointQuery, setKeypointQuery] = useState("");
  const [selectedKeypoint, setSelectedKeypoint] = useState<IKeypoint | null>(
    null
  );
  const lang = useSelector(
    (state: RootState) => state.lang.code
  ) as keyof ITranslation as LangCode;

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

  useEffect(() => {
    if (value) {
      const fetchKeypointDetail = async () => {
        try {
          const res = await keypointService.getById(value);
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
  }, [value]);

  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
      </label>
      <Combobox<string | null>
        value={value || null}
        onChange={(val: string | null) => {
          onChange(val ?? "");
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
            className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
            placeholder="Search keypoint..."
          />
          <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
            {keypoints
              .filter((k) =>
                k.title?.[lang]
                  ?.toLowerCase()
                  .includes(keypointQuery.toLowerCase())
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
  );
};

interface RoleplayFormProps {
  roleplay?: ILearningItem;
  onSave?: (roleplay: ILearningItem) => void;
  onCancel?: () => void;
}

export default function RoleplayForm({
  roleplay,
  onSave,
  onCancel,
}: RoleplayFormProps) {
  const navigate = useNavigate();
  const lang = useSelector(
    (state: RootState) => state.lang.code
  ) as keyof ITranslation as LangCode;
  const isEditMode = !!roleplay;
  const { showSuccess, showError } = useNotification();

  // State for keypoint search
  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [keypointQuery, setKeypointQuery] = useState("");
  const [selectedKeypoint, setSelectedKeypoint] = useState<IKeypoint | null>(
    null
  );

  // State for section ID counter
  const [nextSectionId, setNextSectionId] = useState(1);

  // State for content ID counter
  const [nextContentId, setNextContentId] = useState(1);

  // State for drag-drop option and answer ID counters
  const [nextOptionId, setNextOptionId] = useState(1);
  const [nextAnswerId, setNextAnswerId] = useState(1);

  // Sync roleplay prop -> local state
  const [currentRoleplay, setCurrentRoleplay] = useState<ILearningItem>(
    () =>
      roleplay ??
      ({
        _id: "",
        keypointId: "",
        type: LearningItemType.ROLEPLAY,
        title: { [lang]: "" },
        description: { [lang]: "" },
        image: "",
        isSub: false,
        tag: [],
        questions: [],
        subQuestions: [],
        documents: [],
        sections: [],
        index: 0,
      } as ILearningItem)
  );

  useEffect(() => {
    if (roleplay) {
      setCurrentRoleplay(roleplay);
      // Find max section ID and set nextSectionId accordingly
      const maxSectionId = [...(roleplay.sections || [])].reduce(
        (max, s) => Math.max(max, s.id ?? 0),
        0
      );
      setNextSectionId(maxSectionId + 1);

      // Find max content ID and set nextContentId accordingly
      const maxContentId = [...(roleplay.sections || [])]
        .flatMap((s) => s.contents || [])
        .reduce((max, c) => Math.max(max, c.id ?? 0), 0);
      setNextContentId(maxContentId + 1);

      // Find max option and answer IDs for drag-drop exercise
      const maxOptionId = [...(roleplay.sections || [])]
        .flatMap((s) => s.contents || [])
        .filter((c) => c.type === RoleplaySectionType.EXERCISE)
        .flatMap((c) => (c.exercise as IExerciseDragDrop)?.options || [])
        .reduce((max, opt) => Math.max(max, opt.id || 0), 0);
      setNextOptionId(maxOptionId + 1);

      const maxAnswerId = [...(roleplay.sections || [])]
        .flatMap((s) => s.contents || [])
        .filter((c) => c.type === RoleplaySectionType.EXERCISE)
        .flatMap((c) => (c.exercise as IExerciseDragDrop)?.answer || [])
        .reduce((max, ans) => Math.max(max, ans.id || 0), 0);
      setNextAnswerId(maxAnswerId + 1);
    } else {
      // Reset form when creating new roleplay
      setCurrentRoleplay({
        _id: "",
        keypointId: "",
        type: LearningItemType.ROLEPLAY,
        title: { [lang]: "" },
        description: { [lang]: "" },
        image: "",
        isSub: false,
        tag: [],
        questions: [],
        subQuestions: [],
        documents: [],
        sections: [],
        index: 0,
      } as ILearningItem);
      setNextSectionId(1);
      setNextContentId(1);
      setNextOptionId(1);
      setNextAnswerId(1);
    }
  }, [roleplay]); // Remove lang from dependency to prevent reset on language change

  // Separate effect to update title and description language when creating new roleplay
  useEffect(() => {
    if (!roleplay && currentRoleplay._id === "") {
      // Only update the title and description fields to ensure they have the current language
      setCurrentRoleplay((prev) => ({
        ...prev,
        title: { [lang]: (prev.title as ITranslation)?.[lang] || "" },
        description: {
          [lang]: (prev.description as ITranslation)?.[lang] || "",
        },
      }));
    }
  }, [lang, roleplay, currentRoleplay._id]);

  const [saving, setSaving] = useState(false);
  const [modalOpen, setModalOpen] = useState<{
    sectionId: number | null;
    contentType: RoleplaySectionType;
    content?: any;
    formData?: any;
  }>({ sectionId: null, contentType: RoleplaySectionType.CONVERSATION });
  const [confirmDeleteSection, setConfirmDeleteSection] = useState<{
    sectionId: number | null;
    sectionTitle: string;
  } | null>(null);
  const [confirmDeleteContent, setConfirmDeleteContent] = useState<{
    sectionId: number | null;
    contentId: number | null;
    contentTitle: string;
  } | null>(null);

  const [confirmDeleteRoleplay, setConfirmDeleteRoleplay] = useState(false);
  const [showContentTypePopup, setShowContentTypePopup] = useState(false);
  const [currentSectionForPopup, setCurrentSectionForPopup] = useState<
    number | null
  >(null);
  const [validationErrors, setValidationErrors] = useState<{
    [key: string]: string;
  }>({});

  const transformExerciseToPayload = (
    exercise?: ExerciseInput
  ): ExerciseInputPayload | undefined => {
    if (!exercise) return undefined;

    const exercisePayload = { ...(exercise as ExerciseInputPayload) };

    if ("tag" in exercisePayload) {
      const tagValue = (exercise as { tag?: ITag | string | null }).tag;
      (exercisePayload as { tag?: string }).tag =
        typeof tagValue === "string" ? tagValue : tagValue?._id || "";
    }

    // Clean ITranslation fields - only add if not empty
    if ("speechBubble" in exercisePayload && exercisePayload.speechBubble) {
      const cleanedSpeechBubble = cleanTranslation(
        exercisePayload.speechBubble as ITranslation
      );
      if (cleanedSpeechBubble) {
        (exercisePayload as any).speechBubble = cleanedSpeechBubble;
      } else {
        delete (exercisePayload as any).speechBubble;
      }
    }
    if ("explanation" in exercisePayload && exercisePayload.explanation) {
      const cleanedExplanation = cleanTranslation(
        exercisePayload.explanation as ITranslation
      );
      if (cleanedExplanation) {
        (exercisePayload as any).explanation = cleanedExplanation;
      } else {
        delete (exercisePayload as any).explanation;
      }
    }
    if ("targetArea" in exercisePayload && exercisePayload.targetArea) {
      const cleanedTargetArea = cleanTranslation(
        exercisePayload.targetArea as ITranslation
      );
      if (cleanedTargetArea) {
        (exercisePayload as any).targetArea = cleanedTargetArea;
      } else {
        delete (exercisePayload as any).targetArea;
      }
    }
    if (
      "options" in exercisePayload &&
      Array.isArray(exercisePayload.options)
    ) {
      (exercisePayload as any).options = exercisePayload.options.map(
        (opt: any) => {
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
        }
      );
    }
    if ("answer" in exercisePayload && Array.isArray(exercisePayload.answer)) {
      (exercisePayload as any).answer = exercisePayload.answer.map(
        (ans: any) => {
          const cleanedAnswer: any = { ...ans };
          const cleanedCorrectAnswer = cleanTranslation(ans.correctAnswer);
          if (cleanedCorrectAnswer) {
            cleanedAnswer.correctAnswer = cleanedCorrectAnswer;
          }
          return cleanedAnswer;
        }
      );
    }
    if (
      "document" in exercisePayload &&
      Array.isArray(exercisePayload.document)
    ) {
      (exercisePayload as any).document = exercisePayload.document.map(
        (doc: any) => {
          const cleanedDoc: any = { ...doc };
          if (doc.data?.content) {
            // Always include content field but clean empty translations
            cleanedDoc.data = {
              ...doc.data,
              content: cleanTranslation(doc.data.content) || {},
            };
          }
          return cleanedDoc;
        }
      );
    }

    return exercisePayload;
  };

  const transformSectionsToPayload = (
    sectionList?: ISection[]
  ): ISectionPayload[] | undefined => {
    if (!sectionList) return undefined;

    return sectionList.map((section) => {
      const sectionPayload: any = {
        id: section.id,
        textColor: section.textColor,
        backgroundColor: section.backgroundColor,
        image: section.image || "",
        contents: [],
      };

      // Always include title field but clean empty translations
      sectionPayload.title = cleanTranslation(section.title) || {};

      // Always include transition field but clean empty translations
      sectionPayload.transition = cleanTranslation(section.transition) || {};

      // Process contents
      if (section.contents?.length) {
        sectionPayload.contents = section.contents.map((content) => {
          const contentPayload: any = {
            id: content.id,
            type: content.type,
          };

          // Handle exercise content
          if (content.type === RoleplaySectionType.EXERCISE) {
            const exercisePayload = transformExerciseToPayload(
              content.exercise
            );
            if (exercisePayload) {
              contentPayload.exercise = exercisePayload;
            }
          }
          // Handle conversation content
          else if (
            content.type === RoleplaySectionType.CONVERSATION &&
            content.conversation
          ) {
            contentPayload.conversation = {
              position: content.conversation.position,
              backgroundColor: content.conversation.backgroundColor,
              textColor: content.conversation.textColor,
              avatarId:
                content.conversation.avatar?._id ||
                content.conversation.avatarId ||
                "",
              // Always include content field but clean empty translations
              content: content.conversation.content
                ? cleanTranslation(content.conversation.content) || {}
                : {},
              audio: content.conversation.audio || "",
            };
          }
          // Handle leading text content
          else if (
            content.type === RoleplaySectionType.LEADING_TEXT &&
            content.leadingText
          ) {
            contentPayload.leadingText = {
              ...content.leadingText,
              // Always include content field but clean empty translations
              content: content.leadingText.content
                ? cleanTranslation(content.leadingText.content) || {}
                : {},
            };
          }
          // Handle hint content
          else if (content.type === RoleplaySectionType.HINT && content.hint) {
            contentPayload.hint = {
              ...content.hint,
              // Always include content field but clean empty translations
              content: content.hint.content
                ? cleanTranslation(content.hint.content) || {}
                : {},
            };
          }

          return contentPayload as ISectionContentPayload;
        });
      }

      return sectionPayload;
    });
  };

  const buildLearningItemPayload = (
    item: ILearningItem
  ): LearningItemPayload => {
    const payload: any = {
      keypointId: item.keypointId,
      title: cleanTranslation(item.title) || {},
      type: LearningItemType.ROLEPLAY,
      image: item.image,
      tag: item.tag || [],
      isSub: item.isSub,
      sections: transformSectionsToPayload(item.sections),
      index: item.index,
    };

    const cleanedDescription = cleanTranslation(item.description);
    if (cleanedDescription && Object.keys(cleanedDescription).length > 0) {
      payload.description = cleanedDescription;
    }

    return payload as LearningItemPayload;
  };

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
    if (currentRoleplay.keypointId) {
      const fetchKeypointDetail = async () => {
        try {
          const res = await keypointService.getById(currentRoleplay.keypointId);

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
  }, [currentRoleplay.keypointId]);

  // Save entire roleplay (create or update)
  const handleSaveRoleplay = async () => {
    try {
      setSaving(true);
      const payload = buildLearningItemPayload(currentRoleplay);

      let res;
      if (currentRoleplay._id) {
        res = await learningItemService.update(currentRoleplay._id, payload);
      } else {
        res = await learningItemService.create(payload);
      }

      const savedRoleplay = res.data?.data ?? res.data;
      await new Promise((resolve) => setTimeout(resolve, 500));
      onSave?.(savedRoleplay);

      isEditMode
        ? showSuccess("Saved roleplay successfully")
        : showSuccess("Create roleplay successfully");
    } catch (err) {
      console.error("handleSaveRoleplay", err);
      showError("Failed to save roleplay");
    } finally {
      setSaving(false);
    }
  };

  // Reorder sections and reassign IDs
  const handleReorderSections = (activeId: number, overId: number) => {
    setCurrentRoleplay((prev) => {
      if (!prev) return prev;
      const list = prev.sections || [];

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

      // Update the next ID
      setNextSectionId(reassignedList.length + 1);

      return { ...prev, sections: reassignedList };
    });
  };

  // Reorder content within a section and reassign IDs
  const handleReorderContent = (
    sectionId: number,
    activeId: number,
    overId: number
  ) => {
    setCurrentRoleplay((prev) => {
      if (!prev) return prev;
      const sections = prev.sections || [];
      const sectionIndex = sections.findIndex((s) => s.id === sectionId);

      if (sectionIndex === -1) return prev;

      const section = sections[sectionIndex];
      const contentList = section.contents || [];

      const activeIndex = contentList.findIndex((item) => item.id === activeId);
      const overIndex = contentList.findIndex((item) => item.id === overId);

      if (activeIndex === -1 || overIndex === -1 || activeIndex === overIndex) {
        return prev;
      }

      const newContentList = arrayMove(contentList, activeIndex, overIndex);

      // Reassign IDs starting from 1
      const reassignedList = newContentList.map((item, index) => ({
        ...item,
        id: index + 1,
      }));

      // Update the section with the reordered content
      const updatedSections = [...sections];
      updatedSections[sectionIndex] = {
        ...section,
        contents: reassignedList,
      };

      return { ...prev, sections: updatedSections };
    });
  };

  // Open content type popup
  const handleOpenContentTypePopup = (sectionId: number) => {
    setCurrentSectionForPopup(sectionId);
    setShowContentTypePopup(true);
  };

  // Select content type and open content form
  const handleSelectContentType = (contentType: RoleplaySectionType) => {
    if (currentSectionForPopup === null) return;

    const formData = createEmptyContent(contentType, nextContentId);

    setModalOpen({
      sectionId: currentSectionForPopup,
      contentType,
      formData,
    });

    setShowContentTypePopup(false);
    setCurrentSectionForPopup(null);
  };

  const handleOpenModal = (
    sectionId: number,
    contentType: RoleplaySectionType,
    content?: any
  ) => {
    // If there is content data (editing), copy the data
    // If not (adding new), create empty content
    const formData = content
      ? { ...content }
      : createEmptyContent(contentType, nextContentId);

    // Open modal with corresponding information
    setModalOpen({ sectionId, contentType, content, formData });
  };

  // Create empty content based on type
  const createEmptyContent = (type: RoleplaySectionType, id: number) => {
    switch (type) {
      case RoleplaySectionType.CONVERSATION:
        return {
          id,
          type,
          conversation: {
            avatar: undefined,
            avatarId: "",
            position: SectionConversationPosition.LEFT,
            backgroundColor: "#FFFFFF",
            textColor: "#000000", // Added textColor
            content: { [lang]: "" },
            audio: "",
          } as IConversation,
        } as ISectionContent;
      case RoleplaySectionType.LEADING_TEXT:
        return {
          id,
          type,
          leadingText: {
            backgroundColor: "#000000",
            textColor: "#000000", // Added textColor
            content: { [lang]: "" },
            audio: "",
          } as ILeadingText,
        } as ISectionContent;
      case RoleplaySectionType.HINT:
        return {
          id,
          type,
          hint: {
            icon: "",
            textColor: "#000000", // Added textColor
            content: { [lang]: "" },
          } as IHint,
        } as ISectionContent;
      case RoleplaySectionType.EXERCISE:
        // Create a default single choice exercise
        return {
          id,
          type,
          exercise: {
            id: 1,
            type: ExerciseType.SINGLE_CHOICE,
            speechBubble: { [lang]: "" },
            tag: null,
            keypointId: "",
            document: [
              {
                id: 1,
                type: DocumentType.TEXT,
                data: createEmptyMediaDocument(lang),
              },
            ],
            explanation: { [lang]: "" },
            options: [
              { value: { [lang]: "" }, isCorrect: false },
              { value: { [lang]: "" }, isCorrect: false },
            ] as IExerciseChoiceOption[],
            level: [KeypointLevel.WEAK_POINT],
            maxScore: 10,
            completionTime: 60,
            mainQuestion: 0,
          } as IExerciseSingleChoice,
        } as ISectionContent;
      default:
        return null;
    }
  };

  // Request delete section
  const requestDeleteSection = (
    sectionId: number,
    sectionTitle = "section"
  ) => {
    setConfirmDeleteSection({ sectionId, sectionTitle });
  };

  // Request delete content
  const requestDeleteContent = (
    sectionId: number,
    contentId: number,
    contentTitle = "content"
  ) => {
    setConfirmDeleteContent({ sectionId, contentId, contentTitle });
  };

  // Delete entire roleplay
  const handleDeleteRoleplay = async () => {
    if (!currentRoleplay._id) return;
    try {
      await learningItemService.remove(currentRoleplay._id);
      setConfirmDeleteRoleplay(false);
      if (onCancel) {
        onCancel();
      } else {
        navigate("/roleplay");
      }
    } catch (err) {
      console.error(err);
    } finally {
      setConfirmDeleteRoleplay(false);
    }
  };

  // Handle saving content and roleplay together
  const handleSaveContentAndRoleplay = async (contentData: any) => {
    try {
      // Xóa lỗi cũ
      setValidationErrors({});

      // Chuẩn hóa avatarId cho conversation
      let normalizedContent = contentData;
      if (
        contentData.type === RoleplaySectionType.CONVERSATION &&
        contentData.conversation
      ) {
        const avatarObj = contentData.conversation.avatar;
        const avatarId =
          contentData.conversation.avatarId || avatarObj?._id || "";
        normalizedContent = {
          ...contentData,
          conversation: {
            ...contentData.conversation,
            avatar: avatarObj,
            avatarId,
          },
        };
      }

      // Thực hiện xác thực dựa trên loại nội dung
      let hasError = false;
      const errors: { [key: string]: string } = {};

      if (normalizedContent.type === RoleplaySectionType.CONVERSATION) {
        if (!normalizedContent.conversation.avatarId) {
          errors.avatar = "Avatar is required for conversation content";
          hasError = true;
        }
      } else if (normalizedContent.type === RoleplaySectionType.LEADING_TEXT) {
        if (
          !getCurrentTranslationValue(
            normalizedContent.leadingText.content,
            lang
          )
        ) {
          errors.content = "Content is required for leading text";
          hasError = true;
        }
      } else if (normalizedContent.type === RoleplaySectionType.HINT) {
        if (!normalizedContent.hint.icon) {
          errors.icon = "Icon is required for hint content";
          hasError = true;
        }
        if (!getCurrentTranslationValue(normalizedContent.hint.content, lang)) {
          errors.hintContent = "Content is required for hint content";
          hasError = true;
        }
      }

      // Nếu có lỗi, cập nhật state và dừng việc lưu
      if (hasError) {
        setValidationErrors(errors);
        return;
      }

      setSaving(true);

      let updatedRoleplay;
      if (modalOpen.content) {
        // Update existing content
        const sectionId = modalOpen.sectionId!;
        const sections = currentRoleplay.sections || [];
        const sectionIndex = sections.findIndex((s) => s.id === sectionId);

        if (sectionIndex === -1) return;

        const section = sections[sectionIndex];
        const contentList = section.contents || [];
        const updatedContentList = contentList.map((c) =>
          c.id === normalizedContent.id ? normalizedContent : c
        );

        const updatedSections = [...sections];
        updatedSections[sectionIndex] = {
          ...section,
          contents: updatedContentList,
        };

        updatedRoleplay = { ...currentRoleplay, sections: updatedSections };
      } else {
        // Add new content
        const sectionId = modalOpen.sectionId!;
        const sections = currentRoleplay.sections || [];
        const sectionIndex = sections.findIndex((s) => s.id === sectionId);

        if (sectionIndex === -1) return;

        const section = sections[sectionIndex];
        const contentList = section.contents || [];
        const updatedContentList = [...contentList, normalizedContent];

        const updatedSections = [...sections];
        updatedSections[sectionIndex] = {
          ...section,
          contents: updatedContentList,
        };

        updatedRoleplay = { ...currentRoleplay, sections: updatedSections };

        // Update the next content ID
        setNextContentId(nextContentId + 1);
      }

      setCurrentRoleplay(updatedRoleplay);

      const payload = buildLearningItemPayload(updatedRoleplay);

      if (updatedRoleplay._id) {
        await learningItemService.update(updatedRoleplay._id, payload);
      } else {
        const res = await learningItemService.create(payload);
        const savedRoleplay = res.data?.data ?? res.data;
        setCurrentRoleplay(savedRoleplay);
        onSave?.(savedRoleplay);
      }

      showSuccess("Content saved successfully");
      setModalOpen({
        sectionId: null,
        contentType: RoleplaySectionType.CONVERSATION,
      });
    } catch (err) {
      console.error("handleSaveContentAndRoleplay", err);
      showError("Failed to save content");
    } finally {
      setSaving(false);
    }
  };

  // Handle deleting content and saving roleplay together
  const handleDeleteContentAndSaveRoleplay = async () => {
    if (!confirmDeleteContent) return;
    const { sectionId, contentId } = confirmDeleteContent;
    if (!sectionId || !contentId) {
      setConfirmDeleteContent(null);
      return;
    }

    try {
      setSaving(true);

      const sections = currentRoleplay.sections || [];
      const sectionIndex = sections.findIndex((s) => s.id === sectionId);

      if (sectionIndex === -1) return;

      const section = sections[sectionIndex];
      const contentList = section.contents || [];
      const updatedContentList = contentList.filter((c) => c.id !== contentId);

      const reassignedList = updatedContentList.map((item, index) => ({
        ...item,
        id: index + 1,
      }));

      const updatedSections = [...sections];
      updatedSections[sectionIndex] = {
        ...section,
        contents: reassignedList,
      };

      const updatedRoleplay = { ...currentRoleplay, sections: updatedSections };
      setCurrentRoleplay(updatedRoleplay);

      const payload = buildLearningItemPayload(updatedRoleplay);

      if (updatedRoleplay._id) {
        await learningItemService.update(updatedRoleplay._id, payload);
      }

      showSuccess("Content deleted successfully");
      setConfirmDeleteContent(null);
    } catch (err) {
      console.error("handleDeleteContentAndSaveRoleplay", err);
      showError("Failed to delete content");
    } finally {
      setSaving(false);
    }
  };

  // Handle deleting section and saving roleplay together
  const handleDeleteSectionAndSaveRoleplay = async () => {
    if (!confirmDeleteSection) return;
    const { sectionId } = confirmDeleteSection;
    if (!sectionId) {
      setConfirmDeleteSection(null);
      return;
    }

    try {
      setSaving(true);

      const sections = currentRoleplay.sections || [];
      const updatedSections = sections.filter((s) => s.id !== sectionId);

      const reassignedList = updatedSections.map((item, index) => ({
        ...item,
        id: index + 1,
      }));

      setNextSectionId(reassignedList.length + 1);

      const updatedRoleplay = { ...currentRoleplay, sections: reassignedList };
      setCurrentRoleplay(updatedRoleplay);

      const payload = buildLearningItemPayload(updatedRoleplay);

      if (updatedRoleplay._id) {
        await learningItemService.update(updatedRoleplay._id, payload);
      }

      showSuccess("Section deleted successfully");
      setConfirmDeleteSection(null);
    } catch (err) {
      console.error("handleDeleteSectionAndSaveRoleplay", err);
      showError("Failed to delete section");
    } finally {
      setSaving(false);
    }
  };

  // Add new section
  const addNewSection = () => {
    const newSection: ISection = {
      id: nextSectionId,
      title: { [lang]: `Section ${nextSectionId}` },
      transition: { [lang]: "" },
      textColor: "#000000",
      backgroundColor: "#ffffff",
      image: "", // Added image field
      contents: [],
    };

    setCurrentRoleplay((prev) => ({
      ...prev,
      sections: [...(prev.sections || []), newSection],
    }));

    setNextSectionId(nextSectionId + 1);
  };

  // Update section title
  const updateSectionTitle = (sectionId: number, title: ITranslation) => {
    setCurrentRoleplay((prev) => {
      const sections = prev.sections || [];
      const sectionIndex = sections.findIndex((s) => s.id === sectionId);

      if (sectionIndex === -1) return prev;

      const updatedSections = [...sections];
      updatedSections[sectionIndex] = {
        ...updatedSections[sectionIndex],
        title,
      };

      return { ...prev, sections: updatedSections };
    });
  };

  // Update section transition
  const updateSectionTransition = (
    sectionId: number,
    transition: ITranslation
  ) => {
    setCurrentRoleplay((prev) => {
      const sections = prev.sections || [];
      const sectionIndex = sections.findIndex((s) => s.id === sectionId);

      if (sectionIndex === -1) return prev;

      const updatedSections = [...sections];
      updatedSections[sectionIndex] = {
        ...updatedSections[sectionIndex],
        transition,
      };

      return { ...prev, sections: updatedSections };
    });
  };

  // Update section transition text color
  const updateSectionTransitionTextColor = (
    sectionId: number,
    textColor: string
  ) => {
    setCurrentRoleplay((prev) => {
      const sections = prev.sections || [];
      const sectionIndex = sections.findIndex((s) => s.id === sectionId);

      if (sectionIndex === -1) return prev;

      const updatedSections = [...sections];
      updatedSections[sectionIndex] = {
        ...updatedSections[sectionIndex],
        textColor,
      };

      return { ...prev, sections: updatedSections };
    });
  };

  // Update section transition backgound color
  const updateSectionTransitionBackgoundColor = (
    sectionId: number,
    backgroundColor: string
  ) => {
    setCurrentRoleplay((prev) => {
      const sections = prev.sections || [];
      const sectionIndex = sections.findIndex((s) => s.id === sectionId);

      if (sectionIndex === -1) return prev;

      const updatedSections = [...sections];
      updatedSections[sectionIndex] = {
        ...updatedSections[sectionIndex],
        backgroundColor,
      };

      return { ...prev, sections: updatedSections };
    });
  };

  // Update section image
  const updateSectionImage = (sectionId: number, image: string) => {
    setCurrentRoleplay((prev) => {
      const sections = prev.sections || [];
      const sectionIndex = sections.findIndex((s) => s.id === sectionId);

      if (sectionIndex === -1) return prev;

      const updatedSections = [...sections];
      updatedSections[sectionIndex] = {
        ...updatedSections[sectionIndex],
        image,
      };

      return { ...prev, sections: updatedSections };
    });
  };

  // Render sections with drag and drop
  const renderSections = () => {
    const sections = currentRoleplay.sections || [];

    return (
      <div className="mb-6 bg-gray-50 rounded-xl p-6 shadow-sm">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-800">
            Roleplay Sections
          </h2>
        </div>

        <p className="text-sm text-gray-500 mb-4">
          👉 Drag to reorder sections. Click on section to edit.
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

              handleReorderSections(activeId, overId);
            }
          }}
        >
          <SortableContext
            items={sections.map((item) => item.id!.toString())}
            strategy={verticalListSortingStrategy}
          >
            {sections.length > 0 ? (
              <div className="space-y-3">
                {sections.map((section) => (
                  <SortableItem key={section.id} id={section.id!.toString()}>
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                    >
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex items-center gap-2">
                          <h3 className="font-medium text-gray-800">
                            {getTranslationValue(section.title, lang)}
                          </h3>
                          <span className="text-xs text-gray-500">
                            ID: {section.id}
                          </span>
                        </div>
                        <div className="flex gap-1">
                          <button
                            onClick={() =>
                              requestDeleteSection(
                                section.id || 0,
                                getTranslationValue(section.title, lang)
                              )
                            }
                            className="text-red-500 hover:text-red-700 p-1 rounded"
                            title="Delete Section"
                          >
                            <TrashIcon className="h-5 w-5" />
                          </button>
                        </div>
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-4 gap-3 mb-3">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Section Title
                          </label>
                          <input
                            type="text"
                            value={getCurrentTranslationValue(
                              section.title,
                              lang
                            )}
                            onChange={(e) =>
                              updateSectionTitle(
                                section.id,
                                updateTranslationValue(
                                  section.title || {},
                                  lang,
                                  e.target.value
                                )
                              )
                            }
                            className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                            placeholder="Enter section title"
                          />
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Transition
                          </label>
                          <input
                            type="text"
                            value={getCurrentTranslationValue(
                              section.transition,
                              lang
                            )}
                            onChange={(e) =>
                              updateSectionTransition(
                                section.id,
                                updateTranslationValue(
                                  section.transition || {},
                                  lang,
                                  e.target.value
                                )
                              )
                            }
                            className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                            placeholder="Enter transition text"
                          />
                        </div>
                        <div>
                          <ColorPicker
                            value={section.backgroundColor || "#000000"}
                            onChange={(value) =>
                              updateSectionTransitionBackgoundColor(
                                section.id,
                                value
                              )
                            }
                            label="Backgound Color"
                          />
                        </div>
                        <div>
                          <ColorPicker
                            value={section.textColor || "#ffffff"}
                            onChange={(value) =>
                              updateSectionTransitionTextColor(
                                section.id,
                                value
                              )
                            }
                            label="Text Color"
                          />
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Section Image
                          </label>
                          <CloudflareFileUpload
                            initialUrl={section.image || ""}
                            onUrlChange={(url) =>
                              updateSectionImage(section.id, url)
                            }
                            label=""
                            uploadPayload={{
                              prefix: "",
                              folder: "roleplays",
                            }}
                          />
                        </div>
                      </div>

                      <div className="border-t pt-3">
                        <div className="flex justify-between items-center mb-2">
                          <h4 className="text-sm font-medium text-gray-700">
                            Content
                          </h4>
                        </div>

                        {section.contents && section.contents.length > 0 ? (
                          <DndContext
                            collisionDetection={closestCenter}
                            onDragEnd={(event) => {
                              const { active, over } = event;

                              if (over && active.id !== over.id) {
                                const activeId =
                                  typeof active.id === "string"
                                    ? parseInt(active.id)
                                    : active.id;
                                const overId =
                                  typeof over.id === "string"
                                    ? parseInt(over.id)
                                    : over.id;

                                handleReorderContent(
                                  section.id,
                                  activeId,
                                  overId
                                );
                              }
                            }}
                          >
                            <SortableContext
                              items={section.contents.map((item) =>
                                item.id!.toString()
                              )}
                              strategy={verticalListSortingStrategy}
                            >
                              <div className="space-y-2">
                                {section.contents.map((content) => (
                                  <SortableItem
                                    key={content.id}
                                    id={content.id!.toString()}
                                  >
                                    <div className="bg-gray-50 border border-gray-200 rounded p-2 hover:bg-gray-100 transition-colors">
                                      <div className="flex items-center justify-between">
                                        <div className="flex items-center gap-2">
                                          <span className="text-xs font-medium text-pink-400">
                                            {content.type}
                                          </span>
                                          {content.type ===
                                            RoleplaySectionType.CONVERSATION && (
                                            <div className="flex items-center gap-1">
                                              {content.conversation.avatar
                                                ?.url && (
                                                <img
                                                  src={
                                                    content.conversation.avatar
                                                      .url
                                                  }
                                                  alt={
                                                    content.conversation.avatar
                                                      .name
                                                  }
                                                  className="w-4 h-4 rounded-full object-cover"
                                                />
                                              )}
                                              <span className="text-xs text-gray-500">
                                                {
                                                  content.conversation.avatar
                                                    ?.name
                                                }
                                              </span>
                                              <div
                                                className="w-3 h-3 rounded-full border border-gray-300"
                                                style={{
                                                  backgroundColor:
                                                    content.conversation
                                                      .backgroundColor,
                                                }}
                                              ></div>
                                              <div
                                                className="w-3 h-3 rounded-full border border-gray-300"
                                                style={{
                                                  backgroundColor:
                                                    content.conversation
                                                      .textColor,
                                                }}
                                              ></div>
                                              <span className="text-xs text-gray-500">
                                                {content.conversation.position}
                                              </span>
                                              {content.conversation.audio && (
                                                <svg
                                                  xmlns="http://www.w3.org/2000/svg"
                                                  className="h-3 w-3 text-gray-500"
                                                  fill="none"
                                                  viewBox="0 0 24 24"
                                                  stroke="currentColor"
                                                >
                                                  <path
                                                    strokeLinecap="round"
                                                    strokeLinejoin="round"
                                                    strokeWidth={2}
                                                    d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"
                                                  />
                                                </svg>
                                              )}
                                              <TextWithTooltip
                                                text={
                                                  content.conversation.content
                                                }
                                                maxLength={100}
                                                lang={lang}
                                              />
                                            </div>
                                          )}
                                          {content.type ===
                                            RoleplaySectionType.LEADING_TEXT && (
                                            <div className="flex items-center gap-1">
                                              <div
                                                className="w-3 h-3 rounded-full border border-gray-300"
                                                style={{
                                                  backgroundColor:
                                                    content.leadingText
                                                      .backgroundColor,
                                                }}
                                              ></div>
                                              <div
                                                className="w-3 h-3 rounded-full border border-gray-300"
                                                style={{
                                                  backgroundColor:
                                                    content.leadingText
                                                      .textColor,
                                                }}
                                              ></div>
                                              {content.leadingText.audio && (
                                                <svg
                                                  xmlns="http://www.w3.org/2000/svg"
                                                  className="h-3 w-3 text-gray-500"
                                                  fill="none"
                                                  viewBox="0 0 24 24"
                                                  stroke="currentColor"
                                                >
                                                  <path
                                                    strokeLinecap="round"
                                                    strokeLinejoin="round"
                                                    strokeWidth={2}
                                                    d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"
                                                  />
                                                </svg>
                                              )}
                                              <TextWithTooltip
                                                text={
                                                  content.leadingText.content
                                                }
                                                maxLength={100}
                                                lang={lang}
                                              />
                                            </div>
                                          )}
                                          {content.type ===
                                            RoleplaySectionType.HINT && (
                                            <div className="flex items-center gap-1">
                                              {content.hint.icon && (
                                                <img
                                                  src={content.hint.icon}
                                                  alt="Hint icon"
                                                  className="w-4 h-4 object-contain"
                                                />
                                              )}
                                              <div
                                                className="w-3 h-3 rounded-full border border-gray-300"
                                                style={{
                                                  backgroundColor:
                                                    content.hint.textColor,
                                                }}
                                              ></div>
                                              <TextWithTooltip
                                                text={content.hint.content}
                                                maxLength={100}
                                                lang={lang}
                                              />
                                            </div>
                                          )}
                                          {content.type ===
                                            RoleplaySectionType.EXERCISE && (
                                            <div className="flex flex-col gap-1">
                                              <div className="flex items-center gap-1">
                                                <span className="text-xs text-gray-500">
                                                  {content.exercise.type}
                                                </span>
                                                {content.exercise
                                                  .speechBubble && (
                                                  <TextWithTooltip
                                                    text={
                                                      content.exercise
                                                        .speechBubble
                                                    }
                                                    maxLength={100}
                                                    lang={lang}
                                                  />
                                                )}
                                                {content.exercise.tag && (
                                                  <div className="ml-7">
                                                    <TagDisplay
                                                      tag={content.exercise.tag}
                                                      lang={lang}
                                                    />
                                                  </div>
                                                )}
                                              </div>
                                              {content.exercise.maxScore && (
                                                <span className="text-xs font-medium text-gray-600">
                                                  Max score:{" "}
                                                  {content.exercise.maxScore}
                                                </span>
                                              )}
                                              {content.exercise
                                                .completionTime && (
                                                <span className="text-xs font-medium text-gray-600">
                                                  Completion Time:{" "}
                                                  {
                                                    content.exercise
                                                      .completionTime
                                                  }
                                                </span>
                                              )}
                                              {content.exercise.keypointId && (
                                                <span className="text-xs font-medium text-gray-600">
                                                  Keypoint:{" "}
                                                  {
                                                    keypoints.find(
                                                      (k) =>
                                                        k._id ===
                                                        content.exercise
                                                          .keypointId
                                                    )?.title?.[lang]
                                                  }
                                                </span>
                                              )}
                                              {content.exercise.document &&
                                                content.exercise.document
                                                  .length > 0 && (
                                                  <div className="mt-1 p-1 bg-gray-100 rounded">
                                                    <span className="text-xs font-medium text-gray-600">
                                                      Documents:
                                                    </span>
                                                    {content.exercise.document.map(
                                                      (
                                                        doc: IDocument,
                                                        index: number
                                                      ) => (
                                                        <div
                                                          key={index}
                                                          className="ml-2 mt-1 text-xs"
                                                        >
                                                          <span className="font-semibold text-green-600">
                                                            {doc.type.toUpperCase()}
                                                          </span>
                                                          {isTextualDocumentType(
                                                            doc.type
                                                          ) &&
                                                            doc.data
                                                              .content && (
                                                              <div className="ml-1">
                                                                <TextWithTooltip
                                                                  text={
                                                                    doc.data
                                                                      .content
                                                                  }
                                                                  maxLength={
                                                                    100
                                                                  }
                                                                  lang={lang}
                                                                />
                                                              </div>
                                                            )}
                                                          {doc.type ===
                                                            DocumentType.IMAGE &&
                                                            doc.data.url && (
                                                              <div className="ml-1">
                                                                <TextWithTooltip
                                                                  text={
                                                                    doc.data.url
                                                                  }
                                                                  maxLength={
                                                                    100
                                                                  }
                                                                />
                                                              </div>
                                                            )}
                                                          {doc.type ===
                                                            DocumentType.AUDIO &&
                                                            doc.data.url && (
                                                              <div className="ml-1">
                                                                <TextWithTooltip
                                                                  text={
                                                                    doc.data.url
                                                                  }
                                                                  maxLength={
                                                                    100
                                                                  }
                                                                />
                                                              </div>
                                                            )}
                                                          {doc.type ===
                                                            DocumentType.VIDEO && (
                                                            <>
                                                              {doc.data.url && (
                                                                <div className="ml-1">
                                                                  <TextWithTooltip
                                                                    text={
                                                                      doc.data
                                                                        .url
                                                                    }
                                                                    maxLength={
                                                                      100
                                                                    }
                                                                  />
                                                                </div>
                                                              )}
                                                              {doc.data
                                                                .thumbnail && (
                                                                <div className="ml-1">
                                                                  <TextWithTooltip
                                                                    text={
                                                                      doc.data
                                                                        .thumbnail
                                                                    }
                                                                    maxLength={
                                                                      100
                                                                    }
                                                                  />
                                                                </div>
                                                              )}
                                                            </>
                                                          )}
                                                        </div>
                                                      )
                                                    )}
                                                  </div>
                                                )}
                                              {content.exercise.explanation && (
                                                <div className="flex items-center gap-1">
                                                  <svg
                                                    xmlns="http://www.w3.org/2000/svg"
                                                    className="h-3 w-3 text-gray-500"
                                                    fill="none"
                                                    viewBox="0 0 24 24"
                                                    stroke="currentColor"
                                                  >
                                                    <path
                                                      strokeLinecap="round"
                                                      strokeLinejoin="round"
                                                      strokeWidth={2}
                                                      d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                                                    />
                                                  </svg>
                                                  <TextWithTooltip
                                                    text={
                                                      content.exercise
                                                        .explanation
                                                    }
                                                    maxLength={100}
                                                    lang={lang}
                                                  />
                                                </div>
                                              )}
                                              {(content.exercise.type ===
                                                ExerciseType.SINGLE_CHOICE ||
                                                content.exercise.type ===
                                                  ExerciseType.MULTIPLE_CHOICE) &&
                                                Array.isArray(
                                                  (content.exercise as any)
                                                    .options
                                                ) && (
                                                  <div className="mt-1 p-1 bg-gray-100 rounded">
                                                    <span className="text-xs font-medium text-gray-600">
                                                      Options:
                                                    </span>
                                                    <ul className="mt-1 space-y-1">
                                                      {(
                                                        content.exercise as any
                                                      ).options.map(
                                                        (
                                                          opt: any,
                                                          idx: number
                                                        ) => (
                                                          <li
                                                            key={idx}
                                                            className="flex items-center"
                                                          >
                                                            <span
                                                              className={`w-2 h-2 rounded-full mr-1 ${
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
                                                        )
                                                      )}
                                                    </ul>
                                                  </div>
                                                )}
                                              {content.exercise.type ===
                                                ExerciseType.DRAG_DROP && (
                                                <div className="mt-1 p-1 bg-gray-100 rounded">
                                                  <div className="flex items-center gap-1 mb-1">
                                                    <span className="text-xs font-medium text-gray-600">
                                                      Form:
                                                    </span>
                                                    <span className="text-xs text-gray-500">
                                                      {"form" in
                                                        content.exercise &&
                                                        (content.exercise
                                                          .form ||
                                                          "Not specified")}
                                                    </span>
                                                  </div>
                                                  {"targetArea" in
                                                    content.exercise &&
                                                    content.exercise
                                                      .targetArea && (
                                                      <div className="flex items-center gap-1 mb-1">
                                                        <span className="text-xs font-medium text-gray-600">
                                                          Target:
                                                        </span>
                                                        <TextWithTooltip
                                                          text={
                                                            content.exercise
                                                              .targetArea
                                                          }
                                                          maxLength={100}
                                                          lang={lang}
                                                        />
                                                      </div>
                                                    )}
                                                  {"options" in
                                                    content.exercise &&
                                                    content.exercise.options &&
                                                    Array.isArray(
                                                      content.exercise.options
                                                    ) &&
                                                    content.exercise.options
                                                      .length > 0 && (
                                                      <div className="mb-1">
                                                        <span className="text-xs font-medium text-gray-600">
                                                          Options:
                                                        </span>
                                                        <ul className="mt-1 space-y-1">
                                                          {content.exercise.options.map(
                                                            (
                                                              opt: any,
                                                              idx: number
                                                            ) => (
                                                              <li
                                                                key={
                                                                  opt.id || idx
                                                                }
                                                                className="flex items-center"
                                                              >
                                                                <TextWithTooltip
                                                                  text={
                                                                    opt.text
                                                                  }
                                                                  lang={lang}
                                                                />
                                                              </li>
                                                            )
                                                          )}
                                                        </ul>
                                                      </div>
                                                    )}
                                                  {"answer" in
                                                    content.exercise &&
                                                    content.exercise.answer &&
                                                    Array.isArray(
                                                      content.exercise.answer
                                                    ) &&
                                                    content.exercise.answer
                                                      .length > 0 && (
                                                      <div>
                                                        <span className="text-xs font-medium text-gray-600">
                                                          Answers:
                                                        </span>
                                                        <ul className="mt-1 space-y-1">
                                                          {content.exercise.answer.map(
                                                            (
                                                              ans: any,
                                                              idx: number
                                                            ) => (
                                                              <li
                                                                key={
                                                                  ans.id || idx
                                                                }
                                                                className="flex items-center"
                                                              >
                                                                <TextWithTooltip
                                                                  text={
                                                                    ans.correctAnswer
                                                                  }
                                                                  lang={lang}
                                                                />
                                                              </li>
                                                            )
                                                          )}
                                                        </ul>
                                                      </div>
                                                    )}
                                                </div>
                                              )}
                                              {content.exercise.type ===
                                                ExerciseType.RECORD && (
                                                <div className="mt-1 p-1 bg-gray-100 rounded">
                                                  <div className="flex items-center gap-1">
                                                    <svg
                                                      xmlns="http://www.w3.org/2000/svg"
                                                      className="h-3 w-3 text-gray-500"
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
                                                    <span className="text-xs text-gray-500">
                                                      Max Duration:{" "}
                                                      {
                                                        (
                                                          content.exercise as IExerciseRecord
                                                        ).maxDuration
                                                      }
                                                      s
                                                    </span>
                                                  </div>
                                                  {(
                                                    content.exercise as IExerciseRecord
                                                  ).maxCharacter && (
                                                    <div className="flex items-center gap-1">
                                                      <svg
                                                        xmlns="http://www.w3.org/2000/svg"
                                                        className="h-3 w-3 text-gray-500"
                                                        fill="none"
                                                        viewBox="0 0 24 24"
                                                        stroke="currentColor"
                                                      >
                                                        <path
                                                          strokeLinecap="round"
                                                          strokeLinejoin="round"
                                                          strokeWidth={2}
                                                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                                                        />
                                                      </svg>
                                                      <span className="text-xs text-gray-500">
                                                        Max Character:{" "}
                                                        {
                                                          (
                                                            content.exercise as IExerciseRecord
                                                          ).maxCharacter
                                                        }
                                                      </span>
                                                    </div>
                                                  )}
                                                </div>
                                              )}
                                            </div>
                                          )}
                                        </div>
                                        <div className="flex gap-1">
                                          <button
                                            onClick={() =>
                                              handleOpenModal(
                                                section.id,
                                                content.type,
                                                content
                                              )
                                            }
                                            className="text-blue-600 hover:text-blue-800 p-1 rounded"
                                            title="Edit"
                                          >
                                            <svg
                                              xmlns="http://www.w3.org/2000/svg"
                                              className="h-4 w-4"
                                              viewBox="0 0 20 20"
                                              fill="currentColor"
                                            >
                                              <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                                            </svg>
                                          </button>
                                          <button
                                            onClick={() =>
                                              requestDeleteContent(
                                                section.id,
                                                content.id || 0,
                                                `${content.type} content`
                                              )
                                            }
                                            className="text-red-500 hover:text-red-700 p-1 rounded"
                                            title="Delete"
                                          >
                                            <TrashIcon className="h-4 w-4" />
                                          </button>
                                        </div>
                                      </div>
                                    </div>
                                  </SortableItem>
                                ))}
                              </div>
                            </SortableContext>
                          </DndContext>
                        ) : null}
                        <div className="text-center pt-5">
                          <button
                            className="text-blue-500 hover:text-blue-700 transition-colors"
                            onClick={() =>
                              handleOpenContentTypePopup(section.id)
                            }
                          >
                            <PlusIcon className="h-5 w-5" />
                          </button>
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
                onClick={addNewSection}
              >
                <PlusCircleIcon className="h-8 w-8" />
              </button>
            </div>
          </SortableContext>
        </DndContext>
      </div>
    );
  };

  // Content form component with dynamic fields
  // Content form component with dynamic fields and validation
  const ContentForm = ({
    content,
    onSave,
    onCancel,
    contentType,
    sectionId,
    formData,
  }: {
    content?: any;
    onSave: (c: any) => void;
    onCancel: () => void;
    contentType: RoleplaySectionType;
    sectionId: number;
    formData: any;
  }) => {
    const [localFormData, setLocalFormData] = useState<any>(formData);
    const [validationErrors, setValidationErrors] = useState<{
      [key: string]: string;
    }>({});

    const [localNextOptionId, setLocalNextOptionId] = useState(nextOptionId);
    const [localNextAnswerId, setLocalNextAnswerId] = useState(nextAnswerId);

    // Update local form data when formData prop changes
    useEffect(() => {
      if (formData?.exercise?.type === ExerciseType.RECORD) {
        const normalizedCriteria = rebalanceRecordScoringCriteria(
          formData.exercise.scoringCriteria,
          typeof formData.exercise.maxScore === "number"
            ? formData.exercise.maxScore
            : undefined
        );

        setLocalFormData({
          ...formData,
          exercise: {
            ...formData.exercise,
            scoringCriteria: normalizedCriteria,
          },
        });
      } else {
        setLocalFormData(formData);
      }
      // Clear errors when form data is reset (e.g., when opening a new content form)
      setValidationErrors({});
    }, [formData]);

    // Ensure translation objects have current language key when language changes
    useEffect(() => {
      if (localFormData.exercise) {
        setLocalFormData((prev: any) => {
          const updated = { ...prev };
          if (updated.exercise) {
            // Ensure speechBubble, explanation, and targetArea exist and have current language
            updated.exercise = {
              ...updated.exercise,
              speechBubble: updated.exercise.speechBubble || { [lang]: "" },
              explanation: updated.exercise.explanation || { [lang]: "" },
              targetArea: updated.exercise.targetArea || { [lang]: "" },
            };

            // Ensure options have current language for value/text
            if (updated.exercise.options) {
              updated.exercise.options = updated.exercise.options.map(
                (opt: any) => ({
                  ...opt,
                  value: opt.value || { [lang]: "" },
                  text: opt.text || { [lang]: "" },
                })
              );
            }

            // Ensure answers have current language for correctAnswer
            if (updated.exercise.answer) {
              updated.exercise.answer = updated.exercise.answer.map(
                (ans: any) => ({
                  ...ans,
                  correctAnswer: ans.correctAnswer || { [lang]: "" },
                })
              );
            }
          }
          return updated;
        });
      }
    }, [lang]);

    // --- Validation Function ---
    const validateForm = () => {
      const errors: { [key: string]: string } = {};

      if (contentType === RoleplaySectionType.CONVERSATION) {
        if (!localFormData.conversation?.avatar?._id) {
          errors.avatar = "Avatar is required.";
        }
      } else if (contentType === RoleplaySectionType.LEADING_TEXT) {
        if (
          !getTranslationValue(localFormData.leadingText?.content, lang)?.trim()
        ) {
          errors.content = "Content is required.";
        }
      } else if (contentType === RoleplaySectionType.HINT) {
        if (!localFormData.hint?.icon?.trim()) {
          errors.icon = "Icon is required.";
        }
        if (!getTranslationValue(localFormData.hint?.content, lang)?.trim()) {
          errors.hintContent = "Content is required.";
        }
      }

      setValidationErrors(errors);
      return Object.keys(errors).length === 0;
    };

    const handleChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => ({ ...prev, [field]: value }));
    };

    const handleConversationChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => ({
        ...prev,
        conversation: {
          ...prev.conversation,
          [field]: value,
        },
      }));
      // Clear error on change
      if (field === "avatar" || field === "avatarId") {
        setValidationErrors((prev) => ({ ...prev, avatar: "" }));
      }
    };

    const handleLeadingTextChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => ({
        ...prev,
        leadingText: {
          ...prev.leadingText,
          [field]: value,
        },
      }));
      // Clear error on change
      if (field === "content" && validationErrors.content) {
        setValidationErrors((prev) => ({ ...prev, content: "" }));
      }
    };

    const handleHintChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => ({
        ...prev,
        hint: {
          ...prev.hint,
          [field]: value,
        },
      }));
      // Clear error on change
      if (field === "icon" && validationErrors.icon) {
        setValidationErrors((prev) => ({ ...prev, icon: "" }));
      }
      if (field === "content" && validationErrors.hintContent) {
        setValidationErrors((prev) => ({ ...prev, hintContent: "" }));
      }
    };

    const handleExerciseChange = (
      field: string,
      value: any,
      options?: { skipRebalance?: boolean }
    ) => {
      setLocalFormData((prev: any) => {
        const nextExercise = {
          ...prev.exercise,
          [field]: value,
        };

        if (
          nextExercise.type === ExerciseType.RECORD &&
          !options?.skipRebalance
        ) {
          const normalized = rebalanceRecordScoringCriteria(
            nextExercise.scoringCriteria,
            typeof nextExercise.maxScore === "number"
              ? nextExercise.maxScore
              : undefined
          );
          nextExercise.scoringCriteria = normalized;
        }

        return {
          ...prev,
          exercise: nextExercise,
        };
      });
    };

    const handleDocumentChange = (
      index: number,
      field: keyof IDocument,
      value: any
    ) => {
      setLocalFormData((prev: any) => {
        const newDocuments = [...prev.exercise.document];
        const updatedDoc = {
          ...newDocuments[index],
          [field]: value,
        };
        if (field === "type") {
          updatedDoc.data = createEmptyMediaDocument(lang);
        }
        newDocuments[index] = updatedDoc;
        return {
          ...prev,
          exercise: {
            ...prev.exercise,
            document: newDocuments,
          },
        };
      });
    };

    const handleDataChange = (
      docIndex: number,
      field: keyof IMediaDocument,
      value: string | ITranslation
    ) => {
      setLocalFormData((prev: any) => {
        if (!prev.exercise) return prev;
        const newDocuments = [...prev.exercise.document];
        newDocuments[docIndex] = {
          ...newDocuments[docIndex],
          data: {
            ...newDocuments[docIndex].data,
            [field]:
              field === "content" && typeof value === "string"
                ? updateTranslationValue(
                    newDocuments[docIndex].data.content || {},
                    lang,
                    value
                  )
                : value,
          },
        };
        return {
          ...prev,
          exercise: {
            ...prev.exercise,
            document: newDocuments,
          },
        };
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

      if (doc.type === DocumentType.IMAGE) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={doc.data.url || ""}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Image URL"
              uploadPayload={{
                prefix: "",
                folder: "roleplays",
              }}
            />
          </div>
        );
      }

      if (doc.type === DocumentType.AUDIO) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={doc.data.url || ""}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Audio URL"
              uploadPayload={{
                prefix: "",
                folder: "roleplays",
              }}
            />
          </div>
        );
      }

      if (doc.type === DocumentType.VIDEO) {
        return (
          <div className="flex flex-col gap-3">
            <div className="w-52">
              <CloudflareFileUpload
                initialUrl={doc.data.url || ""}
                onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
                label="Video URL"
                uploadPayload={{
                  prefix: "",
                  folder: "roleplays",
                }}
              />
            </div>
            <div className="w-52">
              <CloudflareFileUpload
                initialUrl={doc.data.thumbnail || ""}
                onUrlChange={(newUrl) =>
                  handleDataChange(index, "thumbnail", newUrl)
                }
                label="Video Thumbnail"
                uploadPayload={{
                  prefix: "",
                  folder: "roleplays",
                }}
              />
            </div>
          </div>
        );
      }

      return null;
    };

    const addNewDocument = () => {
      if (
        contentType !== RoleplaySectionType.EXERCISE ||
        !localFormData.exercise
      )
        return;

      const currentMaxId = localFormData.exercise.document.reduce(
        (max: number, doc: IDocument) => Math.max(max, doc.id || 0),
        0
      );
      const newId = currentMaxId + 1;

      setLocalFormData((prev: any) => ({
        ...prev,
        exercise: {
          ...prev.exercise,
          document: [
            ...prev.exercise.document,
            {
              id: newId,
              type: DocumentType.TEXT,
              data: createEmptyMediaDocument(lang),
            },
          ],
        },
      }));
    };

    const removeDocument = (index: number) => {
      if (
        contentType !== RoleplaySectionType.EXERCISE ||
        !localFormData.exercise
      )
        return;
      if (localFormData.exercise.document.length === 1) return;
      setLocalFormData((prev: any) => ({
        ...prev,
        exercise: {
          ...prev.exercise,
          document: prev.exercise.document.filter(
            (_: IDocument, i: number) => i !== index
          ),
        },
      }));
    };

    const handleSave = () => {
      if (!validateForm()) {
        return; // Stop if validation fails
      }

      // Update global counters for options and answers
      setNextOptionId(localNextOptionId);
      setNextAnswerId(localNextAnswerId);

      let dataToSave = localFormData;

      if (
        contentType === RoleplaySectionType.EXERCISE &&
        localFormData.exercise?.type === ExerciseType.RECORD
      ) {
        const normalizedCriteria = rebalanceRecordScoringCriteria(
          localFormData.exercise.scoringCriteria,
          typeof localFormData.exercise.maxScore === "number"
            ? localFormData.exercise.maxScore
            : undefined
        );

        dataToSave = {
          ...localFormData,
          exercise: {
            ...localFormData.exercise,
            scoringCriteria: normalizedCriteria,
          },
        };

        setLocalFormData(dataToSave);
      }

      onSave(dataToSave);
    };

    // Add new option
    const addOption = () => {
      if (
        contentType === RoleplaySectionType.EXERCISE &&
        (localFormData.exercise.type === ExerciseType.SINGLE_CHOICE ||
          localFormData.exercise.type === ExerciseType.MULTIPLE_CHOICE)
      ) {
        const newOptions = [
          ...localFormData.exercise.options,
          { value: "", isCorrect: false },
        ];
        handleExerciseChange("options", newOptions);
      } else if (
        contentType === RoleplaySectionType.EXERCISE &&
        localFormData.exercise.type === ExerciseType.DRAG_DROP
      ) {
        const newId = localNextOptionId;
        setLocalNextOptionId(newId + 1);

        const newOptions = [
          ...localFormData.exercise.options,
          { text: "", id: newId },
        ];
        handleExerciseChange("options", newOptions);
      }
    };

    // Remove option
    const removeOption = (index: number) => {
      if (
        contentType === RoleplaySectionType.EXERCISE &&
        (localFormData.exercise.type === ExerciseType.SINGLE_CHOICE ||
          localFormData.exercise.type === ExerciseType.MULTIPLE_CHOICE)
      ) {
        const newOptions = [...localFormData.exercise.options];
        newOptions.splice(index, 1);
        handleExerciseChange("options", newOptions);
      } else if (
        contentType === RoleplaySectionType.EXERCISE &&
        localFormData.exercise.type === ExerciseType.DRAG_DROP
      ) {
        const newOptions = [...localFormData.exercise.options];
        newOptions.splice(index, 1);
        handleExerciseChange("options", newOptions);
      }
    };

    // Update option value
    const updateOptionValue = (index: number, value: string) => {
      if (
        contentType === RoleplaySectionType.EXERCISE &&
        (localFormData.exercise.type === ExerciseType.SINGLE_CHOICE ||
          localFormData.exercise.type === ExerciseType.MULTIPLE_CHOICE)
      ) {
        const newOptions = [...localFormData.exercise.options];
        const currentTranslation = newOptions[index].value || {};
        const updatedTranslation = updateTranslationValue(
          currentTranslation,
          lang,
          value
        );
        newOptions[index] = { ...newOptions[index], value: updatedTranslation };
        handleExerciseChange("options", newOptions);
      } else if (
        contentType === RoleplaySectionType.EXERCISE &&
        localFormData.exercise.type === ExerciseType.DRAG_DROP
      ) {
        const newOptions = [...localFormData.exercise.options];
        const currentTranslation = newOptions[index].text || {};
        const updatedTranslation = updateTranslationValue(
          currentTranslation,
          lang,
          value
        );
        newOptions[index] = { ...newOptions[index], text: updatedTranslation };
        handleExerciseChange("options", newOptions);
      }
    };

    // Update option correctness
    const updateOptionCorrectness = (index: number, isCorrect: boolean) => {
      if (
        contentType === RoleplaySectionType.EXERCISE &&
        (localFormData.exercise.type === ExerciseType.SINGLE_CHOICE ||
          localFormData.exercise.type === ExerciseType.MULTIPLE_CHOICE)
      ) {
        const newOptions = [...localFormData.exercise.options];
        newOptions[index] = { ...newOptions[index], isCorrect };
        handleExerciseChange("options", newOptions);
      }
    };

    // Add new answer
    const addAnswer = () => {
      const newId = localNextAnswerId;
      setLocalNextAnswerId(newId + 1);

      const existingAnswers = Array.isArray(localFormData.exercise.answer)
        ? localFormData.exercise.answer
        : [];

      const newAnswer = [...existingAnswers, { correctAnswer: "", id: newId }];
      handleExerciseChange("answer", newAnswer);
    };

    // Remove answer
    const removeAnswer = (index: number) => {
      const existingAnswers = Array.isArray(localFormData.exercise.answer)
        ? localFormData.exercise.answer
        : [];

      const newAnswer = existingAnswers.filter(
        (_: any, i: number) => i !== index
      );
      handleExerciseChange("answer", newAnswer);
    };

    // Update answer value
    const updateAnswerValue = (index: number, value: string) => {
      const existingAnswers = Array.isArray(localFormData.exercise.answer)
        ? localFormData.exercise.answer
        : [];

      const newAnswer = [...existingAnswers];
      const currentTranslation = newAnswer[index].correctAnswer || {};
      const updatedTranslation = updateTranslationValue(
        currentTranslation,
        lang,
        value
      );
      newAnswer[index] = {
        ...newAnswer[index],
        correctAnswer: updatedTranslation,
      };
      handleExerciseChange("answer", newAnswer);
    };

    const getScoringCriteria = () =>
      Array.isArray(localFormData.exercise?.scoringCriteria)
        ? (localFormData.exercise
            .scoringCriteria as Partial<IScoringCriteria>[])
        : [];

    const addScoringCriteria = () => {
      const current = getScoringCriteria();
      handleExerciseChange("scoringCriteria", [
        ...current,
        { criteria: "", maxScore: undefined },
      ]);
    };

    const removeScoringCriteria = (index: number) => {
      const current = getScoringCriteria();
      const next = current.filter((_, idx) => idx !== index);
      handleExerciseChange("scoringCriteria", next);
    };

    const updateScoringCriteria = (
      index: number,
      field: keyof IScoringCriteria,
      value: string | ITranslation
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
        idx === index ? { ...item, [field]: parsedValue } : item
      );

      const isNumeric =
        field === "maxScore" &&
        typeof parsedValue === "number" &&
        !Number.isNaN(parsedValue);
      if (isNumeric) {
        const totalValue =
          typeof localFormData.exercise.maxScore === "number" &&
          !Number.isNaN(localFormData.exercise.maxScore)
            ? localFormData.exercise.maxScore
            : undefined;
        if (typeof totalValue === "number") {
          const lastIndex = next.length - 1;
          const otherManualSum = next.reduce((sum, item, idx) => {
            if (idx === index || idx === lastIndex) return sum;
            const val =
              typeof item.maxScore === "number" && !Number.isNaN(item.maxScore)
                ? Math.max(0, Math.round(item.maxScore))
                : 0;
            return sum + val;
          }, 0);
          const maxAllowed = Math.max(0, totalValue - otherManualSum);
          const adjusted =
            typeof parsedValue === "number"
              ? Math.min(Math.max(0, Math.round(parsedValue)), maxAllowed)
              : parsedValue;
          next[index] = { ...next[index], maxScore: adjusted };
        } else if (typeof parsedValue === "number") {
          const adjusted = Math.max(0, Math.round(parsedValue));
          next[index] = { ...next[index], maxScore: adjusted };
        }
      }

      handleExerciseChange("scoringCriteria", next, {
        skipRebalance: field === "maxScore" && !isNumeric,
      });
    };

    const scoringCriteria = getScoringCriteria();
    const scoringCriteriaTotal = scoringCriteria.reduce((sum, item) => {
      const value =
        typeof item.maxScore === "number" && !Number.isNaN(item.maxScore)
          ? item.maxScore
          : 0;
      return sum + value;
    }, 0);

    return (
      <div className="space-y-4">
        {contentType === RoleplaySectionType.CONVERSATION && (
          <>
            <div>
              <AvatarSelector
                value={localFormData.conversation.avatar}
                onChange={(value) =>
                  handleConversationChange("avatar", value || undefined)
                }
                label="Avatar"
              />
              {validationErrors.avatar && (
                <p className="mt-1 text-sm text-red-600">
                  {validationErrors.avatar}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Position
              </label>
              <select
                value={
                  localFormData.conversation.position ||
                  SectionConversationPosition.LEFT
                }
                onChange={(e) =>
                  handleConversationChange("position", e.target.value)
                }
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              >
                <option value={SectionConversationPosition.LEFT}>Left</option>
                <option value={SectionConversationPosition.RIGHT}>Right</option>
              </select>
            </div>

            <ColorPicker
              value={localFormData.conversation.backgroundColor || "#FFFFFF"}
              onChange={(value) =>
                handleConversationChange("backgroundColor", value)
              }
              label="Backgound Color"
            />

            <ColorPicker
              value={localFormData.conversation.textColor || "#000000"}
              onChange={(value) => handleConversationChange("textColor", value)}
              label="Text Color"
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Content
              </label>
              <textarea
                value={getCurrentTranslationValue(
                  localFormData.conversation.content,
                  lang
                )}
                onChange={(e) =>
                  handleConversationChange(
                    "content",
                    updateTranslationValue(
                      localFormData.conversation.content || {},
                      lang,
                      e.target.value
                    )
                  )
                }
                rows={3}
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder="Enter content"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Audio
              </label>
              <CloudflareFileUpload
                initialUrl={localFormData.conversation.audio || ""}
                onUrlChange={(newUrl) =>
                  handleConversationChange("audio", newUrl)
                }
                label=""
                uploadPayload={{
                  prefix: "",
                  folder: "roleplays",
                }}
              />
            </div>
          </>
        )}

        {contentType === RoleplaySectionType.LEADING_TEXT && (
          <>
            <ColorPicker
              value={localFormData.leadingText.backgroundColor || "#000000"}
              onChange={(value) =>
                handleLeadingTextChange("backgroundColor", value)
              }
              label="Backgound Color"
            />

            <ColorPicker
              value={localFormData.leadingText.textColor || "#000000"}
              onChange={(value) => handleLeadingTextChange("textColor", value)}
              label="Text Color"
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Content
              </label>
              <textarea
                value={getCurrentTranslationValue(
                  localFormData.leadingText.content,
                  lang
                )}
                onChange={(e) =>
                  handleLeadingTextChange(
                    "content",
                    updateTranslationValue(
                      localFormData.leadingText.content || {},
                      lang,
                      e.target.value
                    )
                  )
                }
                rows={3}
                className={`border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400 ${
                  validationErrors.content ? "border-red-500" : ""
                }`}
                placeholder="Enter content"
              />
              {validationErrors.content && (
                <p className="mt-1 text-sm text-red-600">
                  {validationErrors.content}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Audio
              </label>
              <CloudflareFileUpload
                initialUrl={localFormData.leadingText.audio || ""}
                onUrlChange={(newUrl) =>
                  handleLeadingTextChange("audio", newUrl)
                }
                label=""
                uploadPayload={{
                  prefix: "",
                  folder: "roleplays",
                }}
              />
            </div>
          </>
        )}

        {contentType === RoleplaySectionType.HINT && (
          <>
            <div>
              <IconSelector
                value={localFormData.hint.icon || ""}
                onChange={(value) => handleHintChange("icon", value)}
                label="Icon"
              />
              {validationErrors.icon && (
                <p className="mt-1 text-sm text-red-600">
                  {validationErrors.icon}
                </p>
              )}
            </div>

            <ColorPicker
              value={localFormData.hint.textColor || "#000000"}
              onChange={(value) => handleHintChange("textColor", value)}
              label="Text Color"
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Content
              </label>
              <textarea
                value={getCurrentTranslationValue(
                  localFormData.hint.content,
                  lang
                )}
                onChange={(e) =>
                  handleHintChange(
                    "content",
                    updateTranslationValue(
                      localFormData.hint.content || {},
                      lang,
                      e.target.value
                    )
                  )
                }
                rows={3}
                className={`border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400 ${
                  validationErrors.hintContent ? "border-red-500" : ""
                }`}
                placeholder="Enter content"
              />
              {validationErrors.hintContent && (
                <p className="mt-1 text-sm text-red-600">
                  {validationErrors.hintContent}
                </p>
              )}
            </div>
          </>
        )}

        {contentType === RoleplaySectionType.EXERCISE && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Exercise Type
              </label>
              <select
                value={
                  localFormData.exercise.type || ExerciseType.SINGLE_CHOICE
                }
                onChange={(e) => handleExerciseChange("type", e.target.value)}
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              >
                <option value={ExerciseType.SINGLE_CHOICE}>
                  Single Choice
                </option>
                <option value={ExerciseType.MULTIPLE_CHOICE}>
                  Multiple Choice
                </option>
                <option value={ExerciseType.DRAG_DROP}>Drag & Drop</option>
                <option value={ExerciseType.RECORD}>Record</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Speech Bubble
              </label>
              <input
                type="text"
                value={getCurrentTranslationValue(
                  localFormData.exercise?.speechBubble,
                  lang
                )}
                onChange={(e) =>
                  handleExerciseChange(
                    "speechBubble",
                    updateTranslationValue(
                      localFormData.exercise.speechBubble || {},
                      lang,
                      e.target.value
                    )
                  )
                }
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder="Enter speech bubble text"
              />
            </div>

            <KeypointSelector
              value={localFormData.exercise.keypointId || ""}
              onChange={(value) => handleExerciseChange("keypointId", value)}
              label="Keypoint"
            />

            <div className="border rounded-lg p-4 bg-gray-50">
              <div className="flex justify-between items-center mb-3">
                <h3 className="font-medium text-gray-800">Content Documents</h3>
              </div>

              {localFormData.exercise.document.map(
                (doc: IDocument, index: number) => (
                  <div
                    key={doc.id}
                    className="border rounded-lg p-4 bg-white mb-3"
                  >
                    <div className="flex justify-between items-center mb-3">
                      <h4 className="font-medium text-sky-400">
                        Content {index + 1}
                      </h4>
                      {localFormData.exercise.document.length > 1 && (
                        <button
                          type="button"
                          onClick={() => removeDocument(index)}
                          className="text-red-500 hover:text-red-700"
                        >
                          <TrashIcon className="h-4 w-4" />
                        </button>
                      )}
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
                              e.target.value as DocumentType
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
                        </select>
                      </div>

                      {renderDocumentFields(doc, index)}
                    </div>
                  </div>
                )
              )}

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

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Max Score
              </label>
              <input
                type="number"
                value={localFormData.exercise.maxScore ?? ""}
                onChange={(e) => {
                  const val = e.target.value;
                  const isEmpty = val === "";
                  handleExerciseChange("maxScore", isEmpty ? "" : Number(val), {
                    skipRebalance: isEmpty,
                  });
                }}
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder="Enter max score"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Completion Time
              </label>
              <input
                type="number"
                value={localFormData.exercise.completionTime ?? ""}
                onChange={(e) => {
                  const val = e.target.value;
                  handleExerciseChange(
                    "completionTime",
                    val === "" ? "" : Number(val)
                  );
                }}
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder="Enter completion time"
              />
            </div>

            {(localFormData.exercise.type === ExerciseType.SINGLE_CHOICE ||
              localFormData.exercise.type === ExerciseType.MULTIPLE_CHOICE) && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Options
                </label>
                <div className="space-y-3">
                  {localFormData.exercise.options?.map(
                    (opt: any, idx: number) => (
                      <div key={idx} className="flex items-center gap-2">
                        <input
                          type="text"
                          value={getCurrentTranslationValue(opt.value, lang)}
                          onChange={(e) =>
                            updateOptionValue(idx, e.target.value)
                          }
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
                            {localFormData.exercise.type ===
                            ExerciseType.SINGLE_CHOICE
                              ? "Correct"
                              : "Correct Answer"}
                          </span>
                        </label>
                        {localFormData.exercise.options.length > 2 && (
                          <button
                            type="button"
                            onClick={() => removeOption(idx)}
                            className="text-red-500 hover:text-red-700 p-1"
                          >
                            <TrashIcon className="h-5 w-5" />
                          </button>
                        )}
                      </div>
                    )
                  )}
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

            {localFormData.exercise.type === ExerciseType.DRAG_DROP && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Form Type
                </label>
                <select
                  value={
                    localFormData.exercise.form ||
                    FormDragDropType.TextGapFilling
                  }
                  onChange={(e) => handleExerciseChange("form", e.target.value)}
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
                    Arrange The Sequence
                  </option>
                </select>
              </div>
            )}

            {localFormData.exercise.type === ExerciseType.DRAG_DROP && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Target Area
                </label>
                <input
                  type="text"
                  value={getCurrentTranslationValue(
                    localFormData.exercise?.targetArea,
                    lang
                  )}
                  onChange={(e) =>
                    handleExerciseChange(
                      "targetArea",
                      updateTranslationValue(
                        localFormData.exercise.targetArea || {},
                        lang,
                        e.target.value
                      )
                    )
                  }
                  className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                  placeholder="Enter target area"
                />
              </div>
            )}

            {localFormData.exercise.type === ExerciseType.DRAG_DROP && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Options
                </label>
                <div className="space-y-2">
                  {localFormData.exercise.options.map(
                    (opt: any, idx: number) => (
                      <div key={opt.id} className="flex items-center">
                        <input
                          type="text"
                          value={getCurrentTranslationValue(opt.text, lang)}
                          onChange={(e) =>
                            updateOptionValue(idx, e.target.value)
                          }
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
                    )
                  )}
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

            {localFormData.exercise.type === ExerciseType.DRAG_DROP && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Answer
                </label>
                <div className="space-y-2">
                  {localFormData.exercise.answer?.map(
                    (ans: any, idx: number) => (
                      <div key={ans.id} className="flex items-center">
                        <input
                          type="text"
                          value={getCurrentTranslationValue(
                            ans.correctAnswer,
                            lang
                          )}
                          onChange={(e) =>
                            updateAnswerValue(idx, e.target.value)
                          }
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
                    )
                  )}
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

            {localFormData.exercise.type === ExerciseType.RECORD && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Max Duration (seconds)
                </label>
                <input
                  type="number"
                  value={localFormData.exercise.maxDuration}
                  onChange={(e) =>
                    handleExerciseChange(
                      "maxDuration",
                      parseInt(e.target.value)
                    )
                  }
                  className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                  placeholder="Enter max duration"
                />
              </div>
            )}

            {localFormData.exercise.type === ExerciseType.RECORD && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Max Character
                </label>
                <input
                  type="number"
                  value={localFormData.exercise.maxCharacter}
                  onChange={(e) =>
                    handleExerciseChange(
                      "maxCharacter",
                      parseInt(e.target.value)
                    )
                  }
                  className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                  placeholder="Enter max character"
                />
              </div>
            )}

            {localFormData.exercise.type === ExerciseType.RECORD && (
              <div>
                <div className="flex items-center justify-between mb-1">
                  <label className="block text-sm font-medium text-gray-700">
                    Scoring Criteria
                  </label>
                  <button
                    type="button"
                    onClick={addScoringCriteria}
                    className="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    <PlusIcon className="h-4 w-4 mr-1" />
                    Add Criteria
                  </button>
                </div>
                {scoringCriteria.length === 0 ? (
                  <p className="text-sm text-gray-500">
                    Add at least one criterion to describe how this record is
                    scored.
                  </p>
                ) : (
                  <div className="space-y-3">
                    {scoringCriteria.map((criteriaItem, index) => (
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
                                lang
                              )}
                              onChange={(e) =>
                                updateScoringCriteria(
                                  index,
                                  "criteria",
                                  e.target.value
                                )
                              }
                              rows={2}
                              className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400 resize-none"
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
                                  e.target.value
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
                {scoringCriteria.length > 0 && (
                  <p className="mt-2 text-xs text-gray-500">
                    Total criteria score: {scoringCriteriaTotal}
                    {localFormData.exercise.maxScore
                      ? ` / ${localFormData.exercise.maxScore}`
                      : ""}
                    {localFormData.exercise.maxScore &&
                      scoringCriteriaTotal !==
                        localFormData.exercise.maxScore &&
                      " • Missing values are auto-filled on save to match the exercise max score."}
                  </p>
                )}
              </div>
            )}
          </>
        )}

        <div className="flex justify-end gap-2 mt-6">
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
            ) : content ? (
              "Update Content"
            ) : (
              "Add Content"
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
              {currentRoleplay.image ? (
                <img
                  src={currentRoleplay.image}
                  alt={currentRoleplay.title?.[lang]}
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

              <div className="mt-6 w-52 h-auto max-w-md">
                <CloudflareFileUpload
                  initialUrl={currentRoleplay.image || ""}
                  onUrlChange={(url) => {
                    setCurrentRoleplay((prev) => ({
                      ...prev,
                      image: url,
                    }));
                  }}
                  label=""
                  // Bạn có thể tùy chỉnh payload này theo nhu cầu
                  uploadPayload={{
                    prefix: "",
                    folder: "entrances",
                  }}
                />
              </div>
            </div>
          </div>

          {/* RIGHT: form */}
          <div className="flex-[1.5] p-6">
            <div className="flex justify-between items-center mb-6">
              <h1 className="text-2xl md:text-3xl font-bold text-gray-800">
                {isEditMode ? "✏️ Edit Roleplay" : "🌱 Create New Roleplay"}
              </h1>
            </div>

            <div className="space-y-6">
              {/* Title */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Title *
                </label>
                <input
                  value={getCurrentTranslationValue(
                    currentRoleplay.title,
                    lang
                  )}
                  onChange={(e) =>
                    setCurrentRoleplay((prev) => ({
                      ...prev,
                      title: updateTranslationValue(
                        prev.title,
                        lang,
                        e.target.value
                      ),
                    }))
                  }
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  placeholder="Roleplay title..."
                  required
                />
              </div>

              {/* Description */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Description
                </label>
                <textarea
                  value={getCurrentTranslationValue(
                    currentRoleplay.description,
                    lang
                  )}
                  onChange={(e) =>
                    setCurrentRoleplay((prev) => ({
                      ...prev,
                      description: updateTranslationValue(
                        prev.description,
                        lang,
                        e.target.value
                      ),
                    }))
                  }
                  rows={4}
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition resize-none"
                  placeholder="Short description..."
                />
              </div>

              {/* Keypoint: Combobox always shown */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Keypoint
                </label>

                <Combobox<string | null>
                  value={currentRoleplay.keypointId || null}
                  onChange={(val: string | null) => {
                    setCurrentRoleplay((prev) =>
                      prev ? { ...prev, keypointId: val ?? "" } : prev
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
                            .includes(keypointQuery.toLowerCase())
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
                  {currentRoleplay.tag?.map((tag, index) => (
                    <div
                      key={index}
                      className="flex items-center bg-indigo-100 rounded-md"
                    >
                      <input
                        type="text"
                        value={tag}
                        onChange={(e) => {
                          const newTags = [...(currentRoleplay.tag || [])];
                          newTags[index] = e.target.value;
                          setCurrentRoleplay({
                            ...currentRoleplay,
                            tag: newTags,
                          });
                        }}
                        className="px-3 py-1 bg-transparent border-0 focus:ring-0 text-sm"
                        placeholder="Enter tag"
                      />
                      <button
                        type="button"
                        onClick={() => {
                          const newTags = (currentRoleplay.tag || []).filter(
                            (_, i) => i !== index
                          );
                          setCurrentRoleplay({
                            ...currentRoleplay,
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
                    setCurrentRoleplay({
                      ...currentRoleplay,
                      tag: [...(currentRoleplay.tag || []), ""],
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
            </div>
            <div className="flex pt-4 gap-2 justify-end">
              {onCancel && (
                <button
                  onClick={onCancel}
                  className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition"
                >
                  Back
                </button>
              )}
              <button
                onClick={handleSaveRoleplay}
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
                  "Save Roleplay"
                ) : (
                  "Create Roleplay"
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Sections */}
        {currentRoleplay._id ? (
          <div className="mt-8">{renderSections()}</div>
        ) : null}

        {/* If in edit mode, show Delete button */}
        {currentRoleplay._id && (
          <div className="flex justify-center mt-8">
            <button
              onClick={() => setConfirmDeleteRoleplay(true)}
              className="px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg shadow hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2"
            >
              <TrashIcon className="h-5 w-5" />
              Delete Roleplay
            </button>
          </div>
        )}

        {/* Delete confirmation modal */}
        <AnimatePresence>
          {confirmDeleteRoleplay && (
            <LearningItemConfirm
              title="Confirm Delete"
              message="Are you sure you want to delete this roleplay? This action cannot be undone."
              onCancel={() => setConfirmDeleteRoleplay(false)}
              onConfirm={handleDeleteRoleplay}
            />
          )}
        </AnimatePresence>

        {/* Content type selection popup */}
        <AnimatePresence>
          {showContentTypePopup && (
            <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[9999]">
              <motion.div
                initial={{ opacity: 0, y: 100 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 100 }}
                className="bg-white w-full max-w-md rounded-t-2xl shadow-xl p-6"
              >
                <h2 className="text-xl font-bold mb-4">Select Content Type</h2>
                <div className="grid grid-cols-2 gap-4">
                  <button
                    onClick={() =>
                      handleSelectContentType(RoleplaySectionType.CONVERSATION)
                    }
                    className="p-4 bg-blue-50 rounded-lg hover:bg-blue-100 transition flex flex-col items-center gap-2"
                  >
                    <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="h-6 w-6 text-blue-600"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                        />
                      </svg>
                    </div>
                    <span className="font-medium">Conversation</span>
                  </button>
                  <button
                    onClick={() =>
                      handleSelectContentType(RoleplaySectionType.LEADING_TEXT)
                    }
                    className="p-4 bg-purple-50 rounded-lg hover:bg-purple-100 transition flex flex-col items-center gap-2"
                  >
                    <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="h-6 w-6 text-purple-600"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                        />
                      </svg>
                    </div>
                    <span className="font-medium">Leading Text</span>
                  </button>
                  <button
                    onClick={() =>
                      handleSelectContentType(RoleplaySectionType.HINT)
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
                          d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                      </svg>
                    </div>
                    <span className="font-medium">Hint</span>
                  </button>
                  <button
                    onClick={() =>
                      handleSelectContentType(RoleplaySectionType.EXERCISE)
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
                          d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                        />
                      </svg>
                    </div>
                    <span className="font-medium">Exercise</span>
                  </button>
                </div>
                <button
                  onClick={() => {
                    setShowContentTypePopup(false);
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

        {/* Content form modal */}
        <AnimatePresence>
          {modalOpen.sectionId && (
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
                    {modalOpen.content ? "Edit Content" : "New Content"}
                  </h2>

                  <button
                    onClick={() =>
                      setModalOpen({
                        sectionId: null,
                        contentType: RoleplaySectionType.CONVERSATION,
                      })
                    }
                    className="text-gray-500 hover:text-gray-700 p-1 rounded-full transition-colors"
                  >
                    <XMarkIcon className="h-6 w-6" />
                  </button>
                </div>

                <div className="flex-grow overflow-y-auto p-6">
                  <ContentForm
                    content={modalOpen.content}
                    onSave={handleSaveContentAndRoleplay}
                    onCancel={() =>
                      setModalOpen({
                        sectionId: null,
                        contentType: RoleplaySectionType.CONVERSATION,
                      })
                    }
                    contentType={modalOpen.contentType}
                    sectionId={modalOpen.sectionId}
                    formData={modalOpen.formData}
                  />
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>

        {/* Delete confirmation modal for sections */}
        <AnimatePresence>
          {confirmDeleteSection && (
            <LearningItemConfirm
              title="Confirm Delete"
              message={`Are you sure you want to delete "${confirmDeleteSection.sectionTitle}"?`}
              onCancel={() => setConfirmDeleteSection(null)}
              onConfirm={handleDeleteSectionAndSaveRoleplay}
            />
          )}
        </AnimatePresence>

        {/* Delete confirmation modal for content */}
        <AnimatePresence>
          {confirmDeleteContent && (
            <LearningItemConfirm
              title="Confirm Delete"
              message={`Are you sure you want to delete "${confirmDeleteContent.contentTitle}"?`}
              onCancel={() => setConfirmDeleteContent(null)}
              onConfirm={handleDeleteContentAndSaveRoleplay}
            />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
