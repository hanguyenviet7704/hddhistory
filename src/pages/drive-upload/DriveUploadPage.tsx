import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  ArrowPathIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  StopCircleIcon,
} from "@heroicons/react/24/outline";
import { driveImportService } from "../../services/driveImportService";
import {
  DriveImportJob,
  DriveImportJobStatus,
} from "../../types/interface/files/drive-import.interface";

const ACTIVE_STATUSES: DriveImportJobStatus[] = ["queued", "processing"];
const TERMINAL_STATUSES: DriveImportJobStatus[] = [
  "completed",
  "completed_with_errors",
  "failed",
  "cancelled",
];

const getJobId = (job: DriveImportJob) => job._id;

const statusLabels: Record<DriveImportJobStatus, string> = {
  queued: "Queued",
  processing: "Processing",
  completed: "Completed",
  completed_with_errors: "Completed with errors",
  failed: "Failed",
  cancelled: "Cancelled",
};

const statusClasses: Record<DriveImportJobStatus, string> = {
  queued: "bg-slate-100 text-slate-700",
  processing: "bg-blue-100 text-blue-700",
  completed: "bg-green-100 text-green-700",
  completed_with_errors: "bg-amber-100 text-amber-700",
  failed: "bg-red-100 text-red-700",
  cancelled: "bg-gray-200 text-gray-700",
};

