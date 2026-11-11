import React, { useCallback, useEffect, useState } from "react";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { Pagination } from "@mui/material";
import { useSelector } from "react-redux";
import { userProgressService } from "../../../services/userProgressService";
import { RootState } from "../../../store";
import { StatisticsUsersLearningCoursesOrderBy } from "../../../types/enum/user-progress.enum";
import {
  ICourseLearningStatistics,
  StatisticsUsersLearningCoursesQuery,
} from "../../../types/interface/user-progress.interface";
import { getTranslationValue } from "../../../utils/translation";

const PAGE_SIZE = 20;

const normalizeStats = (payload: any): ICourseLearningStatistics[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data?.data)) return payload.data.data;
  return [];
};

const resolvePagination = (
  payload: any,
  fallbackLength: number,
  pageNumber: number,
  take: number,
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

const formatNumber = (value?: number) => {
  if (value === undefined || value === null) return "-";
  return value.toLocaleString("vi-VN");
};

const getRoleplayPassedCount = (
  item: ICourseLearningStatistics,
): number | undefined => {
  const normalizedItem = item as ICourseLearningStatistics & {
    roleplayPassedCount?: number;
    roleplayKeypointPassedCount?: number;
  };
  return (
    normalizedItem.roleplayPassedCount ??
    normalizedItem.roleplayKeypointPassedCount
  );
};

const orderByOptions: {
  value: StatisticsUsersLearningCoursesOrderBy;
  label: string;
}[] = [
  {
    value: StatisticsUsersLearningCoursesOrderBy.STARTED_USER_COUNT,
    label: "Started Users",
  },
  {
    value: StatisticsUsersLearningCoursesOrderBy.ROLEPLAY_PASSED_COUNT,
    label: "Roleplay Passed",
  },
  {
    value: StatisticsUsersLearningCoursesOrderBy.LESSON_KEYPOINT_PASSED_COUNT,
    label: "Lesson Keypoints Passed",
  },
  {
    value: StatisticsUsersLearningCoursesOrderBy.COMPLETED_USER_COUNT,
    label: "Completed Users",
  },
];

const CourseStatistics: React.FC = () => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const [stats, setStats] = useState<ICourseLearningStatistics[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [orderBy, setOrderBy] = useState<StatisticsUsersLearningCoursesOrderBy>(
    StatisticsUsersLearningCoursesOrderBy.STARTED_USER_COUNT,
  );
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const fetchStatistics = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new StatisticsUsersLearningCoursesQuery({ orderBy });
      query.page = page;
      query.take = PAGE_SIZE;
      delete (query as { order?: string }).order;
      const res =
        await userProgressService.statisticsUsersLearningCourses(query);
      const normalized = normalizeStats(res);
      const pagination = resolvePagination(
        res,
        normalized.length,
        page,
        PAGE_SIZE,
      );
      setStats(normalized);
      setTotalPages(pagination.totalPages);
      if (pagination.currentPage !== page) {
        setPage(pagination.currentPage);
      }
    } catch (err: any) {
      console.error("Fetch course statistics failed", err);
      setError(
        err?.response?.data?.message ||
          "Không thể tải thống kê khóa học, vui lòng thử lại",
      );
      setStats([]);
      setTotalPages(1);
    } finally {
      setLoading(false);
    }
  }, [orderBy, page]);

  useEffect(() => {
    fetchStatistics();
  }, [fetchStatistics]);

  useEffect(() => {
    setPage(1);
  }, [orderBy]);

  const handlePageChange = (_: React.ChangeEvent<unknown>, value: number) => {
    setPage(value);
  };

  const isEmpty = !loading && !error && stats.length === 0;

  return (
    <div className="rounded-3xl bg-white border border-slate-100 shadow-sm p-4 md:p-6 space-y-4">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div className="space-y-1">
          <h2 className="text-lg font-semibold text-slate-900">
            Course Statistics
          </h2>
          <p className="text-sm text-slate-500">
            Thống kê tiến trình theo khóa học.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <select
            value={orderBy}
            onChange={(event) =>
              setOrderBy(
                event.target.value as StatisticsUsersLearningCoursesOrderBy,
              )
            }
            className="h-9 rounded-xl border border-slate-200 bg-white px-3 text-sm text-slate-700 shadow-sm focus:outline-none focus:ring-2 focus:ring-brand-200"
          >
            {orderByOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <button
            onClick={fetchStatistics}
            className="inline-flex items-center justify-center px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 border border-gray-300 transition-colors"
            disabled={loading}
          >
            <ArrowPathIcon
              className={`h-5 w-5 mr-2 ${loading ? "animate-spin" : ""}`}
            />
            Làm mới
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {error}
        </div>
      )}

      <div className="overflow-x-auto rounded-2xl border border-slate-100">
        <table className="min-w-full text-sm text-left">
          <thead className="bg-slate-50 text-slate-600">
            <tr>
              <th className="px-4 py-3 font-semibold">Course</th>
              <th className="px-4 py-3 font-semibold">Started Users</th>
              <th className="px-4 py-3 font-semibold">
                Roleplay Passed
              </th>
              <th className="px-4 py-3 font-semibold">
                Lesson Keypoints Passed
              </th>
              <th className="px-4 py-3 font-semibold">Completed Users</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {loading && (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-6 text-center text-slate-500"
                >
                  Đang tải dữ liệu...
                </td>
              </tr>
            )}
            {!loading &&
              stats.map((item) => (
                <tr key={item.courseId} className="hover:bg-slate-50/60">
                  <td className="px-4 py-3 text-slate-900 font-medium">
                    {getTranslationValue(item.title, lang) || "-"}
                  </td>
                  <td className="px-4 py-3 text-slate-700">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full bg-brand-50 text-brand-700 font-semibold">
                      {formatNumber(item.startedUserCount)}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-slate-700">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full bg-amber-100 text-amber-800 font-semibold">
                      {formatNumber(getRoleplayPassedCount(item))}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-slate-700">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full bg-bronze-50 text-bronze-700 font-semibold">
                      {formatNumber(item.lessonKeypointPassedCount)}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-slate-700">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 font-semibold">
                      {formatNumber(item.completedUserCount)}
                    </span>
                  </td>
                </tr>
              ))}
            {isEmpty && (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-6 text-center text-slate-500"
                >
                  Không có dữ liệu thống kê.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {totalPages > 1 && (
        <div className="flex justify-center pt-2">
          <Pagination
            count={totalPages}
            page={page}
            onChange={handlePageChange}
            color="primary"
          />
        </div>
      )}
    </div>
  );
};

export default CourseStatistics;
