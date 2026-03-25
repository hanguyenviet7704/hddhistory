import React, { useState, useEffect, useRef, useCallback } from "react";
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
  RoleplayContentType,
  RoleplayConversationPosition,
} from "../../types/enum/learningItem.enum";
import {
  PlusCircleIcon,
  TrashIcon,
  ArrowDownTrayIcon,
  ArrowPathIcon,
} from "@heroicons/react/24/outline";
import { PlusIcon, XMarkIcon } from "@heroicons/react/24/solid";
import { motion, AnimatePresence } from "framer-motion";
import { DndContext, closestCenter } from "@dnd-kit/core";
import {
  arrayMove,
  SortableContext,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import SortableItem from "../../components/common/SortableItem";
import { KeypointLevel } from "../../utils/enum/course.enum";
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
import {
  IAnswer,
  IExerciseDragDrop,
  IOptions,
} from "../../types/interface/learning-item/excercises/drag-drop.interface";
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
import {
  IConversation,
  ILeadingText,
  IMission,
  IRoleplay,
  IRoleplayContent,
  IRoleplayContentPayload,
  IRoleplayPayload,
  ITransition,
} from "../../types/interface/learning-item/roleplays/roleplay.interface";
import { IRoleplayColorTemplate } from "../../types/interface/learning-item/roleplays/color-template.interface";
import { roleplayColorTemplateService } from "../../services/roleplayColorTemplateService";
import { IAvatar } from "../../types/interface/avatar.interface";

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
  url: { [currentLang]: "" },
  thumbnail: "",
});

const createDefaultTextDocument = (currentLang: LangCode): IDocument => ({
  id: 1,
  type: DocumentType.TEXT,
  data: createEmptyMediaDocument(currentLang),
});

const createDefaultDocumentsForExercise = (
  type: ExerciseType,
  currentLang: LangCode
): IDocument[] =>
  type === ExerciseType.DRAG_DROP
    ? []
    : [createDefaultTextDocument(currentLang)];

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

const EXERCISE_TYPE_LABELS: Record<ExerciseType, string> = {
  [ExerciseType.SINGLE_CHOICE]: "Single Choice",
  [ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER]:
    "Single Choice No Correct Answer",
  [ExerciseType.MULTIPLE_CHOICE]: "Multiple Choice",
  [ExerciseType.DRAG_DROP]: "Drag & Drop",
  [ExerciseType.RECORD]: "Record",
};

const getExerciseTypeLabel = (type?: ExerciseType): string => {
  if (!type) return "";
  return EXERCISE_TYPE_LABELS[type] || type;
};

const getDragDropFormLabel = (
  type?: ExerciseType,
  form?: string | FormDragDropType
): string => {
  if (type !== ExerciseType.DRAG_DROP) return "";
  return (form as string) || FormDragDropType.TextGapFilling;
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
        if (active) {
          setKeypoints(list);
        }
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
  embedded?: boolean;
  hideActions?: boolean;
  externalTitle?: ITranslation;
  lockTitle?: boolean;
  saveRef?: React.MutableRefObject<
    (() => Promise<ILearningItem | undefined>) | null
  >;
  hideMeta?: boolean;
}

