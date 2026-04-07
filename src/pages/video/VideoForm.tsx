import React, { useEffect, useState } from "react";
import { Combobox } from "@headlessui/react";
import { XMarkIcon } from "@heroicons/react/24/solid";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import DOMPurify from "dompurify";
import { AnimatePresence } from "framer-motion";
import { RootState } from "../../store";
import { ICourse } from "../../types/interface/course.interface";
import { ILesson, LessonPayload } from "../../types/interface/lesson.interface";
import { ITag } from "../../types/interface/tag.interface";
import {
  ILearningItem,
  LearningItemPayload,
} from "../../types/interface/learning-item/learning-item.interface";
import { IVideoQuestion } from "../../types/interface/learning-item/videos/video-question.interface";
import { LessonStatus, LessonType } from "../../types/enum/lesson.enum";
import { LangCode } from "../../types/enum/common.enum";
import { LearningItemType } from "../../types/enum/learningItem.enum";
import { courseService } from "../../services/courseService";
import { lessonService } from "../../services/lessonService";
import { learningItemService } from "../../services/learningItemService";
import { tagService } from "../../services/tagService";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  cleanTranslation,
  getTranslationValue,
  updateTranslationValue,
} from "../../utils/translation";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";
import CloudflareAssetPreview from "../../components/files/CloudflareAssetPreview";
import HtmlContentEditor from "../../components/common/html-content-editor";
import VideoQuestionEditor from "../../components/video/video-question-editor";
import { convertExerciseInputToPayload } from "../../components/video/video-question-editor-utils";
import LessonConfirm from "../../components/lessons/LessonConfirm";
import {
  EstimateCompleteTimeUnit,
  buildEstimateCompleteTimeValue,
  getEstimateCompleteTimeUnitLabel,
  parseEstimateCompleteTimeInput,
} from "../../utils/estimate-complete-time";

interface VideoFormProps {
  videoLesson?: ILesson;
  onSave?: (videoLesson: ILesson) => void;
}

const sanitizeTranslation = (translation: any) => {
  if (!translation) return undefined;
  const sanitized: Record<string, string> = {};
  Object.entries(translation).forEach(([key, value]) => {
    if (typeof value !== "string") return;
    const cleaned = DOMPurify.sanitize(value, { ADD_ATTR: ["style"] });
    if (cleaned.trim()) sanitized[key] = cleaned;
  });
  return Object.keys(sanitized).length ? sanitized : undefined;
};

const createEmptyVideoLesson = (lang: LangCode): ILesson =>
  ({
    _id: "",
    courseId: "",
    learningItemId: "",
    type: LessonType.VIDEO,
    title: { [lang]: "" },
    description: { [lang]: "" },
    image: "",
    video: {
      url: "",
      thumbnail: "",
      summary: { [lang]: "" },
    },
    keypoints: [],
    estimateCompleTime: { [lang]: "" },
    status: LessonStatus.DRAFT,
    icon: null,
    lightIcon: null,
    AIConfig: "",
    animation: null,
    index: 0,
  } as ILesson);

const createEmptyVideoItem = (lang: LangCode): ILearningItem =>
  ({
    _id: "",
    keypointId: "",
    type: LearningItemType.VIDEO,
    title: { [lang]: "" },
    description: { [lang]: "" },
    image: "",
    tag: [],
    questions: [],
    subQuestions: [],
    videoQuestions: [],
    isSub: false,
    documents: [],
    index: 0,
  } as ILearningItem);

