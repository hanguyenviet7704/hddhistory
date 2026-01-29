import React, { useCallback, useEffect, useRef, useState } from "react";
import { TrashIcon, CheckCircleIcon } from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { Combobox } from "@headlessui/react";
import { ICourse } from "../../types/interface/course.interface";
import { courseService } from "../../services/courseService";
import { useNavigate } from "react-router-dom";
import { XMarkIcon } from "@heroicons/react/24/solid";
import { ILesson, LessonPayload } from "../../types/interface/lesson.interface";
import { LessonStatus, LessonType } from "../../types/enum/lesson.enum";
import { lessonService } from "../../services/lessonService";
import LessonConfirm from "../../components/lessons/LessonConfirm";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";
import { tagService } from "../../services/tagService";
import { ITag } from "../../types/interface/tag.interface";
import { learningItemService } from "../../services/learningItemService";
import { ILearningItem } from "../../types/interface/learning-item/learning-item.interface";
import { keypointService } from "../../services/keypointService";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { AnimatePresence } from "framer-motion";
import { LearningItemType } from "../../types/enum/learningItem.enum";
import {
  getTranslationValue,
  updateTranslationValue,
  cleanTranslation,
} from "../../utils/translation";
import RoleplayFromDetail from "./RoleplayFromDetail";

interface RoleplayFormProps {
  roleplayLesson?: ILesson;
  onSave?: (roleplayLesson: ILesson) => void;
}

