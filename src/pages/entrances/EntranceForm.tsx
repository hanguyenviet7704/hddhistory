import React, { useEffect, useState } from "react";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { keypointService } from "../../services/keypointService";
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
import { Combobox } from "@headlessui/react";
import { ICourse } from "../../types/interface/cource.interface";
import { courseService } from "../../services/courseService";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { PlusIcon } from "lucide-react";
import { PuzzlePieceIcon, XMarkIcon } from "@heroicons/react/24/solid";
import { ILesson, LessonPayload } from "../../types/interface/lesson.interface";
import { LessonStatus, LessonType } from "../../types/enum/lesson.enum";
import { lessonService } from "../../services/lessonService";
import LessonConfirm from "../../components/lessons/LessonConfirm";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";

import { tagService } from "../../services/tagService";

import { ITag } from "../../types/interface/tag.interface";

interface EntranceFormProps {
  entrance?: ILesson; // Nếu có -> edit mode, không có -> create mode
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

  const [confirmDeleteEntrance, setConfirmDeleteEntrance] = useState(false);

  const [icons, setIcons] = useState<ITag[]>([]);
  const [iconQuery, setIconQuery] = useState("");
  const [isIconSearchActive, setIsIconSearchActive] = useState(false);

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
      const payload: LessonPayload = {
        title: currentEntrance.title?.[lang] || "",
        estimateCompleTime: currentEntrance.estimateCompleTime?.[lang] || "",
        icon: currentEntrance.icon?._id.toString() || "",
        type: LessonType.ENTRANCE,
        description: currentEntrance.description?.[lang] || "",
        image: currentEntrance.image,
        keypoints: (currentEntrance.keypoints || []).map((k) =>
          k._id.toString()
        ),
        status: currentEntrance.status,
        index: currentEntrance.index,
        courseId: currentEntrance.courseId,
      };
      let res;
      if (currentEntrance._id) {
        res = await lessonService.update(currentEntrance._id, payload);
      } else {
        res = await lessonService.create(payload);
      }
      const savedEntrance = res.data?.data ?? res.data;

      await new Promise((resolve) => setTimeout(resolve, 500));
      onSave?.(savedEntrance);

