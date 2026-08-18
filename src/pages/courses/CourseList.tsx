// src/pages/courses/CourseList.tsx
import React, { useEffect, useRef, useState, useCallback } from "react";
import {
  PencilIcon,
  TrashIcon,
  PlusIcon,
  SpeakerWaveIcon,
  GlobeAltIcon,
} from "@heroicons/react/24/outline";
import { countryLabel } from "../../config/countries";
import { courseService } from "../../services/courseService";
import VoiceoverStatusModal from "../../components/courses/VoiceoverStatusModal";
import { ICourse, CoursePayload } from "../../types/interface/course.interface";
import { CourseStatus } from "../../types/enum/course.enum";
import CourseModal from "../../components/courses/CourseModal";
import CourseConfirm from "../../components/courses/ConfirmModal";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { getTranslationValue } from "../../utils/translation";
import CloudflareAssetPreview from "../../components/files/CloudflareAssetPreview";
import ExcelImportButton from "../../components/imports/ExcelImportButton";
import { useNotification } from "../../utils/hooks/useNotification";

export default function CourseList() {
  const navigate = useNavigate();
  const { showSuccess, showError } = useNotification();

  const [courses, setCourses] = useState<ICourse[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState("");
  const debounceRef = useRef<number | undefined>(undefined);
  const observer = useRef<IntersectionObserver | null>(null);
  const lang = useSelector((state: RootState) => state.lang.code);
  // The voiceover status/coverage modal (per course) — see which keypoints ×
  // languages are done / stale / missing / failed, and generate from there.
  const [voiceoverCourse, setVoiceoverCourse] = useState<ICourse | null>(null);

  // modal / confirm state
  const [selectedCourse, setSelectedCourse] = useState<ICourse | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [modalLoading, setModalLoading] = useState(false);
  const [modalError, setModalError] = useState<string | null>(null);

  // fetch helper
  const fetchCourses = async (search = "", pageNum = 1, isLoadMore = false) => {
    if (isLoadMore) {
      setLoadingMore(true);
    } else {
      setLoading(true);
    }

    try {
      const res = await courseService.getList({
        search,
        page: pageNum,
        take: 12,
        isAll: true,
      });

      const list: ICourse[] = res.data.items;
      const totalPages =
        res.data.totalPages || Math.ceil(res.data.total / res.data.limit);

      if (isLoadMore) {
        setCourses((prev) => [...prev, ...list]);
      } else {
        setCourses(list);
      }

      setHasMore(pageNum < totalPages);
      setPage(pageNum);
    } catch (err) {
      console.error("Failed to fetch courses:", err);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  // debounce search
  useEffect(() => {
    window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      fetchCourses(searchTerm.trim(), 1, false);
    }, 10);
    return () => window.clearTimeout(debounceRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchTerm]);

  // Observer for infinite scroll
  const lastCourseElementRef = useCallback(
    (node: any) => {
      if (loading || loadingMore) return;
      if (observer.current) observer.current.disconnect();
      observer.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && hasMore) {
          fetchCourses(searchTerm.trim(), page + 1, true);
        }
      });
      if (node) observer.current.observe(node);
    },
    [loading, loadingMore, hasMore, page, searchTerm]
  );

  const openCreate = () => {
    setSelectedCourse(null);
    setModalError(null);
    setIsModalOpen(true);
  };

  const openEdit = (c: ICourse) => {
    setSelectedCourse(c);
    setModalError(null);
    setIsModalOpen(true);
  };

  const openDelete = (c: ICourse) => {
    setSelectedCourse(c);
    setIsConfirmOpen(true);
  };

  const handleModalSubmit = async (
    payload: Partial<CoursePayload>,
    id?: string
  ) => {
    setModalLoading(true);
    setModalError(null);
    try {
      if (id) {
        await courseService.update(id, payload);
        await fetchCourses(searchTerm.trim(), 1, false);
      } else {
        const res = await courseService.create(payload);
        const created = res.data?.data ?? res.data;
        if (created && created._id) {
          setCourses((prev) => [created, ...prev]);
        } else {
          await fetchCourses(searchTerm.trim(), 1, false);
        }
      }
      setIsModalOpen(false);
      setSelectedCourse(null);
    } catch (err: any) {
      console.error("Save failed", err);
      setModalError(err?.response?.data?.message ?? "Save failed");
    } finally {
      setModalLoading(false);
    }
  };

  const handleConfirmDelete = async (id: string) => {
    try {
      await courseService.remove(id);
      setCourses((prev) => prev.filter((c) => c._id !== id));
      setIsConfirmOpen(false);
      setSelectedCourse(null);
    } catch (err) {
      console.error("Delete failed", err);
      throw err;
    }
  };

  const statusColors: Record<CourseStatus, string> = {
    [CourseStatus.PUBLISHED]: "bg-green-100 text-green-700",
    [CourseStatus.DRAFT]: "bg-yellow-100 text-yellow-700",
    [CourseStatus.COMING_SOON]: "bg-blue-100 text-blue-700",
  };

  const statusLabels: Record<CourseStatus, string> = {
    [CourseStatus.PUBLISHED]: "Published",
    [CourseStatus.DRAFT]: "Draft",
    [CourseStatus.COMING_SOON]: "Coming Soon",
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold">📚 Courses</h1>
          </div>

          <div className="flex items-center gap-3">
            <div className="relative">
              <input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search courses..."
                className="w-full md:w-72 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
              />
              <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                  />
                </svg>
              </div>
            </div>
            <button
              type="button"
              onClick={async () => {
                try {
                  const res = await courseService.downloadTemplate();
                  const url = URL.createObjectURL(res.data);
                  const a = document.createElement("a");
                  a.href = url;
                  a.download = "course-import-template.xlsx";
                  a.click();
                  URL.revokeObjectURL(url);
                } catch {
                  showError("Download template failed");
                }
              }}
              className="inline-flex items-center gap-2 border border-slate-400 text-slate-600 hover:bg-slate-50 px-3 py-2 rounded-lg transition text-sm"
            >
              Template
            </button>
            <ExcelImportButton
              label="Import"
              fileName="course-import-result.xlsx"
              importExcel={courseService.importExcel}
              onSuccess={() => {
                showSuccess("Import courses successfully");
                fetchCourses(searchTerm.trim(), 1, false);
              }}
              onError={showError}
            />
            <button
              onClick={openCreate}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>New Course</span>
            </button>
          </div>
        </div>
      </div>

      {/* Course Grid */}
      <div className="max-w-7xl mx-auto">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
          </div>
        ) : courses.length === 0 ? (
          <div className="py-20 text-center">
            <div className="text-gray-400 mb-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-16 w-16 mx-auto"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                />
              </svg>
            </div>
            <h3 className="text-xl font-medium text-gray-900 mb-1">
              No courses found
            </h3>
            <p className="text-gray-500">
              Get started by creating a new course.
            </p>
            <button
              onClick={openCreate}
              className="mt-4 inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>Create Course</span>
            </button>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              <AnimatePresence>
                {courses.map((course, index) => {
                  // Add ref to the last element
                  const isLast = index === courses.length - 1;
                  return (
                    <motion.div
                      key={course._id}
                      ref={isLast ? lastCourseElementRef : null}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.9 }}
                      transition={{ duration: 0.3 }}
                      className="bg-white rounded-xl shadow-md overflow-hidden hover:shadow-xl transition-shadow duration-300 group flex flex-col h-full"
                    >
                      {/* image */}
                      <div className="relative h-48 overflow-hidden flex-shrink-0">
                        <CloudflareAssetPreview
                          src={course.image}
                          fallbackSrc="https://via.placeholder.com/400x600?text=Course"
                          alt={getTranslationValue(course.title, lang)}
                          className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-500"
                        />

                        {/* hover buttons */}
                        <div className="absolute bottom-3 right-3 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                          <button
                            onClick={() => setVoiceoverCourse(course)}
                            className="p-2 bg-white rounded-full shadow-md hover:bg-gray-100 transition-colors"
                            title="Voiceover status & generate (TTS from theory)"
                          >
                            <SpeakerWaveIcon className="h-5 w-5 text-indigo-600" />
                          </button>
                          <button
                            onClick={() => openEdit(course)}
                            className="p-2 bg-white rounded-full shadow-md hover:bg-gray-100 transition-colors"
                            title="Edit"
                          >
                            <PencilIcon className="h-5 w-5 text-blue-600" />
                          </button>
                          <button
                            onClick={() => openDelete(course)}
                            className="p-2 bg-white rounded-full shadow-md hover:bg-gray-100 transition-colors"
                            title="Delete"
                          >
                            <TrashIcon className="h-5 w-5 text-red-600" />
                          </button>
                        </div>
                      </div>

                      {/* Content */}
                      <div className="p-5 flex flex-col flex-grow">
                        <h2
                          className="font-semibold text-lg mb-2 truncate cursor-pointer text-gray-900 hover:text-blue-600 transition-colors"
                          title={getTranslationValue(course.title, lang)}
                          onClick={() => navigate(`/course/${course._id}`)}
                        >
                          {getTranslationValue(course.title, lang)}
                        </h2>

                        <p
                          className="text-sm text-gray-600 mb-4 flex-grow"
                          style={{
                            display: "-webkit-box",
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: "vertical",
                            overflow: "hidden",
                          }}
                          title={getTranslationValue(course.description, lang)}
                        >
                          {getTranslationValue(course.description, lang)}
                        </p>

                        {/* Price */}
                        {course.prices && course.prices.length > 0 && (
                          <div className="mb-4">
                            {course.prices[0].isFree ? (
                              <span className="text-green-600 font-semibold text-sm bg-green-50 px-2 py-1 rounded-md inline-block">
                                Free
                              </span>
                            ) : (
                              <div className="flex items-center gap-2">
                                {course.prices[0].salePrice ? (
                                  <>
                                    <span className="text-blue-600 font-semibold text-sm">
                                      {course.prices[0].currency}{" "}
                                      {course.prices[0].salePrice.toLocaleString()}
                                    </span>
                                    <span className="text-gray-400 text-xs line-through">
                                      {course.prices[0].currency}{" "}
                                      {course.prices[0].originalPrice.toLocaleString()}
                                    </span>
                                  </>
                                ) : (
                                  <span className="text-gray-800 font-medium text-sm">
                                    {course.prices[0].currency}{" "}
                                    {course.prices[0].originalPrice.toLocaleString()}
                                  </span>
                                )}
                              </div>
                            )}
                          </div>
                        )}

                        {/* Status and Level in the same row */}
                        <div className="flex justify-between items-center  gap-2 mb-3">
                          <span
                            className={`inline-block px-3 py-1 text-xs font-medium rounded-full ${
                              statusColors[course.status]
                            }`}
                          >
                            {statusLabels[course.status]}
                          </span>

                          <span className="text-sm font-medium text-gray-500">
                            {course.numberOfLesson || 0} lessons
                          </span>
                        </div>

                        {/* Giới hạn thị trường. Chỉ hiện khi CÓ giới hạn —
                            course publish mọi nơi là mặc định và là đa số, thêm
                            một chip "Mọi nơi" vào từng thẻ chỉ làm loãng danh
                            sách. Nhưng khi đã giới hạn thì phải nhìn thấy được:
                            targeting vô hình là thứ khiến người ta báo "app
                            không thấy khoá học" mà không ai đoán ra tại sao. */}
                        {!!course.countries?.length && (
                          <div className="flex flex-wrap items-center gap-1 mb-3">
                            <GlobeAltIcon className="w-4 h-4 text-amber-600" />
                            {course.countries.map((code) => (
                              <span
                                key={code}
                                title={countryLabel(code)}
                                className="inline-block px-2 py-0.5 text-xs font-medium rounded-full bg-amber-50 text-amber-700 border border-amber-200"
                              >
                                {code}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    </motion.div>
                  );
                })}
              </AnimatePresence>
            </div>

            {/* Loading more indicator */}
            {loadingMore && (
              <div className="flex justify-center mt-6">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
              </div>
            )}

            {/* No more courses message */}
            {!hasMore && courses.length > 0 && (
              <div className="text-center mt-6 text-gray-500">
                No more courses to load
              </div>
            )}
          </>
        )}
      </div>

      {/* Modal + Confirm */}
      <CourseModal
        isOpen={isModalOpen}
        initial={selectedCourse}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedCourse(null);
        }}
        onSubmit={handleModalSubmit}
        loading={modalLoading}
        error={modalError}
      />

      <CourseConfirm
        isOpen={isConfirmOpen}
        course={selectedCourse ?? undefined}
        onClose={() => {
          setIsConfirmOpen(false);
          setSelectedCourse(null);
        }}
        onConfirm={() => {
          if (!selectedCourse) return Promise.resolve();
          return handleConfirmDelete(selectedCourse._id);
        }}
      />

      <VoiceoverStatusModal
        open={Boolean(voiceoverCourse)}
        courseId={voiceoverCourse?._id ?? ""}
        courseTitle={
          voiceoverCourse
            ? getTranslationValue(voiceoverCourse.title, lang)
            : ""
        }
        onClose={() => setVoiceoverCourse(null)}
      />
    </div>
  );
}
