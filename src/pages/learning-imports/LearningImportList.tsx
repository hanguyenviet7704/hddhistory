import React, { useCallback, useEffect, useState } from "react";
import { Pagination } from "@mui/material";
import {
  ArrowPathIcon,
  ChevronRightIcon,
  MagnifyingGlassIcon,
} from "@heroicons/react/24/outline";
import { Link } from "react-router-dom";

import { learningImportService } from "../../services/learningImportService";
import {
  ILearningImportRow,
  LearningImportListQuery,
} from "../../types/interface/learningImport.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import ImportStatsPanel from "./ImportStatsPanel";
import RunImportPanel from "./RunImportPanel";
import {
  ERROR_LABELS,
  formatDateTime,
  formatVnd,
  SourceBadge,
  StatusBadge,
} from "./learningImportLabels";

const DEFAULT_PAGE_SIZE = 20;

type StatusFilter = NonNullable<LearningImportListQuery["status"]> | "";

// `interrupted` is missing on purpose: it is derived from a stale heartbeat when
// a job is read, never written to the document, so there is nothing to filter on.
// Filter `processing` and read the returned status instead.
const STATUS_OPTIONS: { value: StatusFilter; label: string }[] = [
  { value: "", label: "All statuses" },
  { value: "processing", label: "Processing" },
  { value: "completed", label: "Completed" },
  { value: "failed", label: "Failed" },
  { value: "queued", label: "Queued" },
];

/**
 * What users bring to the import feature, and what came back out.
 *
 * Two jobs: spotting quality problems early (filter Failed, read the error
 * column) and understanding what people actually want to learn from — which is
 * the sort of thing no analytics event would have told us to ask about.
 */
export default function LearningImportList() {
  const { showError } = useNotification();

  const [items, setItems] = useState<ILearningImportRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("");

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(search);
      setPage(1);
    }, 500);
    return () => clearTimeout(handler);
  }, [search]);

  const fetchImports = useCallback(
    async (pageNumber: number, searchQuery: string, status: StatusFilter) => {
      setLoading(true);
      try {
        const data = await learningImportService.getImports({
          page: pageNumber,
          take: DEFAULT_PAGE_SIZE,
          search: searchQuery.trim() || undefined,
          status: status || undefined,
        });
        setItems(data?.items ?? []);
        setTotalPages(data?.totalPages || 1);
      } catch (error: any) {
        console.error("Failed to fetch learning imports", error);
        showError("Failed to load imports");
      } finally {
        setLoading(false);
      }
    },
    [showError],
  );

  useEffect(() => {
    fetchImports(page, debouncedSearch, statusFilter);
  }, [fetchImports, page, debouncedSearch, statusFilter]);

  /**
   * Poll only while something is actually running, and stop when nothing is.
   *
   * An unconditional timer would keep this page hitting the API all day on a
   * screen somebody left open, for rows that cannot change. `queued` counts as
   * running: a job sits there for the moment between being created and the
   * runner picking it up.
   */
  const hasRunningJob = items.some(
    (row) => row.status === "processing" || row.status === "queued",
  );
  useEffect(() => {
    if (!hasRunningJob) return;
    const timer = setInterval(
      () => fetchImports(page, debouncedSearch, statusFilter),
      3000,
    );
    return () => clearInterval(timer);
  }, [hasRunningJob, fetchImports, page, debouncedSearch, statusFilter]);

  return (
    <div className="p-6">
      <div className="mb-6 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">User imports</h1>
          <p className="mt-1 text-sm text-gray-500">
            Lessons users generated from their own PDFs and YouTube links. Open a
            row to read what the model actually wrote.
          </p>
        </div>
        <button
          onClick={() => fetchImports(page, debouncedSearch, statusFilter)}
          disabled={loading}
          className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-50"
        >
          <ArrowPathIcon className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
          Refresh
        </button>
      </div>

      <ImportStatsPanel />

      <RunImportPanel
        onStarted={() => fetchImports(1, debouncedSearch, statusFilter)}
      />

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <div className="flex flex-wrap items-center gap-3 border-b border-gray-200 bg-gray-50 p-4">
          <div className="relative min-w-[260px] flex-1">
            <MagnifyingGlassIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by filename, video title or URL…"
              className="w-full rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm outline-none focus:border-indigo-500"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value as StatusFilter);
              setPage(1);
            }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
          >
            {STATUS_OPTIONS.map((option) => (
              <option key={option.value || "all"} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        {loading && items.length === 0 ? (
          <div className="p-10 text-center text-sm text-gray-500">Loading…</div>
        ) : items.length === 0 ? (
          <div className="p-10 text-center text-sm text-gray-500">
            {debouncedSearch || statusFilter
              ? "No imports match this filter."
              : "Nobody has imported anything yet."}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 text-sm">
              <thead className="bg-white">
                <tr className="text-left text-xs uppercase tracking-wide text-gray-500">
                  <th className="px-4 py-3 font-semibold">Source</th>
                  <th className="px-4 py-3 font-semibold">User</th>
                  <th className="px-4 py-3 font-semibold">Language</th>
                  <th className="px-4 py-3 font-semibold">Status</th>
                  <th className="px-4 py-3 font-semibold">Cost</th>
                  <th className="px-4 py-3 font-semibold">Created</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {items.map((row) => (
                  <tr key={row.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <SourceBadge type={row.sourceType} />
                        <span
                          className="max-w-[320px] truncate font-medium text-gray-900"
                          title={row.sourceLabel}
                        >
                          {row.sourceLabel || "(unnamed)"}
                        </span>
                      </div>
                      {row.errorCode && (
                        <div className="mt-1 text-xs text-rose-600">
                          {ERROR_LABELS[row.errorCode] ?? row.errorCode}
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">
                      {row.userId}
                    </td>
                    <td className="px-4 py-3 uppercase text-gray-700">
                      {row.outputLocale}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={row.status} />
                      {row.status === "processing" && (
                        <span className="ml-2 text-xs text-gray-400">
                          {row.percent}%
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-gray-700">
                      {formatVnd(row.usage?.estimatedCostVnd)}
                    </td>
                    <td className="px-4 py-3 text-gray-700">
                      {formatDateTime(row.createdAt)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Link
                        to={`/learning-imports/${row.id}`}
                        className="inline-flex items-center gap-1 text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                      >
                        Detail
                        <ChevronRightIcon className="h-4 w-4" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {items.length > 0 && totalPages > 1 && (
          <div className="flex justify-end border-t border-gray-200 bg-gray-50 p-4">
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
  );
}