      currentEntrance._id
        ? showSuccess("Saved entrance successfully")
        : showSuccess("Create entrance successfully");
    } catch (err) {
      console.error("handleSaveEntrance", err);
      showError("Failed to save entrance");
    } finally {
      setSaving(false);
    }
  };

  // Save only one section (entrances/keypoints/outputs)
  const handleSaveSection = async (
    section: "keypoints",
    customEntrance?: ILesson
  ) => {
    const targetEntrance = customEntrance || currentEntrance;
    if (!targetEntrance) return;
    try {
      const payload = {
        [section]: (targetEntrance[section] || []).map((k) => k._id.toString()),
      };
      if (targetEntrance._id) {
        await lessonService.update(targetEntrance._id, payload);
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
    setCurrentEntrance((prev) => {
      if (!prev) return prev;
      const list = prev[section] || [];
      const oldIndex = list.findIndex((i) => i._id === activeId);
      const newIndex = list.findIndex((i) => i._id === overId);
      return { ...prev, [section]: arrayMove(list, oldIndex, newIndex) };
    });
  };

  // Open modal to choose keypoint (fetch list)
  const handleOpenModal = async (section: "keypoints") => {
    try {
      const res = await keypointService.getList({
        page: 1,
        take: 100,
        search: searchKeypoint,
      });
      setKeypointList(res.data.items ?? []);
      setModalOpen({ section });
      setSearchKeypoint("");
    } catch (err) {
      console.error("handleOpenModal", err);
    }
  };

  const handleSelectIcon = (icon: ITag) => {
    setCurrentEntrance((prev) => ({
      ...prev,
      icon: icon,
    }));
    setIconQuery("");
  };

  const handleAddKeypoint = (kp: IKeypoint) => {
    if (!modalOpen.section) return;
    const section = modalOpen.section;

    setCurrentEntrance((prev) => {
      const existing = prev[section] || [];

      // kiểm tra trùng bằng _id (nếu có)
      const isDuplicate = existing.some((item) => item._id === kp._id);

      // nếu có trùng, bỏ qua không thêm
      if (isDuplicate) return prev;

      return {
        ...prev,
        [section]: [...existing, kp],
      };
    });

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

  // Confirm delete -> remove from state and save section (if entrance exists)
  const confirmDeleteItem = () => {
    if (!confirmDeleteKeypont) return;
    const { section, itemId } = confirmDeleteKeypont;
    if (!section || !itemId) {
      setConfirmDeleteKeypoint(null);
      return;
    }

    setCurrentEntrance((prev) => {
      if (!prev) return prev;
      const newList = (prev[section] || []).filter((i) => i._id !== itemId);
      const updated = { ...prev, [section]: newList };
      // try to save section (will do nothing if _id is empty)
      // call in next tick to ensure state updated visually first
      setTimeout(() => handleSaveSection(section, updated), 0);
      return updated;
    });

    setConfirmDeleteKeypoint(null);
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

  const renderSection = (label: string, section: "keypoints") => {
    const list = currentEntrance[section] || [];
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
              Add
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
            items={list.map((i) => i._id)}
            strategy={verticalListSortingStrategy}
          >
            {list.length > 0 ? (
              list.map((item) => (
                <SortableItem key={item._id} id={item._id}>
                  <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="flex flex-col sm:flex-row items-start sm:items-center gap-4 p-4 bg-white border rounded-lg mb-3 cursor-pointer hover:shadow-md transition-all duration-300"
                  >
                    {/* {item.image && (
                      <img
                        src={item.image}
                        alt={item.title?.[lang]}
                        className="w-full sm:w-32 h-32 object-cover rounded-lg"
                      />
                    )} */}
                    <PuzzlePieceIcon className="h-8 w- text-yellow-500" />
                    <div className="flex-1">
                      <div className="font-semibold text-gray-800 text-lg">
                        {item.title?.[lang] || "Untitled"}
                      </div>
                      {item.description?.[lang] && (
                        <div className="text-sm text-gray-600 mt-1">
                          {item.description?.[lang]}
                        </div>
                      )}
                      {/* Hiển thị tag nếu có */}
                      {item.tag && item.tag.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-2">
                          {item.tag.map((t, index) => (
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
                          item._id,
                          item.title?.[lang] || "item"
                        );
                      }}
                    >
                      <TrashIcon className="w-5 h-5" />
                    </button>
                  </motion.div>
                </SortableItem>
              ))
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
              {currentEntrance.image ? (
                <img
                  src={currentEntrance.image}
                  alt={currentEntrance.title?.[lang]}
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
                      title: { ...prev.title, [lang]: e.target.value },
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
                      description: {
                        ...prev.description,
                        [lang]: e.target.value,
                      },
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
                  value={currentEntrance.estimateCompleTime?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentEntrance((prev) => ({
                      ...prev,
                      estimateCompleTime: {
                        ...prev.estimateCompleTime,
                        [lang]: e.target.value,
                      },
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
                        : currentEntrance.icon?.title?.[lang] || ""
                    }
                    onChange={(e) => setIconQuery(e.target.value)}
                    onFocus={() => {
                      setIsIconSearchActive(true);
                      // Khi focus, điền sẵn tên icon hiện tại vào ô tìm kiếm
                      setIconQuery(currentEntrance.icon?.title?.[lang] || "");
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
                            return selectedCourse.title?.[lang] || "";
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
                            c.title?.[lang]
                              ?.toLowerCase()
                              .includes(courseQuery.toLowerCase())
                          )
                          .map((c) => (
                            <Combobox.Option
                              key={c._id}
                              value={c._id} // value is courseId (string)
                              className="cursor-pointer px-3 py-3 hover:bg-blue-50"
                            >
                              {c.title?.[lang]}
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
                  onClick={handleSaveEntrance}
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
                    "Save Entrance"
                  ) : (
                    "Create Entrance"
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Sections below */}
        <div className="mt-8">{renderSection("Keypoints", "keypoints")}</div>

        {/* nếu đang edit thì hiển thị nút Delete */}
        {currentEntrance._id && (
          <div className="flex justify-center mt-8">
            <button
              onClick={() => setConfirmDeleteEntrance(true)}
              className="px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg shadow hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2"
            >
              <TrashIcon className="h-5 w-5" />
              Delete Entrance
            </button>
          </div>
        )}

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
                      .map((kp) => (
                        <motion.div
                          key={kp._id}
                          initial={{ opacity: 0, y: 10 }}
                          animate={{ opacity: 1, y: 0 }}
                          className="flex items-center gap-4 p-4 hover:bg-gray-100 cursor-pointer rounded-lg transition-colors"
                          onClick={() => handleAddKeypoint(kp)}
                        >
                          {/* {kp.image && (
                            <img
                              src={kp.image}
                              className="w-16 h-16 rounded-lg object-cover"
                              alt={kp.title?.[lang]}
                            />
                          )} */}
                          <PuzzlePieceIcon className="h-8 w- text-yellow-500" />
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
                      ))
                  ) : (
                    <div className="text-center py-8 text-gray-500">
                      No keypoints found
                    </div>
                  )}
                </div>

                <div className="mt-4 text-right">
                  <button
                    className="px-4 py-2 bg-gray-300 rounded-lg hover:bg-gray-400 transition"
                    onClick={() => setModalOpen({ section: null })}
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
