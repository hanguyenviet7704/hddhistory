import React, { useCallback, useEffect, useState } from "react";
import { Pagination } from "@mui/material";
import { EyeIcon } from "@heroicons/react/24/outline";
import { useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { LangCode } from "../../types/enum/common.enum";
import { LessonType } from "../../types/enum/lesson.enum";
import { userProgressService } from "../../services/userProgressService";
import {
  ICourseProgressSummary,
  IStopAtDetail,
} from "../../types/interface/user-progress.interface";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";

const DEFAULT_PAGE_SIZE = 20;

const formatDate = (value?: string | Date) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};

const normalizeList = (payload: any): ICourseProgressSummary[] => {
  const parsed = payload?.data?.data ?? payload?.data ?? payload ?? {};
  if (Array.isArray(parsed)) return parsed;

  const list =
    parsed.items ??
    parsed.list ??
    parsed.data?.items ??
    parsed.data?.list ??
    parsed.data ??
    [];
  return Array.isArray(list) ? list : [];
};

const resolvePagination = (
  payload: any,
  fallbackLength: number,
  pageNumber: number,
  take: number
) => {
  const parsed = payload?.data?.data ?? payload?.data ?? payload ?? {};
  const totalPages =
    parsed.totalPages ??
    parsed.pagination?.totalPages ??
    parsed.pagination?.total ??
    parsed.data?.totalPages;
  const totalItems =
    parsed.total ??
    parsed.pagination?.totalItems ??
    parsed.data?.total ??
    parsed.data?.totalItems;
  const itemsPerPage =
    parsed.itemsPerPage ??
    parsed.take ??
    parsed.pagination?.take ??
    parsed.data?.take ??
    take;
  const computedTotal =
    totalPages ||
    (totalItems ? Math.ceil(totalItems / itemsPerPage) : undefined) ||
    (itemsPerPage ? Math.ceil(fallbackLength / itemsPerPage) : 1);
  const currentPage =
    parsed.currentPage ??
    parsed.page ??
    parsed.pagination?.page ??
    parsed.data?.page ??
    pageNumber;
  return {
    totalPages: Number(computedTotal) || 1,
    currentPage: Number(currentPage) || pageNumber,
  };
};

const getCourseId = (summary: ICourseProgressSummary | any) =>
  summary?.courseId || summary?.id || summary?._id || "";

const lessonTypeStyles: Record<string, string> = {
  [LessonType.LESSON]: "bg-blue-100 text-blue-700",
  [LessonType.ROLEPLAY]: "bg-amber-100 text-amber-700",
  [LessonType.OUTPUT]: "bg-emerald-100 text-emerald-700",
};

const getStopAtLabel = (stopAt: IStopAtDetail | undefined, lang: LangCode) => {
  if (!stopAt) return "-";
  const lessonTitle = getTranslationValue(stopAt.lessonTitle, lang);
  const keypointTitle = getTranslationValue(stopAt.keypointTitle, lang);
  const parts = [
    stopAt.lessonType,
    lessonTitle || undefined,
    keypointTitle || undefined,
  ].filter(Boolean);
  return parts.length ? parts.join(" - ") : "-";
};

export default function UserProgressSummaryList() {
  const { userId = "" } = useParams();
  const navigate = useNavigate();
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showError } = useNotification();

  const [items, setItems] = useState<ICourseProgressSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const fetchProgress = useCallback(
    async (pageNumber: number) => {
      if (!userId) {
        setItems([]);
        setTotalPages(1);
        return;
      }
      setLoading(true);
      try {
        const res = await userProgressService.getProgressOfUser(userId, {
          page: pageNumber,
          take: DEFAULT_PAGE_SIZE,
        });
        const list = normalizeList(res);
        const pagination = resolvePagination(
          res,
          list.length,
          pageNumber,
          DEFAULT_PAGE_SIZE
        );
        setItems(list);
        setPage(pagination.currentPage);
        setTotalPages(pagination.totalPages);
      } catch (error) {
        console.error("Failed to fetch progress summary", error);
        showError("Không tải được tiến độ học tập");
      } finally {
        setLoading(false);
      }
    },
    [showError, userId]
  );

  useEffect(() => {
    fetchProgress(page);
  }, [fetchProgress, page]);

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-6xl mx-auto space-y-4">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">
              User learn progress
            </h1>
            <p className="text-sm text-gray-500">
              Danh sách tiến độ theo khoá học của người dùng.
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => navigate(-1)}
              className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 text-sm shadow-sm"
            >
              Quay lại
            </button>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          {loading ? (
            <div className="p-10 text-center text-gray-500">
              Đang tải dữ liệu...
            </div>
          ) : items.length === 0 ? (
            <div className="p-10 text-center text-gray-500">
              Chưa có tiến độ học tập.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Course
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Start time
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Last time
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Stop at
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Action
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {items.map((item) => {
                    const courseId = getCourseId(item);
                    const title =
                      getTranslationValue(item.title, lang) ||
                      courseId ||
                      "-";
                    const stopAtLabel = getStopAtLabel(item.stopAt, lang);
                    const lessonTitle = getTranslationValue(
                      item.stopAt?.lessonTitle,
                      lang
                    );
                    const keypointTitle = getTranslationValue(
                      item.stopAt?.keypointTitle,
                      lang
                    );
                    const type = item.stopAt?.lessonType;
                    const typeClass = type
                      ? lessonTypeStyles[type] || "bg-slate-100 text-slate-600"
                      : "";
                    const canNavigate = Boolean(courseId);
                    return (
                      <tr
                        key={courseId || title}
                        className="hover:bg-slate-50 transition-colors"
                      >
                        <td className="px-6 py-4 text-sm text-gray-800">
                          <div
                            className="max-w-[260px] truncate font-semibold text-gray-900"
                            title={title}
                          >
                            {title}
                          </div>
                          <div className="text-xs text-gray-400">
                            {courseId}
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          {formatDate(item.createdAt)}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          {formatDate(item.lastTime)}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          <div className="flex flex-col gap-1">
                            <div className="flex items-center gap-2">
                              {type ? (
                                <span
                                  className={`px-2 py-0.5 rounded-full text-xs font-semibold uppercase ${typeClass}`}
                                >
                                  {type}
                                </span>
                              ) : null}
                              <span
                                className="max-w-[220px] truncate text-sm text-gray-700"
                                title={lessonTitle || stopAtLabel}
                              >
                                {lessonTitle || stopAtLabel || "-"}
                              </span>
                            </div>
                            <span
                              className="max-w-[260px] truncate text-xs text-gray-500"
                              title={keypointTitle || stopAtLabel}
                            >
                              {keypointTitle
                                ? `Keypoint: ${keypointTitle}`
                                : stopAtLabel}
                            </span>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-right text-sm">
                          <button
                            onClick={() => {
                              if (!canNavigate) return;
                              navigate(
                                `/progress/user/${userId}/course/${courseId}`
                              );
                            }}
                            disabled={!canNavigate}
                            className={`inline-flex items-center gap-1 ${
                              canNavigate
                                ? "text-blue-600 hover:text-blue-800"
                                : "text-gray-400 cursor-not-allowed"
                            }`}
                          >
                            <EyeIcon className="h-4 w-4" />
                            <span className="underline">see detail</span>
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          <div className="p-4 flex justify-end">
            <Pagination
              count={totalPages}
              page={page}
              onChange={(_, value) => setPage(value)}
              color="primary"
              shape="rounded"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