export default function RoleplayForm({
  roleplayLesson,
  onSave,
}: RoleplayFormProps) {
  const lang = useSelector((state: RootState) => state.lang.code);
  const isEditMode = !!roleplayLesson;
  const navigate = useNavigate();
  const { showSuccess, showError } = useNotification();

  const createEmptyRoleplay = (): ILearningItem =>
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
      roleplay: {
        image: "",
        contents: [],
        missions: [],
        colorTemplateId: "",
      },
      index: 0,
    } as ILearningItem);

  // sync roleplay lesson prop -> local state (important when fetch async)
  const [currentRoleplayLesson, setCurrentRoleplayLesson] = useState<ILesson>(
    roleplayLesson ??
      ({
        _id: "",
        courseId: "",
        learningItemId: "",
        type: LessonType.ROLEPLAY,
        title: { [lang]: "" },
        description: { [lang]: "" },
        image: "",
        keypoints: [],
        estimateCompleTime: { [lang]: "" },
        icon: null,
        lightIcon: null,
        status: LessonStatus.DRAFT,
        index: 0,
      } as ILesson)
  );

  useEffect(() => {
    if (roleplayLesson) {
      setCurrentRoleplayLesson({
        ...roleplayLesson,
        type: LessonType.ROLEPLAY,
      });
    }
  }, [roleplayLesson]);

  const [saving, setSaving] = useState(false);
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [courseQuery, setCourseQuery] = useState("");
  const [selectedCourse, setSelectedCourse] = useState<ICourse | null>(null);
  const [confirmDeleteRoleplay, setConfirmDeleteRoleplay] = useState(false);
  const [icons, setIcons] = useState<ITag[]>([]);
  const [iconQuery, setIconQuery] = useState("");
  const [isIconSearchActive, setIsIconSearchActive] = useState(false);
  const [lightIcons, setLightIcons] = useState<ITag[]>([]);
  const [lightIconQuery, setLightIconQuery] = useState("");
  const [isLightIconSearchActive, setIsLightIconSearchActive] =
    useState(false);
  const [keypointOptions, setKeypointOptions] = useState<IKeypoint[]>([]);
  const [keypointQuery, setKeypointQuery] = useState("");
  const [selectedKeypoint, setSelectedKeypoint] = useState<IKeypoint | null>(
    null
  );
  const [roleplayItem, setRoleplayItem] =
    useState<ILearningItem>(createEmptyRoleplay);
  const roleplaySaveRef = useRef<
    (() => Promise<ILearningItem | undefined>) | null
  >(null);

  const mergeRoleplayState = (
    prev: ILearningItem | null,
    incoming: ILearningItem
  ): ILearningItem => {
    if (!prev) return incoming;
    return {
      ...prev,
      ...incoming,
      roleplay: {
        image:
          incoming.roleplay?.image ||
          prev.roleplay?.image ||
          incoming.image ||
          "",
        colorTemplateId:
          incoming.roleplay?.colorTemplateId ||
          prev.roleplay?.colorTemplateId ||
          "",
        contents:
          (incoming.roleplay?.contents?.length
            ? incoming.roleplay.contents
            : prev.roleplay?.contents) || [],
        missions:
          (incoming.roleplay?.missions?.length
            ? incoming.roleplay.missions
            : prev.roleplay?.missions) || [],
      },
    } as ILearningItem;
  };

  const refreshRoleplay = useCallback(
    async (id: string) => {
      try {
        const res = await learningItemService.getById(id);
        const apiItem: ILearningItem = res.data?.data ?? res.data;
        const merged = mergeRoleplayState(roleplayItem, apiItem);
        setRoleplayItem(merged);
        return merged;
      } catch (err) {
        console.error("refreshRoleplay", err);
        return undefined;
      }
    },
    [roleplayItem]
  );

  // Hàm mới để xoá icon
  const handleClearIcon = () => {
    setCurrentRoleplayLesson((prev) => ({
      ...prev,
      icon: null, // Gán icon về null để xoá
    }));
    // Đảm bảo ô tìm kiếm cũng được làm sạch
    setIconQuery("");
    setIsIconSearchActive(false);
  };

  const handleClearLightIcon = () => {
    setCurrentRoleplayLesson((prev) => ({
      ...prev,
      lightIcon: null,
    }));
    setLightIconQuery("");
    setIsLightIconSearchActive(false);
  };

  const handleAddKeypoint = (kp: IKeypoint | null) => {
    if (!kp) return;
    setCurrentRoleplayLesson((prev) => {
      const existing = prev.keypoints || [];
      if (existing.some((item) => item._id === kp._id)) return prev;
      return { ...prev, keypoints: [...existing, kp] };
    });
    setSelectedKeypoint(null);
    setKeypointQuery("");
  };

  const handleRemoveKeypoint = (id: string) => {
    setCurrentRoleplayLesson((prev) => ({
      ...prev,
      keypoints: (prev.keypoints || []).filter((kp) => kp._id !== id),
    }));
  };

  useEffect(() => {
    let active = true;
    const fetchIcons = async () => {
      try {
        const res = await tagService.getList({
          search: iconQuery,
        });
        const list: ITag[] = res.data.items ?? [];
        if (active) setIcons(list);
      } catch (err) {
        console.error("fetchIcons", err);
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
        const res = await tagService.getList({
          search: lightIconQuery,
        });
        const list: ITag[] = res.data.items ?? [];
        if (active) setLightIcons(list);
      } catch (err) {
        console.error("fetchLightIcons", err);
      }
    };
    fetchLightIcons();
    return () => {
      active = false;
    };
  }, [lightIconQuery]);

  useEffect(() => {
    let active = true;
    const timer = setTimeout(async () => {
      try {
        const res = await keypointService.getList({
          page: 1,
          take: 50,
          search: keypointQuery,
        });
        const list: IKeypoint[] = res.data.items ?? [];
        if (active) setKeypointOptions(list);
      } catch (err) {
        console.error("fetchKeypoints", err);
      }
    }, 250);

    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [keypointQuery]);

  // Fetch selected roleplay details when learningItemId changes
  useEffect(() => {
    if (currentRoleplayLesson.learningItemId) {
      const fetchLearningItemDetails = async () => {
        try {
          const res = await learningItemService.getById(
            currentRoleplayLesson.learningItemId || ""
          );
          if (res.data) {
            const apiItem = res.data as ILearningItem;
            // If API response lacks nested roleplay data, preserve existing state
            setRoleplayItem((prev) => mergeRoleplayState(prev, apiItem));
          }
        } catch (err) {
          console.error("fetchLearningItemDetails", err);
        }
      };
      fetchLearningItemDetails();
    } else {
      setRoleplayItem(createEmptyRoleplay());
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentRoleplayLesson.learningItemId]);

  const handleRoleplayLessonImageChange = (newUrl: string) => {
    setCurrentRoleplayLesson((prev) => ({
      ...prev,
      image: newUrl,
    }));
  };

  // Fetch courses based on query
  useEffect(() => {
    let active = true;
    const fetchCourses = async () => {
      try {
        const res = await courseService.getList({
          page: 1,
          take: 20,
          search: courseQuery,
          isAll: true,
        });
        const list: ICourse[] = res.data.items ?? [];
        if (active) setCourses(list);
      } catch (err) {
        console.error("fetchCourses", err);
      }
    };
    fetchCourses();
    return () => {
      active = false;
    };
  }, [courseQuery]);

  // Fetch selected course details when courseId changes
  useEffect(() => {
    if (currentRoleplayLesson.courseId) {
      const fetchCourseDetails = async () => {
        try {
          const res = await courseService.getById(
            currentRoleplayLesson.courseId
          );
          if (res.data) {
            setSelectedCourse(res.data);
          }
        } catch (err) {
          console.error("fetchCourseDetails", err);
        }
      };
      fetchCourseDetails();
    } else {
      setSelectedCourse(null);
    }
  }, [currentRoleplayLesson.courseId]);

  // Save entire roleplay lesson (create or update)
  const handleSaveRoleplayLesson = async () => {
    try {
      setSaving(true);

      // Try saving the embedded roleplay; fall back to existing roleplay if already saved
      let savedRoleplay: ILearningItem | undefined =
        (await roleplaySaveRef.current?.()) || undefined;

      if (!savedRoleplay?._id) {
        const existingId =
          roleplayItem?._id || currentRoleplayLesson.learningItemId || "";
        if (existingId) {
          savedRoleplay =
            (await refreshRoleplay(existingId)) ||
            (roleplayItem?._id === existingId ? roleplayItem : undefined);
        }
      }

      if (!savedRoleplay?._id) {
        showError("Please complete and save the roleplay content first.");
        setSaving(false);
        return;
      }

      // Prepare LessonPayload with all ITranslation fields
      // Update translation values and clean empty ones
      const title = cleanTranslation(
        updateTranslationValue(
          currentRoleplayLesson.title,
          lang,
          currentRoleplayLesson.title?.[lang] || ""
        )
      );
      const description = cleanTranslation(
        updateTranslationValue(
          currentRoleplayLesson.description,
          lang,
          currentRoleplayLesson.description?.[lang] || ""
        )
      );
      const estimateCompleTime = cleanTranslation(
        updateTranslationValue(
          currentRoleplayLesson.estimateCompleTime,
          lang,
          currentRoleplayLesson.estimateCompleTime?.[lang] || ""
        )
      );

      // keypoints in LessonPayload should be string array (IDs)
      // Since ILesson.keypoints is IKeypoint[], we need to extract IDs
      const keypointIds =
        currentRoleplayLesson.keypoints?.map((kp) => kp._id) || [];

      const ensuredRoleplay =
        (await refreshRoleplay(savedRoleplay._id)) ||
        mergeRoleplayState(roleplayItem, savedRoleplay);

      setRoleplayItem(ensuredRoleplay);

      const lessonPayload: any = {
        courseId: currentRoleplayLesson.courseId,
        learningItemId: ensuredRoleplay._id,
        type: LessonType.ROLEPLAY,
        title: title || { [lang]: "" },
        ...(description && { description }),
        ...(estimateCompleTime && { estimateCompleTime }),
        icon: (currentRoleplayLesson.icon as any)?._id || "", // Extract ID string from ITag object for LessonPayload
        lightIcon: (currentRoleplayLesson.lightIcon as any)?._id || "",
        image: currentRoleplayLesson.image,
        keypoints: keypointIds, // Convert IKeypoint[] to string[]
        status: currentRoleplayLesson.status,
        index: currentRoleplayLesson.index,
      };

      // Optional fields already handled by conditional spread operator above

      let res;
      if (currentRoleplayLesson._id) {
        res = await lessonService.update(
          currentRoleplayLesson._id,
          lessonPayload as Partial<LessonPayload>
        );
      } else {
        res = await lessonService.create(lessonPayload as LessonPayload);
      }
      const savedRoleplayLesson = res.data?.data ?? res.data;

      await new Promise((resolve) => setTimeout(resolve, 500));
      onSave?.(savedRoleplayLesson);
      setCurrentRoleplayLesson((prev) => ({
        ...prev,
        learningItemId: ensuredRoleplay._id,
      }));

      currentRoleplayLesson._id
        ? showSuccess("Saved roleplay lesson successfully")
        : showSuccess("Create roleplay lesson successfully");
    } catch (err) {
      console.error("handleSaveRoleplayLesson", err);
      showError(
        (err as any).response?.data?.message || "Failed to save roleplay lesson"
      );
    } finally {
      setSaving(false);
    }
  };

  const handleSelectIcon = (icon: ITag) => {
    setCurrentRoleplayLesson((prev) => ({
      ...prev,
      icon: icon as any, // Store full ITag object for display
    }));
    setIconQuery("");
  };

  const handleSelectLightIcon = (icon: ITag) => {
    setCurrentRoleplayLesson((prev) => ({
      ...prev,
      lightIcon: icon as any,
    }));
    setLightIconQuery("");
  };

  const getIconValue = (lesson: ILesson) => (lesson.icon as any) || null;

  const handleDeleteRoleplay = async () => {
    if (!currentRoleplayLesson._id) return;
    try {
      await lessonService.remove(currentRoleplayLesson._id);
      setConfirmDeleteRoleplay(false);
      navigate("/roleplay");
    } catch (err) {
      console.error(err);
    } finally {
      setConfirmDeleteRoleplay(false);
    }
  };

  const normalizedKeypointQuery = keypointQuery.toLowerCase();
  const filteredKeypoints = keypointOptions.filter((kp) => {
    const title = getTranslationValue(kp.title, lang)?.toLowerCase() || "";
    return title.includes(normalizedKeypointQuery);
  });

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Main lesson form */}
        <div className="bg-white shadow-xl rounded-xl overflow-visible flex flex-col md:flex-row">
          {/* LEFT: image + upload */}
          <div className="flex-1 flex flex-col items-start p-6 bg-gray-50">
            <div className="w-full">
              {currentRoleplayLesson.image ? (
                <img
                  src={currentRoleplayLesson.image}
                  alt={getTranslationValue(currentRoleplayLesson.title, lang)}
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

            <div className="mt-6 w-52 h-auto max-w-md">
              <CloudflareFileUpload
                initialUrl={currentRoleplayLesson.image || ""}
                onUrlChange={handleRoleplayLessonImageChange}
                label="Upload Image"
                uploadPayload={{
                  prefix: "",
                  folder: "lessons",
                }}
              />
            </div>
          </div>

          {/* RIGHT: form */}
          <div className="flex-[1.5] p-6">
            <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
              <div>
                <h1 className="text-2xl md:text-3xl font-bold text-gray-800">
                  {isEditMode
                    ? "✏️ Edit Roleplay Lesson"
                    : "🌱 Create New Roleplay Lesson"}
                </h1>
                <p className="text-gray-500 text-sm mt-1">
                  Fill in lesson details, then build the roleplay below.
                </p>
              </div>
              <div className="flex gap-2">
                {currentRoleplayLesson._id && (
                  <button
                    onClick={() => setConfirmDeleteRoleplay(true)}
                    className="px-4 py-2 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg shadow hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2"
                  >
                    Delete
                  </button>
                )}
                <button
                  onClick={handleSaveRoleplayLesson}
                  disabled={saving}
                  className={`flex items-center justify-center gap-2 px-6 py-3 rounded-lg text-white font-semibold shadow transition ${
                    saving
                      ? "bg-gray-400 cursor-not-allowed"
                      : "bg-gradient-to-r from-blue-600 to-green-500 hover:opacity-90"
                  }`}
                >
                  {saving ? <>Saving...</> : isEditMode ? "Save" : "Create"}
                </button>
              </div>
            </div>

            <div className="space-y-6 mt-6">
              {/* Title */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Title *
                </label>
                <input
                  value={currentRoleplayLesson.title?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentRoleplayLesson((prev) => ({
                      ...prev,
                      title: updateTranslationValue(
                        prev.title,
                        lang,
                        e.target.value
                      ),
                    }))
                  }
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  placeholder="Roleplay lesson title..."
                  required
                />
              </div>

              {/* Description */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Description
                </label>
                <textarea
                  value={currentRoleplayLesson.description?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentRoleplayLesson((prev) => ({
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

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Time complete
                </label>
                <input
                  value={currentRoleplayLesson.estimateCompleTime?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentRoleplayLesson((prev) => ({
                      ...prev,
                      estimateCompleTime: updateTranslationValue(
                        prev.estimateCompleTime,
                        lang,
                        e.target.value
                      ),
                    }))
                  }
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  placeholder="Lesson estimate complete time..."
                  required
                />
              </div>

              {/* Status + Course row */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block mb-1 text-sm font-medium text-gray-700">
                    Status
                  </label>
                  <select
                    value={currentRoleplayLesson.status}
                    onChange={(e) =>
                      setCurrentRoleplayLesson((prev) =>
                        prev
                          ? { ...prev, status: e.target.value as LessonStatus }
                          : prev
                      )
                    }
                    className="border rounded-lg w-full p-3 bg-white focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  >
                    {Object.values(LessonStatus).map((status) => (
                      <option key={status} value={status}>
                        {status.charAt(0).toUpperCase() + status.slice(1)}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Course: Combobox always shown */}
                <div>
                  <label className="block mb-1 text-sm font-medium text-gray-700">
                    Course *
                  </label>

                  <Combobox<string | null>
                    value={currentRoleplayLesson.courseId || null}
                    onChange={(val: string | null) => {
                      setCurrentRoleplayLesson((prev) =>
                        prev ? { ...prev, courseId: val ?? "" } : prev
                      );
                      setCourseQuery("");
                    }}
                  >
                    <div className="relative">
                      <Combobox.Input
                        displayValue={(val: string | null) => {
                          if (selectedCourse) {
                            return getTranslationValue(
                              selectedCourse.title,
                              lang
                            );
                          }
                          return courseQuery;
                        }}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                          setCourseQuery(e.target.value)
                        }
                        className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                        placeholder="Search course..."
                      />

                      <Combobox.Options className="absolute z-30 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                        {courses
                          .filter((c) =>
                            getTranslationValue(c.title, lang)
                              ?.toLowerCase()
                              .includes(courseQuery.toLowerCase())
                          )
                          .map((c) => (
                            <Combobox.Option
                              key={c._id}
                              value={c._id}
                              className="cursor-pointer px-3 py-3 hover:bg-blue-50"
                            >
                              {getTranslationValue(c.title, lang)}
                            </Combobox.Option>
                          ))}
                      </Combobox.Options>
                    </div>
                  </Combobox>
                </div>
              </div>

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Icon
                </label>

                <div className="relative">
                  <input
                    value={
                      isIconSearchActive
                        ? iconQuery
                        : getTranslationValue(
                            getIconValue(currentRoleplayLesson)?.title,
                            lang
                          ) || ""
                    }
                    onChange={(e) => setIconQuery(e.target.value)}
                    onFocus={() => {
                      setIsIconSearchActive(true);
                      setIconQuery(
                        getTranslationValue(
                          getIconValue(currentRoleplayLesson)?.title,
                          lang
                        ) || ""
                      );
                    }}
                    onBlur={() => {
                      setTimeout(() => {
                        setIsIconSearchActive(false);
                        setIconQuery("");
                      }, 150);
                    }}
                    className="border rounded-lg w-full p-3 pr-10 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                    placeholder="Search icon..."
                  />

                  {getIconValue(currentRoleplayLesson) &&
                    !isIconSearchActive && (
                    <button
                      type="button"
                      onClick={handleClearIcon}
                      className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 focus:outline-none"
                    >
                      <XMarkIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                  )}

                  {isIconSearchActive && (
                    <div className="absolute z-30 mt-1 w-full max-h-60 overflow-auto rounded-lg border bg-white shadow-lg">
                      {icons
                        .filter((icon) =>
                          icon.title?.[lang]
                            ?.toLowerCase()
                            .includes(iconQuery.toLowerCase())
                        )
                        .map((icon) => (
                          <div
                            key={icon._id}
                            className="flex items-center gap-3 p-3 hover:bg-gray-50 cursor-pointer transition-colors"
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
                                className="w-6 h-6 object-cover rounded"
                              />
                            ) : (
                              <div
                                className="w-6 h-6 rounded flex items-center justify-center"
                                style={{
                                  backgroundColor: icon.color || "#f3f4f6",
                                }}
                              >
                                <span>{icon.url}</span>
                              </div>
                            )}
                            <div className="flex-1">
                              <div className="font-medium text-gray-800">
                                {icon.title?.[lang]}
                              </div>
                            </div>
                          </div>
                        ))}
                    </div>
                  )}
                </div>
              </div>

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Light Icon
                </label>

                <div className="relative">
                  <input
                    value={
                      isLightIconSearchActive
                        ? lightIconQuery
                        : getTranslationValue(
                            (currentRoleplayLesson.lightIcon as any)?.title,
                            lang
                          ) || ""
                    }
                    onChange={(e) => setLightIconQuery(e.target.value)}
                    onFocus={() => {
                      setIsLightIconSearchActive(true);
                      setLightIconQuery(
                        getTranslationValue(
                          (currentRoleplayLesson.lightIcon as any)?.title,
                          lang
                        ) || ""
                      );
                    }}
                    onBlur={() => {
                      setTimeout(() => {
                        setIsLightIconSearchActive(false);
                        setLightIconQuery("");
                      }, 150);
                    }}
                    className="border rounded-lg w-full p-3 pr-10 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                    placeholder="Search light icon..."
                  />

                  {currentRoleplayLesson.lightIcon &&
                    !isLightIconSearchActive && (
                      <button
                        type="button"
                        onClick={handleClearLightIcon}
                        className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 focus:outline-none"
                      >
                        <XMarkIcon className="h-5 w-5" aria-hidden="true" />
                      </button>
                    )}

                  {isLightIconSearchActive && lightIconQuery && (
                    <div className="absolute z-30 mt-1 w-full max-h-60 overflow-auto rounded-lg border bg-white shadow-lg">
                      {lightIcons
                        .filter((icon) =>
                          icon.title?.[lang]
                            ?.toLowerCase()
                            .includes(lightIconQuery.toLowerCase())
                        )
                        .map((icon) => (
                          <div
                            key={icon._id}
                            className="flex items-center gap-3 p-3 hover:bg-gray-50 cursor-pointer transition-colors"
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
                                className="w-6 h-6 object-cover rounded"
                              />
                            ) : (
                              <div
                                className="w-6 h-6 rounded flex items-center justify-center"
                                style={{
                                  backgroundColor: icon.color || "#f3f4f6",
                                }}
                              >
                                <span>{icon.url}</span>
                              </div>
                            )}
                            <div className="flex-1">
                              <div className="font-medium text-gray-800">
                                {icon.title?.[lang]}
                              </div>
                            </div>
                          </div>
                        ))}
                    </div>
                  )}
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <label className="block mb-1 text-sm font-medium text-gray-700">
                    Keypoints
                  </label>
                  <span className="text-xs text-gray-400">
                    Select related objectives
                  </span>
                </div>

                <Combobox<IKeypoint | null>
                  value={selectedKeypoint}
                  onChange={(kp) => handleAddKeypoint(kp)}
                >
                  <div className="relative">
                    <Combobox.Input
                      displayValue={(kp) => {
                        const option = kp as IKeypoint | null;
                        return option
                          ? getTranslationValue(option.title, lang)
                          : keypointQuery;
                      }}
                      onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                        setKeypointQuery(e.target.value);
                        setSelectedKeypoint(null);
                      }}
                      className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                      placeholder="Search keypoint..."
                    />

                    <Combobox.Options className="absolute z-30 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                      {filteredKeypoints.length > 0 ? (
                        filteredKeypoints.map((kp) => (
                          <Combobox.Option
                            key={kp._id}
                            value={kp}
                            className="cursor-pointer px-3 py-3 hover:bg-blue-50"
                          >
                            <div className="font-medium text-gray-800">
                              {getTranslationValue(kp.title, lang) ||
                                "Untitled"}
                            </div>
                            {kp.description?.[lang] && (
                              <div className="text-xs text-gray-500">
                                {kp.description?.[lang]}
                              </div>
                            )}
                          </Combobox.Option>
                        ))
                      ) : (
                        <div className="px-3 py-2 text-sm text-gray-500">
                          No keypoints found
                        </div>
                      )}
                    </Combobox.Options>
                  </div>
                </Combobox>

                <div className="mt-3 flex flex-wrap gap-2">
                  {currentRoleplayLesson.keypoints?.length ? (
                    currentRoleplayLesson.keypoints.map((kp) => (
                      <span
                        key={kp._id}
                        className="flex items-center gap-2 bg-blue-50 text-blue-800 px-3 py-1 rounded-full text-sm"
                      >
                        <span className="truncate max-w-[220px]">
                          {getTranslationValue(kp.title, lang) || "Untitled"}
                        </span>
                        <button
                          type="button"
                          onClick={() => handleRemoveKeypoint(kp._id)}
                          className="text-blue-600 hover:text-blue-800"
                          aria-label={`Remove ${getTranslationValue(
                            kp.title,
                            lang
                          )}`}
                        >
                          <XMarkIcon className="h-4 w-4" />
                        </button>
                      </span>
                    ))
                  ) : (
                    <span className="text-sm text-gray-500">
                      No keypoints selected yet.
                    </span>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Roleplay content full width */}
        <div className="bg-white shadow-xl rounded-xl overflow-visible p-6">
          <div className="mt-2 overflow-x-auto">
            {roleplayItem && (
              <RoleplayFromDetail
                key={`embedded-roleplay-${roleplayItem._id || "new"}-${
                  roleplayItem.roleplay?.missions?.length || 0
                }-${roleplayItem.roleplay?.contents?.length || 0}`}
                roleplay={roleplayItem}
                onSave={async (saved) => {
                  const refreshed =
                    saved._id && (await refreshRoleplay(saved._id));
                  const merged = refreshed
                    ? refreshed
                    : mergeRoleplayState(roleplayItem, saved);
                  setRoleplayItem(merged);
                  setCurrentRoleplayLesson((prev) => ({
                    ...prev,
                    learningItemId: merged._id,
                  }));
                }}
                externalTitle={currentRoleplayLesson.title}
                lockTitle
                embedded
                hideActions
                hideMeta
                saveRef={roleplaySaveRef}
              />
            )}
          </div>
        </div>

        {/* Delete confirmation modal */}
        <AnimatePresence>
          {confirmDeleteRoleplay && (
            <LessonConfirm
              title="Confirm Delete"
              message="Are you sure you want to delete this roleplay lesson? This action cannot be undone."
              onCancel={() => setConfirmDeleteRoleplay(false)}
              onConfirm={handleDeleteRoleplay}
            />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
