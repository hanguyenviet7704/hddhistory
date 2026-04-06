import React, { useMemo, useState } from "react";
import {
  PlusCircleIcon,
  TrashIcon,
  PuzzlePieceIcon,
} from "@heroicons/react/24/outline";
import { motion, AnimatePresence } from "framer-motion";
import { LangCode } from "../../types/enum/common.enum";
import { ExerciseType } from "../../types/enum/learningItem.enum";
import { IVideoQuestion } from "../../types/interface/learning-item/videos/video-question.interface";
import { ExerciseInput } from "../../types/interface/learning-item/learning-item.interface";
import { IDocument } from "../../types/interface/learning-item/document.interface";
import { ITranslation } from "../../utils/translate";
import { DocumentType, KeypointLevel } from "../../utils/enum/course.enum";
import { getTranslationValue } from "../../utils/translation";
import VideoQuestionFormDialog from "./video-question-form-dialog";
import {
  createEmptyExerciseInput,
  isTextualDocumentType,
} from "./video-question-editor-utils";

interface VideoQuestionEditorProps {
  lang: LangCode;
  value: IVideoQuestion[];
  onChange: (questions: IVideoQuestion[]) => void;
  onPersist?: (
    questions: IVideoQuestion[],
    options?: { showToast?: boolean; successMessage?: string },
  ) => Promise<void>;
  saving?: boolean;
}

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
      <span className="inline-block max-w-xl truncate">
        {displayText.length > maxLength
          ? `${displayText.substring(0, maxLength)}...`
          : displayText}
      </span>
      {displayText.length > maxLength && (
        <div className="absolute bottom-full left-0 z-10 mb-2 hidden max-h-40 w-64 overflow-y-auto rounded bg-gray-800 px-3 py-2 text-xs text-white shadow-lg group-hover:block">
          {displayText}
        </div>
      )}
    </div>
  );
};

const getExercisePreview = (exercise?: ExerciseInput, lang?: LangCode) => {
  const question = exercise as any;
  if (!question) return "No exercise data";
  const currentLang = lang || LangCode.EN;

  const textualDocument = (question.document || []).find(
    (doc: any) => doc?.data?.content,
  );
  const textualValue = textualDocument
    ? getTranslationValue(textualDocument.data.content, currentLang)
    : "";

  if (textualValue) return textualValue;
  if (question.explanation) {
    return getTranslationValue(question.explanation, currentLang);
  }
  if (Array.isArray(question.options) && question.options.length > 0) {
    const firstOption = question.options[0];
    return (
      getTranslationValue(firstOption.value, currentLang) ||
      getTranslationValue(firstOption.text, currentLang) ||
      "Has options"
    );
  }
  return "Empty exercise";
};

