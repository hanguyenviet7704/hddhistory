import React, { useCallback, useEffect, useState } from "react";
import { Pagination, Tooltip } from "@mui/material";
import {
  ArrowPathIcon,
  TrashIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { reportService } from "../../services/reportService";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";

const DEFAULT_PAGE_SIZE = 10;

const formatDate = (value?: string | Date) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};

interface IReport {
  _id: string;
  userId: string;
  lessonId: string;
  lessonTitle?: any;
  courseId?: string;
  courseTitle?: any;
  keypointId?: string;
  keypointTitle?: any;
  reasons: string[];
  comment?: string;
  createdAt: string;
}

export default function ReportList() {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showError, showSuccess } = useNotification();

  const [items, setItems] = useState<IReport[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  // Debounce search
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(search);
      setPage(1);
    }, 500);
    return () => clearTimeout(handler);
  }, [search]);

  const fetchReports = useCallback(async (pageNumber: number, searchQuery: string) => {
    setLoading(true);
    try {
      const res = await reportService.getList({
        page: pageNumber,
        take: DEFAULT_PAGE_SIZE,
        search: searchQuery.trim(),
      });
      const data = res.data?.data ?? res.data ?? {};
      setItems(data.items || []);
      setTotalPages(data.totalPages || 1);
      setPage(data.currentPage || pageNumber);
    } catch (error) {
      console.error("Failed to fetch reports", error);
      showError("Failed to fetch reported issues");
    } finally {
      setLoading(false);
    }
  }, [showError]);

  useEffect(() => {
    fetchReports(page, debouncedSearch);
  }, [fetchReports, page, debouncedSearch]);

  const handleDelete = async () => {
    if (!confirmDeleteId) return;
    setDeleting(true);
    try {
      await reportService.remove(confirmDeleteId);
      showSuccess("Deleted report log successfully");
      setConfirmDeleteId(null);
      fetchReports(page, debouncedSearch);
    } catch (error) {
      console.error("Failed to delete report log", error);
      showError("Failed to delete report log");
    } finally {
      setDeleting(false);
    }
  };

  const getReasonLabel = (reason: string) => {
    switch (reason) {
      case "INACCURATE_CONTENT":
        return "Inaccurate content";
      case "DIFFERENT_FROM_PREVIEW":
        return "Different from preview";
      case "CONFUSING_EXPLANATION":
        return "Confusing explanation";
      case "TRANSLATION_ERROR":
        return "Translation error";
      case "HARD_TO_READ":
        return "Hard to read";
      default:
        return reason;
    }
  };

  const getReasonColor = (reason: string) => {
    switch (reason) {
      case "INACCURATE_CONTENT":
        return "bg-rose-100 text-rose-700 border-rose-200";
      case "DIFFERENT_FROM_PREVIEW":
        return "bg-amber-100 text-amber-700 border-amber-200";
      case "CONFUSING_EXPLANATION":
        return "bg-blue-100 text-blue-700 border-blue-200";
      case "TRANSLATION_ERROR":
        return "bg-purple-100 text-purple-700 border-purple-200";
      case "HARD_TO_READ":
        return "bg-slate-100 text-slate-700 border-slate-200";
      default:
        return "bg-gray-100 text-gray-700 border-gray-200";
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <ExclamationTriangleIcon className="h-7 w-7 text-amber-500" />
              Reported Issues
            </h1>
            <p className="text-sm text-gray-500 mt-1">
              View and manage issue reports submitted by users on lessons.
            </p>
          </div>
          <div className="flex items-center gap-3">
            {/* Search Input */}
            <div className="relative">
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search comments..."
                className="border rounded-lg pl-10 pr-4 py-2 w-72 focus:outline-none focus:ring-2 focus:ring-blue-500 shadow-sm bg-white"
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
              onClick={() => fetchReports(page, debouncedSearch)}
              disabled={loading}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 text-gray-700 bg-white hover:bg-gray-50 text-sm shadow-sm disabled:opacity-70"
            >
              <ArrowPathIcon className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
              Refresh
            </button>
          </div>
        </div>

        {/* Table/Content Card */}
        <div className="bg-white rounded-xl shadow-md border border-gray-200 overflow-hidden">
          {loading && items.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20">
              <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500 mb-3"></div>
              <p className="text-gray-500 text-sm">Loading reports...</p>
            </div>
          ) : items.length === 0 ? (
            <div className="py-20 text-center">
              <div className="text-gray-300 mb-4">
                <ExclamationTriangleIcon className="h-16 w-16 mx-auto" />
              </div>
              <h3 className="text-xl font-medium text-gray-900 mb-1">
                No issue reports found
              </h3>
              <p className="text-gray-500 text-sm">
                There are no reports submitted or matching the search criteria.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full table-fixed divide-y divide-gray-200">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="px-4 py-3 text-left text-[11px] font-semibold text-gray-400 uppercase tracking-wider w-[110px]">
                      User ID
                    </th>
                    <th className="px-4 py-3 text-left text-[11px] font-semibold text-gray-400 uppercase tracking-wider w-[220px]">
                      Course / Lesson
                    </th>
                    <th className="px-4 py-3 text-left text-[11px] font-semibold text-gray-400 uppercase tracking-wider w-[200px]">
                      Reasons
                    </th>
                    <th className="px-4 py-3 text-left text-[11px] font-semibold text-gray-400 uppercase tracking-wider">
                      Comment / Feedback
                    </th>
                    <th className="px-4 py-3 text-left text-[11px] font-semibold text-gray-400 uppercase tracking-wider w-[150px]">
                      Date Reported
                    </th>
                    <th className="px-4 py-3 text-right text-[11px] font-semibold text-gray-400 uppercase tracking-wider w-[80px]">
                      Action
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-100">
                  {items.map((item) => {
                    const lessonName = getTranslationValue(item.lessonTitle, lang) || item.lessonId;
                    const courseName = getTranslationValue(item.courseTitle, lang) || item.courseId || "-";
                    const keypointName = item.keypointId ? (getTranslationValue(item.keypointTitle, lang) || item.keypointId) : null;
                    const shortUserId = item.userId.length > 10 ? `${item.userId.slice(0, 8)}…` : item.userId;
                    return (
                      <tr key={item._id} className="hover:bg-amber-50/30 transition-colors align-top">
                        {/* User ID */}
                        <td className="px-4 py-3 w-[110px]">
                          <Tooltip title={item.userId} arrow placement="right">
                            <span className="font-mono text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded cursor-default select-all block truncate">
                              {shortUserId}
                            </span>
                          </Tooltip>
                        </td>

                        {/* Course / Lesson */}
                        <td className="px-4 py-3 w-[220px]">
                          <Tooltip title={lessonName} arrow placement="top">
                            <p className="text-sm font-semibold text-gray-900 leading-snug overflow-hidden" style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>
                              📖 {lessonName}
                            </p>
                          </Tooltip>
                          <Tooltip title={courseName} arrow placement="top">
                            <p className="text-xs text-gray-400 mt-0.5 leading-snug overflow-hidden" style={{ display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical' }}>
                              📦 {courseName}
                            </p>
                          </Tooltip>
                          {keypointName && (
                            <Tooltip title={keypointName} arrow placement="top">
                              <p className="text-xs text-indigo-500 mt-0.5 leading-snug overflow-hidden" style={{ display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical' }}>
                                🔑 {keypointName}
                              </p>
                            </Tooltip>
                          )}
                        </td>

                        {/* Reasons */}
                        <td className="px-4 py-3 w-[200px]">
                          <div className="flex flex-wrap gap-1">
                            {item.reasons.map((r, idx) => (
                              <span
                                key={`${r}-${idx}`}
                                className={`px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase tracking-wide border ${getReasonColor(r)}`}
                              >
                                {getReasonLabel(r)}
                              </span>
                            ))}
                          </div>
                        </td>

                        {/* Comment */}
                        <td className="px-4 py-3">
                          {item.comment ? (
                            <div className="max-h-[88px] overflow-y-auto bg-slate-50 border border-slate-100 rounded-md px-3 py-2 scrollbar-thin">
                              <p className="text-xs text-gray-700 leading-relaxed break-all whitespace-pre-wrap">
                                {item.comment}
                              </p>
                            </div>
                          ) : (
                            <span className="text-gray-400 italic text-xs">No description</span>
                          )}
                        </td>

                        {/* Date */}
                        <td className="px-4 py-3 w-[150px] text-xs text-gray-500 whitespace-nowrap">
                          {formatDate(item.createdAt)}
                        </td>

                        {/* Action */}
                        <td className="px-4 py-3 w-[80px] text-right">
                          <button
                            onClick={() => setConfirmDeleteId(item._id)}
                            className="inline-flex items-center gap-1 px-2 py-1 rounded-md text-rose-600 hover:bg-rose-50 border border-transparent hover:border-rose-200 transition text-xs"
                            title="Delete report log"
                          >
                            <TrashIcon className="h-4 w-4" />
                            <span>Delete</span>
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination Footer */}
          {items.length > 0 && (
            <div className="p-4 bg-gray-50 border-t border-gray-200 flex justify-end">
              <Pagination
                count={totalPages}
                page={page}
                onChange={(_, value) => setPage(value)}
                color="primary"
                shape="rounded"
              />
            </div>
          )}
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {confirmDeleteId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6 space-y-4 transform scale-100 transition-all border border-gray-100">
            <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <ExclamationTriangleIcon className="h-6 w-6 text-rose-500" />
              Delete report log?
            </h3>
            <p className="text-sm text-gray-600 leading-relaxed">
              Are you sure you want to delete this issue report? This action will permanently remove the log from the database.
            </p>
            <div className="flex justify-end gap-3 pt-2">
              <button
                onClick={() => setConfirmDeleteId(null)}
                disabled={deleting}
                className="px-4 py-2 rounded-lg border border-gray-200 text-gray-700 bg-white hover:bg-gray-50 text-sm font-medium transition"
              >
                Cancel
              </button>
              <button
                onClick={handleDelete}
                disabled={deleting}
                className="px-4 py-2 rounded-lg bg-rose-600 hover:bg-rose-700 text-white text-sm font-semibold transition disabled:opacity-70 flex items-center gap-1.5"
              >
                {deleting ? (
                  <>
                    <div className="animate-spin rounded-full h-3.5 w-3.5 border-t-2 border-white"></div>
                    Deleting...
                  </>
                ) : (
                  "Delete"
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
