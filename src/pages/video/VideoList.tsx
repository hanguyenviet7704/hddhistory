import React, { useCallback, useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { Combobox } from "@headlessui/react";
import { PlusIcon } from "lucide-react";
import { RootState } from "../../store";
import { ICourse } from "../../types/interface/course.interface";
import { ILesson } from "../../types/interface/lesson.interface";
import { LessonStatus, LessonType } from "../../types/enum/lesson.enum";
import { courseService } from "../../services/courseService";
import { lessonService } from "../../services/lessonService";
import { getTranslationValue } from "../../utils/translation";
import CloudflareAssetPreview from "../../components/files/CloudflareAssetPreview";

export default function VideoList() {
  const lang = useSelector((state: RootState) => state.lang.code);
  const navigate = useNavigate();
  const [videos, setVideos] = useState<ILesson[]>([]);
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

  const statusColors: Record<LessonStatus, string> = {
    [LessonStatus.PUBLISHED]: "bg-green-100 text-green-700",
    [LessonStatus.DRAFT]: "bg-yellow-100 text-yellow-700",
  };

  const fetchCourses = useCallback(async (query = "") => {
    try {
      const response = await courseService.getList({
        search: query,
        isAll: true,
      });
      setCourses(response.data.items ?? []);
    } catch (error) {
      console.error("fetchCourses", error);
    }
  }, []);

  const fetchVideos = useCallback(async (
    search = "",
    courseId?: string,
    pageNum = 1,
    isLoadMore = false,
  ) => {
    if (isLoadMore) setLoadingMore(true);
    else setLoading(true);

    try {
      const response = await lessonService.getList({
        page: pageNum,
        take: 12,
        search,
        courseId,
        type: LessonType.VIDEO,
      });
      const list: ILesson[] = response.data.items ?? [];

      if (pageNum === 1) setVideos(list);
      else setVideos((prev) => [...prev, ...list]);

      setHasMore(list.length === 12);
      setPage(pageNum);
    } catch (error) {
      console.error("fetchVideos", error);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, []);

  useEffect(() => {
    fetchCourses();
    fetchVideos("", undefined, 1, false);
  }, [fetchCourses, fetchVideos]);

  useEffect(() => {
    window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      fetchVideos(searchTerm.trim(), selectedCourse?._id, 1, false);
    }, 500);
    return () => window.clearTimeout(debounceRef.current);
  }, [fetchVideos, searchTerm, selectedCourse]);

  useEffect(() => {
    window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      fetchCourses(courseQuery.trim());
    }, 400);
    return () => window.clearTimeout(debounceRef.current);
  }, [courseQuery, fetchCourses]);

  const lastVideoRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (loading || loadingMore) return;
      if (observer.current) observer.current.disconnect();
      observer.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && hasMore) {
          fetchVideos(searchTerm.trim(), selectedCourse?._id, page + 1, true);
        }
      });
      if (node) observer.current.observe(node);
    },
    [fetchVideos, loading, loadingMore, hasMore, page, searchTerm, selectedCourse],
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="mx-auto mb-8 max-w-7xl">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Video</h1>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <Combobox value={selectedCourse} onChange={setSelectedCourse}>
              <div className="relative">
                <Combobox.Input
                  className="w-56 rounded-lg border px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-500"
                  placeholder="Search course..."
                  displayValue={(course: ICourse) =>
                    getTranslationValue(course?.title, lang)
                  }
                  onChange={(event) => setCourseQuery(event.target.value)}
                />
                <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                  <Combobox.Option
                    value={null}
                    className="cursor-pointer px-3 py-2 text-gray-500 hover:bg-gray-100"
                  >
                    All Courses
                  </Combobox.Option>
                  {courses.map((course) => (
                    <Combobox.Option
                      key={course._id}
                      value={course}
                      className="cursor-pointer px-3 py-2 hover:bg-gray-100"
                    >
                      {getTranslationValue(course.title, lang)}
                    </Combobox.Option>
                  ))}
                </Combobox.Options>
              </div>
            </Combobox>

            <div className="relative">
              <input
                value={searchTerm}
                onChange={(event) => setSearchTerm(event.target.value)}
                placeholder="Search videos..."
                className="w-72 rounded-lg border py-2 pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-brand-500"
              />
              <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
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
              onClick={() => navigate("/video/create")}
              className="inline-flex items-center gap-2 rounded-lg bg-gradient-to-r from-brand-600 to-bronze-600 px-4 py-2 text-white shadow-md transition-all hover:from-brand-700 hover:to-bronze-700"
            >
              <PlusIcon className="h-5 w-5" />
              New Video
            </button>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-7xl">
        {loading && videos.length === 0 ? (
          <div className="flex items-center justify-center py-20">
            <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-t-2 border-brand-500"></div>
          </div>
        ) : videos.length === 0 ? (
          <div className="py-20 text-center">
            <div className="mx-auto max-w-md rounded-2xl bg-white p-8 shadow-sm">
              <h3 className="text-xl font-semibold text-gray-900">
                No videos found
              </h3>
              <p className="mt-2 text-gray-500">
                Try a different search or create your first video lesson.
              </p>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3">
            {videos.map((video, index) => {
              const isLastItem = index === videos.length - 1;
              return (
                <div
                  key={video._id}
                  ref={isLastItem ? lastVideoRef : undefined}
                  className="group overflow-hidden rounded-2xl bg-white shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl"
                >
                  <div
                    className="cursor-pointer"
                    onClick={() => navigate(`/video/${video._id}`)}
                  >
                    <div className="relative h-56 overflow-hidden bg-gray-100">
                      {video.video?.url ? (
                        <CloudflareAssetPreview
                          src={video.video.url}
                          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                        />
                      ) : video.video?.thumbnail ? (
                        <img
                          src={video.video.thumbnail}
                          alt={getTranslationValue(video.title, lang)}
                          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                        />
                      ) : video.image ? (
                        <img
                          src={video.image}
                          alt={getTranslationValue(video.title, lang)}
                          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                        />
                      ) : (
                        <div className="flex h-full items-center justify-center text-gray-400">
                          No preview
                        </div>
                      )}
                    </div>

                    <div className="space-y-4 p-5">
                      <div className="flex items-center justify-between">
                        <span
                          className={`rounded-full px-3 py-1 text-xs font-medium ${
                            statusColors[video.status]
                          }`}
                        >
                          {video.status}
                        </span>
                        <span className="text-xs text-gray-400">
                          #{video.index || 0}
                        </span>
                      </div>

                      <div>
                        <h3 className="line-clamp-2 text-lg font-semibold text-gray-900">
                          {getTranslationValue(video.title, lang) || "Untitled video"}
                        </h3>
                        <p className="mt-2 line-clamp-2 text-sm text-gray-500">
                          {getTranslationValue(video.description, lang) ||
                            "No description"}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {loadingMore ? (
          <div className="flex justify-center py-8">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-t-2 border-brand-500"></div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