export default function RoleplayFromDetail({
  roleplay,
  onSave,
  onCancel,
  embedded = false,
  hideActions = false,
  externalTitle,
  lockTitle = false,
  saveRef,
  hideMeta = false,
}: RoleplayFormProps) {
  const navigate = useNavigate();
  const lang = useSelector(
    (state: RootState) => state.lang.code
  ) as keyof ITranslation as LangCode;
  const isEditMode = !!roleplay;
  const { showSuccess, showError } = useNotification();
  const showErrorRef = useRef(showError);
  useEffect(() => {
    showErrorRef.current = showError;
  }, [showError]);

  const createEmptyRoleplayData = (): IRoleplay => ({
    image: "",
    contents: [],
    missions: [],
    colorTemplateId: "",
  });

  // State for keypoint search
  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [keypointQuery, setKeypointQuery] = useState("");
  const [selectedKeypoint, setSelectedKeypoint] = useState<IKeypoint | null>(
    null
  );
  const [keypointCache, setKeypointCache] = useState<Record<string, IKeypoint>>(
    {}
  );
  const pendingKeypointFetches = useRef<Set<string>>(new Set());
  const mergeKeypointCache = useCallback((items: IKeypoint[]) => {
    if (!items.length) return;
    setKeypointCache((prev) => {
      const next = { ...prev };
      items.forEach((item) => {
        if (item?._id) {
          next[item._id] = item;
        }
      });
      return next;
    });
  }, []);

  // State for content ID counter
  const [nextContentId, setNextContentId] = useState(1);

  // State for drag-drop option and answer ID counters
  const [nextOptionId, setNextOptionId] = useState(1);
  const [nextAnswerId, setNextAnswerId] = useState(1);
  const [nextMissionId, setNextMissionId] = useState(1);

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
        roleplay: createEmptyRoleplayData(),
        index: 0,
      } as ILearningItem)
  );

  useEffect(() => {
    if (roleplay) {
      const contents = roleplay.roleplay?.contents || [];
      const missions = roleplay.roleplay?.missions || [];

      const maxContentId = contents.reduce(
        (max, c) => Math.max(max, c.id ?? 0),
        0
      );
      let contentCounter = maxContentId;

      const maxOptionId = contents
        .filter((c) => c.type === RoleplayContentType.EXERCISE)
        .flatMap((c) => (c.exercise as IExerciseDragDrop)?.options || [])
        .reduce((max, opt) => Math.max(max, opt.id || 0), 0);
      setNextOptionId(maxOptionId + 1);

      const maxAnswerId = contents
        .filter((c) => c.type === RoleplayContentType.EXERCISE)
        .flatMap((c) => (c.exercise as IExerciseDragDrop)?.answer || [])
        .reduce((max, ans) => Math.max(max, ans.id || 0), 0);
      const startOptionId = maxOptionId + 1;
      const startAnswerId = maxAnswerId + 1;
      setNextOptionId(startOptionId);
      setNextAnswerId(startAnswerId);

      let optionCounter = startOptionId;
      let answerCounter = startAnswerId;

      const normalizeExerciseIds = (exerciseData: any) => {
        if (exerciseData?.type !== ExerciseType.DRAG_DROP) return exerciseData;
        const options = (exerciseData.options || []).map((opt: any) =>
          opt && opt.id ? opt : { ...opt, id: optionCounter++ }
        );
        const answer = (exerciseData.answer || []).map((ans: any) =>
          ans && ans.id ? ans : { ...ans, id: answerCounter++ }
        );
        return { ...exerciseData, options, answer } as IExerciseDragDrop;
      };

      const normalizedContents = contents.map((content) => {
        const assignedId = content.id ?? ++contentCounter;
        if (content.type !== RoleplayContentType.EXERCISE) {
          return { ...content, id: assignedId };
        }
        return {
          ...content,
          id: assignedId,
          exercise: normalizeExerciseIds(content.exercise),
        };
      });
      setNextContentId(contentCounter + 1);

      const missionCounterStart = missions.reduce(
        (max, m) => Math.max(max, m.id ?? 0),
        0
      );
      let missionCounter = missionCounterStart;
      const normalizedMissions = missions.map((mission) => {
        const id = mission.id ?? ++missionCounter;
        return { ...mission, id };
      });
      setNextMissionId(Math.max(missionCounter, missionCounterStart) + 1);

      setNextOptionId(optionCounter);
      setNextAnswerId(answerCounter);
      setCurrentRoleplay({
        ...roleplay,
        image: roleplay.image || roleplay.roleplay?.image || "",
        roleplay: {
          image: roleplay.roleplay?.image || roleplay.image || "",
          contents: normalizedContents,
          missions: normalizedMissions,
          colorTemplateId: roleplay.roleplay?.colorTemplateId || "",
        },
      });
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
        roleplay: createEmptyRoleplayData(),
        index: 0,
      } as ILearningItem);
      setNextContentId(1);
      setNextOptionId(1);
      setNextAnswerId(1);
      setNextMissionId(1);
    }
  }, [roleplay]); // Remove lang from dependency to prevent reset on language change

  // Keep roleplay title in sync with parent entrance when provided
  useEffect(() => {
    if (!externalTitle) return;
    setCurrentRoleplay((prev) => ({
      ...prev,
      title: externalTitle,
    }));
  }, [externalTitle]);

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

  useEffect(() => {
    let active = true;
    const fetchTemplates = async () => {
      try {
        setColorTemplatesLoading(true);
        const res = await roleplayColorTemplateService.getList({
          page: 1,
          take: 1000,
        });
        const list: IRoleplayColorTemplate[] =
          res?.data?.items || res?.items || res?.data || res || [];
        if (active) setColorTemplates(list);
      } catch (err) {
        console.error("fetchRoleplayColorTemplates", err);
        showErrorRef.current?.("Failed to load roleplay color templates");
      } finally {
        if (active) setColorTemplatesLoading(false);
      }
    };
    fetchTemplates();
    return () => {
      active = false;
    };
  }, []);

  const [saving, setSaving] = useState(false);
  const [modalOpen, setModalOpen] = useState<{
    contentType: RoleplayContentType;
    content?: IRoleplayContent;
    formData?: any;
  } | null>(null);
  const [confirmDeleteContent, setConfirmDeleteContent] = useState<{
    contentId: number | null;
    contentTitle: string;
  } | null>(null);

  const [confirmDeleteRoleplay, setConfirmDeleteRoleplay] = useState(false);

  const outerClass = embedded
    ? "bg-white rounded-xl border border-gray-200 p-4"
    : "min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6";
  const innerClass = embedded ? "" : "max-w-7xl mx-auto";
  const cardClass = `bg-white shadow-xl rounded-xl overflow-hidden flex flex-col ${
    hideMeta ? "" : "md:flex-row"
  } ${embedded ? "border border-gray-200" : ""}`;
  const showShell = !(hideMeta && hideActions);
  const [showContentTypePopup, setShowContentTypePopup] = useState(false);
  const [validationErrors, setValidationErrors] = useState<{
    [key: string]: string;
  }>({});
  const [colorTemplates, setColorTemplates] = useState<
    IRoleplayColorTemplate[]
  >([]);
  const [colorTemplatesLoading, setColorTemplatesLoading] = useState(false);

  const getRoleplayColorTemplate = (): IRoleplayColorTemplate | undefined => {
    const templateId = currentRoleplay.roleplay?.colorTemplateId;
    if (!templateId) return undefined;
    return colorTemplates.find((t) => t._id === templateId);
  };

  const transformExerciseToPayload = (
    exercise?: ExerciseInput
  ): ExerciseInputPayload | undefined => {
    if (!exercise) return undefined;

    const { speechBubble: _speechBubble, ...restExercise } =
      (exercise as ExerciseInputPayload & { speechBubble?: ITranslation }) ||
      {};
    const exercisePayload: ExerciseInputPayload = { ...restExercise };

    if ("tag" in exercise) {
      const tagValue = (exercise as { tag?: ITag | string | null }).tag;
      const payloadWithTag = exercisePayload as {
        tag?: string;
        tagId?: string;
      };
      payloadWithTag.tagId =
        typeof tagValue === "string" ? tagValue : tagValue?._id || "";
      delete payloadWithTag.tag;
    }

    // Clean ITranslation fields - only add if not empty
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
      const cleanedDocuments = cleanDocumentItems(
        exercisePayload.document as IDocument[]
      );
      if (cleanedDocuments.length > 0) {
        (exercisePayload as any).document = cleanedDocuments;
      } else {
        delete (exercisePayload as any).document;
      }
    }

    return exercisePayload;
  };

  const transformRoleplayToPayload = (
    roleplayData?: IRoleplay
  ): IRoleplayPayload | undefined => {
    if (!roleplayData) return undefined;

    const payload: IRoleplayPayload = {
      image: roleplayData.image || "",
      contents: [],
      missions: [],
      colorTemplateId: roleplayData.colorTemplateId || "",
    };

    if (roleplayData.contents?.length) {
      payload.contents = roleplayData.contents.map((content) => {
        const contentPayload: any = {
          id: content.id,
          type: content.type,
        };

        if (content.type === RoleplayContentType.EXERCISE) {
          const exercisePayload = transformExerciseToPayload(content.exercise);
          if (exercisePayload) {
            contentPayload.exercise = exercisePayload;
          }
        } else if (
          content.type === RoleplayContentType.CONVERSATION &&
          content.conversation
        ) {
          const cleanedConversationAudio = cleanTranslation(
            content.conversation.audio
          );
          contentPayload.conversation = {
            position: content.conversation.position,
            backgroundColor: content.conversation.backgroundColor,
            textColor: content.conversation.textColor,
            avatarId:
              content.conversation.avatar?._id ||
              content.conversation.avatarId ||
              "",
            content: content.conversation.content
              ? cleanTranslation(content.conversation.content) || {}
              : {},
            audio: cleanedConversationAudio || {},
          };
        } else if (
          content.type === RoleplayContentType.LEADING_TEXT &&
          content.leadingText
        ) {
          const cleanedLeadingAudio = cleanTranslation(
            content.leadingText.audio
          );
          contentPayload.leadingText = {
            ...content.leadingText,
            content: content.leadingText.content
              ? cleanTranslation(content.leadingText.content) || {}
              : {},
            audio: cleanedLeadingAudio || {},
          };
        } else if (
          content.type === RoleplayContentType.TRANSITION &&
          content.transition
        ) {
          contentPayload.transition = {
            ...content.transition,
            content: content.transition.content
              ? cleanTranslation(content.transition.content) || {}
              : {},
          };
        }

        return contentPayload as IRoleplayContentPayload;
      });
    }

    if (roleplayData.missions?.length) {
      payload.missions = roleplayData.missions.map((mission) => ({
        id: mission.id,
        content: cleanTranslation(mission.content) || {},
      }));
    }

    return payload;
  };

  const buildLearningItemPayload = (
    item: ILearningItem,
    titleOverride?: ITranslation
  ): LearningItemPayload => {
    const payload: any = {
      keypointId: item.keypointId,
      title: cleanTranslation(titleOverride ?? item.title) || {},
      type: LearningItemType.ROLEPLAY,
      image: item.image || item.roleplay?.image || "",
      tag: item.tag || [],
      isSub: item.isSub,
      index: item.index,
    };

    payload.roleplay = transformRoleplayToPayload(
      item.roleplay || createEmptyRoleplayData()
    );

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
        if (active) {
          setKeypoints(list);
          mergeKeypointCache(list);
        }
      } catch (err) {
        console.error("fetchKeypoints", err);
      }
    };
    fetchKeypoints();
    return () => {
      active = false;
    };
  }, [keypointQuery, mergeKeypointCache]);

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

  useEffect(() => {
    const contents = currentRoleplay.roleplay?.contents || [];
    const idsToFetch: string[] = [];

    contents.forEach((content) => {
      if (content.type !== RoleplayContentType.EXERCISE) return;
      const keypointId = content.exercise?.keypointId;
      if (
        keypointId &&
        !keypointCache[keypointId] &&
        !pendingKeypointFetches.current.has(keypointId)
      ) {
        idsToFetch.push(keypointId);
        pendingKeypointFetches.current.add(keypointId);
      }
    });

    if (!idsToFetch.length) {
      return;
    }

    let active = true;
    const fetchMissing = async () => {
      await Promise.all(
        idsToFetch.map(async (id) => {
          try {
            const res = await keypointService.getById(id);
            const fetched = res.data;
            if (active && fetched) {
              setKeypointCache((prev) => ({ ...prev, [fetched._id]: fetched }));
            }
          } catch (err) {
            console.error("fetchKeypointDetail", err);
          } finally {
            pendingKeypointFetches.current.delete(id);
          }
        })
      );
    };

    fetchMissing();

    return () => {
      active = false;
    };
  }, [currentRoleplay.roleplay?.contents, keypointCache]);

  const getKeypointLabel = (id?: string) => {
    if (!id) return "";
    const cached = keypointCache[id];
    if (cached) {
      return getTranslationValue(cached.title, lang);
    }
    const found = keypoints.find((kp) => kp._id === id);
    return getTranslationValue(found?.title, lang) || "";
  };

  // Save entire roleplay (create or update)
  const handleSaveRoleplay = useCallback(
    async (options?: { suppressToast?: boolean }) => {
      try {
        setSaving(true);
        const payload = buildLearningItemPayload(currentRoleplay, externalTitle);

        let res;
        if (currentRoleplay._id) {
          res = await learningItemService.update(currentRoleplay._id, payload);
        } else {
          res = await learningItemService.create(payload);
        }

        const savedRoleplay = res.data?.data ?? res.data;
        const apiContents = savedRoleplay.roleplay?.contents || [];
        const apiMissions = savedRoleplay.roleplay?.missions || [];
        const mergedContents =
          (currentRoleplay.roleplay?.contents &&
            currentRoleplay.roleplay.contents.length > 0 &&
            currentRoleplay.roleplay.contents) ||
          apiContents ||
          [];
        const mergedMissions =
          (currentRoleplay.roleplay?.missions &&
            currentRoleplay.roleplay.missions.length > 0 &&
            currentRoleplay.roleplay.missions) ||
          apiMissions ||
          [];
        const mergedRoleplay = {
          ...savedRoleplay,
          roleplay: {
            ...createEmptyRoleplayData(),
            ...(savedRoleplay.roleplay || {}),
            contents: mergedContents,
            missions: mergedMissions,
            colorTemplateId:
              savedRoleplay.roleplay?.colorTemplateId ||
              currentRoleplay.roleplay?.colorTemplateId ||
              "",
            image:
              savedRoleplay.roleplay?.image ||
              currentRoleplay.roleplay?.image ||
              savedRoleplay.image ||
              "",
          },
        };
        setCurrentRoleplay(mergedRoleplay as ILearningItem);
        onSave?.(mergedRoleplay as ILearningItem);
        await new Promise((resolve) => setTimeout(resolve, 500));

        if (!options?.suppressToast) {
          isEditMode
            ? showSuccess("Saved roleplay successfully")
            : showSuccess("Create roleplay successfully");
        }
        return mergedRoleplay as ILearningItem;
    } catch (err) {
      console.error("handleSaveRoleplay", err);
      showError(
        (err as any).response?.data?.message || "Failed to save roleplay"
      );
      return undefined;
    } finally {
      setSaving(false);
    }
  },
    [
      currentRoleplay,
      embedded,
      externalTitle,
      isEditMode,
      onSave,
      showError,
      showSuccess,
    ]
  );

  useEffect(() => {
    if (!saveRef) return;
    saveRef.current = () => handleSaveRoleplay({ suppressToast: embedded });
    return () => {
      saveRef.current = null;
    };
  }, [handleSaveRoleplay, saveRef]);

  // Reorder content and reassign IDs
  const handleReorderContent = (activeId: number, overId: number) => {
    setCurrentRoleplay((prev) => {
      const roleplayData = prev.roleplay || createEmptyRoleplayData();
      const contentList = roleplayData.contents || [];

      const activeIndex = contentList.findIndex((item) => item.id === activeId);
      const overIndex = contentList.findIndex((item) => item.id === overId);

      if (activeIndex === -1 || overIndex === -1 || activeIndex === overIndex) {
        return prev;
      }

      const newContentList = arrayMove(contentList, activeIndex, overIndex);
      const reassignedList = newContentList.map((item, index) => ({
        ...item,
        id: index + 1,
      }));

      return {
        ...prev,
        roleplay: { ...roleplayData, contents: reassignedList },
      };
    });
  };

  const handleOpenContentTypePopup = () => {
    if (colorTemplatesLoading) {
      showError("Please wait for color templates to load");
      return;
    }
    if (!colorTemplates.length) {
      showError("Please create a roleplay color template first");
      return;
    }
    setShowContentTypePopup(true);
  };

  // Select content type and open content form
  const handleSelectContentType = (contentType: RoleplayContentType) => {
    const template = getRoleplayColorTemplate();
    const formData = createEmptyContent(contentType, nextContentId, template);

    setModalOpen({
      contentType,
      formData,
    });

    setShowContentTypePopup(false);
  };

  const handleOpenModal = (
    contentType: RoleplayContentType,
    content?: IRoleplayContent
  ) => {
    const roleplayTemplate = getRoleplayColorTemplate();
    const formData = content
      ? { ...content }
      : createEmptyContent(contentType, nextContentId, roleplayTemplate);

    setModalOpen({ contentType, content, formData });
  };

  // Create empty content based on type
  const createEmptyContent = (
    type: RoleplayContentType,
    id: number,
    template?: IRoleplayColorTemplate
  ) => {
    switch (type) {
      case RoleplayContentType.CONVERSATION: {
        const leftStyle = template?.conversation?.left;
        return {
          id,
          type,
          conversation: {
            avatar: undefined,
            avatarId: "",
            position: RoleplayConversationPosition.LEFT,
            backgroundColor: leftStyle?.backgroundColor || "#FFFFFF",
            textColor: leftStyle?.textColor || "#000000",
            content: { [lang]: "" },
            audio: { [lang]: "" },
          } as IConversation,
        } as IRoleplayContent;
      }
      case RoleplayContentType.LEADING_TEXT:
        return {
          id,
          type,
          leadingText: {
            backgroundColor:
              template?.leadingText?.backgroundColor || "#000000",
            textColor: template?.leadingText?.textColor || "#000000",
            content: { [lang]: "" },
            audio: { [lang]: "" },
          } as ILeadingText,
        } as IRoleplayContent;
      case RoleplayContentType.TRANSITION:
        return {
          id,
          type,
          transition: {
            textColor: template?.transition?.textColor || "#000000",
            content: { [lang]: "" },
          } as ITransition,
        } as IRoleplayContent;
      case RoleplayContentType.EXERCISE:
        return {
          id,
          type,
          exercise: {
            id: 1,
            type: ExerciseType.SINGLE_CHOICE,
            tag: null,
            keypointId: "",
            document: createDefaultDocumentsForExercise(
              ExerciseType.SINGLE_CHOICE,
              lang
            ),
            explanation: { [lang]: "" },
            options: [] as IExerciseChoiceOption[],
            level: [...DEFAULT_LEVELS],
            maxScore: 10,
            mainQuestion: 0,
          } as IExerciseSingleChoice,
        } as IRoleplayContent;
      default:
        return null;
    }
  };

  // Request delete content
  const requestDeleteContent = (
    contentId: number,
    contentTitle = "content"
  ) => {
    setConfirmDeleteContent({ contentId, contentTitle });
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
  const handleSaveContentAndRoleplay = async (
    contentData: IRoleplayContent,
    options?: { isEditing?: boolean }
  ) => {
    try {
      setValidationErrors({});

      let normalizedContent = { ...contentData };
      const assignedId = normalizedContent.id ?? nextContentId;
      normalizedContent = { ...normalizedContent, id: assignedId };

      if (
        normalizedContent.type === RoleplayContentType.CONVERSATION &&
        normalizedContent.conversation
      ) {
        const avatarObj = normalizedContent.conversation.avatar;
        const avatarId =
          normalizedContent.conversation.avatarId || avatarObj?._id || "";
        normalizedContent = {
          ...normalizedContent,
          conversation: {
            ...normalizedContent.conversation,
            avatar: avatarObj,
            avatarId,
          },
        };
      }

      let hasError = false;
      const errors: { [key: string]: string } = {};

      if (normalizedContent.type === RoleplayContentType.CONVERSATION) {
        if (!normalizedContent.conversation?.avatarId) {
          errors.avatar = "Avatar is required for conversation content";
          hasError = true;
        }
      } else if (normalizedContent.type === RoleplayContentType.LEADING_TEXT) {
        if (
          !getCurrentTranslationValue(
            normalizedContent.leadingText?.content,
            lang
          )
        ) {
          errors.content = "Content is required for leading text";
          hasError = true;
        }
      } else if (normalizedContent.type === RoleplayContentType.TRANSITION) {
        if (
          !getCurrentTranslationValue(
            normalizedContent.transition?.content,
            lang
          )
        ) {
          errors.transitionContent = "Content is required for transition";
          hasError = true;
        }
      }

      if (hasError) {
        setValidationErrors(errors);
        return;
      }

      setSaving(true);

      const roleplayData =
        currentRoleplay.roleplay || createEmptyRoleplayData();
      const contents = roleplayData.contents || [];
      const isEditingExisting =
        options?.isEditing || contents.some((c) => c.id === contentData.id);

      let updatedContents: IRoleplayContent[] = [];

      if (isEditingExisting) {
        updatedContents = contents.map((content) =>
          content.id === normalizedContent.id ? normalizedContent : content
        );
      } else {
        updatedContents = [...contents, normalizedContent];
        setNextContentId((prev) => prev + 1);
      }

      const updatedRoleplay: ILearningItem = {
        ...currentRoleplay,
        roleplay: {
          ...roleplayData,
          contents: updatedContents.map((item, index) => ({
            ...item,
            id: item.id ?? index + 1,
          })),
        },
      };

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
      setModalOpen(null);
    } catch (err) {
      console.error("handleSaveContentAndRoleplay", err);
      showError(
        (err as any).response?.data?.message || "Failed to save content"
      );
    } finally {
      setSaving(false);
    }
  };

  // Handle deleting content and saving roleplay together
  const handleDeleteContentAndSaveRoleplay = async () => {
    if (!confirmDeleteContent) return;
    const { contentId } = confirmDeleteContent;
    if (!contentId) {
      setConfirmDeleteContent(null);
      return;
    }

    try {
      setSaving(true);

      const roleplayData =
        currentRoleplay.roleplay || createEmptyRoleplayData();
      const updatedContents = (roleplayData.contents || [])
        .filter((c) => c.id !== contentId)
        .map((item, index) => ({ ...item, id: index + 1 }));

      const updatedRoleplay = {
        ...currentRoleplay,
        roleplay: { ...roleplayData, contents: updatedContents },
      };
      setCurrentRoleplay(updatedRoleplay);

      const payload = buildLearningItemPayload(updatedRoleplay);

      if (updatedRoleplay._id) {
        await learningItemService.update(updatedRoleplay._id, payload);
      }

      showSuccess("Content deleted successfully");
      setConfirmDeleteContent(null);
    } catch (err) {
      console.error("handleDeleteContentAndSaveRoleplay", err);
      showError(
        (err as any).response?.data?.message || "Failed to delete content"
      );
    } finally {
      setSaving(false);
    }
  };

  const updateRoleplayColorTemplate = async (templateId: string) => {
    const template = colorTemplates.find((item) => item._id === templateId);
    if (!template) return;

    const roleplayData = currentRoleplay.roleplay || createEmptyRoleplayData();

    const updatedContents = (roleplayData.contents || []).map((content) => {
      if (content.type === RoleplayContentType.CONVERSATION) {
        const style =
          content.conversation.position === RoleplayConversationPosition.RIGHT
            ? template.conversation?.right
            : template.conversation?.left;
        return {
          ...content,
          conversation: {
            ...content.conversation,
            backgroundColor:
              style?.backgroundColor || content.conversation.backgroundColor,
            textColor: style?.textColor || content.conversation.textColor,
          },
        };
      }
      if (content.type === RoleplayContentType.LEADING_TEXT) {
        return {
          ...content,
          leadingText: {
            ...content.leadingText,
            backgroundColor:
              template.leadingText?.backgroundColor ||
              content.leadingText.backgroundColor,
            textColor:
              template.leadingText?.textColor || content.leadingText.textColor,
          },
        };
      }
      if (content.type === RoleplayContentType.TRANSITION) {
        return {
          ...content,
          transition: {
            ...content.transition,
            textColor:
              template.transition?.textColor ||
              content.transition?.textColor ||
              "#000000",
          },
        };
      }
      return content;
    });

    const updatedRoleplay = {
      ...currentRoleplay,
      roleplay: {
        ...roleplayData,
        colorTemplateId: templateId,
        contents: updatedContents,
      },
    };

    setCurrentRoleplay(updatedRoleplay);

    if (!updatedRoleplay._id) return;

    try {
      setSaving(true);
      const payload = buildLearningItemPayload(updatedRoleplay);
      await learningItemService.update(updatedRoleplay._id, payload);
      showSuccess("Updated roleplay color template");
    } catch (err) {
      console.error("updateRoleplayColorTemplate", err);
      showError(
        (err as any).response?.data?.message || "Failed to save color template"
      );
    } finally {
      setSaving(false);
    }
  };

  const addMission = () => {
    const roleplayData = currentRoleplay.roleplay || createEmptyRoleplayData();
    const newMission: IMission = {
      id: nextMissionId,
      content: { [lang]: "" },
    };
    setCurrentRoleplay({
      ...currentRoleplay,
      roleplay: {
        ...roleplayData,
        missions: [...(roleplayData.missions || []), newMission],
      },
    });
    setNextMissionId((prev) => prev + 1);
  };

  const updateMissionContent = (missionId: number, content: ITranslation) => {
    setCurrentRoleplay((prev) => {
      const roleplayData = prev.roleplay || createEmptyRoleplayData();
      const missions = (roleplayData.missions || []).map((mission) =>
        mission.id === missionId ? { ...mission, content } : mission
      );
      return { ...prev, roleplay: { ...roleplayData, missions } };
    });
  };

  const removeMission = (missionId: number) => {
    setCurrentRoleplay((prev) => {
      const roleplayData = prev.roleplay || createEmptyRoleplayData();
      const missions = (roleplayData.missions || []).filter(
        (mission) => mission.id !== missionId
      );
      return { ...prev, roleplay: { ...roleplayData, missions } };
    });
  };

  const renderMissions = () => {
    const roleplayData = currentRoleplay.roleplay || createEmptyRoleplayData();
    const missions = roleplayData.missions || [];

    return (
      <div className="mb-6 bg-white border border-gray-200 rounded-lg p-4">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div className="space-y-3">
            <h3 className="text-lg font-semibold text-gray-800">
              Roleplay Image
            </h3>
            <CloudflareFileUpload
              initialUrl={roleplayData.image || ""}
              onUrlChange={(url) =>
                setCurrentRoleplay((prev) => ({
                  ...prev,
                  roleplay: {
                    ...(roleplayData || createEmptyRoleplayData()),
                    image: url,
                    contents: roleplayData.contents,
                    missions: roleplayData.missions,
                    colorTemplateId: roleplayData.colorTemplateId,
                  },
                }))
              }
              label=""
              uploadPayload={{
                prefix: "",
                folder: "roleplays",
              }}
            />
            <p className="text-xs text-gray-500">
              Image is shown in previews and alongside the roleplay lesson.
            </p>
          </div>

          <div className="lg:col-span-2 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-800">Missions</h3>
              <button
                type="button"
                onClick={() => handleSaveRoleplay()}
                className="inline-flex items-center gap-2 px-3 py-1.5 bg-blue-600 text-white rounded-md shadow hover:bg-blue-700 transition text-sm"
                disabled={saving}
              >
                {saving ? (
                  <ArrowPathIcon className="h-4 w-4 animate-spin" />
                ) : (
                  <ArrowDownTrayIcon className="h-4 w-4" />
                )}
                <span>{saving ? "Saving..." : "Save"}</span>
              </button>
            </div>

            {missions.length === 0 ? (
              <p className="text-sm text-gray-500">
                No missions yet. Add missions to guide learners through the
                roleplay.
              </p>
            ) : (
              <div className="space-y-3">
                {missions.map((mission, index) => (
                  <div
                    key={mission.id ?? index}
                    className="flex items-start gap-2 border border-gray-100 rounded-lg p-3"
                  >
                    <div className="flex-1">
                      <textarea
                        value={getCurrentTranslationValue(
                          mission.content,
                          lang
                        )}
                        onChange={(e) =>
                          updateMissionContent(
                            mission.id,
                            updateTranslationValue(
                              mission.content || {},
                              lang,
                              e.target.value
                            )
                          )
                        }
                        rows={2}
                        className="w-full border rounded-lg p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                        placeholder="Mission content"
                      />
                    </div>
                    <button
                      type="button"
                      onClick={() => removeMission(mission.id)}
                      className="text-red-500 hover:text-red-700 p-1"
                    >
                      <TrashIcon className="h-5 w-5" />
                    </button>
                  </div>
                ))}
              </div>
            )}

            <div className="flex justify-center">
              <button
                type="button"
                onClick={addMission}
                className="flex items-center gap-1 text-blue-600 hover:text-blue-800"
              >
                <PlusCircleIcon className="h-7 w-7" />
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  };

  // Render contents with drag and drop
  const renderContents = () => {
    const roleplayData = currentRoleplay.roleplay || createEmptyRoleplayData();
    const contents = roleplayData.contents || [];
    const selectedTemplate = getRoleplayColorTemplate();
    const formatDisplay = (val: any) => {
      if (!val) return "(empty)";
      if (typeof val === "string") return val;
      return (
        getTranslationValue(val, lang) ||
        getCurrentTranslationValue(val, lang) ||
        "(empty)"
      );
    };

    return (
      <div className="mb-6 bg-gray-50 rounded-xl p-6 shadow-sm">
        <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-3 mb-4">
          <div></div>
          <div className="w-full md:w-64">
            <label className="block text-[16px] font-medium text-blue-700 mb-1">
              Color Template
            </label>
            <select
              value={roleplayData.colorTemplateId || ""}
              onChange={(e) => updateRoleplayColorTemplate(e.target.value)}
              className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
            >
              <option value="">Select template</option>
              {colorTemplates.map((template) => (
                <option key={template._id} value={template._id}>
                  {template.title}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="mb-6">
          <div className="flex items-center gap-2 mb-2">
            <span className="text-sm font-semibold text-gray-800">
              Missions
            </span>
          </div>
          {renderMissions()}
        </div>

        <div className="border-t border-gray-200 pt-4">
          <div className="flex items-center justify-between mb-3">
            <div>
              <h3 className="text-lg font-semibold text-gray-800">Contents</h3>
              <p className="text-sm text-gray-500">
                👉 Drag to reorder. Click a card to edit.
              </p>
            </div>
          </div>
          {contents.length > 0 ? (
            <DndContext
              collisionDetection={closestCenter}
              onDragEnd={(event) => {
                const { active, over } = event;

                if (over && active.id !== over.id) {
                  const activeId =
                    typeof active.id === "string"
                      ? parseInt(active.id)
                      : (active.id as number);
                  const overId =
                    typeof over.id === "string"
                      ? parseInt(over.id)
                      : (over.id as number);

                  handleReorderContent(activeId, overId);
                }
              }}
            >
              <SortableContext
                items={contents.map((item) => item.id!.toString())}
                strategy={verticalListSortingStrategy}
              >
                <div className="space-y-3">
                  {contents.map((content) => {
                    const keypointLabel =
                      content.type === RoleplayContentType.EXERCISE
                        ? getKeypointLabel(content.exercise.keypointId)
                        : "";
                    const exerciseTypeLabel =
                      content.type === RoleplayContentType.EXERCISE
                        ? getExerciseTypeLabel(content.exercise.type)
                        : "";
                    const exerciseExplanation =
                      content.type === RoleplayContentType.EXERCISE
                        ? getTranslationValue(
                            content.exercise.explanation,
                            lang
                          ) ||
                          getCurrentTranslationValue(
                            content.exercise.explanation,
                            lang
                          )
                        : "";
                    const dragDropFormLabel =
                      content.type === RoleplayContentType.EXERCISE &&
                      content.exercise?.type === ExerciseType.DRAG_DROP
                        ? getDragDropFormLabel(
                            content.exercise.type,
                            (content.exercise as IExerciseDragDrop)?.form
                          )
                        : "";
                    return (
                      <SortableItem
                        key={content.id}
                        id={content.id!.toString()}
                      >
                        <motion.div
                          initial={{ opacity: 0, y: 10 }}
                          animate={{ opacity: 1, y: 0 }}
                          className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                        >
                        <div className="flex items-start justify-between">
                          <div className="flex flex-col gap-2">
                            <div className="flex items-center gap-2">
                              <span className="text-xs font-medium text-pink-500 uppercase tracking-wide">
                                {content.type}
                              </span>
                              <span className="text-xs text-gray-500">
                                ID: {content.id}
                              </span>
                              {selectedTemplate && (
                                <span className="text-xs text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded-full">
                                  {selectedTemplate.title}
                                </span>
                              )}
                            </div>
                            {content.type ===
                              RoleplayContentType.CONVERSATION && (
                              <div className="flex items-center gap-2">
                                {content.conversation.avatar?.url && (
                                  <img
                                    src={content.conversation.avatar.url}
                                    alt={content.conversation.avatar.name}
                                    className="w-8 h-8 rounded-full object-cover border"
                                  />
                                )}
                                <div className="flex items-center gap-2">
                                  <div
                                    className="w-4 h-4 rounded-full border border-gray-300"
                                    style={{
                                      backgroundColor:
                                        content.conversation.backgroundColor,
                                    }}
                                  ></div>
                                  <div
                                    className="w-4 h-4 rounded-full border border-gray-300"
                                    style={{
                                      backgroundColor:
                                        content.conversation.textColor,
                                    }}
                                  ></div>
                                  <span className="text-xs text-gray-500">
                                    {content.conversation.position}
                                  </span>
                                </div>
                                {getTranslationValue(
                                  content.conversation.audio,
                                  lang
                                ) && (
                                  <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    className="h-4 w-4 text-gray-500"
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
                                  text={content.conversation.content}
                                  maxLength={120}
                                  lang={lang}
                                />
                              </div>
                            )}

                            {content.type ===
                              RoleplayContentType.LEADING_TEXT && (
                              <div className="flex items-center gap-2">
                                <div
                                  className="w-4 h-4 rounded-full border border-gray-300"
                                  style={{
                                    backgroundColor:
                                      content.leadingText.backgroundColor,
                                  }}
                                ></div>
                                <div
                                  className="w-4 h-4 rounded-full border border-gray-300"
                                  style={{
                                    backgroundColor:
                                      content.leadingText.textColor,
                                  }}
                                ></div>
                                {getTranslationValue(
                                  content.leadingText.audio,
                                  lang
                                ) && (
                                  <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    className="h-4 w-4 text-gray-500"
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
                                  text={content.leadingText.content}
                                  maxLength={120}
                                  lang={lang}
                                />
                              </div>
                            )}

                            {content.type ===
                              RoleplayContentType.TRANSITION && (
                              <div className="flex items-center gap-2">
                                <div
                                  className="w-4 h-4 rounded-full border border-gray-300"
                                  style={{
                                    backgroundColor:
                                      content.transition?.textColor ||
                                      "#000000",
                                  }}
                                ></div>
                                <TextWithTooltip
                                  text={content.transition?.content}
                                  maxLength={120}
                                  lang={lang}
                                />
                              </div>
                            )}

                            {content.type === RoleplayContentType.EXERCISE && (
                              <div className="space-y-3">
                                <div className="flex flex-wrap items-center gap-3">
                                  <span className="text-base font-semibold text-gray-800">
                                    {exerciseTypeLabel || "Exercise"}
                                  </span>
                                  {dragDropFormLabel && (
                                    <span className="text-xs flex items-center gap-1 text-gray-400">
                                      <span className="font-semibold text-blue-700">
                                        Form:
                                      </span>
                                      <span className="text-gray-600">
                                        {dragDropFormLabel}
                                      </span>
                                    </span>
                                  )}
                                  {keypointLabel && (
                                    <span className="text-xs flex items-center gap-1 text-gray-400">
                                      <span className="font-semibold text-emerald-700">
                                        Keypoint:
                                      </span>
                                      <span className="text-gray-600">
                                        {keypointLabel}
                                      </span>
                                    </span>
                                  )}
                                  {content.exercise.tag && (
                                    <TagDisplay
                                      tag={content.exercise.tag}
                                      lang={lang}
                                    />
                                  )}
                                </div>
                                {content.exercise.maxScore && (
                                  <div className="flex items-center gap-2 flex-wrap text-xs text-gray-600">
                                    <span className="font-medium text-gray-600">
                                      Max score: {content.exercise.maxScore}
                                    </span>
                                    {"scoringCriteria" in content.exercise &&
                                      content.exercise.scoringCriteria && (
                                        <span className="text-xs text-gray-500 font-mono">
                                          Criteria:{" "}
                                          {
                                            content.exercise.scoringCriteria
                                              .length
                                          }
                                        </span>
                                      )}
                                  </div>
                                )}
                                {content.exercise.type ===
                                  ExerciseType.DRAG_DROP &&
                                  (content.exercise as IExerciseDragDrop)
                                    .targetArea && (
                                    <div className="text-xs text-gray-600">
                                      <span className="font-semibold text-gray-700">
                                        Target Area:
                                      </span>
                                      <div className="pl-2">
                                        <TextWithTooltip
                                          text={formatDisplay(
                                            (
                                              content.exercise as IExerciseDragDrop
                                            ).targetArea
                                          )}
                                          maxLength={120}
                                          lang={lang}
                                        />
                                      </div>
                                    </div>
                                  )}
                                {exerciseExplanation?.trim() && (
                                  <div className="text-xs text-gray-600">
                                    <span className="font-semibold text-gray-700">
                                      Explanation:
                                    </span>
                                    <div className="pl-2">
                                      <TextWithTooltip
                                        text={content.exercise.explanation}
                                        maxLength={120}
                                        lang={lang}
                                      />
                                    </div>
                                  </div>
                                )}
                                {"options" in content.exercise &&
                                  Array.isArray(content.exercise.options) &&
                                  content.exercise.options.length > 0 && (
                                    <div>
                                      <span className="font-semibold text-blue-500 text-sm">
                                        Options
                                      </span>
                                      <ul className="mt-2 space-y-1 text-sm text-gray-600">
                                        {content.exercise.options.map(
                                          (opt: any, idx: number) => (
                                            <li
                                              key={opt.id || idx}
                                              className="flex items-start gap-2"
                                            >
                                              {(content.exercise.type ===
                                                ExerciseType.SINGLE_CHOICE ||
                                                content.exercise.type ===
                                                  ExerciseType.MULTIPLE_CHOICE) && (
                                                <span
                                                  className={`w-3 h-3 rounded-full mt-1 ${
                                                    opt.isCorrect
                                                      ? "bg-green-500"
                                                      : "bg-gray-300"
                                                  }`}
                                                ></span>
                                              )}
                                              <TextWithTooltip
                                                text={formatDisplay(
                                                  content.exercise.type ===
                                                    ExerciseType.DRAG_DROP
                                                    ? opt.text
                                                    : opt.value
                                                )}
                                                maxLength={120}
                                                lang={lang}
                                              />
                                            </li>
                                          )
                                        )}
                                      </ul>
                                    </div>
                                  )}
                                {"answer" in content.exercise &&
                                  Array.isArray(content.exercise.answer) &&
                                  content.exercise.answer.length > 0 && (
                                    <div>
                                      <span className="font-semibold text-blue-500 text-sm">
                                        Answers
                                      </span>
                                      <ul className="mt-2 space-y-1 text-sm text-gray-600">
                                        {content.exercise.answer.map(
                                          (ans: any, idx: number) => (
                                            <li
                                              key={ans.id || idx}
                                              className="pl-2"
                                            >
                                              <TextWithTooltip
                                                text={formatDisplay(
                                                  ans.correctAnswer
                                                )}
                                                maxLength={120}
                                                lang={lang}
                                              />
                                            </li>
                                          )
                                        )}
                                      </ul>
                                    </div>
                                  )}
                                {"scoringCriteria" in content.exercise &&
                                  Array.isArray(
                                    content.exercise.scoringCriteria
                                  ) &&
                                  content.exercise.scoringCriteria.length >
                                    0 && (
                                    <span className="text-xs text-gray-600">
                                      Scoring criteria:{" "}
                                      {content.exercise.scoringCriteria.length}
                                    </span>
                                  )}
                                {content.exercise.type ===
                                  ExerciseType.RECORD &&
                                  (content.exercise as any).maxDuration && (
                                    <span className="text-xs text-gray-600">
                                      Max duration:{" "}
                                      {(content.exercise as any).maxDuration}s
                                    </span>
                                  )}
                                {content.exercise.type ===
                                  ExerciseType.RECORD &&
                                  (content.exercise as any).maxCharacter && (
                                    <span className="text-xs text-gray-600">
                                      Max characters:{" "}
                                      {(content.exercise as any).maxCharacter}
                                    </span>
                                  )}
                              </div>
                            )}
                          </div>

                          <div className="flex gap-1">
                            <button
                              onClick={() =>
                                handleOpenModal(content.type, content)
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
                      </motion.div>
                    </SortableItem>
                    );
                  })}
                </div>
              </SortableContext>
            </DndContext>
          ) : (
            <p className="text-sm text-gray-500">
              No content yet. Add conversation, leading text, transition or
              exercise to build this roleplay.
            </p>
          )}
          <div className="mt-4 flex justify-center">
            <button
              className="flex items-center gap-1 text-blue-600 hover:text-blue-800"
              onClick={handleOpenContentTypePopup}
            >
              <PlusCircleIcon className="h-7 w-7" />
            </button>
          </div>
        </div>
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
    formData,
  }: {
    content?: IRoleplayContent;
    onSave: (c: IRoleplayContent, options?: { isEditing?: boolean }) => void;
    onCancel: () => void;
    contentType: RoleplayContentType;
    formData: IRoleplayContent;
  }) => {
    const [localFormData, setLocalFormData] = useState<any>(formData);
    const [validationErrors, setValidationErrors] = useState<{
      [key: string]: string;
    }>({});
    const [showEmptyDocuments, setShowEmptyDocuments] = useState(false);

    const [localNextOptionId, setLocalNextOptionId] = useState(nextOptionId);
    const [localNextAnswerId, setLocalNextAnswerId] = useState(nextAnswerId);

    const normalizeTranslationField = (
      value: ITranslation | string | undefined
    ): ITranslation => {
      if (!value) return { [lang]: "" };
      if (typeof value === "string") {
        const trimmed = value.trim();
        if (!trimmed) return { [lang]: "" };
        const normalized: ITranslation = { [lang]: trimmed };
        if (lang !== LangCode.EN && !normalized[LangCode.EN]) {
          normalized[LangCode.EN] = trimmed;
        }
        return normalized;
      }
      return value;
    };

    const ensureLocalizedContent = (data: any) => {
      if (!data) return data;
      const updated: any = { ...data };

      if (updated.conversation) {
        updated.conversation = {
          ...updated.conversation,
          content: updated.conversation.content || { [lang]: "" },
          audio: normalizeTranslationField(updated.conversation.audio),
        };
      }

      if (updated.leadingText) {
        updated.leadingText = {
          ...updated.leadingText,
          content: updated.leadingText.content || { [lang]: "" },
          audio: normalizeTranslationField(updated.leadingText.audio),
        };
      }

      if (updated.transition) {
        updated.transition = {
          ...updated.transition,
          content: updated.transition.content || { [lang]: "" },
          textColor: updated.transition.textColor || "#000000",
        };
      }

      return updated;
    };

    const applyExerciseDefaults = (data: any) => {
      if (!data?.exercise) return data;
      const type = data.exercise.type;
      const updatedExercise = { ...data.exercise };

      if (
        (type === ExerciseType.SINGLE_CHOICE ||
          type === ExerciseType.MULTIPLE_CHOICE) &&
        (!updatedExercise.options || updatedExercise.options.length === 0)
      ) {
        updatedExercise.options = [{ value: { [lang]: "" }, isCorrect: false }];
      }

      if (
        type === ExerciseType.DRAG_DROP &&
        (!updatedExercise.answer || updatedExercise.answer.length === 0)
      ) {
        const newId = localNextAnswerId;
        updatedExercise.answer = [{ correctAnswer: { [lang]: "" }, id: newId }];
        setLocalNextAnswerId(newId + 1);
      }

      if (type === ExerciseType.DRAG_DROP && updatedExercise.options?.length) {
        const hasContent = updatedExercise.options.some((opt: any) => {
          const tokens = getTranslationTokens(opt.text || opt.value);
          return tokens.size > 0;
        });
        if (!hasContent) {
          updatedExercise.options = [];
        }
      }

      return {
        ...data,
        exercise: updatedExercise,
      };
    };

    // Update local form data when formData prop changes
    useEffect(() => {
      const normalizedFormData = ensureLocalizedContent(formData);
      let nextFormData = normalizedFormData;
      if (normalizedFormData?.exercise?.type === ExerciseType.RECORD) {
        const normalizedCriteria = rebalanceRecordScoringCriteria(
          normalizedFormData.exercise.scoringCriteria,
          typeof normalizedFormData.exercise.maxScore === "number"
            ? normalizedFormData.exercise.maxScore
            : undefined
        );

        nextFormData = {
          ...normalizedFormData,
          exercise: {
            ...normalizedFormData.exercise,
            scoringCriteria: normalizedCriteria,
          },
        };
      }
      setLocalFormData(applyExerciseDefaults(nextFormData));
      // Clear errors when form data is reset (e.g., when opening a new content form)
      setValidationErrors({});
      setShowEmptyDocuments(false);
    }, [formData]);

    // Ensure translation objects have current language key when language changes
    useEffect(() => {
      setLocalFormData((prev: any) => {
        if (!prev) return prev;
        const updated = ensureLocalizedContent(prev);
        if (updated.exercise) {
          updated.exercise = {
            ...updated.exercise,
            explanation: updated.exercise.explanation || { [lang]: "" },
            targetArea: updated.exercise.targetArea || { [lang]: "" },
          };

          if (updated.exercise.options) {
            updated.exercise.options = updated.exercise.options.map(
              (opt: any) => ({
                ...opt,
                value: opt.value || { [lang]: "" },
                text: opt.text || { [lang]: "" },
              })
            );
          }

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
    }, [lang]);

    // --- Validation Function ---
    const validateForm = () => {
      const errors: { [key: string]: string } = {};

      if (contentType === RoleplayContentType.CONVERSATION) {
        if (!localFormData.conversation?.avatar?._id) {
          errors.avatar = "Avatar is required.";
        }
      } else if (contentType === RoleplayContentType.LEADING_TEXT) {
        if (
          !getTranslationValue(localFormData.leadingText?.content, lang)?.trim()
        ) {
          errors.content = "Content is required.";
        }
      } else if (contentType === RoleplayContentType.TRANSITION) {
        if (
          !getTranslationValue(localFormData.transition?.content, lang)?.trim()
        ) {
          errors.transitionContent = "Content is required.";
        }
      }

      setValidationErrors(errors);
      return Object.keys(errors).length === 0;
    };

    const handleChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => ({ ...prev, [field]: value }));
    };

    const roleplayTemplate = getRoleplayColorTemplate();

    const handleConversationChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => {
        const prevConversation = prev.conversation || {};
        const nextValue =
          field === "audio" && typeof value === "string"
            ? updateTranslationValue(prevConversation.audio || {}, lang, value)
            : value;

        const updatedConversation: any = {
          ...prevConversation,
          [field]: nextValue,
        };

        if (field === "position" && roleplayTemplate && value) {
          const style =
            value === RoleplayConversationPosition.RIGHT
              ? roleplayTemplate.conversation?.right
              : roleplayTemplate.conversation?.left;
          if (style?.backgroundColor) {
            updatedConversation.backgroundColor = style.backgroundColor;
          }
          if (style?.textColor) {
            updatedConversation.textColor = style.textColor;
          }
        }

        return {
          ...prev,
          conversation: updatedConversation,
        };
      });
      // Clear error on change
      if (field === "avatar" || field === "avatarId") {
        setValidationErrors((prev) => ({ ...prev, avatar: "" }));
      }
    };

    const handleLeadingTextChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => {
        const prevLeading = prev.leadingText || {};
        const nextValue =
          field === "audio" && typeof value === "string"
            ? updateTranslationValue(prevLeading.audio || {}, lang, value)
            : value;

        return {
          ...prev,
          leadingText: {
            ...prevLeading,
            [field]: nextValue,
          },
        };
      });
      // Clear error on change
      if (field === "content" && validationErrors.content) {
        setValidationErrors((prev) => ({ ...prev, content: "" }));
      }
    };

    const handleTransitionChange = (field: string, value: any) => {
      setLocalFormData((prev: any) => ({
        ...prev,
        transition: {
          ...prev.transition,
          [field]: value,
        },
      }));
      if (field === "content" && validationErrors.transitionContent) {
        setValidationErrors((prev) => ({ ...prev, transitionContent: "" }));
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

        if (field === "type") {
          if (
            (value === ExerciseType.SINGLE_CHOICE ||
              value === ExerciseType.MULTIPLE_CHOICE) &&
            (!nextExercise.options || nextExercise.options.length === 0)
          ) {
            nextExercise.options = [{ value: { [lang]: "" }, isCorrect: false }];
          }

          if (
            value === ExerciseType.DRAG_DROP &&
            (!nextExercise.answer || nextExercise.answer.length === 0)
          ) {
            const newId = localNextAnswerId;
            nextExercise.answer = [{ correctAnswer: { [lang]: "" }, id: newId }];
            setLocalNextAnswerId(newId + 1);
          }

          if (value === ExerciseType.DRAG_DROP && nextExercise.options?.length) {
            const hasContent = nextExercise.options.some((opt: any) => {
              const tokens = getTranslationTokens(opt.text || opt.value);
              return tokens.size > 0;
            });
            if (!hasContent) {
              nextExercise.options = [];
            }
          }
        }

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
        if (!prev.exercise?.document) return prev;
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
        if (!prev.exercise?.document) return prev;
        const newDocuments = [...prev.exercise.document];
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
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Audio URL"
              uploadPayload={{
                prefix: "",
                folder: "roleplays",
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
                folder: "roleplays",
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
                folder: "roleplays",
              }}
              accept="application/json,.json,.lottie"
            />
          </div>
        );
      }

      return null;
    };

    const addNewDocument = () => {
      if (
        contentType !== RoleplayContentType.EXERCISE ||
        !localFormData.exercise
      )
        return;

      setLocalFormData((prev: any) => {
        const existingDocs = prev.exercise?.document || [];
        const hasContent = cleanDocumentItems(existingDocs).length > 0;
        const shouldDropEmpty =
          prev.exercise?.type === ExerciseType.DRAG_DROP &&
          !showEmptyDocuments &&
          !hasContent;
        const baseDocs = shouldDropEmpty ? [] : existingDocs;
        const currentMaxId = baseDocs.reduce(
          (max: number, doc: IDocument) => Math.max(max, doc.id || 0),
          0
        );
        const newId = currentMaxId + 1;

        return {
          ...prev,
          exercise: {
            ...prev.exercise,
            document: [
              ...baseDocs,
              {
                id: newId,
                type: DocumentType.TEXT,
                data: createEmptyMediaDocument(lang),
              },
            ],
          },
        };
      });
      setShowEmptyDocuments(true);
    };

    const removeDocument = (index: number) => {
      if (
        contentType !== RoleplayContentType.EXERCISE ||
        !localFormData.exercise
      )
        return;
      setLocalFormData((prev: any) => {
        const documents = prev.exercise?.document;
        if (!documents) {
          return prev;
        }
        const updatedDocuments = documents.filter(
          (_: IDocument, i: number) => i !== index
        );
        if (updatedDocuments.length === 0) {
          setShowEmptyDocuments(false);
        }
        return {
          ...prev,
          exercise: {
            ...prev.exercise,
            document: updatedDocuments,
          },
        };
      });
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
        contentType === RoleplayContentType.EXERCISE &&
        localFormData.exercise
      ) {
        const cleanedDocuments = cleanDocumentItems(
          localFormData.exercise.document || []
        );
        dataToSave = {
          ...dataToSave,
          exercise: {
            ...localFormData.exercise,
            document: cleanedDocuments,
          },
        };
      }

      if (
        contentType === RoleplayContentType.EXERCISE &&
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

      onSave({ ...dataToSave }, { isEditing: Boolean(content) });
    };

    // Add new option
    const addOption = () => {
      if (
        contentType === RoleplayContentType.EXERCISE &&
        (localFormData.exercise.type === ExerciseType.SINGLE_CHOICE ||
          localFormData.exercise.type === ExerciseType.MULTIPLE_CHOICE)
      ) {
        const newOptions = [
          ...localFormData.exercise.options,
          { value: "", isCorrect: false },
        ];
        handleExerciseChange("options", newOptions);
      } else if (
        contentType === RoleplayContentType.EXERCISE &&
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
        contentType === RoleplayContentType.EXERCISE &&
        (localFormData.exercise.type === ExerciseType.SINGLE_CHOICE ||
          localFormData.exercise.type === ExerciseType.MULTIPLE_CHOICE)
      ) {
        const newOptions = [...localFormData.exercise.options];
        newOptions.splice(index, 1);
        handleExerciseChange("options", newOptions);
      } else if (
        contentType === RoleplayContentType.EXERCISE &&
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
        contentType === RoleplayContentType.EXERCISE &&
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
        contentType === RoleplayContentType.EXERCISE &&
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
        contentType === RoleplayContentType.EXERCISE &&
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
      if (newAnswer.length === 0) {
        const newId = localNextAnswerId;
        setLocalNextAnswerId(newId + 1);
        newAnswer.push({ correctAnswer: { [lang]: "" }, id: newId });
      }
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

    const getTranslationTokens = (
      value: ITranslation | string | undefined
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
      value: ITranslation | string | undefined
    ): ITranslation => {
      if (!value) return { [lang]: "" };
      if (typeof value === "string") {
        return updateTranslationValue(undefined, lang, value);
      }
      return value;
    };

    const mergeTranslations = (
      target: ITranslation | undefined,
      source: ITranslation
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
      if (
        contentType !== RoleplayContentType.EXERCISE ||
        localFormData.exercise?.type !== ExerciseType.DRAG_DROP
      ) {
        return;
      }

      const currentOptions = Array.isArray(localFormData.exercise.options)
        ? localFormData.exercise.options
        : [];
      const currentAnswers = Array.isArray(localFormData.exercise.answer)
        ? localFormData.exercise.answer
        : [];

      let nextId = localNextOptionId;
      const mergedOptions = [...currentOptions];
      const optionTokens = mergedOptions.map((opt: IOptions) =>
        getTranslationTokens(opt.text)
      );

      currentAnswers.forEach((ans: IAnswer) => {
        const answerTranslation = ensureTranslation(ans.correctAnswer);
        const answerTokens = getTranslationTokens(answerTranslation);
        if (answerTokens.size === 0) return;

        const matchIndex = optionTokens.findIndex((tokens) =>
          hasOverlap(tokens, answerTokens)
        );

        if (matchIndex === -1) {
          mergedOptions.push({ id: nextId++, text: answerTranslation });
          optionTokens.push(getTranslationTokens(answerTranslation));
          return;
        }

        const existingOption = mergedOptions[matchIndex];
        const mergedText = mergeTranslations(
          existingOption.text,
          answerTranslation
        );
        mergedOptions[matchIndex] = { ...existingOption, text: mergedText };
        optionTokens[matchIndex] = getTranslationTokens(mergedText);
      });

      const shuffled = shuffleArray(mergedOptions);
      handleExerciseChange("options", shuffled);
      if (nextId !== localNextOptionId) setLocalNextOptionId(nextId);
    };

    const handlePasteExerciseOptions = (
      index: number,
      e: React.ClipboardEvent<HTMLInputElement | HTMLTextAreaElement>
    ) => {
      if (contentType !== RoleplayContentType.EXERCISE) return;
      const pasted = e.clipboardData.getData("text");
      if (!pasted) return;
      const lines = pasted
        .split(/\r?\n/)
        .map((l) => l.trim())
        .filter(Boolean);
      if (lines.length <= 1) return;
      e.preventDefault();

      setLocalFormData((prev: any) => {
        const currentExercise = prev.exercise || {};
        const currentOptions = Array.isArray(currentExercise.options)
          ? [...currentExercise.options]
          : [];
        let nextId = localNextOptionId;

        if (!currentOptions[index]) {
          if (currentExercise.type === ExerciseType.DRAG_DROP) {
            currentOptions[index] = { text: { [lang]: "" }, id: nextId++ };
          } else {
            currentOptions[index] = { value: { [lang]: "" }, isCorrect: false };
          }
        }

        lines.forEach((line, offset) => {
          const targetIndex = index + offset;
          const existing = currentOptions[targetIndex];
          if (currentExercise.type === ExerciseType.DRAG_DROP) {
            const id = existing?.id ?? nextId++;
            currentOptions[targetIndex] = {
              ...existing,
              id,
              text: updateTranslationValue(existing?.text || {}, lang, line),
            };
          } else {
            currentOptions[targetIndex] = {
              ...existing,
              value: updateTranslationValue(existing?.value || {}, lang, line),
              isCorrect: existing?.isCorrect ?? false,
            };
          }
        });

        if (nextId !== localNextOptionId) setLocalNextOptionId(nextId);
        return {
          ...prev,
          exercise: { ...currentExercise, options: currentOptions },
        };
      });
    };

    const handlePasteExerciseAnswers = (
      index: number,
      e: React.ClipboardEvent<HTMLInputElement | HTMLTextAreaElement>
    ) => {
      const pasted = e.clipboardData.getData("text");
      if (!pasted) return;
      const lines = pasted
        .split(/\r?\n/)
        .map((l) => l.trim())
        .filter(Boolean);
      if (lines.length <= 1) return;
      e.preventDefault();

      setLocalFormData((prev: any) => {
        const currentExercise = prev.exercise || {};
        const currentAnswer = Array.isArray(currentExercise.answer)
          ? [...currentExercise.answer]
          : [];
        let nextId = localNextAnswerId;

        if (!currentAnswer[index]) {
          currentAnswer[index] = {
            correctAnswer: { [lang]: "" },
            id: nextId++,
          };
        }

        lines.forEach((line, offset) => {
          const targetIndex = index + offset;
          const existing = currentAnswer[targetIndex];
          const id = existing?.id ?? nextId++;
          currentAnswer[targetIndex] = {
            ...existing,
            id,
            correctAnswer: updateTranslationValue(
              existing?.correctAnswer || {},
              lang,
              line
            ),
          };
        });

        if (nextId !== localNextAnswerId) setLocalNextAnswerId(nextId);
        return {
          ...prev,
          exercise: { ...currentExercise, answer: currentAnswer },
        };
      });
    };

    const handlePasteCriteria = (
      index: number,
      e: React.ClipboardEvent<HTMLTextAreaElement>
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
            line
          ),
          maxScore: existing?.maxScore,
        };
      });
      handleExerciseChange("scoringCriteria", next);
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
        { criteria: { [lang]: "" }, maxScore: undefined },
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

    const effectiveDragDropForm =
      localFormData.exercise?.form || FormDragDropType.TextGapFilling;
    const showShuffleButton =
      localFormData.exercise?.type === ExerciseType.DRAG_DROP &&
      (effectiveDragDropForm === FormDragDropType.TextGapFilling ||
        effectiveDragDropForm === FormDragDropType.ArrangeTheSequence);
    const hasDocumentContent = cleanDocumentItems(
      localFormData.exercise?.document || []
    ).length;
    const showDocumentItems =
      localFormData.exercise?.type !== ExerciseType.DRAG_DROP ||
      hasDocumentContent > 0 ||
      showEmptyDocuments;

    return (
      <div className="space-y-4">
        {contentType === RoleplayContentType.CONVERSATION && (
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
                  RoleplayConversationPosition.LEFT
                }
                onChange={(e) =>
                  handleConversationChange("position", e.target.value)
                }
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              >
                <option value={RoleplayConversationPosition.LEFT}>Left</option>
                <option value={RoleplayConversationPosition.RIGHT}>
                  Right
                </option>
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
                initialUrl={
                  getCurrentTranslationValue(
                    localFormData.conversation.audio,
                    lang
                  ) || ""
                }
                onUrlChange={(newUrl) =>
                  handleConversationChange("audio", newUrl)
                }
                label=""
                uploadPayload={{
                  prefix: "",
                  folder: "roleplays",
                }}
                accept="audio/*"
              />
            </div>
          </>
        )}

        {contentType === RoleplayContentType.LEADING_TEXT && (
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
                initialUrl={
                  getCurrentTranslationValue(
                    localFormData.leadingText.audio,
                    lang
                  ) || ""
                }
                onUrlChange={(newUrl) =>
                  handleLeadingTextChange("audio", newUrl)
                }
                label=""
                uploadPayload={{
                  prefix: "",
                  folder: "roleplays",
                }}
                accept="audio/*"
              />
            </div>
          </>
        )}

        {contentType === RoleplayContentType.TRANSITION && (
          <>
            <ColorPicker
              value={localFormData.transition?.textColor || "#000000"}
              onChange={(value) => handleTransitionChange("textColor", value)}
              label="Text Color"
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Content
              </label>
              <textarea
                value={getCurrentTranslationValue(
                  localFormData.transition?.content,
                  lang
                )}
                onChange={(e) =>
                  handleTransitionChange(
                    "content",
                    updateTranslationValue(
                      localFormData.transition?.content || {},
                      lang,
                      e.target.value
                    )
                  )
                }
                rows={3}
                className={`border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400 ${
                  validationErrors.transitionContent ? "border-red-500" : ""
                }`}
                placeholder="Enter content"
              />
              {validationErrors.transitionContent && (
                <p className="mt-1 text-sm text-red-600">
                  {validationErrors.transitionContent}
                </p>
              )}
            </div>
          </>
        )}

        {contentType === RoleplayContentType.EXERCISE && (
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

            <KeypointSelector
              value={localFormData.exercise.keypointId || ""}
              onChange={(value) => handleExerciseChange("keypointId", value)}
              label="Keypoint"
            />

            <div className="border rounded-lg p-4 bg-gray-50">
              <div className="flex justify-between items-center mb-3">
                <h3 className="font-medium text-gray-800">Content Documents</h3>
              </div>

              {showDocumentItems &&
                (localFormData.exercise.document || []).map(
                  (doc: IDocument, index: number) => (
                    <div
                      key={doc.id}
                      className="border rounded-lg p-4 bg-white mb-3"
                    >
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
                            <option value={DocumentType.ANIMATION}>
                              Animation
                            </option>
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
                Explanation
              </label>
              <textarea
                rows={3}
                value={getCurrentTranslationValue(
                  localFormData.exercise.explanation,
                  lang
                )}
                onChange={(e) =>
                  handleExerciseChange(
                    "explanation",
                    updateTranslationValue(
                      localFormData.exercise.explanation || {},
                      lang,
                      e.target.value
                    )
                  )
                }
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400 whitespace-pre-wrap"
                placeholder="Enter explanation"
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
                          onPaste={(e) => handlePasteExerciseOptions(idx, e)}
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
                <textarea
                  rows={3}
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
                  className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400 whitespace-pre-wrap"
                  placeholder="Enter target area"
                />
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
                          onPaste={(e) => handlePasteExerciseAnswers(idx, e)}
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

            {localFormData.exercise.type === ExerciseType.DRAG_DROP && (
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
                  {localFormData.exercise.options.map(
                    (opt: any, idx: number) => (
                      <div key={opt.id} className="flex items-center">
                        <input
                          type="text"
                          value={getCurrentTranslationValue(opt.text, lang)}
                          onChange={(e) =>
                            updateOptionValue(idx, e.target.value)
                          }
                          onPaste={(e) => handlePasteExerciseOptions(idx, e)}
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
    <div className={outerClass}>
      <div className={innerClass}>
        {/* Card: left image / right form */}
        {showShell && (
          <div className={cardClass}>
            {/* LEFT: image + image input */}
            {!hideMeta && (
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
                          roleplay: {
                            ...(prev.roleplay || createEmptyRoleplayData()),
                            image: url,
                          },
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
            )}

            {/* RIGHT: form */}
            <div className="flex-1 p-6">
              {!hideMeta && (
                <div className="flex justify-between items-center mb-6">
                  <h1 className="text-2xl md:text-3xl font-bold text-gray-800">
                    {isEditMode ? "✏️ Edit Roleplay" : "🌱 Create New Roleplay"}
                  </h1>
                </div>
              )}

              <div className="space-y-6">
                {!hideMeta && (
                  <>
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
                          lockTitle
                            ? undefined
                            : setCurrentRoleplay((prev) => ({
                                ...prev,
                                title: updateTranslationValue(
                                  prev.title,
                                  lang,
                                  e.target.value
                                ),
                              }))
                        }
                        readOnly={lockTitle}
                        className={`border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition ${
                          lockTitle ? "bg-gray-100 text-gray-600" : ""
                        }`}
                        placeholder={
                          lockTitle
                            ? "Title is synced from lesson"
                            : "Roleplay title..."
                        }
                        required
                      />
                      {lockTitle && (
                        <p className="text-xs text-gray-500 mt-1">
                          Title is locked and synced from the lesson.
                        </p>
                      )}
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
                  </>
                )}
              </div>

              {!hideActions && (
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
                    onClick={() => handleSaveRoleplay()}
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
              )}
            </div>
          </div>
        )}

        <div className={showShell ? "mt-8" : ""}>{renderContents()}</div>

        {/* If in edit mode, show Delete button */}
        {!hideActions && currentRoleplay._id && (
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
                      handleSelectContentType(RoleplayContentType.CONVERSATION)
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
                      handleSelectContentType(RoleplayContentType.LEADING_TEXT)
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
                      handleSelectContentType(RoleplayContentType.TRANSITION)
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
                    <span className="font-medium">Transition</span>
                  </button>
                  <button
                    onClick={() =>
                      handleSelectContentType(RoleplayContentType.EXERCISE)
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
          {modalOpen && (
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
                    {modalOpen.content ? (
                      <>
                        Edit Content
                        {modalOpen.content.id != null ? (
                          <>
                            {" "}
                            <span className="text-black font-semibold">
                              {modalOpen.content.id}
                            </span>
                          </>
                        ) : null}
                      </>
                    ) : (
                      "New Content"
                    )}
                  </h2>

                  <button
                    onClick={() => setModalOpen(null)}
                    className="text-gray-500 hover:text-gray-700 p-1 rounded-full transition-colors"
                  >
                    <XMarkIcon className="h-6 w-6" />
                  </button>
                </div>

                <div className="flex-grow overflow-y-auto p-6 relative">
                  <ContentForm
                    content={modalOpen.content}
                    onSave={handleSaveContentAndRoleplay}
                    onCancel={() => setModalOpen(null)}
                    contentType={modalOpen.contentType}
                    formData={modalOpen.formData}
                  />
                </div>
              </motion.div>
            </div>
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
