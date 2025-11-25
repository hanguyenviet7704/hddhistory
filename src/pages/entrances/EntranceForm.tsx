import React, { useEffect, useState } from "react";
import { TrashIcon, CheckCircleIcon } from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { Combobox } from "@headlessui/react";
import { ICourse } from "../../types/interface/cource.interface";
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
import { AnimatePresence } from "framer-motion";
import { LearningItemType } from "../../types/enum/learningItem.enum";
import {
  getTranslationValue,
  updateTranslationValue,
  cleanTranslation,
} from "../../utils/translation";

interface EntranceFormProps {
  entrance?: ILesson;
  onSave?: (entrance: ILesson) => void;
}

export default function EntranceForm({ entrance, onSave }: EntranceFormProps) {
  const lang = useSelector((state: RootState) => state.lang.code);
  const isEditMode = !!entrance;
  const navigate = useNavigate();
  const { showSuccess, showError } = useNotification();

  // sync entrance prop -> local state (important when fetch async)
  const [currentEntrance, setCurrentEntrance] = useState<ILesson>(
    entrance ??
      ({
        _id: "",
        courseId: "",
        learningItemId: "",
        type: LessonType.ENTRANCE,
        title: { [lang]: "" },
        description: { [lang]: "" },
        image: "",
        keypoints: [],
        estimateCompleTime: { [lang]: "" },
        icon: null,
        status: LessonStatus.DRAFT,
        index: 0,
      } as ILesson)
  );

  useEffect(() => {
    if (entrance) setCurrentEntrance(entrance);
  }, [entrance]);

  const [saving, setSaving] = useState(false);
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [courseQuery, setCourseQuery] = useState("");
  const [selectedCourse, setSelectedCourse] = useState<ICourse | null>(null);
  const [confirmDeleteEntrance, setConfirmDeleteEntrance] = useState(false);
  const [icons, setIcons] = useState<ITag[]>([]);
  const [iconQuery, setIconQuery] = useState("");
  const [isIconSearchActive, setIsIconSearchActive] = useState(false);

  // New states for learning items
  const [learningItems, setLearningItems] = useState<ILearningItem[]>([]);
  const [learningItemQuery, setLearningItemQuery] = useState("");
  const [selectedLearningItem, setSelectedLearningItem] =
    useState<ILearningItem | null>(null);

  // Hàm mới để xoá icon
  const handleClearIcon = () => {
    setCurrentEntrance((prev) => ({
      ...prev,
      icon: null, // Gán icon về null để xoá
    }));
    // Đảm bảo ô tìm kiếm cũng được làm sạch
    setIconQuery("");
    setIsIconSearchActive(false);
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

  // Fetch learning items based on query
  useEffect(() => {
    let active = true;
    const fetchLearningItems = async () => {
      try {
        const res = await learningItemService.getList({
          page: 1,
          take: 20,
          search: learningItemQuery,
          type: LearningItemType.ROLEPLAY,
        });
        const list: ILearningItem[] = res.data.items ?? [];
        if (active) setLearningItems(list);
      } catch (err) {
        console.error("fetchLearningItems", err);
      }
    };
    fetchLearningItems();
    return () => {
      active = false;
    };
  }, [learningItemQuery]);

  // Fetch selected learning item details when learningItemId changes
  useEffect(() => {
    if (currentEntrance.learningItemId) {
      const fetchLearningItemDetails = async () => {
        try {
          const res = await learningItemService.getById(
            currentEntrance.learningItemId || ""
          );
          if (res.data) {
            setSelectedLearningItem(res.data);
          }
        } catch (err) {
          console.error("fetchLearningItemDetails", err);
        }
      };
      fetchLearningItemDetails();
    } else {
      setSelectedLearningItem(null);
    }
  }, [currentEntrance.learningItemId]);

  const handleEntranceImageChange = (newUrl: string) => {
    setCurrentEntrance((prev) => ({
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
    if (currentEntrance.courseId) {
      const fetchCourseDetails = async () => {
        try {
          const res = await courseService.getById(currentEntrance.courseId);
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
  }, [currentEntrance.courseId]);

  // Save entire entrance (create or update)
  const handleSaveEntrance = async () => {
    try {
      setSaving(true);

      // Prepare LessonPayload with all ITranslation fields
      // Update translation values and clean empty ones
      const title = cleanTranslation(
        updateTranslationValue(
          currentEntrance.title,
          lang,
          currentEntrance.title?.[lang] || ""
        )
      );
      const description = cleanTranslation(
        updateTranslationValue(
          currentEntrance.description,
          lang,
          currentEntrance.description?.[lang] || ""
        )
      );
      const estimateCompleTime = cleanTranslation(
        updateTranslationValue(
          currentEntrance.estimateCompleTime,
          lang,
          currentEntrance.estimateCompleTime?.[lang] || ""
        )
      );

      // keypoints in LessonPayload should be string array (IDs)
      // Since ILesson.keypoints is IKeypoint[], we need to extract IDs
      const keypointIds = currentEntrance.keypoints?.map((kp) => kp._id) || [];

      const lessonPayload: any = {
        courseId: currentEntrance.courseId,
        learningItemId: currentEntrance.learningItemId,
        type: LessonType.ENTRANCE,
        title: title || { [lang]: "" },
        ...(description && { description }),
        ...(estimateCompleTime && { estimateCompleTime }),
        icon: (currentEntrance.icon as any)?._id || "", // Extract ID string from ITag object for LessonPayload
        image: currentEntrance.image,
        keypoints: keypointIds, // Convert IKeypoint[] to string[]
        status: currentEntrance.status,
        index: currentEntrance.index,
      };

      // Optional fields already handled by conditional spread operator above

      let res;
      if (currentEntrance._id) {
        res = await lessonService.update(
          currentEntrance._id,
          lessonPayload as Partial<LessonPayload>
        );
      } else {
        res = await lessonService.create(lessonPayload as LessonPayload);
      }
      const savedEntrance = res.data?.data ?? res.data;

      await new Promise((resolve) => setTimeout(resolve, 500));
      onSave?.(savedEntrance);

      currentEntrance._id
        ? showSuccess("Saved entrance successfully")
        : showSuccess("Create entrance successfully");
    } catch (err) {
      console.error("handleSaveEntrance", err);
      showError(
        (err as any).response?.data?.message || "Failed to save entrance"
      );
    } finally {
      setSaving(false);
    }
  };

  const handleSelectIcon = (icon: ITag) => {
    setCurrentEntrance((prev) => ({
      ...prev,
      icon: icon as any, // Store full ITag object for display
    }));
    setIconQuery("");
  };

  const handleDeleteEntrance = async () => {
    if (!currentEntrance._id) return;
    try {
      await lessonService.remove(currentEntrance._id);
      setConfirmDeleteEntrance(false);
      navigate("/entrance");
    } catch (err) {
      console.error(err);
    } finally {
      setConfirmDeleteEntrance(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Card: left image / right form */}
        <div className="bg-white shadow-xl rounded-xl overflow-hidden flex flex-col md:flex-row">
          {/* LEFT: image + image input */}
          <div className="flex-1 flex flex-col items-start p-6 bg-gray-50 ">
            <div className="w-full">
              {currentEntrance.image ? (
                <img
                  src={currentEntrance.image}
                  alt={getTranslationValue(currentEntrance.title, lang)}
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
                initialUrl={currentEntrance.image || ""}
                onUrlChange={handleEntranceImageChange}
                label="Upload Image"
                uploadPayload={{
                  prefix: "",
                  folder: "lessons",
                }}
              />
            </div>
          </div>

          {/* RIGHT: form */}
          <div className="flex-[1.5] p-6 relative">
            <h1 className="text-2xl md:text-3xl font-bold text-gray-800 mb-6">
              {isEditMode ? "✏️ Edit Entrance" : "🌱 Create New Entrance"}
            </h1>

            <div className="space-y-6">
              {/* Title */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Title *
                </label>
                <input
                  value={currentEntrance.title?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentEntrance((prev) => ({
                      ...prev,
                      title: updateTranslationValue(
                        prev.title,
                        lang,
                        e.target.value
                      ),
                    }))
                  }
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  placeholder="Entrance title..."
                  required
                />
              </div>

              {/* Description */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Description
                </label>
                <textarea
                  value={currentEntrance.description?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentEntrance((prev) => ({
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

              {/* Learning Item - New field */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Learning Item
                </label>
                <Combobox<string | null>
                  value={currentEntrance.learningItemId || null}
                  onChange={(val: string | null) => {
                    setCurrentEntrance((prev) =>
                      prev ? { ...prev, learningItemId: val ?? "" } : prev
                    );
                    setLearningItemQuery("");
                  }}
                >
                  <div className="relative">
                    <Combobox.Input
                      displayValue={(val: string | null) => {
                        // If there's a selected learning item, display its title
                        if (selectedLearningItem) {
                          return selectedLearningItem.title?.[lang] || "";
                        }
                        // Otherwise, display the search query
                        return learningItemQuery;
                      }}
                      onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                        setLearningItemQuery(e.target.value)
                      }
                      className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                      placeholder="Search learning item..."
                    />

                    <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                      {learningItems
                        .filter((item) =>
                          item.title?.[lang]
                            ?.toLowerCase()
                            .includes(learningItemQuery.toLowerCase())
                        )
                        .map((item) => (
                          <Combobox.Option
                            key={item._id}
                            value={item._id} // value is learningItemId (string)
                            className="cursor-pointer px-3 py-3 hover:bg-blue-50"
                          >
                            {item.title?.[lang]}
                          </Combobox.Option>
                        ))}
                    </Combobox.Options>
                  </div>
                </Combobox>
              </div>

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Time complete
                </label>
                <input
                  value={currentEntrance.estimateCompleTime?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentEntrance((prev) => ({
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

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Icon
                </label>

                <div className="relative">
                  <input
                    // Giá trị sẽ là iconQuery khi đang tìm kiếm, ngược lại là tên icon hiện tại
                    value={
                      isIconSearchActive
                        ? iconQuery
                        : getTranslationValue(
                            (currentEntrance.icon as any)?.title,
                            lang
                          ) || ""
                    }
                    onChange={(e) => setIconQuery(e.target.value)}
                    onFocus={() => {
                      setIsIconSearchActive(true);
                      // Khi focus, điền sẵn tên icon hiện tại vào ô tìm kiếm
                      setIconQuery(
                        getTranslationValue(
                          (currentEntrance.icon as any)?.title,
                          lang
                        ) || ""
                      );
                    }}
                    onBlur={() => {
                      // Dùng setTimeout để cho phép click vào nút 'x' hoặc dropdown item
                      setTimeout(() => {
                        setIsIconSearchActive(false);
                        setIconQuery("");
                      }, 150);
                    }}
                    // Thêm padding bên phải để không bị đè lên nút 'x'
                    className="border rounded-lg w-full p-3 pr-10 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                    placeholder="Search icon..."
                  />

                  {/* Nút 'x' để xoá icon - chỉ hiển thị khi có icon và không đang tìm kiếm */}
                  {currentEntrance.icon && !isIconSearchActive && (
                    <button
                      type="button"
                      onClick={handleClearIcon}
                      className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 focus:outline-none"
                    >
                      <XMarkIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                  )}

                  {/* Dropdown hiển thị kết quả tìm kiếm */}
                  {isIconSearchActive && iconQuery && (
                    <div className="absolute z-10 mt-1 w-full max-h-60 overflow-auto rounded-lg border bg-white shadow-lg">
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

              {/* Status + Course row */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block mb-1 text-sm font-medium text-gray-700">
                    Status
                  </label>
                  <select
                    value={currentEntrance.status}
                    onChange={(e) =>
                      setCurrentEntrance((prev) =>
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
                    value={currentEntrance.courseId || null}
                    onChange={(val: string | null) => {
                      setCurrentEntrance((prev) =>
                        prev ? { ...prev, courseId: val ?? "" } : prev
                      );
                      setCourseQuery("");
                    }}
                  >
                    <div className="relative">
                      <Combobox.Input
                        displayValue={(val: string | null) => {
                          // Nếu có selected course, hiển thị title của nó
                          if (selectedCourse) {
                            return getTranslationValue(
                              selectedCourse.title,
                              lang
                            );
                          }
                          // Nếu không, hiển thị courseQuery (đang nhập hoặc courseId)
                          return courseQuery;
                        }}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                          setCourseQuery(e.target.value)
                        }
                        className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                        placeholder="Search course..."
                      />

                      <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                        {courses
                          .filter((c) =>
                            getTranslationValue(c.title, lang)
                              ?.toLowerCase()
                              .includes(courseQuery.toLowerCase())
                          )
                          .map((c) => (
                            <Combobox.Option
                              key={c._id}
                              value={c._id} // value is courseId (string)
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
            </div>

            <div className="flex gap-4 absolute top-5 right-5">
              <div>
                <button
                  onClick={() => setConfirmDeleteEntrance(true)}
                  className="px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg shadow hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2"
                >
                  Delete
                </button>
              </div>

              <div>
                <button
                  onClick={handleSaveEntrance}
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
          </div>

          {/* Modal xác nhận xoá */}
          <AnimatePresence>
            {confirmDeleteEntrance && (
              <LessonConfirm
                title="Confirm Delete"
                message="Are you sure you want to delete this entrance? This action cannot be undone."
                onCancel={() => setConfirmDeleteEntrance(false)}
                onConfirm={handleDeleteEntrance}
              />
            )}
          </AnimatePresence>
        </div>
      </div>
    </div>
  );
}
