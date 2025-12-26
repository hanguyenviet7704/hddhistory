import React, { useEffect, useRef, useState, useCallback } from "react";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useNavigate } from "react-router-dom";
import { courseService } from "../../services/courseService";
import { ICourse } from "../../types/interface/course.interface";
import { Combobox } from "@headlessui/react";
import { PlusIcon } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { ILesson } from "../../types/interface/lesson.interface";
import { lessonService } from "../../services/lessonService";
import { LessonStatus, LessonType } from "../../types/enum/lesson.enum";
import { getTranslationValue } from "../../utils/translation";

export default function LessonList() {
  const [outputs, setOutputs] = useState<ILesson[]>([]);
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(1);

  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCourse, setSelectedCourse] = useState<ICourse | null>(null);
  const [courseQuery, setCourseQuery] = useState("");

  const debounceRef = useRef<number | undefined>(undefined);
  const observer = useRef<IntersectionObserver | null>(null);
  const lang = useSelector((state: RootState) => state.lang.code);
  const navigate = useNavigate();

  // fetch courses (with search)
  const fetchCourses = async (query = "") => {
    try {
      const res = await courseService.getList({
        search: query,
        isAll: true,
      });
      const data = res.data?.data ?? res.data ?? {};
      const list: ICourse[] =
        data.list ?? data.items ?? (Array.isArray(data) ? data : []);
      setCourses(list);
    } catch (err) {
      console.error("Failed to fetch courses:", err);
    }
  };

  // fetch outputs with pagination
  const fetchOutputs = async (
    search = "",
    courseId?: string,
    pageNum = 1,
    isLoadMore = false
  ) => {
    if (!hasMore && pageNum > 1) return;

    if (isLoadMore) {
      setLoadingMore(true);
    } else {
      setLoading(true);
    }

    try {
      const res = await lessonService.getList({
        page: pageNum,
        take: 12, // Number of items per page
        courseId,
        search,
        type: LessonType.OUTPUT,
      });
      const data = res.data?.data ?? res.data ?? {};
      const list: ILesson[] =
        data.list ?? data.items ?? (Array.isArray(data) ? data : []);

      if (pageNum === 1) {
        setOutputs(list);
      } else {
        setOutputs((prev) => [...prev, ...list]);
      }

      setHasMore(list.length === 12); // If we got less than 12, no more pages
      setPage(pageNum);
    } catch (err) {
      console.error("Failed to fetch outputs:", err);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  useEffect(() => {
    fetchCourses();
    fetchOutputs("", selectedCourse?._id, 1, false);
  }, []);

  useEffect(() => {
    fetchOutputs(searchTerm.trim(), selectedCourse?._id, 1, false);
  }, [selectedCourse]);

  // debounce search outputs
  useEffect(() => {
    window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      fetchOutputs(searchTerm.trim(), selectedCourse?._id, 1, false);
    }, 500);
    return () => window.clearTimeout(debounceRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchTerm]);

  // debounce search courses
  useEffect(() => {
    window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      fetchCourses(courseQuery.trim());
    }, 400);
    return () => window.clearTimeout(debounceRef.current);
  }, [courseQuery]);

  // Using IntersectionObserver for infinite scroll
  const lastOutputRef = useCallback(
    (node: any) => {
      if (loading || loadingMore) return;
      if (observer.current) observer.current.disconnect();
      observer.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && hasMore) {
          fetchOutputs(searchTerm.trim(), selectedCourse?._id, page + 1, true);
        }
      });
      if (node) observer.current.observe(node);
    },
    [loading, loadingMore, hasMore, page, searchTerm, selectedCourse]
  );

  const statusColors: Record<LessonStatus, string> = {
    [LessonStatus.PUBLISHED]: "bg-green-100 text-green-700",
    [LessonStatus.DRAFT]: "bg-yellow-100 text-yellow-700",
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">🧠 Outputs</h1>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Combobox search course */}
            <Combobox value={selectedCourse} onChange={setSelectedCourse}>
              <div className="relative">
                <Combobox.Input
                  className="border rounded-lg px-3 py-2 w-56 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Search course..."
                  displayValue={(course: ICourse) =>
                    getTranslationValue(course?.title, lang)
                  }
                  onChange={(e) => setCourseQuery(e.target.value)}
                />
                <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                  <Combobox.Option
                    value={null}
                    className="cursor-pointer px-3 py-2 hover:bg-gray-100 text-gray-500"
                  >
                    All Courses
                  </Combobox.Option>
                  {courses.map((c) => (
                    <Combobox.Option
                      key={c._id}
                      value={c}
                      className="cursor-pointer px-3 py-2 hover:bg-gray-100"
                    >
                      {getTranslationValue(c.title, lang)}
                    </Combobox.Option>
                  ))}
                </Combobox.Options>
              </div>
            </Combobox>

            <div className="relative">
              <input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search outputs..."
                className="border rounded-lg pl-10 pr-4 py-2 w-72 focus:outline-none focus:ring-2 focus:ring-blue-500"
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
              onClick={() => navigate("/output/create")}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>New Output</span>
            </button>
          </div>
        </div>
      </div>

      {/* List */}
      <div className="max-w-7xl mx-auto">
        {loading && outputs.length === 0 ? (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
          </div>
        ) : outputs.length === 0 ? (
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
              No outputs found
            </h3>
            <p className="text-gray-500">
              Get started by creating a new outputs.
            </p>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              <AnimatePresence>
                {outputs.map((output, index) => {
                  // Add ref to the last element
                  const isLast = index === outputs.length - 1;
                  return (
                    <motion.div
                      key={output._id}
                      ref={isLast ? lastOutputRef : null}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.9 }}
                      transition={{ duration: 0.3 }}
                      className="bg-white rounded-xl shadow-md overflow-hidden hover:shadow-xl transition-shadow duration-300 group flex flex-col h-full cursor-pointer"
                      onClick={() => navigate(`/output/${output._id}`)}
                    >
                      {/* Image */}
                      <div className="relative h-48 overflow-hidden flex-shrink-0">
                        <img
                          src={
                            output.image ||
                            "https://placehold.co/600x400?text=Output+Test&font=roboto"
                          }
                          alt={getTranslationValue(output.title, lang)}
                          className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-500"
                        />
                      </div>

                      {/* Content */}
                      <div className="p-5 flex flex-col flex-grow">
                        <h2 className="font-semibold text-lg mb-2 truncate text-gray-900">
                          {getTranslationValue(output.title, lang)}
                        </h2>

                        <p
                          className="text-sm text-gray-600 mb-4 flex-grow"
                          style={{
                            display: "-webkit-box",
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: "vertical",
                            overflow: "hidden",
                          }}
                          title={getTranslationValue(output.description, lang)}
                        >
                          {getTranslationValue(output.description, lang)}
                        </p>

                        <div className="flex items-center justify-start mt-auto gap-8">
                          <div className="rounded flex items-start justify-center">
                            <img
                              src={(output.icon as any)?.url}
                              alt={getTranslationValue(
                                (output.icon as any)?.title,
                                lang
                              )}
                              className="w-5 h-5 object-cover rounded"
                            />
                            <span
                              style={{
                                color: (output.icon as any)?.color || "#f3f4f6",
                                fontSize: 14,
                                marginLeft: 6,
                              }}
                            >
                              {getTranslationValue(
                                (output.icon as any)?.title,
                                lang
                              )}
                            </span>
                          </div>

                          <div className="flex items-center">
                            <img
                              src="https://z-cdn-media.chatglm.cn/files/622fee3c-3db8-4cfc-9572-36660e61711c_Screenshot%202025-10-24%20at%2017.06.11.png?auth_key=1792836409-e64e6ea69b684b4cb655a845bc553eff-0-1a2c8c30def151790672477fcca1f5ac"
                              alt="Clock icon"
                              className="w-5 h-5 mr-2"
                            />
                            <span className="text-sm text-gray-500">
                              {getTranslationValue(
                                output.estimateCompleTime,
                                lang
                              )}
                            </span>
                          </div>
                        </div>
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

            {/* No more outputs message */}
            {!hasMore && outputs.length > 0 && (
              <div className="text-center mt-6 text-gray-500">
                No more outputs to load
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