export default function DriveUploadPage() {
  const [folderUrl, setFolderUrl] = useState("");
  const [jobs, setJobs] = useState<DriveImportJob[]>([]);
  const [activeJob, setActiveJob] = useState<DriveImportJob | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [cancelling, setCancelling] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const pollRef = useRef<number | undefined>(undefined);

  const isActive = activeJob
    ? ACTIVE_STATUSES.includes(activeJob.status)
    : false;

  const processedFiles = useMemo(() => {
    if (!activeJob) return 0;
    return activeJob.uploadedFiles + activeJob.failedCount;
  }, [activeJob]);

  const loadJobs = useCallback(async () => {
    setError(null);
    try {
      const list = await driveImportService.list();
      setJobs(list);
      const running = list.find((job) => ACTIVE_STATUSES.includes(job.status));
      if (running) {
        setActiveJob(running);
      } else if (!activeJob && list.length > 0) {
        setActiveJob(list[0]);
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || "Load jobs failed");
    } finally {
      setLoading(false);
    }
  }, [activeJob]);

  const refreshJob = useCallback(async (jobId: string) => {
    try {
      const job = await driveImportService.getById(jobId);
      setActiveJob(job);
      setJobs((prev) => {
        const exists = prev.some((item) => getJobId(item) === getJobId(job));
        if (!exists) return [job, ...prev];
        return prev.map((item) =>
          getJobId(item) === getJobId(job) ? job : item
        );
      });
    } catch (err: any) {
      setError(
        err.response?.data?.message || err.message || "Refresh job failed"
      );
    }
  }, []);

  useEffect(() => {
    loadJobs();
  }, [loadJobs]);

  useEffect(() => {
    window.clearTimeout(pollRef.current);
    if (!activeJob || TERMINAL_STATUSES.includes(activeJob.status)) return;

    const delay = document.hidden ? 30000 : 5000;
    pollRef.current = window.setTimeout(() => {
      refreshJob(getJobId(activeJob));
    }, delay);

    return () => window.clearTimeout(pollRef.current);
  }, [activeJob, refreshJob]);

  useEffect(() => {
    const handleVisibilityChange = () => {
      if (!document.hidden && activeJob && isActive) {
        refreshJob(getJobId(activeJob));
      }
    };

    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () =>
      document.removeEventListener("visibilitychange", handleVisibilityChange);
  }, [activeJob, isActive, refreshJob]);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!folderUrl.trim()) return;

    setSubmitting(true);
    setError(null);
    try {
      const job = await driveImportService.create(folderUrl.trim());
      setActiveJob(job);
      setFolderUrl("");
      await refreshJob(getJobId(job));
    } catch (err: any) {
      setError(
        err.response?.data?.message || err.message || "Create import job failed"
      );
    } finally {
      setSubmitting(false);
    }
  };

  const handleCancel = async () => {
    if (!activeJob) return;
    setCancelling(true);
    setError(null);
    try {
      const job = await driveImportService.cancel(getJobId(activeJob));
      setActiveJob(job);
      await loadJobs();
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || "Cancel failed");
    } finally {
      setCancelling(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-[100dvh] bg-slate-100 px-4 py-10">
        <div className="mx-auto flex max-w-5xl justify-center">
          <div className="flex items-center gap-3 rounded-lg border border-slate-200 bg-white px-5 py-4 text-slate-700 shadow-sm">
            <ArrowPathIcon className="h-5 w-5 animate-spin text-blue-600" />
            Loading import jobs...
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[100dvh] bg-slate-100 px-4 py-8 text-slate-900 md:px-8">
      <div className="mx-auto max-w-5xl space-y-6">
        <div className="rounded-xl border border-slate-200 bg-white px-6 py-5 shadow-sm">
          <div className="flex flex-col gap-2">
            <p className="text-xs font-semibold uppercase tracking-wide text-blue-700">
              Drive Import
            </p>
            <h1 className="text-2xl font-semibold text-slate-950">
              Import File From Drive
            </h1>
            <p className="max-w-3xl text-sm leading-6 text-slate-600">
              Paste a Google Drive folder URL. Backend imports files from
              images, videos, and audios folders, then updates progress here.
            </p>
          </div>
        </div>

        {error && (
          <div className="flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 shadow-sm">
            <ExclamationTriangleIcon className="mt-0.5 h-5 w-5 flex-none" />
            <span>{error}</span>
          </div>
        )}

        <form
          onSubmit={handleSubmit}
          className="space-y-4 rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
        >
          <label className="block text-sm font-semibold text-slate-800">
            Google Drive folder URL
          </label>
          <div className="flex flex-col gap-3 md:flex-row">
            <input
              value={folderUrl}
              onChange={(event) => setFolderUrl(event.target.value)}
              placeholder="https://drive.google.com/drive/folders/..."
              className="min-h-11 flex-1 rounded-lg border border-slate-300 bg-slate-50 px-3 text-base text-slate-900 outline-none transition focus:border-blue-500 focus:bg-white focus:ring-2 focus:ring-blue-100 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-500"
              disabled={submitting || isActive}
            />
            <button
              type="submit"
              disabled={submitting || isActive || !folderUrl.trim()}
              className="min-h-11 rounded-lg bg-blue-700 px-5 text-sm font-semibold text-white shadow-sm hover:bg-blue-800 disabled:cursor-not-allowed disabled:bg-slate-300 disabled:text-slate-500"
            >
              {submitting ? "Starting..." : "Start Import"}
            </button>
          </div>
          {isActive && (
            <p className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
              Current user already has an active import job. Finish or cancel it
              before starting another one.
            </p>
          )}
        </form>

        {activeJob && (
          <section className="space-y-5 rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-lg font-semibold text-slate-950">
                  Current Import
                </h2>
                <span
                  className={`rounded-full px-2.5 py-1 text-xs font-medium ${
                    statusClasses[activeJob.status]
                  }`}
                >
                  {statusLabels[activeJob.status]}
                </span>
              </div>
              <p className="mt-1 break-all text-sm leading-6 text-slate-600">
                {activeJob.folderUrl}
              </p>
            </div>

            {isActive && (
              <button
                onClick={handleCancel}
                disabled={cancelling}
                className="inline-flex min-h-10 items-center justify-center gap-2 rounded-lg border border-red-200 px-4 text-sm font-semibold text-red-700 hover:bg-red-50 disabled:cursor-not-allowed disabled:text-slate-400"
              >
                <StopCircleIcon className="h-5 w-5" />
                {cancelling ? "Cancelling..." : "Cancel"}
              </button>
            )}
          </div>

          <div className="grid gap-3 md:grid-cols-4">
            <Metric label="Total" value={activeJob.totalFiles} />
            <Metric label="Processed" value={processedFiles} />
            <Metric label="Uploaded" value={activeJob.uploadedFiles} />
            <Metric label="Failed" value={activeJob.failedCount} />
          </div>

          <div>
            <div className="mb-2 flex items-center justify-between text-sm">
              <span className="font-semibold text-slate-800">Progress</span>
              <span className="font-medium text-slate-600">
                {activeJob.percent}%
              </span>
            </div>
            <div className="h-3 overflow-hidden rounded-full bg-slate-200">
              <div
                className="h-full rounded-full bg-blue-700 transition-all"
                style={{ width: `${Math.min(activeJob.percent, 100)}%` }}
              />
            </div>
          </div>

          {activeJob.lastError && (
            <div className="rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {activeJob.lastError}
            </div>
          )}

          <FileList
            title="Uploaded files"
            emptyText="No uploaded files yet."
            items={activeJob.uploadedItems.map((item) => ({
              key: `${item.path}-${item.uploadedAt}`,
              path: item.path,
              detail: item.url,
              href: item.url,
              icon: <CheckCircleIcon className="h-5 w-5 text-green-600" />,
            }))}
          />

          <FileList
            title="Failed files"
            emptyText="No failed files."
            items={activeJob.failedFiles.map((item) => ({
              key: `${item.path}-${item.failedAt}`,
              path: item.path,
              detail: item.message,
              icon: (
                <ExclamationTriangleIcon className="h-5 w-5 text-red-600" />
              ),
            }))}
          />
          </section>
        )}

        {jobs.length > 0 && (
          <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-lg font-semibold text-slate-950">
            Recent Jobs
          </h2>
          <div className="divide-y divide-slate-100">
            {jobs.map((job) => (
              <button
                key={getJobId(job)}
                onClick={() => setActiveJob(job)}
                className="flex w-full flex-col gap-1 rounded-lg px-2 py-3 text-left hover:bg-slate-50 md:flex-row md:items-center md:justify-between"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-slate-800">
                      {job.uploadedFiles}/{job.totalFiles} uploaded
                    </span>
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs ${
                        statusClasses[job.status]
                      }`}
                    >
                      {statusLabels[job.status]}
                    </span>
                  </div>
                  <p className="mt-1 max-w-3xl truncate text-sm text-slate-500">
                    {job.folderUrl}
                  </p>
                </div>
                <span className="text-sm font-medium text-slate-500">
                  {job.percent}%
                </span>
              </button>
            ))}
          </div>
          </section>
        )}
      </div>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-3">
      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
        {label}
      </p>
      <p className="mt-1 text-xl font-semibold text-slate-950">{value}</p>
    </div>
  );
}

function FileList({
  title,
  emptyText,
  items,
}: {
  title: string;
  emptyText: string;
  items: Array<{
    key: string;
    path: string;
    detail: string;
    href?: string;
    icon: React.ReactNode;
  }>;
}) {
  return (
    <details className="rounded-lg border border-slate-200 bg-white">
      <summary className="cursor-pointer px-3 py-2 text-sm font-semibold text-slate-800">
        {title} ({items.length})
      </summary>
      <div className="max-h-72 overflow-auto border-t border-slate-100">
        {items.length === 0 ? (
          <p className="px-3 py-3 text-sm text-slate-500">{emptyText}</p>
        ) : (
          items.map((item) => (
            <div
              key={item.key}
              className="flex items-start gap-2 px-3 py-2 text-sm"
            >
              {item.icon}
              <div className="min-w-0">
                <p className="break-all font-medium text-slate-800">
                  {item.path}
                </p>
                {item.href ? (
                  <a
                    href={item.href}
                    target="_blank"
                    rel="noreferrer"
                    className="break-all text-blue-700 hover:underline"
                  >
                    {item.detail}
                  </a>
                ) : (
                  <p className="break-all text-slate-500">{item.detail}</p>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </details>
  );
}
