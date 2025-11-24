import React, { useEffect, useState } from "react";
import { ILesson, LessonPayload } from "../../types/interface/lesson.interface";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { keypointService } from "../../services/keypointService";
import { lessonService } from "../../services/lessonService";
import { DndContext, closestCenter } from "@dnd-kit/core";
import {
  arrayMove,
  SortableContext,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import SortableItem from "../../components/common/SortableItem";
import { TrashIcon } from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { LessonStatus, LessonType } from "../../types/enum/lesson.enum";
import { Combobox } from "@headlessui/react";
import { ICourse } from "../../types/interface/cource.interface";
import { courseService } from "../../services/courseService";
import LessonConfirm from "../../components/lessons/LessonConfirm";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { PlusIcon } from "lucide-react";
import { PuzzlePieceIcon, XMarkIcon } from "@heroicons/react/24/solid";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";
import { ITag } from "../../types/interface/tag.interface";
import { tagService } from "../../services/tagService";
import {
  getTranslationValue,
  updateTranslationValue,
  cleanTranslation,
} from "../../utils/translation";

interface LessonFormProps {
  lesson?: ILesson; // Nếu có -> edit mode, không có -> create mode
  onSave?: (lesson: ILesson) => void;
}

export default function LessonForm({ lesson, onSave }: LessonFormProps) {
  const lang = useSelector((state: RootState) => state.lang.code);
  const isEditMode = !!lesson;
  const navigate = useNavigate();
  const { showSuccess, showError } = useNotification();

  // sync lesson prop -> local state (important when fetch async)
  const [currentLesson, setCurrentLesson] = useState<ILesson>(
    lesson ??
      ({
        _id: "",
        courseId: "",
        type: LessonType.LESSON,
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
    if (lesson) setCurrentLesson(lesson);
  }, [lesson]);

  const [saving, setSaving] = useState(false);
  const [modalOpen, setModalOpen] = useState<{
    section: "keypoints" | null;
  }>({ section: null });
  const [keypointList, setKeypointList] = useState<IKeypoint[]>([]);
  const [searchKeypoint, setSearchKeypoint] = useState("");
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [courseQuery, setCourseQuery] = useState("");
  const [selectedCourse, setSelectedCourse] = useState<ICourse | null>(null);
  const [confirmDeleteKeypont, setConfirmDeleteKeypoint] = useState<{
    section: "keypoints" | null;
    itemId: string | null;
    itemTitle: string;
  } | null>(null);
  const [selectedKeypoints, setSelectedKeypoints] = useState<IKeypoint[]>([]);
  const [confirmDeleteLesson, setConfirmDeleteLesson] = useState(false);

  const [icons, setIcons] = useState<ITag[]>([]);
  const [iconQuery, setIconQuery] = useState("");
  const [isIconSearchActive, setIsIconSearchActive] = useState(false);

  // Hàm mới để xoá icon
  const handleClearIcon = () => {
    setCurrentLesson((prev) => ({
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

  const handleLessonImageChange = (newUrl: string) => {
    setCurrentLesson((prev) => ({
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
    if (currentLesson.courseId) {
      const fetchCourseDetails = async () => {
        try {
          const res = await courseService.getById(currentLesson.courseId);

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
  }, [currentLesson.courseId]);

  // Save entire lesson (create or update)
  const handleSaveLesson = async () => {
    try {
      setSaving(true);

      // Prepare lesson data with all ITranslation fields
      // Update translation values and clean empty ones
      const title = cleanTranslation(
        updateTranslationValue(
          currentLesson.title,
          lang,
          currentLesson.title?.[lang] || ""
        )
      );
      const description = cleanTranslation(
        updateTranslationValue(
          currentLesson.description,
          lang,
          currentLesson.description?.[lang] || ""
        )
      );
      const estimateCompleTime = cleanTranslation(
        updateTranslationValue(
          currentLesson.estimateCompleTime,
          lang,
          currentLesson.estimateCompleTime?.[lang] || ""
        )
      );

      // Prepare LessonPayload with all ITranslation fields
      // keypoints in LessonPayload should be string array (IDs)
      // Extract IDs from IKeypoint objects in currentLesson
      const keypointIds = currentLesson.keypoints?.map((kp) => kp._id) || [];

      const lessonPayload: any = {
        courseId: currentLesson.courseId,
        learningItemId: currentLesson.learningItemId,
        type: LessonType.LESSON,
        title: title || { [lang]: "" }, // Always include title for validation
        ...(description && { description }),
        ...(estimateCompleTime && { estimateCompleTime }),
        icon: (currentLesson.icon as any)?._id || "", // Extract ID string from ITag object for LessonPayload
        image: currentLesson.image,
        keypoints: keypointIds, // Convert IKeypoint[] to string[]
        status: currentLesson.status,
        index: currentLesson.index,
      };

      // Optional fields already handled by conditional spread operator above

      let res;
      if (currentLesson._id) {
        res = await lessonService.update(
          currentLesson._id,
          lessonPayload as Partial<LessonPayload>
        );
      } else {
        res = await lessonService.create(lessonPayload as LessonPayload);
      }
      const savedLesson = res.data?.data ?? res.data;

      await new Promise((resolve) => setTimeout(resolve, 500));
      onSave?.(savedLesson);
      currentLesson._id
        ? showSuccess("Saved lesson successfully")
        : showSuccess("Create lesson successfully");
    } catch (err) {
      console.error("handleSaveLesson", err);
      showError((err as any).response.data.message || "Failed to save lesson");
    } finally {
      setSaving(false);
    }
  };

  // Save only one section (entrances/keypoints/outputs)
  const handleSaveSection = async (
    section: "keypoints",
    customLesson?: ILesson
  ) => {
    const targetLesson = customLesson || currentLesson;
    if (!targetLesson) return;
    try {
      // For keypoints, convert IKeypoint[] to string[] for LessonPayload
      const keypointIds = targetLesson.keypoints?.map((kp) => kp._id) || [];
      const payload: Partial<LessonPayload> = {
        [section]: keypointIds, // Convert IKeypoint[] to string[]
      };
      if (targetLesson._id) {
        await lessonService.update(targetLesson._id, payload);
      }
      await new Promise((resolve) => setTimeout(resolve, 500));
    } catch (err) {
      console.error("handleSaveSection", err);
    }
  };

  // Reorder inside a section
  const handleReorder = (
    section: "keypoints",
    activeId: string,
    overId: string
  ) => {
    setCurrentLesson((prev) => {
      if (!prev) return prev;
      const list = (prev[section] as any[]) || [];
      const oldIndex = list.findIndex(
        (i) => (i as any)._id === activeId || i === activeId
      );
      const newIndex = list.findIndex(
        (i) => (i as any)._id === overId || i === overId
      );
      return { ...prev, [section]: arrayMove(list, oldIndex, newIndex) };
    });
  };

  // fetch keypoints whenever modal opens or search changes
  useEffect(() => {
    if (!modalOpen.section) return;
    let active = true;
    const timer = setTimeout(async () => {
      try {
        const res = await keypointService.getList({
          page: 1,
          take: 100,
          search: searchKeypoint,
        });
        if (active) setKeypointList(res.data.items ?? []);
      } catch (err) {
        console.error("fetchKeypoints", err);
      }
    }, 300);

    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [modalOpen.section, searchKeypoint]);

  // Open modal to choose keypoint (triggered above effect)
  const handleOpenModal = (section: "keypoints") => {
    setSearchKeypoint("");
    setSelectedKeypoints([]);
    setModalOpen({ section });
  };

  const toggleKeypointSelection = (kp: IKeypoint) => {
    setSelectedKeypoints((prev) => {
      const exists = prev.some((item) => item._id === kp._id);
      if (exists) return prev.filter((item) => item._id !== kp._id);
      return [...prev, kp];
    });
  };

  const handleAddSelectedKeypoints = () => {
    if (!modalOpen.section) return;
    const section = modalOpen.section;
    setCurrentLesson((prev) => {
      const existing = (prev[section] as any[]) || [];
      const existingIds = new Set(
        existing.map((item: any) => (item as any)._id || item)
      );
      const additions = selectedKeypoints.filter(
        (kp) => !existingIds.has(kp._id)
      );
      return {
        ...prev,
        [section]: [...existing, ...additions],
      } as ILesson;
    });
    setSelectedKeypoints([]);
    setModalOpen({ section: null });
  };

  // Request delete -> open confirm modal
  const requestDeleteItem = (
    section: "keypoints",
    itemId: string,
    itemTitle = "item"
  ) => {
    setConfirmDeleteKeypoint({ section, itemId, itemTitle });
  };

  const handleSelectIcon = (icon: ITag) => {
    setCurrentLesson((prev) => ({
      ...prev,
      icon: icon as any,
    }));
    setIconQuery("");
  };

  // Confirm delete -> remove from state and save section (if lesson exists)
  const confirmDeleteItem = () => {
    if (!confirmDeleteKeypont) return;
    const { section, itemId } = confirmDeleteKeypont;
    if (!section || !itemId) {
      setConfirmDeleteKeypoint(null);
      return;
    }

    setCurrentLesson((prev) => {
      if (!prev) return prev;
      const newList = (prev[section] as any[]).filter(
        (i) => (i as any)._id !== itemId && i !== itemId
      );
      const updated = { ...prev, [section]: newList };
      // try to save section (will do nothing if _id is empty)
      // call in next tick to ensure state updated visually first
      setTimeout(() => handleSaveSection(section, updated), 0);
      return updated;
    });

    setConfirmDeleteKeypoint(null);
  };

  const handleDeleteLesson = async () => {
    if (!currentLesson._id) return;
    try {
      await lessonService.remove(currentLesson._id);
      setConfirmDeleteLesson(false);
      navigate("/lesson");
    } catch (err) {
      console.error(err);
    } finally {
      setConfirmDeleteLesson(false);
    }
  };

  const renderSection = (label: string, section: "keypoints") => {
    const list = currentLesson[section] || [];
    return (
      <div className="mb-6 bg-gray-50 rounded-xl p-6 shadow-sm">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-4">
          <h2 className="text-xl font-semibold text-gray-800">{label}</h2>
          <div className="flex flex-wrap items-center gap-2">
            <button
              className="px-4 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg flex items-center gap-2"
              onClick={() => handleOpenModal(section)}
            >
              <PlusIcon className="h-5 w-5" />
              Add keypoints
            </button>
          </div>
        </div>

        <p className="text-sm text-gray-500 mb-4">
          👉 Drag to reorder. Click on item to view details.
        </p>

        <DndContext
          collisionDetection={closestCenter}
          onDragEnd={({ active, over }) => {
            if (over && active.id !== over.id)
              handleReorder(section, active.id as string, over.id as string);
          }}
        >
          <SortableContext
            items={list.map((i) => (i as any)._id || i)}
            strategy={verticalListSortingStrategy}
          >
            {list.length > 0 ? (
              list.map((item) => {
                const itemObj = item as any;
                const itemId = itemObj._id || item;
                return (
                  <SortableItem key={itemId} id={itemId}>
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="flex flex-col sm:flex-row items-start sm:items-center gap-4 p-4 bg-white border rounded-lg mb-3 cursor-pointer hover:shadow-md transition-all duration-300"
                    >
                      {/* {itemObj.image && (
                        <img
                          src={itemObj.image}
                          alt={itemObj.title?.[lang]}
                          className="w-full sm:w-32 h-32 object-cover rounded-lg"
                        />
                      )} */}
                      <PuzzlePieceIcon className="h-8 w-8 text-yellow-500" />
                      <div className="flex-1">
                        <div className="font-semibold text-gray-800 text-lg">
                          {itemObj.title?.[lang] || "Untitled"}
                        </div>
                        {itemObj.description?.[lang] && (
                          <div className="text-sm text-gray-600 mt-1">
                            {itemObj.description?.[lang]}
                          </div>
                        )}
                        {/* Hiển thị tag nếu có */}
                        {itemObj.tag &&
                          Array.isArray(itemObj.tag) &&
                          itemObj.tag.length > 0 && (
                            <div className="flex flex-wrap gap-1 mt-2">
                              {itemObj.tag.map((t: any, index: number) => (
                                <span
                                  key={index}
                                  className="inline-block px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full"
                                >
                                  {t}
                                </span>
                              ))}
                            </div>
                          )}
                      </div>
                      <button
                        className="text-red-500 hover:text-red-700 p-2 rounded-full hover:bg-red-50 transition-colors"
                        onClick={(e) => {
                          e.stopPropagation();
                          e.preventDefault();
                          requestDeleteItem(
                            section,
                            itemId,
                            itemObj.title?.[lang] || "item"
                          );
                        }}
                      >
                        <TrashIcon className="w-5 h-5" />
                      </button>
                    </motion.div>
                  </SortableItem>
                );
              })
            ) : (
              <div className="text-center py-8 text-gray-500 bg-white rounded-lg border border-dashed border-gray-300">
                No items added yet. Click "Add" to get started.
              </div>
            )}
          </SortableContext>
        </DndContext>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Card: left image / right form */}
        <div className="bg-white shadow-xl rounded-xl overflow-hidden flex flex-col md:flex-row">
          {/* LEFT: image + image input */}
          <div className="flex-1 flex flex-col items-start p-6 bg-gray-50">
            <div className="w-full">
              {currentLesson.image ? (
                <img
                  src={currentLesson.image}
                  alt={getTranslationValue(currentLesson.title, lang)}
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
              <label className="block mb-2 text-sm font-medium text-gray-700"></label>
              <CloudflareFileUpload
                initialUrl={currentLesson.image || ""}
                onUrlChange={handleLessonImageChange}
                label="Upload Image"
                // Bạn có thể tùy chỉnh payload này theo nhu cầu
                uploadPayload={{
                  prefix: "",
                  folder: "lessons",
                }}
              />
            </div>
          </div>

          {/* RIGHT: form */}
          <div className="flex-[1.5] p-6">
            <h1 className="text-2xl md:text-3xl font-bold text-gray-800 mb-6">
              {isEditMode ? "✏️ Edit Lesson" : "🌱 Create New Lesson"}
            </h1>

            <div className="space-y-6">
              {/* Title */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Title *
                </label>
                <input
                  value={currentLesson.title?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentLesson((prev) => ({
                      ...prev,
                      title: updateTranslationValue(
                        prev.title,
                        lang,
                        e.target.value
                      ),
                    }))
                  }
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  placeholder="Lesson title..."
                  required
                />
              </div>

              {/* Description */}
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Description
                </label>
                <textarea
                  value={currentLesson.description?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentLesson((prev) => ({
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
                  value={currentLesson.estimateCompleTime?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentLesson((prev) => ({
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
                            (currentLesson.icon as any)?.title,
                            lang
                          ) || ""
                    }
                    onChange={(e) => setIconQuery(e.target.value)}
                    onFocus={() => {
                      setIsIconSearchActive(true);
                      // Khi focus, điền sẵn tên icon hiện tại vào ô tìm kiếm
                      setIconQuery(
                        getTranslationValue(
                          (currentLesson.icon as any)?.title,
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
                  {currentLesson.icon && !isIconSearchActive && (
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
                    value={currentLesson.status}
                    onChange={(e) =>
                      setCurrentLesson((prev) =>
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
                    value={currentLesson.courseId || null}
                    onChange={(val: string | null) => {
                      setCurrentLesson((prev) =>
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

              {/* Save button */}
              <div className="pt-4 flex justify-end">
                <button
                  onClick={handleSaveLesson}
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
                    "Save Lesson"
                  ) : (
                    "Create Lesson"
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Sections below */}
        <div className="mt-8">{renderSection("Keypoints", "keypoints")}</div>

        {/* nếu đang edit thì hiển thị nút Delete */}
        {currentLesson._id && (
          <div className="flex justify-center mt-8">
            <button
              onClick={() => setConfirmDeleteLesson(true)}
              className="px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg shadow hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2"
            >
              <TrashIcon className="h-5 w-5" />
              Delete Lesson
            </button>
          </div>
        )}

        {/* Modal xác nhận xoá */}
        <AnimatePresence>
          {confirmDeleteLesson && (
            <LessonConfirm
              title="Confirm Delete"
              message="Are you sure you want to delete this lesson? This action cannot be undone."
              onCancel={() => setConfirmDeleteLesson(false)}
              onConfirm={handleDeleteLesson}
            />
          )}
        </AnimatePresence>

        {/* Modal chọn keypoint */}
        <AnimatePresence>
          {modalOpen.section && (
            <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[9999]">
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="bg-white w-[600px] rounded-xl shadow-xl p-6 max-w-full max-h-[90vh] overflow-hidden flex flex-col"
              >
                <h2 className="text-xl font-bold mb-4">
                  Select Keypoint for {modalOpen.section}
                </h2>

                <div className="relative mb-4">
                  <input
                    value={searchKeypoint}
                    onChange={(e) => setSearchKeypoint(e.target.value)}
                    placeholder="Search keypoint..."
                    className="border rounded-lg w-full p-3 pl-10 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  />
                </div>

                <div className="flex-grow overflow-y-auto max-h-[60vh]">
                  {keypointList.length > 0 ? (
                    keypointList
                      .filter((kp) =>
                        kp.title?.[lang]
                          ?.toLowerCase()
                          .includes(searchKeypoint.toLowerCase())
                      )
                      .map((kp) => {
                        const selected = selectedKeypoints.some(
                          (item) => item._id === kp._id
                        );
                        return (
                          <motion.div
                            key={kp._id}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            className={`flex items-center gap-4 p-4 cursor-pointer rounded-lg transition-colors border ${
                              selected
                                ? "bg-blue-50 border-blue-200"
                                : "hover:bg-gray-100 border-transparent"
                            }`}
                            onClick={() => toggleKeypointSelection(kp)}
                          >
                            <div
                              className={`h-6 w-6 rounded-full border flex items-center justify-center ${
                                selected
                                  ? "bg-blue-600 border-blue-600 text-white"
                                  : "border-gray-300 text-transparent"
                              }`}
                            >
                              ✓
                            </div>
                            <PuzzlePieceIcon className="h-8 w-8 text-yellow-500" />
                            <div className="flex-1">
                              <div className="font-medium text-gray-800">
                                {kp.title?.[lang]}
                              </div>
                              {kp.description?.[lang] && (
                                <div className="text-sm text-gray-600 mt-1">
                                  {kp.description?.[lang]}
                                </div>
                              )}
                              {/* Hiển thị tag nếu có */}
                              {kp.tag && kp.tag.length > 0 && (
                                <div className="flex flex-wrap gap-1 mt-2">
                                  {kp.tag.map((t, index) => (
                                    <span
                                      key={index}
                                      className="inline-block px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full"
                                    >
                                      {t}
                                    </span>
                                  ))}
                                </div>
                              )}
                            </div>
                          </motion.div>
                        );
                      })
                  ) : (
                    <div className="text-center py-8 text-gray-500">
                      No keypoints found
                    </div>
                  )}
                </div>

                <div className="mt-4 text-right">
                  <button
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed mr-2"
                    disabled={selectedKeypoints.length === 0}
                    onClick={handleAddSelectedKeypoints}
                  >
                    Add selected
                  </button>
                  <button
                    className="px-4 py-2 bg-gray-300 rounded-lg hover:bg-gray-400 transition"
                    onClick={() => {
                      setSelectedKeypoints([]);
                      setModalOpen({ section: null });
                    }}
                  >
                    Cancel
                  </button>
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>

        {/* Modal confirm delete */}
        <AnimatePresence>
          {confirmDeleteKeypont && (
            <LessonConfirm
              title="Confirm Delete"
              message={`Are you sure you want to delete "${confirmDeleteKeypont.itemTitle}"?`}
              onCancel={() => setConfirmDeleteKeypoint(null)}
              onConfirm={() => confirmDeleteItem()}
            />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
