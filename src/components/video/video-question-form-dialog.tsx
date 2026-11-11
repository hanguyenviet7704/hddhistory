import React, { useEffect, useMemo, useState } from "react";
import { PlusCircleIcon, TrashIcon } from "@heroicons/react/24/outline";
import { XMarkIcon } from "@heroicons/react/24/solid";
import { PlusIcon } from "lucide-react";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import { LangCode } from "../../types/enum/common.enum";
import {
  ExerciseType,
  FormDragDropType,
} from "../../types/enum/learningItem.enum";
import { DocumentType, KeypointLevel } from "../../utils/enum/course.enum";
import { ITranslation } from "../../utils/translate";
import { getCurrentTranslationValue, updateTranslationValue } from "../../utils/translation";
import {
  IAnswer,
  IOptions,
} from "../../types/interface/learning-item/excercises/drag-drop.interface";
import {
  IDocument,
  IDocumentData,
} from "../../types/interface/learning-item/document.interface";
import { IScoringCriteria } from "../../types/interface/learning-item/excercises/record.interface";
import { ExerciseInput } from "../../types/interface/learning-item/learning-item.interface";
import {
  cleanDocumentGroups,
  cleanDocumentItems,
  createDefaultTextDocument,
  createEmptyDocumentData,
  getDocumentContentLabel,
  isTextualDocumentType,
  rebalanceRecordScoringCriteria,
} from "./video-question-editor-utils";

interface VideoQuestionFormDialogProps {
  lang: LangCode;
  questionType: ExerciseType;
  formData: ExerciseInput;
  initialAtSecond?: number;
  onSave: (question: { atSecond: number; exercise: ExerciseInput }) => void | Promise<void>;
  onCancel: () => void;
  saving?: boolean;
}

const QUICK_TIME_OPTIONS = [
  "0:10",
  "0:15",
  "0:30",
  "0:45",
  "1:00",
  "1:30",
  "2:00",
  "3:00",
  "5:00",
];

const formatSecondsForInput = (value: number) => {
  const safeValue = Number.isFinite(value) ? Math.max(0, Math.floor(value)) : 0;
  const hours = Math.floor(safeValue / 3600);
  const minutes = Math.floor((safeValue % 3600) / 60);
  const seconds = safeValue % 60;

  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  }

  return `${minutes}:${String(seconds).padStart(2, "0")}`;
};

const parseAtSecondInput = (value: string) => {
  const normalized = value.trim();
  if (!normalized) return 0;

  if (/^\d+$/.test(normalized)) {
    return Number(normalized);
  }

  const parts = normalized
    .split(":")
    .map((part) => part.trim())
    .filter(Boolean);

  if (!parts.length || parts.some((part) => !/^\d+$/.test(part))) {
    return 0;
  }

  if (parts.length === 2) {
    const [minutes, seconds] = parts.map(Number);
    return minutes * 60 + seconds;
  }

  if (parts.length === 3) {
    const [hours, minutes, seconds] = parts.map(Number);
    return hours * 3600 + minutes * 60 + seconds;
  }

  return 0;
};