export default function VideoForm({ videoLesson, onSave }: VideoFormProps) {
  const lang = useSelector((state: RootState) => state.lang.code) as LangCode;
  const navigate = useNavigate();
  const { showSuccess, showError } = useNotification();
  const isEditMode = !!videoLesson;

  const [currentVideoLesson, setCurrentVideoLesson] = useState<ILesson>(
    videoLesson
      ? { ...videoLesson, type: LessonType.VIDEO }
      : createEmptyVideoLesson(lang),
  );
  const [currentVideoItem, setCurrentVideoItem] = useState<ILearningItem>(
    createEmptyVideoItem(lang),
  );
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [courseQuery, setCourseQuery] = useState("");
  const [selectedCourse, setSelectedCourse] = useState<ICourse | null>(null);
  const [icons, setIcons] = useState<ITag[]>([]);
  const [iconQuery, setIconQuery] = useState("");
  const [isIconSearchActive, setIsIconSearchActive] = useState(false);
  const [lightIcons, setLightIcons] = useState<ITag[]>([]);
  const [lightIconQuery, setLightIconQuery] = useState("");
  const [isLightIconSearchActive, setIsLightIconSearchActive] =
    useState(false);
  const [saving, setSaving] = useState(false);
  const [confirmDeleteVideo, setConfirmDeleteVideo] = useState(false);
  const [estimateCompleTimeInput, setEstimateCompleTimeInput] = useState("");
  const [estimateCompleTimeUnit, setEstimateCompleTimeUnit] =
    useState<EstimateCompleteTimeUnit>("minute");

  useEffect(() => {
    if (!videoLesson) return;
    setCurrentVideoLesson({ ...videoLesson, type: LessonType.VIDEO });
  }, [videoLesson]);

  useEffect(() => {
    const parsed = parseEstimateCompleteTimeInput(
      currentVideoLesson.estimateCompleTime,
      currentVideoLesson.estimateCompleTimeNumber,
      lang,
    );
    setEstimateCompleTimeInput(parsed.amount);
    setEstimateCompleTimeUnit(parsed.unit);
  }, [
    currentVideoLesson.estimateCompleTime,
    currentVideoLesson.estimateCompleTimeNumber,
    lang,
  ]);

  useEffect(() => {
    let active = true;
    const fetchCourses = async () => {
      try {
        const response = await courseService.getList({
          page: 1,
          take: 20,
          search: courseQuery,
          isAll: true,
        });
        if (active) setCourses(response.data.items ?? []);
      } catch (error) {
        console.error("fetchCourses", error);
      }
    };
    fetchCourses();
    return () => {
      active = false;
    };
  }, [courseQuery]);

  useEffect(() => {
    let active = true;
    const fetchIcons = async () => {
      try {
        const response = await tagService.getList({
          search: iconQuery,
        });
        if (active) setIcons(response.data.items ?? []);
      } catch (error) {
        console.error("fetchIcons", error);
      }
    };
    fetchIcons();
    return () => {
      active = false;
    };
  }, [iconQuery]);

  useEffect(() => {
    let active = true;
    const fetchLightIcons = async () => {
      try {
        const response = await tagService.getList({
          search: lightIconQuery,
        });
        if (active) setLightIcons(response.data.items ?? []);
      } catch (error) {
        console.error("fetchLightIcons", error);
      }
    };
    fetchLightIcons();
    return () => {
      active = false;
    };
  }, [lightIconQuery]);

  useEffect(() => {
    if (!currentVideoLesson.courseId) {
      setSelectedCourse(null);
      return;
    }

    const fetchCourseDetail = async () => {
      try {
        const response = await courseService.getById(currentVideoLesson.courseId);
        setSelectedCourse(response.data ?? null);
      } catch (error) {
        console.error("fetchCourseDetail", error);
      }
    };

    fetchCourseDetail();
  }, [currentVideoLesson.courseId]);

  useEffect(() => {
    const learningItemId = currentVideoLesson.learningItemId;
    if (!learningItemId) {
      setCurrentVideoItem((prev) => ({
        ...createEmptyVideoItem(lang),
        _id: prev._id || "",
        videoQuestions: prev.videoQuestions || [],
      }));
      return;
    }

    let active = true;
    const fetchVideoItem = async () => {
      try {
        const response = await learningItemService.getById(learningItemId);
        const data: ILearningItem = response.data?.data ?? response.data;
        if (!active) return;
        setCurrentVideoItem({
          ...createEmptyVideoItem(lang),
          ...data,
          type: LearningItemType.VIDEO,
          videoQuestions: data.videoQuestions || [],
        });
      } catch (error) {
        console.error("fetchVideoItem", error);
      }
    };

    fetchVideoItem();
    return () => {
      active = false;
    };
  }, [currentVideoLesson.learningItemId, lang]);

  const syncVideoQuestions = (videoQuestions: IVideoQuestion[]) => {
    setCurrentVideoItem((prev) => ({
      ...prev,
      videoQuestions,
    }));
  };

  const handleClearIcon = () => {
    setCurrentVideoLesson((prev) => ({
      ...prev,
      icon: null,
    }));
    setIconQuery("");
    setIsIconSearchActive(false);
  };

  const handleClearLightIcon = () => {
    setCurrentVideoLesson((prev) => ({
      ...prev,
      lightIcon: null,
    }));
    setLightIconQuery("");
    setIsLightIconSearchActive(false);
  };

  const handleSelectIcon = (icon: ITag) => {
    setCurrentVideoLesson((prev) => ({
      ...prev,
      icon: icon as any,
    }));
  };

  const handleSelectLightIcon = (icon: ITag) => {
    setCurrentVideoLesson((prev) => ({
      ...prev,
      lightIcon: icon as any,
    }));
  };

  const buildVideoLessonPayload = () => {
    const title = cleanTranslation(
      updateTranslationValue(
        currentVideoLesson.title,
        lang,
        currentVideoLesson.title?.[lang] || "",
      ),
    );
    const description = cleanTranslation(
      updateTranslationValue(
        currentVideoLesson.description,
        lang,
        currentVideoLesson.description?.[lang] || "",
      ),
    );
    const summary = sanitizeTranslation(
      updateTranslationValue(
        currentVideoLesson.video?.summary || {},
        lang,
        getTranslationValue(currentVideoLesson.video?.summary, lang) || "",
      ),
    );
    const {
      label: estimateCompleTimeLabel,
      estimateCompleTimeNumber,
    } = buildEstimateCompleteTimeValue(
      estimateCompleTimeInput,
      estimateCompleTimeUnit,
      lang,
    );
    const estimateCompleTime = cleanTranslation(
      updateTranslationValue(
        currentVideoLesson.estimateCompleTime,
        lang,
        estimateCompleTimeLabel,
      ),
    );
    const videoUrl = currentVideoLesson.video?.url?.trim() || "";
    const videoThumbnail = currentVideoLesson.video?.thumbnail?.trim() || "";
    const shouldIncludeVideo =
      !!(videoUrl || videoThumbnail || summary);

    const lessonPayload: LessonPayload = {
      courseId: currentVideoLesson.courseId,
      learningItemId: currentVideoLesson.learningItemId || "",
      type: LessonType.VIDEO,
      title: title || { [lang]: "" },
      description: description || { [lang]: "" },
      image: currentVideoLesson.image || "",
      ...(shouldIncludeVideo && {
        video: {
          url: videoUrl,
          ...(videoThumbnail && { thumbnail: videoThumbnail }),
          ...(summary && { summary: summary as any }),
        },
      }),
      status: currentVideoLesson.status,
      keypoints: [],
      ...(estimateCompleTime && { estimateCompleTime }),
      ...(Number.isFinite(estimateCompleTimeNumber) && {
        estimateCompleTimeNumber,
      }),
      icon: (currentVideoLesson.icon as any)?._id || "",
      lightIcon: (currentVideoLesson.lightIcon as any)?._id || "",
      AIConfig: currentVideoLesson.AIConfig || "",
      animation: (currentVideoLesson.animation as any)?._id || "",
      index: currentVideoLesson.index || 0,
    };

    return {
      lessonPayload,
      title: title || { [lang]: "" },
      description,
    };
  };

  const buildVideoItemPayload = (
    title: ILesson["title"],
    description?: ILesson["description"],
    videoQuestions: IVideoQuestion[] = currentVideoItem.videoQuestions || [],
  ): LearningItemPayload => {
    const normalizedVideoQuestions = videoQuestions.map((question) => ({
      atSecond: Number.isFinite(question.atSecond) ? question.atSecond : 0,
      exercise: convertExerciseInputToPayload(question.exercise),
    }));

    const videoItemPayload: LearningItemPayload = {
      keypointId: currentVideoItem.keypointId || "",
      title,
      image: currentVideoLesson.image || "",
      tag: currentVideoItem.tag || [],
      type: LearningItemType.VIDEO,
      videoQuestions: normalizedVideoQuestions,
      isSub: false,
      index: currentVideoLesson.index || 0,
    };

    if (description && Object.keys(description).length > 0) {
      videoItemPayload.description = description;
    }

    return videoItemPayload;
  };

  const persistVideoData = async (
    nextVideoQuestions: IVideoQuestion[] = currentVideoItem.videoQuestions || [],
    options?: { showToast?: boolean; successMessage?: string },
  ) => {
    try {
      setSaving(true);
      const { lessonPayload, title, description } = buildVideoLessonPayload();

      let lessonResponse;
      if (currentVideoLesson._id) {
        lessonResponse = await lessonService.update(
          currentVideoLesson._id,
          lessonPayload,
        );
      } else {
        lessonResponse = await lessonService.create(lessonPayload);
      }

      let savedLesson: ILesson = lessonResponse.data?.data ?? lessonResponse.data;
      const savedLessonId =
        currentVideoLesson._id ||
        savedLesson?._id ||
        (lessonResponse.data as any)?._id ||
        (lessonResponse.data?.data as any)?._id ||
        "";
      let savedVideoItem: ILearningItem | null = null;

      const shouldSyncLearningItem =
        !!(
          currentVideoLesson.learningItemId ||
          currentVideoItem._id ||
          nextVideoQuestions.length
        );

      if (shouldSyncLearningItem) {
        const videoItemPayload = buildVideoItemPayload(
          title,
          description,
          nextVideoQuestions,
        );
        const targetLearningItemId =
          currentVideoItem._id || savedLesson.learningItemId || currentVideoLesson.learningItemId || "";

        if (targetLearningItemId) {
          const response = await learningItemService.update(
            targetLearningItemId,
            videoItemPayload,
          );
          savedVideoItem = response.data?.data ?? response.data;
        } else {
          const response = await learningItemService.create(videoItemPayload);
          savedVideoItem = response.data?.data ?? response.data;
        }

        if (
          savedVideoItem?._id &&
          savedVideoItem._id !== savedLesson.learningItemId
        ) {
          if (savedLessonId) {
            await lessonService.update(savedLessonId, {
              ...lessonPayload,
              learningItemId: savedVideoItem._id,
            });

            try {
              const refreshedLessonResponse = await lessonService.getById(
                savedLessonId,
              );
              const refreshedLesson =
                refreshedLessonResponse.data?.data ?? refreshedLessonResponse.data;
              savedLesson =
                refreshedLesson?._id
                  ? refreshedLesson
                  : {
                      ...savedLesson,
                      _id: savedLessonId,
                      learningItemId: savedVideoItem._id,
                    };
            } catch (error) {
              console.error("refreshLinkedVideoLesson", error);
              savedLesson = {
                ...savedLesson,
                _id: savedLessonId,
                learningItemId: savedVideoItem._id,
              };
            }
          } else {
            savedLesson = {
              ...savedLesson,
              learningItemId: savedVideoItem._id,
            };
          }
        } else if (savedVideoItem?._id) {
          savedLesson = {
            ...savedLesson,
            learningItemId: savedVideoItem._id,
          };
        }
      }

      setCurrentVideoLesson((prev) => ({
        ...prev,
        ...savedLesson,
        type: LessonType.VIDEO,
      }));

      if (savedVideoItem) {
        setCurrentVideoItem((prev) => ({
          ...prev,
          ...savedVideoItem,
          type: LearningItemType.VIDEO,
        }));
      } else {
        setCurrentVideoItem((prev) => ({
          ...prev,
          videoQuestions: nextVideoQuestions,
        }));
      }

      if (options?.showToast !== false) {
        onSave?.(savedLesson);
        showSuccess(
          options?.successMessage ||
            (currentVideoLesson._id
              ? "Saved video successfully"
              : "Create video successfully"),
        );
      }
      return savedLesson;
    } catch (error: any) {
      console.error("persistVideoData", error);
      showError(error?.response?.data?.message || "Failed to save video");
      return undefined;
    } finally {
      setSaving(false);
    }
  };

  const handleSaveVideo = async () => {
    await persistVideoData(currentVideoItem.videoQuestions || [], {
      showToast: true,
    });
  };

  const handlePersistVideoQuestions = async (
    videoQuestions: IVideoQuestion[],
    options?: { showToast?: boolean; successMessage?: string },
  ) => {
    setCurrentVideoItem((prev) => ({
      ...prev,
      videoQuestions,
    }));
    await persistVideoData(videoQuestions, options || { showToast: false });
  };

  const handleDeleteVideo = async () => {
    if (!currentVideoLesson._id) return;
    try {
      setSaving(true);
      await lessonService.remove(currentVideoLesson._id);
      if (currentVideoLesson.learningItemId) {
        try {
          await learningItemService.remove(currentVideoLesson.learningItemId);
        } catch (error) {
          console.error("removeLinkedVideoItem", error);
        }
      }
      setConfirmDeleteVideo(false);
      navigate("/video");
    } catch (error) {
      console.error("handleDeleteVideo", error);
      showError("Failed to delete video");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="mx-auto max-w-7xl space-y-6">
        <div className="overflow-hidden rounded-xl bg-white shadow-xl">
          <div className="flex flex-col md:flex-row">
            <div className="flex-1 bg-gray-50 p-6">
              <div className="space-y-3">
                {currentVideoLesson.video?.url ? (
                  <div className="overflow-hidden rounded-xl border border-gray-200 bg-black">
                    <CloudflareAssetPreview
                      src={currentVideoLesson.video.url}
                      className="h-64 w-full object-cover"
                    />
                  </div>
                ) : null}

                <div className="w-52 h-auto max-w-md">
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Video file
                  </label>
                  <CloudflareFileUpload
                    initialUrl={currentVideoLesson.video?.url || ""}
                    onUrlChange={(videoUrl) =>
                      setCurrentVideoLesson((prev) => ({
                        ...prev,
                        video: {
                          ...prev.video,
                          url: videoUrl,
                        },
                      }))
                    }
                    label="Upload Video"
                    uploadPayload={{ prefix: "", folder: "videos" }}
                    accept="video/*"
                  />
                </div>

                <div className="w-52 h-auto max-w-md">
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Thumbnail
                  </label>
                  <CloudflareFileUpload
                    initialUrl={currentVideoLesson.video?.thumbnail || ""}
                    onUrlChange={(thumbnail) =>
                      setCurrentVideoLesson((prev) => ({
                        ...prev,
                        video: {
                          url: prev.video?.url || "",
                          thumbnail,
                          summary: prev.video?.summary,
                        },
                      }))
                    }
                    label="Upload Thumbnail"
                    uploadPayload={{ prefix: "", folder: "videos" }}
                    accept="image/*"
                  />
                </div>
              </div>
            </div>

            <div className="flex-[1.4] p-6">
              <div className="mb-6 flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                <div>
                  <h1 className="text-2xl font-bold text-gray-800 md:text-3xl">
                    {isEditMode ? "Edit Video" : "Create New Video"}
                  </h1>
                  <p className="mt-1 text-sm text-gray-500">
                    Manage video lesson details, video summary, and in-video exercises.
                  </p>
                </div>
                <div className="flex gap-2">
                  {currentVideoLesson._id ? (
                    <button
                      type="button"
                      onClick={() => setConfirmDeleteVideo(true)}
                      className="rounded-lg bg-gradient-to-r from-red-600 to-red-700 px-4 py-2 text-white shadow hover:from-red-700 hover:to-red-800"
                    >
                      Delete
                    </button>
                  ) : null}
                  <button
                    type="button"
                    onClick={handleSaveVideo}
                    disabled={saving}
                    className={`rounded-lg px-6 py-3 font-semibold text-white shadow transition ${
                      saving
                        ? "cursor-not-allowed bg-gray-400"
                        : "bg-gradient-to-r from-blue-600 to-green-500 hover:opacity-90"
                    }`}
                  >
                    {saving
                      ? "Saving..."
                      : isEditMode
                        ? "Save Video"
                        : "Create Video"}
                  </button>
                </div>
              </div>

              <div className="space-y-6">
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">
                    Title *
                  </label>
                  <input
                    value={currentVideoLesson.title?.[lang] || ""}
                    onChange={(event) =>
                      setCurrentVideoLesson((prev) => ({
                        ...prev,
                        title: updateTranslationValue(
                          prev.title,
                          lang,
                          event.target.value,
                        ),
                      }))
                    }
                    className="w-full rounded-lg border p-3 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    placeholder="Video title..."
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">
                    Description
                  </label>
                  <textarea
                    rows={4}
                    value={currentVideoLesson.description?.[lang] || ""}
                    onChange={(event) =>
                      setCurrentVideoLesson((prev) => ({
                        ...prev,
                        description: updateTranslationValue(
                          prev.description,
                          lang,
                          event.target.value,
                        ),
                      }))
                    }
                    className="w-full rounded-lg border p-3 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    placeholder="Short description..."
                  />
                </div>

                <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                  <div>
                    <label className="mb-1 block text-sm font-medium text-gray-700">
                      Status
                    </label>
                    <select
                      value={currentVideoLesson.status}
                      onChange={(event) =>
                        setCurrentVideoLesson((prev) => ({
                          ...prev,
                          status: event.target.value as LessonStatus,
                        }))
                      }
                      className="w-full rounded-lg border p-3 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    >
                      {Object.values(LessonStatus).map((status) => (
                        <option key={status} value={status}>
                          {status}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="mb-1 block text-sm font-medium text-gray-700">
                      Index
                    </label>
                    <input
                      type="number"
                      min={0}
                      value={currentVideoLesson.index || 0}
                      onChange={(event) =>
                        setCurrentVideoLesson((prev) => ({
                          ...prev,
                          index: Number(event.target.value),
                        }))
                      }
                      className="w-full rounded-lg border p-3 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    />
                  </div>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">
                    Course *
                  </label>
                  <Combobox<string | null>
                    value={currentVideoLesson.courseId || null}
                    onChange={(value: string | null) => {
                      setCurrentVideoLesson((prev) => ({
                        ...prev,
                        courseId: value ?? "",
                      }));
                      setCourseQuery("");
                    }}
                  >
                    <div className="relative">
                      <Combobox.Input
                        displayValue={() =>
                          selectedCourse
                            ? getTranslationValue(selectedCourse.title, lang)
                            : courseQuery
                        }
                        onChange={(event) => setCourseQuery(event.target.value)}
                        className="w-full rounded-lg border p-3 focus:outline-none focus:ring-2 focus:ring-blue-400"
                        placeholder="Search course..."
                      />
                      <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                        {courses.map((course) => (
                          <Combobox.Option
                            key={course._id}
                            value={course._id}
                            className="cursor-pointer px-3 py-3 hover:bg-blue-50"
                          >
                            {getTranslationValue(course.title, lang)}
                          </Combobox.Option>
                        ))}
                      </Combobox.Options>
                    </div>
                  </Combobox>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">
                    Time complete
                  </label>
                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                    <select
                      value={estimateCompleTimeUnit}
                      onChange={(event) => {
                        const nextUnit = event.target.value as EstimateCompleteTimeUnit;
                        setEstimateCompleTimeUnit(nextUnit);
                        const { label, estimateCompleTimeNumber } =
                          buildEstimateCompleteTimeValue(
                            estimateCompleTimeInput,
                            nextUnit,
                            lang,
                          );
                        setCurrentVideoLesson((prev) => ({
                          ...prev,
                          estimateCompleTime: updateTranslationValue(
                            prev.estimateCompleTime,
                            lang,
                            label,
                          ),
                          estimateCompleTimeNumber,
                        }));
                      }}
                      className="w-full rounded-lg border p-3 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    >
                      <option value="minute">
                        {getEstimateCompleteTimeUnitLabel("minute", lang, 2)}
                      </option>
                      <option value="hour">
                        {getEstimateCompleteTimeUnitLabel("hour", lang, 2)}
                      </option>
                    </select>

                    <input
                      type="number"
                      min={1}
                      step={1}
                      value={estimateCompleTimeInput}
                      onChange={(event) => {
                        const nextAmount = event.target.value;
                        setEstimateCompleTimeInput(nextAmount);
                        const { label, estimateCompleTimeNumber } =
                          buildEstimateCompleteTimeValue(
                            nextAmount,
                            estimateCompleTimeUnit,
                            lang,
                          );
                        setCurrentVideoLesson((prev) => ({
                          ...prev,
                          estimateCompleTime: updateTranslationValue(
                            prev.estimateCompleTime,
                            lang,
                            label,
                          ),
                          estimateCompleTimeNumber,
                        }));
                      }}
                      className="w-full rounded-lg border p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 sm:col-span-2"
                      placeholder="Enter number..."
                    />
                  </div>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">
                    Icon
                  </label>

                  <div className="relative">
                    <input
                      value={
                        isIconSearchActive
                          ? iconQuery
                          : getTranslationValue(
                              (currentVideoLesson.icon as any)?.title,
                              lang,
                            ) || ""
                      }
                      onChange={(event) => setIconQuery(event.target.value)}
                      onFocus={() => {
                        setIsIconSearchActive(true);
                        setIconQuery(
                          getTranslationValue(
                            (currentVideoLesson.icon as any)?.title,
                            lang,
                          ) || "",
                        );
                      }}
                      onBlur={() => {
                        setTimeout(() => {
                          setIsIconSearchActive(false);
                          setIconQuery("");
                        }, 150);
                      }}
                      className="w-full rounded-lg border p-3 pr-10 focus:outline-none focus:ring-2 focus:ring-blue-400"
                      placeholder="Search icon..."
                    />

                    {currentVideoLesson.icon && !isIconSearchActive ? (
                      <button
                        type="button"
                        onClick={handleClearIcon}
                        className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600"
                      >
                        <XMarkIcon className="h-5 w-5" aria-hidden="true" />
                      </button>
                    ) : null}

                    {isIconSearchActive && iconQuery ? (
                      <div className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                        {icons
                          .filter((icon) =>
                            icon.title?.[lang]
                              ?.toLowerCase()
                              .includes(iconQuery.toLowerCase()),
                          )
                          .map((icon) => (
                            <div
                              key={icon._id}
                              className="flex cursor-pointer items-center gap-3 p-3 transition-colors hover:bg-gray-50"
                              onClick={() => {
                                handleSelectIcon(icon);
                                setIsIconSearchActive(false);
                                setIconQuery("");
                              }}
                            >
                              {icon.url ? (
                                <img
                                  src={icon.url}
                                  alt={icon.title?.[lang]}
                                  className="h-6 w-6 rounded object-cover"
                                />
                              ) : (
                                <div
                                  className="flex h-6 w-6 items-center justify-center rounded"
                                  style={{
                                    backgroundColor: icon.color || "#f3f4f6",
                                  }}
                                />
                              )}
                              <div className="flex-1 font-medium text-gray-800">
                                {icon.title?.[lang]}
                              </div>
                            </div>
                          ))}
                      </div>
                    ) : null}
                  </div>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">
                    Light Icon
                  </label>

                  <div className="relative">
                    <input
                      value={
                        isLightIconSearchActive
                          ? lightIconQuery
                          : getTranslationValue(
                              (currentVideoLesson.lightIcon as any)?.title,
                              lang,
                            ) || ""
                      }
                      onChange={(event) => setLightIconQuery(event.target.value)}
                      onFocus={() => {
                        setIsLightIconSearchActive(true);
                        setLightIconQuery(
                          getTranslationValue(
                            (currentVideoLesson.lightIcon as any)?.title,
                            lang,
                          ) || "",
                        );
                      }}
                      onBlur={() => {
                        setTimeout(() => {
                          setIsLightIconSearchActive(false);
                          setLightIconQuery("");
                        }, 150);
                      }}
                      className="w-full rounded-lg border p-3 pr-10 focus:outline-none focus:ring-2 focus:ring-blue-400"
                      placeholder="Search light icon..."
                    />

                    {currentVideoLesson.lightIcon && !isLightIconSearchActive ? (
                      <button
                        type="button"
                        onClick={handleClearLightIcon}
                        className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600"
                      >
                        <XMarkIcon className="h-5 w-5" aria-hidden="true" />
                      </button>
                    ) : null}

                    {isLightIconSearchActive && lightIconQuery ? (
                      <div className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                        {lightIcons
                          .filter((icon) =>
                            icon.title?.[lang]
                              ?.toLowerCase()
                              .includes(lightIconQuery.toLowerCase()),
                          )
                          .map((icon) => (
                            <div
                              key={icon._id}
                              className="flex cursor-pointer items-center gap-3 p-3 transition-colors hover:bg-gray-50"
                              onClick={() => {
                                handleSelectLightIcon(icon);
                                setIsLightIconSearchActive(false);
                                setLightIconQuery("");
                              }}
                            >
                              {icon.url ? (
                                <img
                                  src={icon.url}
                                  alt={icon.title?.[lang]}
                                  className="h-6 w-6 rounded object-cover"
                                />
                              ) : (
                                <div
                                  className="flex h-6 w-6 items-center justify-center rounded"
                                  style={{
                                    backgroundColor: icon.color || "#f3f4f6",
                                  }}
                                />
                              )}
                              <div className="flex-1 font-medium text-gray-800">
                                {icon.title?.[lang]}
                              </div>
                            </div>
                          ))}
                      </div>
                    ) : null}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="rounded-xl bg-white p-6 shadow-xl">
          <div className="mb-4">
            <h2 className="text-xl font-semibold text-gray-800">Summary</h2>
            <p className="text-sm text-gray-500">
              Add the HTML summary content for this video.
            </p>
          </div>

          <HtmlContentEditor
            value={getTranslationValue(currentVideoLesson.video?.summary, lang) || ""}
            onChange={(html) =>
              setCurrentVideoLesson((prev) => ({
                ...prev,
                video: {
                  url: prev.video?.url || "",
                  thumbnail: prev.video?.thumbnail,
                  summary: updateTranslationValue(
                    prev.video?.summary || {},
                    lang,
                    html,
                  ),
                },
              }))
            }
          />
        </div>

        <VideoQuestionEditor
          lang={lang}
          value={currentVideoItem.videoQuestions || []}
          onChange={syncVideoQuestions}
          onPersist={handlePersistVideoQuestions}
          saving={saving}
        />

        <AnimatePresence>
          {confirmDeleteVideo ? (
            <LessonConfirm
              title="Confirm Delete"
              message="Are you sure you want to delete this video lesson? This action cannot be undone."
              onCancel={() => setConfirmDeleteVideo(false)}
              onConfirm={handleDeleteVideo}
            />
          ) : null}
        </AnimatePresence>
      </div>
    </div>
  );
}