export default function VideoQuestionEditor({
  lang,
  value,
  onChange,
  onPersist,
  saving = false,
}: VideoQuestionEditorProps) {
  const [showTypePicker, setShowTypePicker] = useState(false);
  const [editingIndex, setEditingIndex] = useState<number | null>(null);
  const [draftType, setDraftType] = useState<ExerciseType | null>(null);

  const currentQuestions = useMemo(() => value || [], [value]);

  const handleOpenCreate = (type: ExerciseType) => {
    setDraftType(type);
    setEditingIndex(null);
    setShowTypePicker(false);
  };

  const handleOpenEdit = (index: number) => {
    const question = currentQuestions[index];
    if (!question?.exercise) return;
    setDraftType((question.exercise as any).type || ExerciseType.SINGLE_CHOICE);
    setEditingIndex(index);
  };

  const handleSaveQuestion = async ({
    atSecond,
    exercise,
  }: {
    atSecond: number;
    exercise: ExerciseInput;
  }) => {
    const nextQuestion: IVideoQuestion = {
      atSecond: Number.isFinite(atSecond) ? atSecond : 0,
      exercise,
    };

    let nextQuestions: IVideoQuestion[];
    if (editingIndex != null) {
      nextQuestions = [...currentQuestions];
      nextQuestions[editingIndex] = {
        ...nextQuestion,
      };
    } else {
      nextQuestions = [...currentQuestions, nextQuestion];
    }

    onChange(nextQuestions);
    await onPersist?.(nextQuestions, {
      showToast: true,
      successMessage: editingIndex != null
        ? "Updated video question successfully"
        : "Added video question successfully",
    });

    setDraftType(null);
    setEditingIndex(null);
  };

  const handleDelete = async (index: number) => {
    const nextQuestions = currentQuestions.filter(
      (_, currentIndex) => currentIndex !== index,
    );
    onChange(nextQuestions);
    await onPersist?.(nextQuestions, {
      showToast: true,
      successMessage: "Deleted video question successfully",
    });
  };

  const activeFormData =
    editingIndex != null
      ? currentQuestions[editingIndex]?.exercise
      : draftType
        ? createEmptyExerciseInput(draftType, 1, lang)
        : null;

  return (
    <div className="space-y-4 rounded-xl bg-gray-50 p-6 shadow-sm">
      <div className="flex flex-col gap-3">
        <div>
          <h2 className="text-xl font-semibold text-gray-800">Video Questions</h2>
          <p className="text-sm text-gray-500">
            Add exercises that appear at specific timestamps in the video.
          </p>
        </div>
        <p className="text-sm text-gray-500">
          Drag to reorder is not enabled yet. Click on item to edit.
        </p>
      </div>

      {currentQuestions.length === 0 ? (
        <div className="rounded-lg border border-dashed border-gray-300 bg-white py-8 text-center text-gray-500">
          No video questions yet.
        </div>
      ) : (
        <div className="space-y-3">
          {currentQuestions.map((question, index) => (
            <motion.div
              key={`video-question-${index}`}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="rounded-lg border border-gray-200 bg-white p-4 transition-shadow hover:shadow-md"
            >
              <div className="flex items-start gap-3">
                <div className="mt-1 flex-shrink-0">
                  <PuzzlePieceIcon className="h-6 w-6 text-yellow-500" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="mb-2 flex items-center justify-between">
                    <h3 className="truncate font-medium text-gray-800">
                      Question {index + 1} ({(question.exercise as any)?.type || "unknown"})
                    </h3>
                    <div className="flex gap-1">
                      <button
                        type="button"
                        className="rounded p-1 text-blue-600 hover:text-blue-800"
                        onClick={() => handleOpenEdit(index)}
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
                        type="button"
                        className="rounded p-1 text-red-500 hover:text-red-700"
                        onClick={() => handleDelete(index)}
                        title="Delete"
                      >
                        <TrashIcon className="h-5 w-5" />
                      </button>
                    </div>
                  </div>

                  <div className="space-y-1 text-sm text-gray-600">
                    <div className="flex items-start">
                      <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                        At second:
                      </span>
                      <span>{question.atSecond ?? 0}</span>
                    </div>

                    {(question.exercise as any)?.document?.length > 0 && (
                      <div className="mt-2 rounded bg-gray-50 p-2">
                        <span className="font-medium text-gray-700">Content:</span>
                        {(question.exercise as any).document.map(
                          (doc: IDocument, docIndex: number) => (
                            <div key={docIndex} className="ml-2 mt-1 text-xs">
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
                              {(doc.type === DocumentType.IMAGE ||
                                doc.type === DocumentType.AUDIO ||
                                doc.type === DocumentType.VIDEO ||
                                doc.type === DocumentType.ANIMATION) &&
                                getTranslationValue(doc.data.url, lang) && (
                                  <div className="ml-1">
                                    <TextWithTooltip
                                      text={doc.data.url}
                                      maxLength={50}
                                      lang={lang}
                                    />
                                  </div>
                                )}
                            </div>
                          ),
                        )}
                      </div>
                    )}

                    {(question.exercise as any)?.explanation && (
                      <div className="flex items-start">
                        <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                          Explanation:
                        </span>
                        <TextWithTooltip
                          text={(question.exercise as any).explanation}
                          lang={lang}
                        />
                      </div>
                    )}

                    {((question.exercise as any)?.type === ExerciseType.SINGLE_CHOICE ||
                      (question.exercise as any)?.type === ExerciseType.MULTIPLE_CHOICE) &&
                      Array.isArray((question.exercise as any).options) && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Options:
                          </span>
                          <ul className="mt-1 space-y-1">
                            {(question.exercise as any).options.map(
                              (opt: any, optIndex: number) => (
                                <li key={optIndex} className="flex items-center">
                                  <span
                                    className={`mr-2 h-3 w-3 rounded-full ${
                                      opt.isCorrect ? "bg-green-500" : "bg-gray-300"
                                    }`}
                                  ></span>
                                  <TextWithTooltip text={opt.value} lang={lang} />
                                </li>
                              ),
                            )}
                          </ul>
                        </div>
                      )}

                    {(question.exercise as any)?.type ===
                      ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER &&
                      Array.isArray((question.exercise as any).options) && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Options:
                          </span>
                          <ul className="mt-1 space-y-1">
                            {(question.exercise as any).options.map(
                              (opt: any, optIndex: number) => (
                                <li
                                  key={optIndex}
                                  className="flex items-center gap-2"
                                >
                                  <TextWithTooltip text={opt.value} lang={lang} />
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

                    {(question.exercise as any)?.type ===
                      ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER &&
                      Array.isArray((question.exercise as any).documentGroups) &&
                      (question.exercise as any).documentGroups.length > 0 && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Document Groups:
                          </span>
                          <div className="mt-1 flex flex-wrap gap-2">
                            {(question.exercise as any).documentGroups.map(
                              (group: any, groupIndex: number) => (
                                <span
                                  key={`${group.id || "group"}-${groupIndex}`}
                                  className="inline-flex items-center rounded-full bg-sky-100 px-2 py-1 text-xs font-medium text-sky-800"
                                >
                                  {group.id || "Untitled"}
                                </span>
                              ),
                            )}
                          </div>
                        </div>
                      )}

                    {(question.exercise as any)?.type === ExerciseType.DRAG_DROP && (
                      <div>
                        <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                          Form Type:
                        </span>
                        <span>{(question.exercise as any).form || "Not specified"}</span>
                      </div>
                    )}

                    {(question.exercise as any)?.type === ExerciseType.DRAG_DROP &&
                      (question.exercise as any)?.targetArea && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Target Area:
                          </span>
                          <TextWithTooltip
                            text={(question.exercise as any).targetArea}
                            lang={lang}
                          />
                        </div>
                      )}

                    {(question.exercise as any)?.type === ExerciseType.DRAG_DROP &&
                      Array.isArray((question.exercise as any).options) &&
                      (question.exercise as any).options.length > 0 && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Options:
                          </span>
                          <ul className="mt-1 space-y-1">
                            {(question.exercise as any).options.map(
                              (opt: any, optIndex: number) => (
                                <li key={optIndex} className="flex items-center">
                                  <TextWithTooltip text={opt.text} lang={lang} />
                                </li>
                              ),
                            )}
                          </ul>
                        </div>
                      )}

                    {(question.exercise as any)?.type === ExerciseType.DRAG_DROP &&
                      Array.isArray((question.exercise as any).answer) &&
                      (question.exercise as any).answer.length > 0 && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Answer:
                          </span>
                          <ul className="mt-1 space-y-1">
                            {(question.exercise as any).answer.map(
                              (ans: any, answerIndex: number) => (
                                <li key={answerIndex} className="flex items-center">
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

                    {(question.exercise as any)?.type === ExerciseType.RECORD &&
                      (question.exercise as any)?.maxDuration != null && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Max Duration:
                          </span>
                          <span>{(question.exercise as any).maxDuration} seconds</span>
                        </div>
                      )}

                    {(question.exercise as any)?.type === ExerciseType.RECORD &&
                      (question.exercise as any)?.maxCharacter != null && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Max Character:
                          </span>
                          <span>
                            {(question.exercise as any).maxCharacter} characters
                          </span>
                        </div>
                      )}

                    {(question.exercise as any)?.type === ExerciseType.RECORD &&
                      Array.isArray((question.exercise as any).scoringCriteria) && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Criteria:
                          </span>
                          <span>
                            {(question.exercise as any).scoringCriteria?.length}
                          </span>
                        </div>
                      )}

                    {Array.isArray((question.exercise as any)?.level) &&
                      (question.exercise as any).level.length > 0 && (
                        <div>
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Level:
                          </span>
                          <div className="mt-1 flex flex-wrap gap-1">
                            {(question.exercise as any).level.map(
                              (level: KeypointLevel, levelIndex: number) => (
                                <span
                                  key={levelIndex}
                                  className="inline-flex items-center rounded-full bg-purple-100 px-2 py-1 text-xs font-medium text-purple-800"
                                >
                                  {level}
                                </span>
                              ),
                            )}
                          </div>
                        </div>
                      )}

                    {!((question.exercise as any)?.document?.length > 0) &&
                      !(question.exercise as any)?.explanation &&
                      getExercisePreview(question.exercise, lang) && (
                        <div className="flex items-start">
                          <span className="mr-2 flex-shrink-0 font-medium text-blue-400">
                            Preview:
                          </span>
                          <TextWithTooltip
                            text={getExercisePreview(question.exercise, lang)}
                            lang={lang}
                          />
                        </div>
                      )}
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      <div className="flex justify-center pt-2">
        <button
          type="button"
          className="text-blue-500 transition-colors hover:text-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
          onClick={() => setShowTypePicker(true)}
          disabled={saving}
        >
          <PlusCircleIcon className="h-8 w-8" />
        </button>
      </div>

      <AnimatePresence>
        {showTypePicker && (
          <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 p-4">
            <motion.div
              initial={{ opacity: 0, y: 100 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 100 }}
              className="w-full max-w-md rounded-t-2xl bg-white p-6 shadow-xl"
            >
              <h3 className="mb-4 text-xl font-bold text-gray-800">
                Select Question Type
              </h3>

              <div className="grid grid-cols-2 gap-4">
                <button
                  type="button"
                  onClick={() => handleOpenCreate(ExerciseType.SINGLE_CHOICE)}
                  className="flex flex-col items-center gap-2 rounded-lg bg-blue-50 p-4 transition hover:bg-blue-100"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
                    <span className="font-bold text-blue-600">A</span>
                  </div>
                  <span className="font-medium">Single Choice</span>
                </button>
                <button
                  type="button"
                  onClick={() =>
                    handleOpenCreate(ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER)
                  }
                  className="flex flex-col items-center gap-2 rounded-lg bg-cyan-50 p-4 transition hover:bg-cyan-100"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-cyan-100">
                    <span className="font-bold text-cyan-600">S</span>
                  </div>
                  <span className="text-center font-medium">
                    Single Choice No Correct Answer
                  </span>
                </button>
                <button
                  type="button"
                  onClick={() => handleOpenCreate(ExerciseType.MULTIPLE_CHOICE)}
                  className="flex flex-col items-center gap-2 rounded-lg bg-purple-50 p-4 transition hover:bg-purple-100"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100">
                    <span className="font-bold text-purple-600">A</span>
                  </div>
                  <span className="font-medium">Multiple Choice</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleOpenCreate(ExerciseType.DRAG_DROP)}
                  className="flex flex-col items-center gap-2 rounded-lg bg-green-50 p-4 transition hover:bg-green-100"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-green-100">
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
                  type="button"
                  onClick={() => handleOpenCreate(ExerciseType.RECORD)}
                  className="flex flex-col items-center gap-2 rounded-lg bg-red-50 p-4 transition hover:bg-red-100"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-red-100">
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

              <div className="mt-6">
                <button
                  type="button"
                  className="w-full rounded-lg bg-gray-200 px-4 py-3 text-sm text-gray-700 hover:bg-gray-300"
                  onClick={() => setShowTypePicker(false)}
                >
                  Cancel
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {draftType && activeFormData ? (
        <VideoQuestionFormDialog
          lang={lang}
          questionType={draftType}
          formData={activeFormData}
          initialAtSecond={
            editingIndex != null ? currentQuestions[editingIndex]?.atSecond ?? 0 : 0
          }
          onSave={handleSaveQuestion}
          onCancel={() => {
            setDraftType(null);
            setEditingIndex(null);
          }}
          saving={saving}
        />
      ) : null}
    </div>
  );
}
