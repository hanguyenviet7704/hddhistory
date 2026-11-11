// src/pages/courses/CourseList.tsx
import React, { useEffect, useRef, useState, useCallback } from "react";
import {
  PencilIcon,
  TrashIcon,
  PlusIcon,
  SpeakerWaveIcon,
  GlobeAltIcon,
  CloudArrowUpIcon,
  CloudArrowDownIcon,
  ArrowPathIcon,
  TagIcon,
} from "@heroicons/react/24/outline";
import { countryLabel } from "../../config/countries";
import {
  courseService,
  DriveSyncResult,
} from "../../services/courseService";
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
import { downloadBlob } from "../../utils/downloadBlob";
import CourseVersionsModal from "../../components/courses/CourseVersionsModal";
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
  const [versionsCourse, setVersionsCourse] = useState<ICourse | null>(null);
  // Sync Drive chỉ ghi vào BẢN ĐANG SỬA. Trên khoá đã có tag, app vẫn phát tag
  // cũ cho tới khi đánh tag mới — bật cờ này để mỗi khoá import sạch lỗi được
  // phát hành luôn. Mặc định tắt: phát hành phải là hành động có chủ ý.
  const [syncAutoTag, setSyncAutoTag] = useState(false);

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

  const [syncingDrive, setSyncingDrive] = useState(false);
  const [syncResults, setSyncResults] = useState<DriveSyncResult[] | null>(
    null
  );

  /**
   * Kéo về từng khoá. `syncAutoTag` dùng chung với nút Sync Drive: một ô tick
   * "Phát hành sau sync" điều khiển cả hai, để kéo một khoá và kéo cả folder
   * không âm thầm khác nhau ở chuyện có phát hành hay không.
   */
  const [pullingCourseId, setPullingCourseId] = useState<string | null>(null);

  const pullFromDrive = async (course: ICourse) => {
    setPullingCourseId(course._id);
    try {
      const result = await courseService.pullCourseFromDrive(
        course._id,
        syncAutoTag
      );
      // Đổ vào đúng bảng kết quả của Sync Drive — lỗi import nằm theo dòng và
      // theo sheet, một cái toast không chở nổi.
      setSyncResults([result]);
      if (result.action === "failed" || result.errorCount > 0) {
        showError(`Kéo về "${result.fileName}": ${result.errorCount} lỗi`);
      } else {
        showSuccess(`Đã kéo "${result.fileName}" về`);
      }
      fetchCourses(searchTerm.trim(), 1, false);
    } catch (error: any) {
      showError(error?.response?.data?.message || "Kéo về từ Drive thất bại");
    } finally {
      setPullingCourseId(null);
    }
  };

  const pushToDrive = async (course: ICourse) => {
    try {
      const res = await courseService.pushCourseToDrive(course._id);
      showSuccess("Pushed course sheet to Drive");
      if (res.webViewLink) window.open(res.webViewLink, "_blank");
    } catch (error: any) {
      showError(error?.response?.data?.message || "Push to Drive failed");
    }
  };

  const syncDrive = async () => {
    setSyncingDrive(true);
    try {
      const results = await courseService.syncFromDrive(undefined, syncAutoTag);
      setSyncResults(results);
      const failed = results.filter((r) => r.action === "failed").length;
      if (failed) {
        showError(`Drive sync: ${failed}/${results.length} file(s) failed`);
      } else {
        showSuccess(`Drive sync: ${results.length} file(s) OK`);
      }
      fetchCourses(searchTerm.trim(), 1, false);
    } catch (error: any) {
      showError(error?.response?.data?.message || "Drive sync failed");
    } finally {
      setSyncingDrive(false);
    }
  };

  const describeSyncStats = (result: DriveSyncResult) => {
    if (!result.stats) return "";
    return Object.entries(result.stats)
      .filter(([, s]) => s.created > 0 || s.updated > 0)
      .map(
        ([name, s]) =>
          `${name}: ${s.created > 0 ? `+${s.created} mới` : ""}${
            s.created > 0 && s.updated > 0 ? ", " : ""
          }${s.updated > 0 ? `${s.updated} cập nhật` : ""}`
      )
      .join(" · ");
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
    [CourseStatus.COMING_SOON]: "bg-brand-100 text-brand-700",
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
                className="w-full md:w-72 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-500 focus:border-brand-500 transition"
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
                  downloadBlob(res.data, "course-import-template.xlsx");
                } catch {
                  showError("Download template failed");
                }
              }}
              className="inline-flex items-center gap-2 border border-slate-400 text-slate-600 hover:bg-slate-50 px-3 py-2 rounded-lg transition text-sm"
            >
              Template
            </button>
            <button
              type="button"
              onClick={async () => {
                try {
                  const res = await courseService.exportExcel();
                  downloadBlob(res.data, "course-export.xlsx");
                } catch {
                  showError("Export courses failed");
                }
              }}
              className="inline-flex items-center gap-2 border border-slate-400 text-slate-600 hover:bg-slate-50 px-3 py-2 rounded-lg transition text-sm"
            >
              Export
            </button>
            <label
              className="inline-flex items-center gap-2 text-sm text-slate-600"
              title="Phát hành luôn mỗi khoá import sạch lỗi (đánh tag patch kế tiếp)"
            >
              <input
                type="checkbox"
                checked={syncAutoTag}
                onChange={(event) => setSyncAutoTag(event.target.checked)}
              />
              Phát hành sau sync
            </label>
            <button
              type="button"
              disabled={syncingDrive}
              onClick={syncDrive}
              title="Pull every course sheet in the Drive folder through the importer"
              className="inline-flex items-center gap-2 border border-emerald-600 text-emerald-700 hover:bg-emerald-50 disabled:border-emerald-300 disabled:text-emerald-300 px-3 py-2 rounded-lg transition text-sm"
            >
              <CloudArrowUpIcon className="h-4 w-4" />
              {syncingDrive ? "Syncing..." : "Sync Drive"}
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
              className="inline-flex items-center gap-2 bg-gradient-to-r from-brand-600 to-bronze-600 text-white px-4 py-2 rounded-lg hover:from-brand-700 hover:to-bronze-700 transition-all shadow-md hover:shadow-lg"
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
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-brand-500"></div>
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
              className="mt-4 inline-flex items-center gap-2 bg-gradient-to-r from-brand-600 to-bronze-600 text-white px-4 py-2 rounded-lg hover:from-brand-700 hover:to-bronze-700 transition-all shadow-md hover:shadow-lg"
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
                            onClick={() => pushToDrive(course)}
                            className="p-2 bg-white rounded-full shadow-md hover:bg-gray-100 transition-colors"
                            title="Đẩy sheet của khoá này lên Google Drive"
                          >
                            <CloudArrowUpIcon className="h-5 w-5 text-emerald-600" />
                          </button>
                          <button
                            onClick={() => pullFromDrive(course)}
                            disabled={pullingCourseId === course._id}
                            className="p-2 bg-white rounded-full shadow-md hover:bg-gray-100 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
                            title="Kéo sheet của riêng khoá này từ Google Drive về"
                          >
                            {pullingCourseId === course._id ? (
                              <ArrowPathIcon className="h-5 w-5 text-sky-600 animate-spin" />
                            ) : (
                              <CloudArrowDownIcon className="h-5 w-5 text-sky-600" />
                            )}
                          </button>
                          <button
                            onClick={() => setVersionsCourse(course)}
                            className="p-2 bg-white rounded-full shadow-md hover:bg-gray-100 transition-colors"
                            title="Phiên bản nội dung: đánh tag, phát hành, rollback"
                          >
                            <TagIcon className="h-5 w-5 text-amber-600" />
                          </button>
                          <button
                            onClick={() => setVoiceoverCourse(course)}
                            className="p-2 bg-white rounded-full shadow-md hover:bg-gray-100 transition-colors"
                            title="Voiceover status & generate (TTS from theory)"
                          >
                            <SpeakerWaveIcon className="h-5 w-5 text-bronze-600" />
                          </button>
                          <button
                            onClick={() => openEdit(course)}
                            className="p-2 bg-white rounded-full shadow-md hover:bg-gray-100 transition-colors"
                            title="Edit"
                          >
                            <PencilIcon className="h-5 w-5 text-brand-600" />
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
                          className="font-semibold text-lg mb-2 truncate cursor-pointer text-gray-900 hover:text-brand-600 transition-colors"
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
                                    <span className="text-brand-600 font-semibold text-sm">
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
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-brand-500"></div>
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

      <CourseVersionsModal
        open={Boolean(versionsCourse)}
        courseId={versionsCourse?._id ?? ""}
        courseTitle={
          versionsCourse ? getTranslationValue(versionsCourse.title, lang) : ""
        }
        onClose={() => setVersionsCourse(null)}
      />

      {/* Drive sync results */}
      {syncResults && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-3xl max-h-[80vh] flex flex-col">
            <div className="flex items-center justify-between px-6 py-4 border-b">
              <h2 className="text-lg font-semibold text-gray-900">
                Kết quả Sync Drive ({syncResults.length} file)
              </h2>
              <button
                onClick={() => setSyncResults(null)}
                className="text-gray-400 hover:text-gray-600 text-2xl leading-none"
                aria-label="Đóng"
              >
                ×
              </button>
            </div>
            <div className="overflow-y-auto px-6 py-4">
              {syncResults.length === 0 ? (
                <p className="text-gray-500">
                  Không có sheet nào trong folder để sync.
                </p>
              ) : (
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-left text-gray-500 border-b">
                      <th className="py-2 pr-3">Sheet</th>
                      <th className="py-2 pr-3">Hành động</th>
                      <th className="py-2">Chi tiết</th>
                    </tr>
                  </thead>
                  <tbody>
                    {syncResults.map((r) => (
                      <tr key={r.fileId} className="border-b last:border-0 align-top">
                        <td className="py-2 pr-3 font-medium text-gray-900">
                          {r.fileName}
                          {/* Sync ghi vào bản đang sửa. Nếu không phát hành thì
                              app vẫn phát tag cũ — nói rõ ra để người sửa sheet
                              không tưởng đã live. */}
                          {r.action !== "failed" && r.action !== "noop" && (
                            <span
                              className={`mt-1 block text-xs font-normal ${
                                r.autoTaggedAs ? "text-emerald-600" : "text-amber-600"
                              }`}
                            >
                              {r.autoTaggedAs
                                ? `đã phát hành ${r.autoTaggedAs}`
                                : "chưa phát hành — cần đánh tag"}
                            </span>
                          )}
                        </td>
                        <td className="py-2 pr-3">
                          {r.action === "created" && (
                            <span className="inline-block px-2 py-0.5 rounded-full text-xs bg-emerald-100 text-emerald-700">
                              Tạo mới
                            </span>
                          )}
                          {r.action === "updated" && (
                            <span className="inline-block px-2 py-0.5 rounded-full text-xs bg-brand-100 text-brand-700">
                              Cập nhật
                            </span>
                          )}
                          {r.action === "noop" && (
                            <span className="inline-block px-2 py-0.5 rounded-full text-xs bg-gray-100 text-gray-600">
                              Không đổi
                            </span>
                          )}
                          {r.action === "failed" && (
                            <span className="inline-block px-2 py-0.5 rounded-full text-xs bg-red-100 text-red-700">
                              Lỗi ({r.errorCount})
                            </span>
                          )}
                        </td>
                        <td className="py-2 text-gray-600">
                          {r.action === "failed" ? (
                            <div className="space-y-1">
                              {r.errors.slice(0, 3).map((e, i) => (
                                <div key={i} className="text-red-600">
                                  {e.sheet !== "drive"
                                    ? `[${e.sheet}${e.row ? ` dòng ${e.row}` : ""}${
                                        e.column ? ` · ${e.column}` : ""
                                      }] `
                                    : ""}
                                  {e.message}
                                </div>
                              ))}
                              {r.errors.length > 3 && (
                                <div className="text-gray-400">
                                  … và {r.errors.length - 3} lỗi nữa (xem tab
                                  import_errors trong sheet)
                                </div>
                              )}
                            </div>
                          ) : (
                            describeSyncStats(r) || "—"
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