export default function VideoQuestionFormDialog({
  lang,
  questionType,
  formData,
  initialAtSecond = 0,
  onSave,
  onCancel,
  saving = false,
}: VideoQuestionFormDialogProps) {
  const [localFormData, setLocalFormData] = useState<any>(formData);
  const [atSecondInput, setAtSecondInput] = useState(
    formatSecondsForInput(initialAtSecond || 0),
  );
  const [nextOptionId, setNextOptionId] = useState(1);
  const [nextAnswerId, setNextAnswerId] = useState(1);

  useEffect(() => {
    const normalized = { ...(formData as any) };
    const maxOptionId = (normalized.options || []).reduce(
      (max: number, option: any) => Math.max(max, option.id || 0),
      0,
    );
    const maxAnswerId = (normalized.answer || []).reduce(
      (max: number, answer: any) => Math.max(max, answer.id || 0),
      0,
    );
    setNextOptionId(maxOptionId + 1);
    setNextAnswerId(maxAnswerId + 1);
    setLocalFormData(normalized);
  }, [formData]);

  useEffect(() => {
    setAtSecondInput(formatSecondsForInput(initialAtSecond || 0));
  }, [initialAtSecond]);

  const documentGroupIds = useMemo(
    () =>
      Array.isArray(localFormData.documentGroups)
        ? localFormData.documentGroups
            .map((group: any) =>
              typeof group?.id === "string" ? group.id.trim() : "",
            )
            .filter(Boolean)
        : [],
    [localFormData.documentGroups],
  );

  const handleChange = (field: string, value: any) => {
    setLocalFormData((prev: any) => ({ ...prev, [field]: value }));
  };

  const handleDocumentChange = (
    index: number,
    field: keyof IDocument,
    value: any,
  ) => {
    setLocalFormData((prev: any) => {
      const nextDocuments = [...(prev.document || [])];
      const updatedDoc = {
        ...nextDocuments[index],
        [field]: value,
      };
      if (field === "type") {
        updatedDoc.data = createEmptyDocumentData(lang);
      }
      nextDocuments[index] = updatedDoc;
      return { ...prev, document: nextDocuments };
    });
  };

  const handleDataChange = (
    docIndex: number,
    field: keyof IDocumentData,
    value: string | ITranslation,
  ) => {
    setLocalFormData((prev: any) => {
      const nextDocuments = [...(prev.document || [])];
      const currentDoc = nextDocuments[docIndex];
      const targetFieldValue = currentDoc?.data?.[field];
      const shouldTranslate =
        (field === "content" || field === "url") && typeof value === "string";

      nextDocuments[docIndex] = {
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
      return { ...prev, document: nextDocuments };
    });
  };

  const renderDocumentFields = (doc: IDocument, index: number) => {
    if (isTextualDocumentType(doc.type)) {
      const label = getDocumentContentLabel(doc.type);
      const isLongForm = doc.type === DocumentType.TEXT;
      const value = getCurrentTranslationValue(doc.data.content, lang);
      if (isLongForm) {
        return (
          <textarea
            value={value}
            onChange={(event) =>
              handleDataChange(index, "content", event.target.value)
            }
            rows={3}
            className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
            placeholder={`Enter ${label.toLowerCase()}`}
          />
        );
      }

      return (
        <input
          type="text"
          value={value}
          onChange={(event) =>
            handleDataChange(index, "content", event.target.value)
          }
          className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
          placeholder={`Enter ${label.toLowerCase()}`}
        />
      );
    }

    const mediaUrl = getCurrentTranslationValue(doc.data.url, lang) || "";
    const uploadProps = {
      initialUrl: mediaUrl,
      onUrlChange: (newUrl: string) => handleDataChange(index, "url", newUrl),
      uploadPayload: { prefix: "", folder: "video-questions" },
    };

    if (doc.type === DocumentType.IMAGE) {
      return <CloudflareFileUpload {...uploadProps} label="Image URL" />;
    }
    if (doc.type === DocumentType.AUDIO) {
      return (
        <CloudflareFileUpload
          {...uploadProps}
          label="Audio URL"
          accept="audio/*"
        />
      );
    }
    if (doc.type === DocumentType.VIDEO) {
      return (
        <CloudflareFileUpload
          {...uploadProps}
          label="Video URL"
          accept="video/*"
        />
      );
    }
    if (doc.type === DocumentType.ANIMATION) {
      return (
        <CloudflareFileUpload
          {...uploadProps}
          label="Animation URL"
          accept="application/json,.json,.lottie"
        />
      );
    }

    return null;
  };

  const addNewDocument = () => {
    const currentMaxId = (localFormData.document || []).reduce(
      (max: number, doc: IDocument) => Math.max(max, doc.id || 0),
      0,
    );
    setLocalFormData((prev: any) => ({
      ...prev,
      document: [
        ...(prev.document || []),
        {
          id: currentMaxId + 1,
          type: DocumentType.TEXT,
          data: createEmptyDocumentData(lang),
        },
      ],
    }));
  };

  const removeDocument = (index: number) => {
    setLocalFormData((prev: any) => ({
      ...prev,
      document: (prev.document || []).filter((_: IDocument, i: number) => i !== index),
    }));
  };

  const addOption = () => {
    if (
      questionType === ExerciseType.SINGLE_CHOICE ||
      questionType === ExerciseType.MULTIPLE_CHOICE
    ) {
      handleChange("options", [
        ...(localFormData.options || []),
        { value: { [lang]: "" }, isCorrect: false },
      ]);
      return;
    }

    if (questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) {
      handleChange("options", [
        ...(localFormData.options || []),
        { value: { [lang]: "" }, documentGroupId: "" },
      ]);
      return;
    }

    if (questionType === ExerciseType.DRAG_DROP) {
      const nextId = nextOptionId;
      setNextOptionId(nextId + 1);
      handleChange("options", [
        ...(localFormData.options || []),
        { id: nextId, text: { [lang]: "" } },
      ]);
    }
  };

  const removeOption = (index: number) => {
    handleChange(
      "options",
      (localFormData.options || []).filter((_: unknown, idx: number) => idx !== index),
    );
  };

  const updateOptionValue = (index: number, value: string) => {
    const nextOptions = [...(localFormData.options || [])];
    if (
      questionType === ExerciseType.DRAG_DROP
    ) {
      nextOptions[index] = {
        ...nextOptions[index],
        text: updateTranslationValue(nextOptions[index]?.text || {}, lang, value),
      };
    } else {
      nextOptions[index] = {
        ...nextOptions[index],
        value: updateTranslationValue(nextOptions[index]?.value || {}, lang, value),
      };
    }
    handleChange("options", nextOptions);
  };

  const updateOptionCorrectness = (index: number, checked: boolean) => {
    const nextOptions = [...(localFormData.options || [])];
    nextOptions[index] = {
      ...nextOptions[index],
      isCorrect: checked,
    };
    handleChange("options", nextOptions);
  };

  const updateOptionDocumentGroupId = (index: number, value: string) => {
    const nextOptions = [...(localFormData.options || [])];
    nextOptions[index] = {
      ...nextOptions[index],
      documentGroupId: value,
    };
    handleChange("options", nextOptions);
  };

  const addAnswer = () => {
    const nextId = nextAnswerId;
    setNextAnswerId(nextId + 1);
    handleChange("answer", [
      ...(localFormData.answer || []),
      { id: nextId, correctAnswer: { [lang]: "" } },
    ]);
  };

  const removeAnswer = (index: number) => {
    const nextAnswers = (localFormData.answer || []).filter(
      (_: unknown, idx: number) => idx !== index,
    );
    handleChange("answer", nextAnswers);
  };

  const updateAnswerValue = (index: number, value: string) => {
    const nextAnswers = [...(localFormData.answer || [])];
    nextAnswers[index] = {
      ...nextAnswers[index],
      correctAnswer: updateTranslationValue(
        nextAnswers[index]?.correctAnswer || {},
        lang,
        value,
      ),
    };
    handleChange("answer", nextAnswers);
  };

  const addDocumentGroup = () => {
    handleChange("documentGroups", [
      ...(localFormData.documentGroups || []),
      {
        id: "",
        documents: [createDefaultTextDocument(lang)],
      },
    ]);
  };

  const removeDocumentGroup = (groupIndex: number) => {
    handleChange(
      "documentGroups",
      (localFormData.documentGroups || []).filter(
        (_: unknown, idx: number) => idx !== groupIndex,
      ),
    );
  };

  const updateDocumentGroupId = (groupIndex: number, value: string) => {
    const nextGroups = [...(localFormData.documentGroups || [])];
    nextGroups[groupIndex] = {
      ...(nextGroups[groupIndex] || { documents: [] }),
      id: value,
    };
    handleChange("documentGroups", nextGroups);
  };

  const handleGroupDocumentChange = (
    groupIndex: number,
    docIndex: number,
    field: keyof IDocument,
    value: any,
  ) => {
    const nextGroups = [...(localFormData.documentGroups || [])];
    const group = nextGroups[groupIndex] || { id: "", documents: [] };
    const nextDocuments = [...(group.documents || [])];
    const updatedDoc = { ...nextDocuments[docIndex], [field]: value };
    if (field === "type") {
      updatedDoc.data = createEmptyDocumentData(lang);
    }
    nextDocuments[docIndex] = updatedDoc;
    nextGroups[groupIndex] = { ...group, documents: nextDocuments };
    handleChange("documentGroups", nextGroups);
  };

  const handleGroupDataChange = (
    groupIndex: number,
    docIndex: number,
    field: keyof IDocumentData,
    value: string | ITranslation,
  ) => {
    const nextGroups = [...(localFormData.documentGroups || [])];
    const group = nextGroups[groupIndex] || { id: "", documents: [] };
    const nextDocuments = [...(group.documents || [])];
    const currentDoc = nextDocuments[docIndex];
    const targetFieldValue = currentDoc?.data?.[field];
    const shouldTranslate =
      (field === "content" || field === "url") && typeof value === "string";

    nextDocuments[docIndex] = {
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
    nextGroups[groupIndex] = { ...group, documents: nextDocuments };
    handleChange("documentGroups", nextGroups);
  };

  const renderGroupDocumentFields = (
    doc: IDocument,
    groupIndex: number,
    docIndex: number,
  ) => {
    if (isTextualDocumentType(doc.type)) {
      const label = getDocumentContentLabel(doc.type);
      const value = getCurrentTranslationValue(doc.data.content, lang);
      if (doc.type === DocumentType.TEXT) {
        return (
          <textarea
            rows={3}
            value={value}
            onChange={(event) =>
              handleGroupDataChange(groupIndex, docIndex, "content", event.target.value)
            }
            className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
            placeholder={`Enter ${label.toLowerCase()}`}
          />
        );
      }

      return (
        <input
          type="text"
          value={value}
          onChange={(event) =>
            handleGroupDataChange(groupIndex, docIndex, "content", event.target.value)
          }
          className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
          placeholder={`Enter ${label.toLowerCase()}`}
        />
      );
    }

    const mediaUrl = getCurrentTranslationValue(doc.data.url, lang) || "";
    return (
      <CloudflareFileUpload
        initialUrl={mediaUrl}
        onUrlChange={(newUrl) =>
          handleGroupDataChange(groupIndex, docIndex, "url", newUrl)
        }
        label={`${doc.type} URL`}
        uploadPayload={{ prefix: "", folder: "video-questions" }}
        accept={
          doc.type === DocumentType.AUDIO
            ? "audio/*"
            : doc.type === DocumentType.VIDEO
              ? "video/*"
              : doc.type === DocumentType.ANIMATION
                ? "application/json,.json,.lottie"
                : "image/*"
        }
      />
    );
  };

  const addDocumentToGroup = (groupIndex: number) => {
    const nextGroups = [...(localFormData.documentGroups || [])];
    const group = nextGroups[groupIndex] || { id: "", documents: [] };
    const currentDocs = group.documents || [];
    const currentMaxId = currentDocs.reduce(
      (max: number, doc: IDocument) => Math.max(max, doc.id || 0),
      0,
    );
    nextGroups[groupIndex] = {
      ...group,
      documents: [
        ...currentDocs,
        {
          id: currentMaxId + 1,
          type: DocumentType.TEXT,
          data: createEmptyDocumentData(lang),
        },
      ],
    };
    handleChange("documentGroups", nextGroups);
  };

  const removeDocumentFromGroup = (groupIndex: number, docIndex: number) => {
    const nextGroups = [...(localFormData.documentGroups || [])];
    const group = nextGroups[groupIndex];
    if (!group) return;
    nextGroups[groupIndex] = {
      ...group,
      documents: (group.documents || []).filter(
        (_: IDocument, idx: number) => idx !== docIndex,
      ),
    };
    handleChange("documentGroups", nextGroups);
  };

  const handleSave = async () => {
    const cleanedDocuments = localFormData.document?.length
      ? cleanDocumentItems(localFormData.document)
      : [];
    const nextPayload: any = {
      ...localFormData,
      document: cleanedDocuments,
    };

    if (questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER) {
      nextPayload.documentGroups = cleanDocumentGroups(
        localFormData.documentGroups || [],
      );
    }

    if (questionType === ExerciseType.RECORD) {
      nextPayload.scoringCriteria = rebalanceRecordScoringCriteria(
        localFormData.scoringCriteria,
        localFormData.maxScore,
      );
    }

    await onSave({
      atSecond: parseAtSecondInput(atSecondInput),
      exercise: nextPayload,
    });
  };

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60">
      <div
        className="flex w-[600px] max-w-[calc(100vw-2rem)] flex-col rounded-xl bg-white shadow-xl"
        style={{ maxHeight: "90vh" }}
      >
        <div className="flex items-center justify-between border-b border-gray-200 p-6 pt-6">
          <div>
            <h2 className="text-xl font-bold text-gray-800">Edit Exercise</h2>
            <p className="text-sm text-gray-500">{questionType}</p>
          </div>
          <button
            type="button"
            className="rounded-full p-1 text-gray-500 transition-colors hover:text-gray-700"
            onClick={onCancel}
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <div className="relative flex-grow overflow-y-auto p-6">
          <div className="space-y-6">
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              At second
            </label>
            <input
              type="text"
              list="video-question-time-options"
              value={atSecondInput}
              onChange={(event) => setAtSecondInput(event.target.value)}
              className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
              placeholder="0:30 or 90"
            />
            <datalist id="video-question-time-options">
              {QUICK_TIME_OPTIONS.map((option) => (
                <option key={option} value={option} />
              ))}
            </datalist>
            <p className="mt-1 text-xs text-gray-500">
              Select a suggestion or type seconds, `mm:ss`, or `hh:mm:ss`.
            </p>
          </div>

          <div className="rounded-lg border bg-gray-50 p-4">
            <div className="mb-3 flex items-center justify-between">
              <h3 className="font-medium text-gray-800">Content Documents</h3>
            </div>

            {(localFormData.document || []).map((doc: IDocument, index: number) => (
              <div key={doc.id || index} className="mb-3 rounded-lg border bg-white p-4">
                <div className="mb-3 flex items-center justify-between">
                  <h4 className="font-medium text-sky-500">Content {index + 1}</h4>
                  <button
                    type="button"
                    className="text-red-500 hover:text-red-700"
                    onClick={() => removeDocument(index)}
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                </div>

                <div className="space-y-3">
                  <select
                    value={doc.type}
                    onChange={(event) =>
                      handleDocumentChange(index, "type", event.target.value as DocumentType)
                    }
                    className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                  >
                    <option value={DocumentType.TITLE}>Title</option>
                    <option value={DocumentType.CAPTION}>Caption</option>
                    <option value={DocumentType.TEXT}>Text</option>
                    <option value={DocumentType.IMAGE}>Image</option>
                    <option value={DocumentType.VIDEO}>Video</option>
                    <option value={DocumentType.AUDIO}>Audio</option>
                    <option value={DocumentType.ANIMATION}>Animation</option>
                  </select>
                  {renderDocumentFields(doc, index)}
                </div>
              </div>
            ))}

            <button
              type="button"
              className="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm hover:bg-gray-50"
              onClick={addNewDocument}
            >
              <PlusIcon className="mr-1 h-4 w-4" />
              Add Content
            </button>
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Explanation
            </label>
            <textarea
              rows={3}
              value={getCurrentTranslationValue(localFormData.explanation, lang)}
              onChange={(event) =>
                handleChange(
                  "explanation",
                  updateTranslationValue(
                    localFormData.explanation || {},
                    lang,
                    event.target.value,
                  ),
                )
              }
              className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
              placeholder="Enter explanation"
            />
          </div>

          {(questionType === ExerciseType.SINGLE_CHOICE ||
            questionType === ExerciseType.MULTIPLE_CHOICE) && (
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                Options
              </label>
              <div className="space-y-3">
                {(localFormData.options || []).map((opt: any, idx: number) => (
                  <div key={`option-${idx}`} className="flex items-center gap-2">
                    <input
                      type="text"
                      value={getCurrentTranslationValue(opt.value, lang)}
                      onChange={(event) =>
                        updateOptionValue(idx, event.target.value)
                      }
                      className="flex-1 rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                      placeholder={`Option ${idx + 1}`}
                    />
                    <label className="flex items-center gap-1 text-sm">
                      <input
                        type="checkbox"
                        checked={!!opt.isCorrect}
                        onChange={(event) =>
                          updateOptionCorrectness(idx, event.target.checked)
                        }
                      />
                      Correct
                    </label>
                    <button
                      type="button"
                      className="text-red-500 hover:text-red-700"
                      onClick={() => removeOption(idx)}
                    >
                      <TrashIcon className="h-4 w-4" />
                    </button>
                  </div>
                ))}
                <button
                  type="button"
                  className="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm hover:bg-gray-50"
                  onClick={addOption}
                >
                  <PlusIcon className="mr-1 h-4 w-4" />
                  Add Option
                </button>
              </div>
            </div>
          )}

          {questionType === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER && (
            <div className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Options
                </label>
                <datalist id="video-question-document-group-ids">
                  {documentGroupIds.map((id: string) => (
                    <option key={id} value={id} />
                  ))}
                </datalist>
                <div className="space-y-3">
                  {(localFormData.options || []).map((opt: any, idx: number) => (
                    <div
                      key={`option-${idx}`}
                      className="grid grid-cols-1 gap-2 md:grid-cols-3"
                    >
                      <input
                        type="text"
                        value={getCurrentTranslationValue(opt.value, lang)}
                        onChange={(event) =>
                          updateOptionValue(idx, event.target.value)
                        }
                        className="rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                        placeholder={`Option ${idx + 1}`}
                      />
                      <input
                        type="text"
                        list="video-question-document-group-ids"
                        value={opt.documentGroupId || ""}
                        onChange={(event) =>
                          updateOptionDocumentGroupId(idx, event.target.value)
                        }
                        className="rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                        placeholder="Document group ID"
                      />
                      <div className="flex justify-end">
                        <button
                          type="button"
                          className="text-red-500 hover:text-red-700"
                          onClick={() => removeOption(idx)}
                        >
                          <TrashIcon className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                  <button
                    type="button"
                    className="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm hover:bg-gray-50"
                    onClick={addOption}
                  >
                    <PlusIcon className="mr-1 h-4 w-4" />
                    Add Option
                  </button>
                </div>
              </div>

              <div className="rounded-lg border bg-gray-50 p-4">
                <div className="mb-3 flex items-center justify-between">
                  <h3 className="font-medium text-gray-800">Document Groups</h3>
                  <button
                    type="button"
                    className="text-brand-600 hover:text-brand-700"
                    onClick={addDocumentGroup}
                  >
                    <PlusCircleIcon className="h-6 w-6" />
                  </button>
                </div>

                {(localFormData.documentGroups || []).map(
                  (group: any, groupIndex: number) => (
                    <div
                      key={`group-${groupIndex}`}
                      className="mb-4 rounded-lg border bg-white p-4"
                    >
                      <div className="mb-3 flex items-center gap-3">
                        <input
                          type="text"
                          value={group.id || ""}
                          onChange={(event) =>
                            updateDocumentGroupId(groupIndex, event.target.value)
                          }
                          className="flex-1 rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                          placeholder="Group ID"
                        />
                        <button
                          type="button"
                          className="text-red-500 hover:text-red-700"
                          onClick={() => removeDocumentGroup(groupIndex)}
                        >
                          <TrashIcon className="h-4 w-4" />
                        </button>
                      </div>

                      {(group.documents || []).map((doc: IDocument, docIndex: number) => (
                        <div
                          key={doc.id || docIndex}
                          className="mb-3 rounded-lg border bg-gray-50 p-4"
                        >
                          <div className="mb-3 flex items-center justify-between">
                            <h4 className="font-medium text-sky-500">
                              Content {docIndex + 1}
                            </h4>
                            <button
                              type="button"
                              className="text-red-500 hover:text-red-700"
                              onClick={() =>
                                removeDocumentFromGroup(groupIndex, docIndex)
                              }
                            >
                              <TrashIcon className="h-4 w-4" />
                            </button>
                          </div>

                          <div className="space-y-3">
                            <select
                              value={doc.type}
                              onChange={(event) =>
                                handleGroupDocumentChange(
                                  groupIndex,
                                  docIndex,
                                  "type",
                                  event.target.value as DocumentType,
                                )
                              }
                              className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                            >
                              <option value={DocumentType.TITLE}>Title</option>
                              <option value={DocumentType.CAPTION}>Caption</option>
                              <option value={DocumentType.TEXT}>Text</option>
                              <option value={DocumentType.IMAGE}>Image</option>
                              <option value={DocumentType.VIDEO}>Video</option>
                              <option value={DocumentType.AUDIO}>Audio</option>
                              <option value={DocumentType.ANIMATION}>Animation</option>
                            </select>
                            {renderGroupDocumentFields(doc, groupIndex, docIndex)}
                          </div>
                        </div>
                      ))}

                      <button
                        type="button"
                        className="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm hover:bg-gray-50"
                        onClick={() => addDocumentToGroup(groupIndex)}
                      >
                        <PlusIcon className="mr-1 h-4 w-4" />
                        Add Content
                      </button>
                    </div>
                  ),
                )}
              </div>
            </div>
          )}

          {questionType === ExerciseType.DRAG_DROP && (
            <>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Form Type
                </label>
                <select
                  value={localFormData.form || FormDragDropType.TextGapFilling}
                  onChange={(event) => handleChange("form", event.target.value)}
                  className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
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

              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Target Area
                </label>
                <textarea
                  rows={3}
                  value={getCurrentTranslationValue(localFormData.targetArea, lang)}
                  onChange={(event) =>
                    handleChange(
                      "targetArea",
                      updateTranslationValue(
                        localFormData.targetArea || {},
                        lang,
                        event.target.value,
                      ),
                    )
                  }
                  className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                  placeholder="Enter target area"
                />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Answers
                </label>
                <div className="space-y-2">
                  {(localFormData.answer || []).map((answer: IAnswer, index: number) => (
                    <div key={answer.id || index} className="flex items-center gap-2">
                      <input
                        type="text"
                        value={getCurrentTranslationValue(answer.correctAnswer, lang)}
                        onChange={(event) =>
                          updateAnswerValue(index, event.target.value)
                        }
                        className="flex-1 rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                        placeholder={`Answer ${index + 1}`}
                      />
                      <button
                        type="button"
                        className="text-red-500 hover:text-red-700"
                        onClick={() => removeAnswer(index)}
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                  <button
                    type="button"
                    className="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm hover:bg-gray-50"
                    onClick={addAnswer}
                  >
                    <PlusIcon className="mr-1 h-4 w-4" />
                    Add Answer
                  </button>
                </div>
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Options
                </label>
                <div className="space-y-2">
                  {(localFormData.options || []).map((option: IOptions, index: number) => (
                    <div key={option.id || index} className="flex items-center gap-2">
                      <input
                        type="text"
                        value={getCurrentTranslationValue(option.text, lang)}
                        onChange={(event) =>
                          updateOptionValue(index, event.target.value)
                        }
                        className="flex-1 rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                        placeholder={`Option ${index + 1}`}
                      />
                      <button
                        type="button"
                        className="text-red-500 hover:text-red-700"
                        onClick={() => removeOption(index)}
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                  <button
                    type="button"
                    className="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm hover:bg-gray-50"
                    onClick={addOption}
                  >
                    <PlusIcon className="mr-1 h-4 w-4" />
                    Add Option
                  </button>
                </div>
              </div>
            </>
          )}

          {questionType === ExerciseType.RECORD && (
            <>
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">
                    Max Duration (seconds)
                  </label>
                  <input
                    type="number"
                    value={localFormData.maxDuration || 0}
                    onChange={(event) =>
                      handleChange("maxDuration", Number(event.target.value))
                    }
                    className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">
                    Max Character
                  </label>
                  <input
                    type="number"
                    value={localFormData.maxCharacter || 0}
                    onChange={(event) =>
                      handleChange("maxCharacter", Number(event.target.value))
                    }
                    className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                  />
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-gray-700">
                    Scoring Criteria
                  </span>
                  <button
                    type="button"
                    className="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm hover:bg-gray-50"
                    onClick={() =>
                      handleChange("scoringCriteria", [
                        ...(localFormData.scoringCriteria || []),
                        { criteria: { [lang]: "" }, maxScore: undefined },
                      ])
                    }
                  >
                    <PlusIcon className="mr-1 h-4 w-4" />
                    Add Criteria
                  </button>
                </div>

                {(localFormData.scoringCriteria || []).map(
                  (criteria: Partial<IScoringCriteria>, index: number) => (
                    <div
                      key={`criteria-${index}`}
                      className="grid grid-cols-1 gap-3 rounded-lg border p-3 md:grid-cols-[1fr_160px_auto]"
                    >
                      <textarea
                        rows={2}
                        value={getCurrentTranslationValue(criteria.criteria, lang)}
                        onChange={(event) => {
                          const next = [...(localFormData.scoringCriteria || [])];
                          next[index] = {
                            ...criteria,
                            criteria: updateTranslationValue(
                              criteria.criteria || {},
                              lang,
                              event.target.value,
                            ),
                          };
                          handleChange("scoringCriteria", next);
                        }}
                        className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                        placeholder="Criterion"
                      />
                      <input
                        type="number"
                        value={criteria.maxScore ?? ""}
                        onChange={(event) => {
                          const next = [...(localFormData.scoringCriteria || [])];
                          next[index] = {
                            ...criteria,
                            maxScore:
                              event.target.value === ""
                                ? undefined
                                : Number(event.target.value),
                          };
                          handleChange("scoringCriteria", next);
                        }}
                        className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                        placeholder="Max score"
                      />
                      <div className="flex justify-end">
                        <button
                          type="button"
                          className="text-red-500 hover:text-red-700"
                          onClick={() => {
                            handleChange(
                              "scoringCriteria",
                              (localFormData.scoringCriteria || []).filter(
                                (_: unknown, idx: number) => idx !== index,
                              ),
                            );
                          }}
                        >
                          <TrashIcon className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  ),
                )}
              </div>
            </>
          )}

          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Level
            </label>
            <div className="space-y-2">
              {Object.values(KeypointLevel).map((level) => (
                <label key={level} className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={(localFormData.level || []).includes(level)}
                    onChange={(event) => {
                      const nextLevel = event.target.checked
                        ? [...(localFormData.level || []), level]
                        : (localFormData.level || []).filter(
                            (value: KeypointLevel) => value !== level,
                          );
                      handleChange("level", nextLevel);
                    }}
                  />
                  {level}
                </label>
              ))}
            </div>
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Max Score
            </label>
            <input
              type="number"
              value={localFormData.maxScore || 0}
              onChange={(event) =>
                handleChange("maxScore", Number(event.target.value))
              }
              className="w-full rounded-lg border p-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
            />
          </div>
        </div>

            <div className="sticky bottom-0 mt-6 flex justify-end gap-2 border-t bg-white pt-4">
              <button
                type="button"
                className="rounded-lg bg-gray-200 px-4 py-2 text-gray-700 hover:bg-gray-300"
                onClick={onCancel}
              >
                Cancel
              </button>
              <button
                type="button"
                className="rounded-lg bg-brand-600 px-4 py-2 text-white hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-50"
                onClick={handleSave}
                disabled={saving}
              >
                {saving ? "Saving..." : "Save Exercise"}
              </button>
            </div>
          </div>
        </div>
      </div>
  );
}
