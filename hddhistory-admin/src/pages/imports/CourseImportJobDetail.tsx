import React, { useCallback, useEffect, useRef, useState } from "react";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import {
  ArrowLeftIcon,
  AlertTriangleIcon,
  CheckCircleIcon,
  Loader2Icon,
} from "lucide-react";
import {
  CourseImportJob,
  courseImportJobService,
} from "../../services/courseImportJobService";

const ACTIVE_STATUSES = ["queued", "processing"];
const TERMINAL_STATUSES = ["completed", "failed", "cancelled"];

const statusLabels: Record<CourseImportJob["status"], string> = {
  queued: "Queued",
  processing: "Processing",
  completed: "Completed",
  failed: "Failed",
  cancelled: "Cancelled",
};

const statusClasses: Record<CourseImportJob["status"], string> = {
  queued: "bg-slate-100 text-slate-700",
  processing: "bg-brand-100 text-brand-700",
  completed: "bg-green-100 text-green-700",
  failed: "bg-red-100 text-red-700",
  cancelled: "bg-gray-200 text-gray-700",
};

export default function CourseImportJobDetail() {
  const { jobId } = useParams();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [job, setJob] = useState<CourseImportJob | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const pollRef = useRef<number | undefined>(undefined);
  const target = searchParams.get("target");
  const backPath = target === "exercises" ? "/exercise" : "/theory";

  const refreshJob = useCallback(async () => {
    if (!jobId) return;

    try {
      const response = await courseImportJobService.getById(jobId);
      setJob(response.data || response);
      setError(null);
    } catch (err: any) {
      setError(
        err.response?.data?.message || err.message || "Load import job failed"
      );
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    refreshJob();
  }, [refreshJob]);

  useEffect(() => {
    window.clearTimeout(pollRef.current);
    if (!job || TERMINAL_STATUSES.includes(job.status)) return;

    const delay = document.hidden ? 30000 : 3000;
    pollRef.current = window.setTimeout(refreshJob, delay);
    return () => window.clearTimeout(pollRef.current);
  }, [job, refreshJob]);

  const isActive = job ? ACTIVE_STATUSES.includes(job.status) : false;

  if (loading) {
    return (
      <div className="min-h-[100dvh] bg-slate-100 px-4 py-10">
        <div className="mx-auto flex max-w-4xl justify-center">
          <div className="flex items-center gap-3 rounded-lg border border-slate-200 bg-white px-5 py-4 text-slate-700 shadow-sm">
            <Loader2Icon className="h-5 w-5 animate-spin text-brand-600" />
            Loading import job...
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[100dvh] bg-slate-100 px-4 py-8 text-slate-900 md:px-8">
      <div className="mx-auto max-w-4xl space-y-6">
        <button
          type="button"
          onClick={() => navigate(backPath)}
          className="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm hover:bg-slate-50"
        >
          <ArrowLeftIcon className="h-4 w-4" />
          Back
        </button>

        <section className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
                Excel Import
              </p>
              <h1 className="mt-1 text-2xl font-semibold text-slate-950">
                Learning Item Import
              </h1>
              <p className="mt-1 break-all text-sm text-slate-500">{jobId}</p>
            </div>

            {job && (
              <span
                className={`w-fit rounded-full px-3 py-1 text-sm font-medium ${
                  statusClasses[job.status]
                }`}
              >
                {statusLabels[job.status]}
              </span>
            )}
          </div>
        </section>

        {error && (
          <div className="flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 shadow-sm">
            <AlertTriangleIcon className="mt-0.5 h-5 w-5 flex-none" />
            <span>{error}</span>
          </div>
        )}

        {job && (
          <section className="space-y-5 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="grid gap-3 md:grid-cols-3">
              <Metric label="Total Rows" value={job.totalRows} />
              <Metric label="Processed Rows" value={job.processedRows} />
              <Metric label="Progress" value={`${job.percent}%`} />
            </div>

            <div>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="font-semibold text-slate-800">Progress</span>
                <span className="font-medium text-slate-600">
                  {job.percent}%
                </span>
              </div>
              <div className="h-3 overflow-hidden rounded-full bg-slate-200">
                <div
                  className="h-full rounded-full bg-brand-700 transition-all"
                  style={{ width: `${Math.min(job.percent, 100)}%` }}
                />
              </div>
            </div>

            {isActive && (
              <div className="flex items-center gap-2 rounded-lg border border-brand-100 bg-brand-50 px-4 py-3 text-sm text-brand-700">
                <Loader2Icon className="h-5 w-5 animate-spin" />
                Import is running. This page will refresh automatically.
              </div>
            )}

            {job.status === "completed" && (
              <div className="flex items-center gap-2 rounded-lg border border-green-100 bg-green-50 px-4 py-3 text-sm text-green-700">
                <CheckCircleIcon className="h-5 w-5" />
                Import completed successfully.
              </div>
            )}

            {(job.lastError || job.errors?.length) && (
              <div className="rounded-lg border border-red-200 bg-red-50">
                <div className="border-b border-red-100 px-4 py-3 text-sm font-semibold text-red-800">
                  Import errors
                </div>
                {job.lastError && (
                  <p className="px-4 py-3 text-sm text-red-700">
                    {job.lastError}
                  </p>
                )}
                <div className="max-h-80 overflow-auto">
                  {job.errors?.map((item, index) => (
                    <div
                      key={`${item.sheet}-${item.row}-${item.column}-${index}`}
                      className="border-t border-red-100 px-4 py-3 text-sm text-red-700"
                    >
                      <span className="font-semibold">
                        {item.sheet} row {item.row}
                        {item.column ? ` (${item.column})` : ""}
                      </span>
                      : {item.message}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </section>
        )}
      </div>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: number | string }) {
  return (
    <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-3">
      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
        {label}
      </p>
      <p className="mt-1 text-xl font-semibold text-slate-950">{value}</p>
    </div>
  );
}
